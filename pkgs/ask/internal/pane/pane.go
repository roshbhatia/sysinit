// Package pane keeps a rolling copy of the terminal so the last command's
// output can be handed to an agent without piping it there first.
//
// WezTerm marks command boundaries with OSC 133, but `wezterm cli` does not
// expose the zones, so the boundary has to be recorded from the shell. A hook
// snapshots the pane before every command; the text that appeared between two
// snapshots is one command's output.
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
	// scrollback is how far above the screen a snapshot reaches. It bounds both
	// the snapshot cost and the size of what an agent can be handed.
	scrollback = "-400"

	// widest is the most output handed on, in bytes. A build log runs to
	// megabytes and the agent charges for every one of them.
	widest = 96 * 1024
)

func files() (prev string, now string, err error) {
	id := os.Getenv("WEZTERM_PANE")
	if id == "" {
		return "", "", errors.New("$WEZTERM_PANE is unset, so there is no pane to read")
	}
	dir := store.Dir()
	return filepath.Join(dir, "pane-"+id+"-prev"), filepath.Join(dir, "pane-"+id+"-now"), nil
}

// read asks WezTerm for the pane as plain text, with no escape sequences.
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

// Capture rotates the snapshots and takes a new one. The shell calls it before
// every command, so it has to stay quiet: a pane it cannot read is not an error
// worth interrupting a prompt over.
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

// Delta answers with the lines that appeared between two snapshots. The usual
// case is a clean append. When the scrollback has rolled past the older
// snapshot the two no longer share a prefix, so it anchors on the last line of
// the older one instead, which is the prompt the previous command was typed at.
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

// trim keeps the tail, because the end of a failing command says why it failed
// and the start says what it was doing.
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
