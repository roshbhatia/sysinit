// Package paths reads the sysinit paths manifest.
package paths

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
)

// Keys the manifest carries.
const (
	StateHomeKey        = "stateHome"
	AgentsKey           = "agents"
	AgentPanesKey       = "agentPanes"
	AgentDiffNotesKey   = "agentDiffNotes"
	AgentEditsKey       = "agentEdits"
	AgentWtrunKey       = "agentWtrun"
	AgentWorkerKey      = "agentWorker"
	AgentTranscriptsKey = "agentTranscripts"
	AgentWorklogKey     = "agentWorklog"
	SeshySessionsKey    = "seshySessions"
)

type document struct {
	Paths map[string]string `json:"paths"`
}

// manifestFile is the one fact the manifest cannot carry, so it is the single
func manifestFile() string {
	if override := os.Getenv("SYSINIT_PATHS_MANIFEST"); override != "" {
		return override
	}
	return filepath.Join(fallbackStateHome(), "sysinit", "paths.json")
}

// The one default in this package, reached only when the manifest is absent.
func fallbackStateHome() string {
	if home := strings.TrimRight(os.Getenv("XDG_STATE_HOME"), "/"); home != "" {
		return home
	}
	// sysinit:documented-default
	return filepath.Join(os.Getenv("HOME"), ".local", "state")
}

// load re-reads the manifest on every call rather than caching it.
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

// AgentEdits is the directory holding one edit-event log per workspace.
func AgentEdits() string {
	if value, ok := Get(AgentEditsKey); ok {
		return value
	}
	return filepath.Join(fallbackStateHome(), "agents", "edits")
}

// AgentWtrun is the directory the superseded `wtrun` script writes its per-pane
// logs under. Kept only so the two implementations can run side by side, and so
// the prune can find what the script left behind; nothing new writes here.
func AgentWtrun() string {
	if value, ok := Get(AgentWtrunKey); ok {
		return value
	}
	return filepath.Join(fallbackStateHome(), "agents", "wtrun")
}

// AgentWorker is the directory holding one keyed record per workspace: the pane
// id, its mux generation, the run counter, and every run's log and exit code.
func AgentWorker() string {
	if value, ok := Get(AgentWorkerKey); ok {
		return value
	}
	return filepath.Join(fallbackStateHome(), "agents", "worker")
}

// AgentTranscripts is the directory holding mirrored harness transcripts, laid
func AgentTranscripts() string {
	if value, ok := Get(AgentTranscriptsKey); ok {
		return value
	}
	return filepath.Join(fallbackStateHome(), "agents", "transcripts")
}

// AgentWorklog is the file each session appends one record to. A file rather
// than a directory, so the fallback names it.
func AgentWorklog() string {
	if value, ok := Get(AgentWorklogKey); ok {
		return value
	}
	return filepath.Join(fallbackStateHome(), "agents", "worklog.jsonl")
}
