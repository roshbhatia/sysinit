package ui

import (
	"os"
	"strings"

	"github.com/charmbracelet/lipgloss"
)

const (
	narrowest = 34
	widest    = 84
)

var (
	dim    = lipgloss.NewStyle().Foreground(lipgloss.Color("245"))
	accent = lipgloss.NewStyle().Foreground(lipgloss.Color("111"))
	bad    = lipgloss.NewStyle().Foreground(lipgloss.Color("203"))
	tool   = lipgloss.NewStyle().Foreground(lipgloss.Color("150"))
	edge   = lipgloss.NewStyle().Foreground(lipgloss.Color("238"))
	chosen = lipgloss.NewStyle().Foreground(lipgloss.Color("111")).Bold(true)
)

// inner answers with the room a frame leaves for content, given the whole terminal.
func inner(terminal int) int {
	if terminal <= 0 {
		terminal = narrowest + 4
	}
	if terminal > widest {
		terminal = widest
	}
	room := terminal - 4
	if room < narrowest {
		room = narrowest
	}
	return room
}

// clip cuts to width in runes, not bytes, so a multibyte line keeps its shape.
func clip(text string, width int) string {
	if width <= 0 {
		return ""
	}
	runes := []rune(text)
	if len(runes) <= width {
		return text
	}
	if width == 1 {
		return "…"
	}
	return string(runes[:width-1]) + "…"
}

func pad(text string, width int) string {
	if room := width - lipgloss.Width(text); room > 0 {
		return text + strings.Repeat(" ", room)
	}
	return text
}

// split lays a left half and a right half against the two ends of one row.
func split(left, right string, width int) string {
	gap := width - lipgloss.Width(left) - lipgloss.Width(right)
	if gap < 1 {
		gap = 1
	}
	return left + strings.Repeat(" ", gap) + right
}

type frame struct {
	title string
	width int
	head  string
	rows  []string
}

func (f frame) String() string {
	border := lipgloss.RoundedBorder()
	across := f.width + 2

	var out strings.Builder
	out.WriteString(edge.Render(border.TopLeft+" ") + accent.Render(f.title) + edge.Render(" "+strings.Repeat(border.Top, max(across-2-lipgloss.Width(f.title), 0))+border.TopRight))
	out.WriteString("\n")

	write := func(row string) {
		out.WriteString(edge.Render(border.Left) + " " + pad(row, f.width) + " " + edge.Render(border.Right) + "\n")
	}
	if f.head != "" {
		write(f.head)
		if len(f.rows) > 0 {
			out.WriteString(edge.Render(border.MiddleLeft+strings.Repeat(border.Top, across)+border.MiddleRight) + "\n")
		}
	}
	for _, row := range f.rows {
		write(row)
	}
	out.WriteString(edge.Render(border.BottomLeft + strings.Repeat(border.Top, across) + border.BottomRight))
	return out.String()
}

// console opens the terminal itself, because stdin is often a pipe holding the input.
func console() *os.File {
	handle, err := os.OpenFile("/dev/tty", os.O_RDWR, 0)
	if err != nil {
		return nil
	}
	return handle
}
