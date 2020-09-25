package main

import (
	"../src/rest"
	"log"
)

func main() {
	log.Println("Main log....")
	log.Fatal(rest.RunAPI(":8000"))
}
