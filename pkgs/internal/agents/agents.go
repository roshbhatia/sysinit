// Package agents reads ~/.config/sysinit/agents.json, the one generated list of
// who the agents are. Nix renders it from modules/home/programs/llm/harnesses/
// registry.nix, so a reader here keeps no second copy of the roster.
package agents

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/internal/paths"
)

// Agent is one entry. Every field past Command is optional: the file predates
// them, so a reader has to work when one is absent rather than assume a switch
// has already written the richer shape.
type Agent struct {
	Name    string `json:"name"`
	Label   string `json:"label"`
	Glyph   string `json:"glyph"`
	Command string `json:"command"`
	ACP     bool   `json:"acp"`
	Launch  struct {
		ModelFlag string `json:"modelFlag"`
	} `json:"launch"`

	Notify         string `json:"notify"`
	EditBus        bool   `json:"editBus"`
	ContextDir     string `json:"contextDir"`
	TranscriptRoot string `json:"transcriptRoot"`
	// Guard's type is the registry's to choose, so it is held raw rather than
	// decoded into a guess that would fail the whole file.
	Guard json.RawMessage `json:"guard"`
}

type Registry struct {
	Version int     `json:"version"`
	Agents  []Agent `json:"agents"`
}

func Path() string {
	return filepath.Join(paths.ConfigHome(), "sysinit", "agents.json")
}

// Load reads the registry. A field whose type does not match is skipped rather
// than fatal, so adding a field of an unexpected type degrades one accessor
// instead of blanking the roster.
func Load() (Registry, error) {
	var reg Registry
	data, err := os.ReadFile(Path())
	if err != nil {
		return reg, err
	}
	if err := json.Unmarshal(data, &reg); err != nil {
		var mismatch *json.UnmarshalTypeError
		if !errors.As(err, &mismatch) {
			return Registry{}, err
		}
	}
	return reg, nil
}

func (r Registry) Find(name string) (Agent, bool) {
	for _, agent := range r.Agents {
		if agent.Name == name {
			return agent, true
		}
	}
	return Agent{}, false
}

// TranscriptRoot is the directory a harness writes its own transcripts under,
// already expanded. It is empty when the agent or the field is absent.
func TranscriptRoot(name string) string {
	reg, err := Load()
	if err != nil {
		return ""
	}
	agent, ok := reg.Find(name)
	if !ok {
		return ""
	}
	return Expand(agent.TranscriptRoot)
}

// ContextDirs is the top directory of every agent's context path, as a
// gitignore entry: `~/.atomic/agent/` yields `.atomic/`. A session holding one
// agent's config has to keep it trackable, and the entry is the same for every
// depth the registry declares.
func ContextDirs() []string {
	reg, err := Load()
	if err != nil {
		return nil
	}
	seen := map[string]bool{}
	var out []string
	for _, agent := range reg.Agents {
		entry := topDir(agent.ContextDir)
		if entry == "" || seen[entry] {
			continue
		}
		seen[entry] = true
		out = append(out, entry)
	}
	sort.Strings(out)
	return out
}

// topDir reduces a declared context path to its first directory under the home
// directory, with a trailing slash so gitignore reads it as a directory.
func topDir(declared string) string {
	trimmed := strings.TrimSpace(declared)
	// Some registry entries describe a command rather than a path, such as
	// "codex `context`". Neither character can appear in one of these paths.
	if trimmed == "" || strings.ContainsAny(trimmed, " `") {
		return ""
	}
	rest := strings.TrimPrefix(strings.TrimPrefix(trimmed, "~"), "/")
	parts := strings.Split(rest, "/")
	first := parts[0]
	if first == "" || first == "." || first == ".." {
		return ""
	}
	// One segment and no trailing slash is a file at the home root, which names
	// no directory to negate.
	if len(parts) == 1 {
		return ""
	}
	return first + "/"
}

// Expand resolves a leading ~ against the home directory.
func Expand(path string) string {
	if path == "" {
		return ""
	}
	if path != "~" && !strings.HasPrefix(path, "~/") {
		return path
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return ""
	}
	return filepath.Join(home, strings.TrimPrefix(strings.TrimPrefix(path, "~"), "/"))
}
