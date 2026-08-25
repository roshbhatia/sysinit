package ui

import (
	_ "embed"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/spinner"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/glamour"
	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/x/ansi"
	"github.com/muesli/termenv"

	"github.com/roshbhatia/sysinit/pkgs/internal/diffview"
	"github.com/roshbhatia/sysinit/pkgs/traces/internal/otlp"
	"github.com/roshbhatia/sysinit/pkgs/traces/internal/session"
)

// The layout came out of four variations judged against a fixed fixture. The
// density comes from the one-line variant, the inline second line from the
// two-line variant, the gutter cursor and the tail anchor from the waterfall
// variant, and the fused error row from the transcript variant.

// x/ansi measures East Asian Ambiguous glyphs as narrow unless
// RUNEWIDTH_EASTASIAN is set, and a terminal that disagrees tears every frame.
// The data bearing glyphs are all ASCII or in the Narrow U+254C..U+254F block,
// and the ascii set covers the one variable that can flip the measurement.
type glyphSet struct {
	tl, tr, bl, br, h, v  string
	point, mark           string
	vert, tee, elbow, gap string
	fold, unfold, leaf    string
	tabL, tabR            string
	fill, dot, tick, ell  string
	// The strip's own two: a cell that holds a row, and the playhead. Both are
	// one cell wide in the Narrow block, which every other strip cell has to
	// match or the run's position drifts as the cursor moves.
	block, playhead string
}

var narrowGlyphs = glyphSet{
	tl: "╭", tr: "╮", bl: "╰", br: "╯", h: "─", v: "│",
	point: "▌", mark: "┃",
	vert: "╎ ", tee: "├╌", elbow: "╰╌", gap: "  ",
	fold: "▾", unfold: "▸", leaf: " ",
	tabL: "┤", tabR: "├",
	fill: "╍", dot: "╌", tick: "·", ell: "…",
	block: "▄", playhead: "▮",
}

var asciiGlyphs = glyphSet{
	tl: "+", tr: "+", bl: "+", br: "+", h: "-", v: "|",
	point: "|", mark: "#",
	vert: ": ", tee: "+-", elbow: "\\-", gap: "  ",
	fold: "v", unfold: ">", leaf: " ",
	tabL: "[", tabR: "]",
	fill: "=", dot: "-", tick: ".", ell: "...",
	block: "#", playhead: "|",
}

var gl = narrowGlyphs

func init() {
	if ea, err := strconv.ParseBool(os.Getenv("RUNEWIDTH_EASTASIAN")); err == nil && ea {
		gl = asciiGlyphs
	}
}

// The kind picks the role colour and the detail tags. It is never drawn as a
// glyph: the actor and the label already spell out what ran, and a symbol
// column would ask the reader to hold a legend in their head.
type kind int

const (
	kindTurn kind = iota
	kindPrompt
	kindThink
	kindTool
	kindMCP
	kindSkill
	kindSub
	kindTeam
	kindHook
)

var roleOf = map[kind]session.Role{
	kindTurn:   session.RoleTurn,
	kindPrompt: session.RoleModel,
	kindThink:  session.RoleModel,
	kindTool:   session.RoleTool,
	kindMCP:    session.RoleTool,
	kindSkill:  session.RoleTool,
	kindSub:    session.RoleDelegate,
	kindTeam:   session.RoleDelegate,
	kindHook:   session.RoleSystem,
}

const (
	// One cost column, not two. Tokens and churn never appear on the same row:
	// a tool call costs no tokens and a model call changes no lines. Two columns
	// meant one of them was blank on every row, and the diff column was blank on
	// all of them for the length of a run with no edit in view.
	costCol   = 11
	timeCol   = 6
	metaCol   = costCol + timeCol + 2
	metaTight = 6 + timeCol + 2
	actorCol  = 12
	minTextW  = 26
	maxTextW  = 148
	minTrackW = 14
	maxTrackW = 40
)

// Every field is named at the call site below. The first draft used positional
// literals, and adding one field then rewrote all forty rows by hand.
type row struct {
	node    *session.Node
	depth   int
	kind    kind
	actor   string
	label   string
	preview string
	in      int    // input tokens billed to this span, cache reads included
	out     int    // output tokens
	ms      int    // wall time of this span alone
	src     string // where a hook is configured; empty on every other kind
	add     int    // lines added by this span
	del     int    // lines removed
	files   int    // files this span touched
	fail    bool
	parent  bool
	sibling bool
	guide   string
}

type Model struct {
	store   *session.Store
	current *session.Session
	list    []*session.Session
	pinned  string
	source  string
	query   string

	rows        []row
	visibleRows []int
	cursor      int
	offset      int
	wantLabel   int
	wantPreview int
	hasChurn    bool
	// Both are keyed on span id, not on row index: every batch of spans
	// rebuilds the row list, and an index would then point at another row.
	marks  map[string]bool
	folded map[string]bool

	width  int
	height int

	follow bool
	anchor bool
	help   bool
	leader bool
	place  placement
	last   placement
	split  int
	drag   bool

	// The colon line: what is typed, the history behind it, and where a recall
	// currently sits in that history.
	cmd     bool
	cmdText string
	cmdHist []string
	cmdAt   int
	// The candidate list a tab opened, and where the cycle sits in it. Any key
	// but tab clears it, so a cycle never applies to text typed since.
	cmdCands []string
	cmdCand  int
	// typed is what the reader has entered; query is what the tree is built
	// against. They differ for one filterPause, and tag is what tells a stale
	// tick from the current one.
	typed string
	tag   int
	// timeline draws the run's shape beside every row. It was a permanent
	// column until it cost more width than it earned, so now it is a toggle.
	timeline bool
	pending  string
	status   string
	picking  bool
	pickAt   int
	// visual holds a range selection anchored where it started. The marks it
	// paints are recomputed on every move, so backing off shrinks the range
	// rather than leaving a trail.
	visual   bool
	anchorAt int
	before   map[string]bool
	filter   bool
	now      time.Time

	tab  int
	spin spinner.Model

	pane viewport.Model
	md   *glamour.TermRenderer
	mdW  int
}

// The tab bar, the rule and the pinned strip cost three inner lines of the
// inspector box on every frame.
const paneChrome = 3

func New(store *session.Store, pinned, source string) Model {
	// lipgloss asks the terminal for its background on first render, and Bubble
	// Tea v1 reads the reply as a burst of keys: a hex digit `d` in the answer
	// paged the view and cleared follow before anyone touched the keyboard.
	// Every colour here is an ANSI slot, so nothing is lost by deciding both up
	// front and never asking.
	lipgloss.SetColorProfile(termenv.ANSI)
	lipgloss.SetHasDarkBackground(true)

	m := Model{
		store:  store,
		pinned: pinned,
		source: source,
		marks:  map[string]bool{},
		folded: map[string]bool{},
		width:  120,
		height: 40,
		follow: true,
		anchor: true,
		place:  placeBottom,
		last:   placeBottom,
		split:  50,
		pane:   viewport.New(52, 20),
		spin:   spinner.New(spinner.WithSpinner(spinner.MiniDot), spinner.WithStyle(live)),
		now:    time.Now(),
	}
	m.reload()
	m.cursor = max(0, len(m.rows)-1)
	return m
}

// BatchMsg carries a newly read batch of spans and log records into the
// program.
type BatchMsg otlp.Batch

// reload re-groups every span and keeps the attached session attached. A
// session named on the command line wins, so a reader who asked for one run is
// not moved off it when a newer run appears.
func (m *Model) reload() {
	m.list = m.store.Sessions()
	switch {
	case m.pinned != "":
		// Session() calls Sessions() again, and Sessions() rebuilds every run
		// it returns. The list in hand is that same list.
		if found := pickFrom(m.list, m.pinned); found != nil {
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
	m.rebuild()
}

// pickFrom matches the same way session.Session does, over a list already in
// hand. It exists so reload does not rebuild every run a second time.
func pickFrom(list []*session.Session, want string) *session.Session {
	for _, one := range list {
		switch {
		case one.ID == want, one.Key == want,
			one.ID != "" && strings.HasPrefix(one.ID, want),
			strings.HasSuffix(one.Key, want):
			return one
		}
	}
	return nil
}

// rebuild flattens the session tree into the row list the layout draws.
func (m *Model) rebuild() {
	m.rows = nil
	if m.current == nil {
		m.visibleRows = nil
		m.wantLabel, m.wantPreview, m.hasChurn = 0, 0, false
		return
	}
	first := m.current.First
	span := m.current.Last.Sub(first)
	query := strings.ToLower(strings.TrimSpace(m.query))
	for _, root := range m.current.Roots {
		m.walk(root, 0, first, span, query)
	}
	m.buildGuides()
	m.updateVisibility()
}

func (m *Model) buildGuides() {
	last := []int{}
	for i := range m.rows {
		depth := m.rows[i].depth
		for len(last) <= depth {
			last = append(last, -1)
		}
		for level := depth + 1; level < len(last); level++ {
			last[level] = -1
		}
		if last[depth] >= 0 {
			m.rows[last[depth]].sibling = true
		}
		last[depth] = i
	}

	ancestors := []int{}
	for i := range m.rows {
		depth := m.rows[i].depth
		for len(ancestors) <= depth {
			ancestors = append(ancestors, -1)
		}
		if depth > 0 {
			cols := make([]string, depth)
			for level := 1; level < depth; level++ {
				cols[level-1] = gl.gap
				if ancestor := ancestors[level]; ancestor >= 0 && m.rows[ancestor].sibling {
					cols[level-1] = gl.vert
				}
			}
			cols[depth-1] = gl.elbow
			if m.rows[i].sibling {
				cols[depth-1] = gl.tee
			}
			m.rows[i].guide = strings.Join(cols, "")
		}
		ancestors[depth] = i
	}
}

// updateVisibility is called when the rows or the folds change, and never on a
// cursor move. It measures every visible label and preview, which is three
// lipgloss.Width calls over 35870 rows: 10ms, and clamp used to call it on every
// keystroke and every wheel notch.
func (m *Model) updateVisibility() {
	m.visibleRows = nil
	hide := -1
	for i, r := range m.rows {
		if hide >= 0 && r.depth > m.rows[hide].depth {
			continue
		}
		hide = -1
		m.visibleRows = append(m.visibleRows, i)
		if r.parent && m.folded[m.idOf(i)] {
			hide = i
		}
	}

	m.wantLabel, m.wantPreview, m.hasChurn = 0, 0, false
	for _, idx := range m.visibleRows {
		r := m.rows[idx]
		if width := lipgloss.Width(r.label) + lipgloss.Width(r.guide); width > m.wantLabel {
			m.wantLabel = width
		}
		if width := lipgloss.Width(r.preview); width > m.wantPreview {
			m.wantPreview = width
		}
		m.hasChurn = m.hasChurn || r.add > 0 || r.del > 0 || r.files > 0
	}
}

func (m *Model) walk(node *session.Node, depth int, first time.Time, span time.Duration, query string) {
	if !matches(node, query) {
		return
	}
	// A filter hides the ancestors that gave a depth its meaning, and the guide
	// column then eats the label: a depth-8 row rendered as `╎ ╎    ╎  …` with
	// no name in it. A filtered row is drawn flat, because what is left is a
	// list of hits rather than a tree.
	at := depth
	if query != "" {
		at = 0
	}
	m.rows = append(m.rows, rowOf(node, at))
	for _, kid := range node.Children {
		m.walk(kid, depth+1, first, span, query)
	}
}

type tickMsg struct{ t time.Time }

func tick() tea.Cmd {
	return tea.Tick(900*time.Millisecond, func(t time.Time) tea.Msg { return tickMsg{t} })
}

func (m Model) Init() tea.Cmd { return tea.Batch(tick(), m.spin.Tick) }

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
		// Resize has to reclamp. Without it a shrink can leave the offset past
		// the end and the tree pane renders blank until the next keypress.
		return m.sized().clamp(), nil
	case statusMsg:
		m.status = string(msg)
		return m, nil
	case tickMsg:
		m.now = msg.t
		return m, tick()
	case filterMsg:
		// A stale tick means another keystroke followed it, so the query it
		// would apply is already out of date.
		if int(msg) != m.tag || m.query == m.typed {
			return m, nil
		}
		m.query = m.typed
		m.rebuild()
		return m.clamp(), nil
	case BatchMsg:
		// A poll that found nothing still rebuilt every session and every row:
		// 135ms of frozen frame, once per provider, every 15 seconds. Four
		// providers made that half a second of stall on a loop.
		if otlp.Batch(msg).Empty() {
			return m, nil
		}
		before := len(m.rows)
		m.store.AddBatch(otlp.Batch(msg))
		m.reload()
		if m.follow && len(m.rows) > before {
			if vis := m.visible(); len(vis) > 0 {
				m.cursor = len(vis) - 1
			}
		}
		return m.clamp(), nil
	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spin, cmd = m.spin.Update(msg)
		return m, cmd
	case tea.MouseMsg:
		return m.mouse(msg)
	case tea.KeyMsg:
		return m.key(msg)
	}
	return m, nil
}

