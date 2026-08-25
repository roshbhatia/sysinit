package ui

import (
	"regexp"
	"strings"
	"testing"

	tea "github.com/charmbracelet/bubbletea"
)

var escapes = regexp.MustCompile(`\x1b\[[0-9;]*m`)

// plain2 drops the styling, so a test asserts what a reader sees rather than how
// it was coloured.
func plain2(s string) string { return escapes.ReplaceAllString(s, "") }

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

// "se" is the case completion exists for: two names share it, and the first
// version refused to complete at all there.
func TestTabCyclesAnAmbiguousPrefix(t *testing.T) {
	m := typeIn(Model{}, "se")
	seen := []string{}
	for range 3 {
		next, _ := m.Update(tea.KeyMsg{Type: tea.KeyTab})
		m = next.(Model)
		seen = append(seen, strings.TrimSpace(m.cmdText))
	}
	if seen[0] != "session" && seen[0] != "set" {
		t.Fatalf("first tab = %q", seen[0])
	}
	if seen[1] == seen[0] {
		t.Errorf("second tab did not move: %v", seen)
	}
	// Three presses over two candidates comes back to the first.
	if seen[2] != seen[0] {
		t.Errorf("cycle did not wrap: %v", seen)
	}
}

// A prefix every candidate shares is free progress, so tab takes it.
func TestTabGrowsToTheSharedPrefix(t *testing.T) {
	m := typeIn(Model{}, "v")
	next, _ := m.Update(tea.KeyMsg{Type: tea.KeyTab})
	if got := next.(Model).cmdText; got != "vsplit" {
		t.Errorf("completion = %q", got)
	}
}

func TestTypingClearsTheCycle(t *testing.T) {
	m := typeIn(Model{}, "se")
	next, _ := m.Update(tea.KeyMsg{Type: tea.KeyTab})
	m = next.(Model)
	if len(m.cmdCands) < 2 {
		t.Fatalf("no cycle opened: %v", m.cmdCands)
	}
	m = typeIn(m, "t")
	if m.cmdCands != nil {
		t.Errorf("cycle survived a keystroke: %v", m.cmdCands)
	}
}

func TestSharedPrefix(t *testing.T) {
	for _, one := range []struct {
		in   []string
		want string
	}{
		{[]string{"set", "session"}, "se"},
		{[]string{"split"}, "split"},
		{[]string{"split", "session", "set"}, "s"},
		{nil, ""},
	} {
		if got := shared(one.in); got != one.want {
			t.Errorf("shared(%v) = %q, want %q", one.in, got, one.want)
		}
	}
}

// The bar has to show where a prefix is going before the reader commits.
func TestBarShowsTheGhost(t *testing.T) {
	m := typeIn(Model{width: 120}, "vs")
	bar := plain2(m.commandBar(120))
	if !strings.Contains(bar, "plit") {
		t.Errorf("no ghost in %q", bar)
	}
	if !strings.Contains(bar, "inspector down the right") {
		t.Errorf("no help in %q", bar)
	}
}

func TestBarListsSeveralCandidates(t *testing.T) {
	m := typeIn(Model{width: 120}, "s")
	// The typed part is highlighted apart from the rest, so each name arrives as
	// two styled runs and no name is contiguous in the raw bytes.
	bar := plain2(m.commandBar(120))
	for _, want := range []string{"set", "session", "split"} {
		if !strings.Contains(bar, want) {
			t.Errorf("%q missing from %q", want, bar)
		}
	}
}
