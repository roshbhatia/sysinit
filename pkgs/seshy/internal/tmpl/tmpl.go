// Package tmpl provides Go template rendering for seshy file scaffolding.
package tmpl

import (
	"bytes"
	"fmt"
	"os"
	"os/user"
	"path/filepath"
	"strings"
	"text/template"
)

// RepoData describes a single repo within a session.
type RepoData struct {
	Name   string // basename in session dir
	Path   string // absolute worktree path
	Source string // absolute original clone path
	Branch string // rendered branch name
}

// TemplateData is the shared context for all template rendering.
type TemplateData struct {
	Session     string     // session name
	SessionPath string     // absolute session dir
	User        string     // current unix user
	Repo        string     // repo basename (empty for session-level)
	RepoPath    string     // absolute worktree path (empty for session-level)
	RepoSource  string     // original clone path (empty for session-level)
	Branch      string     // rendered branch name (empty for session-level)
	Repos       []RepoData // all repos in session
}

// NewTemplateData builds session-level TemplateData.
func NewTemplateData(sessionName, sessionPath string, repos []RepoData) TemplateData {
	u, _ := user.Current()
	username := ""
	if u != nil {
		username = u.Username
	}
	return TemplateData{
		Session:     sessionName,
		SessionPath: sessionPath,
		User:        username,
		Repos:       repos,
	}
}

// ForRepo returns a copy of d with per-repo fields populated.
func (d TemplateData) ForRepo(r RepoData) TemplateData {
	d.Repo = r.Name
	d.RepoPath = r.Path
	d.RepoSource = r.Source
	d.Branch = r.Branch
	return d
}

// RenderString parses and executes a template string.
func RenderString(tmplStr string, data TemplateData) (string, error) {
	t, err := template.New("").Parse(tmplStr)
	if err != nil {
		return "", fmt.Errorf("parse template: %w", err)
	}
	var buf bytes.Buffer
	if err := t.Execute(&buf, data); err != nil {
		return "", fmt.Errorf("execute template: %w", err)
	}
	return buf.String(), nil
}

// RenderFile renders a .tmpl file and writes the output.
func RenderFile(tmplPath, outputPath string, data TemplateData) error {
	content, err := os.ReadFile(tmplPath)
	if err != nil {
		return fmt.Errorf("read template %s: %w", tmplPath, err)
	}
	t, err := template.New(filepath.Base(tmplPath)).Parse(string(content))
	if err != nil {
		return fmt.Errorf("parse template %s: %w", tmplPath, err)
	}
	var buf bytes.Buffer
	if err := t.Execute(&buf, data); err != nil {
		return fmt.Errorf("execute template %s: %w", tmplPath, err)
	}

	dir := filepath.Dir(outputPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("create dir for %s: %w", outputPath, err)
	}
	return os.WriteFile(outputPath, buf.Bytes(), 0644)
}

// RenderDir renders all *.tmpl files in tmplDir into outputDir.
// Output filename = template filename minus .tmpl suffix.
// No-clobber: existing files are not overwritten.
// Returns nil if tmplDir doesn't exist.
func RenderDir(tmplDir, outputDir string, data TemplateData) error {
	if _, err := os.Stat(tmplDir); os.IsNotExist(err) {
		return nil
	}

	entries, err := filepath.Glob(filepath.Join(tmplDir, "*.tmpl"))
	if err != nil {
		return fmt.Errorf("glob templates in %s: %w", tmplDir, err)
	}

	for _, tmplPath := range entries {
		base := filepath.Base(tmplPath)
		outName := strings.TrimSuffix(base, ".tmpl")
		outPath := filepath.Join(outputDir, outName)

		// No-clobber: skip if output exists
		if _, err := os.Stat(outPath); err == nil {
			continue
		}

		if err := RenderFile(tmplPath, outPath, data); err != nil {
			return err
		}
	}
	return nil
}

// RenderSessionDir renders all *.tmpl files in tmplDir into outputDir,
// overwriting existing files. Used for session-level templates where
// the Repos list may have changed (e.g., after sy add).
func RenderSessionDir(tmplDir, outputDir string, data TemplateData) error {
	if _, err := os.Stat(tmplDir); os.IsNotExist(err) {
		return nil
	}

	entries, err := filepath.Glob(filepath.Join(tmplDir, "*.tmpl"))
	if err != nil {
		return fmt.Errorf("glob templates in %s: %w", tmplDir, err)
	}

	for _, tmplPath := range entries {
		base := filepath.Base(tmplPath)
		outName := strings.TrimSuffix(base, ".tmpl")
		outPath := filepath.Join(outputDir, outName)
		if err := RenderFile(tmplPath, outPath, data); err != nil {
			return err
		}
	}
	return nil
}
