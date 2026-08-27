package repo

import (
	"path/filepath"
	"strings"
	"testing"
)

func TestKeyedPathsAreStableAndDistinct(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	first := EditLogFile("/work/alpha")
	second := EditLogFile("/other/alpha")
	if first == second {
		t.Fatalf("different roots share %q", first)
	}
	if filepath.Base(first)[:6] != "alpha-" || !strings.HasSuffix(first, ".jsonl") {
		t.Fatalf("edit log path = %q", first)
	}
	if EditLogFile("/work/alpha") != first {
		t.Fatal("edit log path changed for the same root")
	}
	if !strings.HasSuffix(DeltaDir("/work/alpha"), ".delta") || !strings.HasSuffix(PromptFile("/work/alpha"), ".prompt") {
		t.Fatal("derived paths lost their suffix")
	}
}

func TestWorkerKeyed(t *testing.T) {
	for _, name := range []string{"repo-0123456789abcdef", "nested-name-abcdef0123456789"} {
		if !WorkerKeyed(name) {
			t.Fatalf("WorkerKeyed rejected %q", name)
		}
	}
	for _, name := range []string{"repo", "repo-0123", "repo-0123456789abcdeg", "-0123456789abcdef"} {
		if WorkerKeyed(name) {
			t.Fatalf("WorkerKeyed accepted %q", name)
		}
	}
}
