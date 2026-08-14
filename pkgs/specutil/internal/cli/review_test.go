package cli_test

import (
	"bytes"
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/roshbhatia/specutil/internal/cli"
)

func runStdin(stdin string, args ...string) (stdout, stderr string, err error) {
	var outBuf, errBuf bytes.Buffer
	root := cli.NewRootCmd()
	root.SetOut(&outBuf)
	root.SetErr(&errBuf)
	root.SetIn(strings.NewReader(stdin))
	root.SetArgs(args)
	err = root.Execute()
	return outBuf.String(), errBuf.String(), err
}

func taskIdentity(t *testing.T, repo, changeName, taskText string) string {
	t.Helper()
	out, _, err := run("-C", repo, "graph", "--as", "detail")
	if err != nil {
		t.Fatalf("graph --as detail: %v", err)
	}
	var feed struct {
		Changes []struct {
			Name   string `json:"name"`
			Phases []struct {
				Items []struct {
					Text     string `json:"text"`
					Identity string `json:"identity"`
					Drift    string `json:"drift"`
				} `json:"items"`
			} `json:"phases"`
		} `json:"changes"`
	}
	if err := json.Unmarshal([]byte(out), &feed); err != nil {
		t.Fatalf("parsing detail feed: %v", err)
	}
	for _, c := range feed.Changes {
		if c.Name != changeName {
			continue
		}
		for _, p := range c.Phases {
			for _, it := range p.Items {
				if strings.Contains(it.Text, taskText) {
					return it.Identity
				}
			}
		}
	}
	t.Fatalf("no task containing %q in change %q", taskText, changeName)
	return ""
}

func TestReviewShowOnAnUnreviewedChange(t *testing.T) {
	dir := setupMinimalOpenspec(t, "fresh")
	out, _, err := run("-C", dir, "review", "show", "fresh")
	if err != nil {
		t.Fatalf("review show must not fail on an unreviewed change: %v", err)
	}
	if !strings.Contains(out, "has not been reviewed") {
		t.Errorf("expected an unreviewed report, got: %s", out)
	}
}

func TestReviewIngestWritesTheRecordAndPrintsTheBrief(t *testing.T) {
	dir := setupMinimalOpenspec(t, "widget")
	id := taskIdentity(t, dir, "widget", "Do the thing")

	feedback := `{
	  "schema": "specutil.review/v1",
	  "change": "widget",
	  "decision": "changes-requested",
	  "note": "narrow the scope",
	  "annotations": [
	    {"scope":"task","phase":"Build","identity":"` + id + `","action":"drop","comment":"out of scope"}
	  ]
	}`

	out, stderr, err := runStdin(feedback, "-C", dir, "review", "ingest")
	if err != nil {
		t.Fatalf("review ingest: %v (stderr: %s)", err, stderr)
	}
	if !strings.Contains(out, "Decision: changes-requested") {
		t.Errorf("brief missing the decision: %s", out)
	}
	if !strings.Contains(out, "Requested removals") || !strings.Contains(out, "out of scope") {
		t.Errorf("brief missing the removal request: %s", out)
	}

	path := filepath.Join(dir, "openspec", "changes", "widget", "specutil.review.yaml")
	b, rerr := os.ReadFile(path)
	if rerr != nil {
		t.Fatalf("reading the record: %v", rerr)
	}
	if !strings.Contains(string(b), "decision: changes-requested") {
		t.Errorf("record missing the decision:\n%s", b)
	}
}

func TestReviewIngestDryRunWritesNothing(t *testing.T) {
	dir := setupMinimalOpenspec(t, "widget")
	feedback := `{"schema":"specutil.review/v1","change":"widget","decision":"approved","annotations":[]}`

	if _, _, err := runStdin(feedback, "-C", dir, "review", "ingest", "--dry-run"); err != nil {
		t.Fatalf("review ingest --dry-run: %v", err)
	}
	path := filepath.Join(dir, "openspec", "changes", "widget", "specutil.review.yaml")
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Fatalf("--dry-run must write no record, but %s exists", path)
	}
}

