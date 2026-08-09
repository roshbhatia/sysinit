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
	"sync"
)

// Keys the manifest carries. Named rather than typed as strings at each call
// site, so a typo is a compile error instead of an empty path.
const (
	StateHomeKey     = "stateHome"
	AgentsKey        = "agents"
	AgentPanesKey    = "agentPanes"
	AgentDiffNotes   = "agentDiffNotes"
	SeshySessionsKey = "seshySessions"
)

type document struct {
	Paths map[string]string `json:"paths"`
}

var (
	once   sync.Once
	loaded map[string]string
)

// manifestFile is the one fact the manifest cannot carry, so it is the single
// bootstrap constant of this package.
func manifestFile() string {
	if override := os.Getenv("SYSINIT_PATHS_MANIFEST"); override != "" {
		return override
	}
	return filepath.Join(fallbackStateHome(), "sysinit", "paths.json")
}

// sysinit:documented-default
//
// The one default in this package, reached only when the manifest is absent.
// Phase 9 builds a box with `go install` and no Nix, and until the manifest is
// installed there a consumer with no default cannot resolve a path at all.
func fallbackStateHome() string {
	if home := strings.TrimRight(os.Getenv("XDG_STATE_HOME"), "/"); home != "" {
		return home
	}
	return filepath.Join(os.Getenv("HOME"), ".local", "state")
}

func load() map[string]string {
	once.Do(func() {
		raw, err := os.ReadFile(manifestFile())
		if err != nil {
			return
		}
		var doc document
		if err := json.Unmarshal(raw, &doc); err != nil {
			return
		}
		loaded = doc.Paths
	})
	return loaded
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
