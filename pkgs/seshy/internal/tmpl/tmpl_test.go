package tmpl

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestRenderString(t *testing.T) {
	data := TemplateData{Session: "feat", Repo: "api"}
	got, err := RenderString("sy/{{.Session}}/{{.Repo}}", data)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "sy/feat/api" {
		t.Errorf("expected 'sy/feat/api', got %q", got)
	}
}

func TestRenderStringInvalid(t *testing.T) {
	_, err := RenderString("{{.Bad", TemplateData{})
	if err == nil {
		t.Error("expected error for invalid template")
	}
}

func TestRenderFile(t *testing.T) {
	dir := t.TempDir()
	tmplPath := filepath.Join(dir, "test.tmpl")
	os.WriteFile(tmplPath, []byte("Session: {{.Session}}\n"), 0644)

	outPath := filepath.Join(dir, "test")
	data := TemplateData{Session: "my-feat"}
	if err := RenderFile(tmplPath, outPath, data); err != nil {
		t.Fatalf("RenderFile: %v", err)
	}

	got, _ := os.ReadFile(outPath)
	if string(got) != "Session: my-feat\n" {
		t.Errorf("unexpected output: %q", got)
	}
}

func TestRenderFileWithRepoData(t *testing.T) {
	dir := t.TempDir()
	tmplPath := filepath.Join(dir, "envrc.tmpl")
	os.WriteFile(tmplPath, []byte("export SVC={{.Repo}}\nexport BRANCH={{.Branch}}\n"), 0644)

	outPath := filepath.Join(dir, ".envrc")
	data := TemplateData{Repo: "api", Branch: "sy/feat/api"}
	if err := RenderFile(tmplPath, outPath, data); err != nil {
		t.Fatalf("RenderFile: %v", err)
	}

	got, _ := os.ReadFile(outPath)
	if !strings.Contains(string(got), "SVC=api") || !strings.Contains(string(got), "BRANCH=sy/feat/api") {
		t.Errorf("unexpected: %q", got)
	}
}

func TestRenderFileInvalidTemplate(t *testing.T) {
	dir := t.TempDir()
	tmplPath := filepath.Join(dir, "bad.tmpl")
	os.WriteFile(tmplPath, []byte("{{.Bad"), 0644)

	err := RenderFile(tmplPath, filepath.Join(dir, "out"), TemplateData{})
	if err == nil {
		t.Error("expected error for invalid template")
	}
}

func TestRenderDir(t *testing.T) {
	dir := t.TempDir()
	tmplDir := filepath.Join(dir, "templates")
	os.MkdirAll(tmplDir, 0755)
	os.WriteFile(filepath.Join(tmplDir, ".envrc.tmpl"), []byte("S={{.Session}}\n"), 0644)
	os.WriteFile(filepath.Join(tmplDir, "Makefile.tmpl"), []byte("all: build\n"), 0644)

	outDir := filepath.Join(dir, "output")
	os.MkdirAll(outDir, 0755)

	data := TemplateData{Session: "test"}
	if err := RenderDir(tmplDir, outDir, data); err != nil {
		t.Fatalf("RenderDir: %v", err)
	}

	envrc, _ := os.ReadFile(filepath.Join(outDir, ".envrc"))
	if string(envrc) != "S=test\n" {
		t.Errorf("envrc: %q", envrc)
	}
	makefile, _ := os.ReadFile(filepath.Join(outDir, "Makefile"))
	if string(makefile) != "all: build\n" {
		t.Errorf("makefile: %q", makefile)
	}
}

func TestRenderDirNoClobber(t *testing.T) {
	dir := t.TempDir()
	tmplDir := filepath.Join(dir, "templates")
	os.MkdirAll(tmplDir, 0755)
	os.WriteFile(filepath.Join(tmplDir, "file.tmpl"), []byte("NEW\n"), 0644)

	outDir := filepath.Join(dir, "output")
	os.MkdirAll(outDir, 0755)
	os.WriteFile(filepath.Join(outDir, "file"), []byte("ORIGINAL\n"), 0644)

	if err := RenderDir(tmplDir, outDir, TemplateData{}); err != nil {
		t.Fatalf("RenderDir: %v", err)
	}

	got, _ := os.ReadFile(filepath.Join(outDir, "file"))
	if string(got) != "ORIGINAL\n" {
		t.Errorf("expected no-clobber, got: %q", got)
	}
}

func TestRenderDirMissing(t *testing.T) {
	err := RenderDir("/nonexistent/path", t.TempDir(), TemplateData{})
	if err != nil {
		t.Errorf("expected nil for missing dir, got: %v", err)
	}
}

func TestTemplateDataRepoRange(t *testing.T) {
	dir := t.TempDir()
	tmplDir := filepath.Join(dir, "templates")
	os.MkdirAll(tmplDir, 0755)
	os.WriteFile(filepath.Join(tmplDir, "Makefile.tmpl"), []byte(
		".PHONY: all\nall:{{range .Repos}}\n\t$(MAKE) -C {{.Name}}{{end}}\n"), 0644)

	outDir := filepath.Join(dir, "output")
	os.MkdirAll(outDir, 0755)

	data := TemplateData{
		Session: "test",
		Repos: []RepoData{
			{Name: "api", Path: "/p/api"},
			{Name: "web", Path: "/p/web"},
		},
	}
	if err := RenderDir(tmplDir, outDir, data); err != nil {
		t.Fatalf("RenderDir: %v", err)
	}

	got, _ := os.ReadFile(filepath.Join(outDir, "Makefile"))
	s := string(got)
	if !strings.Contains(s, "$(MAKE) -C api") || !strings.Contains(s, "$(MAKE) -C web") {
		t.Errorf("unexpected Makefile: %q", s)
	}
}

func TestNewTemplateData(t *testing.T) {
	repos := []RepoData{{Name: "r1"}, {Name: "r2"}}
	data := NewTemplateData("sess", "/path", repos)
	if data.Session != "sess" {
		t.Errorf("session: %q", data.Session)
	}
	if data.User == "" {
		t.Error("expected User to be non-empty")
	}
	if len(data.Repos) != 2 {
		t.Errorf("repos: %d", len(data.Repos))
	}
}

func TestForRepo(t *testing.T) {
	data := NewTemplateData("sess", "/path", nil)
	rd := RepoData{Name: "api", Path: "/p/api", Source: "/src/api", Branch: "sy/sess/api"}
	forRepo := data.ForRepo(rd)
	if forRepo.Repo != "api" || forRepo.Branch != "sy/sess/api" {
		t.Errorf("ForRepo: Repo=%q Branch=%q", forRepo.Repo, forRepo.Branch)
	}
	// Original should be unchanged
	if data.Repo != "" {
		t.Error("original data was mutated")
	}
}
