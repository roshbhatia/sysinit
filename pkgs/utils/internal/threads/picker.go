package threads

import (
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/roshbhatia/go-utils/cell"
	"github.com/roshbhatia/go-utils/terminal"
	"github.com/roshbhatia/go-utils/ui"
)

type pickerModel struct {
	labels    []string
	prompt    string
	input     textinput.Model
	matches   []int
	cursor    int
	selected  int
	width     int
	height    int
	inserting bool
	done      bool
}

func newPicker(labels []string, prompt string) pickerModel {
	input := textinput.New()
	input.Prompt = prompt
	input.CharLimit = 256
	input.Focus()
	m := pickerModel{prompt: prompt, input: input, selected: -1, width: 80, height: 8, inserting: true}
	for _, label := range labels {
		m.labels = append(m.labels, strings.Map(func(r rune) rune {
			if r < 32 || r == 127 {
				return ' '
			}
			return r
		}, label))
	}
	m.filter()
	return m
}

func (m *pickerModel) filter() {
	m.matches = nil
	if m.input.Value() == "" {
		for i := range m.labels {
			m.matches = append(m.matches, i)
		}
	} else {
		for _, match := range list.DefaultFilter(m.input.Value(), m.labels) {
			m.matches = append(m.matches, match.Index)
		}
	}
	m.cursor = 0
}

func (m pickerModel) Init() tea.Cmd { return textinput.Blink }

func (m pickerModel) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := message.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = max(1, msg.Width), max(1, min(8, msg.Height))
		m.input.Width = max(1, m.width-cell.Width(m.prompt)-1)
		return m, nil
	case tea.KeyMsg:
		if !m.inserting && msg.Type == tea.KeyRunes && len(msg.Runes) > 1 {
			var commands []tea.Cmd
			for _, r := range msg.Runes {
				next, cmd := m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{r}})
				m = next.(pickerModel)
				commands = append(commands, cmd)
				if m.done {
					break
				}
			}
			return m, tea.Batch(commands...)
		}
		key := msg.String()
		if terminal.IsControlReply(key) {
			return m, nil
		}
		switch key {
		case "ctrl+c", "ctrl+g":
			m.done = true
			return m, tea.Quit
		case "enter":
			if len(m.matches) > 0 && m.height >= 4 {
				m.selected, m.done = m.matches[m.cursor], true
				return m, tea.Quit
			}
			return m, nil
		case "tab", "down", "ctrl+j", "ctrl+n":
			m.cursor = min(m.cursor+1, max(0, len(m.matches)-1))
			return m, nil
		case "shift+tab", "up", "ctrl+k", "ctrl+p":
			m.cursor = max(0, m.cursor-1)
			return m, nil
		case "esc":
			if !m.inserting {
				m.done = true
				return m, tea.Quit
			}
			m.inserting = false
			m.input.Blur()
			return m, nil
		}
		if !m.inserting {
			if key == "i" || key == "/" {
				m.inserting = true
				return m, m.input.Focus()
			}
			if action, ok := ui.ActionFor(ui.Key{Name: key}); ok {
				switch action {
				case ui.ActionDown:
					m.cursor = min(m.cursor+1, max(0, len(m.matches)-1))
				case ui.ActionUp:
					m.cursor = max(0, m.cursor-1)
				case ui.ActionQuit:
					m.done = true
					return m, tea.Quit
				}
			}
			return m, nil
		}
	}
	before := m.input.Value()
	var cmd tea.Cmd
	m.input, cmd = m.input.Update(message)
	if before != m.input.Value() {
		m.filter()
	}
	return m, cmd
}

func (m pickerModel) View() string {
	if m.done {
		return ""
	}
	if m.height < 4 {
		return cell.Truncate("Picker needs 4 rows. Ctrl-C cancels.", m.width)
	}
	palette := ui.TerminalPalette()
	accent := lipgloss.NewStyle().Foreground(lipgloss.Color(palette.Accent)).Bold(true)
	muted := lipgloss.NewStyle().Foreground(lipgloss.Color(palette.Muted))
	rows := m.height - 3
	start := max(0, m.cursor-rows+1)
	lines := []string{muted.Render(cell.Truncate(fmt.Sprintf("%s · %d/%d", strings.TrimSuffix(m.prompt, "> "), len(m.matches), len(m.labels)), m.width))}
	for offset := range rows {
		index := start + offset
		line := ""
		if index < len(m.matches) {
			line = cell.Truncate("  "+m.labels[m.matches[index]], m.width)
			if index == m.cursor {
				line = accent.Render(cell.Truncate("> "+m.labels[m.matches[index]], m.width))
			}
		} else if offset == 0 {
			line = muted.Render(cell.Truncate("  No matches", m.width))
		}
		lines = append(lines, line)
	}
	mode, hint := "INSERT", "Tab/Shift-Tab move · Enter choose · Esc normal · Ctrl-C cancel"
	if !m.inserting {
		mode, hint = "NORMAL", "j/k move · i or / search · Enter choose · Esc cancel"
	}
	lines = append(lines, cell.Truncate(m.input.View(), m.width), muted.Render(cell.Truncate(mode+" · "+hint, m.width)))
	return strings.Join(lines, "\n")
}

func pick(labels []string, prompt string) (int, error) {
	if !terminal.IsTTY(os.Stderr) {
		return -1, errors.New("the thread picker needs a terminal; use threads list --style json for structured output")
	}
	result, err := tea.NewProgram(newPicker(labels, prompt), tea.WithInputTTY(), tea.WithOutput(os.Stderr)).Run()
	if err != nil {
		return -1, err
	}
	return result.(pickerModel).selected, nil
}
