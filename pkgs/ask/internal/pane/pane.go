// Package pane keeps a rolling copy of the terminal, so the last command's
// output can reach an agent without a pipe.
//
// WezTerm marks command boundaries with OSC 133, but `wezterm cli` does not
// expose the zones, so a shell hook records the boundary instead.
package pane

import (
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/ask/internal/store"
)

const (
	scrollback = "-400"
	widest     = 96 * 1024
)

func files() (prev string, now string, err error) {
	id := os.Getenv("WEZTERM_PANE")
	if id == "" {
		return "", "", errors.New("$WEZTERM_PANE is unset, so there is no pane to read")
	}
	dir := store.Dir()
	return filepath.Join(dir, "pane-"+id+"-prev"), filepath.Join(dir, "pane-"+id+"-now"), nil
}

func read() ([]byte, error) {
	binary, err := exec.LookPath("wezterm")
	if err != nil {
		return nil, errors.New("wezterm is not on PATH")
	}
	out, err := exec.Command(binary, "cli", "get-text", "--start-line", scrollback).Output()
	if err != nil {
		return nil, err
	}
	return out, nil
}

// Capture rotates the snapshots and takes a new one.
func Capture() error {
	prev, now, err := files()
	if err != nil {
		return err
	}
	text, err := read()
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(now), 0o700); err != nil {
		return err
	}
	if _, err := os.Stat(now); err == nil {
		if err := os.Rename(now, prev); err != nil {
			return err
		}
	}
	return os.WriteFile(now, text, 0o600)
}

// Last answers with what the previous command printed.
func Last() ([]byte, error) {
	prevPath, nowPath, err := files()
	if err != nil {
		return nil, err
	}
	now, err := os.ReadFile(nowPath)
	if err != nil {
		return nil, errors.New("no pane snapshot yet; the shell hook has not run")
	}
	prev, err := os.ReadFile(prevPath)
	if err != nil {
		prev = nil
	}

	grown := Delta(lines(prev), lines(now))
	if len(grown) == 0 {
		return nil, errors.New("the previous command printed nothing")
	}
	return trim([]byte(strings.Join(grown, "\n"))), nil
}

func lines(text []byte) []string {
	cut := strings.Split(strings.ReplaceAll(string(text), "\r\n", "\n"), "\n")
	for len(cut) > 0 && strings.TrimSpace(cut[len(cut)-1]) == "" {
		cut = cut[:len(cut)-1]
	}
	return cut
}

// Delta answers with the lines that appeared between two snapshots. A rolled
// scrollback leaves no shared prefix, so it then anchors on the older snapshot's
// last line, which is the prompt the previous command was typed at.
func Delta(prev, now []string) []string {
	if len(prev) == 0 {
		return now
	}

	shared := 0
	for shared < len(prev) && shared < len(now) && prev[shared] == now[shared] {
		shared++
	}
	if shared == len(prev) {
		return now[shared:]
	}

	anchor := prev[len(prev)-1]
	for at := len(now) - 1; at >= 0; at-- {
		if now[at] == anchor {
			return now[at+1:]
		}
	}
	return now[shared:]
}

// trim keeps the tail, as the end of a failing command says why it failed.
func trim(text []byte) []byte {
	if len(text) <= widest {
		return text
	}
	cut := text[len(text)-widest:]
	if at := strings.IndexByte(string(cut), '\n'); at >= 0 {
		cut = cut[at+1:]
	}
	return append([]byte("[earlier output cut]\n"), cut...)
}
