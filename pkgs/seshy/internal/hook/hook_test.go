package hook

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/roshbhatia/seshy/internal/tmpl"
)

func testData(dir string) tmpl.TemplateData {
	return tmpl.TemplateData{
		Session:     "test-sess",
		SessionPath: dir,
		User:        "testuser",
		Repos: []tmpl.RepoData{
			{Name: "api", Path: filepath.Join(dir, "api")},
			{Name: "web", Path: filepath.Join(dir, "web")},
		},
	}
}

func TestRunSimple(t *testing.T) {
	dir := t.TempDir()
	errs := Run("post-create", []string{"echo hello"}, testData(dir), dir)
	if len(errs) != 0 {
		t.Errorf("expected no errors, got %v", errs)
	}
}

func TestRunWithTemplate(t *testing.T) {
	dir := t.TempDir()
	marker := filepath.Join(dir, "marker")
	cmd := "echo {{.Session}} > " + marker
	errs := Run("post-create", []string{cmd}, testData(dir), dir)
	if len(errs) != 0 {
		t.Errorf("unexpected errors: %v", errs)
	}
	got, _ := os.ReadFile(marker)
	if s := string(got); s != "test-sess\n" {
		t.Errorf("expected 'test-sess', got %q", s)
	}
}

func TestRunSetsEnv(t *testing.T) {
	dir := t.TempDir()
	marker := filepath.Join(dir, "env")
	cmd := "echo $SESHY_SESSION,$SESHY_REPO_COUNT,$SESHY_EVENT > " + marker
	errs := Run("post-create", []string{cmd}, testData(dir), dir)
	if len(errs) != 0 {
		t.Errorf("unexpected errors: %v", errs)
	}
	got, _ := os.ReadFile(marker)
	if s := string(got); s != "test-sess,2,post-create\n" {
		t.Errorf("unexpected env: %q", s)
	}
}

func TestRunNonFatal(t *testing.T) {
	dir := t.TempDir()
	errs := Run("post-create", []string{"false"}, testData(dir), dir)
	if len(errs) != 1 {
		t.Errorf("expected 1 error, got %d", len(errs))
	}
}

func TestRunMultiple(t *testing.T) {
	dir := t.TempDir()
	m1 := filepath.Join(dir, "m1")
	m2 := filepath.Join(dir, "m2")
	cmds := []string{"touch " + m1, "touch " + m2}
	errs := Run("post-create", cmds, testData(dir), dir)
	if len(errs) != 0 {
		t.Errorf("unexpected errors: %v", errs)
	}
	if _, err := os.Stat(m1); err != nil {
		t.Error("m1 not created")
	}
	if _, err := os.Stat(m2); err != nil {
		t.Error("m2 not created")
	}
}

func TestRunEmpty(t *testing.T) {
	dir := t.TempDir()
	errs := Run("post-create", nil, testData(dir), dir)
	if len(errs) != 0 {
		t.Errorf("expected no errors for empty list, got %v", errs)
	}
}

func TestRunHookScript(t *testing.T) {
	dir := t.TempDir()
	cfgDir := t.TempDir()
	t.Setenv("XDG_CONFIG_HOME", cfgDir)

	hooksDir := filepath.Join(cfgDir, "seshy", "hooks")
	os.MkdirAll(hooksDir, 0755)
	marker := filepath.Join(dir, "script-ran")
	script := "#!/bin/sh\ntouch " + marker + "\n"
	scriptPath := filepath.Join(hooksDir, "post-create")
	os.WriteFile(scriptPath, []byte(script), 0755)

	errs := Run("post-create", nil, testData(dir), dir)
	if len(errs) != 0 {
		t.Errorf("unexpected errors: %v", errs)
	}
	if _, err := os.Stat(marker); err != nil {
		t.Error("hook script did not run")
	}
}