// placement is where the inspector sits. Bottom is the default, because a body,
// a diff and a table all read best at the full terminal width. The choice is a
// request and placeAt is the answer: a frame too small for both panes hides it.
type placement int

const (
	placeBottom placement = iota
	placeTop
	placeLeft
	placeRight
	placeHidden
)

func (m Model) placeAt() placement {
	switch m.place {
	case placeBottom, placeTop:
		if m.height >= 24 {
			return m.place
		}
	case placeLeft, placeRight:
		if m.width >= 120 {
			return m.place
		}
	}
	return placeHidden
}

// vertical is true when the inspector stacks with the tree and owns the full
// width. horizontal is true when it sits beside the tree and owns full height.
func (m Model) vertical() bool {
	p := m.placeAt()
	return p == placeBottom || p == placeTop
}

func (m Model) horizontal() bool {
	p := m.placeAt()
	return p == placeLeft || p == placeRight
}

func (m Model) placeName() string {
	switch m.placeAt() {
	case placeBottom:
		return "along the bottom"
	case placeTop:
		return "along the top"
	case placeLeft:
		return "on the left"
	case placeRight:
		return "on the right"
	}
	return "hidden"
}

// detailLines is the whole screen cost of a bottom pane, border rows included.
// The divider is dragged, so the size is held as the inspector's percent of the
// content rows. The clamp keeps four tree rows and one pane row alive.
func (m Model) detailLines() int {
	if !m.vertical() {
		return 0
	}
	rows := max(1, m.height-4)
	return min(max(rows*m.split/100, paneChrome+3), max(paneChrome+3, rows-4))
}

// The tree box bottom border is the divider, and the drag reads that row. The
// inspector top border sits one below it, and the tab bar one below that.
func (m Model) dividerY() int { return m.treeRows() + 2 }

// The split is a percent, so it round trips through two floors and lands the
// divider one row above the pointer. Rounding the percent up cancels that.
func (m Model) resizeTo(y int) Model {
	rows := max(1, m.height-4)
	lines := rows - max(1, y-2)
	m.split = min(85, max(15, (lines*100+rows-1)/rows))
	return m.sized().clamp()
}

// dock moves the inspector to an edge. Asking for the edge it already holds
// hides it, so <leader>ij is both "put it at the bottom" and "put it away",
// and <leader>ii toggles whichever edge it last had.
func (m Model) dock(to placement) Model {
	switch {
	case to == placeHidden && m.place == placeHidden:
		m.place = m.last
	case to == placeHidden, to == m.place:
		m.last, m.place = m.place, placeHidden
	default:
		m.place = to
	}
	m = m.sized()
	m.status = "inspector " + m.placeName()
	return m.clamp()
}

func (m Model) resize(by int) Model {
	m.split = min(85, max(15, m.split+by))
	m.status = fmt.Sprintf("inspector %d%% of the frame", m.split)
	return m.sized().clamp()
}

func (m Model) treeWidth() int { return m.width - m.detailCols() }

// detailCols is the whole screen cost of a side pane, border columns included.
// The clamp keeps 44 columns of tree alive, which is the narrowest frame that
// still fits an actor, a label and a preview.
func (m Model) detailCols() int {
	if !m.horizontal() {
		return 0
	}
	return min(max(m.width*m.split/100, 34), max(34, m.width-44))
}

func (m Model) treeRows() int {
	// 4 for the header, the footer and the tree box's own two borders, and 1
	// more for the strip that sits under the tree.
	rows := max(1, m.height-5)
	if m.vertical() {
		rows = max(3, rows-m.detailLines())
	}
	return rows
}

// treeTop is the screen row of the tree's first body line, and treeLeft the
// screen column of its first inner cell. Every mouse hit test starts here.
// The strip moved from above the tree to below it, so the tree's own first body
// line moved up a row. A mouse hit test off by one row selects the wrong span on
// every click.
func (m Model) treeTop() int {
	if m.placeAt() == placeTop {
		// Above the tree: the pane, then the strip, then the tree's border and
		// its column header.
		return m.detailLines() + 4
	}
	return 3
}

func (m Model) treeLeft() int {
	if m.placeAt() == placeLeft {
		return m.detailCols()
	}
	return 0
}

// Every colour in the sheet is an ANSI slot number, so the terminal palette
// decides the hue and the pane matches the rest of the session. Resolving the
// style from a file also keeps glamour from asking the terminal for its
// background over OSC 11, whose reply Bubble Tea v1 reads as a burst of keys.
//
// The chroma block under code_block is the exception: chroma parses a colour as
// hex only, and terminal16 rounds it to a slot. Round trip any new value first,
// because a mid tone lands on the wrong slot (#5555ff rounds to yellow, not
// blue). #0000ff, #00ffff, #00ff00, #ffff00, #ff00ff, #ff0000, #808080 and
// #ffffff round to slots 4, 6, 2, 3, 5, 1, 8 and 7.
//
//go:embed ansi16.json
var ansi16Style []byte

func (m Model) sized() Model {
	inner := m.detailWidth() - 2
	if inner < 1 {
		inner = 1
	}
	m.pane.Width = inner
	m.pane.Height = max(1, m.detailRows()-paneChrome)
	// Prose and the attribute table both read badly past ~90 columns, and the
	// bottom pane is as wide as the terminal, so the wrap is capped there.
	wrap := min(90, max(20, inner-2))
	if m.md == nil || m.mdW != wrap {
		r, err := glamour.NewTermRenderer(
			glamour.WithStylesFromJSONBytes(ansi16Style),
			// terminal16 sends fenced code through the same sixteen slots, so a
			// code block and the prose around it come from one palette.
			glamour.WithChromaFormatter("terminal16"),
			// A table left to wrap stretches to the widest cell and blows past
			// the pane. Off, glamour holds it inside the word wrap.
			glamour.WithTableWrap(false),
			glamour.WithWordWrap(wrap),
		)
		if err == nil {
			m.md, m.mdW = r, wrap
		}
	}
	return m
}

func (m Model) detailWidth() int {
	if m.vertical() {
		return m.width
	}
	return m.detailCols()
}

// The side pane is as tall as the tree box, so its viewport takes the same
// inner rows less the three chrome lines paneView always draws.
func (m Model) detailRows() int {
	if m.horizontal() {
		return m.treeRows()
	}
	return max(0, m.detailLines()-2)
}

// A terminal answering an OSC colour query writes the reply to stdin, and Bubble
// Tea v1 parses it as keys. Drop the fragments, or one reply clears the leader
// and leaves "no binding" in the footer.
func isTerminalReply(k string) bool {
	return k == "alt+]" || k == "alt+\\" ||
		strings.HasPrefix(k, "]10;") || strings.HasPrefix(k, "]11;") ||
		strings.HasPrefix(k, "10;rgb:") || strings.HasPrefix(k, "11;rgb:")
}

func (m Model) key(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	k := msg.String()
	if isTerminalReply(k) {
		return m, nil
	}
	m.status = ""

	if m.picking {
		return m.pickKey(k)
	}
	if m.filter {
		return m.filterKey(msg, k)
	}
	if m.cmd {
		return m.commandKey(msg, k)
	}

	if m.leader {
		m.leader = false
		switch k {
		case "f":
			m.follow = !m.follow
		case "o":
			m.anchor = !m.anchor
		case "a":
			m.markAll()
		case "t":
			m.timeline = !m.timeline
			m.status = "timeline " + onOff(m.timeline)
		case "m":
			m.markRow(m.at(m.cursor))
		case "s":
			if len(m.list) > 1 {
				m.picking = true
				m.pickAt = m.currentAt()
			}
			return m, nil
		case "i":
			m.pending = "i"
			m.status = "i again to toggle, h j k l to dock"
			return m.clamp(), nil
		case "y":
			return m.yank()
		case "e":
			return m.edit()
		case "?":
			m.help = true
		}
		return m.clamp(), nil
	}

	if m.pending != "" {
		p := m.pending
		m.pending = ""
		switch p + k {
		case "za":
			m.toggleFold()
		case "zo":
			m.expand()
		case "zc":
			m.collapse()
		case "zR":
			m.folded = map[string]bool{}
			m.updateVisibility()
		case "zM":
			m.foldAll()
		case "zx":
			m.foldAll()
			m.openPath()
		case "ZZ", "ZQ":
			return m, tea.Quit
		case "gg":
			m.cursor, m.follow = 0, false
			m.paintRange()
		case "ii":
			return m.dock(placeHidden), nil
		case "ih":
			return m.dock(placeLeft), nil
		case "ij":
			return m.dock(placeBottom), nil
		case "ik":
			return m.dock(placeTop), nil
		case "il":
			return m.dock(placeRight), nil
		case "]t":
			m.jump(1)
		case "[t":
			m.jump(-1)
		// ctrl+w is vim's window prefix. w cycles, and h j k l pick a side the
		// way they pick a split there.
		default:
			// Any unmatched key cancels the prefix instead of vanishing.
			m.status = "no binding for " + p + k
		}
		return m.clamp(), nil
	}

	switch k {
	case "q", "ctrl+c":
		return m, tea.Quit
	case "?":
		m.help = !m.help
		return m, nil
	case "esc":
		if m.help {
			m.help = false
			return m, nil
		}
		if m.visual {
			// Cancelling a range restores what was marked before it started, so
			// an accidental v costs nothing.
			m.visual, m.marks = false, m.before
			m.before = nil
			return m.clamp(), nil
		}
		m.marks = map[string]bool{}
		return m.clamp(), nil
	case " ":
		m.leader = true
		return m, nil
	case "z", "g", "]", "[", "Z":
		m.pending = k
		return m, nil
	case "/":
		m.filter = true
		return m, nil
	case ":":
		m.cmd, m.cmdAt = true, 0
		return m, nil

	// The tree takes j k and the page keys; the inspector takes d u and the
	// scroll pair. Each window owns its own keys, so no press depends on where
	// a focus flag last landed and both panes move without a mode in between.
	case "j", "down":
		m.cursor, m.follow = m.cursor+1, false
		m.paintRange()
	case "k", "up":
		m.cursor, m.follow = m.cursor-1, false
		m.paintRange()
	case "ctrl+d":
		return m.halfPage(1), nil
	case "ctrl+u":
		return m.halfPage(-1), nil
	case "ctrl+f":
		return m.halfPage(2), nil
	case "ctrl+b":
		return m.halfPage(-2), nil
	case "G":
		m.cursor, m.follow = len(m.visible())-1, true
	case "d":
		m.pane.HalfPageDown()
		return m, nil
	case "u":
		m.pane.HalfPageUp()
		return m, nil
	// vim scrolls a view without moving the cursor on these two, and the
	// inspector is the window here with a view to scroll that way.
	case "ctrl+e":
		m.pane.ScrollDown(1)
		return m, nil
	case "ctrl+y":
		m.pane.ScrollUp(1)
		return m, nil
	case "H":
		m.cursor, m.follow = m.offset, false
		m.paintRange()
	case "M":
		m.cursor, m.follow = m.offset+m.treeRows()/2, false
		m.paintRange()
	case "L":
		m.cursor, m.follow = m.offset+m.treeRows()-1, false
		m.paintRange()
	case "}":
		m.jump(1)
	case "{":
		m.jump(-1)
	case "n":
		m.step(1)
	case "N":
		m.step(-1)

	case "tab":
		m.tab = m.tabAt() + 1
		return m.clamp(), nil
	case "shift+tab":
		m.tab = m.tabAt() - 1
		return m.clamp(), nil
	case "-", "_":
		return m.resize(-6), nil
	case "=", "+":
		return m.resize(6), nil

	case "v":
		if m.visual {
			m.visual, m.before = false, nil
			m.status = "range kept"
			return m.clamp(), nil
		}
		if m.at(m.cursor) < 0 {
			return m, nil
		}
		m.visual, m.anchorAt = true, m.cursor
		m.before = copyMarks(m.marks)
		m.paintRange()
		m.status = "visual: j k extend, enter or v keep, esc cancel"
		return m.clamp(), nil
	case "m":
		m.markSubtree(m.at(m.cursor))
	case "h":
		m.collapse()
	case "l":
		m.expand()
	// V is vim's linewise visual, and a turn is this tree's line: the whole
	// block a prompt owns. enter does the same, because a terminal reader
	// reaches for it first.
	case "V", "enter":
		if m.visual {
			m.visual, m.before = false, nil
			m.status = "range kept"
			return m.clamp(), nil
		}
		// markTurn reads the root's own state, so a second press turns the
		// whole turn back off.
		m.markTurn(m.at(m.cursor))
	case "Y":
		return m.yank()
	case "e":
		return m.edit()
	}
	return m.clamp(), nil
}

