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
