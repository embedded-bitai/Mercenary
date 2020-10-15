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
	B := op.Placeholder(root.SubScope("imat"), tf.Int32, op.PlaceholderShape(tf.MakeShape(2, 1)))

	product := op.Add(root, A, B)

	graph, err := root.Finalize()
	if err != nil {
		panic(err)
	}

	// Execute the graph in a session.
	sess, err := tf.NewSession(graph, nil)
	if err != nil {
		panic(err)
	}

	matA, err := tf.NewTensor([2][2]int32{{1, 2}, {-1, -2}})
	if err != nil {
		panic(err)
	}

	matB, err := tf.NewTensor([2][2]int32{{10, 3}, {100, 7}})
	if err != nil {
		panic(err)
	}

	outputs, err := sess.Run(map[tf.Output] * tf.Tensor{A: matA, B: matB, }, []tf.Output{product}, nil)
	if err != nil {
		panic(err)
	}

	for _, output := range outputs {
		fmt.Println(output.Value().([][]int32))
	}

	fmt.Println(c.Op.Name(), A.Op.Name(), B.Op.Name())
}
