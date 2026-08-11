// Package registry wires together all provider implementations and exposes a
// single SelectProvider entry point that the CLI calls. It lives outside the
// provider package to avoid import cycles.
package registry

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/roshbhatia/specutil/internal/extract"
	"github.com/roshbhatia/specutil/internal/graph"
	"github.com/roshbhatia/specutil/internal/ir"
	"github.com/roshbhatia/specutil/internal/provider"
	"github.com/roshbhatia/specutil/internal/provider/bmad"
	openspecprovider "github.com/roshbhatia/specutil/internal/provider/openspec"
	"github.com/roshbhatia/specutil/internal/provider/plan"
	"github.com/roshbhatia/specutil/internal/provider/script"
)

// SelectProvider returns the appropriate Provider based on the 'from' value.
//   - When from is empty, auto-detection inspects the repo layout.
//   - path is the positional file-path argument (may be empty).
//   - providers is the list of script adapters from specutil.yaml.
//
// The returned provider applies the repository's extraction declaration to every
// change it loads, so no adapter needs to know about a spec framework's marker
// conventions.
func SelectProvider(from, repo, path string, providers []graph.ProviderConfig) (provider.Provider, error) {
	p, err := selectRaw(from, repo, path, providers)
	if err != nil {
		return nil, err
	}
	manifest, merr := graph.LoadManifest(repo)
	if merr != nil {
		// A malformed manifest is surfaced by the caller that loads it for the
		// dependency graph; extraction degrades to none rather than failing the
		// load twice for the same reason.
		return p, nil
	}
	cfg, cerr := manifest.ExtractConfig(repo)
	if cerr != nil {
		return nil, cerr
	}
	if cfg.IsZero() {
		return p, nil
	}
	return &extracting{Provider: p, cfg: cfg}, nil
}

// extracting decorates a provider with the post-parse extraction pass.
type extracting struct {
	provider.Provider
	cfg extract.Config
}

func (e *extracting) Load(name string) (*ir.Change, error) {
	c, err := e.Provider.Load(name)
	if err != nil {
		return nil, err
	}
	c.Warnings = append(c.Warnings, extract.Apply(e.cfg, c)...)
	return c, nil
}

func (e *extracting) LoadAll() ([]*ir.Change, error) {
	changes, err := e.Provider.LoadAll()
	if err != nil {
		return nil, err
	}
	for _, c := range changes {
		c.Warnings = append(c.Warnings, extract.Apply(e.cfg, c)...)
	}
	return changes, nil
}

// selectRaw resolves the undecorated provider for the 'from' value.
func selectRaw(from, repo, path string, providers []graph.ProviderConfig) (provider.Provider, error) {
	resolved := from
	if resolved == "" {
		var err error
		resolved, err = detect(repo)
		if err != nil {
			return nil, err
		}
	}

	switch resolved {
	case "openspec":
		return openspecprovider.New(repo), nil
	case "bmad":
		return bmad.New(repo, path), nil
	case "plan":
		return plan.New(repo, path), nil
	case "stdin":
		return plan.New(repo, "-"), nil
	default:
		for _, pc := range providers {
			if pc.Name == resolved {
				return script.New(repo, pc.Command), nil
			}
		}
		available := builtinNames()
		for _, pc := range providers {
			available = append(available, pc.Name)
		}
		sort.Strings(available)
		return nil, fmt.Errorf("unknown provider %q; available: %s", from, strings.Join(available, ", "))
	}
}

// detect auto-selects a provider by inspecting the repo layout.
// Order: openspec/changes/ → stories/*.md → plan.md
func detect(repo string) (string, error) {
	if _, err := os.Stat(filepath.Join(repo, "openspec", "changes")); err == nil {
		return "openspec", nil
	}
	if matches, _ := filepath.Glob(filepath.Join(repo, "stories", "*.md")); len(matches) > 0 {
		return "bmad", nil
	}
	if _, err := os.Stat(filepath.Join(repo, "plan.md")); err == nil {
		return "plan", nil
	}
	return "", fmt.Errorf("no spec provider detected in %s; specify --from openspec|bmad|plan|stdin or declare a script adapter in specutil.yaml", repo)
}

func builtinNames() []string { return []string{"bmad", "openspec", "plan", "stdin"} }
