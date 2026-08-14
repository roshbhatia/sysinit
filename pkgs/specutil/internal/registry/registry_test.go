package registry_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/roshbhatia/specutil/internal/registry"
)

func TestOpenSpecRepoResolves(t *testing.T) {
	dir := t.TempDir()
	os.MkdirAll(filepath.Join(dir, "openspec", "changes"), 0o755)

	p, err := registry.SelectProvider(dir)
	if err != nil {
		t.Fatalf("SelectProvider: %v", err)
	}
	if p.Name() != "openspec" {
		t.Errorf("Name() = %q, want openspec", p.Name())
	}
}

func TestRepoWithoutOpenSpecIsAnError(t *testing.T) {
	_, err := registry.SelectProvider(t.TempDir())
	if err == nil {
		t.Error("expected an error when openspec/changes is absent")
	}
}

func TestExtractionDecoratesTheProvider(t *testing.T) {
	dir := t.TempDir()
	os.MkdirAll(filepath.Join(dir, "openspec", "changes"), 0o755)
	if err := os.WriteFile(filepath.Join(dir, "openspec", "config.yaml"),
		[]byte("schema: spec-driven\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	p, err := registry.SelectProvider(dir)
	if err != nil {
		t.Fatalf("SelectProvider: %v", err)
	}
	if p.Name() != "openspec" {
		t.Errorf("Name() = %q, want the decorator to keep the underlying name", p.Name())
	}
}
