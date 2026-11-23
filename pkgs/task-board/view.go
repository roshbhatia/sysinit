package main

import (
	"encoding/json"
	"fmt"
	"strings"
	"unicode"

	"github.com/charmbracelet/bubbles/help"
	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/x/ansi"
	"github.com/roshbhatia/go-utils/cell"
	"github.com/roshbhatia/go-utils/ui"
)

const (
	minLaneWidth = 40
	laneGap      = 2
)

var (
	palette = ui.TerminalPalette()
	accent  = lipgloss.NewStyle().Foreground(lipgloss.Color(palette.Accent)).Bold(true)
	title   = lipgloss.NewStyle().Foreground(lipgloss.Color(palette.Title)).Bold(true)
	muted   = lipgloss.NewStyle().Foreground(lipgloss.Color(palette.Muted))
	warning = lipgloss.NewStyle().Foreground(lipgloss.Color(palette.Warning))

	navigate     = binding("h/l", "lanes", "h", "l", "left", "right")
	move         = binding("j/k", "move", "j", "k", "down", "up")
	filter       = binding("/", "filter")
	details      = binding("enter", "details")
	back         = binding("esc", "back")
	scroll       = binding("j/k", "scroll", "j", "k", "up", "down", "pgup", "pgdown", "ctrl+u", "ctrl+d")
	diff         = binding("f", "diff")
	note         = binding("a", "annotate")
	review       = binding("v", "review")
	block        = binding("b", "block")
	start        = binding("s", "start/stop")
	workspaceKey = binding("w", "workspace")
	logs         = binding("o", "logs")
	complete     = binding("d", "complete")
	refresh      = binding("r", "refresh")
	quit         = binding("q", "quit")
	helpKey      = binding("?", "keys")
	save         = binding("ctrl+s", "save")
	cancel       = binding("esc", "cancel")
)

func binding(hint, description string, keys ...string) key.Binding {
	if len(keys) == 0 {
		keys = []string{hint}
	}
	return key.NewBinding(key.WithKeys(keys...), key.WithHelp(hint, description))
}

func clean(text string) string {
	return strings.Map(func(r rune) rune {
		if unicode.IsControl(r) {
			return ' '
		}
		return r
	}, ansi.Strip(text))
}

func laneRange(width, current, total int) (first, last, laneWidth int) {
	count := min(total, max(1, (width+laneGap)/(minLaneWidth+laneGap)))
	first = min(max(0, current-count/2), total-count)
	return first, first + count, (width - (count-1)*laneGap) / count
}

func attemptStatus(a *attempt) string {
	var status string
	if json.Unmarshal(a.Result, &status) == nil && status != "" {
		return status
	}
	var result map[string]json.RawMessage
	if json.Unmarshal(a.Result, &result) != nil || len(result) != 1 {
		return "Unknown"
	}
	for state, detail := range result {
		if state != "Done" {
			return state
		}
		if a.Review {
			return "Succeeded"
		}
		var finished struct {
			Result json.RawMessage `json:"result"`
		}
		if json.Unmarshal(detail, &finished) == nil {
			var reason string
			if json.Unmarshal(finished.Result, &reason) == nil && reason != "" {
				return reason
			}
			var result map[string]json.RawMessage
			if json.Unmarshal(finished.Result, &result) == nil && len(result) == 1 {
				for reason := range result {
					return reason
				}
			}
		}
		return "Finished"
	}
	return "Unknown"
}

func cardView(c card, width, height int, selected bool) []string {
	indent := strings.Repeat(" ", min(2, width-1))
	marker, style := indent, lipgloss.NewStyle()
	if selected && width > 2 {
		marker, style = "> ", accent
	}
	textWidth := width - len(indent)
	titleRows := 1
	if height == 4 {
		titleRows = 2
	}
	wrapped := strings.SplitN(ansi.Wrap(clean(c.Task.Description), textWidth, ""), "\n", titleRows+1)
	if len(wrapped) > titleRows {
		wrapped[titleRows-1] = cell.Truncate(strings.Join(wrapped[titleRows-1:], " "), textWidth)
		wrapped = wrapped[:titleRows]
	}
	lines := make([]string, height)
	for i, line := range wrapped {
		prefix := indent
		if i == 0 {
			prefix = marker
		}
		lines[i] = style.Render(prefix + cell.Truncate(line, textWidth))
	}
	if len(wrapped) < height {
		var metadata []string
		if c.Task.Project != "" {
			metadata = append(metadata, clean(c.Task.Project))
		}
		if c.Attempt != nil {
			metadata = append(metadata, clean(attemptStatus(c.Attempt)))
		}
		if len(metadata) > 0 {
			lines[len(wrapped)] = muted.Render(indent + cell.Truncate(strings.Join(metadata, " · "), textWidth))
		}
	}
	return lines
}

func (m model) laneView(index, width, height int) string {
	cards := m.cards(index)
	name := m.board.Lanes[index].Name
	heading := title
	marker := "  "
	if index == m.column {
		heading, marker = accent, "> "
	}
	lines := []string{
		heading.Render(cell.Truncate(fmt.Sprintf("%s%s (%d)", marker, name, len(cards)), width)),
		muted.Render(strings.Repeat("─", width)),
	}
	rows := max(0, height-len(lines))
	cardHeight := min(2, max(1, rows))
	if rows >= 8 {
		cardHeight = 4
	}
	visible := rows / cardHeight
	cursor := m.cursors[index]
	start := max(0, cursor-visible+1)
	for i := start; i < min(len(cards), start+visible); i++ {
		lines = append(lines, cardView(cards[i], width, cardHeight, index == m.column && i == cursor)...)
	}
	if len(cards) == 0 && rows > 0 {
		lines = append(lines, muted.Render(cell.Truncate("  No tasks", width)))
	}
	return lipgloss.NewStyle().Width(width).Render(strings.Join(lines, "\n"))
}

