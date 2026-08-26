package note

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"testing"
)

func newRepo(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()
	resolved, err := filepath.EvalSymlinks(dir)
	if err != nil {
		t.Fatalf("resolve tempdir: %v", err)
	}
	for _, args := range [][]string{
		{"init", "--quiet", "-b", "main"},
		{"config", "user.email", "test@example.com"},
		{"config", "user.name", "test"},
	} {
		cmd := exec.Command("git", args...)
		cmd.Dir = resolved
		if out, err := cmd.CombinedOutput(); err != nil {
			t.Fatalf("git %v: %v: %s", args, err, out)
		}
	}
	if err := os.MkdirAll(filepath.Join(resolved, "src"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(resolved, "src", "app.ts"), []byte("one\ntwo\nthree\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	t.Setenv("XDG_STATE_HOME", filepath.Join(resolved, ".state"))
	t.Chdir(resolved)
	return resolved
}

func run(t *testing.T, args ...string) (int, string) {
	t.Helper()
	old := os.Stdout
	r, w, err := os.Pipe()
	if err != nil {
		t.Fatal(err)
	}
	os.Stdout = w
	var out strings.Builder
	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		buf := make([]byte, 4096)
		for {
			n, err := r.Read(buf)
			out.Write(buf[:n])
			if err != nil {
				return
			}
		}
	}()
	code := Run(args)
	w.Close()
	wg.Wait()
	os.Stdout = old
	return code, out.String()
}

func storePath(t *testing.T) string {
	t.Helper()
	code, out := run(t, "path")
	if code != 0 {
		t.Fatalf("path exited %d", code)
	}
	return strings.TrimSpace(out)
}

func notes(t *testing.T) []map[string]any {
	t.Helper()
	code, out := run(t, "list", "--json")
	if code != 0 {
		t.Fatalf("list --json exited %d", code)
	}
	var doc struct {
		Notes []map[string]any `json:"notes"`
	}
	if err := json.Unmarshal([]byte(out), &doc); err != nil {
		t.Fatalf("list --json is not valid JSON: %v: %s", err, out)
	}
	return doc.Notes
}

func openNotes(t *testing.T) []map[string]any {
	t.Helper()
	code, out := run(t, "list", "--open", "--json")
	if code != 0 {
		t.Fatalf("list --open --json exited %d", code)
	}
	var doc struct {
		Notes []map[string]any `json:"notes"`
	}
	if err := json.Unmarshal([]byte(out), &doc); err != nil {
		t.Fatalf("list --open --json is not valid JSON: %v: %s", err, out)
	}
	return doc.Notes
}

func mustAdd(t *testing.T, args ...string) {
	t.Helper()
	if code, _ := run(t, append([]string{"add"}, args...)...); code != 0 {
		t.Fatalf("add %v exited %d", args, code)
	}
}

func TestPathIsStableAndHonoursStateHome(t *testing.T) {
	root := newRepo(t)
	path := storePath(t)
	if !strings.HasPrefix(path, filepath.Join(root, ".state")+"/agents/diff-notes/") {
		t.Fatalf("store is not under the state home: %s", path)
	}
	t.Setenv("XDG_STATE_HOME", filepath.Join(root, ".state")+"/")
	if slashed := storePath(t); slashed != path {
		t.Fatalf("a trailing slash changed the path:\n  %s\n  %s", path, slashed)
	}
}

func TestPathFallsBackToHomeLocalState(t *testing.T) {
	newRepo(t)
	t.Setenv("XDG_STATE_HOME", "")
	t.Setenv("HOME", "/home/someone")
	path := storePath(t)
	if !strings.HasPrefix(path, "/home/someone/.local/state/") {
		t.Fatalf("fallback path is not under $HOME/.local/state: %s", path)
	}
}

func TestAddRejectsLineWithLeadingZero(t *testing.T) {
	newRepo(t)
	for _, line := range []string{"0", "00", "0123", "1.5", "-1", "x", ""} {
		if code, _ := run(t, "add", "--file", "src/app.ts", "--line", line, "--summary", "x"); code == 0 {
			t.Errorf("add accepted --line %q", line)
		}
	}
	if code, _ := run(t, "add", "--file", "src/app.ts", "--line", "1", "--summary", "x"); code != 0 {
		t.Error("add rejected a plain positive line")
	}
}

func TestAddRejectsControlBytesInThePath(t *testing.T) {
	newRepo(t)
	for _, file := range []string{"src/\x1b[2Jhax.ts", "src/app.ts\nsrc/other.ts:9  forged"} {
		if code, _ := run(t, "add", "--file", file, "--line", "1", "--summary", "ok"); code == 0 {
			t.Errorf("add accepted a control byte in %q", file)
		}
	}
}

func TestAddStripsControlBytesFromTheSummary(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "ok\x1b[2Jcleared\rhidden")
	stored := notes(t)[0]["summary"].(string)
	if strings.ContainsAny(stored, "\x1b\r\n") {
		t.Fatalf("a control byte survived into the stored summary: %q", stored)
	}
	if stored != "ok[2Jclearedhidden" {
		t.Fatalf("unexpected cleaned summary: %q", stored)
	}
}

func TestAddRejectsSummaryThatIsEmptyOnceStripped(t *testing.T) {
	newRepo(t)
	if code, _ := run(t, "add", "--file", "src/app.ts", "--line", "1", "--summary", "\r\a\b"); code == 0 {
		t.Fatal("add accepted a summary that is empty once stripped")
	}
}

func TestAddRejectsAFlagWithNoValue(t *testing.T) {
	newRepo(t)
	if code, _ := run(t, "add", "--file", "src/app.ts", "--line", "1", "--summary"); code == 0 {
		t.Fatal("add accepted --summary with no value")
	}
}

func TestAddReplaceDropsOnlyTheSameFileLineAuthor(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "first", "--author", "pi")
	mustAdd(t, "--file", "src/app.ts", "--line", "2", "--summary", "other", "--author", "pi")
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "elsewhere", "--author", "claude")
	mustAdd(t, "--replace", "--file", "src/app.ts", "--line", "1", "--summary", "second", "--author", "pi")

	got := notes(t)
	if len(got) != 3 {
		t.Fatalf("expected 3 notes after --replace, got %d", len(got))
	}
	for _, note := range got {
		if note["summary"] == "first" {
			t.Fatal("--replace left the note it was meant to supersede")
		}
	}
}

