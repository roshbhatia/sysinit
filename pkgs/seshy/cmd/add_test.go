package cmd

import (
	"testing"
)

func TestAddCommand(t *testing.T) {
	// This is a smoke test - full functionality tested in session_test.go
	if addCmd == nil {
		t.Error("addCmd should not be nil")
	}

	if addCmd.Use != "add <name> [repos...]" {
		t.Errorf("Expected Use='add <name> [repos...]', got '%s'", addCmd.Use)
	}

	if addCmd.Short == "" {
		t.Error("addCmd should have Short description")
	}
}

func TestAddCommandHasValidArgsFunction(t *testing.T) {
	if addCmd.ValidArgsFunction == nil {
		t.Error("addCmd should have ValidArgsFunction for tab completion")
	}
}
