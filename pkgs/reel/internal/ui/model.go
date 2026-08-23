// Package ui draws the agent trace as a folding tree with a waterfall column,
// and keeps it current while the agent is still running.
package ui

import (
	"encoding/base64"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/help"
	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"

	"github.com/roshbhatia/sysinit/pkgs/reel/internal/otlp"
	"github.com/roshbhatia/sysinit/pkgs/reel/internal/session"
)

// SpansMsg carries a batch of newly read spans into the program.
type SpansMsg []otlp.Span

// TickMsg redraws the clock in the header while a run is open.
type TickMsg time.Time

type mode int

const (
	modeTree mode = iota
	modePick
	modeHelp
)

type row struct {
	node   *session.Node
	root   *session.Node
	prefix string
	depth  int
}

type Model struct {
	store   *session.Store
	current *session.Session
	list    []*session.Session

	rows      []row
	at        int
	offset    int
	pickAt    int
	folded    map[string]bool
	follow    bool
	onDetail  bool
	mode      mode
	filtering bool
	query     string
	input     textinput.Model
	help      help.Model
	flash     string

	pinned  string
	source  string
	width   int
	height  int
	now     time.Time
	quitted bool
}

func New(store *session.Store, pinned, source string) Model {
	input := textinput.New()
	input.Prompt = "/"
	input.CharLimit = 64

	model := Model{
		store:  store,
		folded: map[string]bool{},
		follow: true,
		input:  input,
		help:   help.New(),
		pinned: pinned,
		source: source,
		now:    time.Now(),
		width:  100,
		height: 30,
	}
	model.reload()
	return model
}

func (m Model) Init() tea.Cmd {
	return tea.Tick(time.Second, func(at time.Time) tea.Msg { return TickMsg(at) })
}

// reload re-groups every span and keeps the attached session attached.
func (m *Model) reload() {
	m.list = m.store.Sessions()
	switch {
	case m.pinned != "":
		if found := m.store.Session(m.pinned); found != nil {
			m.current = found
		}
	case m.current != nil:
		for _, one := range m.list {
			if one.Key == m.current.Key {
				m.current = one
			}
		}
	}
	if m.current == nil && len(m.list) > 0 {
		m.current = m.list[0]
	}
	m.refresh()
}

func (m *Model) refresh() {
	m.rows = nil
	if m.current == nil {
		return
	}
	query := strings.ToLower(strings.TrimSpace(m.query))
	for _, root := range m.current.Roots {
		m.walk(root, root, "", 0, query)
	}
	if m.at >= len(m.rows) {
		m.at = max(0, len(m.rows)-1)
	}
}

func (m *Model) walk(node, root *session.Node, prefix string, depth int, query string) {
	if !matches(node, query) {
		return
	}
	m.rows = append(m.rows, row{node: node, root: root, prefix: prefix, depth: depth})
	if m.folded[node.Span.SpanID] {
		return
	}
	kids := make([]*session.Node, 0, len(node.Children))
	for _, kid := range node.Children {
		if matches(kid, query) {
			kids = append(kids, kid)
		}
	}
	for at, kid := range kids {
		branch, tail := "├─ ", "│  "
		if at == len(kids)-1 {
			branch, tail = "└─ ", "   "
		}
		if depth == 0 {
			m.walk(kid, root, branch, depth+1, query)
			continue
		}
		m.walk(kid, root, prefix[:len(prefix)-len("├─ ")]+tail+branch, depth+1, query)
	}
}

func matches(node *session.Node, query string) bool {
	if query == "" {
		return true
	}
	haystack := strings.ToLower(node.Label + " " + node.Note + " " + node.Span.Name)
	if strings.Contains(haystack, query) {
		return true
	}
	for _, kid := range node.Children {
		if matches(kid, query) {
			return true
		}
	}
	return false
}

func (m Model) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch message := message.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = message.Width, message.Height
		m.help.Width = message.Width
		m.refresh()
		return m, nil

	case TickMsg:
		m.now = time.Time(message)
		return m, tea.Tick(time.Second, func(at time.Time) tea.Msg { return TickMsg(at) })

	case SpansMsg:
		before := len(m.rows)
		m.store.Add(message)
		m.reload()
		if m.follow && len(m.rows) > before {
			m.at = len(m.rows) - 1
		}
		return m, nil

	case tea.KeyMsg:
		return m.press(message)
	}
	return m, nil
}

