// Package bmad implements the Provider port against BMAD story files
// (stories/*.md). It maps BMAD section conventions to the normalized IR so
// specutil verbs work unchanged against BMAD projects.
package bmad

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"github.com/roshbhatia/specutil/internal/ir"
	"github.com/roshbhatia/specutil/internal/parse"
	"github.com/roshbhatia/specutil/internal/provider"
)

var _ provider.Provider = (*Provider)(nil)

// storyHeadingRe matches "# Story N.M: Title" or "# Story N: Title".
var storyHeadingRe = regexp.MustCompile(`(?i)^story\s+(\d+(?:\.\d+)*):\s*(.+)$`)

// statusFieldRe matches "**Status:** value" anywhere in the document.
var statusFieldRe = regexp.MustCompile(`(?i)\*\*status:\*\*\s*(.+)`)

// Provider loads BMAD story files from stories/*.md under Root.
type Provider struct {
	Root string
	// path is the specific file to load; empty means discover by glob.
	path string
}

// New returns a BMAD provider rooted at repoRoot. When path is non-empty it
// pins the provider to that specific file.
func New(repoRoot, path string) *Provider {
	return &Provider{Root: repoRoot, path: path}
}

func (p *Provider) Name() string { return "bmad" }

func (p *Provider) storiesDir() string { return filepath.Join(p.Root, "stories") }

// List returns the change names derived from each discovered story file.
func (p *Provider) List() ([]string, error) {
	if p.path != "" {
		name, err := p.nameFromFile(p.path)
		if err != nil {
			return nil, err
		}
		return []string{name}, nil
	}
	files, err := p.discoverFiles()
	if err != nil {
		return nil, err
	}
	var names []string
	for _, f := range files {
		name, err := p.nameFromFile(f)
		if err != nil {
			continue
		}
		names = append(names, name)
	}
	sort.Strings(names)
	return names, nil
}

// Load reads a story by name or file path. When name looks like a path
// (contains "/" or ends in ".md") it is treated as a direct path.
// When name is empty, auto-selects the single story (or errors if multiple).
func (p *Provider) Load(name string) (*ir.Change, error) {
	if p.path != "" {
		return p.loadFile(p.path)
	}
	// Name may be a file path or a story name.
	if strings.Contains(name, "/") || strings.HasSuffix(name, ".md") {
		return p.loadFile(name)
	}
	// Discover files.
	files, err := p.discoverFiles()
	if err != nil {
		return nil, err
	}
	if name == "" {
		switch len(files) {
		case 0:
			return nil, fmt.Errorf("bmad: no story files found under %s", p.storiesDir())
		case 1:
			return p.loadFile(files[0])
		default:
			names, _ := p.List()
			return nil, fmt.Errorf("bmad: multiple stories found; specify --change: %v", names)
		}
	}
	for _, f := range files {
		n, err := p.nameFromFile(f)
		if err != nil {
			continue
		}
		if n == name {
			return p.loadFile(f)
		}
	}
	return nil, fmt.Errorf("bmad: story %q not found under %s", name, p.storiesDir())
}

// LoadAll loads every discoverable story.
func (p *Provider) LoadAll() ([]*ir.Change, error) {
	if p.path != "" {
		c, err := p.loadFile(p.path)
		if err != nil {
			return nil, err
		}
		return []*ir.Change{c}, nil
	}
	files, err := p.discoverFiles()
	if err != nil {
		return nil, err
	}
	var changes []*ir.Change
	for _, f := range files {
		c, err := p.loadFile(f)
		if err != nil {
			return nil, err
		}
		changes = append(changes, c)
	}
	return changes, nil
}

func (p *Provider) discoverFiles() ([]string, error) {
	dir := p.storiesDir()
	entries, err := os.ReadDir(dir)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, fmt.Errorf("bmad: reading %s: %w", dir, err)
	}
	var files []string
	for _, e := range entries {
		if !e.IsDir() && strings.HasSuffix(e.Name(), ".md") {
			files = append(files, filepath.Join(dir, e.Name()))
		}
	}
	sort.Strings(files)
	return files, nil
}

// nameFromFile derives the change name from the first heading in the file.
func (p *Provider) nameFromFile(path string) (string, error) {
	src, err := os.ReadFile(path)
	if err != nil {
		return "", fmt.Errorf("bmad: reading %s: %w", path, err)
	}
	preamble, roots := parse.SplitSections(string(src))
	_ = preamble
	if len(roots) > 0 {
		title := strings.TrimSpace(roots[0].Title)
		if m := storyHeadingRe.FindStringSubmatch(title); m != nil {
			return "story-" + m[1], nil
		}
		return slugify(title), nil
	}
	return strings.TrimSuffix(filepath.Base(path), ".md"), nil
}

