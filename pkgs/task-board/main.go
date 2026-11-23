package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"unicode"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/roshbhatia/go-utils/cell"
	"github.com/roshbhatia/go-utils/ui"
)

type loaded struct {
	board board
	err   error
}
type acted struct{ err error }

type model struct {
	filters                          filters
	board                            board
	input                            textinput.Model
	filtering, detail, confirm, busy bool
	column, width, height            int
	cursors                          []int
	message                          string
}

func (m model) Init() tea.Cmd { return m.reload() }

func (m model) reload() tea.Cmd {
	return func() tea.Msg {
		data, err := m.filters.collect()
		return loaded{data, err}
	}
}

func (m model) cards(index int) []card {
	if index >= len(m.board.Lanes) {
		return nil
	}
	query := strings.ToLower(strings.TrimSpace(m.input.Value()))
	list := m.board.Lanes[index].Cards
	if query == "" {
		return list
	}
	var result []card
	for _, c := range list {
		haystack := strings.ToLower(strings.Join([]string{c.Task.Description, c.Task.Project, c.Task.UUID, strings.Join(c.Task.Tags, " ")}, " "))
		if strings.Contains(haystack, query) {
			result = append(result, c)
		}
	}
	return result
}

func (m model) selection() *card {
	if m.column >= len(m.cursors) {
		return nil
	}
	cards := m.cards(m.column)
	if len(cards) == 0 {
		return nil
	}
	return &cards[min(m.cursors[m.column], len(cards)-1)]
}

func (m model) mutate(id string, args ...string) (tea.Model, tea.Cmd) {
	m.busy = true
	command := append(append(m.filters.taskArgs(), "rc.confirmation:no", id), args...)
	return m, func() tea.Msg {
		_, _, err := runCommand("taskwarrior", command...)
		return acted{err}
	}
}

func (m model) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := message.(type) {
	case loaded:
		m.busy = false
		if msg.err != nil {
			m.message = msg.err.Error()
			return m, nil
		}
		m.board = msg.board
		if len(m.cursors) != len(m.board.Lanes) {
			m.cursors = make([]int, len(m.board.Lanes))
		}
		for i := range m.cursors {
			m.cursors[i] = min(m.cursors[i], max(0, len(m.cards(i))-1))
		}
		return m, nil
	case acted:
		m.busy, m.confirm = false, false
		if msg.err != nil {
			m.message = msg.err.Error()
			return m, nil
		}
		m.message = ""
		m.busy = true
		return m, m.reload()
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
	case tea.KeyMsg:
		key := msg.String()
		if key == "ctrl+c" {
			return m, tea.Quit
		}
		if m.filtering {
			if key == "esc" || key == "enter" {
				m.filtering = false
				m.input.Blur()
				return m, nil
			}
			var cmd tea.Cmd
			m.input, cmd = m.input.Update(msg)
			clear(m.cursors)
			return m, cmd
		}
		if m.confirm {
			m.confirm = false
			if key == "y" {
				if c := m.selection(); c != nil {
					return m.mutate(c.Task.UUID, "done")
				}
			}
			return m, nil
		}
		if key == "q" {
			return m, tea.Quit
		}
		if m.busy {
			return m, nil
		}
		if key == "r" {
			m.busy, m.message = true, ""
			return m, m.reload()
		}
		if key == "/" {
			m.filtering = true
			return m, m.input.Focus()
		}
		if len(m.cursors) == 0 {
			return m, nil
		}
		switch action, _ := ui.ActionFor(ui.Key{Name: key}); action {
		case ui.ActionLeft:
			m.column = max(0, m.column-1)
		case ui.ActionRight:
			m.column = min(len(m.cursors)-1, m.column+1)
		case ui.ActionUp:
			m.cursors[m.column] = max(0, m.cursors[m.column]-1)
		case ui.ActionDown:
			m.cursors[m.column] = min(max(0, len(m.cards(m.column))-1), m.cursors[m.column]+1)
		case ui.ActionOpen:
			m.detail = !m.detail
		case ui.ActionBack:
			m.detail = false
			m.input.Reset()
		}
		c := m.selection()
		if c == nil {
			return m, nil
		}
		switch key {
		case "s":
			if c.Task.Start == "" {
				return m.mutate(c.Task.UUID, "start")
			}
			return m.mutate(c.Task.UUID, "stop")
		case "b":
			tag := "+blocked"
			for _, current := range c.Task.Tags {
				if current == "blocked" {
					tag = "-blocked"
				}
			}
			return m.mutate(c.Task.UUID, "modify", tag)
		case "d":
			if c.Task.LinearID != "" {
				m.message = "Complete this imported task in Linear."
			} else {
				m.confirm = true
			}
		case "w":
			if len(c.Workspaces) != 1 {
				m.message = "Select a task with exactly one linked workspace."
				return m, nil
			}
			return m, tea.ExecProcess(exec.Command("agent-workspace", "resume", c.Workspaces[0].ID), func(err error) tea.Msg { return acted{err} })
		case "o":
			if c.Attempt == nil || c.Attempt.PueueID == nil {
				m.message = "This task has no linked Pueue job."
				return m, nil
			}
			return m, tea.ExecProcess(exec.Command("tq", "logs", c.Attempt.ID, "--pager"), func(err error) tea.Msg { return acted{err} })
		}
	}
	return m, nil
}

