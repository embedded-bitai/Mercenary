package main

import (
	tf "github.com/tensorflow/tensorflow/tensorflow/go"
	"github.com/tensorflow/tensorflow/tensorflow/go/op"
	"fmt"
)

func main() {
	root := op.NewScope()
	c := op.Const(root.SubScope("elem"), []int32{3})
	//test := op.Placeholder(root.SubScope("elem"), tf.Int32, op.PlaceholderShape(tf.MakeShape(1)))
	//n1 := op.RandomStandardNormal(root.SubScope("gauss_random"),  tf.Int64)
	//output := op.Placeholder(root.SubScope("elem"), tf.Int32, op.PlaceholderShape(tf.MakeShape(1)))

	graph, err := root.Finalize()
	if err != nil {
		panic(err)
	}

	// Execute the graph in a session.
	sess, err := tf.NewSession(graph, nil)
	if err != nil {
		panic(err)
	}

	//valA, err := tf.NewTensor([]int32{1})
	//if err != nil {
	//	panic(err)
	//}

	output, err := sess.Run(nil, []tf.Output{c}, nil)
	if err != nil {
		panic(err)
	}

	fmt.Println(output[0].Value())

	fmt.Println(c.Op.Name())
}