func TestAddRecordsWhoWroteTheNote(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "theirs")
	mustAdd(t, "--file", "src/app.ts", "--line", "2", "--summary", "mine", "--origin", "user")

	got := notes(t)
	if got[0]["origin"] != "agent" {
		t.Fatalf("a note written with no --origin is not an agent's: %v", got[0]["origin"])
	}
	if got[1]["origin"] != "user" {
		t.Fatalf("--origin user was not recorded: %v", got[1]["origin"])
	}
}

func TestAddRejectsAnOriginThatIsNeither(t *testing.T) {
	newRepo(t)
	code, _ := run(t, "add", "--file", "src/app.ts", "--line", "1", "--summary", "x", "--origin", "robot")
	if code == 0 {
		t.Fatal("add accepted an origin that is neither agent nor user")
	}
	if got := len(notes(t)); got != 0 {
		t.Fatalf("a rejected origin still wrote %d note(s)", got)
	}
}

func TestClearLineRemovesOnlyThatLine(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "one")
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "one again", "--author", "pi")
	mustAdd(t, "--file", "src/app.ts", "--line", "2", "--summary", "two")

	if code, _ := run(t, "clear", "--file", "src/app.ts", "--line", "1"); code != 0 {
		t.Fatalf("clear --line exited %d", code)
	}
	got := notes(t)
	if len(got) != 1 || got[0]["summary"] != "two" {
		t.Fatalf("clear --line did not leave exactly the other line: %v", got)
	}
}

func TestClearLineNeedsAFile(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "one")
	if code, _ := run(t, "clear", "--line", "1", "--yes"); code == 0 {
		t.Fatal("clear accepted --line with no --file")
	}
	if got := len(notes(t)); got != 1 {
		t.Fatalf("the refused clear removed notes anyway: %d left", got)
	}
}

func rewrite(t *testing.T, root, relative, body string) {
	t.Helper()
	if err := os.WriteFile(filepath.Join(root, relative), []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}
}

func lineOf(t *testing.T, summary string) int64 {
	t.Helper()
	for _, note := range notes(t) {
		if note["summary"] == summary {
			line, ok := note["line"].(float64)
			if !ok {
				t.Fatalf("the note %q carries no line", summary)
			}
			return int64(line)
		}
	}
	t.Fatalf("no note reads %q", summary)
	return 0
}

