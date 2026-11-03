package ty

import (
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
)

type foregroundProcess struct {
	PID        int                 `json:"pid"`
	Name       string              `json:"name"`
	Argv       []string            `json:"argv"`
	Executable string              `json:"executable"`
	Children   []foregroundProcess `json:"children,omitempty"`
}

func tmuxForeground(pane string, runner commandRunner) (foregroundProcess, error) {
	info, err := call(runner, "tmux", []string{"display-message", "-p", "-t", pane, "#{pane_pid}\t#{pane_current_command}"}, nil)
	if err != nil {
		return foregroundProcess{}, err
	}
	fields := strings.Split(strings.TrimSpace(string(info)), "\t")
	if len(fields) != 2 {
		return foregroundProcess{}, errors.New("tmux returned an invalid process record")
	}
	root, err := strconv.Atoi(fields[0])
	if err != nil {
		return foregroundProcess{}, err
	}
	rows, err := call(runner, "ps", []string{"-axo", "pid=,ppid=,pgid=,tpgid=,comm="}, nil)
	if err != nil {
		return foregroundProcess{}, err
	}
	return foregroundFrom(root, fields[1], string(rows))
}

func foregroundFrom(root int, name, rows string) (foregroundProcess, error) {
	type process struct {
		pid, parent, group, foreground int
		name                           string
	}
	processes := make([]process, 0)
	group := 0
	for _, row := range strings.Split(rows, "\n") {
		parts := strings.Fields(row)
		if len(parts) < 5 {
			continue
		}
		p := process{name: filepath.Base(strings.Join(parts[4:], " "))}
		p.pid, _ = strconv.Atoi(parts[0])
		p.parent, _ = strconv.Atoi(parts[1])
		p.group, _ = strconv.Atoi(parts[2])
		p.foreground, _ = strconv.Atoi(parts[3])
		processes = append(processes, p)
		if p.pid == root {
			group = p.foreground
		}
	}
	selected := root
	descendants := map[int]bool{root: true}
	for changed := true; changed; {
		changed = false
		for _, p := range processes {
			if descendants[p.parent] && !descendants[p.pid] {
				descendants[p.pid] = true
				changed = true
			}
		}
	}
	// Resolve the foreground command even when a shell shares its process group.
	for _, p := range processes {
		if descendants[p.pid] && p.group == group && p.pid == group {
			selected = p.pid
		}
	}
	for _, p := range processes {
		base := strings.TrimSuffix(strings.TrimPrefix(p.name, "."), "-wrapped")
		if descendants[p.pid] && p.group == group && (p.name == name || base == name) {
			selected = p.pid
			break
		}
	}
	var tree func(int, string) (foregroundProcess, error)
	tree = func(pid int, command string) (foregroundProcess, error) {
		argv, err := processArgv(pid)
		if err != nil {
			return foregroundProcess{}, fmt.Errorf("inspect foreground process %d: %w", pid, err)
		}
		result := foregroundProcess{PID: pid, Name: command, Argv: argv}
		if len(argv) > 0 {
			result.Executable = argv[0]
		}
		for _, p := range processes {
			if p.parent == pid && p.group == group {
				child, err := tree(p.pid, p.name)
				if err == nil {
					result.Children = append(result.Children, child)
				}
			}
		}
		return result, nil
	}
	return tree(selected, name)
}

