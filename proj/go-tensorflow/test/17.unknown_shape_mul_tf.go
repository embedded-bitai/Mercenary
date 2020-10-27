package main

import (
	tf "github.com/tensorflow/tensorflow/tensorflow/go"
	"github.com/tensorflow/tensorflow/tensorflow/go/op"
	"fmt"
	"time"
	"math/rand"
)

func main() {
	root := op.NewScope()
	A := op.Placeholder(root.SubScope("imat"), tf.Float, op.PlaceholderShape(tf.MakeShape(2, 2)))
	B := op.Placeholder(root.SubScope("imat"), tf.Float, op.PlaceholderShape(tf.MakeShape(2)))
	C := op.Placeholder(root.SubScope("out"), tf.Float, op.PlaceholderShape(tf.ScalarShape()))

	res := op.Placeholder(root.SubScope("outmat"), tf.Int32, op.PlaceholderShape(tf.ScalarShape()))
	res2 := op.Placeholder(root.SubScope("outmat"), tf.Int32, op.PlaceholderShape(tf.ScalarShape()))
	//res3 := op.Placeholder(root.SubScope("outmat"), tf.Float, op.PlaceholderShape(tf.ScalarShape()))
	//res := op.Placeholder(root.SubScope("outmat"), tf.Int32, op.PlaceholderShape(tf.MakeShape(2)))

	Y := op.Placeholder(root.SubScope(""), tf.Float)

	mean := op.Mean(root.SubScope("mean"), A, res)
	dmean := op.Mean(root.SubScope("mean"), B, res2)
	//last := op.MatMul(root.SubScope("unknown"), dmean, Y)
	last := op.Mul(root.SubScope("unknown"), C, Y)

	fmt.Println(last)

	s1 := rand.NewSource(time.Now().UnixNano())
	r1 := rand.New(s1)
	fmt.Print("Random: ")
	fmt.Println(r1.Float64())

	fmt.Println("Loop Random")
	rand_num := [10]float32{}
	for i := 0; i < 10; i++ {
		rand_num[i] = r1.Float32()
		fmt.Println(rand_num[i])
	}

	//ready := op.MatMul(root.SubScope("outmat"), Y, res3)

	fmt.Print("Y shape: ")
	fmt.Println(Y.Shape())

	//fmt.Print("res3 shape: ")
	//fmt.Println(res3.Shape())

	graph, err := root.Finalize()
	if err != nil {
		panic(err)
	}

	// Execute the graph in a session.
	sess, err := tf.NewSession(graph, nil)
	if err != nil {
		panic(err)
	}

	matrix, err := tf.NewTensor([2][2]float32{{4.1, 2.7}, {6.3, 4.2}})
	if err != nil {
		panic(err)
	}

	//axis, err := tf.NewTensor([1][1]int32{{1}})
	//axis, err := tf.NewTensor(0)
	axis, err := tf.NewTensor(int32(0))
	if err != nil {
		panic(err)
	}

	outputs, err := sess.Run(map[tf.Output] * tf.Tensor{A: matrix, res: axis, }, []tf.Output{mean}, nil)
	if err != nil {
		panic(err)
	}

	for _, output := range outputs {
		//fmt.Println(output.Value().([][]int32))
		fmt.Println(output.Value())
	}

	tmp, err := tf.NewTensor(outputs[0].Value())
    if err != nil {
        panic(err)
    }

	axis2, err := tf.NewTensor(int32(0))
	if err != nil {
		panic(err)
	}

	outputs, err = sess.Run(map[tf.Output] * tf.Tensor{B: tmp, res2: axis2, }, []tf.Output{dmean}, nil)
	if err != nil {
		panic(err)
	}

	for _, output := range outputs {
		//fmt.Println(output.Value().([][]int32))
		fmt.Println(output.Value())
	}

	// It's for Unknown Shape
	tmp, err = tf.NewTensor(outputs[0].Value())
	if err != nil {
		panic(err)
	}

	y, err := tf.NewTensor(rand_num)
	if err != nil {
		panic(err)
	}

	outputs, err = sess.Run(map[tf.Output] * tf.Tensor{C: tmp, Y: y, }, []tf.Output{last}, nil)
    if err != nil {
        panic(err)
    }

    for _, output := range outputs {
        fmt.Println(output.Value())
    }
}
