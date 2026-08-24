package diffview

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/x/ansi"
)

// The renderer draws box and rail glyphs unconditionally, so the ellipsis is a
// constant here too rather than a glyph set the caller picks.
const ellipsis = "…"

// Every colour is an ANSI slot, so the terminal palette decides the hue and
// the pane matches the rest of the session instead of fighting it. These
// mirror reel's own theme, which is where this renderer came from.
var (
	faint  = lipgloss.NewStyle().Faint(true).Foreground(lipgloss.Color("8"))
	plain  = lipgloss.NewStyle().Foreground(lipgloss.Color("7"))
	accent = lipgloss.NewStyle().Foreground(lipgloss.Color("6"))
	title  = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("4"))
	live   = lipgloss.NewStyle().Foreground(lipgloss.Color("2"))
	bad    = lipgloss.NewStyle().Foreground(lipgloss.Color("1"))
	rule   = lipgloss.NewStyle().Faint(true).Foreground(lipgloss.Color("8"))
)

func clip(text string, width int) string {
	if width <= 0 {
		return ""
	}
	runes := []rune(text)
	if len(runes) <= width {
		return text + strings.Repeat(" ", width-len(runes))
	}
	if width == 1 {
		return "…"
	}
	return string(runes[:width-1]) + "…"
}

func plural(n int, word string) string {
	if n == 1 {
		return word
	}
	return word + "s"
}

// clip counts runes and fit counts display columns, so a line holding a wide
// rune needs both: clip pads it to the column budget, fit cuts what the pad
// then overshot.
func fit(s string, width int) string {
	if width < 1 {
		return ""
	}
	s = ansi.Truncate(s, width, ellipsis)
	if w := ansi.StringWidth(s); w < width {
		s += strings.Repeat(" ", width-w)
	}
	return s
}