func tmuxSnapshot(stdout io.Writer, runner commandRunner) error {
	rows, err := call(runner, "tmux", []string{"list-panes", "-a", "-F", "#{pane_id}\t#{session_name}\t#{pane_pid}\t#{pane_current_command}\t#{pane_title}\t#{pane_current_path}"}, nil)
	if err != nil {
		return err
	}
	processes, err := call(runner, "ps", []string{"-axo", "pid=,ppid=,pgid=,tpgid=,comm="}, nil)
	if err != nil {
		return err
	}
	panes := make([]map[string]any, 0)
	for _, line := range strings.Split(strings.TrimSpace(string(rows)), "\n") {
		if line == "" {
			continue
		}
		fields := strings.SplitN(line, "\t", 6)
		if len(fields) != 6 {
			return errors.New("tmux returned an invalid snapshot row")
		}
		if _, err := parseTmuxPaneID(fields[0]); err != nil {
			return err
		}
		pid, err := strconv.Atoi(fields[2])
		if err != nil {
			return err
		}
		process, inspectErr := foregroundFrom(pid, fields[3], string(processes))
		row := map[string]any{"pane": fields[0], "session": fields[1], "title": fields[4], "cwd": fields[5]}
		if inspectErr == nil && len(process.Argv) > 0 {
			row["process"] = process
		}
		text, captureErr := call(runner, "tmux", []string{"capture-pane", "-p", "-S", "-500", "-t", fields[0]}, nil)
		if captureErr == nil {
			row["text"] = string(text)
		}
		panes = append(panes, row)
	}
	return writeJSON(stdout, panes)
}

func remoteCommand(argv []string) ([]string, error) {
	if len(argv) == 0 {
		return nil, nil
	}
	switch filepath.Base(argv[0]) {
	case "mosh-client":
		if len(argv) > 1 && strings.HasPrefix(argv[1], "-# ") && strings.HasSuffix(argv[1], " |") {
			host := strings.TrimSuffix(strings.TrimPrefix(argv[1], "-# "), " |")
			if host != "" && !strings.ContainsAny(host, " \t\n") && !strings.HasPrefix(host, "-") {
				return []string{"mosh", host}, nil
			}
		}
		return nil, errors.New("cannot recover this Mosh destination; use a local split")
	case "ssh":
		command := []string{"ssh", "-o", "ClearAllForwardings=yes", "-o", "RemoteCommand=none"}
		values, retain := "BbcDEeFIiJLlmOoPpQRSWw", "bciFJlmpS"
		for i := 1; i < len(argv); i++ {
			arg := argv[i]
			if arg == "--" {
				i++
				if i < len(argv) {
					command = append(command, argv[i])
					return command, nil
				}
				break
			}
			if !strings.HasPrefix(arg, "-") {
				return append(command, arg), nil
			}
			if len(arg) < 2 {
				break
			}
			flag := arg[1:2]
			if strings.Contains(values, flag) {
				value := arg[2:]
				if value == "" {
					i++
					if i == len(argv) {
						break
					}
					value = argv[i]
				}
				if strings.Contains(retain, flag) || flag == "o" {
					command = append(command, "-"+flag, value)
				}
			} else if strings.Trim(arg[1:], "46AaKkqv") == "" {
				command = append(command, arg)
			} else if strings.Trim(arg[1:], "tTnNfXxYyCMgs") != "" {
				return nil, errors.New("cannot recover the SSH connection options; use a local split")
			}
		}
		return nil, errors.New("cannot recover the SSH destination; use a local split")
	}
	return nil, nil
}

func remoteProcess(process foregroundProcess) ([]string, error) {
	command, err := remoteCommand(process.Argv)
	if command != nil || err != nil {
		return command, err
	}
	for _, child := range process.Children {
		command, err = remoteProcess(child)
		if command != nil || err != nil {
			return command, err
		}
	}
	return nil, nil
}