// step moves to the next row the filter matched. / filters rather than
// searches, so every visible row is a match and n is a plain move; without the
// binding n was a second name for the turn jump and vim's n did nothing.
func (m Model) step(dir int) {
	if m.query == "" {
		m.jump(dir)
		return
	}
	m.cursor, m.follow = m.cursor+dir, false
	m.paintRange()
}

// yank reports the verbatim bytes behind the cursor row. glamour is always on
// and has no toggle, so this is the only way to recover text it reflowed
// or that the tree pane truncated.
// yank puts the row's whole text on the system clipboard. It used to report a
// byte count and copy nothing, so the one escape from a reflowed pane did not
// work. The copier is a plain Cmd rather than ExecProcess: pbcopy needs no
// terminal, and handing it one would blank the frame for the length of a pipe.
func (m Model) yank() (Model, tea.Cmd) {
	at := m.at(m.cursor)
	if at < 0 {
		return m, nil
	}
	src := m.rows[at].raw()
	if src == "" {
		m.status = "nothing to yank on this row"
		return m, nil
	}
	name, args := copier()
	if name == "" {
		m.status = "no clipboard command on this machine"
		return m, nil
	}
	m.status = fmt.Sprintf("yanked %s", count(len(src), "byte"))
	return m, func() tea.Msg {
		cmd := exec.Command(name, args...)
		cmd.Stdin = strings.NewReader(src)
		if err := cmd.Run(); err != nil {
			return statusMsg("clipboard: " + err.Error())
		}
		return nil
	}
}

type statusMsg string

// The first command that exists wins. Wayland before X11, because a Wayland
// session usually still carries xclip and it writes to a clipboard nothing on
// that session reads.
func copier() (string, []string) {
	for _, try := range [][]string{
		{"pbcopy"}, {"wl-copy"}, {"xclip", "-selection", "clipboard"}, {"xsel", "-ib"},
	} {
		if _, err := exec.LookPath(try[0]); err == nil {
			return try[0], try[1:]
		}
	}
	return "", nil
}

// edit hands the row's text to $EDITOR. A tool result runs to thousands of
// bytes and the pane reflows it; this is the way out to a reader's own pager,
// search and yank.
func (m Model) edit() (Model, tea.Cmd) {
	at := m.at(m.cursor)
	if at < 0 {
		return m, nil
	}
	r := m.rows[at]
	src := r.raw()
	if src == "" {
		m.status = "nothing to open on this row"
		return m, nil
	}
	f, err := os.CreateTemp("", "traces-*.md")
	if err != nil {
		m.status = "temp file: " + err.Error()
		return m, nil
	}
	if _, err := f.WriteString(src); err != nil {
		f.Close()
		m.status = "temp file: " + err.Error()
		return m, nil
	}
	f.Close()
	editor := os.Getenv("EDITOR")
	if editor == "" {
		editor = "vi"
	}
	// The file is left behind on purpose. The editor may fork, and deleting it
	// on return would empty a buffer the reader is still in.
	m.status = "opened " + f.Name()
	return m, tea.ExecProcess(exec.Command(editor, f.Name()), func(err error) tea.Msg {
		if err != nil {
			return statusMsg("editor: " + err.Error())
		}
		return statusMsg("closed " + filepath.Base(f.Name()))
	})
}

// halfPage moves the cursor and the view by the same step, which is what vim
// ctrl+d and ctrl+u do. Moving the cursor alone left the offset behind, so the
// page never turned and the cursor only slid down the same screen.
func (m Model) halfPage(dir int) Model {
	step := max(1, m.bodyHeight()/2)
	m.follow = false
	m.cursor += dir * step
	m.offset += dir * step
	if m.offset < 0 {
		m.offset = 0
	}
	return m.clamp()
}

// at maps a cursor position to a row index, and returns -1 when there is no
// row at all. The fixture always had rows; a live run starts empty, and every
// caller that indexes m.rows has to survive that.
func (m Model) at(i int) int {
	vis := m.visible()
	if len(vis) == 0 {
		return -1
	}
	if i < 0 {
		i = 0
	}
	if i >= len(vis) {
		i = len(vis) - 1
	}
	return vis[i]
}

// markSubtree marks the row and every descendant, so "select a folder" is true
// rather than advertised. The footer claims the detail pane shows all of them.
func (m *Model) markSubtree(idx int) {
	if idx < 0 {
		return
	}
	on := !m.marks[m.idOf(idx)]
	set := func(i int) {
		if on {
			m.marks[m.idOf(i)] = true
		} else {
			delete(m.marks, m.idOf(i))
		}
	}
	set(idx)
	for i := idx + 1; i < len(m.rows) && m.rows[i].depth > m.rows[idx].depth; i++ {
		set(i)
	}
}

// markTurn marks the whole turn the cursor sits in, which is the unit a
// reader thinks in: one thing asked, everything it caused.
func (m *Model) markTurn(idx int) {
	if idx < 0 {
		return
	}
	for m.rows[idx].depth > 0 {
		a := m.ancestorOf(idx)
		if a < 0 {
			break
		}
		idx = a
	}
	m.markSubtree(idx)
}

func (m *Model) markRow(idx int) {
	if idx < 0 {
		return
	}
	if m.marks[m.idOf(idx)] {
		delete(m.marks, m.idOf(idx))
		return
	}
	m.marks[m.idOf(idx)] = true
}

// idOf is the row's span id, which survives a rebuild. A row with no node
// cannot happen once the tree is built, and an empty key is harmless.
func (m Model) idOf(idx int) string {
	if idx < 0 || idx >= len(m.rows) || m.rows[idx].node == nil {
		return ""
	}
	return m.rows[idx].node.Span.SpanID
}

func (m *Model) toggleFold() {
	idx := m.at(m.cursor)
	if idx < 0 {
		return
	}
	if !m.rows[idx].parent {
		return
	}
	if m.folded[m.idOf(idx)] {
		delete(m.folded, m.idOf(idx))
	} else {
		m.folded[m.idOf(idx)] = true
	}
	m.updateVisibility()
}

func (m *Model) foldAll() {
	for i, r := range m.rows {
		if r.parent {
			m.folded[m.idOf(i)] = true
		}
	}
	m.updateVisibility()
}

func (m *Model) openPath() {
	for i := m.at(m.cursor); i >= 0 && i < len(m.rows); i = m.ancestorOf(i) {
		delete(m.folded, m.idOf(i))
		if m.rows[i].depth == 0 {
			break
		}
	}
	m.updateVisibility()
}

func (m *Model) collapse() {
	idx := m.at(m.cursor)
	if idx < 0 {
		return
	}
	if m.rows[idx].parent && !m.folded[m.idOf(idx)] {
		m.folded[m.idOf(idx)] = true
		return
	}
	if a := m.ancestorOf(idx); a >= 0 {
		m.cursor, m.follow = m.indexOf(a), false
	}
	m.updateVisibility()
}

func (m *Model) expand() {
	idx := m.at(m.cursor)
	if idx < 0 {
		return
	}
	if m.rows[idx].parent {
		delete(m.folded, m.idOf(idx))
	}
	m.updateVisibility()
}

func (m *Model) jump(d int) {
	vis := m.visible()
	for i := m.cursor + d; i >= 0 && i < len(vis); i += d {
		if m.rows[vis[i]].depth == 0 {
			m.cursor, m.follow = i, false
			return
		}
	}
}

func (m Model) clamp() Model {
	vis := m.visible()
	if len(vis) == 0 {
		m.cursor, m.offset = 0, 0
		return m.refresh()
	}
	if m.cursor < 0 {
		m.cursor = 0
	}
	if m.cursor >= len(vis) {
		m.cursor = len(vis) - 1
	}

	h := m.bodyHeight()
	switch {
	case m.fits(vis, h):
		// Sparse content is always top anchored. Padding blank rows above a
		// short list is dead space, not a tail view.
		m.offset = 0
	case m.follow && m.anchor:
		m.offset = m.tailOffset(vis, h)
	default:
		if m.offset > m.cursor {
			m.offset = m.cursor
		}
		for m.offset < m.cursor && m.linesFrom(vis, m.offset, m.cursor+1) > h {
			m.offset++
		}
		if t := m.tailOffset(vis, h); m.offset > t {
			m.offset = t
		}
		if m.offset < 0 {
			m.offset = 0
		}
	}
	return m.refresh()
}

// tailOffset is the smallest offset whose remaining rows still fit, so the last
// row lands on the last line and no blank row opens under it.
func (m Model) tailOffset(vis []int, h int) int {
	o := len(vis) - 1
	for o > 0 && m.linesFrom(vis, o-1, len(vis)) <= h {
		o--
	}
	return o
}

