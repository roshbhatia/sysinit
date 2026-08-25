package source

import "testing"

func TestTranscriptAliasExpandsHarnessProvidersOnce(t *testing.T) {
	providers, err := Resolve("transcript,opencode")
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
