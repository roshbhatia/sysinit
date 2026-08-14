package ui

import (
	"fmt"
	"io"
	"os"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/roshbhatia/sysinit/pkgs/ask/internal/provider"
)

const depth = 8

var (
	dim    = lipgloss.NewStyle().Foreground(lipgloss.Color("245"))
	accent = lipgloss.NewStyle().Foreground(lipgloss.Color("111"))
	bad    = lipgloss.NewStyle().Foreground(lipgloss.Color("203"))
	tool   = lipgloss.NewStyle().Foreground(lipgloss.Color("150"))
)

type model struct {
	spin    spinner.Model
	events  <-chan provider.Event
	lines   []string
	status  string
	started time.Time
	result  *provider.Result
	failed  string
}

type tick struct {
	event provider.Event
	open  bool
}

func next(events <-chan provider.Event) tea.Cmd {
	return func() tea.Msg {
		event, open := <-events
		return tick{event: event, open: open}
	}
}

func (m model) Init() tea.Cmd {
	return tea.Batch(m.spin.Tick, next(m.events))
}

func (m model) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch message := message.(type) {
	case tick:
		if !message.open {
			return m, tea.Quit
		}
		m.take(message.event)
		if m.result != nil {
			return m, tea.Quit
		}
		return m, next(m.events)
	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spin, cmd = m.spin.Update(message)
		return m, cmd
	case tea.KeyMsg:
		if message.Type == tea.KeyCtrlC {
			return m, tea.Quit
		}
	}
	return m, nil
}

func (m *model) take(event provider.Event) {
	switch event.Kind {
	case provider.Started:
		m.status = event.Text
	case provider.Text:
		m.push(dim.Render(first(event.Text)))
	case provider.Tool:
		m.push(tool.Render(event.Tool) + " " + dim.Render(event.Text))
	case provider.Notice:
		m.push(bad.Render(event.Text))
	case provider.Done:
		m.result = event.Result
		if event.Result != nil && event.Result.Failed {
			m.failed = event.Result.Reason
		}
	}
}

func (m *model) push(line string) {
	m.lines = append(m.lines, line)
	if len(m.lines) > depth {
		m.lines = m.lines[len(m.lines)-depth:]
	}
}

func first(text string) string {
	line := strings.TrimSpace(strings.SplitN(text, "\n", 2)[0])
	if len(line) > 100 {
		line = line[:100] + "…"
	}
	return line
}

func (m model) View() string {
	if m.result != nil {
		return ""
	}
	var out strings.Builder
	for _, line := range m.lines {
		out.WriteString("  " + line + "\n")
	}
	status := m.status
	if status == "" {
		status = "starting"
	}
	out.WriteString(fmt.Sprintf(
		"%s %s %s\n",
		m.spin.View(),
		accent.Render(status),
		dim.Render(time.Since(m.started).Round(time.Second).String()),
	))
	return out.String()
}

func Run(events <-chan provider.Event) (*provider.Result, error) {
	spin := spinner.New()
	spin.Spinner = spinner.Dot
	spin.Style = accent

	start := model{spin: spin, events: events, started: time.Now()}

	program := tea.NewProgram(start, tea.WithOutput(os.Stderr), tea.WithInput(nil))
	final, err := program.Run()
	if err != nil {
		return nil, err
	}
	done, _ := final.(model)
	return done.result, nil
}

func Drain(events <-chan provider.Event, to io.Writer) *provider.Result {
	var result *provider.Result
	for event := range events {
		if event.Kind == provider.Done {
			result = event.Result
		}
		if to != nil && event.Kind == provider.Tool {
			fmt.Fprintf(to, "%s %s\n", event.Tool, event.Text)
		}
	}
	return result
}

func Summary(result *provider.Result) string {
	if result == nil {
		return ""
	}
	return dim.Render(fmt.Sprintf(
		"%s · %d turns · $%.4f",
		result.Duration.Round(time.Millisecond*100),
		result.Turns,
		result.CostUSD,
	))
}
