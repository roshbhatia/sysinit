package ui

import (
	"fmt"
	"time"

	"github.com/charmbracelet/lipgloss"
	"github.com/roshbhatia/sysinit/pkgs/traces/internal/session"
)

// Every colour is an ANSI slot, so the terminal palette decides the hue and
// traces matches the rest of the session instead of fighting it.
var (
	dim     = lipgloss.NewStyle().Foreground(lipgloss.Color("8"))
	faint   = lipgloss.NewStyle().Faint(true).Foreground(lipgloss.Color("8"))
	plain   = lipgloss.NewStyle().Foreground(lipgloss.Color("7"))
	accent  = lipgloss.NewStyle().Foreground(lipgloss.Color("6"))
	title   = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("4"))
	live    = lipgloss.NewStyle().Foreground(lipgloss.Color("2"))
	bad     = lipgloss.NewStyle().Foreground(lipgloss.Color("1"))
	rule    = lipgloss.NewStyle().Faint(true).Foreground(lipgloss.Color("8"))
	cursor  = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("6"))
	tagKey  = lipgloss.NewStyle().Foreground(lipgloss.Color("4"))
	tagText = lipgloss.NewStyle().Foreground(lipgloss.Color("7"))
)

// One color family per role, so a turn, a model call, a tool call and a
// delegated subagent stay apart at a glance without reading the label.
var roleColor = map[session.Role]lipgloss.Color{
	session.RoleTurn:     lipgloss.Color("3"),
	session.RoleModel:    lipgloss.Color("4"),
	session.RoleTool:     lipgloss.Color("2"),
	session.RoleDelegate: lipgloss.Color("5"),
	session.RoleSystem:   lipgloss.Color("8"),
	session.RoleError:    lipgloss.Color("1"),
}

func roleStyle(role session.Role) lipgloss.Style {
	color, ok := roleColor[role]
	if !ok {
		color = roleColor[session.RoleSystem]
	}
	return lipgloss.NewStyle().Foreground(color)
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
