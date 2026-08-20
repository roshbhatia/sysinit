package ui

import (
	"encoding/json"
	"fmt"
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

// hexOf answers a slot as a hex string, so a colour can be mixed rather than
// only rendered. paint takes a 256-colour fallback because it needs no maths;
// this one cannot mix an indexed colour, so the fallback is a hex too.
func hexOf(slot, fallback string) string {
	if found, ok := slots[slot]; ok && hex.MatchString(found) {
		return found
	}
	return fallback
}

func channels(colour string) (r, g, b int) {
	var red, green, blue int
	if _, err := fmt.Sscanf(colour, "#%02x%02x%02x", &red, &green, &blue); err != nil {
		return 0, 0, 0
	}
	return red, green, blue
}

// mix reads one step along a straight line between two colours.
func mix(from, to string, at, of int) string {
	if of < 2 {
		return to
	}
	fr, fg, fb := channels(from)
	tr, tg, tb := channels(to)
	part := float64(at) / float64(of-1)
	blend := func(a, b int) int { return a + int(float64(b-a)*part) }
	return fmt.Sprintf("#%02x%02x%02x", blend(fr, tr), blend(fg, tg), blend(fb, tb))
}

// sweep builds a band that climbs to the accent and falls back, so cycling it
// reads as one bright spot travelling rather than a hard edge wrapping around.
func sweep(width int) []lipgloss.Style {
	from, to := hexOf("base03", "#585b70"), hexOf("base0D", "#89b4fa")
	half := width / 2
	band := make([]lipgloss.Style, 0, width)
	for at := range width {
		step := at
		if at >= half {
			step = width - at - 1
		}
		colour := mix(from, to, step, max(half, 1))
		band = append(band, lipgloss.NewStyle().Foreground(lipgloss.Color(colour)))
	}
	return band
}

// dark reads the scheme's background, so the markdown style matches the frame
// without asking the terminal anything.
func dark() bool {
	r, g, b := channels(hexOf("base00", "#1e1e2e"))
	return (r*299+g*587+b*114)/1000 < 128
}
