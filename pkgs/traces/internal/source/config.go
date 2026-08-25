package source

import (
	"encoding/json"
	"maps"
	"os"
	"path/filepath"
	"slices"
	"sort"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/internal/paths"
)

// A source is declared per harness, not once for the machine. TRACES_PROVIDER
// was one flat list, so every source ran for every read: `traces --service
// codex` still queried Observe over the network for spans no codex run can have,
// and a machine that needed one extra source for one harness had to name every
// other source again beside it.
//
// Defaults cover the machine that configures nothing. Each harness that keeps
// its own activity on disk reads it; every other harness reaches the local
// collector, which traces always reads.
var Defaults = map[string][]string{
	"claude-code":  {"claude"},
	"codex":        {"codex"},
	"codex_cli_rs": {"codex"},
	"opencode":     {"opencode"},
}

// ConfigEnv points the reader at another config file, for a test and for a
// one-off read of another machine's declaration.
const ConfigEnv = "SYSINIT_TRACES_CONFIG"

type document struct {
	// Providers maps a service name to the sources that answer for it. A name
	// that is not a harness is read as a source that answers for every harness,
	// which is what a machine-wide source like a remote store is.
	Providers map[string][]string `json:"providers"`
}

// ConfigFile is where home-manager writes the declaration.
func ConfigFile() string {
	if override := os.Getenv(ConfigEnv); override != "" {
		return override
	}
	return filepath.Join(paths.ConfigHome(), "sysinit", "traces.json")
}

// Config is the per-harness source table: the defaults, with the config file
// merged over them. A harness named in the file replaces its default rather than
// adding to it, so a machine can take a source away as well as add one.
func Config() map[string][]string {
	out := map[string][]string{}
	maps.Copy(out, Defaults)

	blob, err := os.ReadFile(ConfigFile())
	if err != nil {
		return out
	}
	var doc document
	if json.Unmarshal(blob, &doc) != nil {
		// A malformed file is not worth failing the whole view over: the
		// defaults still draw every harness that keeps its work on disk.
		return out
	}
	for harness, list := range doc.Providers {
		kept := []string{}
		for _, one := range list {
			if one = strings.TrimSpace(one); one != "" {
				kept = append(kept, one)
			}
		}
		if len(kept) == 0 {
			delete(out, harness)
			continue
		}
		out[harness] = kept
	}
	return out
}

// wanted is every source the table names, once each, in a stable order. The
// order decides which source a duplicate name is attributed to, and an unstable
// one would move a provider between harnesses between runs.
func wanted(table map[string][]string, service string) []*Provider {
	harnesses := slices.Sorted(maps.Keys(table))
	out, seen := []*Provider{}, map[string]*Provider{}
	for _, harness := range harnesses {
		for _, name := range table[harness] {
			if found, ok := seen[name]; ok {
				// One source can answer for two harnesses. It is fetched once,
				// and it is skipped only when neither harness is wanted.
				found.harnesses = append(found.harnesses, harness)
				continue
			}
			one := &Provider{Name: name, harnesses: []string{harness}}
			seen[name] = one
			out = append(out, one)
		}
	}
	if service == "" {
		return out
	}
	kept := []*Provider{}
	for _, one := range out {
		if one.answers(service) {
			kept = append(kept, one)
		}
	}
	return kept
}

// answers reports whether this source can hold anything for the service the
// reader asked for. A prefix matches, because `codex` is what a reader types for
// `codex_cli_rs`, and the service filter matches the same way.
func (p Provider) answers(service string) bool {
	if service == "" || len(p.harnesses) == 0 {
		return true
	}
	for _, harness := range p.harnesses {
		if strings.HasPrefix(harness, service) || strings.HasPrefix(service, harness) {
			return true
		}
	}
	return false
}

// For names the harnesses a source answers for, so the header can say what it
// was read for rather than only that it was read.
func (p Provider) For() string {
	if len(p.harnesses) == 0 {
		return ""
	}
	out := append([]string{}, p.harnesses...)
	sort.Strings(out)
	return strings.Join(out, "+")
}
