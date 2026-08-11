// Package plan implements the Provider port against a lightweight plan.md
// convention. It also handles --from stdin (path "-") by reading os.Stdin.
// The convention: first # heading is the change name, ## Why/What Changes/Tasks
// map to the IR directly. Unknown headings are silently ignored.
package plan

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/roshbhatia/specutil/internal/ir"
	"github.com/roshbhatia/specutil/internal/parse"
	"github.com/roshbhatia/specutil/internal/provider"
)

var _ provider.Provider = (*Provider)(nil)

// Provider loads a plan.md file (or stdin) into the normalized IR.
type Provider struct {
	Root string
	// path is the file to load; "-" means stdin; empty means auto-discover plan.md.
	path string
	// stdinOnce guards the single read of os.Stdin so List/Load/LoadAll all see
	// the same bytes even though the interface requires separate calls.
	stdinOnce  sync.Once
	stdinBytes []byte
	stdinErr   error
}

// New returns a plan provider rooted at repoRoot. When path is non-empty it
// pins the provider to that file; "-" reads stdin.
func New(repoRoot, path string) *Provider {
	return &Provider{Root: repoRoot, path: path}
}

func (p *Provider) Name() string { return "plan" }

func (p *Provider) resolvedPath() string {
	if p.path != "" {
		return p.path
	}
	return filepath.Join(p.Root, "plan.md")
}

func (p *Provider) List() ([]string, error) {
	c, err := p.loadOne()
	if err != nil {
		return nil, err
	}
	return []string{c.Name}, nil
}

func (p *Provider) Load(name string) (*ir.Change, error) {
	c, err := p.loadOne()
	if err != nil {
		return nil, err
	}
	// Override the name if the caller specifies one (e.g. from --change).
	if name != "" {
		c.Name = name
	}
	return c, nil
}

func (p *Provider) LoadAll() ([]*ir.Change, error) {
	c, err := p.loadOne()
	if err != nil {
		return nil, err
	}
	return []*ir.Change{c}, nil
}

func (p *Provider) loadOne() (*ir.Change, error) {
	var src string
	var label string

	if p.path == "-" {
		p.stdinOnce.Do(func() {
			p.stdinBytes, p.stdinErr = io.ReadAll(os.Stdin)
		})
		if p.stdinErr != nil {
			return nil, fmt.Errorf("plan: reading stdin: %w", p.stdinErr)
		}
		src = string(p.stdinBytes)
		label = "stdin"
	} else {
		path := p.resolvedPath()
		b, err := os.ReadFile(path)
		if err != nil {
			if os.IsNotExist(err) {
				return nil, fmt.Errorf("plan: %s not found; pass a path or create plan.md at the repo root", path)
			}
			return nil, fmt.Errorf("plan: reading %s: %w", path, err)
		}
		src = string(b)
		label = filepath.Base(path)
	}

	return parsePlan(label, src)
}

// parsePlan maps the plan.md convention into ir.Change. It is tolerant: absent
// sections emit a warning rather than failing.
func parsePlan(file, src string) (*ir.Change, error) {
	preamble, roots := parse.SplitSections(src)
	_ = preamble

	c := &ir.Change{}
	var warns []ir.Warning

	// Collect the ## sections to scan. When the document starts with a # heading,
	// SplitSections makes all ## headings children of that root rather than roots
	// themselves. Handle both layouts.
	var level2 []*parse.Node
	for _, n := range roots {
		if n.Level == 1 {
			if c.Name == "" {
				c.Name = strings.TrimSpace(n.Title)
			}
			for _, child := range n.Children {
				if child.Level == 2 {
					level2 = append(level2, child)
				}
			}
		} else if n.Level == 2 {
			level2 = append(level2, n)
		}
	}

	// Map known ## sections.
	var foundWhy, foundWhat, foundTasks bool
	for _, n := range level2 {
		title := strings.ToLower(strings.TrimSpace(n.Title))
		body := strings.TrimSpace(n.Body)

		switch {
		case title == "why":
			foundWhy = true
			if c.Proposal == nil {
				c.Proposal = &ir.Proposal{Section: ir.Section{Raw: n.Raw}}
			}
			c.Proposal.Why = body

		case title == "what changes":
			foundWhat = true
			if c.Proposal == nil {
				c.Proposal = &ir.Proposal{}
			}
			c.Proposal.WhatChanges = body

		case title == "tasks":
			foundTasks = true
			// Reconstruct as a minimal tasks.md-compatible block and reuse the existing parser.
			tasks, tw := parse.ParseTasks(file, buildTasksSrc(n))
			c.Tasks = tasks
			warns = append(warns, tw...)
		}
		// Unknown headings are silently skipped per the spec.
	}

	if !foundWhy {
		warns = append(warns, ir.Warning{File: file, Msg: "[plan]: section \"Why\" absent"})
	}
	if !foundWhat {
		warns = append(warns, ir.Warning{File: file, Msg: "[plan]: section \"What Changes\" absent"})
	}
	if !foundTasks {
		warns = append(warns, ir.Warning{File: file, Msg: "[plan]: section \"Tasks\" absent"})
	}

	if c.Name == "" {
		c.Name = strings.TrimSuffix(file, ".md")
	}
	c.Warnings = warns
	return c, nil
}

// buildTasksSrc reconstructs the tasks section as a tasks.md-compatible string
// for parse.ParseTasks. ParseTasks expects phase headings at level 2 (##).
// In plan.md the phases are at level 3 (###) under ## Tasks, so we demote them.
func buildTasksSrc(n *parse.Node) string {
	var sb strings.Builder
	if len(n.Children) > 0 {
		// Emit each ### Phase child as ## so ParseTasks sees them as phase roots.
		for _, child := range n.Children {
			raw := child.Raw
			if strings.HasPrefix(raw, "### ") {
				raw = "## " + raw[4:]
			}
			sb.WriteString(raw)
			sb.WriteString("\n")
		}
	} else if n.Body != "" {
		// No sub-phases: wrap items in a default phase.
		sb.WriteString("## Tasks\n")
		sb.WriteString(n.Body)
	}
	return sb.String()
}
