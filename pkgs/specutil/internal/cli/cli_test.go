package cli_test

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"

	"github.com/roshbhatia/specutil/internal/cli"
)

// fixture resolves a repository under testdata/. The trees are real change
// artifacts rather than generated ones, so a parser regression shows up as a
// diff a reader can follow instead of as a mismatch against a builder.
func fixture(name string) string {
	_, file, _, _ := runtime.Caller(0)
	return filepath.Join(filepath.Dir(file), "testdata", name)
}

func examplesDir() string { return fixture("getting-started") }

func run(args ...string) (stdout, stderr string, err error) {
	var outBuf, errBuf bytes.Buffer
	root := cli.NewRootCmd()
	root.SetOut(&outBuf)
	root.SetErr(&errBuf)
	root.SetArgs(args)
	err = root.Execute()
	return outBuf.String(), errBuf.String(), err
}

func TestRenderRFC(t *testing.T) {
	out, _, err := run("-C", examplesDir(), "render", "--as", "rfc", "--change", "add-auth-layer")
	if err != nil {
		t.Fatalf("render rfc: %v", err)
	}
	for _, want := range []string{"Add auth layer", "JWT", "middleware"} {
		if !strings.Contains(out, want) {
			t.Errorf("render rfc output missing %q", want)
		}
	}
}

func TestRenderDesign(t *testing.T) {
	out, _, err := run("-C", examplesDir(), "render", "--as", "design", "--change", "add-auth-layer")
	if err != nil {
		t.Fatalf("render design: %v", err)
	}
	if !strings.Contains(out, "Add auth layer") {
		t.Error("render design output missing the reader-facing title")
	}
}

func TestRenderTickets(t *testing.T) {
	out, _, err := run("-C", examplesDir(), "render", "--as", "tickets", "--change", "add-auth-layer")
	if err != nil {
		t.Fatalf("render tickets: %v", err)
	}
	if !strings.Contains(out, "Add auth layer") {
		t.Error("render tickets output missing the reader-facing title")
	}
	// Tickets are what reaches a tracker, so the source numbering must be gone.
	for _, leak := range []string{"1.1 ", "## 1. ", "### 1.1"} {
		if strings.Contains(out, leak) {
			t.Errorf("render tickets leaked source numbering %q", leak)
		}
	}
}

func TestRenderMissingAs(t *testing.T) {
	_, _, err := run("-C", examplesDir(), "render", "--change", "add-auth-layer")
	if err == nil {
		t.Error("expected error when --as is missing")
	}
}

func TestRenderUnknownTarget(t *testing.T) {
	_, _, err := run("-C", examplesDir(), "render", "--as", "nonexistent", "--change", "add-auth-layer")
	if err == nil {
		t.Error("expected error for unknown render target")
	}
}

func TestGraphMermaid(t *testing.T) {
	out, _, err := run("-C", examplesDir(), "graph", "--as", "mermaid")
	if err != nil {
		t.Fatalf("graph mermaid: %v", err)
	}
	if !strings.Contains(out, "graph") {
		t.Error("graph mermaid output missing graph keyword")
	}
}

func TestGraphDot(t *testing.T) {
	out, _, err := run("-C", examplesDir(), "graph", "--as", "dot")
	if err != nil {
		t.Fatalf("graph dot: %v", err)
	}
	if !strings.Contains(out, "digraph") {
		t.Error("graph dot output missing digraph keyword")
	}
}

func TestRenderBMAD(t *testing.T) {
	dir := fixture("bmad-project")

	out, _, err := run("-C", dir, "--from", "bmad", "render", "--as", "rfc", "--change", "story-1.1")
	if err != nil {
		t.Fatalf("render bmad rfc: %v", err)
	}
	if !strings.Contains(out, "Story 1.1") {
		t.Error("render bmad output missing the reader-facing title")
	}
}

func TestRenderPlanMd(t *testing.T) {
	dir := fixture("plan-md")

	// Use -C to set the repo root so the plan provider auto-discovers plan.md.
	out, _, err := run("-C", dir, "--from", "plan", "render", "--as", "rfc")
	if err != nil {
		t.Fatalf("render plan.md rfc: %v", err)
	}
	if len(out) == 0 {
		t.Error("render plan.md produced empty output")
	}
}

// setupMinimalOpenspec creates a temp dir with a minimal openspec change and returns the root.
func setupMinimalOpenspec(t *testing.T, changeName string) string {
	t.Helper()
	dir := t.TempDir()
	changeDir := filepath.Join(dir, "openspec", "changes", changeName)
	if err := os.MkdirAll(changeDir, 0o755); err != nil {
		t.Fatalf("mkdir %s: %v", changeDir, err)
	}
	if err := os.WriteFile(filepath.Join(changeDir, "proposal.md"),
		[]byte("## Why\n\nTest change.\n\n## What Changes\n\n- Something.\n"), 0o644); err != nil {
		t.Fatalf("write proposal: %v", err)
	}
	if err := os.WriteFile(filepath.Join(changeDir, "tasks.md"),
		[]byte("## 1. Build\n\n- [ ] 1.1 Do the thing\n"), 0o644); err != nil {
		t.Fatalf("write tasks: %v", err)
	}
	return dir
}