func TestANoteFollowsItsLineThroughAnEdit(t *testing.T) {
	root := newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "2", "--summary", "about two")
	rewrite(t, root, "src/app.ts", "zero\nhalf\none\ntwo\nthree\n")

	if got := lineOf(t, "about two"); got != 4 {
		t.Fatalf("the note did not follow its line: expected 4, got %d", got)
	}
}

func TestANoteStaysPutWhenItsLineIsNotUnique(t *testing.T) {
	root := newRepo(t)
	rewrite(t, root, "src/app.ts", "end\nend\nend\n")
	mustAdd(t, "--file", "src/app.ts", "--line", "2", "--summary", "the middle end")
	rewrite(t, root, "src/app.ts", "added\nend\nend\nend\n")

	if got := lineOf(t, "the middle end"); got != 2 {
		t.Fatalf("an ambiguous anchor moved the note to %d", got)
	}
}

func TestAnAnchoredNoteIsNotRenumberedInTheRecord(t *testing.T) {
	root := newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "2", "--summary", "about two")
	rewrite(t, root, "src/app.ts", "zero\nhalf\none\ntwo\nthree\n")
	if got := lineOf(t, "about two"); got != 4 {
		t.Fatalf("expected the reader to see line 4, got %d", got)
	}

	body, err := os.ReadFile(storePath(t))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(body), `"line": 2`) {
		t.Fatalf("the record was renumbered rather than re-anchored on read:\n%s", body)
	}
}

func TestAnswerMarksTheQuestionAndFilesTheReply(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "2", "--summary", "why this here", "--origin", "user")
	asked := notes(t)[0]
	id, _ := asked["id"].(string)
	if id == "" {
		t.Fatal("a note was written with no id")
	}
	if asked["state"] != "open" {
		t.Fatalf("a note the owner wrote is not open: %v", asked["state"])
	}

	if code, _ := run(t, "answer", "--id", id, "--summary", "it pins the old rev", "--author", "claude"); code != 0 {
		t.Fatal("answer exited non-zero")
	}

	got := notes(t)
	if len(got) != 2 {
		t.Fatalf("expected the question and its reply, got %d note(s)", len(got))
	}
	if got[0]["state"] != "answered" {
		t.Fatalf("the question is still %v", got[0]["state"])
	}
	if got[1]["reply_to"] != id || got[1]["line"] != got[0]["line"] {
		t.Fatalf("the reply does not sit on the question: %v", got[1])
	}
	if len(openNotes(t)) != 0 {
		t.Fatal("an answered question is still listed as open")
	}
}

func TestAnswerRefusesAnIDTheRecordDoesNotHold(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "seed", "--origin", "user")
	if code, _ := run(t, "answer", "--id", "deadbeef", "--summary", "into the void"); code == 0 {
		t.Fatal("answer accepted an id no note carries")
	}
	if got := len(notes(t)); got != 1 {
		t.Fatalf("the refused answer wrote a note anyway: %d", got)
	}
}

func TestClearByIDRemovesExactlyOneNote(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "first")
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "second")
	id, _ := notes(t)[0]["id"].(string)

	if code, _ := run(t, "clear", "--id", id); code != 0 {
		t.Fatal("clear --id exited non-zero")
	}
	got := notes(t)
	if len(got) != 1 || got[0]["summary"] != "second" {
		t.Fatalf("clear --id removed the wrong note: %v", got)
	}
}

func TestZeroByteStoreIsNotAbsorbing(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "seed")
	path := storePath(t)

	if err := os.Truncate(path, 0); err != nil {
		t.Fatal(err)
	}
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "after truncation")

	info, err := os.Stat(path)
	if err != nil || info.Size() == 0 {
		t.Fatal("a zero-byte store stayed zero bytes after a write")
	}
	if got := len(notes(t)); got != 1 {
		t.Fatalf("expected 1 note after writing through truncation, got %d", got)
	}
}

func TestMalformedStoreIsRefusedNotOverwritten(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "seed")
	path := storePath(t)
	if err := os.WriteFile(path, []byte("not json"), 0o644); err != nil {
		t.Fatal(err)
	}
	if code, _ := run(t, "add", "--file", "src/app.ts", "--line", "1", "--summary", "x"); code == 0 {
		t.Fatal("add overwrote a corrupt store instead of refusing")
	}
	got, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != "not json" {
		t.Fatal("a corrupt store was modified; it must be left for the owner to move aside")
	}
}

