package wezspawn

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

type muxCall struct {
	bin  string
	args []string
}

func stubMux(t *testing.T, clients, panes string) (*[]muxCall, *bool) {
	t.Helper()
	var calls []muxCall
	launched := false
	realQuery := queryMux
	realStart := startGUI
	queryMux = func(bin string, args ...string) (string, error) {
		calls = append(calls, muxCall{bin: bin, args: append([]string(nil), args...)})
		if len(args) < 3 {
			return "", fmt.Errorf("short mux command")
		}
		switch args[2] {
		case "list-clients":
			return clients, nil
		case "list":
			return panes, nil
		case "spawn":
			return "42\n", nil
		default:
			return "", fmt.Errorf("unexpected mux command %q", args[2])
		}
	}
	startGUI = func(string, string) error {
		launched = true
		return nil
	}
	t.Cleanup(func() {
		queryMux = realQuery
		startGUI = realStart
	})
	return &calls, &launched
}

func clientsFor(workspace string, pane int) string {
	return fmt.Sprintf(`[{"workspace":%q,"focused_pane_id":%d}]`, workspace, pane)
}

func panesFor(pane int, cwd string) string {
	return fmt.Sprintf(`[{"pane_id":%d,"cwd":"file://somehost%s"}]`, pane, cwd)
}

func TestRunJoinsTheFocusedWorkspaceAndDirectory(t *testing.T) {
	dir := t.TempDir()
	calls, launched := stubMux(t, clientsFor("review", 23), panesFor(23, dir))
	if code := Run([]string{"--wezterm", "/nix/store/wezterm", "nvim", "-R"}); code != 0 {
		t.Fatalf("Run exited %d", code)
	}
	if *launched {
		t.Fatal("Run started a second GUI")
	}
	last := (*calls)[len(*calls)-1]
	if last.bin != "/nix/store/wezterm" {
		t.Errorf("binary = %q", last.bin)
	}
	joined := strings.Join(last.args, " ")
	for _, want := range []string{"--new-window", "--workspace review", "--cwd " + dir, "-- nvim -R"} {
		if !strings.Contains(joined, want) {
			t.Errorf("spawn is missing %q: %s", want, joined)
		}
	}
}

func TestRunStartsTheGUIWithoutAClient(t *testing.T) {
	calls, launched := stubMux(t, "[]", "[]")
	if code := Run(nil); code != 0 {
		t.Fatalf("Run exited %d", code)
	}
	if !*launched {
		t.Fatal("Run did not start the GUI")
	}
	if len(*calls) != 1 || (*calls)[0].args[2] != "list-clients" {
		t.Errorf("mux calls = %+v", *calls)
	}
}

func TestFocusKeepsAWorkspaceWhenTheDirectoryIsUnavailable(t *testing.T) {
	found := focus(clientsFor("review", 4), panesFor(4, "/not/a/directory/here"))
	if found.workspace != "review" || found.cwd != "" {
		t.Errorf("focus = %+v", found)
	}
}

func TestMuxOutputHasATimeLimit(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "wezterm")
	if err := os.WriteFile(path, []byte("#!/bin/sh\nsleep 30\n"), 0o700); err != nil {
		t.Fatal(err)
	}

	real := muxTimeout
	t.Cleanup(func() { muxTimeout = real })
	muxTimeout = 150 * time.Millisecond

	started := time.Now()
	if _, err := muxOutput(path, "cli"); err == nil {
		t.Fatal("a mux that never answered returned no error")
	}
	if elapsed := time.Since(started); elapsed > 3*time.Second {
		t.Errorf("mux timeout took %s", elapsed)
	}
}
