package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
)

func output(v any) error {
	e := json.NewEncoder(os.Stdout)
	e.SetIndent("", "  ")
	return e.Encode(v)
}

func call(name string, args ...string) ([]byte, error) {
	c := exec.Command(name, args...)
	c.Stderr = os.Stderr
	b, e := c.Output()
	if e != nil {
		return nil, fmt.Errorf("%s: %w", name, e)
	}
	return b, nil
}

func jsonCall(v any, name string, args ...string) error {
	b, e := call(name, args...)
	if e != nil {
		return e
	}
	return json.Unmarshal(b, v)
}
