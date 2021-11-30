mac:learn-operator jianzhang$ cat test.go 
package main

import (
	"fmt"
    "github.com/blang/semver"
)

func main() {
    v, _:= semver.ParseTolerant("4.9.0-0.nightly-2021-07-26-220837")
    fmt.Println(v)
    v.Minor++
    fmt.Println(v)
    max, _ := semver.ParseTolerant("4.9")
    fmt.Print(max.GTE(v))

}