func (m Model) press(message tea.KeyMsg) (tea.Model, tea.Cmd) {
	if m.filtering {
		switch message.String() {
		case "enter":
			m.filtering = false
		case "esc":
			m.filtering, m.query = false, ""
			m.input.SetValue("")
			m.refresh()
		default:
			var command tea.Cmd
			m.input, command = m.input.Update(message)
			m.query = m.input.Value()
			m.refresh()
			return m, command
		}
		return m, nil
	}

	if m.mode == modePick {
		return m.pressPick(message)
	}
	if m.mode == modeHelp {
		m.mode = modeTree
		return m, nil
	}

	m.flash = ""
	switch {
	case key.Matches(message, keys.quit):
		m.quitted = true
		return m, tea.Quit

	case key.Matches(message, keys.up):
		m.move(-1)
	case key.Matches(message, keys.down):
		m.move(1)
	case key.Matches(message, keys.pageUp):
		m.move(-m.bodyHeight() / 2)
	case key.Matches(message, keys.pageDwn):
		m.move(m.bodyHeight() / 2)
	case key.Matches(message, keys.top):
		m.at, m.follow = 0, false
	case key.Matches(message, keys.bottom):
		m.at = max(0, len(m.rows)-1)

	case key.Matches(message, keys.fold):
		m.fold()
	case key.Matches(message, keys.unfold):
		m.unfold()
	case key.Matches(message, keys.toggle):
		if node := m.node(); node != nil && len(node.Children) > 0 {
			m.folded[node.Span.SpanID] = !m.folded[node.Span.SpanID]
			m.refresh()
		}

	case key.Matches(message, keys.turn):
		wanted, err := strconv.Atoi(message.String())
		if err == nil {
			m.jumpTurn(wanted)
		}

	case key.Matches(message, keys.follow):
		m.follow = !m.follow
		if m.follow {
			m.at = max(0, len(m.rows)-1)
		}
	case key.Matches(message, keys.detail):
		m.onDetail = !m.onDetail
	case key.Matches(message, keys.filter):
		m.filtering = true
		m.input.Focus()
		return m, textinput.Blink
	case key.Matches(message, keys.pick):
		m.mode = modePick
		m.pickAt = 0
		for at, one := range m.list {
			if m.current != nil && one.Key == m.current.Key {
				m.pickAt = at
			}
		}
	case key.Matches(message, keys.help):
		m.mode = modeHelp
	case key.Matches(message, keys.yank):
		if node := m.node(); node != nil {
			m.flash = "copied " + node.Span.SpanID
			return m, yankOSC52(node.Span.SpanID)
		}
	}
	return m, nil
}

func (m Model) pressPick(message tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch {
	case key.Matches(message, picking.back):
		m.mode = modeTree
	case key.Matches(message, picking.up):
		if m.pickAt > 0 {
			m.pickAt--
		}
	case key.Matches(message, picking.down):
		if m.pickAt < len(m.list)-1 {
			m.pickAt++
		}
	case key.Matches(message, picking.number):
		wanted, err := strconv.Atoi(message.String())
		if err == nil && wanted <= len(m.list) {
			m.pickAt = wanted - 1
			return m.attach(), nil
		}
	case key.Matches(message, picking.take):
		return m.attach(), nil
	case message.String() == "ctrl+c":
		m.quitted = true
		return m, tea.Quit
	}
	return m, nil
}

func (m Model) attach() tea.Model {
	if m.pickAt < len(m.list) {
		m.current = m.list[m.pickAt]
		m.pinned = m.current.Key
		m.at, m.offset = 0, 0
		m.refresh()
	}
	m.mode = modeTree
	return m
}

func (m *Model) move(by int) {
	m.at = min(max(0, m.at+by), max(0, len(m.rows)-1))
	if by < 0 {
		m.follow = false
	}
}

func (m *Model) node() *session.Node {
	if m.at < 0 || m.at >= len(m.rows) {
		return nil
	}
	return m.rows[m.at].node
}

// fold closes an open row, and steps to the parent when the row is already
// closed. That is the habit `h` carries in a file tree.
func (m *Model) fold() {
	node := m.node()
	if node == nil {
		return
	}
	if len(node.Children) > 0 && !m.folded[node.Span.SpanID] {
		m.folded[node.Span.SpanID] = true
		m.refresh()
		return
	}
	depth := m.rows[m.at].depth
	for at := m.at - 1; at >= 0; at-- {
		if m.rows[at].depth < depth {
			m.at = at
			return
		}
	}
}

func (m *Model) unfold() {
	node := m.node()
	if node == nil || len(node.Children) == 0 {
		return
	}
	if m.folded[node.Span.SpanID] {
		m.folded[node.Span.SpanID] = false
		m.refresh()
		return
	}
	m.move(1)
}

func (m *Model) jumpTurn(wanted int) {
	for at, one := range m.rows {
		if one.depth == 0 && one.node.Turn == wanted {
			m.at, m.follow = at, false
			return
		}
	}
}

func (m Model) Quitted() bool { return m.quitted }

// yankOSC52 hands the text to the terminal, which forwards it to the system
// clipboard. bubbletea v1.3 has no clipboard command, and the escape keeps reel
// free of a clipboard dependency that would not work over ssh anyway.
func yankOSC52(text string) tea.Cmd {
	return func() tea.Msg {
		fmt.Fprintf(os.Stdout, "\x1b]52;c;%s\x07", base64.StdEncoding.EncodeToString([]byte(text)))
		return nil
	}
}
