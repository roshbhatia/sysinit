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
  wezspawn [--wezterm <path>] [--gui-app <path>] [prog...]

The new window joins the workspace the GUI has focused and starts in the focused
pane's directory, so a spawn from a window manager lands in the session the user is
looking at rather than in the default one. prog runs instead of the shell.

With no GUI attached, a spawn lands in the headless mux server that wezterm cli
starts on demand and is never drawn, so wezspawn opens a GUI instead and leaves the
spawn to the next call.

--wezterm names the binary to drive, for a caller with none on PATH. A window manager
is one, so it passes its own store path rather than relying on a shell to prepend it.
--gui-app names the macOS bundle to open for that GUI; without it the wezterm binary
runs directly.

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

func hasGUI(clientsJSON string) bool {
	var clients []client
	if json.Unmarshal([]byte(clientsJSON), &clients) != nil {
		return false
	}
	return len(clients) > 0
}

// The GUI is started detached: it runs for as long as the window does, and a
// window manager's exec is not a place to hold that open.
func launch(bin, app string) error {
	if app != "" {
		return exec.Command("open", "-n", "-a", app).Start()
	}
	return exec.Command(bin, "start").Start()
}

func spawnArgs(found target, prog []string) []string {
	args := []string{"cli", "--no-auto-start", "spawn", "--new-window"}
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
	app := ""
	for len(args) > 0 && (args[0] == "--wezterm" || args[0] == "--gui-app") {
		if len(args) < 2 {
			fmt.Fprintf(os.Stderr, "wezspawn: %s needs a path\n", args[0])
			return 2
		}
		if args[0] == "--wezterm" {
			bin = args[1]
		} else {
			app = args[1]
		}
		args = args[2:]
	}
	if len(args) > 0 {
		switch args[0] {
		case "-h", "--help", "help":
			fmt.Print(usage)
			return 0
		}
	}

	clients, _ := muxOutput(bin, "cli", "--no-auto-start", "list-clients", "--format", "json")
	if !hasGUI(clients) {
		if err := launch(bin, app); err != nil {
			fmt.Fprintf(os.Stderr, "wezspawn: %v\n", err)
			return 1
		}
		return 0
	}

	panes, _ := muxOutput(bin, "cli", "--no-auto-start", "list", "--format", "json")

	out, err := muxOutput(bin, spawnArgs(focus(clients, panes), args)...)
	if err != nil {
		fmt.Fprintf(os.Stderr, "wezspawn: %v\n", err)
		return 1
	}
	fmt.Print(out)
	return 0
}
