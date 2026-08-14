package check

import "testing"

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

func TestAliasesDoNotShadowPresets(t *testing.T) {
	for name := range aliases {
		if _, ok := presets[name]; ok {
			t.Fatalf("alias %q shadows a real preset", name)
		}
	}
}
