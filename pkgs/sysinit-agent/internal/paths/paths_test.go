package paths

import (
	"os"
	"path/filepath"
	"testing"
)

// writeManifest points SYSINIT_PATHS_MANIFEST at a manifest holding body, and
// returns its path. An empty body writes no file, so the manifest is absent.
func writeManifest(t *testing.T, body string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "paths.json")
	if body != "" {
		if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
			t.Fatalf("write manifest: %v", err)
		}
	}
	t.Setenv("SYSINIT_PATHS_MANIFEST", path)
	return path
}

func TestManifestValueWins(t *testing.T) {
	writeManifest(t, `{"version":1,"paths":{"agentPanes":"/srv/panes"}}`)
	t.Setenv("XDG_STATE_HOME", "/ignored")
	if got := AgentPanes(); got != "/srv/panes" {
		t.Fatalf("AgentPanes() = %q, want the manifest value", got)
	}
}

func TestKeyMissingFromTheManifestFallsBack(t *testing.T) {
	// The manifest is present and parses, but has no answer for this key. That
	// is the case a cache-the-whole-document reader gets wrong, so it is worth
	// separating from the absent-manifest case below.
	writeManifest(t, `{"version":1,"paths":{"agentPanes":"/srv/panes"}}`)
	t.Setenv("XDG_STATE_HOME", "/state")
	if got := SeshySessions(); got != "/state/seshy/sessions" {
		t.Fatalf("SeshySessions() = %q, want the documented default", got)
	}
}

func TestAbsentManifestFallsBackToHomeLocalState(t *testing.T) {
	writeManifest(t, "")
	t.Setenv("XDG_STATE_HOME", "")
	t.Setenv("HOME", "/home/someone")
	if got := StateHome(); got != "/home/someone/.local/state" {
		t.Fatalf("StateHome() = %q", got)
	}
	if got := AgentDiffNotes(); got != "/home/someone/.local/state/agents/diff-notes" {
		t.Fatalf("AgentDiffNotes() = %q", got)
	}
}

func TestMalformedManifestFallsBackRatherThanFailing(t *testing.T) {
	// A half-written manifest must not take the agent runtime down. The
	// fallback is the same one an absent manifest reaches.
	writeManifest(t, `{"version":1,"paths":{"agentPanes":`)
	t.Setenv("XDG_STATE_HOME", "/state")
	if got := AgentPanes(); got != "/state/agents/panes" {
		t.Fatalf("AgentPanes() = %q, want the documented default", got)
	}
}

func TestTrailingSlashesAreTrimmedOnBothSides(t *testing.T) {
	// Both sides, because either one alone keys the same directory on a second
	// path and the two ends then disagree about one location.
	writeManifest(t, `{"version":1,"paths":{"stateHome":"/srv/state/"}}`)
	if got := StateHome(); got != "/srv/state" {
		t.Fatalf("StateHome() kept the manifest's trailing slash: %q", got)
	}

	writeManifest(t, "")
	t.Setenv("XDG_STATE_HOME", "/state/")
	if got := StateHome(); got != "/state" {
		t.Fatalf("StateHome() kept the environment's trailing slash: %q", got)
	}
}

func TestEmptyManifestValueIsNotAnAnswer(t *testing.T) {
	writeManifest(t, `{"version":1,"paths":{"seshySessions":""}}`)
	t.Setenv("XDG_STATE_HOME", "/state")
	if got := SeshySessions(); got != "/state/seshy/sessions" {
		t.Fatalf("SeshySessions() = %q, want the documented default", got)
	}
}

func TestLookupDoesNotDependOnTestOrder(t *testing.T) {
	// The reader used to cache the document once per process. Under that cache
	// this second lookup returned the first manifest's answer, so the result
	// depended on which test ran first.
	writeManifest(t, `{"version":1,"paths":{"agentPanes":"/first/panes"}}`)
	if got := AgentPanes(); got != "/first/panes" {
		t.Fatalf("AgentPanes() = %q on the first manifest", got)
	}
	writeManifest(t, `{"version":1,"paths":{"agentPanes":"/second/panes"}}`)
	if got := AgentPanes(); got != "/second/panes" {
		t.Fatalf("AgentPanes() = %q, so the reader is still caching", got)
	}
}