func runTmuxAction(args []string, stdout io.Writer, runner commandRunner) error {
	if len(args) < 2 {
		return invalidUsage("ty tmux %s requires a pane ID", args[0])
	}
	pane, err := parseTmuxPaneID(args[1])
	if err != nil {
		return err
	}
	switch args[0] {
	case "process":
		if len(args) != 2 {
			return invalidUsage("usage: ty tmux process <pane-id>")
		}
		process, err := tmuxForeground(pane, runner)
		if err != nil {
			return err
		}
		return writeJSON(stdout, process)
	case "navigate", "resize":
		if len(args) != 3 {
			return invalidUsage("usage: ty tmux %s <pane-id> h|j|k|l", args[0])
		}
		direction := map[string]string{"h": "L", "j": "D", "k": "U", "l": "R"}[args[2]]
		if direction == "" {
			return invalidUsage("invalid direction %q", args[2])
		}
		process, err := tmuxForeground(pane, runner)
		if err != nil {
			return err
		}
		passthrough := process.Name == "nvim" || process.Name == "vim" || process.Name == "hx"
		if args[0] == "navigate" {
			passthrough = passthrough || process.Name == "traces" || process.Name == "orc"
		}
		command := []string{"select-pane", "-t", pane, "-" + direction}
		if args[0] == "resize" {
			command = []string{"resize-pane", "-t", pane, "-" + direction, "3"}
		}
		if passthrough {
			key := "C-" + args[2]
			if args[0] == "resize" {
				key = "C-S-" + args[2]
			}
			command = []string{"send-keys", "-t", pane, key}
		}
		_, err = call(runner, "tmux", command, nil)
		return err
	case "spawn":
		if len(args) < 3 || len(args) > 4 || (len(args) == 4 && args[3] != "--local") {
			return invalidUsage("usage: ty tmux spawn <pane-id> right|down|window [--local]")
		}
		kind := args[2]
		if kind != "right" && kind != "down" && kind != "window" {
			return invalidUsage("invalid spawn kind %q", kind)
		}
		var argv []string
		cwd := "#{pane_current_path}"
		if len(args) == 4 {
			cwd, err = os.UserHomeDir()
		} else {
			process, inspectErr := tmuxForeground(pane, runner)
			if inspectErr != nil {
				return inspectErr
			}
			argv, err = remoteProcess(process)
			if argv != nil {
				cwd, err = os.UserHomeDir()
			}
		}
		if err != nil {
			return err
		}
		command := []string{"split-window", "-t", pane, "-c", cwd}
		switch kind {
		case "window":
			command[0] = "new-window"
		case "right":
			command = append(command, "-h")
		default:
			command = append(command, "-v")
		}
		if kind != "window" && len(args) == 4 {
			command = append(command, "-f")
		}
		if len(argv) != 0 {
			command = append(command, "--")
			command = append(command, argv...)
		}
		_, err = call(runner, "tmux", command, nil)
		return err
	case "select", "scrollback":
		if len(args) != 2 {
			return invalidUsage("usage: ty tmux %s <pane-id>", args[0])
		}
		text, err := call(runner, "tmux", []string{"capture-pane", "-p", "-S", "-", "-t", pane}, nil)
		if err != nil {
			return err
		}
		if args[0] == "select" {
			pattern := regexp.MustCompile(`https?://[^\s<>"']+|/[^\s<>"']+|[0-9a-f]{40}|[0-9a-f]{8}-[0-9a-f-]{27,}|\b[0-9a-f]{7}\b`)
			var matches []string
			seen := map[string]bool{}
			for _, match := range pattern.FindAllString(string(text), -1) {
				if !seen[match] {
					seen[match] = true
					matches = append(matches, match)
				}
			}
			if len(matches) == 0 {
				return errors.New("no paths, URLs, hashes or identifiers in pane history")
			}
			selected, err := choose(matches, "Copy from pane history")
			if err != nil || selected < 0 {
				return err
			}
			_, err = call(runner, "tmux", []string{"load-buffer", "-w", "-"}, strings.NewReader(matches[selected]))
			return err
		}
		file, err := os.CreateTemp("", "tmux-scrollback-*.txt")
		if err != nil {
			return err
		}
		if _, err = file.Write(text); err != nil {
			_ = file.Close()
			return err
		}
		if err = file.Close(); err != nil {
			return err
		}
		command := "trap " + shellCommand([]string{"rm -f " + shellCommand([]string{file.Name()})}) + " EXIT; nvim " + shellCommand([]string{file.Name()})
		_, err = call(runner, "tmux", []string{"new-window", "-t", pane, "-n", "scrollback", command}, nil)
		if err != nil {
			_ = os.Remove(file.Name())
		}
		return err
	}
	return invalidUsage("unknown tmux action %q", args[0])
}
