package main

import (
	tf "github.com/tensorflow/tensorflow/tensorflow/go"
	"github.com/tensorflow/tensorflow/tensorflow/go/op"
	"fmt"
)

func main() {
	root := op.NewScope()
	c := op.Const(root.SubScope("hello"), "Hello from TensorFlow version " + tf.Version())
	A := op.Placeholder(root.SubScope("imat"), tf.Int32, op.PlaceholderShape(tf.MakeShape(2, 2)))
	x := op.Placeholder(root.SubScope("imat"), tf.Int32, op.PlaceholderShape(tf.MakeShape(2, 1)))

	product := op.MatMul(root, A, x)

	graph, err := root.Finalize()
	if err != nil {
		panic(err)
	}

	// Execute the graph in a session.
	sess, err := tf.NewSession(graph, nil)
	if err != nil {
		panic(err)
	}

	matrix, err := tf.NewTensor([2][2]int32{{1, 2}, {-1, -2}})
	if err != nil {
		panic(err)
	}

	column, err := tf.NewTensor([2][1]int32{{10}, {100}})
	if err != nil {
		panic(err)
	}

	outputs, err := sess.Run(map[tf.Output] * tf.Tensor{A: matrix, x: column, }, []tf.Output{product}, nil)
	if err != nil {
		panic(err)
	}

	for _, output := range outputs {
		fmt.Println(output.Value().([][]int32))
	}

	fmt.Println(c.Op.Name(), A.Op.Name(), x.Op.Name())
}
