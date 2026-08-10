package watch

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func TestLastLinesKeepsTheTrailingN(t *testing.T) {
	body := "one\ntwo\nthree\nfour\n"
	cases := map[int]string{
		0:  "",
		1:  "four\n",
		2:  "three\nfour\n",
		9:  body,
		-1: "",
	}
	for n, want := range cases {
		if got := lastLines(body, n); got != want {
			t.Errorf("lastLines(_, %d) = %q, want %q", n, got, want)
		}
	}

	if got := lastLines("a\nb", 1); got != "b" {
		t.Errorf("lastLines without a final newline = %q, want %q", got, "b")
	}
	if got := lastLines("", 5); got != "" {
		t.Errorf("lastLines of an empty body = %q, want empty", got)
	}
}

func TestWtrunNeverResolvesFromTheViewersOwnPane(t *testing.T) {
	t.Setenv("WEZTERM_PANE", "99")
	t.Setenv("WTRUN_SESSION", "from-env")

	source, err := newWtrun([]string{"explicit"}, "last")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(source.Title(), "explicit") {
		t.Errorf("an explicit session lost to the environment: %q", source.Title())
	}

	source, err = newWtrun(nil, "last")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(source.Title(), "from-env") {
		t.Errorf("WTRUN_SESSION lost to the pane: %q", source.Title())
	}

	t.Setenv("WTRUN_SESSION", "")
	source, err = newWtrun(nil, "last")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(source.Title(), "pane-99") {
		t.Errorf("the pane fallback did not apply: %q", source.Title())
	}
}

func TestWtrunAndTranscriptRejectPathSeparators(t *testing.T) {
	if _, err := newWtrun([]string{"../etc"}, "last"); err == nil {
		t.Error("a session name with a separator was accepted")
	}
	if _, err := newWtrun([]string{"ok"}, "../etc/passwd"); err == nil {
		t.Error("a log name with a separator was accepted")
	}
	if _, err := newTranscript([]string{"../etc/x"}); err == nil {
		t.Error("a transcript harness with a separator was accepted")
	}
	if _, err := newTranscript([]string{"claude"}); err == nil {
		t.Error("a transcript with no session was accepted")
	}
}

func TestTranscriptAcceptsBothSpellings(t *testing.T) {
	one, err := newTranscript([]string{"claude/abc"})
	if err != nil {
		t.Fatal(err)
	}
	two, err := newTranscript([]string{"claude", "abc.jsonl"})
	if err != nil {
		t.Fatal(err)
	}
	if one.Title() != two.Title() {
		t.Errorf("the two spellings resolved differently: %q and %q", one.Title(), two.Title())
	}
}

func TestFileTailEmitsOnlyWhatWasAppended(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "run.log")

	source := &fileTail{path: path, title: "test"}

	var first strings.Builder
	if err := source.Render(&first, 40); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(first.String(), "yet") {
		t.Errorf("an absent file did not say so: %q", first.String())
	}

	var second strings.Builder
	if err := source.Render(&second, 0); err != nil {
		t.Fatal(err)
	}
	if second.String() != "" {
		t.Errorf("the absent notice repeated: %q", second.String())
	}

	if err := os.WriteFile(path, []byte("a\nb\nc\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	var third strings.Builder
	if err := source.Render(&third, 2); err != nil {
		t.Fatal(err)
	}
	if third.String() != "b\nc\n" {
		t.Errorf("history = %q, want %q", third.String(), "b\nc\n")
	}

	var fourth strings.Builder
	if err := source.Render(&fourth, 0); err != nil {
		t.Fatal(err)
	}
	if fourth.String() != "" {
		t.Errorf("an unchanged file printed %q", fourth.String())
	}

	if err := os.WriteFile(path, []byte("a\nb\nc\nd\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	var fifth strings.Builder
	if err := source.Render(&fifth, 0); err != nil {
		t.Fatal(err)
	}
	if fifth.String() != "d\n" {
		t.Errorf("append = %q, want %q", fifth.String(), "d\n")
	}
}

func TestFileTailRestartsWhenTheFileShrinks(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "last.log")
	if err := os.WriteFile(path, []byte("old\nold\nold\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	source := &fileTail{path: path, title: "test"}
	var ignored strings.Builder
	if err := source.Render(&ignored, 40); err != nil {
		t.Fatal(err)
	}

	if err := os.WriteFile(path, []byte("new\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	var after strings.Builder
	if err := source.Render(&after, 0); err != nil {
		t.Fatal(err)
	}
	if after.String() != "new\n" {
		t.Errorf("after a shrink = %q, want %q", after.String(), "new\n")
	}
}

func TestBusShowsOnlyThisWorktree(t *testing.T) {
	panes := t.TempDir()
	t.Setenv("SYSINIT_PATHS_MANIFEST", writeManifest(t, map[string]string{"agentPanes": panes}))

	write := func(pane, worktree, agent string) {
		body, err := json.Marshal(busRecord{
			Pane: json.RawMessage(pane), Worktree: worktree, Agent: agent, Status: "working",
		})
		if err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(filepath.Join(panes, pane+".json"), body, 0o644); err != nil {
			t.Fatal(err)
		}
	}
	write("1", "/repo/here", "claude")
	write("2", "/repo/here/", "codex")
	write("3", "/repo/elsewhere", "pi")

	source, err := newBus([]string{"/repo/here"})
	if err != nil {
		t.Fatal(err)
	}
	var out strings.Builder
	if err := source.Render(&out, 0); err != nil {
		t.Fatal(err)
	}
	got := out.String()
	for _, want := range []string{"claude", "codex"} {
		if !strings.Contains(got, want) {
			t.Errorf("a record for this worktree is missing %q:\n%s", want, got)
		}
	}
	if strings.Contains(got, "pi") {
		t.Errorf("a record from another worktree was shown:\n%s", got)
	}

	var again strings.Builder
	if err := source.Render(&again, 0); err != nil {
		t.Fatal(err)
	}
	if again.String() != "" {
		t.Errorf("an unchanged bus reprinted: %q", again.String())
	}
}

func TestLivenessRejectsAndNeverConfirms(t *testing.T) {
	cmd := exec.Command(os.Args[0], "-test.run=^$")
	if err := cmd.Run(); err != nil {
		t.Fatalf("could not produce a dead pid: %v", err)
	}

	cases := map[string]struct {
		mux  int
		want string
	}{
		"a dead mux is ruled out":     {cmd.Process.Pid, "stale"},
		"a live mux is not confirmed": {os.Getpid(), "unverified"},
		"no marker at all":            {0, "unverified"},
		"a nonsense pid":              {-5, "unverified"},
	}
	for name, c := range cases {
		if got := liveness(busRecord{Mux: c.mux}); got != c.want {
			t.Errorf("%s: liveness = %q, want %q", name, got, c.want)
		}
	}
}

// writeManifest builds a paths manifest holding the given keys and returns its
func writeManifest(t *testing.T, entries map[string]string) string {
	t.Helper()
	body, err := json.Marshal(map[string]any{"version": 1, "paths": entries})
	if err != nil {
		t.Fatal(err)
	}
	path := filepath.Join(t.TempDir(), "paths.json")
	if err := os.WriteFile(path, body, 0o644); err != nil {
		t.Fatal(err)
	}
	return path
}
