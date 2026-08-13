// Package store keeps the last run's input and prompt. A piped command that produced the
// wrong answer is expensive to reproduce, and the input that fed it is usually gone by the
// time the caller reads the answer.
package store

import (
	"os"
	"path/filepath"
)

// The three things a rerun needs, and the one thing a reader asks for.
const (
	inputFile  = "last-input"
	promptFile = "last-prompt"
	outputFile = "last-output"
)

// Dir is where the last run is kept, under the state directory rather than the cache one,
// because a rerun is worth surviving a cache sweep.
func Dir() string {
	base := os.Getenv("XDG_STATE_HOME")
	if base == "" {
		base = filepath.Join(os.Getenv("HOME"), ".local", "state")
	}
	return filepath.Join(base, "ask")
}

// write one file, owner-readable only: what is piped into a model is as sensitive as the
// thing it was piped from.
func write(name string, data []byte) error {
	dir := Dir()
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(dir, name), data, 0o600)
}

func read(name string) ([]byte, error) {
	return os.ReadFile(filepath.Join(Dir(), name))
}

// SaveRun records what was sent, before it is sent, so a run that dies still leaves the
// input behind.
func SaveRun(input []byte, prompt string) error {
	if err := write(inputFile, input); err != nil {
		return err
	}
	return write(promptFile, []byte(prompt))
}

// SaveOutput records what came back.
func SaveOutput(output []byte) error {
	return write(outputFile, output)
}

// Input is what the last run was given.
func Input() ([]byte, error) {
	return read(inputFile)
}

// Prompt is what the last run was asked.
func Prompt() ([]byte, error) {
	return read(promptFile)
}

// Output is what the last run answered.
func Output() ([]byte, error) {
	return read(outputFile)
}
