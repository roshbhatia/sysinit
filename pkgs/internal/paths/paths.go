package paths

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
)

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

func manifestFile() string {
	if override := os.Getenv("SYSINIT_PATHS_MANIFEST"); override != "" {
		return override
	}
	return filepath.Join(fallbackStateHome(), "sysinit", "paths.json")
}

func fallbackStateHome() string { return StateHome() }

func StateHome() string {
	if home := strings.TrimRight(os.Getenv("XDG_STATE_HOME"), "/"); home != "" {
		return home
	}
	return filepath.Join(home(), ".local", "state")
}

func ConfigHome() string {
	if dir := strings.TrimRight(os.Getenv("XDG_CONFIG_HOME"), "/"); dir != "" {
		return dir
	}
	return filepath.Join(home(), ".config")
}

func home() string {
	if dir := os.Getenv("HOME"); dir != "" {
		return dir
	}
	dir, err := os.UserHomeDir()
	if err != nil {
		return ""
	}
	return dir
}

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

func Get(key string) (string, bool) {
	value, ok := load()[key]
	if !ok || value == "" {
		return "", false
	}
	return strings.TrimRight(value, "/"), true
}

func SeshySessions() string {
	if value, ok := Get(SeshySessionsKey); ok {
		return value
	}
	return filepath.Join(fallbackStateHome(), "seshy", "sessions")
}

func AgentPanes() string {
	if value, ok := Get(AgentPanesKey); ok {
		return value
	}
	return filepath.Join(fallbackStateHome(), "agents", "panes")
}

func AgentDiffNotes() string {
	if value, ok := Get(AgentDiffNotesKey); ok {
		return value
	}
	return filepath.Join(fallbackStateHome(), "agents", "diff-notes")
}

func AgentEdits() string {
	if value, ok := Get(AgentEditsKey); ok {
		return value
	}
	return filepath.Join(fallbackStateHome(), "agents", "edits")
}

func AgentWtrun() string {
	if value, ok := Get(AgentWtrunKey); ok {
		return value
	}
	return filepath.Join(fallbackStateHome(), "agents", "wtrun")
}

func AgentWorker() string {
	if value, ok := Get(AgentWorkerKey); ok {
		return value
	}
	return filepath.Join(fallbackStateHome(), "agents", "worker")
}

func AgentTranscripts() string {
	if value, ok := Get(AgentTranscriptsKey); ok {
		return value
	}
	return filepath.Join(fallbackStateHome(), "agents", "transcripts")
}

func AgentWorklog() string {
	if value, ok := Get(AgentWorklogKey); ok {
		return value
	}
	return filepath.Join(fallbackStateHome(), "agents", "worklog.jsonl")
}
