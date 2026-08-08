package agentstate

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestTidyFoldsEverySeparatorItOwns(t *testing.T) {
	// The pipe is the OSC payload's own field separator, so one inside a
	// reason forges a field. A newline does the same to the file bus.
	cases := map[string]string{
		"a|b":              "a b",
		"a\nb":             "a b",
		"a\r\nb":           "a b",
		"a\tb":             "a b",
		"  leading":        "leading",
		"trailing   ":      "trailing",
		"many     spaces":  "many spaces",
		"working|done|now": "working done now",
	}
	for in, want := range cases {
		if got := tidy(in); got != want {
			t.Errorf("tidy(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestTruncateCapsTheReasonAtTheRenderedWidth(t *testing.T) {
	long := strings.Repeat("x", 200)
	if got := truncate(long, reasonLimit); len([]rune(got)) != reasonLimit {
		t.Fatalf("expected %d runes, got %d", reasonLimit, len([]rune(got)))
	}
	if got := truncate("short", reasonLimit); got != "short" {
		t.Fatalf("truncate shortened a string under the cap: %q", got)
	}
	// Counted in runes, not bytes, so a multibyte reason is not cut mid-character.
	multi := strings.Repeat("é", 80)
	if got := truncate(multi, reasonLimit); len([]rune(got)) != reasonLimit {
		t.Fatalf("multibyte truncation produced %d runes", len([]rune(got)))
	}
}

func TestPaneValueKeepsANumericIDANumber(t *testing.T) {
	// The lua side compares pane ids numerically where it can. Quoting a
	// numeric id would make every comparison fail silently.
	if got := paneValue("12"); got != int64(12) {
		t.Errorf("paneValue(\"12\") = %v (%T), want int64 12", got, got)
	}
	for _, pane := range []string{"abc", "12a", ""} {
		if got := paneValue(pane); got != pane {
			t.Errorf("paneValue(%q) = %v, want the string back", pane, got)
		}
	}
}

func TestDigWalksDottedPathsAndSkipsEmpties(t *testing.T) {
	doc := map[string]any{
		"tool_name": "Bash",
		"tool_input": map[string]any{
			"command":   "",
			"file_path": "/tmp/x",
		},
	}
	if got := dig(doc, "tool_name"); got != "Bash" {
		t.Errorf("dig tool_name = %q", got)
	}
	// An empty string must fall through to the next candidate, which is what
	// jq's `//` did.
	if got := dig(doc, "tool_input.command", "tool_input.file_path"); got != "/tmp/x" {
		t.Errorf("dig did not fall through an empty value: %q", got)
	}
	if got := dig(doc, "absent.deeply.nested"); got != "" {
		t.Errorf("dig invented a value: %q", got)
	}
	// A non-object where an object belongs must not panic.
	if got := dig(map[string]any{"a": 5}, "a.b"); got != "" {
		t.Errorf("dig indexed into a scalar: %q", got)
	}
}

func TestDeriveReasonPerSource(t *testing.T) {
	dir := t.TempDir()
	input := map[string]any{
		"tool_name":  "Bash",
		"tool_input": map[string]any{"command": "ls -la"},
		"message":    "a message",
	}
	cases := []struct {
		src   string
		input map[string]any
		want  string
	}{
		{"tool", input, "Bash: ls -la"},
		{"tool", map[string]any{"tool_name": "Read"}, "Read"},
		{"tool", nil, "working"},
		{"message", input, "a message"},
		{"message", nil, "working"},
		{"", nil, "working"},
		{"a literal reason", nil, "a literal reason"},
	}
	for _, tc := range cases {
		got := deriveReason(tc.src, "working", tc.input, dir, "1", 100)
		if got != tc.want {
			t.Errorf("deriveReason(%q) = %q, want %q", tc.src, got, tc.want)
		}
	}
}

func TestSubmitWritesTheStartStamp(t *testing.T) {
	dir := t.TempDir()
	// The surfaces subtract this to show elapsed time; without it every turn
	// reads as having just started.
	if got := deriveReason("submit", "working", nil, dir, "7", 1234); got != "thinking" {
		t.Fatalf("submit reason = %q", got)
	}
	data, err := os.ReadFile(filepath.Join(dir, "7.start"))
	if err != nil {
		t.Fatalf("no start stamp written: %v", err)
	}
	if string(data) != "1234" {
		t.Fatalf("start stamp = %q, want 1234", data)
	}
}

func TestPublishWritesCompleteJSONOrNothing(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "3.json")
	publish(path, state{Pane: int64(3), Agent: "claude", Status: "working", Since: 42})

	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	var back map[string]any
	if err := json.Unmarshal(data, &back); err != nil {
		t.Fatalf("the published record does not parse: %v: %s", err, data)
	}
	// The wezterm surfaces read these names. A rename here is silent.
	for _, key := range []string{
		"pane", "session", "repo", "branch", "dirty", "worktree",
		"agent", "status", "reason", "since",
	} {
		if _, ok := back[key]; !ok {
			t.Errorf("the file bus record is missing %q", key)
		}
	}
	if back["pane"] != float64(3) {
		t.Errorf("pane serialized as %v, want the number 3", back["pane"])
	}
	if back["dirty"] != false {
		t.Errorf("dirty serialized as %v, want a bool", back["dirty"])
	}
}

func TestPublishLeavesNoTempFileBehind(t *testing.T) {
	dir := t.TempDir()
	publish(filepath.Join(dir, "3.json"), state{Pane: int64(3)})
	entries, err := os.ReadDir(dir)
	if err != nil {
		t.Fatal(err)
	}
	// A surface reading a half-written record shows garbage, and this rewrites
	// on every tool call, so the window is not theoretical.
	for _, entry := range entries {
		if entry.Name() != "3.json" {
			t.Errorf("publish left %s behind", entry.Name())
		}
	}
}

func TestExitRemovesBothPaneFiles(t *testing.T) {
	dir := t.TempDir()
	t.Setenv("XDG_STATE_HOME", dir)
	t.Setenv("WEZTERM_PANE", "9")
	panes := filepath.Join(dir, "agents", "panes")
	if err := os.MkdirAll(panes, 0o755); err != nil {
		t.Fatal(err)
	}
	for _, name := range []string{"9.json", "9.start"} {
		if err := os.WriteFile(filepath.Join(panes, name), []byte("x"), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	if code := Run([]string{"claude", "exit"}); code != 0 {
		t.Fatalf("exit returned %d", code)
	}
	for _, name := range []string{"9.json", "9.start"} {
		if _, err := os.Stat(filepath.Join(panes, name)); err == nil {
			t.Errorf("exit left %s behind", name)
		}
	}
}

func TestNoWezternPaneIsASilentNoOp(t *testing.T) {
	dir := t.TempDir()
	t.Setenv("XDG_STATE_HOME", dir)
	t.Setenv("WEZTERM_PANE", "")
	// The same hooks run under other terminals, where there is no pane to key
	// the record on.
	if code := Run([]string{"claude", "working"}); code != 0 {
		t.Fatalf("Run returned %d with no pane", code)
	}
	if _, err := os.Stat(filepath.Join(dir, "agents", "panes")); err == nil {
		t.Fatal("a record was written with no pane id")
	}
}

func TestStateHomeFallsBackToHomeLocalState(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", "")
	t.Setenv("HOME", "/home/someone")
	if got := stateHome(); got != "/home/someone/.local/state" {
		t.Fatalf("stateHome() = %q", got)
	}
	// A trailing slash must not double up in the joined path.
	t.Setenv("XDG_STATE_HOME", "/state/")
	if got := stateHome(); got != "/state" {
		t.Fatalf("stateHome() kept a trailing slash: %q", got)
	}
}
