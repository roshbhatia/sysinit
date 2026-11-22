package main

import (
	"bufio"
	"context"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"time"
	"unsafe"
)

func envWithout(keys ...string) []string {
	out := []string{}
	for _, s := range os.Environ() {
		key, _, _ := strings.Cut(s, "=")
		keep := true
		for _, k := range keys {
			if key == k {
				keep = false
			}
		}
		if keep {
			out = append(out, s)
		}
	}
	return out
}

// The persistent WezTerm mux hosts attachable terminals, one workspace per attempt.
const muxDomain = "unix"

func wezterm(args ...string) *exec.Cmd {
	c := exec.Command("wezterm", append([]string{"cli", "--prefer-mux", "--no-auto-start"}, args...)...)
	socket := os.Getenv("TQ_WEZTERM_SOCKET")
	if socket == "" {
		// The socket path configured by the sysinit-wezterm module.
		home, _ := os.UserHomeDir()
		socket = filepath.Join(home, ".local", "state", "wezterm", "mux.sock")
	}
	// WezTerm serializes the CLI's environment when spawning a command.
	c.Env = []string{"WEZTERM_UNIX_SOCKET=" + socket}
	for _, key := range []string{
		"HOME", "USER", "LOGNAME", "PATH", "SHELL", "TMPDIR", "LANG", "LC_ALL", "LC_CTYPE",
		"XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_RUNTIME_DIR", "XDG_STATE_HOME", "WEZTERM_CONFIG_FILE",
	} {
		if value, ok := os.LookupEnv(key); ok {
			c.Env = append(c.Env, key+"="+value)
		}
	}
	return c
}

func terminalPanes(name string) ([]int, error) {
	b, e := wezterm("list", "--format", "json").Output()
	if e != nil {
		return nil, fmt.Errorf("terminal mux unavailable: %w", e)
	}
	var panes []struct {
		PaneID    int    `json:"pane_id"`
		Workspace string `json:"workspace"`
	}
	if e = json.Unmarshal(b, &panes); e != nil {
		return nil, e
	}
	ids := []int{}
	for _, p := range panes {
		if p.Workspace == name {
			ids = append(ids, p.PaneID)
		}
	}
	return ids, nil
}

func killTerminal(name string) error {
	ids, e := terminalPanes(name)
	if e != nil {
		return e
	}
	for _, id := range ids {
		if e = wezterm("kill-pane", "--pane-id", strconv.Itoa(id)).Run(); e != nil {
			return e
		}
	}
	return nil
}

func exitCode(e error) int {
	if e == nil {
		return 0
	}
	var x *exec.ExitError
	if errors.As(e, &x) {
		if s, ok := x.Sys().(syscall.WaitStatus); ok && s.Signaled() {
			return 128 + int(s.Signal())
		}
		return x.ExitCode()
	}
	return 1
}

func ttyForeground(f *os.File, pid int) error {
	p := int32(pid)
	_, _, e := syscall.Syscall(syscall.SYS_IOCTL, f.Fd(), syscall.TIOCSPGRP, uintptr(unsafe.Pointer(&p)))
	if e != 0 {
		return e
	}
	return nil
}

