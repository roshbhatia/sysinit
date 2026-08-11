package editevent

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"

	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/repo"
)

// isolate points the state root at a temporary directory and returns a working
// directory outside any git repository, so `Workspace` resolves to that
// directory and the log path is predictable.
func isolate(t *testing.T) string {
	t.Helper()
	root := t.TempDir()
	t.Setenv("SYSINIT_PATHS_MANIFEST", filepath.Join(root, "absent.json"))
	t.Setenv("XDG_STATE_HOME", filepath.Join(root, "state"))
	t.Setenv("ZMX_SESSION", "")

	work := filepath.Join(root, "work")
	if err := os.MkdirAll(work, 0o755); err != nil {
		t.Fatalf("mkdir work: %v", err)
	}
	return work
}

// logFor is the path Run writes for a working directory.
func logFor(t *testing.T, work string) string {
	t.Helper()
	return repo.EditLogFile(repo.Workspace(work))
}

func readEvents(t *testing.T, path string) []event {
	t.Helper()
	body, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read log: %v", err)
	}
	var events []event
	for _, line := range strings.Split(strings.TrimRight(string(body), "\n"), "\n") {
		if line == "" {
			continue
		}
		var parsed event
		if err := json.Unmarshal([]byte(line), &parsed); err != nil {
			t.Fatalf("line is not one JSON object: %q: %v", line, err)
		}
		events = append(events, parsed)
	}
	return events
}

func TestWritesOneEventPerFile(t *testing.T) {
	work := isolate(t)

	if code := Run([]string{"claude", "--cwd", work, "--file", "a.go", "--file", "b.go"}); code != 0 {
		t.Fatalf("exit code = %d, want 0", code)
	}

	events := readEvents(t, logFor(t, work))
	if len(events) != 2 {
		t.Fatalf("event count = %d, want 2", len(events))
	}
	for _, e := range events {
		if e.Harness != "claude" {
			t.Errorf("harness = %q, want claude", e.Harness)
		}
		if e.Kind != "edit" {
			t.Errorf("kind = %q, want the edit default", e.Kind)
		}
		if !filepath.IsAbs(e.File) {
			t.Errorf("file = %q, want an absolute path", e.File)
		}
		if e.Version != SchemaVersion {
			t.Errorf("version = %d, want %d", e.Version, SchemaVersion)
		}
		if e.TS <= 0 {
			t.Errorf("ts = %d, want a positive timestamp", e.TS)
		}
	}
}

// The line MUST NOT carry file contents. A reader that found them there would
// use them, and they go stale the moment the agent writes again.
func TestLineCarriesNoFileContents(t *testing.T) {
	work := isolate(t)
	target := filepath.Join(work, "secret.txt")
	if err := os.WriteFile(target, []byte("BODY-SENTINEL"), 0o600); err != nil {
		t.Fatalf("write target: %v", err)
	}

	Run([]string{"claude", "--cwd", work, "--file", target})

	body, err := os.ReadFile(logFor(t, work))
	if err != nil {
		t.Fatalf("read log: %v", err)
	}
	if strings.Contains(string(body), "BODY-SENTINEL") {
		t.Error("the log holds the file's contents; it must hold only its path")
	}
}

// The proposal's "the hook cannot write at all" scenario: exit 0, silently.
func TestUnwritableLogDirectoryStillExitsZero(t *testing.T) {
	work := isolate(t)

	// A regular file where the log directory belongs, so MkdirAll cannot succeed.
	editsDir := filepath.Dir(logFor(t, work))
	if err := os.MkdirAll(filepath.Dir(editsDir), 0o700); err != nil {
		t.Fatalf("mkdir parent: %v", err)
	}
	if err := os.WriteFile(editsDir, []byte("not a directory"), 0o600); err != nil {
		t.Fatalf("write blocker: %v", err)
	}

	if code := Run([]string{"claude", "--cwd", work, "--file", "a.go"}); code != 0 {
		t.Fatalf("exit code = %d, want 0 even when the log cannot be written", code)
	}
}

func TestMissingHarnessExitsZero(t *testing.T) {
	isolate(t)
	if code := Run([]string{"--file", "a.go"}); code != 0 {
		t.Fatalf("exit code = %d, want 0", code)
	}
}

func TestNoFileWritesNothing(t *testing.T) {
	work := isolate(t)

	if code := Run([]string{"claude", "--cwd", work}); code != 0 {
		t.Fatalf("exit code = %d, want 0", code)
	}
	if _, err := os.Stat(logFor(t, work)); !os.IsNotExist(err) {
		t.Error("a call naming no file created a log; it should write nothing")
	}
}

// Two harnesses writing at the same moment MUST each produce an intact line.
func TestConcurrentWritersProduceIntactLines(t *testing.T) {
	work := isolate(t)

	const writers = 8
	const each = 25

	var wg sync.WaitGroup
	for w := 0; w < writers; w++ {
		wg.Add(1)
		go func(w int) {
			defer wg.Done()
			for i := 0; i < each; i++ {
				// A long path, so a line is wide enough that an interleaved
				// write would be visible rather than lucky.
				name := filepath.Join(work, strings.Repeat("deep/", 12), "file.go")
				Run([]string{"harness", "--cwd", work, "--file", name})
			}
		}(w)
	}
	wg.Wait()

	events := readEvents(t, logFor(t, work))
	if len(events) != writers*each {
		t.Fatalf("event count = %d, want %d", len(events), writers*each)
	}
}

