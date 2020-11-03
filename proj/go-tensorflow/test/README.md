# Useful Functions  
Const  
VarHandleOp  
AssignVariableOp  
ReadVariableOp  
Empty  
EmptyTensorList  
ExpandDims  
Fill  
LinSpace  
MatrixSolve  
Placeholder  
RandomDataset(scope, seed, seed2, output_type, output_shape)  
RandomGamma  
RandomUniform  
RandomUniformInt  
Range  
Rank  
RangeDataset  
Reshape  

# AdamOptimizer Implementation Strategy  

AdamOptimizer starts here.  
It's on training/adam.py  

```python
@tf_export("train.AdamOptimizer")
class AdamOptimizer(optimizer.Optimizer):
  """Optimizer that implements the Adam algorithm.

  See [Kingma et al., 2014](http://arxiv.org/abs/1412.6980)
  ([pdf](http://arxiv.org/pdf/1412.6980.pdf)).
  """

  def __init__(self, learning_rate=0.001, beta1=0.9, beta2=0.999, epsilon=1e-8,
               use_locking=False, name="Adam"):

    super(AdamOptimizer, self).__init__(use_locking, name)
    self._lr = learning_rate
    self._beta1 = beta1
    self._beta2 = beta2
    self._epsilon = epsilon

    # Tensor versions of the constructor arguments, created in _prepare().
    self._lr_t = None
    self._beta1_t = None
    self._beta2_t = None
    self._epsilon_t = None

    # Created in SparseApply if needed.
    self._updated_lr = None
```

However, we use it like below.  

```python
train_step = tf.compat.v1.train.AdamOptimizer(0.001).minimize(cross_entropy)  
```

So, we have to understand minimize to implement AdamOptimizer with Golang.  
And AdamOptimizer inherit Optimizer that looks like below.  

```python
@tf_export("train.Optimizer")
class Optimizer(
    # Optimizers inherit from CheckpointableBase rather than Checkpointable
    # since they do most of their dependency management themselves (slot
    # variables are special-cased, and non-slot variables are keyed to graphs).
    checkpointable.CheckpointableBase):

  # Values for gate_gradients.
  GATE_NONE = 0
  GATE_OP = 1
  GATE_GRAPH = 2

  def __init__(self, use_locking, name):
    """Create a new Optimizer.

    This must be called by the constructors of subclasses.

    Args:
      use_locking: Bool. If True apply use locks to prevent concurrent updates
        to variables.
      name: A non-empty string.  The name to use for accumulators created
        for the optimizer.

    Raises:
      ValueError: If name is malformed.
    """
    if not name:
      raise ValueError("Must specify the optimizer name")
    self._use_locking = use_locking
    self._name = name
    # Dictionary of slots.
    #  {slot_name :
    #      {_var_key(variable_to_train): slot_for_the_variable, ... },
    #   ... }
    self._slots = {}
    self._non_slot_dict = {}

    self._deferred_slot_restorations = {}
```

Upper Constructor operates when super() called.  
After constructing then minimize will operate.  

```python
def minimize(self, loss, global_step=None, var_list=None,
               gate_gradients=GATE_OP, aggregation_method=None,
               colocate_gradients_with_ops=False, name=None,
               grad_loss=None):

    grads_and_vars = self.compute_gradients(
        loss, var_list=var_list, gate_gradients=gate_gradients,
        aggregation_method=aggregation_method,
        colocate_gradients_with_ops=colocate_gradients_with_ops,
        grad_loss=grad_loss)

    vars_with_grad = [v for g, v in grads_and_vars if g is not None]
    if not vars_with_grad:
      raise ValueError(
          "No gradients provided for any variable, check your graph for ops"
          " that do not support gradients, between variables %s and loss %s." %
          ([str(v) for _, v in grads_and_vars], loss))

    return self.apply_gradients(grads_and_vars, global_step=global_step, name=name)
```

There are some equations to implement AdamOptimizer that is below.  
We can know it when apply_gradients() operate.  

```go
lr_t := \text{learning_rate} * \sqrt{(1 - beta_2^t) / (1 - beta_1^t)}
m_t := beta_1 * m_{t-1} + (1 - beta_1) * g
v_t := beta_2 * v_{t-1} + (1 - beta_2) * g * g
variable := variable - lr_t * m_t / (\sqrt{v_t} + \epsilon)
```

Anyway, compute_gradients() likes below.  

```python
def compute_gradients(self, loss, var_list=None,
                        gate_gradients=GATE_OP,
                        aggregation_method=None,
                        colocate_gradients_with_ops=False,
                        grad_loss=None):

    if callable(loss):
      with backprop.GradientTape() as tape:
        if var_list is not None:
          tape.watch(var_list)
        loss_value = loss()

        # Scale loss if using a "mean" loss reduction and multiple towers.
        # Have to be careful to call distribute_lib.get_loss_reduction()
        # *after* loss() is evaluated, so we know what loss reduction it uses.
        # TODO(josh11b): Test that we handle weight decay in a reasonable way.
        if (distribute_lib.get_loss_reduction() ==
            variable_scope.VariableAggregation.MEAN):
          num_towers = distribution_strategy_context.get_distribution_strategy(
          ).num_towers
          if num_towers > 1:
            loss_value *= (1. / num_towers)

      if var_list is None:
        var_list = tape.watched_variables()
      grads = tape.gradient(loss_value, var_list, grad_loss)
      return list(zip(grads, var_list))

    # Non-callable/Tensor loss case
    if context.executing_eagerly():
      raise RuntimeError(
          "`loss` passed to Optimizer.compute_gradients should "
          "be a function when eager execution is enabled.")

    # Scale loss if using a "mean" loss reduction and multiple towers.
    if (distribute_lib.get_loss_reduction() ==
        variable_scope.VariableAggregation.MEAN):
      num_towers = distribution_strategy_context.get_distribution_strategy(
      ).num_towers
      if num_towers > 1:
        loss *= (1. / num_towers)

    if gate_gradients not in [Optimizer.GATE_NONE, Optimizer.GATE_OP,
                              Optimizer.GATE_GRAPH]:
      raise ValueError("gate_gradients must be one of: Optimizer.GATE_NONE, "
                       "Optimizer.GATE_OP, Optimizer.GATE_GRAPH.  Not %s" %
                       gate_gradients)
    self._assert_valid_dtypes([loss])
    if grad_loss is not None:
      self._assert_valid_dtypes([grad_loss])
    if var_list is None:
      var_list = (
          variables.trainable_variables() +
          ops.get_collection(ops.GraphKeys.TRAINABLE_RESOURCE_VARIABLES))
    else:
      var_list = nest.flatten(var_list)
    # pylint: disable=protected-access
    var_list += ops.get_collection(ops.GraphKeys._STREAMING_MODEL_PORTS)
    # pylint: enable=protected-access
    processors = [_get_processor(v) for v in var_list]
    if not var_list:
      raise ValueError("No variables to optimize.")
    var_refs = [p.target() for p in processors]
    grads = gradients.gradients(
        loss, var_refs, grad_ys=grad_loss,
        gate_gradients=(gate_gradients == Optimizer.GATE_OP),
        aggregation_method=aggregation_method,
        colocate_gradients_with_ops=colocate_gradients_with_ops)
    if gate_gradients == Optimizer.GATE_GRAPH:
      grads = control_flow_ops.tuple(grads)
    grads_and_vars = list(zip(grads, var_list))
    self._assert_valid_dtypes(
        [v for g, v in grads_and_vars
         if g is not None and v.dtype != dtypes.resource])
    return grads_and_vars
```

```python

```