func TestFailedProducerDoesNotPublish(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "seed")
	path := storePath(t)
	root, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	scalar := `{"version":1,"repo":"` + root + `","notes":[5]}`
	if err := os.WriteFile(path, []byte(scalar), 0o644); err != nil {
		t.Fatal(err)
	}
	if code, _ := run(t, "clear", "--file", "src/app.ts"); code == 0 {
		t.Fatal("clear reported success while it could not read a note")
	}
	got, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != scalar {
		t.Fatalf("a failed producer replaced the store; got %s", got)
	}
}

func TestSymlinkedStoreIsRefused(t *testing.T) {
	root := newRepo(t)
	path := storePath(t)
	target := filepath.Join(root, "real-notes.json")
	if err := os.WriteFile(target, []byte(`{"version":1,"repo":"x","notes":[]}`), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(target, path); err != nil {
		t.Fatal(err)
	}
	if code, _ := run(t, "add", "--file", "src/app.ts", "--line", "1", "--summary", "x"); code == 0 {
		t.Fatal("add wrote through a symlinked store")
	}
	info, err := os.Lstat(path)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode()&os.ModeSymlink == 0 {
		t.Fatal("the symlink was replaced by a regular file")
	}
}

func TestWriteIsRefusedWhileTheLockIsHeld(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "seed")
	path := storePath(t)
	if err := os.Mkdir(path+".lock", 0o755); err != nil {
		t.Fatal(err)
	}
	defer os.Remove(path + ".lock")
	if code, _ := run(t, "add", "--file", "src/app.ts", "--line", "2", "--summary", "should not land"); code == 0 {
		t.Fatal("add wrote while the store lock was held")
	}
	if got := len(notes(t)); got != 1 {
		t.Fatalf("expected the store untouched under a held lock, got %d notes", got)
	}
}

func TestLockIsReleasedAfterEveryWrite(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "one")
	path := storePath(t)
	if _, err := os.Stat(path + ".lock"); err == nil {
		t.Fatal("the lock survived a successful write")
	}
	run(t, "add", "--file", "../outside.txt", "--line", "1", "--summary", "x")
	if _, err := os.Stat(path + ".lock"); err == nil {
		t.Fatal("the lock survived a refused write")
	}
	mustAdd(t, "--file", "src/app.ts", "--line", "2", "--summary", "two")
}

func TestRelativePathResolvesThroughASymlinkedCwd(t *testing.T) {
	root := newRepo(t)
	link := filepath.Join(filepath.Dir(root), "link")
	if err := os.Symlink(root, link); err != nil {
		t.Skipf("cannot create the symlink: %v", err)
	}
	t.Chdir(link)
	if code, _ := run(t, "add", "--file", "src/app.ts", "--line", "2", "--summary", "via symlink"); code != 0 {
		t.Fatal("a relative --file failed when reached through a symlinked path")
	}
}

func TestClearOnARepositoryWithNoStoreSucceeds(t *testing.T) {
	newRepo(t)
	if code, _ := run(t, "clear", "--yes"); code != 0 {
		t.Fatal("clear --yes on a repository with no store exited non-zero")
	}
	if code, _ := run(t, "clear", "--file", "src/app.ts"); code != 0 {
		t.Fatal("clear --file on a repository with no store exited non-zero")
	}
}

func TestClearEveryNoteNeedsYes(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "x")
	if code, _ := run(t, "clear"); code == 0 {
		t.Fatal("clear without --yes wiped the store")
	}
	if got := len(notes(t)); got != 1 {
		t.Fatalf("expected the note to survive, got %d", got)
	}
}

func TestClearYesSucceedsOnAHandAuthoredStore(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "seed")
	path := storePath(t)
	root, _ := os.Getwd()
	hand := `{"version":1,"repo":"` + root + `","notes":[
	  {"file":"src/app.ts","line":2,"summary":"valid","author":"pi"},
	  {"file":"src/app.ts","line":2,"author":"pi"},
	  {"file":"src/app.ts","line":2.5,"summary":"non-integral","author":"pi"}
	]}`
	if err := os.WriteFile(path, []byte(hand), 0o644); err != nil {
		t.Fatal(err)
	}
	if code, _ := run(t, "clear", "--yes"); code != 0 {
		t.Fatal("clear --yes failed on a hand-authored store")
	}
	if got := len(notes(t)); got != 0 {
		t.Fatalf("expected an empty store, got %d notes", got)
	}
}