func TestReviewIngestRejectsAnUnknownSchema(t *testing.T) {
	dir := setupMinimalOpenspec(t, "widget")
	_, _, err := runStdin(`{"schema":"plannotator/v9","change":"widget","decision":"approved"}`,
		"-C", dir, "review", "ingest")
	if err == nil {
		t.Fatal("an unknown feedback schema must be rejected, not guessed at")
	}
	if !strings.Contains(err.Error(), "schema") {
		t.Errorf("the error should name the schema: %v", err)
	}
}

func TestReviewSetThenDriftAppearsInTheDetailFeed(t *testing.T) {
	dir := setupMinimalOpenspec(t, "widget")
	if _, _, err := run("-C", dir, "review", "set", "widget", "--decision", "approved"); err != nil {
		t.Fatalf("review set: %v", err)
	}

	out, _, err := run("-C", dir, "graph", "--as", "detail")
	if err != nil {
		t.Fatalf("graph --as detail: %v", err)
	}
	if !strings.Contains(out, `"drift": "unchanged"`) {
		t.Errorf("a just-reviewed change must report unchanged tasks: %s", out)
	}

	tasks := filepath.Join(dir, "openspec", "changes", "widget", "tasks.md")
	if werr := os.WriteFile(tasks,
		[]byte("## 1. Build\n\n- [ ] 1.1 Do the thing\n- [ ] 1.2 Do a second unrelated thing\n"), 0o644); werr != nil {
		t.Fatalf("rewriting tasks.md: %v", werr)
	}
	out, _, err = run("-C", dir, "graph", "--as", "detail")
	if err != nil {
		t.Fatalf("graph --as detail: %v", err)
	}
	if !strings.Contains(out, `"drift": "new"`) {
		t.Errorf("an added task must report as new: %s", out)
	}

	out, _, err = run("-C", dir, "review", "show", "widget")
	if err != nil {
		t.Fatalf("review show: %v", err)
	}
	if !strings.Contains(out, "stale") {
		t.Errorf("editing after a decision must report the decision stale: %s", out)
	}
}

func TestReviewSetRejectsAnUnknownDecision(t *testing.T) {
	dir := setupMinimalOpenspec(t, "widget")
	if _, _, err := run("-C", dir, "review", "set", "widget", "--decision", "lgtm"); err == nil {
		t.Fatal("an unknown decision must be rejected")
	}
}

func TestReviewSetKeepsCommentsUnlessCleared(t *testing.T) {
	dir := setupMinimalOpenspec(t, "widget")
	id := taskIdentity(t, dir, "widget", "Do the thing")
	feedback := `{"schema":"specutil.review/v1","change":"widget","decision":"changes-requested",
	  "annotations":[{"scope":"task","phase":"Build","identity":"` + id + `","comment":"say which thing"}]}`
	if _, _, err := runStdin(feedback, "-C", dir, "review", "ingest"); err != nil {
		t.Fatalf("review ingest: %v", err)
	}

	out, _, err := run("-C", dir, "review", "set", "widget", "--decision", "approved")
	if err != nil {
		t.Fatalf("review set: %v", err)
	}
	if !strings.Contains(out, "say which thing") {
		t.Errorf("approving must not erase what the reviewer said: %s", out)
	}

	out, _, err = run("-C", dir, "review", "set", "widget", "--decision", "approved", "--clear-comments")
	if err != nil {
		t.Fatalf("review set --clear-comments: %v", err)
	}
	if strings.Contains(out, "say which thing") {
		t.Errorf("--clear-comments must drop the comments: %s", out)
	}
}

