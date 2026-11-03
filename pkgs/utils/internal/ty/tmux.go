package ty

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"
)

func runTmux(args []string, stdin io.Reader, stdout io.Writer, runner commandRunner) error {
	if len(args) == 0 || args[0] == "--help" || args[0] == "help" {
		_, err := io.WriteString(stdout, "ty tmux: inspect and control tmux sessions and panes\n\nUsage: ty tmux catalog|sessions|panes|session|pane|picker\n")
		return err
	}
	switch args[0] {
	case "catalog":
		return runTmuxCatalog(stdout, runner)
	case "sessions":
		return runSessions(stdout, runner)
	case "panes":
		return runTmuxPanes(stdout, runner)
	case "snapshot":
		return tmuxSnapshot(stdout, runner)
	case "session":
		return runTmuxSession(args[1:], stdout, runner)
	case "pane":
		return runTmuxPane(args[1:], stdin, stdout, runner)
	case "picker":
		if len(args) != 1 {
			return invalidUsage("usage: ty tmux picker")
		}
		return runTmuxPicker(stdout, runner)
	case "process", "navigate", "resize", "spawn", "select", "scrollback":
		return runTmuxAction(args, stdout, runner)
	default:
		return invalidUsage("unknown tmux command %q", args[0])
	}
}

func runTmuxCatalog(stdout io.Writer, runner commandRunner) error {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	sessions, err := listSessions(ctx, runner)
	if err != nil {
		return err
	}
	panes, err := listTmuxPanes(ctx, runner)
	if err != nil {
		return err
	}

	return writeJSON(stdout, catalog{Version: protocolVersion, Sessions: sessions, Panes: panes})
}

func runTmuxPanes(stdout io.Writer, runner commandRunner) error {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	panes, err := listTmuxPanes(ctx, runner)
	if err != nil {
		return err
	}
	return writeJSON(stdout, panesResult{Version: protocolVersion, Panes: panes})
}

func listTmuxPanes(ctx context.Context, runner commandRunner) ([]json.RawMessage, error) {
	panesText, err := runner(ctx, "tmux", []string{"list-panes", "-a", "-F", "#{pane_id}\t#{session_name}\t#{window_index}\t#{pane_index}\t#{pane_active}"}, nil)
	if err != nil {
		return nil, fmt.Errorf("list tmux panes: %w", err)
	}
	panes := make([]json.RawMessage, 0)
	for _, line := range strings.Split(strings.TrimSpace(string(panesText)), "\n") {
		if line == "" {
			continue
		}
		fields := strings.Split(line, "\t")
		if len(fields) != 5 {
			return nil, fmt.Errorf("decode tmux pane row: expected 5 fields, got %d", len(fields))
		}
		active := fields[4] == "1"
		row, err := json.Marshal(map[string]any{
			"pane_id": fields[0], "session_name": fields[1], "window_index": fields[2],
			"workspace": fields[1], "pane_index": fields[3], "pane_active": active,
		})
		if err != nil {
			return nil, fmt.Errorf("encode tmux pane row: %w", err)
		}
		panes = append(panes, row)
	}
	return panes, nil
}

