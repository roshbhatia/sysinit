package worklog

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

var stamp = time.Date(2026, 8, 13, 19, 4, 0, 0, time.UTC)

func isolate(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()
	t.Setenv("HOME", filepath.Join(dir, "home"))
	t.Setenv("XDG_STATE_HOME", filepath.Join(dir, "state"))
	t.Setenv("SYSINIT_PATHS_MANIFEST", filepath.Join(dir, "no-manifest.json"))
	log := filepath.Join(dir, "worklog.jsonl")
	t.Setenv("CLAUDE_WORKLOG_FILE", log)
	return log
}

func repoIn(t *testing.T, dir string) string {
	t.Helper()
	upstream := filepath.Join(dir, "upstream.git")
	work := filepath.Join(dir, "work")
	runGit(t, "", "init", "--bare", "--initial-branch=main", upstream)
	runGit(t, "", "clone", "--quiet", upstream, work)
	runGit(t, work, "config", "user.email", "probe@example.com")
	runGit(t, work, "config", "user.name", "Probe")
	write(t, filepath.Join(work, "base.txt"), "one\n")
	runGit(t, work, "add", "-A")
	runGit(t, work, "commit", "--quiet", "-m", "base commit")
	runGit(t, work, "push", "--quiet", "origin", "main")
	runGit(t, work, "remote", "set-head", "origin", "main")

	write(t, filepath.Join(work, "added.txt"), "two\nthree\n")
	runGit(t, work, "add", "-A")
	runGit(t, work, "commit", "--quiet", "-m", "add a file")
	write(t, filepath.Join(work, "base.txt"), "one\nedited\n")
	return work
}

func runGit(t *testing.T, dir string, args ...string) {
	t.Helper()
	cmd := exec.Command("git", args...)
	if dir != "" {
		cmd.Dir = dir
	}
	cmd.Env = append(os.Environ(), "GIT_CONFIG_GLOBAL=/dev/null", "GIT_CONFIG_SYSTEM=/dev/null")
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("git %s: %v\n%s", strings.Join(args, " "), err, out)
	}
}

func write(t *testing.T, path, body string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
}

func transcriptIn(t *testing.T, session string) string {
	t.Helper()
	dir := filepath.Join(os.Getenv("HOME"), ".claude", "projects", "probe")
	path := filepath.Join(dir, session+".jsonl")
	write(t, path, strings.Join([]string{
		`{"type":"user","timestamp":"2026-08-13T18:34:00Z","message":{"content":"first   prompt\nwith breaks"}}`,
		`{"type":"assistant","timestamp":"2026-08-13T18:35:00Z","message":{"model":"claude-opus-5","content":[{"type":"text","text":"working"}]}}`,
		`{"type":"user","timestamp":"2026-08-13T18:40:00Z","message":{"content":[{"type":"text","text":"second prompt"},{"type":"tool_result","text":"ignored"}]}}`,
	}, "\n")+"\n")
	return path
}

func TestARepoSessionRecordsTheBranchesWorkAndTheIntent(t *testing.T) {
	isolate(t)
	work := repoIn(t, t.TempDir())
	transcriptIn(t, "s1")

	record, ok := build(event{SessionID: "s1", CWD: work, Reason: "clear"}, stamp)
	if !ok {
		t.Fatal("nothing was recorded for a repo session")
	}

	if record.V != 2 || record.Kind != "repo" || record.SessionName != "" {
		t.Errorf("shape = v%d kind=%q name=%q", record.V, record.Kind, record.SessionName)
	}
	if len(record.Repos) != 1 {
		t.Fatalf("repos = %d, want 1", len(record.Repos))
	}
	repo := record.Repos[0]
	if repo.Branch != "main" || repo.Base != "main" {
		t.Errorf("branch=%q base=%q", repo.Branch, repo.Base)
	}
	if repo.CommitsAhead != 1 || len(repo.Commits) != 1 || repo.Commits[0].Subject != "add a file" {
		t.Errorf("ahead=%d commits=%+v", repo.CommitsAhead, repo.Commits)
	}
	if repo.Insertions != 2 || repo.Deletions != 0 {
		t.Errorf("insertions=%d deletions=%d, want 2 and 0", repo.Insertions, repo.Deletions)
	}
	if len(repo.Files) != 1 || repo.Files[0].Status != "A" || !strings.HasSuffix(repo.Files[0].Path, "added.txt") {
		t.Errorf("files = %+v", repo.Files)
	}

	if repo.Dirty == "" {
		t.Error("a dirty worktree reported no shortstat")
	}

	if record.UserTurns != 2 {
		t.Errorf("user_turns = %d, want 2", record.UserTurns)
	}

	if record.FirstPrompt != "first prompt with breaks" {
		t.Errorf("first_prompt = %q", record.FirstPrompt)
	}
	if record.LastPrompt != "second prompt" {
		t.Errorf("last_prompt = %q", record.LastPrompt)
	}
	if record.Model == nil || *record.Model != "claude-opus-5" {
		t.Errorf("model = %v", record.Model)
	}
	if record.DurationMin == nil || *record.DurationMin != 30 {
		t.Errorf("duration_min = %v, want 30", record.DurationMin)
	}
}

