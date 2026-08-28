package main

import (
	"os"
	"path/filepath"
	"slices"
	"testing"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/ask"
	piadapter "github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/pi"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

func TestPrepareRuntimeDirectoryCreatesConfiguredPath(t *testing.T) {
	directory := filepath.Join(t.TempDir(), "runtime")
	t.Setenv("COLCHIS_RUNTIME_DIRECTORY", directory)

	resolved, err := prepareRuntimeDirectory()
	if err != nil {
		t.Fatalf("prepareRuntimeDirectory() returned %v", err)
	}
	if resolved != directory {
		t.Fatalf("runtime directory = %q, want %q", resolved, directory)
	}
	info, err := os.Stat(resolved)
	if err != nil {
		t.Fatalf("Stat() returned %v", err)
	}
	if !info.IsDir() || info.Mode().Perm()&0o077 != 0 {
		t.Fatalf("runtime directory mode = %v", info.Mode())
	}
}

func TestRuntimeAdaptersDeclareDifferentControlCapabilities(t *testing.T) {
	t.Parallel()

	askManifest, err := ask.Manifest()
	if err != nil {
		t.Fatalf("ask Manifest() returned %v", err)
	}
	piManifests, err := piadapter.Manifests()
	if err != nil {
		t.Fatalf("Pi Manifests() returned %v", err)
	}
	var piCapabilities []string
	for _, manifest := range piManifests {
		if manifest.Port == domain.AdapterPortAgentRuntime {
			piCapabilities = manifest.Capabilities
		}
	}
	if !slices.Contains(askManifest.Capabilities, "queued-input") ||
		slices.Contains(askManifest.Capabilities, "live-input") {
		t.Fatalf("ask capabilities = %#v", askManifest.Capabilities)
	}
	for _, capability := range []string{
		"structured-result", "live-input", "interrupt", "resume",
	} {
		if !slices.Contains(piCapabilities, capability) {
			t.Fatalf("Pi capabilities lack %q: %#v", capability, piCapabilities)
		}
	}
}

func TestMultiplexerLoadsOnlyAvailableAdapters(t *testing.T) {
	directory := t.TempDir()
	nixExecutable := filepath.Join(directory, "nix")
	if err := os.WriteFile(nixExecutable, []byte("#!/bin/sh\nexit 0\n"), 0o700); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	t.Setenv("PATH", directory)
	multiplexer, piRuntime, err := newMultiplexer(directory, filepath.Join(directory, "runtime"))
	if err != nil {
		t.Fatalf("newMultiplexer() returned %v", err)
	}
	if piRuntime != nil {
		t.Fatal("newMultiplexer() started an unavailable Pi runtime")
	}
	manifests := multiplexer.Manifests()
	if len(manifests) != 1 || manifests[0].Port != domain.AdapterPortEnvironment {
		t.Fatalf("available manifests = %#v", manifests)
	}
}