// Past the bound the newest events survive and the file gets shorter, which is
// the same replacement the reader has to survive anyway.
func TestBoundKeepsNewestAndShortensFile(t *testing.T) {
	work := isolate(t)
	log := logFor(t, work)
	if err := os.MkdirAll(filepath.Dir(log), 0o700); err != nil {
		t.Fatalf("mkdir log dir: %v", err)
	}

	// A log past maxBytes whose lines are identifiable by index.
	var builder strings.Builder
	total := 0
	for i := 0; builder.Len() <= maxBytes; i++ {
		line, err := json.Marshal(event{Version: SchemaVersion, TS: int64(i), Harness: "old", Kind: "edit", File: "/old", CWD: work})
		if err != nil {
			t.Fatalf("marshal seed: %v", err)
		}
		builder.Write(line)
		builder.WriteByte('\n')
		total++
	}
	seeded := builder.Len()
	if err := os.WriteFile(log, []byte(builder.String()), 0o600); err != nil {
		t.Fatalf("write seed: %v", err)
	}
	if total <= keepLines {
		t.Fatalf("seed produced %d lines, which is not past the %d-line bound", total, keepLines)
	}

	Run([]string{"claude", "--cwd", work, "--file", "new.go"})

	events := readEvents(t, log)
	if len(events) != keepLines+1 {
		t.Fatalf("event count = %d, want %d kept plus the new one", len(events), keepLines+1)
	}
	if events[len(events)-1].Harness != "claude" {
		t.Error("the newest event is not last; truncation dropped the wrong end")
	}
	if events[0].TS != int64(total-keepLines) {
		t.Errorf("oldest kept ts = %d, want %d; the newest lines are not the ones kept", events[0].TS, total-keepLines)
	}

	info, err := os.Stat(log)
	if err != nil {
		t.Fatalf("stat log: %v", err)
	}
	if info.Size() >= int64(seeded) {
		t.Errorf("log size = %d, want shorter than the %d it held before", info.Size(), seeded)
	}
	if _, err := os.Stat(log + ".trim"); !os.IsNotExist(err) {
		t.Error("the temporary file used for truncation was left behind")
	}
}

func TestKindOverridesTheDefault(t *testing.T) {
	work := isolate(t)

	Run([]string{"claude", "--cwd", work, "--kind", "write", "--file", "a.go"})

	events := readEvents(t, logFor(t, work))
	if len(events) != 1 || events[0].Kind != "write" {
		t.Fatalf("events = %+v, want one with kind write", events)
	}
}

func TestSeshySessionKeysOneLogForSeveralRepositories(t *testing.T) {
	root := t.TempDir()
	manifest := filepath.Join(root, "paths.json")
	sessions := filepath.Join(root, "sessions")
	body, err := json.Marshal(map[string]any{
		"version": 1,
		"paths": map[string]string{
			"seshySessions": sessions,
			"agentEdits":    filepath.Join(root, "edits"),
		},
	})
	if err != nil {
		t.Fatalf("marshal manifest: %v", err)
	}
	if err := os.WriteFile(manifest, body, 0o600); err != nil {
		t.Fatalf("write manifest: %v", err)
	}
	t.Setenv("SYSINIT_PATHS_MANIFEST", manifest)

	first := filepath.Join(sessions, "a-session", "repo-one")
	second := filepath.Join(sessions, "a-session", "repo-two")
	for _, dir := range []string{first, second} {
		if err := os.MkdirAll(dir, 0o755); err != nil {
			t.Fatalf("mkdir %s: %v", dir, err)
		}
	}

	if repo.Workspace(first) != repo.Workspace(second) {
		t.Fatalf("two directories in one session resolved to %q and %q; they must share a workspace",
			repo.Workspace(first), repo.Workspace(second))
	}

	Run([]string{"claude", "--cwd", first, "--file", "one.go"})
	Run([]string{"amp", "--cwd", second, "--file", "two.go"})

	events := readEvents(t, repo.EditLogFile(repo.Workspace(first)))
	if len(events) != 2 {
		t.Fatalf("event count = %d, want both repositories in one log", len(events))
	}
}

func TestStdinSuppliesTheFileWhenNoFlagDoes(t *testing.T) {
	work := isolate(t)

	payload, err := json.Marshal(map[string]any{
		"cwd":        work,
		"tool_input": map[string]any{"file_path": filepath.Join(work, "from-stdin.go")},
	})
	if err != nil {
		t.Fatalf("marshal payload: %v", err)
	}

	withStdin(t, payload, func() {
		Run([]string{"claude"})
	})

	events := readEvents(t, logFor(t, work))
	if len(events) != 1 || !strings.HasSuffix(events[0].File, "from-stdin.go") {
		t.Fatalf("events = %+v, want the path read from stdin", events)
	}
}

// withStdin replaces os.Stdin with a pipe holding body for the duration of run.
func withStdin(t *testing.T, body []byte, run func()) {
	t.Helper()
	reader, writer, err := os.Pipe()
	if err != nil {
		t.Fatalf("pipe: %v", err)
	}
	original := os.Stdin
	os.Stdin = reader
	defer func() {
		os.Stdin = original
		reader.Close()
	}()

	go func() {
		writer.Write(body)
		writer.Close()
	}()
	run()
}