func TestReviewShowJSON(t *testing.T) {
	dir := setupMinimalOpenspec(t, "widget")
	if _, _, err := run("-C", dir, "review", "set", "widget", "--decision", "approved"); err != nil {
		t.Fatalf("review set: %v", err)
	}
	out, _, err := run("-C", dir, "review", "show", "--as", "json")
	if err != nil {
		t.Fatalf("review show --as json: %v", err)
	}
	var statuses []struct {
		Change   string `json:"change"`
		Reviewed bool   `json:"reviewed"`
		Decision string `json:"decision"`
		Stale    bool   `json:"stale"`
	}
	if jerr := json.Unmarshal([]byte(out), &statuses); jerr != nil {
		t.Fatalf("parsing review show json: %v", jerr)
	}
	if len(statuses) != 1 || statuses[0].Decision != "approved" || statuses[0].Stale {
		t.Errorf("unexpected status: %+v", statuses)
	}
}

func gitInit(t *testing.T, dir string) {
	t.Helper()
	for _, args := range [][]string{
		{"init", "-q"},
		{"config", "user.email", "test@example.com"},
		{"config", "user.name", "Test"},
		{"add", "-A"},
		{"commit", "-qm", "initial"},
	} {
		cmd := exec.Command("git", append([]string{"-C", dir}, args...)...)
		cmd.Env = append(os.Environ(), "GIT_CONFIG_GLOBAL=/dev/null", "GIT_CONFIG_SYSTEM=/dev/null")
		if out, err := cmd.CombinedOutput(); err != nil {
			t.Skipf("git unavailable or unusable (%v): %s", err, out)
		}
	}
}

func TestReviewDiffShowsUncommittedWork(t *testing.T) {
	dir := setupMinimalOpenspec(t, "widget")
	gitInit(t, dir)

	tasks := filepath.Join(dir, "openspec", "changes", "widget", "tasks.md")
	if err := os.WriteFile(tasks, []byte("## 1. Build\n\n- [ ] 1.1 Do the thing differently\n"), 0o644); err != nil {
		t.Fatalf("rewriting tasks.md: %v", err)
	}

	out, _, err := run("-C", dir, "review", "diff", "--as", "json")
	if err != nil {
		t.Fatalf("review diff: %v", err)
	}
	var d struct {
		Base  string `json:"base"`
		Files []struct {
			Path  string `json:"path"`
			Hunks []struct {
				Identity string `json:"identity"`
			} `json:"hunks"`
		} `json:"files"`
	}
	if jerr := json.Unmarshal([]byte(out), &d); jerr != nil {
		t.Fatalf("parsing diff json: %v", jerr)
	}
	if len(d.Files) != 1 || !strings.HasSuffix(d.Files[0].Path, "tasks.md") {
		t.Fatalf("expected the edited tasks.md, got %+v", d.Files)
	}
	if len(d.Files[0].Hunks) == 0 || d.Files[0].Hunks[0].Identity == "" {
		t.Error("every hunk needs an identity; it is what an annotation names")
	}
}

func TestReviewDiffDefaultsToTheReviewedCommit(t *testing.T) {
	dir := setupMinimalOpenspec(t, "widget")
	gitInit(t, dir)

	if _, _, err := run("-C", dir, "review", "set", "widget", "--decision", "approved"); err != nil {
		t.Fatalf("review set: %v", err)
	}
	rec, err := os.ReadFile(filepath.Join(dir, "openspec", "changes", "widget", "specutil.review.yaml"))
	if err != nil {
		t.Fatalf("reading the record: %v", err)
	}
	if !strings.Contains(string(rec), "base_commit:") {
		t.Errorf("inside a git tree the record must pin the reviewed commit:\n%s", rec)
	}

	out, _, err := run("-C", dir, "review", "diff", "widget", "--as", "text")
	if err != nil {
		t.Fatalf("review diff: %v", err)
	}
	if !strings.Contains(out, "No changes against") {
		t.Errorf("nothing moved since the review, so the diff should be empty: %s", out)
	}
}

