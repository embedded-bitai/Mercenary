package main

import (
	tf "github.com/tensorflow/tensorflow/tensorflow/go"
	"github.com/tensorflow/tensorflow/tensorflow/go/op"
	"fmt"
)

func main() {
	root := op.NewScope()
	//sc := op.VariableShape(root.SubScope("shape"), c, tf.Int32)

	c := op.Const(root.SubScope("elem"), []int32{3})
	c2 := op.Const(root.SubScope("elem"), []int32{3, 3})
	c3 := op.Const(root.SubScope("elem"), [][]int32{{3, 3}, {2, 2}})

	test_val := op.Const(root.SubScope("test_val"), int32(7))
	variable := op.VarHandleOp(root.SubScope("var_elem"), tf.Int32, tf.ScalarShape())
	init := op.AssignVariableOp(root.SubScope("var_elem"), variable, test_val)
	read := op.ReadVariableOp(root.SubScope("var_elem"), variable, tf.Int32)

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

	output, err := sess.Run(nil, nil, []*tf.Operation{init})
	if err != nil {
		panic(err)
	}

	fmt.Print("output: ")
	fmt.Println(output)

	matA, err := tf.NewTensor([2][2]int32{{1, 2}, {-1, -2}})
	matB, err := tf.NewTensor([2][2]int32{{10, 3}, {100, 7}})

	sA := op.VariableShape(root.SubScope("shape"), A)

	outputs, err := sess.Run(map[tf.Output] * tf.Tensor{A: matA, B: matB, }, []tf.Output{product}, nil)
	if err != nil {
		panic(err)
	}

	for _, output := range outputs {
		fmt.Println(output.Value().([][]int32))
	}

	res, err := sess.Run(nil, []tf.Output{read}, nil)
	if err != nil {
		panic(err)
	}

	fmt.Println(res[0].Value())

	fmt.Print("product: ")
	outputShape := product.Shape()
	fmt.Println(outputShape)

	fmt.Print("c: ")
	outputShape = c.Shape()
	fmt.Println(outputShape)

	fmt.Print("A: ")
	outputShape = A.Shape()
	fmt.Println(outputShape)

	fmt.Print("c2: ")
	outputShape = c2.Shape()
	fmt.Println(outputShape)

	fmt.Print("c3: ")
	outputShape = c3.Shape()
	fmt.Println(outputShape)

	fmt.Print("variable: ")
	outputShape = variable.Shape()
	fmt.Println(outputShape)

	fmt.Println(sA)
	fmt.Println(matA)
}