func (m *model) updateDetails() {
	c := m.selection()
	if c == nil {
		m.detail = false
		return
	}
	width := max(1, m.width-2)
	m.notes.Width = width
	m.notes.Height = max(1, m.height-4)
	lines := []string{title.Render(clean(c.Task.Description))}
	if c.Task.Project != "" {
		lines = append(lines, clean(c.Task.Project))
	}
	lines = append(lines, muted.Render(c.Task.UUID))
	if c.Attempt != nil {
		lines = append(lines, "Run: "+clean(attemptStatus(c.Attempt))+"  "+muted.Render(c.Attempt.ID))
	}
	lines = append(lines, "", title.Render("Handoff"))
	if len(c.Task.Annotations) == 0 {
		lines = append(lines, muted.Render("No annotations"))
	}
	for _, annotation := range c.Task.Annotations {
		for _, line := range strings.Split(annotation.Description, "\n") {
			lines = append(lines, clean(line))
		}
		lines = append(lines, "")
	}
	m.notes.SetContent(lipgloss.NewStyle().Width(width).Render(strings.Join(lines, "\n")))
}

func (m *model) sizeAnnotation() {
	m.annotation.SetWidth(max(1, m.width-4))
	m.annotation.SetHeight(max(1, min(8, m.height-5)))
}

func (m model) View() string {
	if m.width < 2 || m.height < 2 {
		return ""
	}
	if m.height < 7 {
		return cell.Truncate("Needs seven rows. Ctrl-C quits.", m.width)
	}
	hints := help.New()
	hints.Width = m.width
	hints.Styles.ShortKey = accent
	hints.Styles.ShortDesc = lipgloss.NewStyle()
	hints.ShortSeparator = "  "
	if m.showHelp {
		groups := [][]key.Binding{{navigate, move, filter, details, refresh, quit}, {diff, note, review}, {start, block, complete}, {workspaceKey, logs}}
		var lines []string
		for _, group := range groups {
			lines = append(lines, hints.ShortHelpView(group))
		}
		return strings.Join(append(lines, hints.ShortHelpView([]key.Binding{back})), "\n")
	}
	if m.annotating {
		lines := []string{title.Render("Task annotation"), m.annotation.View(), hints.ShortHelpView([]key.Binding{save, cancel})}
		if m.message != "" {
			lines = append(lines, warning.Render(cell.Truncate(clean(m.message), m.width)))
		}
		return strings.Join(lines, "\n")
	}
	header := cell.Truncate("Tasks · "+clean(m.board.Scope), m.width)
	var content string
	var notices []string
	if m.message != "" {
		notices = append(notices, warning.Render(cell.Truncate(clean(m.message), m.width)))
	} else if len(m.board.Errors) > 0 {
		notices = append(notices, warning.Render(cell.Truncate(clean(strings.Join(m.board.Errors, " · ")), m.width)))
	}
	if m.confirm {
		notices = append(notices, cell.Truncate("Complete selected task? y confirm  Esc cancel", m.width))
	}
	if len(m.board.Lanes) > 0 && !m.detail && (m.filtering || m.input.Value() != "") {
		notices = append(notices, m.input.View())
	}
	bodyHeight := m.height - 3 - len(notices)
	bindings := []key.Binding{helpKey, navigate, move, filter, details, diff, note, quit}
	switch {
	case len(m.board.Lanes) == 0:
		header = "Tasks"
		if m.message == "" {
			content = "Loading tasks…"
		}
		bindings = []key.Binding{refresh, quit}
	case m.detail:
		notes := m.notes
		notes.Height = bodyHeight
		content = notes.View()
		bindings = []key.Binding{helpKey, back, scroll, diff, note, review}
		if c := m.selection(); c != nil && c.Attempt != nil && c.Attempt.PueueID != nil {
			bindings = append(bindings, logs)
		}
	default:
		first, last, width := laneRange(m.width, m.column, len(m.board.Lanes))
		if last-first < len(m.board.Lanes) {
			header = cell.Truncate(
				fmt.Sprintf("Tasks · Lanes %d–%d of %d · %s", first+1, last, len(m.board.Lanes), clean(m.board.Scope)),
				m.width,
			)
		}
		extra := m.width - (last-first)*width - (last-first-1)*laneGap
		var columns []string
		for index := first; index < last; index++ {
			laneWidth := width
			if index-first < extra {
				laneWidth++
			}
			columns = append(columns, m.laneView(index, laneWidth, bodyHeight))
			if index+1 < last {
				columns = append(columns, strings.Repeat(" ", laneGap))
			}
		}
		content = lipgloss.JoinHorizontal(lipgloss.Top, columns...)
	}
	content = lipgloss.NewStyle().Height(bodyHeight).MaxHeight(bodyHeight).Render(content)
	lines := append([]string{title.Render(header), "", content}, notices...)
	return strings.Join(append(lines, hints.ShortHelpView(bindings)), "\n")
}