func runTmuxSession(args []string, stdout io.Writer, runner commandRunner) error {
	if len(args) != 2 || (args[0] != "open" && args[0] != "switch") {
		return invalidUsage("usage: ty tmux session open|switch <session-id-or-name>")
	}
	action := args[0]
	target := strings.TrimSpace(args[1])
	if target == "" {
		return invalidUsage("session id or name cannot be empty")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	planJSON, err := runner(ctx, "sy", []string{"open", target, "--format", "json"}, nil)
	if err != nil {
		return fmt.Errorf("resolve seshy open plan: %w", err)
	}
	var plan openPlan
	if err := json.Unmarshal(planJSON, &plan); err != nil {
		return fmt.Errorf("decode seshy open plan: %w", err)
	}
	if plan.Version != "seshy.open/v1" {
		return fmt.Errorf("unsupported seshy open plan version %q", plan.Version)
	}
	if !strings.HasPrefix(plan.ID, "seshy:") || strings.TrimPrefix(plan.ID, "seshy:") == "" {
		return fmt.Errorf("invalid seshy session id %q", plan.ID)
	}
	if !filepath.IsAbs(plan.CWD) {
		return fmt.Errorf("seshy open plan cwd must be absolute: %q", plan.CWD)
	}
	for key, value := range plan.Environment {
		if !validEnvironmentKey(key) || strings.ContainsRune(value, '\x00') {
			return fmt.Errorf("invalid environment entry %q", key)
		}
	}
	for _, arg := range plan.Command {
		if strings.ContainsRune(arg, '\x00') {
			return errors.New("seshy open plan command contains a null byte")
		}
	}

	workspace := strings.TrimPrefix(plan.ID, "seshy:")
	if !validSessionName(workspace) {
		return fmt.Errorf("seshy session id is not safe for tmux: %q", workspace)
	}
	if action == "switch" {
		if _, err := runner(ctx, "tmux", []string{"has-session", "-t", "=" + workspace}, nil); err == nil {
			if _, err := selectTmuxSession(ctx, runner, workspace, plan.CWD); err != nil {
				return fmt.Errorf("switch to tmux session %q: %w", plan.ID, err)
			}
			panes, listErr := listTmuxPanes(ctx, runner)
			if listErr != nil {
				return listErr
			}
			paneID, findErr := findTmuxWorkspacePane(panes, workspace)
			if findErr != nil {
				return findErr
			}
			opened := os.Getenv("TMUX") == ""
			return writeJSON(stdout, actionResult{
				Version: protocolVersion, Action: "session.switch", SessionID: plan.ID,
				Workspace: workspace, CWD: plan.CWD, PaneID: paneID, Opened: &opened,
			})
		}
	}
	command := plan.Command
	if len(command) == 0 {
		command = []string{loginShell(), "-l"}
	}
	created := false
	if _, err := runner(ctx, "tmux", []string{"has-session", "-t", "=" + workspace}, nil); err != nil {
		newArgs := []string{"new-session", "-d", "-P", "-F", "#{pane_id}", "-s", workspace, "-c", plan.CWD}
		for _, key := range sortedKeys(plan.Environment) {
			newArgs = append(newArgs, "-e", key+"="+plan.Environment[key])
		}
		newArgs = append(newArgs, shellCommand(command))
		if _, err := runner(ctx, "tmux", newArgs, nil); err != nil {
			return fmt.Errorf("open tmux session %q: %w", plan.ID, err)
		}
		created = true
	}
	if _, err := selectTmuxSession(ctx, runner, workspace, plan.CWD); err != nil {
		return fmt.Errorf("select tmux session %q: %w", plan.ID, err)
	}
	panes, err := listTmuxPanes(ctx, runner)
	if err != nil {
		return err
	}
	paneID, err := findTmuxWorkspacePane(panes, workspace)
	if err != nil {
		return err
	}
	resultAction := "session.open"
	opened := created || os.Getenv("TMUX") == ""
	if action == "switch" {
		resultAction = "session.switch"
	}
	return writeJSON(stdout, actionResult{
		Version: protocolVersion, Action: resultAction, SessionID: plan.ID,
		Workspace: workspace, CWD: plan.CWD, PaneID: string(paneID), Opened: &opened,
	})
}

func findTmuxWorkspacePane(panes []json.RawMessage, workspace string) (string, error) {
	for _, raw := range panes {
		var pane struct {
			PaneID    string `json:"pane_id"`
			Workspace string `json:"session_name"`
		}
		if err := json.Unmarshal(raw, &pane); err != nil {
			return "", fmt.Errorf("decode tmux pane: %w", err)
		}
		if pane.Workspace == workspace {
			return pane.PaneID, nil
		}
	}
	return "", nil
}

func validSessionName(value string) bool {
	if value == "" || strings.HasPrefix(value, "-") || strings.ContainsAny(value, ":\t\r\n") {
		return false
	}
	return true
}

func runTmuxPane(args []string, stdin io.Reader, stdout io.Writer, runner commandRunner) error {
	if len(args) == 0 {
		return invalidUsage("expected pane subcommand: split, spawn, read, send, focus, or close")
	}
	switch args[0] {
	case "split":
		return runTmuxSplit(args[1:], false, stdout, runner)
	case "spawn":
		return runTmuxSplit(args[1:], true, stdout, runner)
	case "read":
		return runTmuxRead(args[1:], stdout, runner)
	case "send":
		return runTmuxSend(args[1:], stdin, stdout, runner)
	case "focus":
		return runTmuxPaneAction(args[1:], "focus", stdout, runner)
	case "close":
		return runTmuxPaneAction(args[1:], "close", stdout, runner)
	default:
		return invalidUsage("unknown pane command %q", args[0])
	}
}

func runTmuxSplit(args []string, spawn bool, stdout io.Writer, runner commandRunner) error {
	var paneID, direction, cwd string
	percent := 0
	var command []string
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--direction":
			i++
			if i >= len(args) {
				return invalidUsage("--direction requires right or down")
			}
			direction = args[i]
		case "--cwd":
			i++
			if i >= len(args) {
				return invalidUsage("--cwd requires a path")
			}
			cwd = args[i]
		case "--percent":
			i++
			if i >= len(args) {
				return invalidUsage("--percent requires a value from 1 to 99")
			}
			value, err := strconv.Atoi(args[i])
			if err != nil || value < 1 || value > 99 {
				return invalidUsage("--percent must be between 1 and 99")
			}
			percent = value
		case "--":
			command = append([]string(nil), args[i+1:]...)
			i = len(args)
		default:
			if strings.HasPrefix(args[i], "-") || paneID != "" {
				return invalidUsage("unexpected split argument %q", args[i])
			}
			paneID = args[i]
		}
	}
	if _, err := parseTmuxPaneID(paneID); err != nil {
		return err
	}
	if direction != "right" && direction != "down" && direction != "left" && direction != "up" {
		return invalidUsage("--direction must be right, down, left, or up")
	}
	if cwd != "" && !filepath.IsAbs(cwd) {
		return invalidUsage("--cwd must be an absolute path")
	}
	if spawn && len(command) == 0 {
		return invalidUsage("pane spawn requires a command after --")
	}
	if !spawn && len(command) > 0 {
		return invalidUsage("pane split does not accept a command; use pane spawn")
	}
	for _, arg := range command {
		if strings.ContainsRune(arg, '\x00') {
			return invalidUsage("command contains a null byte")
		}
	}
	argsOut := []string{"split-window", "-P", "-F", "#{pane_id}", "-t", paneID}
	if direction == "right" || direction == "left" {
		argsOut = append(argsOut, "-h")
	} else {
		argsOut = append(argsOut, "-v")
	}
	if direction == "left" || direction == "up" {
		argsOut = append(argsOut, "-b")
	}
	if cwd != "" {
		argsOut = append(argsOut, "-c", cwd)
	}
	if percent > 0 {
		argsOut = append(argsOut, "-p", strconv.Itoa(percent))
	}
	if len(command) > 0 {
		argsOut = append(argsOut, shellCommand(command))
	}
	newPane, err := call(runner, "tmux", argsOut, nil)
	if err != nil {
		return fmt.Errorf("split pane %s: %w", paneID, err)
	}
	newPane = []byte(strings.TrimSpace(string(newPane)))
	if _, err := parseTmuxPaneID(string(newPane)); err != nil {
		return fmt.Errorf("tmux returned invalid pane id: %w", err)
	}
	action := "pane.split"
	if spawn {
		action = "pane.spawn"
	}
	return writeJSON(stdout, actionResult{Version: protocolVersion, Action: action, PaneID: string(newPane)})
}

