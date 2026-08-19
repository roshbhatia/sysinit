package config

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestDefaults(t *testing.T) {
	cfg := defaults()
	if cfg.BranchFormat != "sy/{{.Session}}/{{.Repo}}" {
		t.Errorf("unexpected BranchFormat: %q", cfg.BranchFormat)
	}
	if cfg.RepoSource != "zoxide query --list" {
		t.Errorf("unexpected RepoSource: %q", cfg.RepoSource)
	}
	if !strings.Contains(cfg.Picker, "fzf") {
		t.Errorf("unexpected Picker: %q", cfg.Picker)
	}
	if !strings.Contains(cfg.SessionPicker, "fzf") {
		t.Errorf("unexpected SessionPicker: %q", cfg.SessionPicker)
	}
}

func TestLoadMissingFile(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", t.TempDir())
	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	if cfg.BranchFormat != "sy/{{.Session}}/{{.Repo}}" {
		t.Errorf("expected default BranchFormat, got %q", cfg.BranchFormat)
	}
	if cfg.RepoSource != "zoxide query --list" {
		t.Errorf("expected default RepoSource, got %q", cfg.RepoSource)
	}
}

func TestLoadEmptyFile(t *testing.T) {
	dir := t.TempDir()
	t.Setenv("XDG_CONFIG_HOME", dir)
	cfgDir := filepath.Join(dir, "seshy")
	os.MkdirAll(cfgDir, 0755)
	os.WriteFile(filepath.Join(cfgDir, "config.yaml"), []byte(""), 0644)

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	if cfg.BranchFormat != "sy/{{.Session}}/{{.Repo}}" {
		t.Errorf("expected default BranchFormat for empty file, got %q", cfg.BranchFormat)
	}
	if cfg.RepoSource != "zoxide query --list" {
		t.Errorf("expected default RepoSource for empty file, got %q", cfg.RepoSource)
	}
}

func TestLoadPartialConfig(t *testing.T) {
	dir := t.TempDir()
	t.Setenv("XDG_CONFIG_HOME", dir)
	cfgDir := filepath.Join(dir, "seshy")
	os.MkdirAll(cfgDir, 0755)
	os.WriteFile(filepath.Join(cfgDir, "config.yaml"), []byte("branchFormat: \"custom/{{.Repo}}\"\n"), 0644)

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	if cfg.BranchFormat != "custom/{{.Repo}}" {
		t.Errorf("expected custom BranchFormat, got %q", cfg.BranchFormat)
	}
	// Other fields should have defaults
	if cfg.RepoSource != "zoxide query --list" {
		t.Errorf("expected default RepoSource, got %q", cfg.RepoSource)
	}
}

func TestLoadWithHooks(t *testing.T) {
	dir := t.TempDir()
	t.Setenv("XDG_CONFIG_HOME", dir)
	cfgDir := filepath.Join(dir, "seshy")
	os.MkdirAll(cfgDir, 0755)
	yaml := `hooks:
  postCreate:
    - "direnv allow ."
    - "mise install"
  preDelete:
    - "echo bye"
`
	os.WriteFile(filepath.Join(cfgDir, "config.yaml"), []byte(yaml), 0644)

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	if len(cfg.Hooks.PostCreate) != 2 {
		t.Errorf("expected 2 postCreate hooks, got %d", len(cfg.Hooks.PostCreate))
	}
	if cfg.Hooks.PostCreate[0] != "direnv allow ." {
		t.Errorf("unexpected hook: %q", cfg.Hooks.PostCreate[0])
	}
	if len(cfg.Hooks.PreDelete) != 1 {
		t.Errorf("expected 1 preDelete hook, got %d", len(cfg.Hooks.PreDelete))
	}
}

func TestLoadWithDefaultRepos(t *testing.T) {
	dir := t.TempDir()
	t.Setenv("XDG_CONFIG_HOME", dir)
	cfgDir := filepath.Join(dir, "seshy")
	os.MkdirAll(cfgDir, 0755)
	yaml := `defaultRepos:
  - ~/github/shared
  - /absolute/path
`
	os.WriteFile(filepath.Join(cfgDir, "config.yaml"), []byte(yaml), 0644)

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	if len(cfg.DefaultRepos) != 2 {
		t.Fatalf("expected 2 defaultRepos, got %d", len(cfg.DefaultRepos))
	}
	// Tilde should be expanded
	home, _ := os.UserHomeDir()
	if cfg.DefaultRepos[0] != home+"/github/shared" {
		t.Errorf("expected tilde expansion, got %q", cfg.DefaultRepos[0])
	}
	// Absolute path unchanged
	if cfg.DefaultRepos[1] != "/absolute/path" {
		t.Errorf("expected /absolute/path, got %q", cfg.DefaultRepos[1])
	}
}

func TestLoadInvalidYAML(t *testing.T) {
	dir := t.TempDir()
	t.Setenv("XDG_CONFIG_HOME", dir)
	cfgDir := filepath.Join(dir, "seshy")
	os.MkdirAll(cfgDir, 0755)
	os.WriteFile(filepath.Join(cfgDir, "config.yaml"), []byte("{{invalid yaml"), 0644)

	_, err := Load()
	if err == nil {
		t.Error("expected error for invalid YAML")
	}
}

func TestConfigDirXDGOverride(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", "/custom/config")
	dir := ConfigDir()
	if dir != "/custom/config/seshy" {
		t.Errorf("expected /custom/config/seshy, got %q", dir)
	}
}

func TestConfigPath(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", "/custom/config")
	p := ConfigPath()
	if p != "/custom/config/seshy/config.yaml" {
		t.Errorf("expected /custom/config/seshy/config.yaml, got %q", p)
	}
}

func TestWriteDefault(t *testing.T) {
	dir := t.TempDir()
	t.Setenv("XDG_CONFIG_HOME", dir)
	if err := WriteDefault(); err != nil {
		t.Fatalf("WriteDefault: %v", err)
	}
	data, err := os.ReadFile(filepath.Join(dir, "seshy", "config.yaml"))
	if err != nil {
		t.Fatalf("ReadFile: %v", err)
	}
	s := string(data)
	if !strings.Contains(s, "branchFormat") {
		t.Errorf("expected branchFormat in default config")
	}
	if !strings.Contains(s, "repoSource") {
		t.Errorf("expected repoSource in default config")
	}
}

func TestGetSessionsRootXDGOverride(t *testing.T) {
	// Isolate config so a real sessionsDir setting doesn't override XDG_STATE_HOME.
	t.Setenv("XDG_CONFIG_HOME", t.TempDir())
	t.Setenv("XDG_STATE_HOME", "/tmp/custom-state")
	root := GetSessionsRoot()
	if root != "/tmp/custom-state/seshy/sessions" {
		t.Errorf("got %q", root)
	}
}

func TestGetSessionsRootDefault(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", "")
	root := GetSessionsRoot()
	home, _ := os.UserHomeDir()
	expected := filepath.Join(home, ".local", "state", "seshy", "sessions")
	if root != expected {
		t.Errorf("expected %q, got %q", expected, root)
	}
}
