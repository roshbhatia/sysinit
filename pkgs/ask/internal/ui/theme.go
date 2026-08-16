package ui

import (
	"encoding/json"
	"os"
	"path/filepath"
	"regexp"

	"github.com/charmbracelet/lipgloss"
)

// Written by `modules/darwin/home/hammerspoon/default.nix` from the host's
// stylix scheme; every other reader of it is Lua.
const themeFile = "sysinit/theme_config.json"

var hex = regexp.MustCompile(`^#[0-9a-fA-F]{6}$`)

func themePath() string {
	if home := os.Getenv("XDG_CONFIG_HOME"); home != "" {
		return filepath.Join(home, themeFile)
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return ""
	}
	return filepath.Join(home, ".config", themeFile)
}

// scheme answers the host's base16 slots, or nil when nothing wrote them.
func scheme() map[string]string {
	path := themePath()
	if path == "" {
		return nil
	}
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil
	}
	var read struct {
		Base16 map[string]string `json:"base16"`
	}
	if json.Unmarshal(raw, &read) != nil {
		return nil
	}
	return read.Base16
}

// paint falls back to the 256-colour number this frame used before the scheme
// existed, so an unthemed machine looks unchanged.
func paint(slots map[string]string, slot string, fallback string) lipgloss.Style {
	if found, ok := slots[slot]; ok && hex.MatchString(found) {
		return lipgloss.NewStyle().Foreground(lipgloss.Color(found))
	}
	return lipgloss.NewStyle().Foreground(lipgloss.Color(fallback))
}
