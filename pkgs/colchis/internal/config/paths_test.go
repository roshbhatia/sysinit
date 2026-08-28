package config

import (
	"path/filepath"
	"testing"
)

func TestResolvePathsUsesOverride(t *testing.T) {
	t.Setenv(StateDirectoryEnvironment, filepath.Join(t.TempDir(), "environment"))
	override := filepath.Join(t.TempDir(), "override")

	paths, err := ResolvePaths(override)
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	if paths.StateDirectory != override {
		t.Fatalf("state directory = %q", paths.StateDirectory)
	}
	if paths.Database != filepath.Join(override, "broker.db") {
		t.Fatalf("database = %q", paths.Database)
	}
	if paths.Socket != filepath.Join(override, "broker.sock") {
		t.Fatalf("socket = %q", paths.Socket)
	}
}

func TestResolvePathsUsesEnvironmentThenXDGState(t *testing.T) {
	configured := filepath.Join(t.TempDir(), "configured")
	xdgState := filepath.Join(t.TempDir(), "xdg")
	t.Setenv(StateDirectoryEnvironment, configured)
	t.Setenv("XDG_STATE_HOME", xdgState)

	paths, err := ResolvePaths("")
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	if paths.StateDirectory != configured {
		t.Fatalf("state directory = %q", paths.StateDirectory)
	}

	t.Setenv(StateDirectoryEnvironment, "")
	paths, err = ResolvePaths("")
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	if paths.StateDirectory != filepath.Join(xdgState, "colchis") {
		t.Fatalf("state directory = %q", paths.StateDirectory)
	}
}
