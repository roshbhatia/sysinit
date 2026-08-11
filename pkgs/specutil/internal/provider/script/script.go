// Package script implements the Provider port for user-defined script adapters
// declared in specutil.yaml. The script is executed with {change} substituted;
// its stdout is parsed as openspec-compatible markdown.
package script

import (
	"bytes"
	"fmt"
	"os/exec"
	"strings"

	"github.com/roshbhatia/specutil/internal/ir"
	"github.com/roshbhatia/specutil/internal/parse"
	"github.com/roshbhatia/specutil/internal/provider"
)

var _ provider.Provider = (*Provider)(nil)

// Provider executes a shell command and parses its stdout as openspec markdown.
type Provider struct {
	Root    string
	Command string // may contain {change} placeholder
}

// New returns a script provider for the given command template.
func New(repoRoot, command string) *Provider {
	return &Provider{Root: repoRoot, Command: command}
}

func (p *Provider) Name() string { return "script" }

// List is not supported for script adapters — they require an explicit name.
func (p *Provider) List() ([]string, error) {
	return nil, fmt.Errorf("script adapter %q does not support listing changes; use --change", p.Command)
}

// Load executes the script with {change} replaced by name, then parses stdout.
func (p *Provider) Load(name string) (*ir.Change, error) {
	cmd := strings.ReplaceAll(p.Command, "{change}", name)
	out, err := execShell(p.Root, cmd)
	if err != nil {
		return nil, fmt.Errorf("script adapter: %s: %w", cmd, err)
	}
	return parseOpenSpecMarkdown(name, string(out))
}

// LoadAll is not supported for script adapters.
func (p *Provider) LoadAll() ([]*ir.Change, error) {
	return nil, fmt.Errorf("script adapter %q does not support loading all changes; use --change", p.Command)
}

func execShell(dir, cmd string) ([]byte, error) {
	c := exec.Command("sh", "-c", cmd)
	c.Dir = dir
	var stdout, stderr bytes.Buffer
	c.Stdout = &stdout
	c.Stderr = &stderr
	if err := c.Run(); err != nil {
		if stderr.Len() > 0 {
			return nil, fmt.Errorf("%w\n%s", err, strings.TrimSpace(stderr.String()))
		}
		return nil, err
	}
	return stdout.Bytes(), nil
}

// parseOpenSpecMarkdown is a minimal openspec-compatible parser for script
// output: it maps ## Why, ## What Changes, ## Tasks to the IR.
func parseOpenSpecMarkdown(name, src string) (*ir.Change, error) {
	_, roots := parse.SplitSections(src)
	c := &ir.Change{Name: name}

	for _, n := range roots {
		title := strings.TrimSpace(n.Title)
		body := strings.TrimSpace(n.Body)

		switch strings.ToLower(title) {
		case "why":
			if c.Proposal == nil {
				c.Proposal = &ir.Proposal{}
			}
			c.Proposal.Why = body
		case "what changes":
			if c.Proposal == nil {
				c.Proposal = &ir.Proposal{}
			}
			c.Proposal.WhatChanges = body
		case "tasks":
			tasks, warns := parse.ParseTasks("script", "## Tasks\n"+n.Body)
			c.Tasks = tasks
			c.Warnings = append(c.Warnings, warns...)
		case "design", "context":
			if c.Design == nil {
				c.Design = &ir.Design{}
			}
			c.Design.Context = body
		}
	}

	// Emit warnings for absent key sections — a script that exits 0 with no
	// recognizable output would otherwise silently produce an empty change.
	if c.Proposal == nil {
		c.Warnings = append(c.Warnings, ir.Warning{File: name, Msg: "[script]: no \"## Why\" or \"## What Changes\" section in script output"})
	}
	if c.Tasks == nil {
		c.Warnings = append(c.Warnings, ir.Warning{File: name, Msg: "[script]: no \"## Tasks\" section in script output"})
	}

	return c, nil
}
