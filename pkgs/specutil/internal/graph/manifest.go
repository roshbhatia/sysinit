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

const ManifestFile = "openspec/specutil.yaml"

type Manifest struct {
	Changes map[string]ManifestEntry `yaml:"changes"`
	Edges   []Edge                   `yaml:"edges"`

	Extract extract.Config `yaml:"extract"`

	Check check.Config `yaml:"check"`
}

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

const schemaConfigFile = "openspec/config.yaml"

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

type ManifestEntry struct {
	DependsOn []string `yaml:"depends_on"`
}

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
