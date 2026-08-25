package source

import (
	"os"
	"path/filepath"
	"testing"
)

func TestTranscriptAliasExpandsHarnessProvidersOnce(t *testing.T) {
	providers, err := Resolve("transcript,opencode", "")
	if err != nil {
		t.Fatal(err)
	}
	want := []string{"claude", "codex", "opencode"}
	if len(providers) != len(want) {
		t.Fatalf("providers = %d, want %d", len(providers), len(want))
	}
	for index, provider := range providers {
		if provider.Name != want[index] {
			t.Errorf("provider %d = %q, want %q", index, provider.Name, want[index])
		}
	}
}

func writeConfig(t *testing.T, body string) {
	t.Helper()
	path := filepath.Join(t.TempDir(), "traces.json")
	if err := os.WriteFile(path, []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
	t.Setenv(ConfigEnv, path)
}

// A machine that declares nothing still reads every harness that keeps its work
// on disk, which is the case the defaults exist for.
func TestDefaultsNeedNoConfig(t *testing.T) {
	t.Setenv(ConfigEnv, filepath.Join(t.TempDir(), "absent.json"))
	names := map[string]bool{}
	for _, one := range wanted(Config(), "") {
		names[one.Name] = true
	}
	for _, want := range []string{"claude", "codex", "opencode"} {
		if !names[want] {
			t.Errorf("default table is missing %q: %v", want, names)
		}
	}
}

func TestConfigReplacesOneHarnessOnly(t *testing.T) {
	writeConfig(t, `{"providers":{"claude-code":["observe","claude"]}}`)
	table := Config()
	got := table["claude-code"]
	if len(got) != 2 || got[0] != "observe" || got[1] != "claude" {
		t.Errorf("claude-code = %v", got)
	}
	// Replacing one harness must not take the others with it.
	if len(table["codex"]) == 0 {
		t.Errorf("codex lost its default: %v", table)
	}
}

func TestEmptyListTakesASourceAway(t *testing.T) {
	writeConfig(t, `{"providers":{"codex":[]}}`)
	if got, ok := Config()["codex"]; ok {
		t.Errorf("codex = %v, want removed", got)
	}
}

// The point of declaring a source per harness: reading one harness must not
// fetch the sources that answer only for another.
func TestServiceFilterSkipsOtherHarnesses(t *testing.T) {
	writeConfig(t, `{"providers":{"claude-code":["observe","claude"],"codex":["codex"]}}`)
	for _, one := range wanted(Config(), "codex") {
		if one.Name == "observe" || one.Name == "claude" {
			t.Errorf("reading codex fetched %q", one.Name)
		}
	}
	found := false
	for _, one := range wanted(Config(), "codex") {
		found = found || one.Name == "codex"
	}
	if !found {
		t.Error("reading codex skipped its own source")
	}
}

// A prefix is what a reader types: `codex` for the service `codex_cli_rs`.
func TestServiceFilterMatchesAPrefix(t *testing.T) {
	writeConfig(t, `{"providers":{"codex_cli_rs":["codex"]}}`)
	if got := wanted(Config(), "codex"); len(got) != 1 {
		t.Errorf("providers = %d, want 1", len(got))
	}
}

func TestOneSourceServingTwoHarnessesIsFetchedOnce(t *testing.T) {
	writeConfig(t, `{"providers":{"claude-code":["observe"],"codex":["observe"]}}`)
	got := wanted(Config(), "")
	seen := 0
	for _, one := range got {
		if one.Name == "observe" {
			seen++
			if one.For() != "claude-code+codex" {
				t.Errorf("observe answers for %q", one.For())
			}
		}
	}
	if seen != 1 {
		t.Errorf("observe resolved %d times, want 1", seen)
	}
}

// An explicit ask is the escape hatch and is never narrowed by the filter.
func TestExplicitAskIgnoresTheServiceFilter(t *testing.T) {
	got, err := Resolve("claude", "codex")
	if err != nil {
		t.Fatal(err)
	}
	if len(got) != 1 || got[0].Name != "claude" {
		t.Errorf("providers = %v", got)
	}
}

func TestMalformedConfigFallsBackToDefaults(t *testing.T) {
	writeConfig(t, `{"providers":`)
	if len(Config()) != len(Defaults) {
		t.Errorf("table = %v, want the defaults", Config())
	}
}