func TestListJSONCarriesTheSameKeysWithNoStore(t *testing.T) {
	newRepo(t)
	code, out := run(t, "list", "--json")
	if code != 0 {
		t.Fatalf("list --json exited %d", code)
	}
	var doc map[string]any
	if err := json.Unmarshal([]byte(out), &doc); err != nil {
		t.Fatalf("not valid JSON: %v", err)
	}
	for _, key := range []string{"version", "notes"} {
		if _, ok := doc[key]; !ok {
			t.Errorf("list --json on an absent store is missing %q", key)
		}
	}
}

func TestListFiltersByFile(t *testing.T) {
	root := newRepo(t)
	if err := os.WriteFile(filepath.Join(root, "README.md"), []byte("root\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "a")
	mustAdd(t, "--file", "README.md", "--line", "1", "--summary", "b")

	code, out := run(t, "list", "--file", "README.md", "--json")
	if code != 0 {
		t.Fatalf("list --file exited %d", code)
	}
	var doc struct {
		Notes []map[string]any `json:"notes"`
	}
	if err := json.Unmarshal([]byte(out), &doc); err != nil {
		t.Fatal(err)
	}
	if len(doc.Notes) != 1 || doc.Notes[0]["file"] != filepath.Join(root, "README.md") {
		t.Fatalf("expected only the README note, got %v", doc.Notes)
	}
}

func TestListTextEmitsNoControlBytes(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "ok\x1b[2Jcleared\rhidden")
	_, out := run(t, "list")
	for _, r := range strings.TrimSuffix(out, "\n") {
		if r < 0x20 || r == 0x7f {
			t.Fatalf("list emitted a control byte: %q", out)
		}
	}
}

func TestConcurrentAddsLoseNoNote(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "seed")

	const writers = 8
	var wg sync.WaitGroup
	for i := 0; i < writers; i++ {
		wg.Add(1)
		go func(n int) {
			defer wg.Done()
			cmdAdd([]string{
				"--file", "src/app.ts",
				"--line", "2",
				"--summary", "concurrent " + strconv.Itoa(n),
			})
		}(i)
	}
	wg.Wait()

	if got := len(notes(t)); got != writers+1 {
		t.Fatalf("expected %d notes after %d concurrent writers, got %d", writers+1, writers, got)
	}
}

func TestUnknownSubcommandFails(t *testing.T) {
	newRepo(t)
	if code, _ := run(t, "nope"); code == 0 {
		t.Fatal("an unknown subcommand exited zero")
	}
	if code, _ := run(t, "add", "--nope", "x"); code == 0 {
		t.Fatal("an unknown add argument exited zero")
	}
}

// The reason the record is keyed by absolute path: work spanning several
// repositories has to read back as one list, from anywhere, including from a
// directory that is not a repository at all.
func TestNotesSpanRepositories(t *testing.T) {
	first := newRepo(t)
	state := os.Getenv("XDG_STATE_HOME")
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "in the first repo")

	second := t.TempDir()
	resolved, err := filepath.EvalSymlinks(second)
	if err != nil {
		t.Fatal(err)
	}
	cmd := exec.Command("git", "init", "--quiet", "-b", "main")
	cmd.Dir = resolved
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("git init: %v: %s", err, out)
	}
	if err := os.WriteFile(filepath.Join(resolved, "other.go"), []byte("alpha\nbeta\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	// Same record, because the state home is what locates it, not the repository.
	t.Setenv("XDG_STATE_HOME", state)
	t.Chdir(resolved)
	mustAdd(t, "--file", "other.go", "--line", "2", "--summary", "in the second repo")

	found := notes(t)
	if len(found) != 2 {
		t.Fatalf("expected both repositories' notes, got %d", len(found))
	}
	want := map[string]bool{
		filepath.Join(first, "src", "app.ts"): false,
		filepath.Join(resolved, "other.go"):   false,
	}
	for _, note := range found {
		path, _ := note["file"].(string)
		if _, ok := want[path]; !ok {
			t.Fatalf("a note names %q, which is neither repository", path)
		}
		want[path] = true
	}
	for path, seen := range want {
		if !seen {
			t.Errorf("no note came back for %s", path)
		}
	}

	// And from a directory that is not a repository, where the old per-repo
	// record could not even be located.
	t.Chdir(t.TempDir())
	if len(notes(t)) != 2 {
		t.Error("listing from outside any repository lost notes")
	}
}
