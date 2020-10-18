package main

import (
	tf "github.com/tensorflow/tensorflow/tensorflow/go"
	"github.com/tensorflow/tensorflow/tensorflow/go/op"
	"fmt"
)

func main() {
	s := op.NewScope()
	input := op.Placeholder(s, tf.Float)

    output := op.MatMul(s,
        op.Const(s, [][]float32{{10}, {20}}),
        input,
        op.MatMulTransposeB(true))

    if s.Err() != nil {
        panic(s.Err())
    }

	fmt.Print("Check Shape: ")
    fmt.Println(output.Shape())
}
