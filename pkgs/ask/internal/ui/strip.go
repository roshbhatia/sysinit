package ui

import (
	"math/rand"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// A spinner says a process is alive. This says the agent is writing, which is
// the thing worth watching, so the cells reroll while a line lands rather than
// turning at a fixed rate. Crush animates the characters for the same reason.
const (
	cells = 10
	beat  = 90 * time.Millisecond
	// how many of the cells reroll on a frame; every cell rerolling reads as
	// noise, and one cell reads as a fault.
	churn = 0.4
)

var glyphs = []rune("ABCDEFGHJKLMNPQRSTUVWXYZ0123456789<>/\\|=+*#$%&")

type stripTick time.Time

func tock() tea.Cmd {
	return tea.Tick(beat, func(at time.Time) tea.Msg { return stripTick(at) })
}

type strip struct {
	glyph []rune
	shade []lipgloss.Style
	head  int
}

func newStrip() strip {
	glyph := make([]rune, cells)
	for at := range glyph {
		glyph[at] = roll()
	}
	return strip{glyph: glyph, shade: sweep(cells)}
}

func roll() rune { return glyphs[rand.Intn(len(glyphs))] }

// step rerolls part of the strip and moves the bright band along one cell.
func (s *strip) step() {
	for at := range s.glyph {
		if rand.Float64() < churn {
			s.glyph[at] = roll()
		}
	}
	s.head = (s.head + 1) % len(s.glyph)
}

func (s strip) View() string {
	var out strings.Builder
	for at, glyph := range s.glyph {
		out.WriteString(s.shade[(at+s.head)%len(s.shade)].Render(string(glyph)))
	}
	return out.String()
}
