package controller

import (
	"github.com/jianzhangbjz/learn-operator/pkg/controller/learn"
)

func init() {
	// AddToManagerFuncs is a list of functions to create controllers and add them to a manager.
	AddToManagerFuncs = append(AddToManagerFuncs, learn.Add)
}