func runTmuxRead(args []string, stdout io.Writer, runner commandRunner) error {
	if len(args) != 1 {
		return invalidUsage("usage: ty tmux pane read <pane-id>")
	}
	if _, err := parseTmuxPaneID(args[0]); err != nil {
		return err
	}
	text, err := call(runner, "tmux", []string{"capture-pane", "-p", "-S", "-", "-t", args[0]}, nil)
	if err != nil {
		return fmt.Errorf("read pane %s: %w", args[0], err)
	}
	_, err = stdout.Write(text)
	return err
}

func runTmuxSend(args []string, stdin io.Reader, stdout io.Writer, runner commandRunner) error {
	submit := false
	if len(args) > 0 && args[0] == "--submit" {
		submit = true
		args = args[1:]
	}
	if len(args) == 0 {
		return invalidUsage("usage: ty tmux pane send [--submit] <pane-id> [text...]")
	}
	paneID := args[0]
	if _, err := parseTmuxPaneID(paneID); err != nil {
		return err
	}
	var text []byte
	if len(args) > 1 {
		text = []byte(strings.Join(args[1:], " "))
	} else {
		var err error
		text, err = io.ReadAll(stdin)
		if err != nil {
			return fmt.Errorf("read input: %w", err)
		}
	}
	if len(text) == 0 {
		return invalidUsage("text is empty")
	}
	buffer := fmt.Sprintf("sysinit-%d", os.Getpid())
	if _, err := call(runner, "tmux", []string{"load-buffer", "-b", buffer, "-"}, strings.NewReader(string(text))); err != nil {
		return fmt.Errorf("send text to pane %s: %w", paneID, err)
	}
	if _, err := call(runner, "tmux", []string{"paste-buffer", "-p", "-d", "-b", buffer, "-t", paneID}, nil); err != nil {
		return fmt.Errorf("paste text to pane %s: %w", paneID, err)
	}
	if submit {
		if _, err := call(runner, "tmux", []string{"send-keys", "-t", paneID, "Enter"}, nil); err != nil {
			return fmt.Errorf("submit text to pane %s: %w", paneID, err)
		}
	}
	return writeJSON(stdout, actionResult{Version: protocolVersion, Action: "pane.send", PaneID: paneID})
}

