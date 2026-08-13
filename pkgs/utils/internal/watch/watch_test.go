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

// workerState points the paths manifest at a temporary tree, so resolving a record
// does not read the owner's real state root.
func workerState(t *testing.T) string {
	t.Helper()
	home := t.TempDir()
	manifest := filepath.Join(home, "paths.json")
	body, err := json.Marshal(map[string]any{
		"version": 1,
		"paths": map[string]string{
			"agentWorker":   filepath.Join(home, "worker"),
			"agentPanes":    filepath.Join(home, "panes"),
			"seshySessions": filepath.Join(home, "no-sessions-here"),
		},
	})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(manifest, body, 0o600); err != nil {
		t.Fatal(err)
	}
	t.Setenv("SYSINIT_PATHS_MANIFEST", manifest)
	return filepath.Join(home, "worker")
}

// The worker source resolves by DIRECTORY, and the viewer's own pane no longer
// enters into it. The pane number was the key before, so a viewer in a different
// pane from the one that ran the command watched the wrong record, or nothing.
func TestTheWorkerSourceResolvesByDirectoryNotByPane(t *testing.T) {
	root := workerState(t)
	t.Setenv("WEZTERM_PANE", "99")

	one, err := newWorker([]string{t.TempDir()}, "last")
	if err != nil {
		t.Fatal(err)
	}
	two, err := newWorker([]string{t.TempDir()}, "last")
	if err != nil {
		t.Fatal(err)
	}
	if one.(*fileTail).path == two.(*fileTail).path {
		t.Error("two different directories resolved to one record")
	}
	for _, source := range []renderer{one, two} {
		if path := source.(*fileTail).path; !strings.HasPrefix(path, root) {
			t.Errorf("record %q is not under the manifest root %q", path, root)
		}
		if strings.Contains(source.(*fileTail).path, "pane-99") {
			t.Errorf("the viewer's own pane leaked into the key: %q", source.(*fileTail).path)
		}
	}

	// No argument means the working directory, the same default `bus` has.
	here := t.TempDir()
	t.Chdir(here)
	implicit, err := newWorker(nil, "last")
	if err != nil {
		t.Fatal(err)
	}
	explicit, err := newWorker([]string{here}, "last")
	if err != nil {
		t.Fatal(err)
	}
	if implicit.(*fileTail).path != explicit.(*fileTail).path {
		t.Errorf("the default %q differs from the explicit directory %q",
			implicit.(*fileTail).path, explicit.(*fileTail).path)
	}
}

// The override reaches the watcher too, which is what makes a private worker
// watchable. It is the same variable the worker itself reads, so there is one key
// rule rather than two: honouring a second name resolved to a path nothing writes.
func TestTheWorkerSourceHonoursTheSessionOverride(t *testing.T) {
	workerState(t)
	dir := t.TempDir()

	plain, err := newWorker([]string{dir}, "last")
	if err != nil {
		t.Fatal(err)
	}

	t.Setenv("SYSINIT_WORKER_SESSION", "build")
	overridden, err := newWorker([]string{dir}, "last")
	if err != nil {
		t.Fatal(err)
	}
	if plain.(*fileTail).path == overridden.(*fileTail).path {
		t.Error("the override did not change the record the watcher reads")
	}
	if !strings.Contains(overridden.(*fileTail).path, "/build/") {
		t.Errorf("override path = %q, want it under the chosen name", overridden.(*fileTail).path)
	}

	// A value the worker would refuse to write under is refused here too, rather than
	// silently falling back to the shared record.
	t.Setenv("SYSINIT_WORKER_SESSION", "../escape")
	if _, err := newWorker([]string{dir}, "last"); err == nil {
		t.Error("an unusable override resolved anyway")
	}
}

func TestTheLogNameAndTranscriptRejectPathSeparators(t *testing.T) {
	workerState(t)
	// The directory argument is a PATH now, so a separator in it is ordinary. The guard
	// moved to the derived key, which the caller does not choose, and to the log name.
	if _, err := newWorker([]string{t.TempDir()}, "../etc/passwd"); err == nil {
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
