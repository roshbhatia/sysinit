package main

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/instance"
	"github.com/roshbhatia/sysinit/pkgs/internal/agents"
)

type orcaActionMessage struct {
	text string
	err  error
}

type orcaUIModel struct {
	record   instance.Record
	active   bool
	agents   []agents.Agent
	cursor   int
	message  string
	selected string
}

var (
	orcaTitleStyle    = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("5"))
	orcaActiveStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("2"))
	orcaInactiveStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("8"))
	orcaCursorStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("4"))
)

func runOrcaUI(stdout io.Writer, stderr io.Writer) int {
	model, err := newOrcaUIModel()
	if err != nil {
		fmt.Fprintf(stderr, "open UI: %v\n", err)
		return 1
	}
	program := tea.NewProgram(model, tea.WithInput(os.Stdin), tea.WithOutput(stdout))
	result, err := program.Run()
	if err != nil {
		fmt.Fprintf(stderr, "run UI: %v\n", err)
		return 1
	}
	finished, ok := result.(orcaUIModel)
	if ok && finished.selected != "" {
		return runOrcaAgent([]string{finished.selected}, stderr)
	}
	return 0
}

func newOrcaUIModel() (orcaUIModel, error) {
	model := orcaUIModel{}
	if err := model.refresh(); err != nil {
		return model, err
	}
	registry, err := agents.Load()
	if err != nil {
		return model, err
	}
	for _, agent := range registry.Agents {
		if agent.Command == "" {
			continue
		}
		if _, err := exec.LookPath(agent.Command); err == nil {
			model.agents = append(model.agents, agent)
		}
	}
	return model, nil
}

func (model orcaUIModel) Init() tea.Cmd {
	return nil
}

func (model orcaUIModel) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch typed := message.(type) {
	case orcaActionMessage:
		if typed.err != nil {
			model.message = typed.err.Error()
		} else {
			model.message = typed.text
		}
		_ = model.refresh()
	case tea.KeyMsg:
		switch typed.String() {
		case "q", "ctrl+c":
			return model, tea.Quit
		case "up", "k":
			if model.cursor > 0 {
				model.cursor--
			}
		case "down", "j":
			if model.cursor+1 < len(model.agents) {
				model.cursor++
			}
		case "r":
			if err := model.refresh(); err != nil {
				model.message = err.Error()
			}
		case "s":
			active := model.active
			return model, func() tea.Msg {
				var stdout, stderr bytes.Buffer
				var code int
				if active {
					code = runOrcaStop(nil, &stdout, &stderr)
				} else {
					code = runOrcaStart(nil, &stdout, &stderr)
				}
				text := strings.TrimSpace(stdout.String())
				if code != 0 {
					return orcaActionMessage{err: errors.New(strings.TrimSpace(stderr.String()))}
				}
				return orcaActionMessage{text: text}
			}
		case "enter":
			if !model.active {
				model.message = "start Orca before launching an attached agent"
				break
			}
			if len(model.agents) > 0 {
				model.selected = model.agents[model.cursor].Name
				return model, tea.Quit
			}
		}
	}
	return model, nil
}

func (model orcaUIModel) View() string {
	status := orcaInactiveStyle.Render("inactive")
	if model.active {
		status = orcaActiveStyle.Render("running")
	}
	scope := model.record.Scope
	if scope == "" {
		scope = "."
	}
	var view strings.Builder
	fmt.Fprintf(&view, "%s  %s\n", orcaTitleStyle.Render("Orca"), status)
	fmt.Fprintf(&view, "%s\n\n", filepath.Clean(scope))
	view.WriteString("Agents\n")
	for index, agent := range model.agents {
		cursor := "  "
		if index == model.cursor {
			cursor = orcaCursorStyle.Render("> ")
		}
		label := agent.Label
		if label == "" {
			label = agent.Name
		}
		fmt.Fprintf(&view, "%s%s\n", cursor, label)
	}
	if len(model.agents) == 0 {
		view.WriteString("  no installed agents\n")
	}
	if model.message != "" {
		fmt.Fprintf(&view, "\n%s\n", model.message)
	}
	view.WriteString("\ns start/stop  enter launch  r refresh  q quit\n")
	return view.String()
}

func (model *orcaUIModel) refresh() error {
	record, active, err := activeOrca()
	if err != nil {
		return err
	}
	model.record = record
	model.active = active
	return nil
}