func runTmuxPaneAction(args []string, action string, stdout io.Writer, runner commandRunner) error {
	if len(args) != 1 {
		return invalidUsage("usage: ty tmux pane %s <pane-id>", action)
	}
	paneID := args[0]
	if _, err := parseTmuxPaneID(paneID); err != nil {
		return err
	}
	command := "select-pane"
	if action == "close" {
		command = "kill-pane"
	}
	if action == "focus" {
		panes, err := listTmuxPanes(context.Background(), runner)
		if err != nil {
			return err
		}
		for _, raw := range panes {
			var pane struct {
				PaneID  string `json:"pane_id"`
				Session string `json:"session_name"`
				Window  string `json:"window_index"`
			}
			if err := json.Unmarshal(raw, &pane); err != nil {
				return fmt.Errorf("decode tmux pane: %w", err)
			}
			if pane.PaneID == paneID {
				if _, err := call(runner, "tmux", []string{"switch-client", "-t", pane.Session + ":" + pane.Window}, nil); err != nil {
					return fmt.Errorf("switch to tmux window: %w", err)
				}
				break
			}
		}
	}
	if _, err := call(runner, "tmux", []string{command, "-t", paneID}, nil); err != nil {
		return fmt.Errorf("%s pane %s: %w", action, paneID, err)
	}
	return writeJSON(stdout, actionResult{Version: protocolVersion, Action: "pane." + action, PaneID: paneID})
}

func parseTmuxPaneID(value string) (string, error) {
	if len(value) < 2 || value[0] != '%' {
		return "", invalidUsage("pane id must be a tmux pane id such as %%3: %q", value)
	}
	for _, r := range value[1:] {
		if r < '0' || r > '9' {
			return "", invalidUsage("pane id must be a tmux pane id such as %%3: %q", value)
		}
	}
	return value, nil
}

func shellCommand(argv []string) string {
	quoted := make([]string, 0, len(argv))
	for _, arg := range argv {
		quoted = append(quoted, "'"+strings.ReplaceAll(arg, "'", "'\\''")+"'")
	}
	return strings.Join(quoted, " ")
}

func sortedKeys(values map[string]string) []string {
	keys := make([]string, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}

func selectTmuxSession(ctx context.Context, runner commandRunner, name, cwd string) ([]byte, error) {
	if os.Getenv("TMUX") == "" {
		return runner(ctx, "wezterm", []string{"cli", "--no-auto-start", "spawn", "--new-window", "--cwd", cwd, "--", "tmux-client", name}, nil)
	}
	return runner(ctx, "tmux", []string{"switch-client", "-t", "=" + name}, nil)
}
