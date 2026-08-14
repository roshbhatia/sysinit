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

var muxTimeout = 5 * time.Second

type client struct {
	Workspace     string `json:"workspace"`
	FocusedPaneID int    `json:"focused_pane_id"`
}

type pane struct {
	PaneID int    `json:"pane_id"`
	Cwd    string `json:"cwd"`
}

type target struct {
	workspace string
	cwd       string
}

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

func focus(clientsJSON, panesJSON string) target {
	var clients []client
	if json.Unmarshal([]byte(clientsJSON), &clients) != nil || len(clients) == 0 {
		return target{}
	}

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

	cmd.WaitDelay = muxTimeout
	out, err := cmd.Output()
	if ctx.Err() != nil {
		return "", fmt.Errorf("no answer in %s", muxTimeout)
	}
	return string(out), err
}

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
