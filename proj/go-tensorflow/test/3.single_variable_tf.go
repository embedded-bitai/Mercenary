package main

import (
	tf "github.com/tensorflow/tensorflow/tensorflow/go"
	"github.com/tensorflow/tensorflow/tensorflow/go/op"
	"fmt"
)

func main() {
	root := op.NewScope()
	//varElem := op.AssignVariableOp(root.SubScope("varElem"), VarHandleOp(s, tf.Int32, tf.ScalarShape()))
	test_val := op.Const(root.SubScope("test_val"), int32(7))
	variable := op.VarHandleOp(root.SubScope("var_elem"), tf.Int32, tf.ScalarShape())
	init := op.AssignVariableOp(root.SubScope("var_elem"), variable, test_val)
	read := op.ReadVariableOp(root.SubScope("var_elem"), variable, tf.Int32)
	//Placeholder(root.SubScope("varElem"), tf.Int32)
	//varNormal := op.RandomStandardNormal(root.SubScope("gauss_random"),
	//									variable, tf.Float, op.RandomStandardNormalSeed(zero))
	//varNormal := op.RandomStandardNormal(root.SubScope("var_elem"),
	//									variable, tf.Float, )

	graph, err := root.Finalize()
	if err != nil {
		panic(err)
	}

	// Execute the graph in a session.
	sess, err := tf.NewSession(graph, nil)
	if err != nil {
		panic(err)
	}

	output, err := sess.Run(nil, nil, []*tf.Operation{init})
	if err != nil {
		panic(err)
	}

	res, err := sess.Run(nil, []tf.Output{read}, nil)
	if err != nil {
		panic(err)
	}

	fmt.Println(variable)
	fmt.Println(output)

	fmt.Println(variable.Op.Name())
	fmt.Println(variable.Op.Output(0))

	fmt.Println(res)
	fmt.Println(res[0].Value())
}
