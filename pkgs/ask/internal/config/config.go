package config

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"sort"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/ask/internal/provider"
)

const ProviderDefault = "provider.default"

type Setting struct {
	Key string

	Help string

	// Values answers with the whole allowed set, or nil when any value will do.
	Values func() []string

	// Clean rewrites an accepted value into the one spelling it is stored as.
	Clean func(string) (string, error)
}

var settings = []Setting{{
	Key:    ProviderDefault,
	Help:   "the agent to run when no -p and no ASK_PROVIDER say otherwise",
	Values: provider.Names,
	Clean: func(value string) (string, error) {
		one, ok := provider.Lookup(value)
		if !ok {
			return "", fmt.Errorf("unknown provider %q, known: %s", value, strings.Join(provider.Names(), ", "))
		}
		return one.Name, nil
	},
}}

func Settings() []Setting { return slices.Clone(settings) }

func Keys() []string {
	keys := make([]string, 0, len(settings))
	for _, one := range settings {
		keys = append(keys, one.Key)
	}
	return keys
}

func find(key string) (Setting, error) {
	for _, one := range settings {
		if one.Key == key {
			return one, nil
		}
	}
	return Setting{}, fmt.Errorf("unknown setting %q, known: %s", key, strings.Join(Keys(), ", "))
}

func Path() string {
	base := os.Getenv("XDG_CONFIG_HOME")
	if base == "" {
		base = filepath.Join(os.Getenv("HOME"), ".config")
	}
	return filepath.Join(base, "ask", "config.json")
}

// Load answers with an empty set when no file has been written yet, and with an
// error when one has been written and will not parse.
func Load() (map[string]string, error) {
	raw, err := os.ReadFile(Path())
	if errors.Is(err, os.ErrNotExist) {
		return map[string]string{}, nil
	}
	if err != nil {
		return nil, err
	}
	held := map[string]string{}
	if len(strings.TrimSpace(string(raw))) == 0 {
		return held, nil
	}
	if err := json.Unmarshal(raw, &held); err != nil {
		return nil, fmt.Errorf("%s will not parse: %w", Path(), err)
	}
	return held, nil
}

func Get(key string) (string, error) {
	if _, err := find(key); err != nil {
		return "", err
	}
	held, err := Load()
	if err != nil {
		return "", err
	}
	return held[key], nil
}

// Set takes one KEY=VALUE pair, so a single flag carries both halves.
func Set(pair string) (string, string, error) {
	key, value, ok := strings.Cut(pair, "=")
	if !ok {
		return "", "", fmt.Errorf("say it as KEY=VALUE, not %q", pair)
	}
	key, value = strings.TrimSpace(key), strings.TrimSpace(value)

	setting, err := find(key)
	if err != nil {
		return "", "", err
	}
	if setting.Clean != nil && value != "" {
		if value, err = setting.Clean(value); err != nil {
			return "", "", err
		}
	}

	held, err := Load()
	if err != nil {
		return "", "", err
	}
	if value == "" {
		delete(held, key)
	} else {
		held[key] = value
	}
	return key, value, save(held)
}

func save(held map[string]string) error {
	path := Path()
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return err
	}
	raw, err := json.MarshalIndent(held, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(path, append(raw, '\n'), 0o600)
}

// List answers with every known setting, so an unset one is still visible.
func List() ([]string, error) {
	held, err := Load()
	if err != nil {
		return nil, err
	}
	lines := make([]string, 0, len(settings))
	for _, one := range settings {
		value := held[one.Key]
		if value == "" {
			value = "(unset)"
		}
		lines = append(lines, one.Key+"="+value)
	}
	sort.Strings(lines)
	return lines, nil
}
