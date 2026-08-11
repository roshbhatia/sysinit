package graph

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/roshbhatia/specutil/internal/check"
	"github.com/roshbhatia/specutil/internal/extract"
	"gopkg.in/yaml.v3"
)

// ManifestFile is the repo-relative path of the cross-change dependency
// manifest. It is deliberately separate from OpenSpec's .openspec.yaml so the
// dependency model stays framework-agnostic.
const ManifestFile = "openspec/specutil.yaml"

// Manifest is the hand-editable, repo-level dependency DAG. It accepts two
// equivalent spellings of the same edge set, because both appear in the wild:
//
//   - changes.<name>.depends_on — each change lists its prerequisites, so
//     `add-auth.depends_on: [add-db]` yields edge add-db -> add-auth.
//   - edges — an explicit from/to list, where from is the prerequisite.
//
// Both are merged and deduplicated by edges().
type Manifest struct {
	Changes   map[string]ManifestEntry `yaml:"changes"`
	Edges     []Edge                   `yaml:"edges"`
	Providers []ProviderConfig         `yaml:"providers"`
	// Extract declares the schema-specific markers and inline fields to lift
	// out of parsed artifacts. Absent means "detect from the spec framework's
	// own config, and extract nothing if that is unrecognized".
	Extract extract.Config `yaml:"extract"`
	// Check declares the rubric `specutil check` enforces. Absent follows the
	// same detection rule as Extract.
	Check check.Config `yaml:"check"`
}

// CheckConfig returns the effective rubric for a repository, following the same
// precedence as ExtractConfig: an explicit `check:` block wins, otherwise the
// spec framework's declared schema selects a matching built-in preset, and an
// unrecognized name enforces nothing.
func (m *Manifest) CheckConfig(repoRoot string) (check.Config, error) {
	if m != nil && !m.Check.IsZero() {
		return m.Check, nil
	}
	name := detectSchemaName(repoRoot)
	if name == "" || !check.HasPreset(name) {
		return check.Config{}, nil
	}
	return check.Config{Preset: name}, nil
}

// schemaConfigFile is the spec framework's own config, read only to detect
// which extraction preset applies when specutil.yaml does not say.
const schemaConfigFile = "openspec/config.yaml"

// ExtractConfig returns the effective extraction declaration for a repository.
// An explicit `extract:` block wins. Otherwise the spec framework's declared
// schema name selects a matching built-in preset, and an unrecognized name
// extracts nothing rather than guessing.
func (m *Manifest) ExtractConfig(repoRoot string) (extract.Config, error) {
	if m != nil && !m.Extract.IsZero() {
		return extract.Resolve(m.Extract)
	}
	name := detectSchemaName(repoRoot)
	if name == "" || !extract.HasPreset(name) {
		return extract.Config{}, nil
	}
	return extract.Resolve(extract.Config{Preset: name})
}

// detectSchemaName reads the `schema:` key from the spec framework's config.
// An absent or unreadable file yields an empty name, never an error: detection
// is a convenience, and a repository without one simply extracts nothing.
func detectSchemaName(repoRoot string) string {
	b, err := os.ReadFile(filepath.Join(repoRoot, schemaConfigFile))
	if err != nil {
		return ""
	}
	var cfg struct {
		Schema string `yaml:"schema"`
	}
	if err := yaml.Unmarshal(b, &cfg); err != nil {
		return ""
	}
	return strings.TrimSpace(cfg.Schema)
}

// ManifestEntry is one change's manifest record.
type ManifestEntry struct {
	DependsOn []string `yaml:"depends_on"`
}

// ProviderConfig declares a user-defined script adapter. The script is executed
// with {change} substituted by the --change value; its stdout is parsed as
// openspec-compatible markdown.
type ProviderConfig struct {
	Name    string `yaml:"name"`
	Command string `yaml:"command"`
}

// LoadManifest reads <repoRoot>/openspec/specutil.yaml. An absent file is not an
// error — it yields an empty manifest so a repo with no declared dependencies
// still produces a valid (edgeless) graph.
func LoadManifest(repoRoot string) (*Manifest, error) {
	path := filepath.Join(repoRoot, ManifestFile)
	b, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return &Manifest{}, nil
		}
		return nil, fmt.Errorf("reading %s: %w", path, err)
	}
	var m Manifest
	if err := yaml.Unmarshal(b, &m); err != nil {
		return nil, fmt.Errorf("parsing %s: %w", path, err)
	}
	return &m, nil
}

// edges flattens both manifest spellings into a deterministic, deduplicated
// directed edge list (prerequisite -> dependent).
func (m *Manifest) edges() []Edge {
	if m == nil {
		return nil
	}
	names := make([]string, 0, len(m.Changes))
	for name := range m.Changes {
		names = append(names, name)
	}
	sort.Strings(names)

	seen := make(map[Edge]bool)
	var edges []Edge
	add := func(e Edge) {
		if e.From == "" || e.To == "" || seen[e] {
			return
		}
		seen[e] = true
		edges = append(edges, e)
	}
	for _, dependent := range names {
		deps := append([]string(nil), m.Changes[dependent].DependsOn...)
		sort.Strings(deps)
		for _, prereq := range deps {
			add(Edge{From: prereq, To: dependent})
		}
	}
	for _, e := range m.Edges {
		add(e)
	}
	return edges
}