// fits answers whether the whole list is on one screen, which is all the anchor
// rule needs. Summing every row's height to find out was O(rows) on a path that
// runs on every keypress.
func (m Model) fits(vis []int, h int) bool {
	n := 0
	for i := range vis {
		n += m.rowHeight(i)
		if n > h {
			return false
		}
	}
	return true
}

func (m Model) linesFrom(vis []int, a, b int) int {
	n := 0
	for i := a; i < b && i < len(vis); i++ {
		n += m.rowHeight(i)
	}
	return n
}

// The cursor row is the only row that costs two lines. Two lines for every row
// caps an 87 row terminal near 40 spans, and a real session logged 857.
func (m Model) rowHeight(i int) int {
	if i == m.cursor {
		return 2
	}
	return 1
}

// The tree box spends one inner line on the column strip, so the scroll math
// and treeBody have to read the same number or the cursor walks off the pane.
func (m Model) bodyHeight() int {
	return max(1, m.treeRows()-1)
}

func (m Model) visible() []int {
	return m.visibleRows
}

func (m Model) indexOf(idx int) int {
	for i, v := range m.visible() {
		if v == idx {
			return i
		}
	}
	return 0
}

func (m Model) ancestorOf(idx int) int {
	for i := idx - 1; i >= 0; i-- {
		if m.rows[i].depth < m.rows[idx].depth {
			return i
		}
	}
	return -1
}

func (m Model) marked() []int {
	if len(m.marks) == 0 {
		if idx := m.at(m.cursor); idx >= 0 {
			return []int{idx}
		}
		return nil
	}
	out := []int{}
	for i := range m.rows {
		if m.marks[m.idOf(i)] {
			out = append(out, i)
		}
	}
	if len(out) == 0 {
		if idx := m.at(m.cursor); idx >= 0 {
			out = append(out, idx)
		}
	}
	return out
}

// fit pads or truncates to an exact cell width. ansi.Truncate is the only safe
// cut here: it copies escape bytes through even past the cutoff, so a style
// never bleeds into the next column.
func fit(s string, width int) string {
	if width < 1 {
		return ""
	}
	s = ansi.Truncate(s, width, gl.ell)
	if w := ansi.StringWidth(s); w < width {
		s += strings.Repeat(" ", width-w)
	}
	return s
}

func rightFit(s string, width int) string {
	if width < 1 {
		return ""
	}
	s = ansi.Truncate(s, width, gl.ell)
	if w := ansi.StringWidth(s); w < width {
		s = strings.Repeat(" ", width-w) + s
	}
	return s
}

// clipWord cuts to width on a word boundary, and only cuts mid word when the
// boundary would throw away more than two fifths of the budget. ansi.Wordwrap
// wraps rather than clips, so the single line case is hand rolled.
func clipWord(s string, width int) string {
	if width < 1 {
		return ""
	}
	if ansi.StringWidth(s) <= width {
		return s
	}
	budget := width - ansi.StringWidth(gl.ell)
	if budget < 1 {
		return ansi.Truncate(s, width, "")
	}
	head := ansi.Truncate(s, budget, "")
	if cut := strings.LastIndexAny(head, " \t"); cut > 0 {
		if ansi.StringWidth(head[:cut])*5 >= budget*3 {
			head = head[:cut]
		}
	}
	return strings.TrimRight(head, " ") + gl.ell
}

// columns splits the row between the label, the preview and the numbers. A
// gantt track stood to the right of the numbers through several drafts. It
// measured the same thing as the time column beside it, and it cost up to 72
// cells to say it, so the preview is where those cells went instead.
// The actor column is the first thing dropped when the pane narrows. The guide
// tree still carries the nesting, so a narrow frame loses the least here.
func (m Model) columns(width int) (actor, text, meta, track int) {
	if width < 1 {
		return 0, 0, 0, 0
	}
	if width < minTextW+metaTight+1 {
		return 0, width, 0, 0
	}
	if width >= actorCol+1+minTextW+metaCol+2+20 {
		actor = actorCol
	}
	// The diff cell is the first of the three to go. Tokens and time answer a
	// question every row has an answer to; churn only applies to a write, and a
	// Claude Code trace carries none at all: 11 columns of header over 11
	// columns of blank, on every row.
	meta = metaTight
	if width >= minTextW+metaCol+2+actor {
		meta = metaCol
	}
	text = width - actor - meta - 1
	if actor > 0 {
		text--
	}
	// The track is off by default and takes its cells from the preview when it
	// is on, so the reader chooses which of the two the width buys.
	if m.timeline && text >= minTextW+minTrackW+1 {
		track = min(maxTrackW, text/3)
		text -= track + 1
	}
	if text > maxTextW {
		text = maxTextW
	}
	if text < 1 {
		text = 1
	}
	return actor, text, meta, track
}

// prefixWidth is the cell count before the label starts: the cursor bar, the
// state gutter, one space, and the actor column when it is on screen. rowLines,
// treeHead and onWedge all have to agree on it.
func (m Model) prefixWidth(width int) int {
	actor, _, _, _ := m.columns(width)
	if actor > 0 {
		return 3 + actor + 1
	}
	return 3
}

// The two text columns are measured, not shared by a constant. The label was a
// fixed 22 whatever the rows held, so `list_tools_for_client_uncached` clipped
// to `list_tools_for_clie…` beside a preview column that was empty on all 27
// rows.
//
// The preview takes what its widest row needs and the label takes the rest, so
// a run of bare span names spends nothing on an empty column and a run of shell
// commands still reads. Both are computed from the visible rows, so the split
// is stable while the reader scrolls and moves only when the content does.
func (m Model) textSplit(text int) (label, preview int) {
	floor := 10
	switch {
	case text >= 56:
		floor = 22
	case text >= 40:
		floor = 16
	}

	preview = min(m.wantPreview, max(0, text-floor-4))
	label = max(floor, text-preview-4)
	if label > text-4 {
		label = max(1, text-4)
	}
	// A label wider than it needs pushes the preview off the right edge for no
	// gain, so it never takes more than its widest row.
	if m.wantLabel > 0 && label > m.wantLabel {
		label = max(floor, m.wantLabel)
	}
	return label, max(0, text-label-4)
}

// tokens reads at a glance down a column, so it trades exactness for a fixed
// width: four significant figures at most, and blank for a span that bills none.
func tokens(n int) string {
	switch {
	case n <= 0:
		return ""
	case n < 1000:
		return fmt.Sprintf("%d", n)
	case n < 10000:
		return fmt.Sprintf("%.1fk", float64(n)/1000)
	default:
		return fmt.Sprintf("%dk", n/1000)
	}
}

// A parent rolls up the tokens of everything under it, because that is the
// question a turn row answers: what did this cost. Time never rolls up. Child
// spans overlap, so summing them double counts, and the parent already carries
// its own wall clock, which is the honest number.
func (m Model) rollup(idx int) int {
	total := m.rows[idx].in + m.rows[idx].out
	for i := idx + 1; i < len(m.rows) && m.rows[i].depth > m.rows[idx].depth; i++ {
		total += m.rows[i].in + m.rows[i].out
	}
	return total
}

// churn rolls up the same way tokens do, and for the same reason: a turn row is
// asked what it changed, not what its last child changed.
func (m Model) churn(idx int) (add, del, files int) {
	r := m.rows[idx]
	add, del, files = r.add, r.del, r.files
	for i := idx + 1; i < len(m.rows) && m.rows[i].depth > m.rows[idx].depth; i++ {
		add += m.rows[i].add
		del += m.rows[i].del
		files += m.rows[i].files
	}
	return add, del, files
}

// The diff cell keeps its own colours: added is always green and removed always
// red, on a failed row too, because those two numbers are not about the outcome.
// The file count only appears once a span touched more than one.
func (m Model) diffCell(idx, width int) string {
	add, del, files := m.churn(idx)
	if add == 0 && del == 0 && files == 0 {
		return strings.Repeat(" ", width)
	}
	// The counts are abbreviated the way tokens are, and the file count is the
	// first thing dropped. A turn that changed 11 files and 1056 lines needs 14
	// cells spelled out and the column has 11, so the deletions were clipped
	// away: the half of a churn figure a reader most wants to see.
	cell := ""
	if add > 0 {
		cell = live.Render("+" + tokens(add))
	}
	if del > 0 {
		if add > 0 {
			cell += " "
		}
		cell += bad.Render("-" + tokens(del))
	}
	if files > 1 && lipgloss.Width(cell)+3 <= width {
		cell = dim.Render(fmt.Sprintf("%d\u0192 ", files)) + cell
	}
	return rightFit(cell, width)
}

// Left to right the cells read as one sentence about the row: what it changed,
// what it cost, how long it took. Time sits last because it is the fact a
// reader scans down the column for, and the column ends at the frame edge.
func (m Model) metaCell(idx, width int) string {
	r := m.rows[idx]
	// A tool call costs no tokens. It carries the request's counts so a turn can
	// sum them, and printing them per row said every Shell call read 440k: the
	// same cached input, restated on twenty rows.
	tok := ""
	if r.kind != kindTool && r.kind != kindMCP && r.kind != kindSkill && r.kind != kindHook {
		tok = tokens(m.rollup(idx))
	}
	span := gl.dot
	if r.ms > 0 {
		span = duration(time.Duration(r.ms) * time.Millisecond)
	}
	style := dim
	if r.fail {
		style = bad
	}
	cost := m.diffCell(idx, width-timeCol-2)
	if strings.TrimSpace(cost) == "" {
		cost = rightFit(style.Render(tok), width-timeCol-2)
	}
	return cost + "  " + rightFit(style.Render(span), timeCol)
}

// The gutter marks a span that is still open. A failure needs no glyph here: the
// whole row is already red, which reads from further away than a symbol does.
func (m Model) state(idx int, r row) string {
	if m.running(idx) {
		return accent.Render("\u00b7")
	}
	return " "
}

// A gutter rule rather than a background colour row: lipgloss v1.1.0 resets a
// nested style before the outer background closes, so a filled cursor row tears.
func (m Model) bar(idx int) string {
	switch {
	case idx == m.at(m.cursor) && m.marks[m.idOf(idx)]:
		// Both states on one column. Without this arm the cursor arm won, so
		// marking the row under the cursor changed no pixel at all.
		return accent.Render(gl.mark)
	case idx == m.at(m.cursor):
		return accent.Render(gl.point)
	case m.marks[m.idOf(idx)]:
		return live.Render(gl.mark)
	default:
		return " "
	}
}

// The wedges are reserved for fold state only. Reusing them for role collided
// with the expander the owner already reads as "expand this" in neo-tree.
func (m Model) glyph(idx int, r row) string {
	if m.running(idx) {
		return m.spin.View() + " "
	}
	if !r.parent {
		return gl.leaf + " "
	}
	if m.folded[m.idOf(idx)] {
		return gl.unfold + " "
	}
	return gl.fold + " "
}

// guide draws one column per ancestor level: a rule where that ancestor still
// has siblings below, blank where it does not, and a tee or elbow at the row's
// own level. Folding does not change it, because a folded sibling still exists.
func (m Model) guide(idx int) string {
	return m.rows[idx].guide
}

// Five actors, five colours, and the prefix is the whole rule: @user is the
// person, @main is the session thread, @sub-* is a subagent it spawned,
// @team-* is a teammate running beside it, and @hook is the harness itself.
func actorStyle(actor string) lipgloss.Style {
	switch {
	case actor == "@user":
		return roleStyle(session.RoleTurn)
	case strings.HasPrefix(actor, "@sub-"):
		return roleStyle(session.RoleDelegate)
	case strings.HasPrefix(actor, "@team-"):
		return accent
	case actor == "@hook":
		return roleStyle(session.RoleSystem)
	default:
		return plain
	}
}

