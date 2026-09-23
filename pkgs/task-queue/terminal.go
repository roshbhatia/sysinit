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
	c.Env = envWithout("ORC_SESSION_ID", "ORC_SCOPE", "CODEX_THREAD_ID", "CLAUDECODE", "WEZTERM_PANE")
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
	stop := func() {
		_ = syscall.Kill(-c.Process.Pid, syscall.SIGKILL)
		<-done
	}
	var supervisor struct {
		PID int `json:"pid"`
	}
	if e = read(filepath.Join(dir, a.ID+".supervisor"), &supervisor); e != nil {
		stop()
		return 1, e
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
			stop()
			return 128 + int(s.(syscall.Signal)), fmt.Errorf("terminal interrupted: %s", s)
		case <-ticker.C:
			if e := syscall.Kill(supervisor.PID, 0); e != nil {
				stop()
				return 1, errors.New("queue supervisor disappeared")
			}
			ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
			b, queryErr := exec.CommandContext(ctx, "pueue", "status", "--json", "label=task-queue:"+a.ID).Output()
			cancel()
			var snapshot struct {
				Tasks map[string]job `json:"tasks"`
			}
			if queryErr != nil {
				stop()
				return 1, fmt.Errorf("queue unavailable: %w", queryErr)
			}
			if e := json.Unmarshal(b, &snapshot); e != nil {
				stop()
				return 1, e
			}
			j, exists := snapshot.Tasks[strconv.Itoa(*a.PueueID)]
			if !exists || state(j.Status) == "Done" {
				stop()
				return 1, errors.New("queue job no longer running")
			}
			stopped := state(j.Status) == "Paused"
			if stopped != paused {
				sig := syscall.SIGCONT
				if stopped {
					sig = syscall.SIGSTOP
				}
				if e = syscall.Kill(-c.Process.Pid, sig); e != nil && !errors.Is(e, syscall.ESRCH) {
					stop()
					return 1, e
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
	c.Env = envWithout("ZMX_SESSION", "ZMX_SESSION_PREFIX", "ORC_SESSION_ID", "ORC_SCOPE", "CODEX_THREAD_ID", "CLAUDECODE", "WEZTERM_PANE")
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
	case <-done:
	case s := <-signals:
		k := exec.Command("zmx", "kill", a.Terminal, "--force")
		k.Env = c.Env
		_ = k.Run()
		<-done
		return 128 + int(s.(syscall.Signal)), errors.New("queue job cancelled")
	}
	var result struct {
		Code int `json:"code"`
	}
	if e = read(filepath.Join(dir, a.ID+".exit"), &result); e != nil {
		return 1, fmt.Errorf("terminal disconnected without command exit record: %w", e)
	}
	return result.Code, nil
}
