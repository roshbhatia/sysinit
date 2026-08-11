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
	// A bare directory is the common mistake: running specutil from the wrong
	// place. Naming the missing directory beats a nil provider panicking later.
	_, err := registry.SelectProvider(t.TempDir())
	if err == nil {
		t.Error("expected an error when openspec/changes is absent")
	}
}

func TestExtractionDecoratesTheProvider(t *testing.T) {
	// A repo declaring a schema gets the extracting decorator, which is what
	// applies the marker grammar. Without it the phase shapes never parse.
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