func (m Model) rowLines(vi, idx, width int) []string {
	r := m.rows[idx]
	actorW, textW, metaW, trackW := m.columns(width)
	labelW, prevW := m.textSplit(textW)
	style := roleStyle(roleOf[r.kind])
	if r.fail {
		style = bad
	}

	label := fit(m.guide(idx)+m.glyph(idx, r)+r.label, labelW)
	line := m.bar(idx) + m.state(idx, r) + " "
	if actorW > 0 {
		line += fit(actorStyle(r.actor).Render(r.actor), actorW) + " "
	}
	line += style.Render(label)
	if prevW > 0 {
		// A failed span carries its error in the preview, so the preview joins
		// the red. Red is now the only failure marker, so it has to reach far.
		text := dim
		if r.fail {
			text = bad
		}
		line += " " + fit(text.Render(clipWord(r.preview, prevW)), prevW)
	}
	if metaW > 0 {
		line += " " + m.metaCell(idx, metaW)
	}
	if trackW > 0 {
		style := live
		switch {
		case r.fail:
			style = bad
		case m.running(idx):
			style = accent
		}
		line += " " + m.gantt(idx, trackW, style)
	}

	if vi == m.cursor {
		rule := m.cursorRule(width)
		return []string{rule, fit(line, width), rule}
	}
	return []string{fit(line, width)}
}

// A rule above and below brackets the cursor row without repainting it, so the
// row keeps its own outcome colour.
func (m Model) cursorRule(width int) string {
	return faint.Render(strings.Repeat("\u2500", width))
}

func (m Model) treeHead(width int) string {
	actorW, textW, metaW, trackW := m.columns(width)
	labelW, prevW := m.textSplit(textW)
	line := "   "
	if actorW > 0 {
		line += fit("actor", actorW) + " "
	}
	line += fit("span", labelW)
	if prevW > 0 {
		line += " " + fit("preview", prevW)
	}
	if metaW > 0 {
		line += " " + rightFit("cost", metaW-timeCol-2) + "  " + rightFit("time", timeCol)
	}
	if trackW > 0 {
		_, span := m.window()
		label := duration(span)
		line += " " + fit("on screen", max(0, trackW-len(label))) + label
	}
	return faint.Render(fit(line, width))
}

func (m Model) treeBody(width, height int) string {
	vis := m.visible()
	body := []string{}
	for i := m.offset; i < len(vis) && len(body) < height; i++ {
		body = append(body, m.rowLines(i, vis[i], width)...)
	}
	if len(body) > height {
		body = body[:height]
	}
	// Slack always goes below the content. Blank rows above sparse content were
	// the single largest defect in the earlier drafts, at 62 percent dead rows.
	for len(body) < height {
		body = append(body, strings.Repeat(" ", width))
	}
	return strings.Join(body, "\n")
}

// A hook that fires on every event has no matcher, and a blank attribute value
// reads as a missing one, so say so.
func orDash(s string) string {
	if s == "" {
		return "*"
	}
	return s
}

// Every value here was a literal until now: the attribute pane printed
// tool_use_id "toolu_01Qk3mPd8Rax" and input_tokens "42,013" over every row,
// left from the fixture the layout was judged against. It read as real data and
// was not. Everything below comes off the span.

// sessionKeys are the attributes that describe the machine and the account
// rather than the span. Every span of a run carries the same values, so listing
// them beside the span's own attributes buries the four that differ.
var sessionKeys = map[string]bool{
	"host.arch": true, "os.type": true, "os.version": true,
	"service.name": true, "service.version": true, "service.namespace": true,
	"organization.id": true, "terminal.type": true,
	"user.id": true, "user.email": true, "user.account_id": true, "user.account_uuid": true,
	"telemetry.sdk.language": true, "telemetry.sdk.name": true, "telemetry.sdk.version": true,
}

// detailTags is the whole attribute list, span first and session last, for the
// attrs tab. Sorted, because a map has no order and a pane that reshuffles
// between frames cannot be read.
func (m Model) detailTags(r row) [][2]string {
	out := [][2]string{}
	if r.node == nil {
		return out
	}
	span := r.node.Span
	out = append(out,
		[2]string{"name", span.Name},
		[2]string{"span.id", orDash(span.SpanID)},
		[2]string{"trace.id", orDash(span.TraceID)},
	)
	if span.ParentID != "" {
		out = append(out, [2]string{"parent.id", span.ParentID})
	}
	if !span.Start.IsZero() {
		out = append(out, [2]string{"start", span.Start.Format("15:04:05.000")})
	}
	if r.ms > 0 {
		out = append(out, [2]string{"duration", duration(time.Duration(r.ms) * time.Millisecond)})
	}
	if span.Error != "" {
		out = append(out, [2]string{"error", span.Error})
	}
	own, shared := []string{}, []string{}
	for key := range span.Attrs {
		if sessionKeys[key] {
			shared = append(shared, key)
			continue
		}
		own = append(own, key)
	}
	sort.Strings(own)
	sort.Strings(shared)
	for _, key := range own {
		out = append(out, [2]string{key, span.Attrs[key]})
	}
	for _, key := range shared {
		out = append(out, [2]string{"session/" + key, span.Attrs[key]})
	}
	return out
}

// pinned is the handful of facts that stay under the pane whatever tab is open,
// so switching to the body never hides them. They are chosen per kind rather
// than taken off the front of detailTags, which is alphabetical and would pin
// whatever sorts first.
func (m Model) strip4(r row) [][2]string {
	attrs := map[string]string{}
	if r.node != nil {
		attrs = r.node.Span.Attrs
	}
	out := [][2]string{}
	add := func(k, v string) {
		if v != "" {
			out = append(out, [2]string{k, v})
		}
	}
	switch r.kind {
	case kindTurn:
		// The label beside this already says "turn 55", and the unit is in the
		// value: "spans 1 span" and "turn 55 · turn 55" were both in one strip.
		add("spans", strconv.Itoa(m.subtreeSize(r)))
		add("prompt", count(len(r.prompt()), "char"))
	case kindPrompt, kindThink:
		add("stop", first(attrs, "stop_reason", "gen_ai.response.finish_reasons"))
		add("out", num(attrs, "output_tokens"))
		if ms := number(attrs, "ttft_ms"); ms > 0 {
			add("first token", duration(time.Duration(ms)*time.Millisecond))
		}
	case kindHook:
		event, matcher, _ := strings.Cut(r.label, ":")
		add("event", event)
		add("matcher", orDash(matcher))
		add("source", r.src)
	default:
		// tool_name is the row's own label, and the strip already prints that.
		add("use id", first(attrs, "tool_use_id", "gen_ai.tool.call.id"))
		if out := r.output(); out != "" {
			add("output", count(len(out), "byte"))
		}
	}
	if r.ms > 0 {
		add("took", duration(time.Duration(r.ms)*time.Millisecond))
	}
	if r.fail {
		add("state", "failed")
	}
	return out
}

// plural names the unit; count says how many of it. Passing plural alone where
// count was meant printed "output bytes" with no number in front of it.
func count(n int, word string) string {
	return strconv.Itoa(n) + " " + plural(n, word)
}

// gantt draws one row's span against the rows on screen, not against the whole
// run. The first version scaled every bar to the run: a 54 minute run put a 30ms
// grep and a 3 minute build in the same cell, and scrolling changed nothing
// because the scale never moved. Scoped to the window, the bars answer the
// question a reader actually has here, which is what took the time in what they
// are looking at. The strip above the tree is what holds the whole run.
func (m Model) gantt(idx, width int, style lipgloss.Style) string {
	r := m.rows[idx]
	from, span := m.window()
	if width < 1 || r.node == nil || span <= 0 {
		return strings.Repeat(" ", max(0, width))
	}
	at := func(t time.Time) int {
		col := int(t.Sub(from) * time.Duration(width) / span)
		return min(width, max(0, col))
	}
	start, end := at(r.node.Start()), at(r.node.End())
	if end <= start {
		// Below one cell the bar cannot be proportional, so it says "a point
		// here" rather than claiming a length it does not have.
		end = start + 1
	}
	if end > width {
		start, end = width-1, width
	}
	body := style.Render(strings.Repeat(gl.fill, end-start))
	return strings.Repeat(" ", start) + body + strings.Repeat(" ", width-end)
}

// window is the time the rows on screen cover: the earliest start and the
// latest end among them. Both the bars and the track's own header read it, so
// the axis always names the scale the bars were drawn to.
func (m Model) window() (time.Time, time.Duration) {
	vis := m.visible()
	var from, to time.Time
	for i := m.offset; i < len(vis) && i < m.offset+m.treeRows(); i++ {
		node := m.rows[vis[i]].node
		if node == nil {
			continue
		}
		if from.IsZero() || node.Start().Before(from) {
			from = node.Start()
		}
		if to.IsZero() || node.End().After(to) {
			to = node.End()
		}
	}
	return from, to.Sub(from)
}

func onOff(b bool) string {
	if b {
		return "on"
	}
	return "off"
}

func (m Model) subtreeSize(r row) int {
	if r.node == nil {
		return 0
	}
	n := 0
	var walk func(*session.Node)
	walk = func(node *session.Node) {
		n++
		for _, kid := range node.Children {
			walk(kid)
		}
	}
	walk(r.node)
	return n
}

// One tab per way of reading a span. A span the tab has nothing to say about
// returns the empty string, and tabsFor drops it from the bar, so the reader
// never lands on a blank pane.
type paneTab struct {
	name string
	// A raw tab hands back finished ANSI. glamour would strip the tree rail and
	// re render the diff colour, so refresh sends a raw body straight to the
	// viewport.
	raw  bool
	body func(Model, row) string
	// A tab that has to see the whole selection at once, like the file tree,
	// sets all instead of body. all wins where both are set.
	all func(Model) string
}

var paneTabs = []paneTab{
	{name: "changes", raw: true, body: Model.tabChanges},
	// raw, because the body draws its own tree and glamour would strip the rail
	// and reflow the code under it.
	{name: "body", raw: true, body: Model.tabBody},
	// raw, because the table is already laid out to the pane and glamour would
	// reflow it back to markdown's own idea of a table.
	{name: "attrs", raw: true, body: Model.tabAttrs},
}

func (m Model) tabChanges(r row) string {
	if r.node == nil {
		return ""
	}
	patch := r.node.Patch
	if patch == "" && r.label == "Edit" && strings.Contains(r.node.Output, "@@") {
		patch = r.node.Output
	}
	files := diffview.Parse(normalizePatch(patch))
	if len(files) == 0 {
		return ""
	}
	return diffview.Render(diffview.Options{Files: files, Width: m.pane.Width})
}

func normalizePatch(patch string) string {
	if len(diffview.Parse(patch)) > 0 || !strings.Contains(patch, "@@") {
		return patch
	}
	b := &strings.Builder{}
	for _, line := range strings.Split(patch, "\n") {
		if path := strings.TrimSpace(strings.TrimPrefix(line, "## ")); strings.HasPrefix(line, "## ") && path != "" {
			fmt.Fprintf(b, "--- %s\n+++ %s\n", path, path)
			continue
		}
		b.WriteString(line + "\n")
	}
	return b.String()
}