func clean(text string) string {
	return strings.Map(func(r rune) rune {
		if unicode.IsControl(r) {
			return ' '
		}
		return r
	}, text)
}

func (m model) View() string {
	if len(m.board.Lanes) == 0 {
		if m.message != "" {
			return clean(m.message) + "\nr retry  q quit"
		}
		return "Loading tasks…  q quit"
	}
	if m.width < 2 {
		return ""
	}
	title := cell.Truncate("Tasks · "+clean(m.board.Scope), m.width)
	visible := []int{m.column}
	width := m.width
	if m.width >= 100 {
		visible = make([]int, len(m.board.Lanes))
		for i := range visible {
			visible[i] = i
		}
		width = (m.width - len(visible) + 1) / len(visible)
	}
	rows := max(1, m.height-9)
	if m.detail {
		rows = max(1, rows-4)
	}
	var columns []string
	for _, i := range visible {
		cards := m.cards(i)
		head := fmt.Sprintf("%s (%d)", m.board.Lanes[i].Name, len(cards))
		heading := lipgloss.NewStyle().Bold(true)
		if i == m.column {
			heading = heading.Foreground(lipgloss.Color("12"))
		}
		lines := []string{heading.Render(cell.Truncate(head, width))}
		cursor := m.cursors[i]
		begin := max(0, cursor-rows+1)
		for j := begin; j < min(len(cards), begin+rows); j++ {
			c := cards[j]
			label := clean(c.Task.Description)
			if len(c.Workspaces) > 0 {
				label = "[W] " + label
			}
			if c.Attempt != nil {
				label = "[Q] " + label
			}
			label = cell.Truncate(label, width)
			if i == m.column && j == cursor {
				label = lipgloss.NewStyle().Reverse(true).Render(label)
			}
			lines = append(lines, label)
		}
		columns = append(columns, lipgloss.NewStyle().Width(width).Render(strings.Join(lines, "\n")))
		if i != visible[len(visible)-1] {
			columns = append(columns, " ")
		}
	}
	lines := []string{title, "", lipgloss.JoinHorizontal(lipgloss.Top, columns...)}
	if m.filtering || m.input.Value() != "" {
		lines = append(lines, m.input.View())
	}
	if c := m.selection(); m.detail && c != nil {
		lines = append(lines, "", clean(c.Task.Description), clean(c.Task.Project+"  "+c.Task.UUID))
		if c.Attempt != nil {
			lines = append(lines, "Attempt "+clean(c.Attempt.ID)+"  "+clean(string(c.Attempt.Result)))
		}
	}
	for _, warning := range m.board.Errors {
		lines = append(lines, cell.Truncate(clean(warning), m.width))
	}
	if m.message != "" {
		lines = append(lines, cell.Truncate(clean(m.message), m.width))
	}
	if m.confirm {
		lines = append(lines, "Complete selected task? y confirm  Esc cancel")
	}
	lines = append(lines, cell.Truncate("h/l columns  j/k cards  / filter  Enter details  s start/stop  b block  w workspace  o logs  d done  r refresh  q quit", m.width))
	return strings.Join(lines, "\n")
}

func main() {
	var selected filters
	flag.StringVar(&selected.Context, "context", "", "Taskwarrior context for this invocation")
	flag.StringVar(&selected.Project, "project", "", "Taskwarrior project")
	flag.StringVar(&selected.Repo, "repo", "", "Taskwarrior repo field")
	flag.BoolVar(&selected.All, "all", false, "Use the context without inferring the current repository")
	flag.BoolVar(&selected.Workspaces, "workspaces", false, "Include links from agent-workspace")
	output := flag.Bool("json", false, "Write the board as JSON")
	flag.Parse()
	selected.Terms = flag.Args()
	if *output {
		data, err := selected.collect()
		if err == nil {
			err = json.NewEncoder(os.Stdout).Encode(data)
		}
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		return
	}
	input := textinput.New()
	input.Prompt = "/ "
	input.CharLimit = 120
	_, err := tea.NewProgram(model{filters: selected, input: input, width: 80, height: 24, busy: true}, tea.WithAltScreen()).Run()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