func TestReviewDiffHidesSpecutilsOwnState(t *testing.T) {
	dir := setupMinimalOpenspec(t, "widget")
	gitInit(t, dir)
	if _, _, err := run("-C", dir, "review", "set", "widget", "--decision", "approved"); err != nil {
		t.Fatalf("review set: %v", err)
	}
	out, _, err := run("-C", dir, "review", "diff", "widget", "--as", "text")
	if err != nil {
		t.Fatalf("review diff: %v", err)
	}
	if strings.Contains(out, "specutil.review.yaml") {
		t.Errorf("the review record must not appear in its own diff: %s", out)
	}
}

func TestReviewIngestRecordsHunkComments(t *testing.T) {
	dir := setupMinimalOpenspec(t, "widget")
	feedback := `{"schema":"specutil.review/v1","change":"widget","decision":"changes-requested",
	  "annotations":[{"scope":"hunk","file":"internal/auth/token.go","identity":"abc123",
	                  "text":"@@ -10,7 +10,9 @@","comment":"this needs a test"}]}`

	out, _, err := runStdin(feedback, "-C", dir, "review", "ingest")
	if err != nil {
		t.Fatalf("review ingest: %v", err)
	}
	if !strings.Contains(out, "Code comments") || !strings.Contains(out, "this needs a test") {
		t.Errorf("the brief must carry hunk comments: %s", out)
	}
	if !strings.Contains(out, "internal/auth/token.go") {
		t.Errorf("a code comment must name its file: %s", out)
	}
}

func TestReviewIngestRejectsAHunkAnnotationWithNoIdentity(t *testing.T) {
	dir := setupMinimalOpenspec(t, "widget")
	feedback := `{"schema":"specutil.review/v1","change":"widget","decision":"commented",
	  "annotations":[{"scope":"hunk","file":"x.go","comment":"hi"}]}`
	if _, _, err := runStdin(feedback, "-C", dir, "review", "ingest"); err == nil {
		t.Fatal("a hunk annotation with no identity must be rejected")
	}
}

func TestWebDiffNeedsAChangeWhenSeveralExist(t *testing.T) {
	_, _, err := run("-C", examplesDir(), "web", "--diff", "-o", "-", "--open=false")
	if err == nil {
		t.Fatal("--diff must not guess which change a diff belongs to")
	}
	if !strings.Contains(err.Error(), "--change") {
		t.Errorf("the error should say what to pass: %v", err)
	}
}

func TestWebDiffEmbedsTheDiffForAnnotation(t *testing.T) {
	dir := setupMinimalOpenspec(t, "widget")
	gitInit(t, dir)
	tasks := filepath.Join(dir, "openspec", "changes", "widget", "tasks.md")
	if err := os.WriteFile(tasks, []byte("## 1. Build\n\n- [ ] 1.1 Do the thing differently\n"), 0o644); err != nil {
		t.Fatalf("rewriting tasks.md: %v", err)
	}

	out, _, err := run("-C", dir, "web", "--diff", "--change", "widget", "-o", "-", "--open=false")
	if err != nil {
		t.Fatalf("web --diff: %v", err)
	}
	for _, want := range []string{`"diff"`, `"hunks"`, "diffSectionHTML", `scope: "hunk"`} {
		if !strings.Contains(out, want) {
			t.Errorf("the page must embed the diff for annotation; missing %q", want)
		}
	}
}

func TestWebPageCarriesTheAnnotationSurface(t *testing.T) {
	dir := setupMinimalOpenspec(t, "widget")
	out, _, err := run("-C", dir, "web", "-o", "-", "--open=false")
	if err != nil {
		t.Fatalf("web: %v", err)
	}
	for _, want := range []string{"specutil.review/v1", "ann-input", "specutil review ingest", "buildFeedback"} {
		if !strings.Contains(out, want) {
			t.Errorf("the page must carry the annotation surface; missing %q", want)
		}
	}
}
