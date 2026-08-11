package registry_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/roshbhatia/specutil/internal/graph"
	"github.com/roshbhatia/specutil/internal/registry"
)

func TestDetectOpenSpec(t *testing.T) {
	dir := t.TempDir()
	os.MkdirAll(filepath.Join(dir, "openspec", "changes"), 0o755)

	p, err := registry.SelectProvider("", dir, "", nil)
	if err != nil {
		t.Fatalf("SelectProvider: %v", err)
	}
	if p.Name() != "openspec" {
		t.Errorf("Name() = %q, want openspec", p.Name())
	}
}

func TestDetectBMAD(t *testing.T) {
	dir := t.TempDir()
	storiesDir := filepath.Join(dir, "stories")
	os.MkdirAll(storiesDir, 0o755)
	os.WriteFile(filepath.Join(storiesDir, "story-1.md"), []byte("# Story 1: Test\n\n## Story\ntest"), 0o644)

	p, err := registry.SelectProvider("", dir, "", nil)
	if err != nil {
		t.Fatalf("SelectProvider: %v", err)
	}
	if p.Name() != "bmad" {
		t.Errorf("Name() = %q, want bmad", p.Name())
	}
}

func TestDetectPlan(t *testing.T) {
	dir := t.TempDir()
	os.WriteFile(filepath.Join(dir, "plan.md"), []byte("# my-change\n\n## Why\ntest"), 0o644)

	p, err := registry.SelectProvider("", dir, "", nil)
	if err != nil {
		t.Fatalf("SelectProvider: %v", err)
	}
	if p.Name() != "plan" {
		t.Errorf("Name() = %q, want plan", p.Name())
	}
}

func TestExplicitFromFlag(t *testing.T) {
	dir := t.TempDir()
	os.MkdirAll(filepath.Join(dir, "openspec", "changes"), 0o755)

	p, err := registry.SelectProvider("openspec", dir, "", nil)
	if err != nil {
		t.Fatalf("SelectProvider: %v", err)
	}
	if p.Name() != "openspec" {
		t.Errorf("Name() = %q, want openspec", p.Name())
	}
}

func TestUnknownProviderError(t *testing.T) {
	dir := t.TempDir()
	_, err := registry.SelectProvider("jira", dir, "", nil)
	if err == nil {
		t.Error("expected error for unknown provider")
	}
}

func TestScriptAdapterSelected(t *testing.T) {
	dir := t.TempDir()
	providers := []graph.ProviderConfig{
		{Name: "jira", Command: "echo jira"},
	}
	p, err := registry.SelectProvider("jira", dir, "", providers)
	if err != nil {
		t.Fatalf("SelectProvider: %v", err)
	}
	if p.Name() != "script" {
		t.Errorf("Name() = %q, want script", p.Name())
	}
}

func TestNoDetectionError(t *testing.T) {
	dir := t.TempDir()
	_, err := registry.SelectProvider("", dir, "", nil)
	if err == nil {
		t.Error("expected error when no provider detected")
	}
}
