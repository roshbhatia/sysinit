package main

import (
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
			return code, e
		case s := <-signals:
			return 128 + int(s.(syscall.Signal)), errors.Join(fmt.Errorf("terminal interrupted: %s", s), stop())
		case <-ticker.C:
			if e := syscall.Kill(supervisor.PID, 0); e != nil {
				return 1, errors.Join(errors.New("queue supervisor disappeared"), stop())
			}
			ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
			b, queryErr := exec.CommandContext(ctx, "pueue", "status", "--json", "label=task-queue:"+a.ID).Output()
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
	c := exec.Command("zmx", "run", a.Terminal, self, "--state", dir, "terminal-child", a.ID)
	c.Dir = a.Cwd
	c.Env = envWithout("ZMX_SESSION", "ZMX_SESSION_PREFIX", "CODEX_THREAD_ID", "CLAUDECODE", "WEZTERM_PANE")
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	if e = c.Start(); e != nil {
		return 1, e
	}
	done := make(chan error, 1)
	go func() { done <- c.Wait() }()
	signals := make(chan os.Signal, 1)
	signal.Notify(signals, syscall.SIGTERM, syscall.SIGINT)
	defer signal.Stop(signals)
	select {
	case waitErr := <-done:
		if waitErr != nil {
			return exitCode(waitErr), fmt.Errorf("terminal client failed: %w", waitErr)
		}
	case s := <-signals:
		k := exec.Command("zmx", "kill", a.Terminal, "--force")
		k.Env = c.Env
		_ = k.Run()
		return 128 + int(s.(syscall.Signal)), errors.Join(errors.New("queue job cancelled"), <-done)
	}
	var result struct {
		Code int `json:"code"`
	}
	if e = read(filepath.Join(dir, a.ID+".exit"), &result); e != nil {
		return 1, fmt.Errorf("terminal disconnected without command exit record: %w", e)
	}
	return result.Code, nil
}