func TestASeshySessionRecordsEveryWorktreeUnderIt(t *testing.T) {
	isolate(t)
	dir := t.TempDir()
	t.Setenv("XDG_STATE_HOME", dir)
	sessions := filepath.Join(dir, "seshy", "sessions", "a-session")
	for _, name := range []string{"zeta", "alpha"} {
		work := repoIn(t, filepath.Join(dir, "src", name))
		if err := os.MkdirAll(sessions, 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.Rename(work, filepath.Join(sessions, name)); err != nil {
			t.Fatal(err)
		}
	}

	write(t, filepath.Join(sessions, "notes", "todo.md"), "x\n")

	record, ok := build(event{SessionID: "s2", CWD: filepath.Join(sessions, "alpha")}, stamp)
	if !ok {
		t.Fatal("nothing was recorded for a seshy session")
	}
	if record.Kind != "seshy-session" || record.SessionName != "a-session" {
		t.Errorf("kind=%q name=%q", record.Kind, record.SessionName)
	}
	if len(record.Repos) != 2 {
		t.Fatalf("repos = %d, want 2", len(record.Repos))
	}

	if record.Repos[0].Name != "alpha" || record.Repos[1].Name != "zeta" {
		t.Errorf("order = %s, %s", record.Repos[0].Name, record.Repos[1].Name)
	}
}

func TestNothingWorthALineIsNotRecorded(t *testing.T) {
	isolate(t)
	plain := t.TempDir()
	for _, probe := range []struct {
		name string
		ev   event
	}{
		{"no session id", event{CWD: plain}},
		{"a resume has no finished work", event{SessionID: "s3", CWD: plain, Reason: "resume"}},
		{"no repository and no prompt", event{SessionID: "s4", CWD: plain}},
	} {
		if _, ok := build(probe.ev, stamp); ok {
			t.Errorf("%s: a record was built anyway", probe.name)
		}
	}
}

func TestADirectorySessionWithAPromptIsRecorded(t *testing.T) {
	isolate(t)
	transcriptIn(t, "s5")
	record, ok := build(event{SessionID: "s5", CWD: t.TempDir()}, stamp)
	if !ok {
		t.Fatal("a prompt with no repository was dropped")
	}
	if record.Kind != "dir" || len(record.Repos) != 0 {
		t.Errorf("kind=%q repos=%d", record.Kind, len(record.Repos))
	}
}

func TestARemoteBecomesABrowsableURL(t *testing.T) {
	for _, probe := range []struct{ in, want string }{
		{"git@github.com:roshbhatia/sysinit.git", "https://github.com/roshbhatia/sysinit"},
		{"ssh://git@github.com/roshbhatia/sysinit.git", "https://github.com/roshbhatia/sysinit"},
		{"https://github.com/roshbhatia/sysinit.git", "https://github.com/roshbhatia/sysinit"},
		{"https://github.com/roshbhatia/sysinit", "https://github.com/roshbhatia/sysinit"},
	} {
		if got := normalizeRemote(probe.in); got != probe.want {
			t.Errorf("normalizeRemote(%q) = %q, want %q", probe.in, got, probe.want)
		}
	}
}

func TestAPromptIsCutByCharacter(t *testing.T) {
	if got := truncate(strings.Repeat("é", 300), promptChars); len([]rune(got)) != promptChars {
		t.Errorf("cut to %d runes, want %d", len([]rune(got)), promptChars)
	}
	if got := truncate("short", promptChars); got != "short" {
		t.Errorf("a short prompt was changed to %q", got)
	}
}

func TestTheWrittenLineCarriesEveryFieldTheReaderExpects(t *testing.T) {
	log := isolate(t)
	transcriptIn(t, "s6")
	record, ok := build(event{SessionID: "s6", CWD: t.TempDir(), Reason: "other"}, stamp)
	if !ok {
		t.Fatal("nothing to write")
	}
	if err := appendLine(log, record); err != nil {
		t.Fatal(err)
	}

	if err := appendLine(log, record); err != nil {
		t.Fatal(err)
	}

	data, err := os.ReadFile(log)
	if err != nil {
		t.Fatal(err)
	}
	written := strings.Split(strings.TrimRight(string(data), "\n"), "\n")
	if len(written) != 2 {
		t.Fatalf("lines = %d, want 2", len(written))
	}

	var got map[string]any
	if err := json.Unmarshal([]byte(written[0]), &got); err != nil {
		t.Fatalf("the line does not parse: %v", err)
	}
	for _, key := range []string{
		"v", "ts", "ts_start", "duration_min", "session_id", "kind", "session_name",
		"model", "user_turns", "repos", "cwd", "first_prompt", "last_prompt",
		"transcript_path", "end_reason", "summary",
	} {
		if _, present := got[key]; !present {
			t.Errorf("the record is missing %q", key)
		}
	}
	if got["summary"] != nil {
		t.Errorf("summary = %v, want null", got["summary"])
	}
	if got["ts"] != "2026-08-13T19:04:00Z" {
		t.Errorf("ts = %v", got["ts"])
	}
}

func TestHelpWritesNoRecord(t *testing.T) {
	log := isolate(t)
	if code := Run([]string{"--help"}); code != 0 {
		t.Errorf("--help exited %d", code)
	}
	if _, err := os.Stat(log); !os.IsNotExist(err) {
		t.Error("--help wrote to the log")
	}
}

func TestUnreadableInputStillExitsZero(t *testing.T) {
	isolate(t)
	if code := Run(nil); code != 0 {
		t.Errorf("empty stdin exited %d", code)
	}
}
