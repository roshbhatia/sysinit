package ui

import (
	_ "embed"
	"fmt"
	"os"
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
	fill, dot, tick, ell  string
}

var narrowGlyphs = glyphSet{
	tl: "╭", tr: "╮", bl: "╰", br: "╯", h: "─", v: "│",
	point: "▌", mark: "┃",
	vert: "╎ ", tee: "├╌", elbow: "╰╌", gap: "  ",
	fold: "▾", unfold: "▸", leaf: " ",
	fill: "╍", dot: "╌", tick: "·", ell: "…",
}

var asciiGlyphs = glyphSet{
	tl: "+", tr: "+", bl: "+", br: "+", h: "-", v: "|",
	point: "|", mark: "#",
	vert: ": ", tee: "+-", elbow: "\\-", gap: "  ",
	fold: "v", unfold: ">", leaf: " ",
	fill: "=", dot: "-", tick: ".", ell: "...",
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
	tokenCol  = 6
	timeCol   = 6
	diffCol   = 11
	metaCol   = diffCol + tokenCol + timeCol + 4
	metaTight = tokenCol + timeCol + 2
	actorCol  = 12
	minTextW  = 26
	maxTextW  = 148
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
}

type Model struct {
	store   *session.Store
	current *session.Session
	list    []*session.Session
	pinned  string
	source  string
	query   string

	rows   []row
	cursor int
	offset int
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

	pending string
	status  string
	picking bool
	pickAt  int
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
	m.rebuild()
}

