package syncplan

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"

	"gopkg.in/yaml.v3"
)

// LockVersion is the on-disk schema version of the lockfile.
const LockVersion = 1

// Lock is the per-change identity map. It is namespaced by target so the same
// item can map to both a Linear issue and a Notion page without collision.
// External IDs live ONLY here, never in OpenSpec source artifacts.
type Lock struct {
	Version int                       `yaml:"version"`
	Targets map[string]map[string]Ref `yaml:"targets"`
}

// Ref is one lock entry: the external system's ID plus the content hash that
// was current when it was recorded, enabling drift detection. Title retains the
// item's text at record time so diff can fuzzy re-match an item whose
// normalized identity changed (a larger edit) instead of reporting a spurious
// orphan + new pair.
type Ref struct {
	ExternalID  string `yaml:"external_id"`
	ContentHash string `yaml:"content_hash,omitempty"`
	Title       string `yaml:"title,omitempty"`
}

// LockPath returns the lockfile path for a change.
func LockPath(repoRoot, change string) string {
	return filepath.Join(repoRoot, "openspec", "changes", change, "specutil.lock.yaml")
}

// LoadLock reads a change's lockfile. An absent file yields an empty,
// initialized lock (not an error) so the first plan/set works seamlessly.
func LoadLock(repoRoot, change string) (*Lock, error) {
	path := LockPath(repoRoot, change)
	b, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return &Lock{Version: LockVersion, Targets: map[string]map[string]Ref{}}, nil
		}
		return nil, fmt.Errorf("reading %s: %w", path, err)
	}
	var l Lock
	if err := yaml.Unmarshal(b, &l); err != nil {
		return nil, fmt.Errorf("parsing %s: %w", path, err)
	}
	if l.Targets == nil {
		l.Targets = map[string]map[string]Ref{}
	}
	if l.Version == 0 {
		l.Version = LockVersion
	}
	return &l, nil
}

// Save writes the lock back deterministically. yaml.v3 emits map keys sorted,
// so identical state produces identical bytes.
func (l *Lock) Save(repoRoot, change string) error {
	path := LockPath(repoRoot, change)
	b, err := yaml.Marshal(l)
	if err != nil {
		return fmt.Errorf("encoding lock: %w", err)
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return fmt.Errorf("creating change dir: %w", err)
	}
	return os.WriteFile(path, b, 0o644)
}

// Get returns the ref for an identity under a target, and whether it exists.
func (l *Lock) Get(target, identity string) (Ref, bool) {
	ns := l.Targets[target]
	if ns == nil {
		return Ref{}, false
	}
	r, ok := ns[identity]
	return r, ok
}

// Set records or replaces the ref for an identity under a target.
func (l *Lock) Set(target, identity string, ref Ref) {
	if l.Targets == nil {
		l.Targets = map[string]map[string]Ref{}
	}
	if l.Targets[target] == nil {
		l.Targets[target] = map[string]Ref{}
	}
	l.Targets[target][identity] = ref
}

// Identities returns the sorted identity keys recorded for a target.
func (l *Lock) Identities(target string) []string {
	ns := l.Targets[target]
	out := make([]string, 0, len(ns))
	for id := range ns {
		out = append(out, id)
	}
	sort.Strings(out)
	return out
}
