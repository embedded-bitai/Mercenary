package main

import (
	tf "github.com/tensorflow/tensorflow/tensorflow/go"
	"github.com/tensorflow/tensorflow/tensorflow/go/op"
	"fmt"
)

func main() {
	root := op.NewScope()

	normalW1 := op.RandomStandardNormal(root.SubScope("gauss"),
										op.Const(root.SubScope("gauss"), []int32{2, 3}), tf.Float)

	w1 := op.VarHandleOp(root.SubScope("gauss"), tf.Float, tf.MakeShape(2, 3))
	assignW1 := op.AssignVariableOp(root.SubScope("gauss"), w1, normalW1)
	readW1 := op.ReadVariableOp(root.SubScope("gauss"), w1, tf.Float)

	normalW2 := op.RandomStandardNormal(root.SubScope("gauss"),
										op.Const(root.SubScope("gauss"), []int32{3, 1}), tf.Float)

	w2 := op.VarHandleOp(root.SubScope("gauss"), tf.Float, tf.MakeShape(3, 1))
	assignW2 := op.AssignVariableOp(root.SubScope("gauss"), w2, normalW2)
	readW2 := op.ReadVariableOp(root.SubScope("gauss"), w2, tf.Float)

	x := op.Const(root.SubScope("constElem"), [][]float32{{0.7, 0.9}})

	W1 := op.Placeholder(root.SubScope("elem"), tf.Float, op.PlaceholderShape(tf.MakeShape(2, 3)))
	W2 := op.Placeholder(root.SubScope("elem"), tf.Float, op.PlaceholderShape(tf.MakeShape(3, 1)))

	a := op.MatMul(root.SubScope("elem"), x, W1)
	y := op.MatMul(root.SubScope("elem"), a, W2)

	MIN := op.Placeholder(root.SubScope("elem"), tf.Float, op.PlaceholderShape(tf.MakeShape(1, 1)))
	MAX := op.Placeholder(root.SubScope("elem"), tf.Float, op.PlaceholderShape(tf.MakeShape(1, 1)))
	Y := op.Placeholder(root.SubScope("elem"), tf.Float, op.PlaceholderShape(tf.MakeShape(1, 1)))

	// func ClipByValue(scope *Scope, t tf.Output, clip_value_min tf.Output, clip_value_max tf.Output) (output tf.Output)
	clipped := op.ClipByValue(root.SubScope("elem"), Y, MIN, MAX)
	log_value := op.Log(root.SubScope("elem"), clipped)

	fmt.Println("x Shape: ")
	fmt.Println(x.Shape())

	graph, err := root.Finalize()
	if err != nil {
		panic(err)
	}

	// Execute the graph in a session.
	sess, err := tf.NewSession(graph, nil)
	if err != nil {
		panic(err)
	}

	//min, err := tf.NewTensor([1][1]float32{{1.0 / 10000000000.0}})
	min, err := tf.NewTensor([1][1]float32{{1.0 / 10.0}})
    if err != nil {
        panic(err)
    }

    max, err := tf.NewTensor([1][1]float32{{1.0}})
    if err != nil {
        panic(err)
    }

	fmt.Println(normalW1.Op.Name())

	//res, err := sess.Run(nil, []tf.Output{varNormal}, nil)
	//if err != nil {
	//	panic(err)
	//}
	if _, err := sess.Run(nil, nil, []*tf.Operation{assignW1}); err != nil {
        panic(err)
	}

    resW1, err := sess.Run(nil, []tf.Output{readW1}, nil)
    if err != nil {
        panic(err)
    }

	if _, err := sess.Run(nil, nil, []*tf.Operation{assignW2}); err != nil {
        panic(err)
	}

    resW2, err := sess.Run(nil, []tf.Output{readW2}, nil)
    if err != nil {
        panic(err)
    }

	fmt.Print("resW1: ")
	fmt.Println(resW1[0].Value())
	fmt.Println(resW1[0].Shape())

	fmt.Print("resW2: ")
	fmt.Println(resW2[0].Value())
	fmt.Println(resW2[0].Shape())

	//matW1 := op.DeepCopy(root.SubScope("elem"), resW1[0])
	//matW2 := op.DeepCopy(root.SubScope("elem"), resW2[0])

	outputs, err := sess.Run(map[tf.Output] * tf.Tensor{W1: resW1[0], W2: resW2[0], }, []tf.Output{y}, nil)
	if err != nil {
		panic(err)
	}

	for _, output := range outputs {
		fmt.Println(output.Value())
		fmt.Println(output.Shape())
	}

	fmt.Println(outputs)
	fmt.Println(y)

	tmp, err := tf.NewTensor(outputs[0].Value().([][]float32))
	if err != nil {
        panic(err)
    }

	outputs, err = sess.Run(map[tf.Output] * tf.Tensor{Y: tmp, MIN: min, MAX: max, }, []tf.Output{clipped}, nil)
    if err != nil {
        panic(err)
    }

    for _, output := range outputs {
        fmt.Println(output.Value().([][]float32))
		fmt.Print("output shape: ")
		fmt.Println(output.Shape())
    }

	fmt.Print("log value: ");
	fmt.Println(log_value);

	//outputs, err = sess.Run(map[tf.Output] * tf.Tensor{CLIPPED: outputs[0], }, []tf.Output{log_value}, nil)
	outputs, err = sess.Run(map[tf.Output] * tf.Tensor{Y: tmp, MIN: min, MAX: max, }, []tf.Output{log_value}, nil)
    if err != nil {
        panic(err)
    }

    for _, output := range outputs {
        fmt.Println(output.Value())
    }
	/*
	outputs, err = sess.Run(map[tf.Output] * tf.Tensor{CLIPPED: tmp, }, []tf.Output{log_value}, nil)
    if err != nil {
        panic(err)
    }

    for _, output := range outputs {
        fmt.Println(output.Value().([][]float32))
    }
	*/

	//fmt.Println("clipped Shape: ")
	//fmt.Println(clipped.Shape())
	//fmt.Println(clipped)

}
