package agentstate

import (
	"encoding/base64"
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"testing"

	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/paths"
)

func TestTidyFoldsEverySeparatorItOwns(t *testing.T) {
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
	multi := strings.Repeat("é", 80)
	if got := truncate(multi, reasonLimit); len([]rune(got)) != reasonLimit {
		t.Fatalf("multibyte truncation produced %d runes", len([]rune(got)))
	}
}

func TestPaneValueKeepsANumericIDANumber(t *testing.T) {
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
	if got := dig(doc, "tool_input.command", "tool_input.file_path"); got != "/tmp/x" {
		t.Errorf("dig did not fall through an empty value: %q", got)
	}
	if got := dig(doc, "absent.deeply.nested"); got != "" {
		t.Errorf("dig invented a value: %q", got)
	}
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
	if code := Run([]string{"claude", "working"}); code != 0 {
		t.Fatalf("Run returned %d with no pane", code)
	}
	if _, err := os.Stat(filepath.Join(dir, "agents", "panes")); err == nil {
		t.Fatal("a record was written with no pane id")
	}
}

func TestPaneDirFallsBackToHomeLocalState(t *testing.T) {
	t.Setenv("SYSINIT_PATHS_MANIFEST", filepath.Join(t.TempDir(), "absent.json"))
	t.Setenv("XDG_STATE_HOME", "")
	t.Setenv("HOME", "/home/someone")
	if got := paths.AgentPanes(); got != "/home/someone/.local/state/agents/panes" {
		t.Fatalf("AgentPanes() = %q", got)
	}
	t.Setenv("XDG_STATE_HOME", "/state/")
	if got := paths.AgentPanes(); got != "/state/agents/panes" {
		t.Fatalf("AgentPanes() kept a trailing slash: %q", got)
	}
}

// TestBothEncodingsAgree pins the property SCHEMA.md states: the OSC user
func TestBothEncodingsAgree(t *testing.T) {
	dir := t.TempDir()
	t.Setenv("XDG_STATE_HOME", dir)
	t.Setenv("SYSINIT_PATHS_MANIFEST", filepath.Join(dir, "absent.json"))
	t.Setenv("WEZTERM_PANE", "7")

	var captured string
	original := emitUserVar
	emitUserVar = func(encoded string) { captured = encoded }
	t.Cleanup(func() { emitUserVar = original })

	if code := Run([]string{"claude", "working", "a reason with | a pipe"}); code != 0 {
		t.Fatalf("Run returned %d", code)
	}
	if captured == "" {
		t.Fatal("no user variable was emitted")
	}

	raw, err := base64.StdEncoding.DecodeString(captured)
	if err != nil {
		t.Fatalf("user variable is not base64: %v", err)
	}
	parts := strings.Split(string(raw), "|")
	if len(parts) != 4 {
		t.Fatalf("user variable has %d fields, want 4: %q", len(parts), raw)
	}

	body, err := os.ReadFile(filepath.Join(dir, "agents", "panes", "7.json"))
	if err != nil {
		t.Fatalf("read record: %v", err)
	}
	var record struct {
		Version int    `json:"version"`
		Agent   string `json:"agent"`
		Status  string `json:"status"`
		Reason  string `json:"reason"`
		Since   int64  `json:"since"`
	}
	if err := json.Unmarshal(body, &record); err != nil {
		t.Fatalf("record is not JSON: %v", err)
	}

	if record.Version != SchemaVersion {
		t.Errorf("record version = %d, want %d", record.Version, SchemaVersion)
	}
	if parts[0] != record.Status {
		t.Errorf("status: user var %q, record %q", parts[0], record.Status)
	}
	if parts[1] != record.Reason {
		t.Errorf("reason: user var %q, record %q", parts[1], record.Reason)
	}
	if parts[2] != strconv.FormatInt(record.Since, 10) {
		t.Errorf("since: user var %q, record %d", parts[2], record.Since)
	}
	if parts[3] != record.Agent {
		t.Errorf("agent: user var %q, record %q", parts[3], record.Agent)
	}

	if strings.Contains(record.Reason, "|") {
		t.Errorf("reason kept a pipe: %q", record.Reason)
	}
}

