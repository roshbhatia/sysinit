package registry

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/roshbhatia/specutil/internal/extract"
	"github.com/roshbhatia/specutil/internal/graph"
	"github.com/roshbhatia/specutil/internal/ir"
	"github.com/roshbhatia/specutil/internal/provider"
	openspecprovider "github.com/roshbhatia/specutil/internal/provider/openspec"
)

func SelectProvider(repo string) (provider.Provider, error) {
	if _, err := os.Stat(filepath.Join(repo, "openspec", "changes")); err != nil {
		return nil, fmt.Errorf("no openspec/changes directory in %s", repo)
	}
	p := provider.Provider(openspecprovider.New(repo))

	manifest, merr := graph.LoadManifest(repo)
	if merr != nil {
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
