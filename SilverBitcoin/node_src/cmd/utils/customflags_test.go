// Copyright 2025 Silver Bitcoin Foundation
// This file is part of go-ethereum.
// go-ethereum is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// go-ethereum is distributed in the hope that it will be useful,
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with go-ethereum. If not, see <http://www.gnu.org/licenses/>.

package utils

import (
	"os"
	"os/user"
	"testing"
)

func TestPathExpansion(t *testing.T) {
	user, _ := user.Current()
	tests := map[string]string{
		"/home/someuser/tmp": "/home/someuser/tmp",
		"~/tmp":              user.HomeDir + "/tmp",
		"~thisOtherUser/b/":  "~thisOtherUser/b",
		"$DDDXXX/a/b":        "/tmp/a/b",
		"/a/b/":              "/a/b",
	}
	os.Setenv("DDDXXX", "/tmp")
	for test, expected := range tests {
		got := expandPath(test)
		if got != expected {
			t.Errorf("test %s, got %s, expected %s\n", test, got, expected)
		}
	}
}
