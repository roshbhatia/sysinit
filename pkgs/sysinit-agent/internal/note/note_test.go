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

// newRepo builds a real git working tree and points the store at a private
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

// run executes a subcommand and returns its exit code and stdout.
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

func mustAdd(t *testing.T, args ...string) {
	t.Helper()
	if code, _ := run(t, append([]string{"add"}, args...)...); code != 0 {
		t.Fatalf("add %v exited %d", args, code)
	}
}

func apply(t *testing.T, payload string) int {
	t.Helper()
	old := os.Stdout
	r, w, _ := os.Pipe()
	os.Stdout = w
	code := cmdApplyCode(strings.NewReader(payload))
	w.Close()
	io := make([]byte, 4096)
	r.Read(io)
	os.Stdout = old
	return code
}

func cmdApplyCode(stdin *strings.Reader) int {
	if err := cmdApply([]string{"--stdin"}, stdin); err != nil {
		return 1
	}
	return 0
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

func TestAddRejectsPathOutsideTheRepoRoot(t *testing.T) {
	newRepo(t)
	for _, file := range []string{"../outside.txt", "/etc/hosts", ".", "../"} {
		if code, _ := run(t, "add", "--file", file, "--line", "1", "--summary", "x"); code == 0 {
			t.Errorf("add accepted --file %q", file)
		}
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

func TestApplyAcceptsBothPayloadShapes(t *testing.T) {
	newRepo(t)
	if code := apply(t, `{"comments":[{"filePath":"src/app.ts","newLine":2,"summary":"hunk shape"}]}`); code != 0 {
		t.Fatal("apply rejected the hunk payload shape")
	}
	if code := apply(t, `{"notes":[{"file":"src/app.ts","line":1,"summary":"native shape"}]}`); code != 0 {
		t.Fatal("apply rejected the native payload shape")
	}
	if got := len(notes(t)); got != 2 {
		t.Fatalf("expected 2 notes after both shapes, got %d", got)
	}
}

func TestApplyRejectionsLeaveTheStoreByteIdentical(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "seed")
	path := storePath(t)

	cases := map[string]string{
		"path escaping with ..":       `{"comments":[{"filePath":"../outside.txt","newLine":1,"summary":"escape"}]}`,
		"absolute path outside":       `{"comments":[{"filePath":"/etc/hosts","newLine":1,"summary":"outside"}]}`,
		"non-integral line":           `{"notes":[{"file":"src/app.ts","line":2.5,"summary":"float"}]}`,
		"line below one":              `{"notes":[{"file":"src/app.ts","line":0,"summary":"zero"}]}`,
		"missing summary":             `{"comments":[{"filePath":"src/app.ts","newLine":1}]}`,
		"oldLine only":                `{"comments":[{"filePath":"src/app.ts","oldLine":3,"summary":"removed"}]}`,
		"one good beside one bad":     `{"comments":[{"filePath":"src/app.ts","newLine":1,"summary":"ok"},{"filePath":"../out.txt","newLine":1,"summary":"bad"}]}`,
		"control byte in filePath":    `{"comments":[{"filePath":"src/[2Jhax.ts","newLine":1,"summary":"x"}]}`,
		"carriage return in filePath": `{"comments":[{"filePath":"src/app.ts\rsrc/other.ts:9  approved","newLine":1,"summary":"x"}]}`,
		"non-string author":           `{"notes":[{"file":"src/app.ts","line":1,"summary":"s","author":{"nested":true}}]}`,
		"numeric rationale":           `{"notes":[{"file":"src/app.ts","line":1,"summary":"s","rationale":123}]}`,
		"empty batch":                 `{"notes":[]}`,
		"not JSON at all":             `not json`,
	}
	for label, payload := range cases {
		before, err := os.ReadFile(path)
		if err != nil {
			t.Fatal(err)
		}
		if code := apply(t, payload); code == 0 {
			t.Errorf("apply accepted a batch it must reject: %s", label)
		}
		after, err := os.ReadFile(path)
		if err != nil {
			t.Fatal(err)
		}
		if string(before) != string(after) {
			t.Errorf("a rejected batch mutated the store (%s)", label)
		}
	}
}

func TestApplyRejectionDoesNotCreateAStore(t *testing.T) {
	newRepo(t)
	path := storePath(t)
	if code := apply(t, `{"comments":[{"filePath":"../out.txt","newLine":1,"summary":"bad"}]}`); code == 0 {
		t.Fatal("apply accepted an escaping path")
	}
	if _, err := os.Stat(path); err == nil {
		t.Fatalf("a rejected batch created a store at %s", path)
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
	for _, key := range []string{"version", "repo", "notes"} {
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
	if len(doc.Notes) != 1 || doc.Notes[0]["file"] != "README.md" {
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
