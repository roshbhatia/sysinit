package ty

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/roshbhatia/go-utils/paths"
)

// Terminal entry points keep session ownership independent of the GUI renderer.
type terminalConfig struct {
	Tmux, Sessionizer, Client, ShellCommand, RuntimePath string
	Version                                              string `json:"version"`
	Renderer                                             string `json:"renderer"`
	Executable                                           string `json:"executable"`
	Application                                          string `json:"application"`
}
type rendererPane struct {
	TabID     int    `json:"tab_id"`
	ID        int    `json:"pane_id"`
	TTY       string `json:"tty_name"`
	Workspace string `json:"workspace"`
	Title     string `json:"title"`
	CWD       string `json:"cwd"`
}
type terminalRow struct {
	ID     string `json:"id"`
	Title  string `json:"title"`
	Detail string `json:"detail"`
}

func terminalSettings() (terminalConfig, error) {
	root, err := paths.ConfigHomeE()
	if err != nil {
		return terminalConfig{}, err
	}
	data, err := os.ReadFile(filepath.Join(root, "sysinit", "terminal.json"))
	if err != nil {
		return terminalConfig{}, err
	}
	var cfg terminalConfig
	if err = json.Unmarshal(data, &cfg); err != nil {
		return cfg, err
	}
	if cfg.Version != "sysinit.terminal/v1" || cfg.Renderer != "wezterm" || !filepath.IsAbs(cfg.Executable) {
		return cfg, fmt.Errorf("invalid terminal renderer configuration")
	}
	return cfg, nil
}
func rendererPanes(ctx context.Context, cfg terminalConfig, runner commandRunner) ([]rendererPane, error) {
	data, err := runner(ctx, cfg.Executable, []string{"cli", "--no-auto-start", "list", "--format", "json"}, nil)
	if err != nil {
		return nil, err
	}
	var panes []rendererPane
	err = json.Unmarshal(data, &panes)
	return panes, err
}
func rendererRaise(ctx context.Context, cfg terminalConfig, runner commandRunner) error {
	if runtime.GOOS == "darwin" {
		_, err := runner(ctx, "/usr/bin/open", []string{"-a", cfg.Application}, nil)
		return err
	}
	return nil
}
func rendererFocus(ctx context.Context, cfg terminalConfig, runner commandRunner, id int) error {
	rows, err := rendererPanes(ctx, cfg, runner)
	if err != nil {
		return err
	}
	for _, row := range rows {
		if row.ID != id {
			continue
		}
		if _, err = runner(ctx, cfg.Executable, []string{"cli", "--no-auto-start", "activate-tab", "--tab-id", strconv.Itoa(row.TabID)}, nil); err != nil {
			return err
		}
		if _, err = runner(ctx, cfg.Executable, []string{"cli", "--no-auto-start", "activate-pane", "--pane-id", strconv.Itoa(id)}, nil); err != nil {
			return err
		}
		tty, err := os.OpenFile(row.TTY, os.O_WRONLY, 0)
		if err != nil {
			return fmt.Errorf("open renderer terminal: %w", err)
		}
		nonce := base64.StdEncoding.EncodeToString([]byte(strconv.FormatInt(time.Now().UnixNano(), 10)))
		_, writeErr := fmt.Fprintf(tty, "\x1b]1337;SetUserVar=SYSINIT_FOCUS=%s\x07", nonce)
		closeErr := tty.Close()
		if writeErr != nil {
			return writeErr
		}
		if closeErr != nil {
			return closeErr
		}
		return rendererRaise(ctx, cfg, runner)
	}
	return fmt.Errorf("renderer pane %d is no longer available", id)
}
func rendererOpen(ctx context.Context, runner commandRunner, cwd string, argv []string) ([]byte, error) {
	cfg, err := terminalSettings()
	if err != nil {
		return nil, err
	}
	if len(argv) > 0 && argv[0] == "tmux-client" && cfg.Client != "" {
		argv = append([]string(nil), argv...)
		argv[0] = cfg.Client
	}
	args := []string{"--cwd", cwd, "--"}
	args = append(args, argv...)
	panes, probeErr := rendererPanes(ctx, cfg, runner)
	if probeErr == nil && len(panes) > 0 {
		out, err := runner(ctx, cfg.Executable, append([]string{"cli", "--no-auto-start", "spawn", "--new-window"}, args...), nil)
		if err != nil {
			return out, err
		}
		id, err := strconv.Atoi(strings.TrimSpace(string(out)))
		if err != nil {
			return out, fmt.Errorf("invalid renderer pane id: %w", err)
		}
		return out, rendererFocus(ctx, cfg, runner, id)
	}
	if runtime.GOOS == "darwin" {
		return runner(ctx, "/usr/bin/open", append([]string{"-na", cfg.Application, "--args", "start", "--always-new-process"}, args...), nil)
	}
	return runner(ctx, cfg.Executable, append([]string{"start", "--always-new-process"}, args...), nil)
}
func terminalFocus(ctx context.Context, runner commandRunner, id string) error {
	if strings.HasPrefix(id, "wezterm:") {
		number, err := strconv.Atoi(strings.TrimPrefix(id, "wezterm:"))
		if err != nil {
			return err
		}
		cfg, err := terminalSettings()
		if err != nil {
			return err
		}
		return rendererFocus(ctx, cfg, runner, number)
	}
	if _, err := parseTmuxPaneID(id); err != nil {
		return err
	}
	data, err := runner(ctx, "tmux", []string{"display-message", "-p", "-t", id, "#{session_name}\t#{window_id}\t#{pane_current_path}\t#{@sysinit_float_parent}"}, nil)
	if err != nil {
		return err
	}
	fields := strings.Split(strings.TrimSpace(string(data)), "\t")
	if len(fields) < 3 {
		return fmt.Errorf("invalid terminal pane target")
	}
	session, target, cwd := fields[0], fields[1], fields[2]
	if len(fields) == 4 && fields[3] != "" {
		parent, err := runner(ctx, "tmux", []string{"display-message", "-p", "-t", fields[3] + ":", "#{session_name}"}, nil)
		if err != nil {
			return err
		}
		session = strings.TrimSpace(string(parent))
		target = "=" + session
		if _, err = runner(ctx, "tmux", []string{"join-pane", "-s", id, "-t", fields[3] + ":"}, nil); err != nil {
			return err
		}
		if _, err = runner(ctx, "tmux", []string{"break-pane", "-W", "-s", id, "-x", "85%", "-y", "80%", "-X", "7%", "-Y", "10%"}, nil); err != nil {
			return err
		}
	}
	focused, err := focusTmuxTarget(ctx, runner, session, target, id)
	if err != nil {
		return err
	}
	if !focused {
		_, err = runner(ctx, "tmux", []string{"select-window", "-t", target}, nil)
		if err != nil {
			return err
		}
		_, err = runner(ctx, "tmux", []string{"select-pane", "-t", id}, nil)
		if err != nil {
			return err
		}
		if os.Getenv("TMUX") != "" {
			_, err = runner(ctx, "tmux", []string{"switch-client", "-t", target}, nil)
			return err
		}
		_, err = rendererOpen(ctx, runner, cwd, []string{"tmux-client", session})
	}
	return err
}
func runTerminal(args []string, stdin io.Reader, stdout io.Writer, runner commandRunner) error {
	if len(args) == 0 {
		return invalidUsage("usage: ty terminal catalog|focus <pane>|open [session cwd]|run -- <command> [args...]")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	switch args[0] {
	case "focus":
		if len(args) != 2 {
			return invalidUsage("usage: ty terminal focus <pane>")
		}
		return terminalFocus(ctx, runner, args[1])
	case "catalog":
		cfg, err := terminalSettings()
		if err != nil {
			return err
		}
		rows := []terminalRow{}
		clients := map[string]bool{}
		data, listErr := runner(ctx, "tmux", []string{"list-clients", "-F", "#{client_name}"}, nil)
		if listErr == nil {
			for _, tty := range strings.Split(strings.TrimSpace(string(data)), "\n") {
				clients[tty] = true
			}
		}
		if settings, err := pickerSettings(); err == nil && listErr == nil {
			p, err := loadPresentation(settings, runner, true)
			if err != nil {
				return err
			}
			for _, r := range p.Rows {
				if strings.HasPrefix(r.ID, "pane:") {
					rows = append(rows, terminalRow{strings.TrimPrefix(r.ID, "pane:"), strings.TrimSpace(r.Text), "tmux"})
				}
			}
		}
		panes, err := rendererPanes(ctx, cfg, runner)
		if err == nil {
			for _, p := range panes {
				if !clients[p.TTY] {
					rows = append(rows, terminalRow{"wezterm:" + strconv.Itoa(p.ID), p.Workspace + ": " + p.Title, p.CWD})
				}
			}
		}
		return writeJSON(stdout, rows)
	case "open":
		name := ""
		cwd, err := os.UserHomeDir()
		if err != nil {
			return err
		}
		if len(args) > 1 {
			name = args[1]
		}
		if len(args) > 2 {
			cwd = args[2]
		}
		if len(args) > 3 {
			return invalidUsage("usage: ty terminal open [session cwd]")
		}
		if name != "" {
			if strings.HasPrefix(name, "seshy:") {
				return runTmuxSession([]string{"open", name}, stdout, runner)
			}
			if !validSessionName(name) {
				return invalidUsage("invalid terminal session name")
			}
			_, err = selectTmuxSession(ctx, runner, name, cwd)
			return err
		}
		_, err = rendererOpen(ctx, runner, cwd, []string{"tmux-client"})
		return err
	case "run":
		if len(args) < 3 || args[1] != "--" {
			return invalidUsage("usage: ty terminal run -- <command> [args...]")
		}
		cwd, err := os.UserHomeDir()
		if err != nil {
			return err
		}
		// A dedicated session avoids inserting review commands into an unrelated GUI.
		name := fmt.Sprintf("command-%d", os.Getpid())
		cfg, err := terminalSettings()
		if err != nil {
			return err
		}
		login := cfg.ShellCommand
		if login == "" {
			login = `"$SHELL" -l`
		}
		if _, err = runner(ctx, "tmux", []string{"new-session", "-d", "-s", name, "-c", cwd, shellCommand(args[2:]) + "; exec " + login}, stdin); err != nil {
			return err
		}
		_, err = rendererOpen(ctx, runner, cwd, []string{"tmux-client", name})
		return err
	default:
		return invalidUsage("unknown terminal command %q", args[0])
	}
}

func focusTmuxTarget(ctx context.Context, runner commandRunner, session, target, pane string) (bool, error) {
	data, err := runner(ctx, "tmux", []string{"list-clients", "-F", "#{client_name}\t#{client_termname}\t#{client_activity}\t#{session_name}"}, nil)
	if err != nil {
		return false, err
	}
	type client struct {
		name, session string
		activity      int64
	}
	clients := []client{}
	for _, line := range strings.Split(strings.TrimSpace(string(data)), "\n") {
		if line == "" {
			continue
		}
		f := strings.Split(line, "\t")
		if len(f) != 4 {
			return false, fmt.Errorf("invalid tmux client row")
		}
		if !strings.HasPrefix(f[1], "wezterm") {
			continue
		}
		activity, _ := strconv.ParseInt(f[2], 10, 64)
		clients = append(clients, client{f[0], f[3], activity})
	}
	if len(clients) == 0 {
		return false, nil
	}
	cfg, err := terminalSettings()
	if err != nil {
		return false, err
	}
	rows, err := rendererPanes(ctx, cfg, runner)
	if err != nil {
		return false, nil
	}
	localTTY := map[string]int{}
	for _, row := range rows {
		localTTY[row.TTY] = row.ID
	}
	local := clients[:0]
	for _, client := range clients {
		if _, ok := localTTY[client.name]; ok {
			local = append(local, client)
		}
	}
	clients = local
	if len(clients) == 0 {
		return false, nil
	}
	sort.SliceStable(clients, func(i, j int) bool {
		a, b := clients[i], clients[j]
		if (a.session == session) != (b.session == session) {
			return a.session == session
		}
		return a.activity > b.activity
	})
	chosen := clients[0]
	if os.Getenv("TMUX") == "" && chosen.session != session {
		return false, nil
	}
	if _, err = runner(ctx, "tmux", []string{"switch-client", "-c", chosen.name, "-t", target}, nil); err != nil {
		return false, err
	}
	if pane != "" {
		if _, err = runner(ctx, "tmux", []string{"select-pane", "-t", pane}, nil); err != nil {
			return false, err
		}
	}
	return true, rendererFocus(ctx, cfg, runner, localTTY[chosen.name])
}