func (p *Provider) loadFile(path string) (*ir.Change, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("bmad: reading %s: %w", path, err)
	}
	src := string(b)
	file := filepath.Base(path)

	_, roots := parse.SplitSections(src)

	c := &ir.Change{Root: p.Root}
	annotations := map[string]string{}

	// Extract change name and bmad.id from the first # heading.
	if len(roots) > 0 {
		title := strings.TrimSpace(roots[0].Title)
		if m := storyHeadingRe.FindStringSubmatch(title); m != nil {
			annotations["bmad.id"] = m[1]
			c.Name = "story-" + m[1]
		} else {
			c.Name = slugify(title)
		}
	}
	if c.Name == "" {
		c.Name = strings.TrimSuffix(file, ".md")
	}

	// Extract **Status:** field from the raw document.
	if m := statusFieldRe.FindStringSubmatch(src); m != nil {
		annotations["bmad.status"] = strings.TrimSpace(m[1])
	}

	// Collect the nodes to scan: when the file starts with a # heading, level-2
	// sections are its children rather than roots. Handle both layouts.
	var sections []*parse.Node
	for _, n := range roots {
		if n.Level == 1 {
			sections = append(sections, n.Children...)
		} else {
			sections = append(sections, n)
		}
	}

	// Map sections.
	for _, n := range sections {
		title := strings.ToLower(strings.TrimSpace(n.Title))
		body := strings.TrimSpace(n.Body)

		switch {
		case title == "story":
			c.Proposal = &ir.Proposal{
				Section: ir.Section{Raw: n.Raw},
				Why:     body,
			}

		case title == "acceptance criteria":
			c.Specs = append(c.Specs, acToSpec(file, n))

		case title == "tasks":
			// n.Raw already starts with "## Tasks", so pass n.Body to avoid
			// a doubled heading that causes ParseTasks to see 0 phases.
			tasks, warns := parse.ParseTasks(file, "## Tasks\n"+n.Body)
			c.Tasks = tasks
			c.Warnings = append(c.Warnings, warns...)

		case title == "dev notes" || title == "dev note":
			if c.Design == nil {
				c.Design = &ir.Design{}
			}
			c.Design.Context = body
		}
	}

	// Emit warnings for absent key sections.
	if c.Proposal == nil {
		c.Warnings = append(c.Warnings, ir.Warning{File: file, Msg: "[bmad]: section \"Story\" absent"})
	}
	if len(c.Specs) == 0 {
		c.Warnings = append(c.Warnings, ir.Warning{File: file, Msg: "[bmad]: section \"Acceptance Criteria\" absent"})
	}
	if c.Tasks == nil {
		c.Warnings = append(c.Warnings, ir.Warning{File: file, Msg: "[bmad]: section \"Tasks\" absent"})
	}

	if len(annotations) > 0 {
		c.Annotations = annotations
	}
	return c, nil
}

// acToSpec converts a BMAD "## Acceptance Criteria" node into an ir.Spec where
// each top-level checkbox item becomes a Requirement.
func acToSpec(file string, n *parse.Node) *ir.Spec {
	spec := &ir.Spec{
		Section:    ir.Section{Raw: n.Raw},
		Capability: "acceptance-criteria",
	}
	items := extractCheckboxItems(n.Body)
	for i, item := range items {
		req := ir.Requirement{
			Section: ir.Section{Raw: item},
			Name:    strings.TrimSpace(item),
			Delta:   ir.DeltaAdded,
			Text:    strings.TrimSpace(item),
		}
		_ = i
		spec.Requirements = append(spec.Requirements, req)
	}
	return spec
}

// extractCheckboxItems returns the text of each top-level checkbox bullet.
func extractCheckboxItems(body string) []string {
	var out []string
	for _, line := range strings.Split(body, "\n") {
		t := strings.TrimSpace(line)
		if strings.HasPrefix(t, "- [ ]") || strings.HasPrefix(t, "- [x]") || strings.HasPrefix(t, "- [X]") {
			// Strip the checkbox marker.
			after := strings.TrimPrefix(t, "- [ ]")
			after = strings.TrimPrefix(after, "- [x]")
			after = strings.TrimPrefix(after, "- [X]")
			after = strings.TrimSpace(after)
			if after != "" {
				out = append(out, after)
			}
		}
	}
	return out
}

// slugify converts a heading title to a lowercase kebab-case name.
func slugify(s string) string {
	s = strings.ToLower(s)
	s = regexp.MustCompile(`[^a-z0-9]+`).ReplaceAllString(s, "-")
	return strings.Trim(s, "-")
}
