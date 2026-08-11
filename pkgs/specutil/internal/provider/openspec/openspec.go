// Package openspec implements the Provider port against an on-disk OpenSpec
// layout: openspec/changes/<name>/{proposal.md,design.md,tasks.md,specs/<cap>/spec.md}.
// It only reads the local filesystem; it never touches the network.
package openspec

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/roshbhatia/specutil/internal/ir"
	"github.com/roshbhatia/specutil/internal/parse"
	"github.com/roshbhatia/specutil/internal/provider"
)

// Provider loads OpenSpec changes rooted at a repository directory.
type Provider struct {
	// Root is the repository root containing the openspec/ directory.
	Root string
}

// New returns an OpenSpec provider rooted at repoRoot.
func New(repoRoot string) *Provider { return &Provider{Root: repoRoot} }

var _ provider.Provider = (*Provider)(nil)

func (p *Provider) Name() string { return "openspec" }

// changesDir is the directory holding per-change folders.
func (p *Provider) changesDir() string {
	return filepath.Join(p.Root, "openspec", "changes")
}

// List returns the sorted names of every change directory that contains a
// proposal.md (the minimal marker of an OpenSpec change).
func (p *Provider) List() ([]string, error) {
	dir := p.changesDir()
	entries, err := os.ReadDir(dir)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, fmt.Errorf("reading %s: %w", dir, err)
	}
	var names []string
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		if _, err := os.Stat(filepath.Join(dir, e.Name(), "proposal.md")); err == nil {
			names = append(names, e.Name())
		}
	}
	sort.Strings(names)
	return names, nil
}

// Load reads one change by name.
func (p *Provider) Load(name string) (*ir.Change, error) {
	root := filepath.Join(p.changesDir(), name)
	if _, err := os.Stat(root); err != nil {
		return nil, fmt.Errorf("change %q not found under %s", name, p.changesDir())
	}
	c := &ir.Change{Name: name, Root: root}

	if src, ok := readFile(filepath.Join(root, "proposal.md")); ok {
		prop, warns := parse.ParseProposal("proposal.md", src)
		c.Proposal = prop
		c.Warnings = append(c.Warnings, warns...)
	}

	if src, ok := readFile(filepath.Join(root, "design.md")); ok {
		des, warns := parse.ParseDesign("design.md", src)
		c.Design = des
		c.Warnings = append(c.Warnings, warns...)
	}

	if src, ok := readFile(filepath.Join(root, "tasks.md")); ok {
		tasks, warns := parse.ParseTasks("tasks.md", src)
		c.Tasks = tasks
		c.Warnings = append(c.Warnings, warns...)
	}

	specs, warns, err := p.loadSpecs(root)
	if err != nil {
		return nil, err
	}
	c.Specs = specs
	c.Warnings = append(c.Warnings, warns...)

	return c, nil
}

// loadSpecs discovers specs/<capability>/spec.md files in sorted order.
func (p *Provider) loadSpecs(changeRoot string) ([]*ir.Spec, []ir.Warning, error) {
	specsDir := filepath.Join(changeRoot, "specs")
	entries, err := os.ReadDir(specsDir)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil, nil
		}
		return nil, nil, fmt.Errorf("reading %s: %w", specsDir, err)
	}
	var caps []string
	for _, e := range entries {
		if e.IsDir() {
			caps = append(caps, e.Name())
		}
	}
	sort.Strings(caps)

	var specs []*ir.Spec
	var warns []ir.Warning
	for _, cap := range caps {
		path := filepath.Join(specsDir, cap, "spec.md")
		src, ok := readFile(path)
		if !ok {
			warns = append(warns, ir.Warning{
				File: filepath.Join("specs", cap), Msg: "capability directory has no spec.md",
			})
			continue
		}
		rel := strings.Join([]string{"specs", cap, "spec.md"}, "/")
		spec, w := parse.ParseSpec(rel, cap, src)
		specs = append(specs, spec)
		warns = append(warns, w...)
	}
	return specs, warns, nil
}

// LoadAll loads every discoverable change.
func (p *Provider) LoadAll() ([]*ir.Change, error) {
	names, err := p.List()
	if err != nil {
		return nil, err
	}
	changes := make([]*ir.Change, 0, len(names))
	for _, name := range names {
		c, err := p.Load(name)
		if err != nil {
			return nil, err
		}
		changes = append(changes, c)
	}
	return changes, nil
}

// readFile returns the file contents and true, or ("", false) if absent.
func readFile(path string) (string, bool) {
	b, err := os.ReadFile(path)
	if err != nil {
		return "", false
	}
	return string(b), true
}
