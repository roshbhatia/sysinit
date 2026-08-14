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
		{"claude", "claude"},
		{"cld", "claude"},
		{"codex", "codex"},
		{"cdx", "codex"},
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

func TestNoProviderIsTheDefaultOne(t *testing.T) {
	if _, err := Find(""); err == nil {
		t.Fatal("an unnamed provider was accepted")
	}
}

func TestAProviderNoOneKnowsIsRejectedByName(t *testing.T) {
	_, err := Find("bogus")
	if err == nil {
		t.Fatal("an unknown provider was accepted")
	}
	for _, named := range []string{"bogus", "claude", "cld", "codex", "cdx"} {
		if !strings.Contains(err.Error(), named) {
			t.Errorf("the error %q does not name %q", err, named)
		}
	}
}

func TestEveryKnownProviderIsWholeAndDistinct(t *testing.T) {
	seen := map[string]bool{}
	for _, one := range Known() {
		if one.Name == "" || one.Short == "" || one.Binary == "" || one.Blurb == "" {
			t.Errorf("%+v is missing a field", one)
		}
		if one.New() == nil {
			t.Errorf("%s builds nothing", one.Name)
		}
		for _, spelling := range []string{one.Name, one.Short} {
			if seen[spelling] {
				t.Errorf("%q names two providers", spelling)
			}
			seen[spelling] = true
		}
	}
}

// A wrapper name is a short with a trailing j, so a short ending in j would make
// _<short>j read two ways at once.
func TestNoShortNameEndsInTheLetterThatMeansJSON(t *testing.T) {
	for _, one := range Known() {
		if strings.HasSuffix(one.Short, "j") {
			t.Errorf("the short name %q collides with the json wrapper suffix", one.Short)
		}
	}
}

func TestTheKnownListIsACopy(t *testing.T) {
	taken := Known()
	taken[0].Name = "clobbered"
	if Known()[0].Name == "clobbered" {
		t.Error("the registry was edited through the list it handed out")
	}
}
