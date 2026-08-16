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
	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/roshbhatia/sysinit/pkgs/ask/internal/provider"
)

// chrome is the rows a frame spends on itself: two borders, the head, the rule
// under it, the help line, and one row of slack so the view never scrolls.
const (
	chrome  = 6
	deepest = 24
	shallow = 3
	unsized = 8
)

// depth answers how many event rows fit a terminal of this height. Zero means
// the size has not arrived yet, so it holds the old fixed count.
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
	spin    spinner.Model
	help    help.Model
	events  <-chan provider.Event
	stop    func()
	rows    []row
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
	case tea.WindowSizeMsg:
		m.width, m.height = message.Width, message.Height
		m.trim()
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
		m.push(row{text: first(event.Text), gutter: dim, body: dim})
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

// trim drops the oldest rows past what the window holds. It runs on a resize as
// well as a push, so shrinking the terminal cuts the view down at once instead
// of waiting for the next event.
func (m *model) trim() {
	if keep := depth(m.height); len(m.rows) > keep {
		m.rows = m.rows[len(m.rows)-keep:]
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
			m.spin.View()+accent.Render(clip(status, width-8)),
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

	return shown.String() + "\n" + dim.Render("  "+m.help.ShortHelpView(running.ShortHelp())) + "\n"
}

// Run watches a live run and answers with what it ended on. stop is called when
// the keyboard asks the run to end, so the agent stops rather than only the view.
func Run(events <-chan provider.Event, stop func()) (*provider.Result, error) {
	spin := spinner.New()
	spin.Spinner = spinner.Dot
	spin.Style = accent

	guide := help.New()
	guide.ShowAll = false

	start := model{spin: spin, help: guide, events: events, stop: stop, started: time.Now()}

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
