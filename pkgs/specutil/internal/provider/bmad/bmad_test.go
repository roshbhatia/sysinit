package bmad_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/roshbhatia/specutil/internal/provider/bmad"
)

const storyFull = `# Story 1.1: Add Authentication

**Status:** In Progress

## Story

As a user, I want to log in so that I can access my account.

## Acceptance Criteria

- [ ] User can log in with email and password
- [x] Invalid credentials show an error message
- [ ] Session expires after 24 hours

## Tasks

### Phase 1: Foundation

- [ ] 1.1 Create login endpoint
- [ ] 1.2 Add session management

## Dev Notes

Use bcrypt for password hashing. JWT tokens for sessions.
`

const storyPartial = `# Story 2.1: Minimal Story

## Story

Minimal description only.
`

func writeStory(t *testing.T, dir, name, content string) string {
	t.Helper()
	path := filepath.Join(dir, name)
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatalf("writing story: %v", err)
	}
	return path
}

func TestBMADSectionMapping(t *testing.T) {
	dir := t.TempDir()
	storiesDir := filepath.Join(dir, "stories")
	if err := os.MkdirAll(storiesDir, 0o755); err != nil {
		t.Fatal(err)
	}
	writeStory(t, storiesDir, "story-1.1.md", storyFull)

	p := bmad.New(dir, "")
	c, err := p.Load("")
	if err != nil {
		t.Fatalf("Load: %v", err)
	}

	if c.Name != "story-1.1" {
		t.Errorf("Name = %q, want %q", c.Name, "story-1.1")
	}
	if c.Annotations["bmad.id"] != "1.1" {
		t.Errorf("Annotations[bmad.id] = %q, want %q", c.Annotations["bmad.id"], "1.1")
	}
	if c.Annotations["bmad.status"] != "In Progress" {
		t.Errorf("Annotations[bmad.status] = %q, want %q", c.Annotations["bmad.status"], "In Progress")
	}
	if c.Proposal == nil || c.Proposal.Why == "" {
		t.Error("Proposal.Why should be populated from ## Story")
	}
	if len(c.Specs) == 0 {
		t.Error("Specs should be populated from ## Acceptance Criteria")
	} else if len(c.Specs[0].Requirements) != 3 {
		t.Errorf("len(Specs[0].Requirements) = %d, want 3", len(c.Specs[0].Requirements))
	}
	if c.Tasks == nil {
		t.Error("Tasks should be populated from ## Tasks")
	}
	if c.Design == nil || c.Design.Context == "" {
		t.Error("Design.Context should be populated from ## Dev Notes")
	}
}

func TestBMADStatusAnnotation(t *testing.T) {
	dir := t.TempDir()
	storiesDir := filepath.Join(dir, "stories")
	os.MkdirAll(storiesDir, 0o755)
	writeStory(t, storiesDir, "story-1.1.md", storyFull)

	p := bmad.New(dir, "")
	c, err := p.Load("")
	if err != nil {
		t.Fatal(err)
	}
	if c.Annotations["bmad.status"] != "In Progress" {
		t.Errorf("got %q, want %q", c.Annotations["bmad.status"], "In Progress")
	}
}

func TestBMADTolerantParsing(t *testing.T) {
	dir := t.TempDir()
	storiesDir := filepath.Join(dir, "stories")
	os.MkdirAll(storiesDir, 0o755)
	writeStory(t, storiesDir, "story-2.1.md", storyPartial)

	p := bmad.New(dir, "")
	c, err := p.Load("")
	if err != nil {
		t.Fatalf("Load should not fail on partial story: %v", err)
	}
	if c.Proposal == nil {
		t.Error("Proposal should be set from ## Story")
	}
	// Missing sections should produce warnings, not failures.
	warnMsgs := make([]string, len(c.Warnings))
	for i, w := range c.Warnings {
		warnMsgs[i] = w.Msg
	}
	foundAC := false
	for _, msg := range warnMsgs {
		if msg == `[bmad]: section "Acceptance Criteria" absent` {
			foundAC = true
		}
	}
	if !foundAC {
		t.Errorf("expected warning about missing Acceptance Criteria; got %v", warnMsgs)
	}
}

func TestBMADMultipleStoriesRequireChange(t *testing.T) {
	dir := t.TempDir()
	storiesDir := filepath.Join(dir, "stories")
	os.MkdirAll(storiesDir, 0o755)
	writeStory(t, storiesDir, "story-1.1.md", storyFull)
	writeStory(t, storiesDir, "story-2.1.md", storyPartial)

	p := bmad.New(dir, "")
	names, err := p.List()
	if err != nil {
		t.Fatal(err)
	}
	if len(names) != 2 {
		t.Errorf("len(List()) = %d, want 2", len(names))
	}
}

func TestBMADDirectPath(t *testing.T) {
	dir := t.TempDir()
	path := writeStory(t, dir, "my-story.md", storyFull)

	p := bmad.New(dir, path)
	c, err := p.Load("")
	if err != nil {
		t.Fatalf("Load with explicit path: %v", err)
	}
	if c.Name != "story-1.1" {
		t.Errorf("Name = %q, want %q", c.Name, "story-1.1")
	}
}
