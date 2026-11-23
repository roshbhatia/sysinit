package picker

import (
	"errors"
	"fmt"
	"os"
	"strings"
	"unicode"

	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/roshbhatia/go-utils/cell"
	"github.com/roshbhatia/go-utils/terminal"
	"github.com/roshbhatia/go-utils/ui"
)

type pickerModel struct {
	items     []Item
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

// Item keeps the primary label and optional searchable detail separate.
type Item struct {
	Title  string
	Detail string
}

func Items(labels []string) []Item {
	items := make([]Item, len(labels))
	for i, label := range labels {
		items[i].Title = label
	}
	return items
}

func oneLine(value string) string {
	return strings.Map(func(r rune) rune {
		if unicode.IsControl(r) {
			return ' '
		}
		return r
	}, value)
}

func newPicker(items []Item, prompt string) pickerModel {
	input := textinput.New()
	input.Prompt = prompt
	input.CharLimit = 256
	input.Focus()
	m := pickerModel{prompt: prompt, input: input, selected: -1, width: 80, height: 8, inserting: true}
	for _, item := range items {
		item.Title, item.Detail = oneLine(item.Title), oneLine(item.Detail)
		m.items = append(m.items, item)
		m.labels = append(m.labels, strings.TrimSpace(item.Title+" "+item.Detail))
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
	title := lipgloss.NewStyle().Foreground(lipgloss.Color(palette.Title)).Bold(true)
	rows := m.height - 3
	start := max(0, m.cursor-rows+1)
	lines := []string{title.Render(cell.Truncate(fmt.Sprintf("%s · %d/%d", strings.TrimSuffix(m.prompt, "> "), len(m.matches), len(m.items)), m.width))}
	for offset := range rows {
		index := start + offset
		line := ""
		if index < len(m.matches) {
			item := m.items[m.matches[index]]
			style := lipgloss.NewStyle()
			prefix := "  "
			if index == m.cursor {
				prefix, style = "> ", accent
			}
			labelWidth := m.width
			detail := ""
			if item.Detail != "" && m.width >= 28 {
				detail = "  " + cell.Truncate(item.Detail, m.width/3)
				labelWidth -= cell.Width(detail)
			}
			line = style.Render(cell.Truncate(prefix+item.Title, labelWidth)) + muted.Render(detail)
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

// Pick displays an inline, searchable list without replacing the caller's screen.
func Pick(items []Item, prompt string, inserting bool) (int, error) {
	if !terminal.IsTTY(os.Stderr) {
		return -1, errors.New("the picker needs a terminal; use the command's structured output instead")
	}
	model := newPicker(items, prompt)
	model.inserting = inserting
	if !inserting {
		model.input.Blur()
	}
	result, err := tea.NewProgram(model, tea.WithInputTTY(), tea.WithOutput(os.Stderr)).Run()
	if err != nil {
		return -1, err
	}
	return result.(pickerModel).selected, nil
}
