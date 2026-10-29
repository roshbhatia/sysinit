package termsesh

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

const protocolVersion = "sysinit.termsesh/v1"

const usage = `termsesh: inspect and control seshy sessions in WezTerm

Usage:
  termsesh catalog
  termsesh sessions
  termsesh panes
  termsesh session open <session-id-or-name>
  termsesh session switch <session-id-or-name>
  termsesh pane split <pane-id> --direction right|down [--cwd PATH]
  termsesh pane spawn <pane-id> --direction right|down [--cwd PATH] -- <command> [args...]
  termsesh pane read <pane-id>
  termsesh pane send [--submit] <pane-id> [text...]
  termsesh pane focus <pane-id>
  termsesh pane close <pane-id>

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

func Summary() string { return "compose seshy sessions and WezTerm panes" }

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
	default:
		err = invalidUsage("unknown command %q", args[0])
	}
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "termsesh: %v\n", err)
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
	panesJSON, err := runner(ctx, "wezterm", []string{"cli", "--no-auto-start", "list", "--format", "json"}, nil)
	if err != nil {
		return nil, fmt.Errorf("list WezTerm panes: %w", err)
	}
	var panes []json.RawMessage
	if err := json.Unmarshal(panesJSON, &panes); err != nil {
		return nil, fmt.Errorf("decode WezTerm pane list: %w", err)
	}
	if panes == nil {
		panes = []json.RawMessage{}
	}
	return panes, nil
}

func runSession(args []string, stdout io.Writer, runner commandRunner) error {
	if len(args) != 2 || (args[0] != "open" && args[0] != "switch") {
		return invalidUsage("usage: termsesh session open|switch <session-id-or-name>")
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
	if action == "switch" {
		panes, err := listPanes(ctx, runner)
		if err != nil {
			return err
		}
		paneID, err := findWorkspacePane(panes, workspace)
		if err != nil {
			return err
		}
		if paneID != "" {
			if _, err := runner(ctx, "wezterm", []string{"cli", "--no-auto-start", "activate-pane", "--pane-id", paneID}, nil); err != nil {
				return fmt.Errorf("switch to WezTerm session %q: %w", plan.ID, err)
			}
			opened := false
			return writeJSON(stdout, actionResult{
				Version: protocolVersion, Action: "session.switch", SessionID: plan.ID,
				Workspace: workspace, CWD: plan.CWD, PaneID: paneID, Opened: &opened,
			})
		}
	}
	weztermArgs := []string{
		"cli", "--no-auto-start", "spawn", "--new-window",
		"--workspace", workspace, "--cwd", plan.CWD,
	}
	command := plan.Command
	if len(plan.Environment) > 0 {
		command = environmentCommand(plan.Environment)
		if len(plan.Command) > 0 {
			command = append(command, plan.Command...)
		} else {
			command = append(command, loginShell())
			if runtime.GOOS != "windows" {
				command = append(command, "-l")
			}
		}
	}
	if len(command) > 0 {
		weztermArgs = append(weztermArgs, "--")
		weztermArgs = append(weztermArgs, command...)
	}
	paneID, err := runner(ctx, "wezterm", weztermArgs, nil)
	if err != nil {
		return fmt.Errorf("open WezTerm session %q: %w", plan.ID, err)
	}
	paneID = []byte(strings.TrimSpace(string(paneID)))
	if _, err := parsePaneID(string(paneID)); err != nil {
		return fmt.Errorf("WezTerm returned invalid pane id: %w", err)
	}
	resultAction := "session.open"
	opened := true
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
			PaneID    int    `json:"pane_id"`
			Workspace string `json:"workspace"`
		}
		if err := json.Unmarshal(raw, &pane); err != nil {
			return "", fmt.Errorf("decode WezTerm pane: %w", err)
		}
		if pane.Workspace == workspace {
			return strconv.Itoa(pane.PaneID), nil
		}
	}
	return "", nil
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
	if direction != "right" && direction != "down" {
		return invalidUsage("--direction must be right or down")
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
	argsOut := []string{"cli", "--no-auto-start", "split-pane", "--pane-id", paneID}
	if direction == "right" {
		argsOut = append(argsOut, "--right")
	} else {
		argsOut = append(argsOut, "--bottom")
	}
	if cwd != "" {
		argsOut = append(argsOut, "--cwd", cwd)
	}
	if len(command) > 0 {
		argsOut = append(argsOut, "--")
		argsOut = append(argsOut, command...)
	}
	newPane, err := call(runner, "wezterm", argsOut, nil)
	if err != nil {
		return fmt.Errorf("split pane %s: %w", paneID, err)
	}
	newPane = []byte(strings.TrimSpace(string(newPane)))
	if _, err := parsePaneID(string(newPane)); err != nil {
		return fmt.Errorf("WezTerm returned invalid pane id: %w", err)
	}
	action := "pane.split"
	if spawn {
		action = "pane.spawn"
	}
	return writeJSON(stdout, actionResult{Version: protocolVersion, Action: action, PaneID: string(newPane)})
}

func runRead(args []string, stdout io.Writer, runner commandRunner) error {
	if len(args) != 1 {
		return invalidUsage("usage: termsesh pane read <pane-id>")
	}
	if _, err := parsePaneID(args[0]); err != nil {
		return err
	}
	text, err := call(runner, "wezterm", []string{"cli", "--no-auto-start", "get-text", "--pane-id", args[0]}, nil)
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
		return invalidUsage("usage: termsesh pane send [--submit] <pane-id> [text...]")
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
	if _, err := call(runner, "wezterm", []string{"cli", "--no-auto-start", "send-text", "--pane-id", paneID}, strings.NewReader(string(text))); err != nil {
		return fmt.Errorf("send text to pane %s: %w", paneID, err)
	}
	if submit {
		if _, err := call(runner, "wezterm", []string{
			"cli", "--no-auto-start", "send-text", "--no-paste", "--pane-id", paneID, "\r",
		}, nil); err != nil {
			return fmt.Errorf("submit text to pane %s: %w", paneID, err)
		}
	}
	return writeJSON(stdout, actionResult{Version: protocolVersion, Action: "pane.send", PaneID: paneID})
}

func runPaneAction(args []string, action string, stdout io.Writer, runner commandRunner) error {
	if len(args) != 1 {
		return invalidUsage("usage: termsesh pane %s <pane-id>", action)
	}
	paneID := args[0]
	if _, err := parsePaneID(paneID); err != nil {
		return err
	}
	command := "activate-pane"
	if action == "close" {
		command = "kill-pane"
	}
	if _, err := call(runner, "wezterm", []string{"cli", "--no-auto-start", command, "--pane-id", paneID}, nil); err != nil {
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
		name = commandPath("SYSINIT_TERMSESH_SY", "sy")
	case "wezterm":
		name = commandPath("SYSINIT_TERMSESH_WEZTERM", "wezterm")
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

func parsePaneID(value string) (int, error) {
	id, err := strconv.Atoi(value)
	if err != nil || id < 0 {
		return 0, invalidUsage("pane id must be a non-negative integer: %q", value)
	}
	return id, nil
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

func environmentCommand(environment map[string]string) []string {
	keys := make([]string, 0, len(environment))
	for key := range environment {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	args := []string{commandPath("SYSINIT_TERMSESH_ENV", "env")}
	for _, key := range keys {
		args = append(args, key+"="+environment[key])
	}
	return args
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
