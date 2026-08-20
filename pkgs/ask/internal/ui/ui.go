package ui

import (
	"errors"
	"fmt"
	"io"
	"os"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/help"
	"github.com/charmbracelet/bubbles/key"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/roshbhatia/sysinit/pkgs/ask/internal/provider"
)

// chrome is the rows a frame spends on itself: two borders, the head, the rule
// under it, the help line, and one row of slack.
const (
	chrome  = 6
	deepest = 24
	shallow = 3
	unsized = 8
	// The prose is what the watcher is here for, so the tool calls keep three
	// rows and the agent's text takes the rest of the frame.
	recent = 3
)

// depth answers how many event rows fit a terminal of this height.
func depth(height int) int {
	if height <= 0 {
		return unsized
	}
	room := height - chrome
	if room < shallow {
		return shallow
	}
	if room > deepest {
		return deepest
	}
	return room
}

// ErrStopped says the run ended because the keyboard asked it to.
var ErrStopped = errors.New("stopped")

type runKeys struct {
	stop key.Binding
}

func (k runKeys) ShortHelp() []key.Binding { return []key.Binding{k.stop} }

var running = runKeys{
	stop: key.NewBinding(key.WithKeys("ctrl+c", "esc"), key.WithHelp("ctrl+c", "stop")),
}

type row struct {
	name string
	text string

	gutter lipgloss.Style
	body   lipgloss.Style
}

type model struct {
	strip   strip
	help    help.Model
	events  <-chan provider.Event
	stop    func()
	rows    []row
	body    string
	shown   []string
	status  string
	width   int
	height  int
	started time.Time
	result  *provider.Result
	stopped bool
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
	return tea.Batch(tock(), next(m.events))
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
	case stripTick:
		m.strip.step()
		return m, tock()
	case tea.WindowSizeMsg:
		m.width, m.height = message.Width, message.Height
		m.reflow()
		return m, nil
	case tea.KeyMsg:
		if key.Matches(message, running.stop) {
			m.stopped = true
			if m.stop != nil {
				m.stop()
			}
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
		m.say(event.Text)
	case provider.Tool:
		m.push(row{name: event.Tool, text: first(event.Text), gutter: tool, body: dim})
	case provider.Notice:
		m.push(row{name: "!", text: first(event.Text), gutter: bad, body: bad})
	case provider.Done:
		m.result = event.Result
	}
}

func (m *model) push(line row) {
	m.rows = append(m.rows, line)
	m.trim()
}

// say adds a block of the agent's markdown and lays it out again. The render
// runs here rather than in View, which the strip redraws eleven times a second.
func (m *model) say(text string) {
	if text = strings.TrimSpace(text); text == "" {
		return
	}
	if m.body != "" {
		m.body += "\n\n"
	}
	m.body += text
	m.reflow()
}

func (m *model) reflow() {
	m.shown = render(m.body, inner(m.width))
}

// trim holds the tool rows to a fixed few, whatever the terminal height, so the
// prose below them keeps the same room as the run goes on.
func (m *model) trim() {
	if len(m.rows) > recent {
		m.rows = m.rows[len(m.rows)-recent:]
	}
}

// first keeps the opening line of a block, since a whole block will not fit a row.
func first(text string) string {
	return clip(strings.TrimSpace(strings.SplitN(text, "\n", 2)[0]), 200)
}

// clock reads as a stopwatch, so a long run stays legible past a minute.
func clock(since time.Duration) string {
	whole := int(since.Seconds())
	return fmt.Sprintf("%d:%02d", whole/60, whole%60)
}

// column sizes the tool name gutter to the widest name on screen.
func column(rows []row) int {
	width := 0
	for _, one := range rows {
		if size := lipgloss.Width(one.name); size > width {
			width = size
		}
	}
	if width > 12 {
		width = 12
	}
	return width
}

func (m model) View() string {
	if m.result != nil || m.stopped {
		return ""
	}

	width := inner(m.width)
	status := m.status
	if status == "" {
		status = "starting"
	}

	shown := frame{
		title: "ask",
		width: width,
		head: split(
			m.strip.View()+" "+accent.Render(clip(status, width-cells-8)),
			dim.Render(clock(time.Since(m.started))),
			width,
		),
	}

	gutter := column(m.rows)
	for _, one := range m.rows {
		name := one.gutter.Render(pad(clip(one.name, gutter), gutter))
		text := one.body.Render(clip(one.text, width-gutter-3))
		shown.rows = append(shown.rows, " "+name+"  "+text)
	}

	// The prose takes whatever the tool rows leave, and the tail of it is the
	// part still being written.
	if room := depth(m.height) - len(shown.rows); room > 0 && len(m.shown) > 0 {
		lines := m.shown
		if len(lines) > room {
			lines = lines[len(lines)-room:]
		}
		fit := lipgloss.NewStyle().MaxWidth(width)
		for _, line := range lines {
			shown.rows = append(shown.rows, fit.Render(line))
		}
	}

	return shown.String() + "\n" + dim.Render("  "+m.help.ShortHelpView(running.ShortHelp())) + "\n"
}

// Run watches a live run and answers with what it ended on. stop is called when
// the keyboard asks the run to end, so the agent stops rather than only the view.
func Run(events <-chan provider.Event, stop func()) (*provider.Result, error) {
	guide := help.New()
	guide.ShowAll = false

	start := model{strip: newStrip(), help: guide, events: events, stop: stop, started: time.Now()}

	options := []tea.ProgramOption{tea.WithOutput(os.Stderr)}
	if keyboard := console(); keyboard != nil {
		defer keyboard.Close()
		options = append(options, tea.WithInput(keyboard))
	} else {
		options = append(options, tea.WithInput(nil))
	}

	final, err := tea.NewProgram(start, options...).Run()
	if err != nil {
		return nil, err
	}
	done, _ := final.(model)
	if done.stopped {
		return nil, ErrStopped
	}
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
