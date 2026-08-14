package config

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func here(t *testing.T) {
	t.Helper()
	t.Setenv("XDG_CONFIG_HOME", t.TempDir())
}

func TestASettingIsWrittenAndReadBack(t *testing.T) {
	here(t)

	key, value, err := Set(ProviderDefault + "=codex")
	if err != nil {
		t.Fatal(err)
	}
	if key != ProviderDefault || value != "codex" {
		t.Errorf("the write answered %q=%q", key, value)
	}

	got, err := Get(ProviderDefault)
	if err != nil {
		t.Fatal(err)
	}
	if got != "codex" {
		t.Errorf("the setting reads back as %q", got)
	}
}

func TestAShortNameIsStoredAsTheNameItStandsFor(t *testing.T) {
	here(t)

	if _, value, err := Set(ProviderDefault + "=cld"); err != nil || value != "claude" {
		t.Errorf("cld was stored as %q, %v", value, err)
	}
	if got, _ := Get(ProviderDefault); got != "claude" {
		t.Errorf("the setting reads back as %q, want claude", got)
	}
}

func TestAnUnsetSettingIsEmptyRatherThanAnError(t *testing.T) {
	here(t)

	got, err := Get(ProviderDefault)
	if err != nil {
		t.Fatalf("reading a settings file that was never written failed: %v", err)
	}
	if got != "" {
		t.Errorf("the setting reads as %q", got)
	}
}

func TestAnEmptyValueUnsetsTheSetting(t *testing.T) {
	here(t)

	if _, _, err := Set(ProviderDefault + "=codex"); err != nil {
		t.Fatal(err)
	}
	if _, value, err := Set(ProviderDefault + "="); err != nil || value != "" {
		t.Errorf("the unset answered %q, %v", value, err)
	}
	if got, _ := Get(ProviderDefault); got != "" {
		t.Errorf("the setting is still %q", got)
	}
}

func TestASettingNoOneKnowsIsRejected(t *testing.T) {
	here(t)

	if _, _, err := Set("provider.nope=claude"); err == nil {
		t.Error("an unknown key was written")
	}
	if _, err := Get("provider.nope"); err == nil {
		t.Error("an unknown key was read")
	}
	if _, err := os.Stat(Path()); err == nil {
		t.Error("a rejected write still made the settings file")
	}
}

func TestAValueOutsideTheAllowedSetIsRejected(t *testing.T) {
	here(t)

	_, _, err := Set(ProviderDefault + "=bogus")
	if err == nil {
		t.Fatal("an unknown provider was written")
	}
	if !strings.Contains(err.Error(), "bogus") {
		t.Errorf("the error %q does not name the value", err)
	}
}

func TestAPairWithNoEqualsIsRejected(t *testing.T) {
	here(t)

	if _, _, err := Set(ProviderDefault); err == nil {
		t.Error("a pair with no value was accepted")
	}
}

func TestASettingsFileThatWillNotParseIsReported(t *testing.T) {
	here(t)

	if err := os.MkdirAll(filepath.Dir(Path()), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(Path(), []byte("{not json"), 0o600); err != nil {
		t.Fatal(err)
	}

	_, err := Get(ProviderDefault)
	if err == nil {
		t.Fatal("a settings file that will not parse was read as empty")
	}
	if !strings.Contains(err.Error(), Path()) {
		t.Errorf("the error %q does not name the file", err)
	}
}

// An interrupted first write leaves a file of no bytes behind, which is not a
// settings file anyone wrote and must not stop a run.
func TestASettingsFileOfNoBytesReadsAsUnset(t *testing.T) {
	here(t)

	if err := os.MkdirAll(filepath.Dir(Path()), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(Path(), nil, 0o600); err != nil {
		t.Fatal(err)
	}

	if got, err := Get(ProviderDefault); err != nil || got != "" {
		t.Errorf("an empty settings file read as %q, %v", got, err)
	}
}

func TestListNamesEverySettingIncludingTheUnsetOnes(t *testing.T) {
	here(t)

	lines, err := List()
	if err != nil {
		t.Fatal(err)
	}
	if len(lines) != len(Keys()) {
		t.Fatalf("the list holds %d lines for %d settings", len(lines), len(Keys()))
	}
	if !strings.Contains(lines[0], "(unset)") {
		t.Errorf("an unset setting reads as %q", lines[0])
	}
}

func TestTheSettingsFileSitsUnderTheConfigHome(t *testing.T) {
	home := t.TempDir()
	t.Setenv("XDG_CONFIG_HOME", home)

	if want := filepath.Join(home, "ask", "config.json"); Path() != want {
		t.Errorf("the settings live at %q, want %q", Path(), want)
	}
}

func TestEverySettingCarriesItsOwnHelp(t *testing.T) {
	for _, one := range Settings() {
		if one.Key == "" || one.Help == "" {
			t.Errorf("%+v is missing a field", one)
		}
	}
}
