package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"slices"
	"strings"

	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/textarea"
	"github.com/charmbracelet/bubbles/textinput"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/roshbhatia/go-utils/cell"
	"github.com/roshbhatia/go-utils/terminal"
	"github.com/roshbhatia/go-utils/ui"
	"github.com/roshbhatia/sysinit/pkgs/internal/terminalprovider"
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
	showHelp, annotating             bool
	notes                            viewport.Model
	annotation                       textarea.Model
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
		if m.detail {
			m.updateDetails()
		}
		return m, nil
	case acted:
		m.busy, m.confirm = false, false
		if msg.err != nil {
			m.message = msg.err.Error()
			return m, nil
		}
		m.annotating = false
		m.message = ""
		m.busy = true
		return m, m.reload()
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
		m.input.Width = max(1, m.width-cell.Width(m.input.Prompt)-2)
		if m.detail {
			m.updateDetails()
		}
		if m.annotating {
			m.sizeAnnotation()
		}
	case tea.KeyMsg:
		pressed := msg.String()
		if pressed == "ctrl+c" {
			return m, tea.Quit
		}
		if terminal.IsControlReply(pressed) {
			return m, nil
		}
		if m.annotating {
			if m.busy {
				return m, nil
			}
			switch {
			case key.Matches(msg, cancel):
				m.annotating = false
				return m, nil
			case key.Matches(msg, save):
				if c := m.selection(); c != nil {
					if note := strings.TrimSpace(m.annotation.Value()); note != "" {
						return m.mutate(c.Task.UUID, "annotate", "--", note)
					}
				}
				return m, nil
			}
			var cmd tea.Cmd
			m.annotation, cmd = m.annotation.Update(msg)
			return m, cmd
		}
		if m.showHelp {
			if key.Matches(msg, helpKey, back) {
				m.showHelp = false
			} else if key.Matches(msg, quit) {
				return m, tea.Quit
			}
			return m, nil
		}
		if m.filtering {
			if key.Matches(msg, back, details) {
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
			if pressed == "y" {
				if c := m.selection(); c != nil {
					return m.mutate(c.Task.UUID, "done")
				}
			}
			return m, nil
		}
		if key.Matches(msg, quit) {
			return m, tea.Quit
		}
		if key.Matches(msg, helpKey) {
			m.showHelp = true
			return m, nil
		}
		if m.busy {
			return m, nil
		}
		if key.Matches(msg, refresh) {
			m.busy, m.message = true, ""
			return m, m.reload()
		}
		if key.Matches(msg, filter) && !m.detail {
			m.filtering = true
			return m, m.input.Focus()
		}
		if len(m.cursors) == 0 {
			return m, nil
		}
		if m.detail {
			switch {
			case key.Matches(msg, details, back):
				m.detail = false
				return m, nil
			case key.Matches(msg, scroll):
				var cmd tea.Cmd
				m.notes, cmd = m.notes.Update(msg)
				return m, cmd
			}
		} else {
			switch action, _ := ui.ActionFor(ui.Key{Name: pressed}); action {
			case ui.ActionLeft:
				m.column = max(0, m.column-1)
			case ui.ActionRight:
				m.column = min(len(m.cursors)-1, m.column+1)
			case ui.ActionUp:
				m.cursors[m.column] = max(0, m.cursors[m.column]-1)
			case ui.ActionDown:
				m.cursors[m.column] = min(max(0, len(m.cards(m.column))-1), m.cursors[m.column]+1)
			case ui.ActionOpen:
				if m.selection() != nil {
					m.detail = true
					m.updateDetails()
					m.notes.GotoTop()
				}
			case ui.ActionBack:
				m.detail = false
				m.input.Reset()
			}
		}
		c := m.selection()
		if c == nil {
			return m, nil
		}
		switch {
		case key.Matches(msg, note):
			m.annotation = textarea.New()
			m.annotation.Placeholder = "Record a question, answer, or verification"
			m.annotation.ShowLineNumbers = false
			m.annotation.FocusedStyle.CursorLine = m.annotation.FocusedStyle.Text
			m.annotation.FocusedStyle.Prompt = accent
			m.annotation.FocusedStyle.Placeholder = muted
			m.annotating = true
			m.sizeAnnotation()
			return m, m.annotation.Focus()
		case key.Matches(msg, start):
			if c.Task.Start == "" {
				return m.mutate(c.Task.UUID, "start")
			}
			return m.mutate(c.Task.UUID, "stop")
		case key.Matches(msg, block):
			if slices.Contains(c.Task.Tags, "blocked") {
				return m.mutate(c.Task.UUID, "modify", "-blocked")
			}
			return m.mutate(c.Task.UUID, "modify", "+blocked", "-review")
		case key.Matches(msg, review):
			if slices.Contains(c.Task.Tags, "review") {
				return m.mutate(c.Task.UUID, "modify", "-review")
			}
			if m.board.Lanes[m.column].Name == "Blocked / Waiting" {
				m.message = "Resolve the blocker before marking work ready for review."
				return m, nil
			}
			return m.mutate(c.Task.UUID, "modify", "+review")
		case key.Matches(msg, diff):
			dir, err := c.reviewDirectory()
			if err != nil {
				m.message = err.Error()
				return m, nil
			}
			path := os.Getenv(terminalprovider.Selection)
			if path == "" {
				m.message = "Configure a terminal provider to open a review."
				return m, nil
			}
			m.busy = true
			return m, func() tea.Msg {
				manifest, err := terminalprovider.Open(path)
				if err == nil {
					err = terminalprovider.Invoke(manifest, c.Task.UUID, "review", map[string]string{"cwd": dir}, nil)
				}
				return acted{err}
			}
		case key.Matches(msg, complete):
			if c.Task.LinearID != "" {
				m.message = "Complete this imported task in Linear."
			} else {
				m.confirm = true
			}
		case key.Matches(msg, workspaceKey):
			if len(c.Workspaces) != 1 {
				m.message = "Select a task with exactly one linked workspace."
				return m, nil
			}
			return m, tea.ExecProcess(exec.Command("agent-workspace", "resume", c.Workspaces[0].ID), func(err error) tea.Msg { return acted{err} })
		case key.Matches(msg, logs):
			if c.Attempt == nil || c.Attempt.PueueID == nil {
				m.message = "This task has no linked Pueue job."
				return m, nil
			}
			return m, tea.ExecProcess(exec.Command("task-queue", "logs", c.Attempt.ID, "--pager"), func(err error) tea.Msg { return acted{err} })
		}
	}
	if m.annotating {
		var cmd tea.Cmd
		m.annotation, cmd = m.annotation.Update(message)
		return m, cmd
	}
	if m.filtering {
		var cmd tea.Cmd
		m.input, cmd = m.input.Update(message)
		return m, cmd
	}
	return m, nil
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
	_, err := tea.NewProgram(model{filters: selected, input: input, notes: viewport.New(80, 20), width: 80, height: 24, busy: true}, tea.WithAltScreen()).Run()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
