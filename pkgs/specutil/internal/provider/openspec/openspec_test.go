package openspec

import (
	"os"
	"path/filepath"
	"testing"
)

// repoRoot walks up from the test directory to the module root (where go.mod is).
func repoRoot(t *testing.T) string {
	t.Helper()
	dir, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	for {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			t.Fatalf("no go.mod found above %s", dir)
		}
		dir = parent
	}
}

// examplesRepo returns the getting-started fixture root. The test binds to a
// committed fixture rather than to this repository's own live changes, which
// move in and out of openspec/changes/ as work is archived. The fixture is
// shared with the cli tests, so it lives under their testdata/ rather than
// being duplicated here.
func examplesRepo(t *testing.T) string {
	t.Helper()
	return filepath.Join(repoRoot(t), "internal", "cli", "testdata", "getting-started")
}

func TestLoadRealChange(t *testing.T) {
	p := New(examplesRepo(t))

	names, err := p.List()
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if !contains(names, "add-auth-layer") {
		t.Fatalf("add-auth-layer not discovered; got %v", names)
	}

	c, err := p.Load("add-auth-layer")
	if err != nil {
		t.Fatalf("Load: %v", err)
	}

	if c.Proposal == nil {
		t.Fatal("proposal not loaded")
	}
	if len(c.Proposal.Capabilities.New) != 1 {
		t.Errorf("expected 1 new capability, got %d", len(c.Proposal.Capabilities.New))
	}
	if len(c.Proposal.Capabilities.Modified) != 1 {
		t.Errorf("expected 1 modified capability, got %d", len(c.Proposal.Capabilities.Modified))
	}
	if c.Tasks == nil || len(c.Tasks.Phases) == 0 {
		t.Error("tasks not loaded")
	}
	if len(c.Specs) != 1 {
		t.Errorf("expected 1 spec, got %d", len(c.Specs))
	}

	// Every spec should have at least one requirement with at least one scenario.
	for _, s := range c.Specs {
		if len(s.Requirements) == 0 {
			t.Errorf("spec %q has no requirements", s.Capability)
		}
		for _, r := range s.Requirements {
			if len(r.Scenarios) == 0 {
				t.Errorf("spec %q requirement %q has no scenarios", s.Capability, r.Name)
			}
		}
	}

	// A well-formed change parses without warnings. The fixture has no design.md,
	// which is optional, so it must not produce one either.
	if len(c.Warnings) != 0 {
		t.Errorf("expected no warnings on the fixture change, got %d:", len(c.Warnings))
		for _, w := range c.Warnings {
			t.Logf("  %s:%d %s", w.File, w.Line, w.Msg)
		}
	}

	// Internal structure graph: change -> capability edges exist.
	edges := c.Edges()
	if len(edges) == 0 {
		t.Error("expected internal edges")
	}
}

// The provider must discover every change in a multi-change repo, so a repo
// whose changes are all archived reports none rather than erroring.
func TestListDiscoversAllChanges(t *testing.T) {
	names, err := New(examplesRepo(t)).List()
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if len(names) != 2 || !contains(names, "add-auth-layer") || !contains(names, "user-profile-api") {
		t.Errorf("expected both fixture changes, got %v", names)
	}
}

func TestListEmptyRepo(t *testing.T) {
	p := New(t.TempDir())
	names, err := p.List()
	if err != nil {
		t.Fatalf("List on empty repo: %v", err)
	}
	if len(names) != 0 {
		t.Errorf("expected no changes, got %v", names)
	}
}

func contains(s []string, v string) bool {
	for _, x := range s {
		if x == v {
			return true
		}
	}
	return false
}
