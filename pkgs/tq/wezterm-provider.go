package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"

	"github.com/roshbhatia/go-utils/provider"
)

func weztermAttachArgs(workspace string) []string {
	binary, err := exec.LookPath("wezterm")
	if err != nil {
		binary = "wezterm"
	}
	domain := os.Getenv("TQ_WEZTERM_DOMAIN")
	if domain == "" {
		domain = muxDomain
	}
	return []string{binary, "connect", domain, "--workspace", workspace}
}

func weztermPane(ref terminalRef) (muxPane, bool, error) {
	identity, err := muxIdentity()
	if errors.Is(err, os.ErrNotExist) || (err == nil && identity != ref.Mux) {
		return muxPane{}, false, nil
	}
	if err != nil {
		return muxPane{}, false, err
	}
	panes, err := muxPanes()
	for _, pane := range panes {
		if pane.PaneID == ref.PaneID {
			return pane, true, nil
		}
	}
	return muxPane{}, false, err
}

func spawnWezTerm(input terminalInput, shared bool) (terminalRef, error) {
	placement := []string{"--new-window", "--workspace", input.Workspace}
	var ref terminalRef
	if shared {
		var err error
		ref.Mux, err = muxIdentity()
		if err != nil {
			return ref, err
		}
		panes, err := muxPanes()
		if err != nil {
			return ref, err
		}
		for _, pane := range panes {
			if pane.Workspace == input.Workspace {
				placement = []string{"--window-id", strconv.Itoa(pane.WindowID)}
				break
			}
		}
	}
	args := append([]string{"spawn"}, placement...)
	args = append(args, "--cwd", input.Cwd, "--")
	command := wezterm(append(args, input.Argv...)...)
	command.Stderr = os.Stderr
	out, err := command.Output()
	if err != nil || !shared {
		return ref, err
	}
	paneID := strings.TrimSpace(string(out))
	ref.PaneID, err = strconv.Atoi(paneID)
	if err != nil {
		return ref, fmt.Errorf("invalid mux pane ID %q: %w", paneID, err)
	}
	if err = wezterm("set-tab-title", "--pane-id", paneID, "--", input.Title).Run(); err != nil {
		fmt.Fprintln(os.Stderr, "tq: set terminal tab title:", err)
	}
	return ref, nil
}

func weztermAction(capability string, input terminalInput) (terminalResult, error) {
	if capability == "terminal.spawn" {
		if input.Workspace == "" || input.Cwd == "" || len(input.Argv) == 0 {
			return terminalResult{}, errors.New("spawn requires workspace, working directory, and argv")
		}
		ref, err := spawnWezTerm(input, true)
		if err != nil {
			return terminalResult{}, err
		}
		raw, err := json.Marshal(ref)
		return terminalResult{Reference: raw}, err
	}
	if capability == "terminal.review" {
		command := exec.Command("agent-diff", "--review", "--allow-directory", "--cwd", input.Cwd, "--background")
		if out, err := command.CombinedOutput(); err != nil {
			return terminalResult{}, fmt.Errorf("agent-diff: %w %s", err, strings.TrimSpace(string(out)))
		}
		return terminalResult{}, nil
	}

	var ref terminalRef
	if err := json.Unmarshal(input.Reference, &ref); err != nil {
		return terminalResult{}, err
	}
	pane, live, err := weztermPane(ref)
	if err != nil || !live {
		return terminalResult{}, err
	}
	paneID := strconv.Itoa(pane.PaneID)
	switch capability {
	case "terminal.status":
		return terminalResult{Live: true}, nil
	case "terminal.focus":
		err := wezterm("activate-pane", "--pane-id", paneID).Run()
		return terminalResult{Live: err == nil, Argv: weztermAttachArgs(pane.Workspace), Workspace: pane.Workspace}, err
	case "terminal.close":
		return terminalResult{}, wezterm("kill-pane", "--pane-id", paneID).Run()
	default:
		return terminalResult{}, fmt.Errorf("unsupported WezTerm capability %q", capability)
	}
}

func serveWezTerm() error {
	var request provider.Request
	if err := json.NewDecoder(os.Stdin).Decode(&request); err != nil {
		return err
	}
	if request.Version != provider.Version || request.Kind != "request" {
		return errors.New("expected a provider/v1 request")
	}
	result := provider.Result{
		Version: provider.Version, Kind: "result", RequestID: request.RequestID, Status: provider.ResultOK,
	}
	var input terminalInput
	err := json.Unmarshal(request.Input, &input)
	if err == nil {
		var response terminalResult
		response, err = weztermAction(request.Capability, input)
		if err == nil {
			result.Output, err = json.Marshal(response)
		}
	}
	if err != nil {
		result.Status, result.Message = provider.ResultError, err.Error()
	}
	return json.NewEncoder(os.Stdout).Encode(result)
}