func (m Model) tabsFor() []paneTab {
	out := []paneTab{}
	for _, t := range paneTabs {
		if t.all != nil {
			if strings.TrimSpace(t.all(m)) != "" {
				out = append(out, t)
			}
			continue
		}
		for _, idx := range m.marked() {
			if strings.TrimSpace(t.body(m, m.rows[idx])) != "" {
				out = append(out, t)
				break
			}
		}
	}
	return out
}

// The tab set changes as the cursor moves, so the index is normalised on read
// instead of clamped on write. A negative index wraps to the last tab.
func (m Model) tabAt() int {
	n := len(m.tabsFor())
	if n < 1 {
		return 0
	}
	return ((m.tab % n) + n) % n
}

// tabBody is the content half of the pane: what was asked, what was written,
// what came back. It names the section rather than the row, because the row's
// own name is in the tree, in the pane title and in the pinned strip, and a
// fourth copy of "claude-opus-5" told the reader nothing they had not read.
//
// No attribute appears here. The attrs tab holds all of them, and the table
// this used to print restated eight of them one tab away.
// tabBody draws the row as a tree of what it holds, not as a run of markdown
// headings. The headings version concatenated whatever was marked, so two marked
// rows rendered as "Prompt / open / --- / Response / -20251001", which is two
// placeholders and a separator and no content at all.
//
// A section is a branch. Its own text hangs under it, indented to the rail, so a
// long reply and a long tool output stay told apart while both scroll in one
// pane. The children are one line each: the tree above already holds them, and
// what a reader wants here is to see that they exist.
func (m Model) tabBody(r row) string {
	inner := max(24, m.detailWidth()-2)
	out := []string{m.bodyHead(r, inner)}
	parts := r.sections()
	for i, one := range parts {
		last := i == len(parts)-1 && len(m.kidLines(r)) == 0
		out = append(out, section(one, last, inner))
	}
	out = append(out, m.kidLines(r)...)
	if len(parts) == 0 && len(out) == 1 {
		out = append(out, faint.Render("  nothing recorded on this row"))
		if r.kind == kindPrompt || r.kind == kindThink {
			out = append(out, faint.Render("  add `transcript` to TRACES_PROVIDER to join the reply text"))
		}
	}
	return strings.Join(out, "\n")
}

// bodyHead names the row once, at the root of its own tree, with the two facts
// that frame everything under it.
func (m Model) bodyHead(r row, width int) string {
	head := roleStyle(roleOf[r.kind]).Render(r.label)
	facts := []string{}
	if r.ms > 0 {
		facts = append(facts, duration(time.Duration(r.ms)*time.Millisecond))
	}
	if r.fail {
		facts = append(facts, bad.Render("failed"))
	}
	if len(facts) > 0 {
		head += dim.Render("  "+gl.tick+"  ") + dim.Render(strings.Join(facts, dim.Render("  "+gl.tick+"  ")))
	}
	return fit(head, width)
}

// A part is one branch of the row: a name, the text under it, and whether the
// text is code. A reply is prose and reflows; a command is not and must not.
type part struct {
	name string
	text string
	code bool
}

func (r row) sections() []part {
	out := []part{}
	add := func(name, text string, code bool) {
		if strings.TrimSpace(text) != "" {
			out = append(out, part{name: name, text: text, code: code})
		}
	}
	if r.node != nil {
		add("prompt", r.node.Prompt, false)
		add("reasoning", r.node.Thinking, false)
		add("response", r.node.Text, false)
	}
	// The input is the row's argument wherever nothing above claimed it: a
	// tool's command, a hook's command, a delegate's task.
	if len(out) == 0 || r.kind == kindTool || r.kind == kindMCP || r.kind == kindSkill || r.kind == kindHook {
		cmd, hookOut, _ := strings.Cut(r.command(), "  ->  ")
		add("input", cmd, true)
		add("stderr", hookOut, true)
	}
	add("output", r.output(), true)
	return out
}

// section draws one branch and hangs its text under the rail, so the reader can
// see at a glance where one part of the row ends and the next begins.
func section(one part, last bool, width int) string {
	elbow, rail := gl.tee, gl.vert
	if last {
		elbow, rail = gl.elbow, gl.gap
	}
	head := rule.Render(elbow) + " " + tagKey.Render(one.name)
	body := []string{head}
	style := plain
	if one.code {
		style = dim
	}
	for _, ln := range bodyLines(one.text, max(8, width-len(rail)-2)) {
		body = append(body, rule.Render(rail)+" "+style.Render(ln))
	}
	return strings.Join(body, "\n")
}

// bodyLines wraps prose and leaves code alone but for the width, because a
// reflowed command is a command that no longer runs.
func bodyLines(text string, width int) []string {
	out := []string{}
	for _, raw := range strings.Split(strings.TrimRight(text, "\n"), "\n") {
		raw = strings.ReplaceAll(raw, "\t", "    ")
		if raw == "" {
			out = append(out, "")
			continue
		}
		out = append(out, wrapTo(raw, width)...)
	}
	return out
}

// kidLines names the row's children, one line each. A folded turn is the case
// this exists for: the pane says what is inside without the reader unfolding it.
func (m Model) kidLines(r row) []string {
	if r.node == nil || len(r.node.Children) == 0 {
		return nil
	}
	width := max(24, m.detailWidth()-2)
	kids := len(r.node.Children)
	head := fmt.Sprintf("%d children", kids)
	if kids == 1 {
		head = "1 child"
	}
	out := []string{rule.Render(gl.elbow) + " " + tagKey.Render(head)}
	for i, kid := range r.node.Children {
		if i == bodyKids {
			out = append(out, rule.Render(gl.gap)+" "+
				faint.Render(fmt.Sprintf("%d more", kids-bodyKids)))
			break
		}
		text := Line(kid)
		out = append(out, rule.Render(gl.gap)+" "+
			fit(roleStyle(kid.Role).Render(kid.Label)+dim.Render("  "+text), width-3))
	}
	return out
}

// Ten is what fits beside a section without pushing it off the pane. A turn with
// forty children is read in the tree, which is where forty rows belong.
const bodyKids = 10

func (m Model) tabAttrs(r row) string {
	tags := m.detailTags(r)
	if len(tags) == 0 {
		return ""
	}
	inner := max(20, m.detailWidth()-2)
	keyW := 0
	for _, kv := range tags {
		keyW = max(keyW, lipgloss.Width(kv[0]))
	}
	keyW = min(keyW, inner/3)
	valW := max(8, inner-keyW-2)

	out := []string{}
	for _, kv := range tags {
		// A session attribute is the same on every span of the run, so it is
		// dimmed rather than dropped: it is context, not a fact about this row.
		key, style := kv[0], tagText
		if rest, ok := strings.CutPrefix(key, "session/"); ok {
			key, style = rest, faint
		}
		for i, ln := range wrapTo(kv[1], valW) {
			gutter := tagKey.Render(fit(key, keyW))
			if i > 0 {
				gutter = strings.Repeat(" ", keyW)
			}
			out = append(out, gutter+"  "+style.Render(ln))
		}
	}
	return strings.Join(out, "\n")
}

// wrapTo breaks on width, and on a word where one is near enough the edge. A
// value is usually an id with no spaces in it, so a hard break has to work.
func wrapTo(s string, width int) []string {
	s = strings.ReplaceAll(s, "\t", "    ")
	s = strings.ReplaceAll(s, "\n", " ")
	if s == "" {
		return []string{""}
	}
	out := []string{}
	for lipgloss.Width(s) > width {
		cut := width
		if at := strings.LastIndexAny(s[:min(len(s), width)], " /,;"); at > width/2 {
			cut = at + 1
		}
		out = append(out, strings.TrimRight(s[:cut], " "))
		s = strings.TrimLeft(s[cut:], " ")
	}
	return append(out, s)
}

func first(attrs map[string]string, keys ...string) string {
	for _, k := range keys {
		if v := attrs[k]; v != "" {
			return v
		}
	}
	return ""
}

func num(attrs map[string]string, key string) string {
	if attrs[key] == "" {
		return ""
	}
	return fmt.Sprintf("%d", number(attrs, key))
}

func (m Model) rendered(src string) string {
	if m.md == nil {
		return src
	}
	out, err := m.md.Render(src)
	if err != nil {
		return src
	}
	return strings.TrimRight(out, "\n")
}

func (m Model) paneSource() string {
	tabs := m.tabsFor()
	if len(tabs) < 1 {
		return ""
	}
	t := tabs[m.tabAt()]
	if t.all != nil {
		return t.all(m)
	}
	parts := []string{}
	for _, idx := range m.marked() {
		if s := strings.TrimSpace(t.body(m, m.rows[idx])); s != "" {
			parts = append(parts, s)
		}
	}
	// A markdown rule between marked rows rendered as a bare "---" once the body
	// stopped being markdown. Each marked row is its own tree, so a blank line
	// is the whole separator they need.
	return strings.Join(parts, "\n\n")
}

// The viewport was constructed and sized in the earlier drafts but never fed,
// so a multi mark preview cut silently at the pane height with no way to scroll.
func (m Model) refresh() Model {
	src := m.paneSource()
	tabs := m.tabsFor()
	if len(tabs) > 0 && tabs[m.tabAt()].raw {
		m.pane.SetContent(src)
		return m
	}
	m.pane.SetContent(m.rendered(src))
	return m
}

// The bar names every reading available for the selection and marks the live
// one. tabCols reports where each name starts, so a click can pick one.
func (m Model) tabCols() []int {
	cols, x := []int{}, 0
	for _, t := range m.tabsFor() {
		cols = append(cols, x)
		x += lipgloss.Width(t.name) + 3
	}
	return cols
}

// tabTop draws the tab row into the pane's own top border, the way the charm
// tabs example seats a tab on the window frame. It was a separate line inside
// the box, which cost one row of content and printed the word "inspector" over
// a pane whose only possible identity was the inspector.
func (m Model) tabTop(inner int) string {
	tabs := m.tabsFor()
	at := m.tabAt()
	parts := []string{}
	for i, t := range tabs {
		if i == at {
			parts = append(parts, rule.Render(gl.tabL+" ")+title.Render(t.name)+rule.Render(" "+gl.tabR))
			continue
		}
		parts = append(parts, rule.Render(gl.h+" ")+dim.Render(t.name)+rule.Render(" "+gl.h))
	}
	head := rule.Render(gl.tl+gl.h) + strings.Join(parts, rule.Render(gl.h))
	// The percent earns its place only when the pane can actually scroll.
	tail := ""
	if m.pane.TotalLineCount() > m.pane.Height {
		tail = " " + dim.Render(fmt.Sprintf("%.0f%%", m.pane.ScrollPercent()*100)) + " "
	}
	fill := inner + 2 - lipgloss.Width(head) - lipgloss.Width(tail) - 1
	if fill < 0 {
		fill = 0
	}
	return head + rule.Render(strings.Repeat(gl.h, fill)) + tail + rule.Render(gl.tr)
}

// The attribute block has its own tab; the few facts a reader checks most stay
// pinned under the pane, so switching tabs never hides them. It names the row
// first, because the body tab no longer does.
func (m Model) paneStrip(width int) string {
	at := m.at(m.cursor)
	if at < 0 {
		return strings.Repeat(" ", max(0, width))
	}
	r := m.rows[at]
	parts := []string{roleStyle(roleOf[r.kind]).Render(r.label)}
	for _, kv := range m.strip4(r) {
		parts = append(parts, tagKey.Render(kv[0])+" "+tagText.Render(clipWord(kv[1], 22)))
	}
	return fit(strings.Join(parts, dim.Render("  \u00b7  ")), width)
}

