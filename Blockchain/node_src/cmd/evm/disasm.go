// Copyright 2025 Silver Bitcoin Foundation
// This file is part of go-ethereum.
// go-ethereum is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// go-ethereum is distributed in the hope that it will be useful,
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with go-ethereum. If not, see <http://www.gnu.org/licenses/>.

package main

import (
	"errors"
	"fmt"
	"io/ioutil"
	"strings"

	"github.com/ethereum/go-ethereum/core/asm"
	"gopkg.in/urfave/cli.v1"
)

var disasmCommand = cli.Command{
	Action:    disasmCmd,
	Name:      "disasm",
	Usage:     "disassembles evm binary",
	ArgsUsage: "<file>",
}

func disasmCmd(ctx *cli.Context) error {
	var in string
	switch {
	case len(ctx.Args().First()) > 0:
		fn := ctx.Args().First()
		input, err := ioutil.ReadFile(fn)
		if err != nil {
			return err
		}
		in = string(input)
	case ctx.GlobalIsSet(InputFlag.Name):
		in = ctx.GlobalString(InputFlag.Name)
	default:
		return errors.New("missing filename or --input value")
	}

	code := strings.TrimSpace(in)
	fmt.Printf("%v\n", code)
	return asm.PrintDisassembled(code)
}
