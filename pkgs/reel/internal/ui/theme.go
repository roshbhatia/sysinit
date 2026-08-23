package ui

import (
	"fmt"
	"time"

	"github.com/charmbracelet/lipgloss"
	"github.com/roshbhatia/sysinit/pkgs/reel/internal/session"
)

var (
	dim     = lipgloss.NewStyle().Foreground(lipgloss.Color("241"))
	faint   = lipgloss.NewStyle().Foreground(lipgloss.Color("238"))
	plain   = lipgloss.NewStyle().Foreground(lipgloss.Color("252"))
	accent  = lipgloss.NewStyle().Foreground(lipgloss.Color("212"))
	title   = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("62"))
	live    = lipgloss.NewStyle().Foreground(lipgloss.Color("78"))
	bad     = lipgloss.NewStyle().Foreground(lipgloss.Color("203"))
	rule    = lipgloss.NewStyle().Foreground(lipgloss.Color("237"))
	cursor  = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("212"))
	tagKey  = lipgloss.NewStyle().Foreground(lipgloss.Color("109"))
	tagText = lipgloss.NewStyle().Foreground(lipgloss.Color("250"))
)

// One color family per role, so a turn, a model call, a tool call and a
// delegated subagent stay apart at a glance without reading the label.
var roleColor = map[session.Role]lipgloss.Color{
	session.RoleTurn:     lipgloss.Color("214"),
	session.RoleModel:    lipgloss.Color("111"),
	session.RoleTool:     lipgloss.Color("78"),
	session.RoleDelegate: lipgloss.Color("141"),
	session.RoleSystem:   lipgloss.Color("245"),
	session.RoleError:    lipgloss.Color("203"),
}

func roleStyle(role session.Role) lipgloss.Style {
	color, ok := roleColor[role]
	if !ok {
		color = roleColor[session.RoleSystem]
	}
	return lipgloss.NewStyle().Foreground(color)
}

func span(count int, ch string) string {
	if count <= 0 {
		return ""
	}
	out := make([]byte, 0, count*len(ch))
	for range count {
		out = append(out, ch...)
	}
	return string(out)
}

func clip(text string, width int) string {
	if width <= 0 {
		return ""
	}
	runes := []rune(text)
	if len(runes) <= width {
		return text + span(width-len(runes), " ")
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

func duration(d time.Duration) string {
	switch {
	case d <= 0:
		return "—"
	case d < time.Millisecond:
		return fmt.Sprintf("%dµs", d/time.Microsecond)
	case d < time.Second:
		return fmt.Sprintf("%dms", d/time.Millisecond)
	case d < time.Minute:
		return fmt.Sprintf("%.1fs", d.Seconds())
	case d < time.Hour:
		return fmt.Sprintf("%dm%02ds", int(d/time.Minute), int((d%time.Minute)/time.Second))
	default:
		return fmt.Sprintf("%dh%02dm", int(d/time.Hour), int((d%time.Hour)/time.Minute))
	}
}

func ago(at time.Time, now time.Time) string {
	if at.IsZero() {
		return "—"
	}
	return duration(now.Sub(at).Round(time.Second)) + " ago"
}
