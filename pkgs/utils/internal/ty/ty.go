package ty

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"time"
)

const protocolVersion = "sysinit.ty/v1"

const usage = `ty: inspect and control seshy sessions and tmux panes

Usage:
  ty catalog
  ty sessions
  ty panes
  ty session open <session-id-or-name>
  ty session switch <session-id-or-name>
  ty pane split <pane-id> --direction right|down|left|up [--cwd PATH]
  ty pane spawn <pane-id> --direction right|down|left|up [--percent N] [--cwd PATH] -- <command> [args...]
  ty pane read <pane-id>
  ty pane send [--submit] <pane-id> [text...]
  ty pane focus <pane-id>
  ty pane close <pane-id>

Catalog and action results use JSON. Pane read writes terminal text directly.
Pane send reads text from stdin when no text argument is supplied.
`

type commandRunner func(ctx context.Context, name string, args []string, stdin io.Reader) ([]byte, error)

type usageError string

func (e usageError) Error() string { return string(e) }

func invalidUsage(format string, args ...any) error {
	return usageError(fmt.Sprintf(format, args...))
}

type catalog struct {
	Version  string            `json:"version"`
	Sessions []json.RawMessage `json:"sessions"`
	Panes    []json.RawMessage `json:"panes"`
}

type sessionsResult struct {
	Version  string            `json:"version"`
	Sessions []json.RawMessage `json:"sessions"`
}

type panesResult struct {
	Version string            `json:"version"`
	Panes   []json.RawMessage `json:"panes"`
}

type openPlan struct {
	Version     string            `json:"version"`
	ID          string            `json:"id"`
	CWD         string            `json:"cwd"`
	Command     []string          `json:"command"`
	Environment map[string]string `json:"environment"`
}

type actionResult struct {
	Version   string `json:"version"`
	Action    string `json:"action"`
	SessionID string `json:"session_id,omitempty"`
	Workspace string `json:"workspace,omitempty"`
	CWD       string `json:"cwd,omitempty"`
	PaneID    string `json:"pane_id,omitempty"`
	Opened    *bool  `json:"opened,omitempty"`
}

func Summary() string { return "compose seshy sessions and tmux panes" }

func Run(args []string) int {
	return run(args, os.Stdin, os.Stdout, os.Stderr, execRunner)
}

func run(args []string, stdin io.Reader, stdout, stderr io.Writer, runner commandRunner) int {
	if len(args) == 0 || args[0] == "--help" || args[0] == "-h" || args[0] == "help" {
		_, _ = io.WriteString(stdout, usage)
		return 0
	}

	var err error
	switch args[0] {
	case "catalog":
		err = runCatalog(stdout, runner)
	case "sessions":
		err = runSessions(stdout, runner)
	case "panes":
		err = runPanes(stdout, runner)
	case "session":
		err = runSession(args[1:], stdout, runner)
	case "pane":
		err = runPane(args[1:], stdin, stdout, runner)
	case "picker":
		if len(args) != 1 {
			err = invalidUsage("usage: ty picker")
		} else {
			err = runPicker(stdout, runner)
		}
	default:
		err = invalidUsage("unknown command %q", args[0])
	}
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "ty: %v\n", err)
		var usage usageError
		if errors.As(err, &usage) {
			return 2
		}
		return 1
	}
	return 0
}

func runCatalog(stdout io.Writer, runner commandRunner) error {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	sessions, err := listSessions(ctx, runner)
	if err != nil {
		return err
	}
	panes, err := listPanes(ctx, runner)
	if err != nil {
		return err
	}

	return writeJSON(stdout, catalog{Version: protocolVersion, Sessions: sessions, Panes: panes})
}

func runSessions(stdout io.Writer, runner commandRunner) error {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	sessions, err := listSessions(ctx, runner)
	if err != nil {
		return err
	}
	return writeJSON(stdout, sessionsResult{Version: protocolVersion, Sessions: sessions})
}

