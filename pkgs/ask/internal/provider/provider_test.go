package provider

import (
	"strings"
	"testing"
)

func TestAProviderIsFoundByEitherNameItGoesBy(t *testing.T) {
	for _, one := range []struct {
		given string
		want  string
	}{
		{"", "claude"},
		{"claude", "claude"},
		{"c", "claude"},
		{"codex", "codex"},
		{"o", "codex"},
	} {
		found, err := Find(one.given)
		if err != nil {
			t.Fatalf("%q: %v", one.given, err)
		}
		if found.Name() != one.want {
			t.Errorf("%q found %s, want %s", one.given, found.Name(), one.want)
		}
	}
}

func TestAProviderNoOneKnowsIsRejectedByName(t *testing.T) {
	_, err := Find("bogus")
	if err == nil {
		t.Fatal("an unknown provider was accepted")
	}
	for _, named := range []string{"bogus", "claude", "codex"} {
		if !strings.Contains(err.Error(), named) {
			t.Errorf("the error %q does not name %q", err, named)
		}
	}
}
