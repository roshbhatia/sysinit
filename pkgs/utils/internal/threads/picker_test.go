package threads

import (
	"strings"
	"testing"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/roshbhatia/go-utils/cell"
)

func key(m pickerModel, kind tea.KeyType, runes ...rune) pickerModel {
	next, _ := m.Update(tea.KeyMsg{Type: kind, Runes: runes})
	return next.(pickerModel)
}

func TestPickerInsertFirstNavigationAndFiltering(t *testing.T) {
	m := newPicker([]string{"alpha", "beta", "gamma"}, "thread> ")
	m = key(m, tea.KeyRunes, 'j')
	if m.input.Value() != "j" || len(m.matches) != 0 {
		t.Fatal("j should type in insert mode")
	}
	m = key(m, tea.KeyCtrlU)
	m = key(m, tea.KeyTab)
	if m.cursor != 1 {
		t.Fatal("Tab did not advance")
	}
	m = key(m, tea.KeyShiftTab)
	if m.cursor != 0 {
		t.Fatal("Shift-Tab did not return")
	}
	m = key(m, tea.KeyEsc)
	m = key(m, tea.KeyRunes, 'j')
	if m.inserting || m.cursor != 1 || m.input.Value() != "" {
		t.Fatal("normal j did not navigate")
	}
	m = key(m, tea.KeyRunes, 'k')
	if m.cursor != 0 {
		t.Fatal("normal k did not navigate")
	}
	m = key(m, tea.KeyRunes, 'i')
	m = key(m, tea.KeyRunes, 'b', 't', 'a')
	if !m.inserting || len(m.matches) != 1 || m.matches[0] != 1 {
		t.Fatal("Bubbles fuzzy filter did not match beta")
	}
	m = key(m, tea.KeyEnter)
	if m.selected != 1 || !m.done || m.View() != "" {
		t.Fatal("selection did not return the original index and clear the picker")
	}
}

func TestPickerCancelAndNoMatches(t *testing.T) {
	m := newPicker([]string{"alpha"}, "action> ")
	m = key(m, tea.KeyRunes, 'z')
	m = key(m, tea.KeyEnter)
	if m.done || !strings.Contains(m.View(), "No matches") {
		t.Fatal("empty search accepted a selection")
	}
	m = key(m, tea.KeyCtrlC)
	if !m.done || m.selected != -1 {
		t.Fatal("cancel selected an item")
	}
	m = newPicker([]string{"alpha"}, "action> ")
	m = key(key(m, tea.KeyEsc), tea.KeyEsc)
	if !m.done || m.selected != -1 {
		t.Fatal("normal Escape did not cancel")
	}
}

func TestPickerCoalescedNormalKeys(t *testing.T) {
	m := newPicker([]string{"alpha", "beta", "gamma"}, "action> ")
	m = key(m, tea.KeyEsc)
	m = key(m, tea.KeyRunes, 'j', 'j')
	if m.cursor != 2 {
		t.Fatal("coalesced j keys did not navigate twice")
	}
	m = key(m, tea.KeyRunes, 'k', 'i', 'b')
	if !m.inserting || m.input.Value() != "b" || len(m.matches) != 1 || m.matches[0] != 1 {
		t.Fatal("coalesced keys did not preserve navigation, mode switch, and typing")
	}
}

func TestPickerFitsInlineAndSanitizesLabels(t *testing.T) {
	for _, width := range []int{80, 21, 6} {
		for _, height := range []int{3, 4, 8, 20} {
			m := newPicker([]string{"wide 界 label\nwith\x1bcontrols", "second"}, "thread> ")
			next, _ := m.Update(tea.WindowSizeMsg{Width: width, Height: height})
			m = next.(pickerModel)
			if strings.ContainsAny(m.labels[0], "\n\x1b") {
				t.Fatal("unsanitized label")
			}
			lines := strings.Split(m.View(), "\n")
			if len(lines) > min(height, 8) {
				t.Fatalf("picker exceeds height %d: %d", height, len(lines))
			}
			for _, line := range lines {
				if cell.Width(line) > width {
					t.Fatalf("line exceeds width %d: %q", width, line)
				}
			}
		}
	}
}
