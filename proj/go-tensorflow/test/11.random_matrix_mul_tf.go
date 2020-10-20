package main

import (
	tf "github.com/tensorflow/tensorflow/tensorflow/go"
	"github.com/tensorflow/tensorflow/tensorflow/go/op"
	"fmt"
)

func main() {
	root := op.NewScope()
	normalW1 := op.RandomStandardNormal(root.SubScope("gauss"),
										op.Const(root.SubScope("gauss"), []int32{2, 3}),
										tf.Float)

	w1 := op.VarHandleOp(root.SubScope("gauss"), tf.Float, tf.MakeShape(2, 3))
	assignW1 := op.AssignVariableOp(root.SubScope("gauss"), w1, normalW1)
	readW1 := op.ReadVariableOp(root.SubScope("gauss"), w1, tf.Float)

	normalW2 := op.RandomStandardNormal(root.SubScope("gauss"),
										op.Const(root.SubScope("gauss"), []int32{3, 1}),
										tf.Float)

	w2 := op.VarHandleOp(root.SubScope("gauss"), tf.Float, tf.MakeShape(3, 1))
	assignW2 := op.AssignVariableOp(root.SubScope("gauss"), w2, normalW2)
	readW2 := op.ReadVariableOp(root.SubScope("gauss"), w2, tf.Float)

	graph, err := root.Finalize()
	if err != nil {
		panic(err)
	}

	// Execute the graph in a session.
	sess, err := tf.NewSession(graph, nil)
	if err != nil {
		panic(err)
	}

	fmt.Println(normalW1.Op.Name())

	//res, err := sess.Run(nil, []tf.Output{varNormal}, nil)
	//if err != nil {
	//	panic(err)
	//}
	if _, err := sess.Run(nil, nil, []*tf.Operation{assignW1, assignW2}); err != nil {
        panic(err)
	}

    resNormal, err := sess.Run(nil, []tf.Output{readW1, readW2}, nil)
    if err != nil {
        panic(err)
    }

	fmt.Println(resNormal)
	fmt.Println(resNormal[0].Value())
	fmt.Println(resNormal[1].Value())
}