func TestMuxIDReadsTheGenerationMarkerOrNothing(t *testing.T) {
	cases := map[string]int{
		"/Users/x/.local/share/wezterm/gui-sock-1679": 1679,
		"gui-sock-1":         1,
		"":                   0,
		"/tmp/gui-sock-":     0,
		"/tmp/gui-sock-abc":  0,
		"/tmp/gui-sock--3":   0,
		"/tmp/mux-sock-1679": 0,
	}
	for socket, want := range cases {
		t.Setenv("WEZTERM_UNIX_SOCKET", socket)
		if got := muxID(); got != want {
			t.Errorf("muxID() with socket %q = %d, want %d", socket, got, want)
		}
	}
}

// A pid that is certainly not running: start a process, wait for it, then reuse
func deadPid(t *testing.T) int {
	t.Helper()
	cmd := exec.Command(os.Args[0], "-test.run=^$")
	if err := cmd.Run(); err != nil {
		t.Fatalf("could not produce a dead pid: %v", err)
	}
	return cmd.Process.Pid
}

func TestReapRemovesOnlyRecordsFromADeadMux(t *testing.T) {
	dir := t.TempDir()

	dead := deadPid(t)

	write := func(pane string, mux int) {
		body, err := json.Marshal(state{Version: SchemaVersion, Mux: mux, Pane: pane})
		if err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(filepath.Join(dir, pane+".json"), body, 0o644); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(filepath.Join(dir, pane+".start"), []byte("1"), 0o644); err != nil {
			t.Fatal(err)
		}
	}

	current := os.Getpid()
	write("dead", dead)
	write("current", current)
	write("live", os.Getppid())
	write("unmarked", 0)
	if err := os.WriteFile(filepath.Join(dir, "notjson.txt"), []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}

	reapDeadMuxes(dir, current)

	for _, pane := range []string{"current", "live", "unmarked"} {
		if _, err := os.Stat(filepath.Join(dir, pane+".json")); err != nil {
			t.Errorf("%s.json was reaped and should not have been: %v", pane, err)
		}
	}
	if _, err := os.Stat(filepath.Join(dir, "dead.json")); !os.IsNotExist(err) {
		t.Errorf("dead.json survived the reap: %v", err)
	}
	if _, err := os.Stat(filepath.Join(dir, "dead.start")); !os.IsNotExist(err) {
		t.Errorf("dead.start survived the reap: %v", err)
	}
	if _, err := os.Stat(filepath.Join(dir, "notjson.txt")); err != nil {
		t.Errorf("a non-record file was touched: %v", err)
	}
}

func TestReapRunsOncePerMux(t *testing.T) {
	dir := t.TempDir()
	current := os.Getpid()

	dead := deadPid(t)

	reapDeadMuxes(dir, current)

	body, err := json.Marshal(state{Version: SchemaVersion, Mux: dead, Pane: "0"})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "0.json"), body, 0o644); err != nil {
		t.Fatal(err)
	}

	reapDeadMuxes(dir, current)

	if _, err := os.Stat(filepath.Join(dir, "0.json")); err != nil {
		t.Errorf("the second reap scanned the directory again: %v", err)
	}
}

func TestReapWithoutAMarkerDoesNothing(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "0.json"), []byte(`{"mux":1}`), 0o644); err != nil {
		t.Fatal(err)
	}

	reapDeadMuxes(dir, 0)

	if _, err := os.Stat(filepath.Join(dir, "0.json")); err != nil {
		t.Errorf("a record was reaped with no mux of our own: %v", err)
	}
	entries, err := os.ReadDir(dir)
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) != 1 {
		t.Errorf("the marker file was written with no mux: %d entries", len(entries))
	}
}
