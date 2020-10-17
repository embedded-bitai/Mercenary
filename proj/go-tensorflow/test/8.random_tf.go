package main

import (
	tf "github.com/tensorflow/tensorflow/tensorflow/go"
	"github.com/tensorflow/tensorflow/tensorflow/go/op"
	"fmt"
)

func main() {
	root := op.NewScope()
	//varElem := op.Placeholder(root.SubScope("varElem"), tf.Int32)
	test_val := op.Const(root.SubScope("test_val"), int32(7))
	variable := op.VarHandleOp(root.SubScope("var_elem"), tf.Int32, tf.ScalarShape())
	init := op.AssignVariableOp(root.SubScope("var_elem"), variable, test_val)
	read := op.ReadVariableOp(root.SubScope("var_elem"), variable, tf.Int32)

	//varNormal := op.RandomStandardNormal(root.SubScope("gauss_random"),
	//									op.VarHandleOp(root.SubScope("gauss_random"), tf.Float, tf.MakeShape(2, 2)),
	//									tf.Float)
	normal := op.RandomStandardNormal(root.SubScope("gauss_random"),
										op.Placeholder(root.SubScope("gauss_random"), tf.Int32, op.PlaceholderShape(tf.MakeShape(1))),
										tf.Float)
	varNormal := op.AssignVariableOp(root.SubScope("gauss_random"), normal,

	graph, err := root.Finalize()
	if err != nil {
		panic(err)
	}

	// Execute the graph in a session.
	sess, err := tf.NewSession(graph, nil)
	if err != nil {
		panic(err)
	}

	if _, err := sess.Run(nil, nil, []*tf.Operation{init}); err != nil {
        panic(err)
    }

    res, err := sess.Run(nil, []tf.Output{read}, nil)
    if err != nil {
        panic(err)
    }

	fmt.Println(varNormal.Op.Name())
	fmt.Println(res)
	fmt.Println(res[0].Value())

	res, err := sess.Run(nil, []tf.Output{varNormal}, nil)
	if err != nil {
		panic(err)
	}

	fmt.Println(res[0].Value())
}
