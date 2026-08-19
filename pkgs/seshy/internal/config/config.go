// Package config handles seshy configuration via YAML files with XDG support.
package config

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"

	"github.com/roshbhatia/sysinit/pkgs/internal/paths"
)

// HooksConfig holds lifecycle hook commands.
type HooksConfig struct {
	PostCreate []string `yaml:"postCreate"`
	PostAdd    []string `yaml:"postAdd"`
	PreDelete  []string `yaml:"preDelete"`
}

// Config holds all seshy configuration.
type Config struct {
	BranchFormat  string      `yaml:"branchFormat"`
	SessionsDir   string      `yaml:"sessionsDir"`
	ArchiveDir    string      `yaml:"archiveDir"`
	RepoSource    string      `yaml:"repoSource"`
	Picker        string      `yaml:"picker"`
	SessionPicker string      `yaml:"sessionPicker"`
	DefaultRepos  []string    `yaml:"defaultRepos"`
	Hooks         HooksConfig `yaml:"hooks"`
}

func defaults() Config {
	return Config{
		BranchFormat:  "sy/{{.Session}}/{{.Repo}}",
		SessionsDir:   "",
		ArchiveDir:    "",
		RepoSource:    "zoxide query --list",
		Picker:        "fzf --multi --height=40% --reverse --prompt='repo > '",
		SessionPicker: "fzf --height=40% --reverse --prompt='session > '",
	}
}

// ConfigDir returns the seshy config directory.
func ConfigDir() string {
	return filepath.Join(paths.ConfigHome(), "seshy")
}

// ConfigPath returns the path to config.yaml.
func ConfigPath() string {
	return filepath.Join(ConfigDir(), "config.yaml")
}

// Load reads config from disk and merges with defaults.
func Load() (*Config, error) {
	cfg := defaults()
	data, err := os.ReadFile(ConfigPath())
	if err != nil {
		if os.IsNotExist(err) {
			return &cfg, nil
		}
		return nil, fmt.Errorf("reading config: %w", err)
	}
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("parsing config: %w", err)
	}

	// Apply defaults for empty string fields
	d := defaults()
	if cfg.BranchFormat == "" {
		cfg.BranchFormat = d.BranchFormat
	}
	if cfg.RepoSource == "" {
		cfg.RepoSource = d.RepoSource
	}
	if cfg.Picker == "" {
		cfg.Picker = d.Picker
	}
	if cfg.SessionPicker == "" {
		cfg.SessionPicker = d.SessionPicker
	}

	// Tilde expansion for default repos
	for i, p := range cfg.DefaultRepos {
		cfg.DefaultRepos[i] = expandTilde(p)
	}

	return &cfg, nil
}

func expandTilde(path string) string {
	if strings.HasPrefix(path, "~/") {
		home, _ := os.UserHomeDir()
		return home + path[1:]
	}
	return path
}

// WriteDefault writes a default config file.
func WriteDefault() error {
	dir := ConfigDir()
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}
	cfg := defaults()
	data, err := yaml.Marshal(&cfg)
	if err != nil {
		return err
	}
	return os.WriteFile(ConfigPath(), data, 0644)
}

// GetSessionsRoot returns the sessions directory. config.yaml wins, then the
// sysinit paths manifest, which is the value nix wrote into config.yaml anyway.
func GetSessionsRoot() string {
	if data, err := os.ReadFile(ConfigPath()); err == nil {
		var cfg Config
		if yaml.Unmarshal(data, &cfg) == nil && cfg.SessionsDir != "" {
			return expandTilde(cfg.SessionsDir)
		}
	}
	return paths.SeshySessions()
}

// EnsureSessionsRoot creates the sessions directory if it doesn't exist.
func EnsureSessionsRoot() error {
	return os.MkdirAll(GetSessionsRoot(), 0755)
}

// GetArchiveRoot returns the directory that holds archived sessions.
// Respects archiveDir in config if set. Otherwise it sits beside the sessions
// directory, which keeps archiving a same-filesystem rename.
func GetArchiveRoot() string {
	if data, err := os.ReadFile(ConfigPath()); err == nil {
		var cfg Config
		if yaml.Unmarshal(data, &cfg) == nil && cfg.ArchiveDir != "" {
			return expandTilde(cfg.ArchiveDir)
		}
	}
	return filepath.Join(filepath.Dir(GetSessionsRoot()), "archive")
}

// EnsureArchiveRoot creates the archive directory if it doesn't exist.
func EnsureArchiveRoot() error {
	return os.MkdirAll(GetArchiveRoot(), 0755)
}
