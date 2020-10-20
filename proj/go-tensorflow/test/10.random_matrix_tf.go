package main

import (
	tf "github.com/tensorflow/tensorflow/tensorflow/go"
	"github.com/tensorflow/tensorflow/tensorflow/go/op"
	"fmt"
)

func main() {
	root := op.NewScope()
	//varElem := op.Placeholder(root.SubScope("varElem"), tf.Int32)
	//test_val := op.Const(root.SubScope("test_val"), int32(7))
	//variable := op.VarHandleOp(root.SubScope("var_elem"), tf.Int32, tf.ScalarShape())
	//init := op.AssignVariableOp(root.SubScope("var_elem"), variable, test_val)
	//read := op.ReadVariableOp(root.SubScope("var_elem"), variable, tf.Int32)

	//varNormal := op.RandomStandardNormal(root.SubScope("gauss_random"),
	//									op.VarHandleOp(root.SubScope("gauss_random"), tf.Float, tf.MakeShape(2, 2)),
	//									tf.Float)
	//normal := op.RandomStandardNormal(root.SubScope("gauss_random"),
	//									op.Placeholder(root.SubScope("gauss_random"), tf.Int32, op.PlaceholderShape(tf.MakeShape(1))),
	//									tf.Float)
	//varNormal := op.AssignVariableOp(root.SubScope("gauss_random"), normal,
	//normal := op.RandomStandardNormal(root.SubScope("gauss_random"),
	//									op.Const(root.SubScope("gauss_random"), []float32{3}),
	//									tf.Float)
	//readNormal := op.ReadVariableOp(root.SubScope("gauss_random"), normal, tf.Float)
	//normal := op.RandomStandardNormal(root.SubScope("gauss_random"),
	//									op.Empty(root.SubScope("gauss_random"), test, tf.Float,
	//								tf.Float)
	normal := op.RandomStandardNormal(root.SubScope("gauss"),
										op.Const(root.SubScope("gauss"), []int32{2, 3}),
										tf.Float)

	w1 := op.VarHandleOp(root.SubScope("gauss"), tf.Float, tf.MakeShape(2, 3))
	assignW1 := op.AssignVariableOp(root.SubScope("gauss"), w1, normal)
	readW1 := op.ReadVariableOp(root.SubScope("gauss"), w1, tf.Float)
	// if VarHandleOp has tf.MakeShape(3) then need RandomStandardNormal's op.Const []int32{3}

	graph, err := root.Finalize()
	if err != nil {
		panic(err)
	}

	// Execute the graph in a session.
	sess, err := tf.NewSession(graph, nil)
	if err != nil {
		panic(err)
	}

	fmt.Println(normal.Op.Name())

	//res, err := sess.Run(nil, []tf.Output{varNormal}, nil)
	//if err != nil {
	//	panic(err)
	//}
	if _, err := sess.Run(nil, nil, []*tf.Operation{assignW1}); err != nil {
        panic(err)
	}

    resNormal, err := sess.Run(nil, []tf.Output{readW1}, nil)
    if err != nil {
        panic(err)
    }

	fmt.Println(resNormal)
	fmt.Println(resNormal[0].Value())
}
