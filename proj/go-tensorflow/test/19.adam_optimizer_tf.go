package main

import (
	tf "github.com/tensorflow/tensorflow/tensorflow/go"
	"github.com/tensorflow/tensorflow/tensorflow/go/op"
	"fmt"
	"time"
	"math/rand"
)

// Adam Optimizer = ResourceApplyAdam
// ResourceApplyAdam(scope, var_, m, v, beta1_power, beta2_power, lr, beta1, beta2, epsilon, grad)
// ResourceApplyAdam(root.SubScope("adam"), 
func main() {
	root := op.NewScope()
	A := op.Placeholder(root.SubScope("imat"), tf.Float, op.PlaceholderShape(tf.MakeShape(2, 2)))
	B := op.Placeholder(root.SubScope("imat"), tf.Float, op.PlaceholderShape(tf.MakeShape(2)))

	res := op.Placeholder(root.SubScope("outmat"), tf.Int32, op.PlaceholderShape(tf.ScalarShape()))
	res2 := op.Placeholder(root.SubScope("outmat"), tf.Int32, op.PlaceholderShape(tf.ScalarShape()))
	//res3 := op.Placeholder(root.SubScope("outmat"), tf.Float, op.PlaceholderShape(tf.ScalarShape()))
	//res := op.Placeholder(root.SubScope("outmat"), tf.Int32, op.PlaceholderShape(tf.MakeShape(2)))

	mean := op.Mean(root.SubScope("mean"), A, res)
	dmean := op.Mean(root.SubScope("mean"), B, res2)

	//last := op.MatMul(root.SubScope("unknown"), dmean, Y)
	C := op.Placeholder(root.SubScope("unknown"), tf.Float, op.PlaceholderShape(tf.MakeShape(-1, 1)))
	Y := op.Placeholder(root.SubScope("unknown"), tf.Float)
	last := op.Mul(root.SubScope("unknown"), C, Y)
	fmt.Println(last)

	X := op.Placeholder(root.SubScope("out"), tf.Float, op.PlaceholderShape(tf.MakeShape(-1, 2)))
	D := op.Placeholder(root.SubScope("unknown"), tf.Float)
	//nby2 := op.AddV2(root.SubScope("unknown"), D, X)
	nby2 := op.Add(root.SubScope("unknown"), D, X)

	fmt.Print("D Shape Test: ")
	fmt.Println(D.Shape())

	fmt.Print("nby2 Shape Test: ")
	fmt.Println(nby2.Shape())

	// AdamOptimizer inherits Optimizer
	// tf.compat.v1.train.AdamOptimizer(
	//    learning_rate=0.001, beta1=0.9, beta2=0.999, epsilon=1e-08, use_locking=False,
	//    name='Adam'
	// )

	// train_step = tf.compat.v1.train.AdamOptimizer(0.001).minimize(cross_entropy)

	// Update '*var' according to the Adam algorithm.
	//
	// lr_t := \text{learning_rate} * \sqrt{(1 - beta_2^t) / (1 - beta_1^t)}
	// m_t := beta_1 * m_{t-1} + (1 - beta_1) * g
	// v_t := beta_2 * v_{t-1} + (1 - beta_2) * g * g
	// variable := variable - lr_t * m_t / (\sqrt{v_t} + \epsilon)
	//
	// Arguments:
	//  var_: Should be from a Variable().
	//  m: Should be from a Variable().
	//  v: Should be from a Variable().
	//  beta1_power: Must be a scalar.
	//  beta2_power: Must be a scalar.
	//  lr: Scaling factor. Must be a scalar.
	//  beta1: Momentum factor. Must be a scalar.
	//  beta2: Momentum factor. Must be a scalar.
	//  epsilon: Ridge term. Must be a scalar.
	//  grad: The gradient.
	//
	// Returns the created operation.

	//adamTest := ResourceApplyAdam(root.SubScope("adam"), var_, m, v, beta1_power, beta2_power, lr, beta1, beta2, epsilon, grad)
	adamTest := ResourceApplyAdam(root.SubScope("adam"), nil, m, v, beta1_power, beta2_power, lr, beta1, beta2, epsilon, grad)
	fmt.Print("Go Based Adam Optimizer: ")
	fmt.Println(adamTest.Shape())

	s1 := rand.NewSource(time.Now().UnixNano())
	r1 := rand.New(s1)
	fmt.Print("Random: ")
	fmt.Println(r1.Float64())

	fmt.Println("Loop Random")
	rand_num := [10]float32{}
	for i := 0; i < 10; i++ {
		rand_num[i] = r1.Float32()
		fmt.Println(rand_num[i])
	}

	fmt.Println("Random Matrix")
	rand_mat := [10][2]float32{{}}
	for j := 0; j < 10; j++ {
		for i := 0; i < 2; i++ {
			rand_mat[j][i] = r1.Float32()
		}
	}
	fmt.Println(rand_mat)

	//ready := op.MatMul(root.SubScope("outmat"), Y, res3)

	fmt.Print("Y shape: ")
	fmt.Println(Y.Shape())

	//fmt.Print("res3 shape: ")
	//fmt.Println(res3.Shape())

	graph, err := root.Finalize()
	if err != nil {
		panic(err)
	}

	// Execute the graph in a session.
	sess, err := tf.NewSession(graph, nil)
	if err != nil {
		panic(err)
	}

	matrix, err := tf.NewTensor([2][2]float32{{4.1, 2.7}, {6.3, 4.2}})
	if err != nil {
		panic(err)
	}

	//axis, err := tf.NewTensor([1][1]int32{{1}})
	//axis, err := tf.NewTensor(0)
	axis, err := tf.NewTensor(int32(0))
	if err != nil {
		panic(err)
	}

	outputs, err := sess.Run(map[tf.Output] * tf.Tensor{A: matrix, res: axis, }, []tf.Output{mean}, nil)
	if err != nil {
		panic(err)
	}

	for _, output := range outputs {
		//fmt.Println(output.Value().([][]int32))
		fmt.Println(output.Value())
	}

	tmp, err := tf.NewTensor(outputs[0].Value())
    if err != nil {
        panic(err)
    }

	axis2, err := tf.NewTensor(int32(0))
	if err != nil {
		panic(err)
	}

	outputs, err = sess.Run(map[tf.Output] * tf.Tensor{B: tmp, res2: axis2, }, []tf.Output{dmean}, nil)
	if err != nil {
		panic(err)
	}

	for _, output := range outputs {
		//fmt.Println(output.Value().([][]int32))
		fmt.Println(output.Value())
	}

	// It's for Unknown Shape
	tmp, err = tf.NewTensor(outputs[0].Value())
	if err != nil {
		panic(err)
	}

	y, err := tf.NewTensor(rand_num)
	if err != nil {
		panic(err)
	}

	outputs, err = sess.Run(map[tf.Output] * tf.Tensor{C: tmp, Y: y, }, []tf.Output{last}, nil)
    if err != nil {
        panic(err)
    }

    for _, output := range outputs {
        fmt.Println(output.Value())
    }

	// It's for Unknown by 2 Shape
	//const_2by2 := op.Const(root.SubScope("elem"), [][]float32{{3.3, 1.1}, {-2.2, 1.7}})
	tmp, err = tf.NewTensor([2]float32{3.3, -1.1})
	if err != nil {
		panic(err)
	}

	x, err := tf.NewTensor(rand_mat)
	if err != nil {
		panic(err)
	}

	outputs, err = sess.Run(map[tf.Output] * tf.Tensor{D: tmp, X: x, }, []tf.Output{nby2}, nil)
    if err != nil {
        panic(err)
    }

    for _, output := range outputs {
        fmt.Println(output.Value())
    }
}
