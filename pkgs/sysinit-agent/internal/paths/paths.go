// Package paths reads the sysinit paths manifest.
//
// The manifest holds absolute paths and `modules/shared/options/paths-layout.json`
// is the only place the layout is written down. Every Go consumer reads it here,
// so this file is the only one in the module that can name a state path.
//
// Absolute rather than composed, because a process launched from a mux server
// inherits no session variables, so XDG_STATE_HOME is unset in exactly the
// place a composed path would run.
package paths

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
)

// Keys the manifest carries. Named rather than typed as strings at each call
// site, so a typo is a compile error instead of an empty path.
const (
	StateHomeKey      = "stateHome"
	AgentsKey         = "agents"
	AgentPanesKey     = "agentPanes"
	AgentDiffNotesKey = "agentDiffNotes"
	SeshySessionsKey  = "seshySessions"
)

type document struct {
	Paths map[string]string `json:"paths"`
}

// manifestFile is the one fact the manifest cannot carry, so it is the single
// bootstrap constant of this package.
func manifestFile() string {
	if override := os.Getenv("SYSINIT_PATHS_MANIFEST"); override != "" {
		return override
	}
	return filepath.Join(fallbackStateHome(), "sysinit", "paths.json")
}

// The one default in this package, reached only when the manifest is absent.
// Phase 9 builds a box with `go install` and no Nix, and until the manifest is
// installed there a consumer with no default cannot resolve a path at all.
func fallbackStateHome() string {
	if home := strings.TrimRight(os.Getenv("XDG_STATE_HOME"), "/"); home != "" {
		return home
	}
	// sysinit:documented-default
	return filepath.Join(os.Getenv("HOME"), ".local", "state")
}

// load re-reads the manifest on every call rather than caching it.
//
// A cache would be free in a process that runs once and exits, which is every
// real caller, but it makes the answer depend on which lookup happened first.
// A test that sets HOME or XDG_STATE_HOME would then get whatever an earlier
// test in the same binary resolved, and pass or fail on test order.
func load() map[string]string {
	raw, err := os.ReadFile(manifestFile())
	if err != nil {
		return nil
	}
	var doc document
	if err := json.Unmarshal(raw, &doc); err != nil {
		return nil
	}
	return doc.Paths
}

// Get returns the manifest's value for key, and whether the manifest had one.
func Get(key string) (string, bool) {
	value, ok := load()[key]
	if !ok || value == "" {
		return "", false
	}
	return strings.TrimRight(value, "/"), true
}

// StateHome is the root every other state path sits under.
//
// The trailing slash is trimmed because the fallback branch is the one that
// runs in practice, and a trailing slash would key the same repository on a
// second path.
func StateHome() string {
	if value, ok := Get(StateHomeKey); ok {
		return value
	}
	return fallbackStateHome()
}

// SeshySessions is the root seshy checks out sessions under.
func SeshySessions() string {
	if value, ok := Get(SeshySessionsKey); ok {
		return value
	}
	return filepath.Join(fallbackStateHome(), "seshy", "sessions")
}

// AgentPanes is the directory holding one record per agent pane.
//
// Read as its own key rather than composed under StateHome, because ui.lua
// reads the same key and a composed path would let the two disagree whenever
// the manifest's stateHome and the reader's own root differ.
func AgentPanes() string {
	if value, ok := Get(AgentPanesKey); ok {
		return value
	}
	return filepath.Join(fallbackStateHome(), "agents", "panes")
}

// AgentDiffNotes is the directory holding the note record and its export.
func AgentDiffNotes() string {
	if value, ok := Get(AgentDiffNotesKey); ok {
		return value
	}
	return filepath.Join(fallbackStateHome(), "agents", "diff-notes")
}