// Three inner lines are chrome: the tab bar, the rule and the pinned strip.
// sized subtracts the same three from the viewport height.
func (m Model) paneView(inner int) string {
	return strings.Join([]string{
		m.pane.View(),
		rule.Render(strings.Repeat(gl.h, max(0, inner))),
		m.paneStrip(inner),
	}, "\n")
}

// boxWith is box, with the top border already drawn by the caller. The tab row
// is that border, so it cannot be handed in as a title string.
func boxWith(top string, inner int, body string) string {
	if inner < 1 {
		return body
	}
	out := []string{fit(top, inner+2)}
	for _, ln := range strings.Split(body, "\n") {
		out = append(out, rule.Render(gl.v)+fit(ln, inner)+rule.Render(gl.v))
	}
	out = append(out, rule.Render(gl.bl+strings.Repeat(gl.h, inner)+gl.br))
	return strings.Join(out, "\n")
}

func box(name string, inner int, body string) string {
	if inner < 1 {
		return body
	}
	dashes := inner - 3 - lipgloss.Width(name)
	if dashes < 0 {
		dashes = 0
	}
	// The dash count is inner-3-width, not inner-4: the fixed parts are corner,
	// rule, space, name, space, corner. The earlier draft ran one column short
	// on every frame, so the top border never met the body wall.
	top := rule.Render(gl.tl+gl.h+" ") + title.Render(name) +
		rule.Render(" "+strings.Repeat(gl.h, dashes)+gl.tr)
	out := []string{fit(top, inner+2)}
	for _, ln := range strings.Split(body, "\n") {
		out = append(out, rule.Render(gl.v)+fit(ln, inner)+rule.Render(gl.v))
	}
	out = append(out, rule.Render(gl.bl+strings.Repeat(gl.h, inner)+gl.br))
	return strings.Join(out, "\n")
}

// State is spelled out, never carried by colour alone. A saved frame has no
// escape bytes, so a green "follow" flag and a grey one read identically.
func (m Model) head() string {
	// Built right to left. The flags are fixed facts about what the view is
	// doing and the name is elastic, so the name is what gives way. Growing the
	// left side first truncated the flags instead, and the header read
	// "1632 shown …" with no follow state on it at all.
	flags := []string{}
	if m.follow {
		flags = append(flags, live.Render("follow"))
	} else {
		flags = append(flags, faint.Render("no follow"))
	}
	if m.anchor {
		flags = append(flags, plain.Render("newest last"))
	} else {
		flags = append(flags, plain.Render("scroll free"))
	}
	if m.timeline {
		flags = append(flags, plain.Render("timeline"))
	}
	// The shown and total counts moved to the tree box title, which is the box
	// they count. Two copies of one number cost the name its room.
	right := strings.Join(flags, dim.Render("  \u00b7  "))

	who := "no session"
	if m.current != nil {
		who = m.current.Service + " " + m.current.Short()
	}
	left := title.Render("traces") + dim.Render("  "+who)
	// The typed text shows the moment it is typed, and the applied query is
	// what the tree is drawn from. While they differ the header carries a
	// caret, so a pause never reads as a dropped keystroke.
	if m.typed != "" || m.filter {
		left += accent.Render("  /" + m.typed)
		if m.filter {
			left += cursor.Render(" ")
		}
		if m.typed != m.query {
			left += faint.Render(gl.ell)
		}
	}
	if m.current != nil {
		if name := m.current.Name(); name != "" && name != m.current.Short() {
			room := m.width - lipgloss.Width(left) - lipgloss.Width(right) - 6
			if room > 12 {
				left += dim.Render("  " + clipWord(name, room))
			}
		}
	}
	gap := m.width - lipgloss.Width(left) - lipgloss.Width(right)
	if gap < 1 {
		gap = 1
	}
	// head is the one chrome line the earlier draft never clamped, so an
	// overflow wrapped and every row budget below it went wrong.
	return fit(left+strings.Repeat(" ", gap)+right, m.width)
}

// The divider is a plain border until it says otherwise, so it carries a short
// dashed grip. A drag target with no mark on it is a target nobody finds.
func withGrip(tree string, inner int) string {
	lines := strings.Split(tree, "\n")
	if len(lines) < 2 || inner < 16 {
		return tree
	}
	grip := strings.Repeat(gl.dot, 8)
	left := (inner - 8) / 2
	lines[len(lines)-1] = rule.Render(gl.bl+strings.Repeat(gl.h, left)) +
		title.Render(grip) + rule.Render(strings.Repeat(gl.h, inner-left-8)+gl.br)
	return strings.Join(lines, "\n")
}

func (m Model) footer() string {
	if m.status != "" {
		return fit(accent.Render(m.status), m.width)
	}
	if m.pending != "" {
		return fit(accent.Render(m.pending+"…")+dim.Render("  a fold  R open all  M close all  x focus"), m.width)
	}
	if m.cmd {
		return m.commandBar(m.width)
	}
	if m.filter {
		return fit(accent.Render("/"+m.typed)+cursor.Render(" ")+dim.Render("   enter keep   esc clear"), m.width)
	}
	if m.visual {
		return fit(accent.Render("visual")+dim.Render("   j k extend   enter keep   esc cancel"), m.width)
	}
	// The bar names the focused window first, because every motion below it
	// lands there and a reader who has moved focus has no other way to tell.
	hint := "j k trace   d u inspector   { } turn   v range   V turn   m subtree   / filter   : command   - = size   ? help"
	return fit(dim.Render(hint), m.width)
}

func (m Model) leaderBar() string {
	keys := []string{"f follow", "o anchor", "t timeline", "s session", "a all", "m one row", "i inspector", "y yank raw", "? help"}
	if m.pending == "i" {
		keys = []string{"i toggle", "h left", "j bottom", "k top", "l right"}
	}
	return fit(accent.Render("<space>")+dim.Render("  "+strings.Join(keys, "   ")), m.width)
}

var helpTable = [][2]string{
	{"j / k", "move one row in the trace"},
	{"ctrl+d / ctrl+u", "half page the trace  (ctrl+f and ctrl+b page it whole)"},
	{"d / u", "half page the inspector  (ctrl+e and ctrl+y scroll it one line)"},
	{"gg / G", "first row / last row and resume follow"},
	{"H / M / L", "cursor to the top, middle or bottom of the view"},
	{"{ / }", "previous turn / next turn  ([t and ]t also work)"},
	{"n / N", "next row / previous row of the current filter"},
	{"/", "filter the tree by text  (esc clears it)"},
	{"h / l", "collapse or step out / expand"},
	{"za / zo / zc", "toggle, open or close the fold under the cursor"},
	{"zR / zM", "open every fold / close every fold"},
	{"zx", "close all, then open the path to the cursor"},
	{"v", "range: j k extend, enter or v keep, esc cancel"},
	{"V / enter", "toggle the whole turn the cursor sits in"},
	{"m", "toggle the row and its whole subtree"},
	{"esc", "cancel a range, or clear every mark"},
	{"Y", "yank the row's whole text to the clipboard"},
	{"e", "open the row's whole text in $EDITOR"},
	{"tab / shift+tab", "next inspector tab / previous"},
	{"- / =", "move the divider  (dragging it does the same)"},
	{"click / wheel", "select a row, fold on the wedge, pick a tab, scroll either pane"},
	{"<space> t", "timeline: draw each row's span beside it"},
	{"<space> i", "inspector: i toggle, h left, j bottom, k top, l right"},
	{"<space>", "leader: f follow, o anchor, s session, a all, m one row, e edit, y yank, ? help"},
	{":", "command line: :w <path>, :turn 40, :set notimeline, :session <id>"},
	{"ZZ / q", "quit"},
}

func viewHelp(width, height int) string {
	lines := []string{}
	for _, h := range helpTable {
		lines = append(lines, accent.Render(fit(h[0], 18))+plain.Render(h[1]))
	}
	// m is bound to mark here and to move in neo-tree. traces has no move, so the
	// key is free; v stays open because neo-tree uses it for a vertical split.
	lines = append(lines, "", dim.Render("The trace takes j k; the inspector takes d u. Neither needs a focus mode."))
	for len(lines) < height-2 {
		lines = append(lines, "")
	}
	return box("keys", width-2, strings.Join(lines[:max(0, height-2)], "\n"))
}

// The cursor row costs two lines, so a tree body under two lines can never
// hold it. Below this the frame either clips the cursor or overruns the pane.
const (
	minWidth  = 40
	minHeight = 8
)

func viewTooSmall(w, h int) string {
	if w < 1 || h < 1 {
		return ""
	}
	out := make([]string, h)
	for i := range out {
		out[i] = strings.Repeat(" ", w)
	}
	msgs := []string{
		fmt.Sprintf("traces needs %dx%d", minWidth, minHeight),
		fmt.Sprintf("this pane is %dx%d", w, h),
	}
	for i, msg := range msgs {
		row := h/2 - 1 + i
		if row < 0 || row >= h {
			continue
		}
		left := max(0, (w-lipgloss.Width(msg))/2)
		out[row] = fit(strings.Repeat(" ", left)+plain.Render(msg), w)
	}
	return strings.Join(out, "\n")
}

func (m Model) View() string {
	if m.width < minWidth || m.height < minHeight {
		return viewTooSmall(m.width, m.height)
	}
	if m.help {
		return viewHelp(m.width, m.height)
	}
	if m.picking {
		return m.viewPick()
	}
	if len(m.rows) == 0 {
		waiting := "waiting for spans in " + m.source
		switch {
		case m.query != "":
			waiting = "no row matches /" + m.query
		case m.store.Scoped() && len(m.list) == 0:
			// The scope is the reason, and without saying so the frame reads as
			// a broken source rather than as a directory with no run in view.
			waiting = "no run from this directory in " + m.source + "; -all shows every run"
		}
		return m.head() + "\n\n" + faint.Render(waiting) + "\n\n" + m.footer()
	}
	inner := max(1, m.treeWidth()-2)
	tree := box(fmt.Sprintf("trace  %d shown of %d  \u00b7  %s", len(m.visible()), len(m.rows), m.runFor()),
		inner, m.treeHead(inner)+"\n"+m.treeBody(inner, m.bodyHeight()))

	// The strip belongs to the tree and reads as its scale, so it sits against
	// it. With the inspector below, that puts it between the two, which is
	// where a scrubber belongs: at the boundary, not off at the frame's top.
	main := tree + "\n" + m.strip(m.width)
	if p := m.placeAt(); p != placeHidden {
		pw := max(1, m.detailWidth()-2)
		pane := boxWith(m.tabTop(pw), pw, m.paneView(pw))
		switch p {
		case placeBottom:
			main = withGrip(tree, inner) + "\n" + m.strip(m.width) + "\n" + pane
		case placeTop:
			main = pane + "\n" + m.strip(m.width) + "\n" + tree
		case placeLeft:
			main = lipgloss.JoinHorizontal(lipgloss.Top, pane, tree) + "\n" + m.strip(m.width)
		case placeRight:
			main = lipgloss.JoinHorizontal(lipgloss.Top, tree, pane) + "\n" + m.strip(m.width)
		}
	}

	bottom := m.footer()
	if m.leader || m.pending == "i" {
		bottom = m.leaderBar()
	}
	return strings.Join([]string{m.head(), main, bottom}, "\n")
}

