// Package wezspawn opens a WezTerm window where the focused pane already is. `wezterm
// cli spawn --new-window` does not: it names the new window's workspace "default" and
// starts it in the home directory, whichever session the user is looking at.
package wezspawn

import (
	"context"
	"encoding/json"
	"fmt"
	"net/url"
	"os"
	"os/exec"
	"time"
)

const Summary = "open a WezTerm window in the focused workspace and directory"

const usage = `wezspawn: open a WezTerm window where the focused pane already is

Usage:
  wezspawn [--wezterm <path>] [prog...]

The new window joins the workspace the GUI has focused and starts in the focused
pane's directory, so a spawn from a window manager lands in the session the user is
looking at rather than in the default one. prog runs instead of the shell.

--wezterm names the binary to drive, for a caller with none on PATH. A window manager
is one, so it passes its own store path rather than relying on a shell to prepend it.

Prints the new pane's id. Exits 1 when the mux cannot be reached.
`

// muxTimeout bounds a call to the mux, so a spawn bound to a key never hangs the key.
var muxTimeout = 5 * time.Second

// client is the part of `cli list-clients` that names where the user is looking.
type client struct {
	Workspace     string `json:"workspace"`
	FocusedPaneID int    `json:"focused_pane_id"`
}

// pane is the part of `cli list` that names a pane's directory.
type pane struct {
	PaneID int    `json:"pane_id"`
	Cwd    string `json:"cwd"`
}

// target is where a new window should open. An empty field is one this spawn does not
// know, which leaves its flag off and lets WezTerm pick as it does today.
type target struct {
	workspace string
	cwd       string
}

// localPath turns a pane's cwd URL into a directory this host can open. A pane on a
// remote domain names a path that does not exist here, and passing it to a local window
// would fail the spawn, so it reports none.
func localPath(raw string) string {
	parsed, err := url.Parse(raw)
	if err != nil || parsed.Path == "" {
		return ""
	}
	info, err := os.Stat(parsed.Path)
	if err != nil || !info.IsDir() {
		return ""
	}
	return parsed.Path
}

// focus reads the workspace the GUI has focused and the directory of the pane in it.
func focus(clientsJSON, panesJSON string) target {
	var clients []client
	if json.Unmarshal([]byte(clientsJSON), &clients) != nil || len(clients) == 0 {
		return target{}
	}
	// The first client: one GUI answers here, and a second one is looking somewhere this
	// spawn has no way to choose between.
	found := target{workspace: clients[0].Workspace}

	var panes []pane
	if json.Unmarshal([]byte(panesJSON), &panes) != nil {
		return found
	}
	for _, p := range panes {
		if p.PaneID == clients[0].FocusedPaneID {
			found.cwd = localPath(p.Cwd)
			break
		}
	}
	return found
}

// spawnArgs builds the spawn call, naming only what is known.
func spawnArgs(found target, prog []string) []string {
	args := []string{"cli", "spawn", "--new-window"}
	if found.workspace != "" {
		args = append(args, "--workspace", found.workspace)
	}
	if found.cwd != "" {
		args = append(args, "--cwd", found.cwd)
	}
	if len(prog) > 0 {
		args = append(args, "--")
		args = append(args, prog...)
	}
	return args
}

func muxOutput(bin string, args ...string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), muxTimeout)
	defer cancel()
	cmd := exec.CommandContext(ctx, bin, args...)
	// The deadline kills wezterm, and this bounds the wait for the output pipes a
	// grandchild it left behind still holds open.
	cmd.WaitDelay = muxTimeout
	out, err := cmd.Output()
	if ctx.Err() != nil {
		return "", fmt.Errorf("no answer in %s", muxTimeout)
	}
	return string(out), err
}

// Run opens the window.
func Run(args []string) int {
	bin := "wezterm"
	if len(args) > 0 && args[0] == "--wezterm" {
		if len(args) < 2 {
			fmt.Fprintln(os.Stderr, "wezspawn: --wezterm needs a path")
			return 2
		}
		bin, args = args[1], args[2:]
	}
	if len(args) > 0 {
		switch args[0] {
		case "-h", "--help", "help":
			fmt.Print(usage)
			return 0
		}
	}

	// A mux that answers neither probe still gets a spawn: this is bound to a key, and a
	// window in the default workspace beats no window at all.
	clients, _ := muxOutput(bin, "cli", "list-clients", "--format", "json")
	panes, _ := muxOutput(bin, "cli", "list", "--format", "json")

	out, err := muxOutput(bin, spawnArgs(focus(clients, panes), args)...)
	if err != nil {
		fmt.Fprintf(os.Stderr, "wezspawn: %v\n", err)
		return 1
	}
	fmt.Print(out)
	return 0
}
