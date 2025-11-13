// Copyright 2025 Silver Bitcoin Foundation

//go:build windows || js
// +build windows js

package metrics

// getProcessCPUTime returns 0 on Windows as there is no system call to resolve
func getProcessCPUTime() int64 {
	return 0
}
