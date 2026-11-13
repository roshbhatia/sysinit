package statusline

import (
	"os"
	"path/filepath"
	"testing"
)

func TestWholePercentDropsTheFraction(t *testing.T) {
	for in, want := range map[string]string{
		"42.7": "42",
		"42":   "42",
		"0.1":  "0",
		"":     "",
		"100":  "100",
	} {
		if got := wholePercent(in); got != want {
			t.Errorf("wholePercent(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestSeshySessionNamesOnlyDirectoriesInsideASession(t *testing.T) {
	t.Setenv("HOME", "/home/someone")
	t.Setenv("XDG_STATE_HOME", "/home/someone/.local/state")
	t.Setenv("SYSINIT_PATHS_MANIFEST", filepath.Join(t.TempDir(), "absent.json"))
	root := "/home/someone/.local/state/seshy/sessions"
	if got := seshySession(root + "/zulu/repo/src"); got != "zulu" {
		t.Errorf("seshySession = %q, want zulu", got)
	}
	if got := seshySession(root + "/zulu"); got != "zulu" {
		t.Errorf("seshySession on the session root = %q, want zulu", got)
	}
	for _, dir := range []string{"/home/someone/code/repo", root, root + "-other/zulu"} {
		if got := seshySession(dir); got != "" {
			t.Errorf("seshySession(%q) = %q, want empty", dir, got)
		}
	}
}

func TestMalformedPayloadRendersNothingRatherThanFailing(t *testing.T) {
	for _, body := range []string{"not json", "", "[]"} {
		r, w, err := os.Pipe()
		if err != nil {
			t.Fatal(err)
		}
		if _, err := w.WriteString(body); err != nil {
			t.Fatal(err)
		}
		if err := w.Close(); err != nil {
			t.Fatal(err)
		}
		old := os.Stdin
		os.Stdin = r
		code := Run(nil)
		os.Stdin = old
		if code != 0 {
			t.Errorf("Run returned %d for payload %q", code, body)
		}
	}
}
