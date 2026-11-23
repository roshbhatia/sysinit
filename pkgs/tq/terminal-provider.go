package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"github.com/roshbhatia/sysinit/pkgs/internal/terminalprovider"
)

type terminalInput struct {
	Workspace string          `json:"workspace"`
	Reference json.RawMessage `json:"reference,omitempty"`
	Cwd       string          `json:"cwd,omitempty"`
	Title     string          `json:"title,omitempty"`
	Argv      []string        `json:"argv,omitempty"`
}

type terminalResult struct {
	Reference json.RawMessage `json:"reference"`
	Live      bool            `json:"live"`
	Argv      []string        `json:"argv"`
	Workspace string          `json:"workspace,omitempty"`
}

func invokeTerminal(a attempt, action string, input terminalInput) (terminalResult, error) {
	var result terminalResult
	manifest, err := terminalprovider.Open(a.TerminalProvider)
	if err != nil {
		return result, err
	}
	input.Workspace = a.Terminal
	err = terminalprovider.Invoke(manifest, a.ID, action, input, &result)
	return result, err
}

func providerRefPath(a attempt, dir string) string {
	return filepath.Join(dir, a.ID+".terminal-provider")
}

func terminalTitle(a attempt) string {
	return fmt.Sprintf("%s · %s · %s", filepath.Base(a.Argv[0]), filepath.Base(a.Cwd), a.ID[:8])
}

func openProviderTerminal(a attempt, dir, self string) error {
	guard, err := lock(filepath.Join(dir, "terminal.lock"), false)
	if err != nil {
		return err
	}
	defer func() { _ = guard.Close() }()
	result, err := invokeTerminal(a, "spawn", terminalInput{
		Cwd:   a.Cwd,
		Title: terminalTitle(a),
		Argv:  []string{self, "--state", dir, "terminal-child", a.ID},
	})
	if err != nil {
		return err
	}
	if len(result.Reference) == 0 || string(result.Reference) == "null" {
		return errors.New("terminal provider returned no reference")
	}
	if err = save(providerRefPath(a, dir), result.Reference); err != nil {
		_, closeErr := invokeTerminal(a, "close", terminalInput{Reference: result.Reference})
		return errors.Join(err, closeErr)
	}
	return nil
}

func existingProviderTerminal(a attempt, dir, action string) (terminalResult, error) {
	var reference json.RawMessage
	if err := read(providerRefPath(a, dir), &reference); err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return terminalResult{}, nil
		}
		return terminalResult{}, err
	}
	return invokeTerminal(a, action, terminalInput{Reference: reference})
}

func hasTerminal(a attempt, dir string) (bool, error) {
	if a.TerminalProvider != "" {
		result, err := existingProviderTerminal(a, dir, "status")
		return result.Live, err
	}
	panes, err := terminalPanes(a, dir)
	return len(panes) > 0, err
}