// strip is the whole run on one line, above the tree. A gantt column stood to
// the right of every row before this and was removed: it was indexed by wall
// clock, so one 3 minute Bash call in a 54 minute run left every other span a
// sliver, and it cost up to 72 cells of preview to say it.
//
// This is indexed by row instead, which is what zoetrope calls event indexing:
// a busy minute gets room rather than collapsing. Each cell takes the colour of
// the strongest thing inside it, and the bar is where the cursor sits, so the
// reader can see their position in a run that is 200 rows longer than the pane.
func (m Model) strip(width int) string {
	vis := m.visible()
	if width < 1 {
		return ""
	}
	if len(vis) == 0 {
		return faint.Render(strings.Repeat(gl.dot, width))
	}
	// A cell holds the strongest row in its slice, so one failure in forty rows
	// still shows. Without the rank a later row simply overwrote an earlier one
	// and the mark a reader is scanning for was a coin flip.
	rank := make([]int, width)
	ink := make([]lipgloss.Style, width)
	for at, idx := range vis {
		col := at * width / len(vis)
		if col >= width {
			col = width - 1
		}
		r := m.rows[idx]
		if got := stripRank(r); got > rank[col] {
			rank[col], ink[col] = got, roleStyle(roleOf[r.kind])
			if r.fail {
				ink[col] = bad
			}
		}
	}
	here := m.cursor * width / len(vis)
	if here >= width {
		here = width - 1
	}
	cells := make([]string, width)
	for i := range cells {
		switch {
		case i == here:
			cells[i] = cursor.Render(gl.playhead)
		case rank[i] == 0:
			cells[i] = faint.Render(gl.dot)
		case rank[i] <= 2:
			// A run alternates model call and tool call, so drawing those as
			// blocks made the strip one solid bar and the landmarks a reader
			// scans for vanished into it. They are the baseline instead, and
			// only a turn, a delegate and a failure rise off it.
			cells[i] = ink[i].Render(gl.dot)
		default:
			cells[i] = ink[i].Render(gl.block)
		}
	}
	return strings.Join(cells, "")
}

// The order is what a reader scans the strip for: a failure first, then the
// turn boundaries that divide the run, then the model calls that shape it.
func stripRank(r row) int {
	switch {
	case r.fail:
		return 5
	case r.kind == kindTurn:
		return 4
	case r.kind == kindSub, r.kind == kindTeam:
		return 3
	case r.kind == kindPrompt, r.kind == kindThink:
		return 2
	}
	return 1
}

// A span with no end has not returned yet, so its row wears
// the spinner in place of a leaf glyph.
func (m Model) running(idx int) bool {
	if idx < 0 || idx >= len(m.rows) || m.rows[idx].node == nil {
		return false
	}
	node := m.rows[idx].node
	return node.Pending || node.Span.End.IsZero() || node.Span.End.Before(node.Span.Start)
}

// The tree's first body line sits at treeTop, which is Y=3 unless the inspector
// took the top. A cursor row is two lines tall, which rowHeight knows.
func (m Model) rowAtY(y int) int {
	vis := m.visible()
	line := y - m.treeTop()
	if line < 0 || line >= m.treeRows() {
		return -1
	}
	for i := m.offset; i < len(vis); i++ {
		if line < m.rowHeight(i) {
			return i
		}
		line -= m.rowHeight(i)
	}
	return -1
}

// The label starts at prefixWidth, and the guide spends two cells per depth
// level. So the fold wedge of a row at depth d sits at that offset plus 2*d,
// and the box border adds one more on screen.
func (m Model) onWedge(vi, x int) bool {
	idx := m.at(vi)
	if !m.rows[idx].parent {
		return false
	}
	wedge := m.treeLeft() + 1 + m.prefixWidth(m.treeWidth()) + 2*m.rows[idx].depth
	return x >= wedge && x <= wedge+1
}

// inPane is the complement of the tree box on whichever edge the inspector
// took, so a wheel event lands in exactly one of the two.
func (m Model) inPane(msg tea.MouseMsg) bool {
	switch m.placeAt() {
	case placeBottom:
		return msg.Y > m.dividerY()
	case placeTop:
		return msg.Y < m.detailLines()+1
	case placeLeft:
		return msg.X < m.detailCols()
	case placeRight:
		return msg.X >= m.treeWidth()
	}
	return false
}

// paneTop is the screen row of the inspector's tab bar, the first inner row
// below its top border.
func (m Model) paneTop() int {
	if m.placeAt() == placeBottom {
		return m.dividerY() + 2
	}
	return 2
}

func (m Model) paneLeft() int {
	if m.placeAt() == placeRight {
		return m.treeWidth()
	}
	return 0
}

func (m Model) mouse(msg tea.MouseMsg) (tea.Model, tea.Cmd) {
	// A press on the divider grabs it, and the grab outranks both panes until
	// the button comes back up. Without the grab, one fast drag past the row
	// drops the resize and selects a span instead.
	switch {
	case msg.Action == tea.MouseActionRelease:
		m.drag = false
		return m, nil
	case m.drag:
		return m.resizeTo(msg.Y), nil
	case msg.Action == tea.MouseActionPress && msg.Button == tea.MouseButtonLeft &&
		m.placeAt() == placeBottom && msg.Y == m.dividerY():
		m.drag = true
		m.status = "drag the divider to resize"
		return m, nil
	}

	if m.inPane(msg) {
		// A click on the tab bar picks that tab. The bar is the pane's first
		// inner row, one below the inspector top border.
		if msg.Action == tea.MouseActionPress && msg.Button == tea.MouseButtonLeft && msg.Y == m.paneTop() {
			x := msg.X - m.paneLeft() - 1
			for i, col := range m.tabCols() {
				if x >= col {
					m.tab = i
				}
			}
			return m.clamp(), nil
		}
		// The viewport already answers a wheel event, so forwarding it is the
		// whole implementation for the pane.
		var cmd tea.Cmd
		m.pane, cmd = m.pane.Update(msg)
		return m, cmd
	}

	switch {
	case msg.Button == tea.MouseButtonWheelDown:
		m.cursor, m.follow = m.cursor+1, false
	case msg.Button == tea.MouseButtonWheelUp:
		m.cursor, m.follow = m.cursor-1, false
	case msg.Action == tea.MouseActionPress && msg.Button == tea.MouseButtonLeft:
		vi := m.rowAtY(msg.Y)
		if vi < 0 {
			return m, nil
		}
		wedge := m.onWedge(vi, msg.X)
		m.cursor, m.follow = vi, false
		if wedge {
			m.toggleFold()
		}
	}
	return m.clamp(), nil
}

// currentAt is where the attached session sits in the list, so the picker opens
// on the run the reader is already watching.
func (m Model) currentAt() int {
	for i, one := range m.list {
		if m.current != nil && one.Key == m.current.Key {
			return i
		}
	}
	return 0
}

// The picker is a list, not a pane: a reader reaches for it to change what they
// are watching, then leaves. Attaching resets the cursor, because a row index
// means nothing in another run.
func (m Model) pickKey(k string) (tea.Model, tea.Cmd) {
	switch k {
	case "q", "ctrl+c":
		return m, tea.Quit
	case "esc", "s":
		m.picking = false
		return m, nil
	case "j", "down":
		m.pickAt = min(len(m.list)-1, m.pickAt+1)
	case "k", "up":
		m.pickAt = max(0, m.pickAt-1)
	case "enter":
		if m.pickAt < len(m.list) {
			m.current = m.list[m.pickAt]
			// A pin names one run. Attaching to another is the reader
			// overriding that, so the pin has to go or reload would undo it.
			m.pinned = ""
			m.marks = map[string]bool{}
			m.folded = map[string]bool{}
			m.updateVisibility()
			m.rebuild()
			m.cursor, m.offset, m.follow = max(0, len(m.rows)-1), 0, true
		}
		m.picking = false
		return m.clamp(), nil
	}
	return m, nil
}

// The filter reads text a keystroke at a time rather than through a textinput,
// because one line of query does not earn a component and its own focus rules.
// A rebuild walks every span in the run, and typing a six letter filter ran six
// of them over 900 spans while the reader was still on the second letter. The
// query is applied after a pause instead: each keystroke stamps a tag and
// schedules a tick carrying it, and only the tick whose tag is still current
// does the work. This is the debounce pattern from the charm example.
const filterPause = 120 * time.Millisecond

type filterMsg int

func (m Model) filterKey(msg tea.KeyMsg, k string) (tea.Model, tea.Cmd) {
	switch k {
	case "esc":
		m.filter, m.typed, m.query = false, "", ""
		m.rebuild()
		return m.clamp(), nil
	case "enter":
		m.filter = false
		// Enter commits at once. Waiting out the pause after an explicit
		// commit would show the reader the previous query's tree.
		m.query = m.typed
		m.rebuild()
		return m.clamp(), nil
	case "backspace":
		if m.typed != "" {
			m.typed = m.typed[:len(m.typed)-1]
		}
		return m.debounce()
	}
	if len(msg.Runes) > 0 {
		m.typed += string(msg.Runes)
	}
	return m.debounce()
}

func (m Model) debounce() (tea.Model, tea.Cmd) {
	m.tag++
	tag := m.tag
	return m, tea.Tick(filterPause, func(time.Time) tea.Msg { return filterMsg(tag) })
}

// viewPick is the whole frame while the picker is open, because a list of runs
// competing with a tree for the same rows reads as neither.
func (m Model) viewPick() string {
	b := &strings.Builder{}
	b.WriteString(title.Render("traces") + dim.Render("  attach to a session") + "\n\n")
	for i, one := range m.list {
		mark := "  "
		style := plain
		if i == m.pickAt {
			mark, style = accent.Render(gl.point)+" ", accent
		}
		b.WriteString(fit(mark+style.Render(fmt.Sprintf("%-12s %-40s %5d items  %s",
			one.Service, one.Title(), one.ViewCount(), ago(one.Last, m.now))), m.width) + "\n")
	}
	b.WriteString("\n" + faint.Render("j k move   enter attach   esc cancel   q quit"))
	return b.String()
}

func copyMarks(in map[string]bool) map[string]bool {
	out := make(map[string]bool, len(in))
	for key, held := range in {
		out[key] = held
	}
	return out
}

// paintRange rewrites the marks as everything marked before the range opened,
// plus every visible row between the anchor and the cursor. Recomputing beats
// marking as you go: a reader who overshoots and comes back expects the range
// to shrink.
func (m *Model) paintRange() {
	if !m.visual {
		return
	}
	m.marks = copyMarks(m.before)
	vis := m.visible()
	if len(vis) == 0 {
		return
	}
	lo, hi := m.anchorAt, m.cursor
	if lo > hi {
		lo, hi = hi, lo
	}
	lo, hi = max(0, lo), min(len(vis)-1, hi)
	for i := lo; i <= hi; i++ {
		m.marks[m.idOf(vis[i])] = true
	}
}

// markAll is a toggle, because the reader who marked everything to read it in
// the inspector is the same reader who wants it all off again.
func (m *Model) markAll() {
	if len(m.marks) >= len(m.rows) && len(m.rows) > 0 {
		m.marks = map[string]bool{}
		m.status = "marks cleared"
		return
	}
	m.marks = make(map[string]bool, len(m.rows))
	for i := range m.rows {
		m.marks[m.idOf(i)] = true
	}
	m.status = fmt.Sprintf("%d rows marked", len(m.rows))
}

// runFor is the attached run's own length. It titles the tree box, which is the
// one place the whole run is described; every row's own time is its own column.
func (m Model) runFor() string {
	if m.current == nil {
		return "0s"
	}
	return duration(m.current.Last.Sub(m.current.First))
}
