package note

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"testing"
)

// autoHook runs `note auto` against payload and returns its code and stdout.
func autoHook(t *testing.T, payload string, args ...string) (int, string) {
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
	code := autoRun(args, strings.NewReader(payload))
	w.Close()
	wg.Wait()
	os.Stdout = old
	return code, out.String()
}

// transcript writes a harness transcript holding one narrated tool call.
func transcript(t *testing.T, dir, text, file string) string {
	t.Helper()
	rows := []map[string]any{
		{"type": "user", "message": map[string]any{"content": "fix it"}},
		{"type": "assistant", "message": map[string]any{"content": []map[string]any{
			{"type": "text", "text": text},
			{"type": "tool_use", "name": "Edit", "input": map[string]any{"file_path": file}},
		}}},
	}
	var body strings.Builder
	for _, row := range rows {
		encoded, err := json.Marshal(row)
		if err != nil {
			t.Fatal(err)
		}
		body.Write(append(encoded, '\n'))
	}
	path := filepath.Join(dir, "transcript.jsonl")
	if err := os.WriteFile(path, []byte(body.String()), 0o600); err != nil {
		t.Fatal(err)
	}
	return path
}

// payload builds a PostToolUse payload. A nil patch stands for a harness that
// reports none.
func payload(t *testing.T, cwd, transcriptPath, file string, patch []map[string]any, input map[string]any) string {
	t.Helper()
	if input == nil {
		input = map[string]any{}
	}
	input["file_path"] = file
	event := map[string]any{
		"cwd":             cwd,
		"transcript_path": transcriptPath,
		"tool_name":       "Edit",
		"tool_input":      input,
	}
	if patch != nil {
		event["tool_response"] = map[string]any{"structuredPatch": patch}
	} else {
		event["tool_response"] = "ok"
	}
	encoded, err := json.Marshal(event)
	if err != nil {
		t.Fatal(err)
	}
	return string(encoded)
}

func TestAutoFilesTheNarrationAsANote(t *testing.T) {
	root := newRepo(t)
	file := filepath.Join(root, "src", "app.ts")
	tx := transcript(t, root, "Moved the guard above the read. The value was read before the check ran.\n\nNothing else changed.", file)

	code, out := autoHook(t, payload(t, root, tx, file, []map[string]any{{"newStart": 2, "newLines": 1}}, nil), "claude")
	if code != 0 {
		t.Fatalf("auto exited %d", code)
	}
	if out != "" {
		t.Fatalf("auto printed on stdout: %q", out)
	}

	stored := notes(t)
	if len(stored) != 1 {
		t.Fatalf("want 1 note, got %d", len(stored))
	}
	got := stored[0]
	if got["file"] != "src/app.ts" {
		t.Errorf("file = %v", got["file"])
	}
	if got["line"] != float64(2) {
		t.Errorf("line = %v, want the patch's newStart", got["line"])
	}
	if got["summary"] != "Moved the guard above the read." {
		t.Errorf("summary = %v, want the first sentence", got["summary"])
	}
	if !strings.HasPrefix(got["rationale"].(string), "The value was read") {
		t.Errorf("rationale = %v, want the rest of the narration", got["rationale"])
	}
	// The author says the note was derived rather than written, because a reader
	// weighs the two differently.
	if got["author"] != "claude (auto)" {
		t.Errorf("author = %v", got["author"])
	}
}

func TestAutoWritesNothingWithoutNarration(t *testing.T) {
	root := newRepo(t)
	file := filepath.Join(root, "src", "app.ts")
	empty := filepath.Join(root, "empty.jsonl")
	if err := os.WriteFile(empty, nil, 0o600); err != nil {
		t.Fatal(err)
	}

	code, _ := autoHook(t, payload(t, root, empty, file, nil, nil), "claude")
	if code != 0 {
		t.Fatalf("auto exited %d", code)
	}
	if stored := notes(t); len(stored) != 0 {
		t.Fatalf("want no notes, got %v", stored)
	}
}

func TestAutoNeverFailsTheHook(t *testing.T) {
	newRepo(t)
	for name, args := range map[string][]string{
		"no harness":      {},
		"unknown flag":    {"claude", "--wat"},
		"harness with /":  {"a/b"},
		"garbage payload": {"claude"},
	} {
		code, out := autoHook(t, "not json at all", args...)
		if code != 0 {
			t.Errorf("%s: exited %d, want 0", name, code)
		}
		if out != "" {
			t.Errorf("%s: printed %q, want nothing", name, out)
		}
	}
}

func TestAutoAnchorsOnTheFileWhenNoPatchIsReported(t *testing.T) {
	root := newRepo(t)
	file := filepath.Join(root, "src", "app.ts")
	tx := transcript(t, root, "Rewrote the middle line.", file)

	// `two` is line 2 of the fixture, and the harness reports no patch, so the
	// only anchor left is where the replacement text now sits.
	code, _ := autoHook(t, payload(t, root, tx, file, nil, map[string]any{"new_string": "two"}), "claude")
	if code != 0 {
		t.Fatalf("auto exited %d", code)
	}
	stored := notes(t)
	if len(stored) != 1 {
		t.Fatalf("want 1 note, got %d", len(stored))
	}
	if stored[0]["line"] != float64(2) {
		t.Errorf("line = %v, want 2", stored[0]["line"])
	}
}

