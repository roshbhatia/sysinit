package check

import "testing"

// The rename from rosh-spec-driven to spec-driven has to keep resolving the old
// name: archived changes pin it in .openspec.yaml and are not rewritten.
func TestRetiredSchemaNameStillResolves(t *testing.T) {
	if !HasPreset("rosh-spec-driven") {
		t.Fatal("retired name rosh-spec-driven no longer resolves")
	}
	viaAlias, err := Resolve(Config{Preset: "rosh-spec-driven"})
	if err != nil {
		t.Fatalf("resolve via alias: %v", err)
	}
	direct, err := Resolve(Config{Preset: "spec-driven"})
	if err != nil {
		t.Fatalf("resolve direct: %v", err)
	}
	if len(viaAlias) != len(direct) {
		t.Fatalf("alias resolved %d rules, direct resolved %d", len(viaAlias), len(direct))
	}
	if len(direct) == 0 {
		t.Fatal("spec-driven preset resolved zero rules")
	}
}

// An alias must never shadow a real preset.
func TestAliasesDoNotShadowPresets(t *testing.T) {
	for name := range aliases {
		if _, ok := presets[name]; ok {
			t.Fatalf("alias %q shadows a real preset", name)
		}
	}
}
