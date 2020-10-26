package main

import (
	tf "github.com/tensorflow/tensorflow/tensorflow/go"
	"github.com/tensorflow/tensorflow/tensorflow/go/op"
	"fmt"
)

func main() {
	root := op.NewScope()
	A := op.Placeholder(root.SubScope("imat"), tf.Int32, op.PlaceholderShape(tf.MakeShape(2, 2)))
	B := op.Placeholder(root.SubScope("imat"), tf.Int32, op.PlaceholderShape(tf.MakeShape(2)))

	res := op.Placeholder(root.SubScope("outmat"), tf.Int32, op.PlaceholderShape(tf.ScalarShape()))
	res2 := op.Placeholder(root.SubScope("outmat"), tf.Int32, op.PlaceholderShape(tf.ScalarShape()))
	//res := op.Placeholder(root.SubScope("outmat"), tf.Int32, op.PlaceholderShape(tf.MakeShape(2)))

	//product := op.MatMul(root, A, x)
	mean := op.Mean(root.SubScope("mean"), A, res)
	dmean := op.Mean(root.SubScope("mean"), B, res2)

	graph, err := root.Finalize()
	if err != nil {
		panic(err)
	}

	// Execute the graph in a session.
	sess, err := tf.NewSession(graph, nil)
	if err != nil {
		panic(err)
	}

	matrix, err := tf.NewTensor([2][2]int32{{4, 2}, {6, 4}})
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
}
