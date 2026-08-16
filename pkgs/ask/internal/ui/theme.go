package ui

import (
	"encoding/json"
	"os"
	"path/filepath"
	"regexp"

	"github.com/charmbracelet/lipgloss"
)

// theme_config.json is written by modules/darwin/home/hammerspoon/default.nix
// from the host's stylix scheme. Reading it is what makes this frame the same
// colour as the shell around it; every other reader of the file is Lua.
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

// paint answers the scheme's colour for a slot, or the fallback when the file is
// missing a slot or absent. The fallbacks are the 256-colour numbers this frame
// used before the scheme existed, so an unthemed machine looks unchanged.
func paint(slots map[string]string, slot string, fallback string) lipgloss.Style {
	if found, ok := slots[slot]; ok && hex.MatchString(found) {
		return lipgloss.NewStyle().Foreground(lipgloss.Color(found))
	}
	return lipgloss.NewStyle().Foreground(lipgloss.Color(fallback))
}
