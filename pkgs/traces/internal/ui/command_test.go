package ui

import (
	"strings"
	"testing"

	tea "github.com/charmbracelet/bubbletea"
)

func typeIn(m Model, text string) Model {
	m.cmd = true
	for _, r := range text {
		next, _ := m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{r}})
		m = next.(Model)
	}
	return m
}

func enter(m Model) Model {
	next, _ := m.Update(tea.KeyMsg{Type: tea.KeyEnter})
	return next.(Model)
}

func TestSetTogglesAnOption(t *testing.T) {
	m := enter(typeIn(Model{}, "set timeline"))
	if !m.timeline {
		t.Error("set timeline did not turn it on")
	}
	m = enter(typeIn(m, "set notimeline"))
	if m.timeline {
		t.Error("set notimeline did not turn it off")
	}
}

// vim resolves any unambiguous prefix, which is what makes a command line worth
// typing at all.
func TestAPrefixResolves(t *testing.T) {
	m := enter(typeIn(Model{}, "se not"))
	if m.timeline {
		t.Errorf("se not did not resolve: status %q", m.status)
	}
}

func TestAnAmbiguousPrefixIsRefused(t *testing.T) {
	// "s" is the head of set, session and split.
	m := enter(typeIn(Model{}, "s"))
	if !strings.Contains(m.status, "ambiguous") {
		t.Errorf("status = %q", m.status)
	}
}

func TestAnUnknownNameSaysSo(t *testing.T) {
	m := enter(typeIn(Model{}, "nope"))
	if !strings.Contains(m.status, "no command") {
		t.Errorf("status = %q", m.status)
	}
}

func TestSlashRunsAFilter(t *testing.T) {
	m := enter(typeIn(Model{}, "/goroutine"))
	if m.query != "goroutine" {
		t.Errorf("query = %q", m.query)
	}
}

func TestHistoryRecallsBackwards(t *testing.T) {
	m := enter(typeIn(Model{}, "set timeline"))
	m = enter(typeIn(m, "set notimeline"))
	m.cmd = true
	next, _ := m.Update(tea.KeyMsg{Type: tea.KeyUp})
	m = next.(Model)
	if m.cmdText != "set notimeline" {
		t.Errorf("one up = %q", m.cmdText)
	}
	next, _ = m.Update(tea.KeyMsg{Type: tea.KeyUp})
	m = next.(Model)
	if m.cmdText != "set timeline" {
		t.Errorf("two up = %q", m.cmdText)
	}
}

func TestTabCompletesOneMatch(t *testing.T) {
	m := typeIn(Model{}, "vs")
	next, _ := m.Update(tea.KeyMsg{Type: tea.KeyTab})
	if got := next.(Model).cmdText; got != "vsplit" {
		t.Errorf("completion = %q", got)
	}
}

// A repeat must not fill the history with one string.
func TestHistorySkipsARepeat(t *testing.T) {
	m := enter(typeIn(Model{}, "set follow"))
	m = enter(typeIn(m, "set follow"))
	if len(m.cmdHist) != 1 {
		t.Errorf("history = %v", m.cmdHist)
	}
}

func TestEscapeLeavesNoText(t *testing.T) {
	m := typeIn(Model{}, "set timeline")
	next, _ := m.Update(tea.KeyMsg{Type: tea.KeyEsc})
	m = next.(Model)
	if m.cmd || m.cmdText != "" {
		t.Errorf("cmd=%v text=%q", m.cmd, m.cmdText)
	}
}