func execute(a attempt, dir string, terminal bool) (int, error) {
	for k, v := range a.Env {
		if e := os.Setenv(k, v); e != nil {
			return 1, e
		}
	}
	if a.Task != "" {
		if _, e := validateTask(a.Task); e != nil {
			return 1, e
		}
	}
	if e := os.Chdir(a.Cwd); e != nil {
		return 1, e
	}
	if len(a.Argv) == 0 {
		return 1, errors.New("missing command")
	}
	var guard *os.File
	if a.Task != "" {
		key := fmt.Sprintf("%x", sha256.Sum256([]byte(a.Cwd)))
		var e error
		guard, e = lock(filepath.Join(dir, key+".worktree-lock"), true)
		if e != nil {
			return 1, fmt.Errorf("working directory is busy: %w", e)
		}
		defer func() { _ = guard.Close() }()
	}
	c := exec.Command(a.Argv[0], a.Argv[1:]...)
	c.Env = envWithout("CODEX_THREAD_ID", "CLAUDECODE", "WEZTERM_PANE")
	c.Stdin = os.Stdin
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	if !terminal {
		e := c.Run()
		return exitCode(e), e
	}
	tty, e := os.OpenFile("/dev/tty", os.O_RDWR, 0)
	if e != nil {
		return 1, e
	}
	defer func() { _ = tty.Close() }()
	signal.Ignore(syscall.SIGTTOU)
	c.Stdin = tty
	c.SysProcAttr = &syscall.SysProcAttr{Foreground: true, Ctty: int(tty.Fd())}
	if e = c.Start(); e != nil {
		return 1, e
	}
	defer func() { _ = ttyForeground(tty, syscall.Getpgrp()) }()
	done := make(chan error, 1)
	go func() { done <- c.Wait() }()
	signals := make(chan os.Signal, 1)
	signal.Notify(signals, syscall.SIGTERM, syscall.SIGHUP, syscall.SIGINT)
	defer signal.Stop(signals)
	stop := func() error {
		_ = syscall.Kill(-c.Process.Pid, syscall.SIGKILL)
		return <-done
	}
	var supervisor struct {
		PID int `json:"pid"`
	}
	if e = read(filepath.Join(dir, a.ID+".supervisor"), &supervisor); e != nil {
		return 1, errors.Join(e, stop())
	}
	ticker := time.NewTicker(200 * time.Millisecond)
	defer ticker.Stop()
	paused := false
	for {
		select {
		case e := <-done:
			code := exitCode(e)
			if writeErr := save(filepath.Join(dir, a.ID+".exit"), map[string]int{"code": code}); writeErr != nil {
				return 1, writeErr
			}
			// Hold the pane open so its output stays attachable after the command ends.
			_ = ttyForeground(tty, syscall.Getpgrp())
			_, _ = fmt.Fprintf(tty, "\n[tq] command exited with status %d; press Enter to close\n", code)
			_, _ = bufio.NewReader(tty).ReadString('\n')
			return code, e
		case s := <-signals:
			return 128 + int(s.(syscall.Signal)), errors.Join(fmt.Errorf("terminal interrupted: %s", s), stop())
		case <-ticker.C:
			if e := syscall.Kill(supervisor.PID, 0); e != nil {
				return 1, errors.Join(errors.New("queue supervisor disappeared"), stop())
			}
			ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
			b, queryErr := exec.CommandContext(ctx, "pueue", "status", "--json", "label="+labelPrefix+a.ID).Output()
			cancel()
			var snapshot struct {
				Tasks map[string]job `json:"tasks"`
			}
			if queryErr != nil {
				return 1, errors.Join(fmt.Errorf("queue unavailable: %w", queryErr), stop())
			}
			if e := json.Unmarshal(b, &snapshot); e != nil {
				return 1, errors.Join(e, stop())
			}
			j, exists := snapshot.Tasks[strconv.Itoa(*a.PueueID)]
			if !exists || state(j.Status) == "Done" {
				return 1, errors.Join(errors.New("queue job no longer running"), stop())
			}
			stopped := state(j.Status) == "Paused"
			if stopped != paused {
				sig := syscall.SIGCONT
				if stopped {
					sig = syscall.SIGSTOP
				}
				if e = syscall.Kill(-c.Process.Pid, sig); e != nil && !errors.Is(e, syscall.ESRCH) {
					return 1, errors.Join(e, stop())
				}
				paused = stopped
			}
		}
	}
}

func terminalRun(a attempt, dir string) (int, error) {
	if a.Task != "" {
		if _, e := validateTask(a.Task); e != nil {
			return 1, e
		}
	}
	for key, value := range a.Env {
		if e := os.Setenv(key, value); e != nil {
			return 1, e
		}
	}
	if e := save(filepath.Join(dir, a.ID+".supervisor"), map[string]int{"pid": os.Getpid()}); e != nil {
		return 1, e
	}
	self, e := os.Executable()
	if e != nil {
		return 1, e
	}
	spawn := wezterm("spawn", "--new-window", "--workspace", a.Terminal, "--cwd", a.Cwd, "--", self, "--state", dir, "terminal-child", a.ID)
	spawn.Stderr = os.Stderr
	if e = spawn.Run(); e != nil {
		return 1, fmt.Errorf("terminal spawn failed: %w", e)
	}
	signals := make(chan os.Signal, 1)
	signal.Notify(signals, syscall.SIGTERM, syscall.SIGINT)
	defer signal.Stop(signals)
	ticker := time.NewTicker(200 * time.Millisecond)
	defer ticker.Stop()
	exitRecord := filepath.Join(dir, a.ID+".exit")
	var result struct {
		Code int `json:"code"`
	}
	for {
		select {
		case s := <-signals:
			return 128 + int(s.(syscall.Signal)), errors.Join(errors.New("queue job cancelled"), killTerminal(a.Terminal))
		case <-ticker.C:
			if read(exitRecord, &result) == nil {
				return result.Code, nil
			}
			panes, e := terminalPanes(a.Terminal)
			if e != nil {
				return 1, e
			}
			if len(panes) == 0 {
				if read(exitRecord, &result) == nil {
					return result.Code, nil
				}
				return 1, errors.New("terminal disconnected without command exit record")
			}
		}
	}
}
