package main

import (
	tf "github.com/tensorflow/tensorflow/tensorflow/go"
	"github.com/tensorflow/tensorflow/tensorflow/go/op"
	"fmt"
)

func main() {
	root := op.NewScope()
	c := op.Const(root.SubScope("hello"), "Hello from TensorFlow version " + tf.Version())
	A := op.Placeholder(root.SubScope("imat"), tf.Int64, op.PlaceholderShape(tf.MakeShape(2, 2)))

	graph, err := root.Finalize()
	if err != nil {
		panic(err)
	}

	// Execute the graph in a session.
	sess, err := tf.NewSession(graph, nil)
	if err != nil {
		panic(err)
	}

	output, err := sess.Run(nil, []tf.Output{c}, nil)
	if err != nil {
		panic(err)
	}

	fmt.Println(output[0].Value())
	fmt.Println(c.Op.Name(), A.Op.Name())
}