// writeSchema declares the spec framework's schema so check and extract detect
// their presets without an explicit specutil.yaml block.
func writeSchema(t *testing.T, repo, schema string) {
	t.Helper()
	path := filepath.Join(repo, "openspec", "config.yaml")
	if err := os.WriteFile(path, []byte("schema: "+schema+"\n"), 0o644); err != nil {
		t.Fatalf("write config.yaml: %v", err)
	}
}

func TestCheckListRules(t *testing.T) {
	out, _, err := run("check", "--list-rules")
	if err != nil {
		t.Fatalf("check --list-rules: %v", err)
	}
	for _, want := range []string{"no-em-dash", "scenario-marker-coverage", "task-deps-resolve"} {
		if !strings.Contains(out, want) {
			t.Errorf("rule listing missing %q", want)
		}
	}
}

func TestCheckWithNoRubricIsANoOp(t *testing.T) {
	dir := setupMinimalOpenspec(t, "plain")
	_, stderr, err := run("-C", dir, "check")
	if err != nil {
		t.Fatalf("a repo with no rubric must not fail: %v", err)
	}
	if !strings.Contains(stderr, "no rubric declared") {
		t.Errorf("expected a note explaining nothing was checked, got %q", stderr)
	}
}

func TestCheckDetectsPresetFromSchemaAndFails(t *testing.T) {
	dir := setupMinimalOpenspec(t, "rough")
	writeSchema(t, dir, "spec-driven")

	out, _, err := run("-C", dir, "check")
	if err == nil {
		t.Fatal("expected a rubric violation for a change missing Non-goals and a shape")
	}
	if !cli.IsCheckFailed(err) {
		t.Fatalf("expected the check sentinel, got %v", err)
	}
	for _, want := range []string{"proposal-sections", "phase-marker-required", "check: failed"} {
		if !strings.Contains(out, want) {
			t.Errorf("findings missing %q; got:\n%s", want, out)
		}
	}
}

func TestCheckJSONOutput(t *testing.T) {
	dir := setupMinimalOpenspec(t, "rough")
	writeSchema(t, dir, "spec-driven")

	out, _, err := run("-C", dir, "check", "--as", "json")
	if err == nil || !cli.IsCheckFailed(err) {
		t.Fatalf("expected a rubric violation, got %v", err)
	}
	var report struct {
		Findings []struct {
			Rule     string `json:"rule"`
			Severity string `json:"severity"`
			Change   string `json:"change"`
			Msg      string `json:"msg"`
		} `json:"findings"`
		Checked []string `json:"checked"`
	}
	if jerr := json.Unmarshal([]byte(out), &report); jerr != nil {
		t.Fatalf("output is not valid JSON: %v\n%s", jerr, out)
	}
	if len(report.Findings) == 0 {
		t.Fatal("expected findings in the JSON report")
	}
	if len(report.Checked) != 1 || report.Checked[0] != "rough" {
		t.Errorf("checked = %v, want [rough]", report.Checked)
	}
	for _, f := range report.Findings {
		if f.Rule == "" || f.Severity == "" || f.Change == "" || f.Msg == "" {
			t.Errorf("finding is missing fields: %+v", f)
		}
	}
}

func TestCheckUnknownFormatIsAnError(t *testing.T) {
	dir := setupMinimalOpenspec(t, "rough")
	writeSchema(t, dir, "spec-driven")
	if _, _, err := run("-C", dir, "check", "--as", "xml"); err == nil {
		t.Error("expected an error naming the supported formats")
	}
}

// The verb accepts a change directory so it is a drop-in for a lint that took a
// path; the repository root and change name are derived from the layout.
func TestCheckAcceptsAChangeDirectory(t *testing.T) {
	dir := setupMinimalOpenspec(t, "rough")
	writeSchema(t, dir, "spec-driven")

	changeDir := filepath.Join(dir, "openspec", "changes", "rough")
	out, _, err := run("check", changeDir)
	if err == nil || !cli.IsCheckFailed(err) {
		t.Fatalf("expected a rubric violation, got %v", err)
	}
	if !strings.Contains(out, "rough") {
		t.Errorf("findings should name the change derived from the path; got:\n%s", out)
	}
}

func TestCheckPathFormMatchesNameForm(t *testing.T) {
	dir := setupMinimalOpenspec(t, "rough")
	writeSchema(t, dir, "spec-driven")

	byName, _, err1 := run("-C", dir, "check", "--change", "rough")
	byPath, _, err2 := run("check", filepath.Join(dir, "openspec", "changes", "rough"))
	if !cli.IsCheckFailed(err1) || !cli.IsCheckFailed(err2) {
		t.Fatalf("both forms should fail the rubric: %v / %v", err1, err2)
	}
	if byName != byPath {
		t.Errorf("the two forms must report identically:\n--- name:\n%s\n--- path:\n%s", byName, byPath)
	}
}