func TestAutoReplacesOnlyInsideTheRegionItRewrote(t *testing.T) {
	root := newRepo(t)
	file := filepath.Join(root, "src", "app.ts")
	tx := transcript(t, root, "Touched it again.", file)
	same := payload(t, root, tx, file, []map[string]any{{"newStart": 2, "newLines": 2}}, nil)
	far := payload(t, root, tx, file, []map[string]any{{"newStart": 40, "newLines": 1}}, nil)

	for _, event := range []string{same, same, far} {
		if code, _ := autoHook(t, event, "claude"); code != 0 {
			t.Fatalf("auto exited %d", code)
		}
	}

	stored := notes(t)
	if len(stored) != 2 {
		t.Fatalf("want 2 notes (one per region), got %d: %v", len(stored), stored)
	}
	lines := map[float64]bool{}
	for _, note := range stored {
		lines[note["line"].(float64)] = true
	}
	if !lines[2] || !lines[40] {
		t.Errorf("want notes at 2 and 40, got %v", lines)
	}
}

func TestAutoFilesAgainstTheRepositoryHoldingTheFile(t *testing.T) {
	root := newRepo(t)
	nested := filepath.Join(root, "vendor", "inner")
	if err := os.MkdirAll(nested, 0o755); err != nil {
		t.Fatal(err)
	}
	for _, args := range [][]string{{"init", "--quiet", "-b", "main"}} {
		cmd := exec.Command("git", args...)
		cmd.Dir = nested
		if out, err := cmd.CombinedOutput(); err != nil {
			t.Fatalf("git %v: %v: %s", args, err, out)
		}
	}
	file := filepath.Join(nested, "inner.txt")
	if err := os.WriteFile(file, []byte("a\nb\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	tx := transcript(t, root, "Bumped the inner file.", file)

	// The hook's working directory is the outer repository, which is what an agent
	// started at a workspace root reports for every edit under it.
	code, _ := autoHook(t, payload(t, root, tx, file, []map[string]any{{"newStart": 1, "newLines": 1}}, nil), "claude")
	if code != 0 {
		t.Fatalf("auto exited %d", code)
	}
	if outer := notes(t); len(outer) != 0 {
		t.Fatalf("the outer store took the note: %v", outer)
	}
	t.Chdir(nested)
	inner := notes(t)
	if len(inner) != 1 || inner[0]["file"] != "inner.txt" {
		t.Fatalf("the inner store did not take the note: %v", inner)
	}
}

func TestSplitSeparatesTheClaimFromTheReason(t *testing.T) {
	cases := []struct {
		name      string
		text      string
		summary   string
		rationale string
	}{
		{
			name:    "one sentence carries no rationale",
			text:    "Dropped the retry.",
			summary: "Dropped the retry.",
		},
		{
			name:      "the rest becomes the rationale",
			text:      "Dropped the retry. It masked the timeout.",
			summary:   "Dropped the retry.",
			rationale: "It masked the timeout.",
		},
		{
			name:    "a period inside a name does not split",
			text:    "Renamed app.ts to main.ts",
			summary: "Renamed app.ts to main.ts",
		},
		{
			name:      "markdown decoration is removed",
			text:      "**Fixed** the `guard`. Here is why:\n```go\nif x != nil {\n```\nIt was nil.",
			summary:   "Fixed the guard.",
			rationale: "Here is why:\nIt was nil.",
		},
		{
			name:    "a list marker is removed",
			text:    "- Added the flag.",
			summary: "Added the flag.",
		},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			summary, rationale := split(c.text)
			if summary != c.summary {
				t.Errorf("summary = %q, want %q", summary, c.summary)
			}
			if rationale != c.rationale {
				t.Errorf("rationale = %q, want %q", rationale, c.rationale)
			}
		})
	}
}

func TestSplitBoundsWhatItWrites(t *testing.T) {
	long := strings.Repeat("word ", 200)
	summary, rationale := split(long + ". " + long)
	if len([]rune(summary)) > maxSummary+1 {
		t.Errorf("summary is %d runes, want at most %d plus the mark", len([]rune(summary)), maxSummary)
	}
	if !strings.HasSuffix(summary, "…") {
		t.Errorf("a clipped summary does not say it was clipped: %q", summary)
	}
	if len([]rune(rationale)) > maxRationale+1 {
		t.Errorf("rationale is %d runes, want at most %d plus the mark", len([]rune(rationale)), maxRationale)
	}
}

func TestNarrationWalksBackToTheNearestText(t *testing.T) {
	dir := t.TempDir()
	file := filepath.Join(dir, "a.txt")
	rows := []string{
		`{"type":"assistant","message":{"content":[{"type":"text","text":"Here is the plan."}]}}`,
		`{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Read","input":{"file_path":"` + file + `"}}]}}`,
		`{"type":"user","message":{"content":"[tool result]"}}`,
		`{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{"file_path":"` + file + `"}}]}}`,
	}
	path := filepath.Join(dir, "t.jsonl")
	if err := os.WriteFile(path, []byte(strings.Join(rows, "\n")+"\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	// The Edit call carries no text of its own, and the text two messages earlier
	// is the narration for the whole sequence.
	if got := narration(path, "Edit", file); got != "Here is the plan." {
		t.Errorf("narration = %q", got)
	}
}