func runPanes(stdout io.Writer, runner commandRunner) error {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	panes, err := listPanes(ctx, runner)
	if err != nil {
		return err
	}
	return writeJSON(stdout, panesResult{Version: protocolVersion, Panes: panes})
}

func listSessions(ctx context.Context, runner commandRunner) ([]json.RawMessage, error) {
	sessionsJSON, err := runner(ctx, "sy", []string{"list", "--format", "json"}, nil)
	if err != nil {
		return nil, fmt.Errorf("list seshy sessions: %w", err)
	}
	var sessions []json.RawMessage
	if err := json.Unmarshal(sessionsJSON, &sessions); err != nil {
		return nil, fmt.Errorf("decode seshy session list: %w", err)
	}
	if sessions == nil {
		sessions = []json.RawMessage{}
	}
	return sessions, nil
}

func listPanes(ctx context.Context, runner commandRunner) ([]json.RawMessage, error) {
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

func runSession(args []string, stdout io.Writer, runner commandRunner) error {
	if len(args) != 2 || (args[0] != "open" && args[0] != "switch") {
		return invalidUsage("usage: ty session open|switch <session-id-or-name>")
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
		if _, err := runner(ctx, "tmux", []string{"has-session", "-t", workspace}, nil); err == nil {
			if _, err := runner(ctx, "tmux", []string{"switch-client", "-t", workspace}, nil); err != nil {
				return fmt.Errorf("switch to tmux session %q: %w", plan.ID, err)
			}
			panes, listErr := listPanes(ctx, runner)
			if listErr != nil {
				return listErr
			}
			paneID, findErr := findWorkspacePane(panes, workspace)
			if findErr != nil {
				return findErr
			}
			opened := false
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
	if _, err := runner(ctx, "tmux", []string{"has-session", "-t", workspace}, nil); err != nil {
		newArgs := []string{"new-session", "-d", "-P", "-F", "#{pane_id}", "-s", workspace, "-c", plan.CWD}
		for _, key := range sortedKeys(plan.Environment) {
			newArgs = append(newArgs, "-e", key+"="+plan.Environment[key])
		}
		newArgs = append(newArgs, shellCommand(command))
		if _, err := runner(ctx, "tmux", newArgs, nil); err != nil {
			if _, checkErr := runner(ctx, "tmux", []string{"has-session", "-t", workspace}, nil); checkErr != nil {
				return fmt.Errorf("open tmux session %q: %w", plan.ID, err)
			}
		} else {
			created = true
		}
	}
	if _, err := runner(ctx, "tmux", []string{"switch-client", "-t", workspace}, nil); err != nil {
		return fmt.Errorf("select tmux session %q: %w", plan.ID, err)
	}
	panes, err := listPanes(ctx, runner)
	if err != nil {
		return err
	}
	paneID, err := findWorkspacePane(panes, workspace)
	if err != nil {
		return err
	}
	resultAction := "session.open"
	opened := created
	if action == "switch" {
		resultAction = "session.switch"
	}
	return writeJSON(stdout, actionResult{
		Version: protocolVersion, Action: resultAction, SessionID: plan.ID,
		Workspace: workspace, CWD: plan.CWD, PaneID: string(paneID), Opened: &opened,
	})
}

func findWorkspacePane(panes []json.RawMessage, workspace string) (string, error) {
	for _, raw := range panes {
		var pane struct {
			PaneID    string `json:"pane_id"`
			Workspace string `json:"session_name"`
		}
		if err := json.Unmarshal(raw, &pane); err != nil {
			return "", fmt.Errorf("decode WezTerm pane: %w", err)
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

func runPane(args []string, stdin io.Reader, stdout io.Writer, runner commandRunner) error {
	if len(args) == 0 {
		return invalidUsage("expected pane subcommand: split, spawn, read, send, focus, or close")
	}
	switch args[0] {
	case "split":
		return runSplit(args[1:], false, stdout, runner)
	case "spawn":
		return runSplit(args[1:], true, stdout, runner)
	case "read":
		return runRead(args[1:], stdout, runner)
	case "send":
		return runSend(args[1:], stdin, stdout, runner)
	case "focus":
		return runPaneAction(args[1:], "focus", stdout, runner)
	case "close":
		return runPaneAction(args[1:], "close", stdout, runner)
	default:
		return invalidUsage("unknown pane command %q", args[0])
	}
}

func runSplit(args []string, spawn bool, stdout io.Writer, runner commandRunner) error {
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
	if _, err := parsePaneID(paneID); err != nil {
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
	if _, err := parsePaneID(string(newPane)); err != nil {
		return fmt.Errorf("tmux returned invalid pane id: %w", err)
	}
	action := "pane.split"
	if spawn {
		action = "pane.spawn"
	}
	return writeJSON(stdout, actionResult{Version: protocolVersion, Action: action, PaneID: string(newPane)})
}

func runRead(args []string, stdout io.Writer, runner commandRunner) error {
	if len(args) != 1 {
		return invalidUsage("usage: ty pane read <pane-id>")
	}
	if _, err := parsePaneID(args[0]); err != nil {
		return err
	}
	text, err := call(runner, "tmux", []string{"capture-pane", "-p", "-S", "-", "-t", args[0]}, nil)
	if err != nil {
		return fmt.Errorf("read pane %s: %w", args[0], err)
	}
	_, err = stdout.Write(text)
	return err
}

func runSend(args []string, stdin io.Reader, stdout io.Writer, runner commandRunner) error {
	submit := false
	if len(args) > 0 && args[0] == "--submit" {
		submit = true
		args = args[1:]
	}
	if len(args) == 0 {
		return invalidUsage("usage: ty pane send [--submit] <pane-id> [text...]")
	}
	paneID := args[0]
	if _, err := parsePaneID(paneID); err != nil {
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

func runPaneAction(args []string, action string, stdout io.Writer, runner commandRunner) error {
	if len(args) != 1 {
		return invalidUsage("usage: ty pane %s <pane-id>", action)
	}
	paneID := args[0]
	if _, err := parsePaneID(paneID); err != nil {
		return err
	}
	command := "select-pane"
	if action == "close" {
		command = "kill-pane"
	}
	if action == "focus" {
		panes, err := listPanes(context.Background(), runner)
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

func call(runner commandRunner, name string, args []string, stdin io.Reader) ([]byte, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	return runner(ctx, name, args, stdin)
}

func execRunner(ctx context.Context, name string, args []string, stdin io.Reader) ([]byte, error) {
	switch name {
	case "sy":
		name = commandPath("SYSINIT_TY_SY", "sy")
	case "tmux":
		name = commandPath("SYSINIT_TY_TMUX", "tmux")
	}
	cmd := exec.CommandContext(ctx, name, args...)
	cmd.Stdin = stdin
	var stderr strings.Builder
	cmd.Stderr = &stderr
	output, err := cmd.Output()
	if err != nil {
		message := strings.TrimSpace(stderr.String())
		if message != "" {
			return nil, fmt.Errorf("%s: %w: %s", filepath.Base(name), err, message)
		}
		return nil, fmt.Errorf("%s: %w", filepath.Base(name), err)
	}
	return output, nil
}

func commandPath(variable, fallback string) string {
	if path := os.Getenv(variable); path != "" {
		return path
	}
	return fallback
}

func writeJSON(w io.Writer, value any) error {
	return json.NewEncoder(w).Encode(value)
}

func parsePaneID(value string) (string, error) {
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

func validEnvironmentKey(key string) bool {
	if key == "" {
		return false
	}
	for i, r := range key {
		if (r >= 'A' && r <= 'Z') || (r >= 'a' && r <= 'z') || r == '_' || (i > 0 && r >= '0' && r <= '9') {
			continue
		}
		return false
	}
	return true
}

func loginShell() string {
	if shell := os.Getenv("SHELL"); shell != "" && filepath.IsAbs(shell) {
		return shell
	}
	if runtime.GOOS == "darwin" {
		return "/bin/zsh"
	}
	return "/bin/sh"
}