// rebuild flattens the session tree into the row list the layout draws.
func (m *Model) rebuild() {
	m.rows = nil
	if m.current == nil {
		return
	}
	first := m.current.First
	span := m.current.Last.Sub(first)
	query := strings.ToLower(strings.TrimSpace(m.query))
	for _, root := range m.current.Roots {
		m.walk(root, 0, first, span, query)
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
	case tickMsg:
		m.now = msg.t
		return m, tick()
	case BatchMsg:
		before := len(m.rows)
		m.store.Add(msg.Spans)
		m.store.AddRecords(msg.Records)
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
	rows := max(1, m.height-4)
	if m.vertical() {
		rows = max(3, rows-m.detailLines())
	}
	return rows
}

// treeTop is the screen row of the tree's first body line, and treeLeft the
// screen column of its first inner cell. Every mouse hit test starts here.
func (m Model) treeTop() int {
	if m.placeAt() == placeTop {
		return m.detailLines() + 3
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

	if m.leader {
		m.leader = false
		switch k {
		case "f":
			m.follow = !m.follow
		case "o":
			m.anchor = !m.anchor
		case "d":
			return m.dock(placeHidden), nil
		case "i":
			m.pending = "i"
			m.status = "i again to toggle, h j k l to dock"
			return m.clamp(), nil
		case "y":
			return m.yank(), nil
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
		case "zR", "ZZ":
			m.folded = map[string]bool{}
		case "zM":
			m.foldAll()
		case "zx":
			m.foldAll()
			m.openPath()
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
		case "gg":
			m.cursor, m.follow = 0, false
		case "]t":
			m.jump(1)
		case "[t":
			m.jump(-1)
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
	case "z", "g", "]", "[":
		m.pending = k
		return m, nil
	case "Z":
		// neo-tree parity: bare Z expands every node.
		m.folded = map[string]bool{}
		return m.clamp(), nil
	case "s":
		if len(m.list) > 1 {
			m.picking = true
			m.pickAt = m.currentAt()
		}
		return m, nil
	case "/":
		m.filter = true
		return m, nil
	case "j", "down":
		m.cursor, m.follow = m.cursor+1, false
		m.paintRange()
	case "k", "up":
		m.cursor, m.follow = m.cursor-1, false
		m.paintRange()
	case "d", "ctrl+d":
		return m.halfPage(1), nil
	case "u", "ctrl+u":
		return m.halfPage(-1), nil
	case "D", "ctrl+f":
		m.pane.HalfPageDown()
		return m, nil
	case "U", "ctrl+b":
		m.pane.HalfPageUp()
		return m, nil
	case "-", "_", "J":
		return m.resize(-6), nil
	case "=", "+", "K":
		return m.resize(6), nil
	case "tab":
		m.tab = m.tabAt() + 1
		return m.clamp(), nil
	case "shift+tab":
		m.tab = m.tabAt() - 1
		return m.clamp(), nil
	case "G":
		m.cursor, m.follow = len(m.visible())-1, true
	case "n":
		m.jump(1)
	case "p":
		m.jump(-1)
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
	case "A":
		m.markAll()
		return m.clamp(), nil
	case "m":
		m.markSubtree(m.at(m.cursor))
	case "h":
		m.collapse()
	case "l":
		m.expand()
	case "enter":
		if m.visual {
			m.visual, m.before = false, nil
			m.status = "range kept"
			return m.clamp(), nil
		}
		// markSubtree reads the root's own state, so a second press turns the
		// whole turn back off.
		m.markTurn(m.at(m.cursor))
	case "M":
		m.markRow(m.at(m.cursor))
	// shift+enter only reaches a v1 app over the kitty keyboard protocol, so
	// "A" carries the same binding for every other terminal.
	case "shift+enter":
		m.markAll()
	case "o":
		m.anchor = !m.anchor
	case "Y":
		return m.yank(), nil
	}
	return m.clamp(), nil
}

// yank reports the verbatim bytes behind the cursor row. glamour is always on
// and has no toggle, so this is the only way to recover text it reflowed
// or that the tree pane truncated.
func (m Model) yank() Model {
	r := m.rows[m.at(m.cursor)]
	src := r.preview
	if r.kind == kindTurn {
		src = r.prompt()
	}
	m.status = fmt.Sprintf("yanked %d bytes verbatim", len(src))
	return m
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
}

func (m *Model) foldAll() {
	for i, r := range m.rows {
		if r.parent {
			m.folded[m.idOf(i)] = true
		}
	}
}

func (m *Model) openPath() {
	for i := m.at(m.cursor); i >= 0 && i < len(m.rows); i = m.ancestorOf(i) {
		delete(m.folded, m.idOf(i))
		if m.rows[i].depth == 0 {
			break
		}
	}
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
}

func (m *Model) expand() {
	idx := m.at(m.cursor)
	if idx < 0 {
		return
	}
	if m.rows[idx].parent {
		delete(m.folded, m.idOf(idx))
	}
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
	total := m.linesFrom(vis, 0, len(vis))
	switch {
	case total <= h:
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
	out := []int{}
	hide := -1
	for i, r := range m.rows {
		if hide >= 0 && r.depth > m.rows[hide].depth {
			continue
		}
		hide = -1
		out = append(out, i)
		if r.parent && m.folded[m.idOf(i)] {
			hide = i
		}
	}
	return out
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
func (m Model) columns(width int) (actor, text, meta int) {
	if width < 1 {
		return 0, 0, 0
	}
	if width < minTextW+metaTight+1 {
		return 0, width, 0
	}
	if width >= actorCol+1+minTextW+metaCol+2+20 {
		actor = actorCol
	}
	// The diff cell is the first of the three to go. Tokens and time answer a
	// question every row has an answer to; churn only applies to a write, and a
	// Claude Code trace carries none at all: 11 columns of header over 11
	// columns of blank, on every row.
	meta = metaTight
	if m.churny() && width >= minTextW+metaCol+2+actor {
		meta = metaCol
	}
	text = width - actor - meta - 1
	if actor > 0 {
		text--
	}
	if text > maxTextW {
		text = maxTextW
	}
	if text < 1 {
		text = 1
	}
	return actor, text, meta
}

// prefixWidth is the cell count before the label starts: the cursor bar, the
// state gutter, one space, and the actor column when it is on screen. rowLines,
// treeHead and onWedge all have to agree on it.
func (m Model) prefixWidth(width int) int {
	actor, _, _ := m.columns(width)
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
// churny reports whether any visible row moved a line. The diff cell is drawn
// for the whole tree or for none of it, because a column that appears when the
// filter changes moves every other column with it.
func (m Model) churny() bool {
	for _, idx := range m.visible() {
		r := m.rows[idx]
		if r.add > 0 || r.del > 0 || r.files > 0 {
			return true
		}
	}
	return false
}

func (m Model) textSplit(text int) (label, preview int) {
	floor := 10
	switch {
	case text >= 56:
		floor = 22
	case text >= 40:
		floor = 16
	}

	wantLabel, wantPreview := 0, 0
	for _, idx := range m.visible() {
		r := m.rows[idx]
		if w := lipgloss.Width(r.label) + lipgloss.Width(m.guide(idx)); w > wantLabel {
			wantLabel = w
		}
		if w := lipgloss.Width(r.preview); w > wantPreview {
			wantPreview = w
		}
	}

	preview = min(wantPreview, max(0, text-floor-4))
	label = max(floor, text-preview-4)
	if label > text-4 {
		label = max(1, text-4)
	}
	// A label wider than it needs pushes the preview off the right edge for no
	// gain, so it never takes more than its widest row.
	if wantLabel > 0 && label > wantLabel {
		label = max(floor, wantLabel)
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
	cell := ""
	if files > 1 {
		cell = dim.Render(fmt.Sprintf("%d\u0192 ", files))
	}
	if add > 0 {
		cell += live.Render(fmt.Sprintf("+%d", add))
	}
	if del > 0 {
		if add > 0 {
			cell += " "
		}
		cell += bad.Render(fmt.Sprintf("-%d", del))
	}
	return rightFit(cell, width)
}

// Left to right the cells read as one sentence about the row: what it changed,
// what it cost, how long it took. Time sits last because it is the fact a
// reader scans down the column for, and the column ends at the frame edge.
func (m Model) metaCell(idx, width int) string {
	r := m.rows[idx]
	tok := tokens(m.rollup(idx))
	span := ""
	if r.ms > 0 {
		span = duration(time.Duration(r.ms) * time.Millisecond)
	}
	style := dim
	if r.fail {
		style = bad
	}
	cell := ""
	if width >= metaCol {
		cell = m.diffCell(idx, diffCol) + "  "
		width -= diffCol + 2
	}
	return cell + rightFit(style.Render(tok), tokenCol) + "  " +
		rightFit(style.Render(span), max(0, width-tokenCol-2))
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

// hasSibling reports whether a later row sits at depth d before the parent
// closes. The earlier draft asked "does the next row go shallower", which is
// "has no children", so every leaf drew the last-child elbow and the tree read
// as a flat list.
func hasSibling(rows []row, idx, d int) bool {
	for i := idx + 1; i < len(rows); i++ {
		if rows[i].depth < d {
			return false
		}
		if rows[i].depth == d {
			return true
		}
	}
	return false
}

// guide draws one column per ancestor level: a rule where that ancestor still
// has siblings below, blank where it does not, and a tee or elbow at the row's
// own level. Folding does not change it, because a folded sibling still exists.
func (m Model) guide(idx int) string {
	d := m.rows[idx].depth
	if d == 0 {
		return ""
	}
	cols := make([]string, d)
	cols[d-1] = gl.elbow
	if hasSibling(m.rows, idx, d) {
		cols[d-1] = gl.tee
	}
	want := d - 1
	for i := idx - 1; i >= 0 && want > 0; i-- {
		if m.rows[i].depth != want {
			continue
		}
		cols[want-1] = gl.gap
		if hasSibling(m.rows, i, want) {
			cols[want-1] = gl.vert
		}
		want--
	}
	for i := range cols {
		if cols[i] == "" {
			cols[i] = gl.gap
		}
	}
	return strings.Join(cols, "")
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
	actorW, textW, metaW := m.columns(width)
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
	actorW, textW, metaW := m.columns(width)
	labelW, prevW := m.textSplit(textW)
	line := "   "
	if actorW > 0 {
		line += fit("actor", actorW) + " "
	}
	line += fit("span", labelW)
	if prevW > 0 {
		line += " " + fit("preview", prevW)
	}
	if metaW >= metaCol {
		line += " " + rightFit("diff", diffCol) + "  " + rightFit("tokens", tokenCol) +
			"  " + rightFit("time", timeCol)
	} else if metaW > 0 {
		line += " " + rightFit("tokens", tokenCol) + "  " + rightFit("time", metaW-tokenCol-2)
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

func (m Model) detailTags(r row) [][2]string {
	if r.kind == kindHook {
		event, matcher, _ := strings.Cut(r.label, ":")
		cmd, out, _ := strings.Cut(r.preview, "  ->  ")
		decision, code := "allow", "0"
		if r.fail {
			decision, code = "deny", "2"
		}
		tags := [][2]string{
			{"hook.event", event}, {"hook.matcher", orDash(matcher)},
			{"hook.source", r.src}, {"hook.command", cmd},
			{"hook.decision", decision}, {"exit_code", code},
			{"duration_ms", fmt.Sprintf("%d", r.ms)},
		}
		if out != "" {
			tags = append(tags, [2]string{"stderr", out})
		}
		return tags
	}
	if r.fail {
		return [][2]string{
			{"tool_name", r.label}, {"tool_use_id", "toolu_01Qk3mPd8Rax"},
			{"duration_ms", fmt.Sprintf("%d", r.ms)}, {"success", "False"},
			{"error", r.preview},
		}
	}
	switch r.kind {
	case kindTurn:
		return [][2]string{
			{"span.id", "a1f39c2e77b04d81"}, {"trace.id", "6b2f…c904"},
			{"prompt.id", "c106e261-96a2-4c73"}, {"interaction.sequence", "3"},
			{"interaction.duration_ms", "live · 48.2s so far"}, {"user_prompt_length", "412"},
			{"terminal.type", "WezTerm"}, {"children", "1 model · 2 tool · 0 delegate"},
		}
	case kindPrompt, kindThink:
		return [][2]string{
			{"gen_ai.request.model", "claude-opus-5[1m]"}, {"gen_ai.system", "anthropic"},
			{"effort", "high"}, {"input_tokens", "42,013"}, {"output_tokens", "890"},
			{"cache_read_tokens", "31,402"}, {"cache_creation_tokens", "29,747"},
			{"ttft_ms", "831"}, {"duration_ms", "9,214"}, {"stop_reason", "end_turn"},
			{"cost_usd_micros", "186,029"}, {"request_id", "req_011CeLRZ6wbf"},
			{"attempt", "1"}, {"success", "True"},
		}
	case kindSub, kindTeam:
		return [][2]string{
			{"tool_name", "Task"}, {"tool_use_id", "toolu_01SaNEb2U5ts"},
			{"subagent_type", strings.TrimPrefix(strings.TrimPrefix(r.actor, "@sub-"), "@team-")},
			{"actor", r.actor}, {"duration_ms", fmt.Sprintf("%d", r.ms)},
			{"child spans", "14"}, {"decision", "accept · source config"},
		}
	case kindMCP:
		server, tool, _ := strings.Cut(r.label, ":")
		return [][2]string{
			{"tool_name", "mcp__plugin_hm_" + server + "__" + tool},
			{"mcp.server", server}, {"mcp.tool", tool},
			{"tool_use_id", "toolu_01Mc9pQr4Vzt"},
			{"duration_ms", fmt.Sprintf("%d", r.ms)}, {"success", "True"},
		}
	case kindSkill:
		return [][2]string{
			{"tool_name", "Skill"}, {"skill.name", strings.TrimPrefix(r.label, "/")},
			{"skill.source", "~/.claude/skills"}, {"tool_use_id", "toolu_01Sk5tYb3Nqw"},
			{"duration_ms", fmt.Sprintf("%d", r.ms)}, {"success", "True"},
		}
	default:
		return [][2]string{
			{"tool_name", r.label}, {"tool_use_id", "toolu_01Wg7hV2nKpz"},
			{"duration_ms", "430"}, {"success", "True"},
			{"decision", "accept"}, {"source", "config"},
			{"tool_input_size_bytes", "118  (from transcript)"},
			{"tool_result_size_bytes", "9,204  (from transcript)"},
		}
	}
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

// A diff tab and a call-graph tab both stood here while the layout was judged
// against a fixture. No harness puts a patch or a call edge on a span, so both
// had no live source; the `changes` command reads a diff from git instead.
var paneTabs = []paneTab{
	{name: "body", body: Model.tabBody},
	{name: "attrs", body: Model.tabAttrs},
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

func (m Model) tabBody(r row) string {
	b := &strings.Builder{}
	fmt.Fprintf(b, "## %s\n\n", r.label)
	switch r.kind {
	case kindTurn:
		// A turn's text is its prompt, whole and unclipped: the row above it
		// already showed the one line that fits there.
		fmt.Fprintf(b, "%s\n", r.prompt())
	case kindPrompt, kindThink:
		b.WriteString(modelBody(r))
	case kindSub, kindTeam:
		fmt.Fprintf(b, "%s\n", r.preview)
	case kindHook:
		cmd, out, _ := strings.Cut(r.preview, "  ->  ")
		if r.src != "" {
			fmt.Fprintf(b, "configured in `%s`\n\n", r.src)
		}
		fmt.Fprintf(b, "```sh\n%s\n```\n", cmd)
		if out != "" {
			fmt.Fprintf(b, "\n```text\n%s\n```\n", out)
		}
	default:
		lang := "sh"
		switch r.label {
		case "Read", "Edit", "Grep":
			lang = "text"
		}
		fmt.Fprintf(b, "```%s\n%s\n```\n", lang, r.preview)
	}
	if r.fail {
		fmt.Fprintf(b, "\n> **failed** after %s\n", duration(time.Duration(r.ms)*time.Millisecond))
	}
	return b.String()
}

// modelBody answers the question a model row raises and cannot answer with a
// preview line: what did this call produce? No harness exports the reply text,
// so the honest answer is the stop reason plus the shape of the call, and the
// tool rows that follow in the tree are the reply's visible half.
func modelBody(r row) string {
	attrs := map[string]string{}
	if r.node != nil {
		attrs = r.node.Span.Attrs
	}
	b := &strings.Builder{}
	if r.preview != "" {
		fmt.Fprintf(b, "%s\n\n", r.preview)
	}
	b.WriteString("| what | value |\n| --- | --- |\n")
	row := func(k, v string) {
		if v != "" {
			fmt.Fprintf(b, "| %s | %s |\n", k, v)
		}
	}
	row("model", first(attrs, "gen_ai.request.model", "model"))
	row("stop reason", first(attrs, "stop_reason", "gen_ai.response.finish_reasons"))
	// The three input counters are one number in the row's token column, and
	// that number is misleading on its own: a 900k input is almost all cache.
	row("fresh input", num(attrs, "input_tokens"))
	row("cached input", num(attrs, "cache_read_tokens"))
	row("cache written", num(attrs, "cache_creation_tokens"))
	row("output", num(attrs, "output_tokens"))
	if ms := number(attrs, "ttft_ms"); ms > 0 {
		row("first token", duration(time.Duration(ms)*time.Millisecond))
	}
	if r.ms > 0 {
		row("total", duration(time.Duration(r.ms)*time.Millisecond))
	}
	row("request", first(attrs, "request_id", "gen_ai.response.id"))
	b.WriteString("\nClaude Code exports no response text, so the reply itself is not here.\n" +
		"On a `tool_use` stop the tool rows below this one are what the call asked for.\n")
	return b.String()
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

func (m Model) tabAttrs(r row) string {
	b := &strings.Builder{}
	fmt.Fprintf(b, "## %s · attributes\n\n", r.label)
	b.WriteString("| attribute | value |\n| --- | --- |\n")
	for _, kv := range m.detailTags(r) {
		fmt.Fprintf(b, "| %s | %s |\n", kv[0], kv[1])
	}
	return b.String()
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
	return strings.Join(parts, "\n\n---\n\n")
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

func (m Model) tabBar(width int) string {
	tabs := m.tabsFor()
	at := m.tabAt()
	parts := []string{}
	for i, t := range tabs {
		style := dim
		if i == at {
			style = cursor
		}
		parts = append(parts, style.Render(" "+t.name+" "))
	}
	return fit(strings.Join(parts, faint.Render(gl.v)), width)
}

// The attribute block has its own tab, but the four facts a reader checks most
// stay pinned under the pane, so switching tabs never hides them.
func (m Model) paneStrip(width int) string {
	tags := m.detailTags(m.rows[m.at(m.cursor)])
	parts := []string{}
	for i, kv := range tags {
		if i == 4 {
			break
		}
		parts = append(parts, tagKey.Render(kv[0])+" "+tagText.Render(clipWord(kv[1], 22)))
	}
	return fit(strings.Join(parts, dim.Render("  ·  ")), width)
}

// Three inner lines are chrome: the tab bar, the rule and the pinned strip.
// sized subtracts the same three from the viewport height.
func (m Model) paneView(inner int) string {
	return strings.Join([]string{
		m.tabBar(inner),
		m.pane.View(),
		rule.Render(strings.Repeat(gl.h, max(0, inner))),
		m.paneStrip(inner),
	}, "\n")
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
	// The session and its source are the two facts a reader needs to know what
	// they are looking at, so they sit ahead of the view's own flags.
	who := "no session"
	if m.current != nil {
		who = m.current.Service + " " + m.current.Short()
	}
	left := title.Render("traces") + dim.Render("  "+who)
	if m.query != "" {
		left += accent.Render("  /" + m.query)
	}
	flags := []string{}
	if m.follow {
		flags = append(flags, live.Render("follow on"))
	} else {
		flags = append(flags, faint.Render("follow off"))
	}
	if m.anchor {
		flags = append(flags, plain.Render("newest at bottom"))
	} else {
		flags = append(flags, plain.Render("scroll free"))
	}
	flags = append(flags,
		dim.Render(fmt.Sprintf("%d shown", len(m.visible()))),
		dim.Render(fmt.Sprintf("%d total", len(m.rows))))
	right := strings.Join(flags, dim.Render("  ·  "))
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
	if m.filter {
		return fit(accent.Render("/"+m.query)+dim.Render("   enter keep   esc clear"), m.width)
	}
	if m.visual {
		return fit(accent.Render("visual")+dim.Render("   j k extend   enter keep   esc cancel"), m.width)
	}
	hint := "j k move   d u page   D U inspector   J K size   tab pane   n p turn   enter turn   v range   A all   s session   / filter   ? help"
	return fit(dim.Render(hint), m.width)
}

func (m Model) leaderBar() string {
	keys := []string{"f follow", "o anchor", "i inspector", "y yank raw", "? help"}
	if m.pending == "i" {
		keys = []string{"i toggle", "h left", "j bottom", "k top", "l right"}
	}
	return fit(accent.Render("<space>")+dim.Render("  "+strings.Join(keys, "   ")), m.width)
}

var helpTable = [][2]string{
	{"j / k", "move one span"},
	{"d / u", "page the trace half a screen  (ctrl+d and ctrl+u also work)"},
	{"D / U", "page the inspector  (ctrl+f and ctrl+b also work)"},
	{"tab / shift+tab", "next inspector tab / previous"},
	{"gg / G", "first span / last span and resume follow"},
	{"h / l", "collapse or step out / expand"},
	{"za", "toggle fold under the cursor  (vim)"},
	{"zR / zM", "open every fold / close every fold  (vim)"},
	{"zx", "close all, then open the path to the cursor  (vim)"},
	{"Z", "expand every node  (neo-tree)"},
	{"enter", "toggle the whole turn the cursor sits in"},
	{"M", "toggle the one span under the cursor"},
	{"m", "toggle the span and its whole subtree"},
	{"v", "range: j k extend, enter or v keep, esc cancel"},
	{"A", "toggle every row  (shift+enter also works)"},
	{"esc", "cancel a range, or clear every mark"},
	{"n / p", "next turn / previous turn  (]t and [t also work)"},
	{"Y", "yank the verbatim bytes behind the row"},
	{"o", "anchor newest at bottom, or scroll free"},
	{"- / = , J / K", "move the divider  (dragging it does the same)"},
	{"click / wheel", "select a row, fold on the wedge, pick a tab, scroll either pane"},
	{"<space> i", "inspector: i toggle, h left, j bottom, k top, l right"},
	{"<space>", "leader: f follow, o anchor, i inspector, y yank, ? help"},
	{"s", "attach to another session"},
	{"/", "filter the tree by text  (esc clears it)"},
	{"q", "quit"},
}

func viewHelp(width, height int) string {
	lines := []string{}
	for _, h := range helpTable {
		lines = append(lines, accent.Render(fit(h[0], 18))+plain.Render(h[1]))
	}
	// m is bound to mark here and to move in neo-tree. traces has no move, so the
	// key is free; v stays open because neo-tree uses it for a vertical split.
	lines = append(lines, "", dim.Render("m marks here and moves in neo-tree; traces has no move, so the key is free."))
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

	main := tree
	if p := m.placeAt(); p != placeHidden {
		pw := max(1, m.detailWidth()-2)
		// A bare percent next to a resizable pane reads as its size, so the
		// title says what the number measures.
		name := fmt.Sprintf("inspector  %.0f%% scrolled", m.pane.ScrollPercent()*100)
		pane := box(name, pw, m.paneView(pw))
		switch p {
		case placeBottom:
			main = withGrip(tree, inner) + "\n" + pane
		case placeTop:
			main = pane + "\n" + tree
		case placeLeft:
			main = lipgloss.JoinHorizontal(lipgloss.Top, pane, tree)
		case placeRight:
			main = lipgloss.JoinHorizontal(lipgloss.Top, tree, pane)
		}
	}

	bottom := m.footer()
	if m.leader || m.pending == "i" {
		bottom = m.leaderBar()
	}
	return strings.Join([]string{m.head(), main, bottom}, "\n")
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
func (m Model) filterKey(msg tea.KeyMsg, k string) (tea.Model, tea.Cmd) {
	switch k {
	case "esc":
		m.filter, m.query = false, ""
		m.rebuild()
		return m.clamp(), nil
	case "enter":
		m.filter = false
		return m.clamp(), nil
	case "backspace":
		if m.query != "" {
			m.query = m.query[:len(m.query)-1]
			m.rebuild()
		}
		return m.clamp(), nil
	}
	if len(msg.Runes) > 0 {
		m.query += string(msg.Runes)
		m.rebuild()
	}
	return m.clamp(), nil
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
		b.WriteString(fit(mark+style.Render(fmt.Sprintf("%-12s %-40s %5d spans  %s",
			one.Service, one.Title(), one.Count, ago(one.Last, m.now))), m.width) + "\n")
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
