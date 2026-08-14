package store

import (
	"os"
	"path/filepath"
)

const (
	inputFile  = "last-input"
	promptFile = "last-prompt"
	outputFile = "last-output"
)

func Dir() string {
	base := os.Getenv("XDG_STATE_HOME")
	if base == "" {
		base = filepath.Join(os.Getenv("HOME"), ".local", "state")
	}
	return filepath.Join(base, "ask")
}

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

func SaveRun(input []byte, prompt string) error {
	if err := write(inputFile, input); err != nil {
		return err
	}
	return write(promptFile, []byte(prompt))
}

func SaveOutput(output []byte) error {
	return write(outputFile, output)
}

func Input() ([]byte, error) {
	return read(inputFile)
}

func Prompt() ([]byte, error) {
	return read(promptFile)
}

func Output() ([]byte, error) {
	return read(outputFile)
}
