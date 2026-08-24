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

	"github.com/roshbhatia/sysinit/pkgs/internal/diffview"
	"github.com/roshbhatia/sysinit/pkgs/reel/internal/session"
)

// Mockup renders one candidate layout over a fixed fixture so the layout can be
// judged before any of it reaches the live view. The fixture is real content
// pulled from the collector file and the matching transcript, with one
// exception noted in the detail pane.
//
// Four earlier variations collapsed into this one. The density comes from the
// one-line variant, the inline second line from the two-line variant, the
// gutter cursor and the tail anchor from the waterfall variant, and the fused
// error row from the transcript variant.

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
type mockKind int

const (
	kindTurn mockKind = iota
	kindPrompt
	kindThink
	kindTool
	kindMCP
	kindSkill
	kindSub
	kindTeam
	kindHook
)

var roleOf = map[mockKind]session.Role{
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
	minTrackW = 12
	maxTextW  = 104
	maxTrackW = 72
)

// Every field is named at the call site below. The first draft used positional
// literals, and adding one field then rewrote all forty rows by hand.
type mockRow struct {
	depth   int
	kind    mockKind
	actor   string
	label   string
	preview string
	in      int    // input tokens billed to this span, cache reads included
	out     int    // output tokens
	ms      int    // wall time of this span alone
	at      int    // start, as a percent of the trace
	took    int    // width, as a percent of the trace
	src     string // where a hook is configured; empty on every other kind
	add     int    // lines added by this span
	del     int    // lines removed
	files   int    // files this span touched
	fail    bool
	parent  bool
}

type mockModel struct {
	rows   []mockRow
	next   int
	cursor int
	offset int
	marks  map[int]bool
	folded map[int]bool

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

	tab  int
	spin spinner.Model

	pane viewport.Model
	md   *glamour.TermRenderer
	mdW  int
}

// The tab bar, the rule and the pinned strip cost three inner lines of the
// inspector box on every frame.
const paneChrome = 3

func Mockup() mockModel {
	m := mockModel{
		rows:   append([]mockRow{}, fixture...),
		marks:  map[int]bool{},
		folded: map[int]bool{},
		width:  120,
		height: 40,
		follow: true,
		anchor: true,
		place:  placeBottom,
		last:   placeBottom,
		split:  50,
		pane:   viewport.New(52, 20),
		spin:   spinner.New(spinner.WithSpinner(spinner.MiniDot), spinner.WithStyle(live)),
	}
	m.cursor = len(m.rows) - 1
	return m
}

type tickMsg struct{ t time.Time }

func tick() tea.Cmd {
	return tea.Tick(900*time.Millisecond, func(t time.Time) tea.Msg { return tickMsg{t} })
}

func (m mockModel) Init() tea.Cmd { return tea.Batch(tick(), m.spin.Tick) }

func (m mockModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
		// Resize has to reclamp. Without it a shrink can leave the offset past
		// the end and the tree pane renders blank until the next keypress.
		return m.sized().clamp(), nil
	case tickMsg:
		if m.next < len(stream) {
			m.rows = append(m.rows, stream[m.next])
			m.next++
		}
		if m.follow {
			if vis := m.visible(); len(vis) > 0 {
				m.cursor = len(vis) - 1
			}
		}
		return m.clamp(), tick()
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

func (m mockModel) placeAt() placement {
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
func (m mockModel) vertical() bool {
	p := m.placeAt()
	return p == placeBottom || p == placeTop
}

func (m mockModel) horizontal() bool {
	p := m.placeAt()
	return p == placeLeft || p == placeRight
}

func (m mockModel) placeName() string {
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
func (m mockModel) detailLines() int {
	if !m.vertical() {
		return 0
	}
	rows := max(1, m.height-4)
	return min(max(rows*m.split/100, paneChrome+3), max(paneChrome+3, rows-4))
}

// The tree box bottom border is the divider, and the drag reads that row. The
// inspector top border sits one below it, and the tab bar one below that.
func (m mockModel) dividerY() int { return m.treeRows() + 2 }

// The split is a percent, so it round trips through two floors and lands the
// divider one row above the pointer. Rounding the percent up cancels that.
func (m mockModel) resizeTo(y int) mockModel {
	rows := max(1, m.height-4)
	lines := rows - max(1, y-2)
	m.split = min(85, max(15, (lines*100+rows-1)/rows))
	return m.sized().clamp()
}

// dock moves the inspector to an edge. Asking for the edge it already holds
// hides it, so <leader>ij is both "put it at the bottom" and "put it away",
// and <leader>ii toggles whichever edge it last had.
func (m mockModel) dock(to placement) mockModel {
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

func (m mockModel) resize(by int) mockModel {
	m.split = min(85, max(15, m.split+by))
	m.status = fmt.Sprintf("inspector %d%% of the frame", m.split)
	return m.sized().clamp()
}

func (m mockModel) treeWidth() int { return m.width - m.detailCols() }

// detailCols is the whole screen cost of a side pane, border columns included.
// The clamp keeps 44 columns of tree alive, which is the narrowest frame that
// still fits an actor, a label and a preview.
func (m mockModel) detailCols() int {
	if !m.horizontal() {
		return 0
	}
	return min(max(m.width*m.split/100, 34), max(34, m.width-44))
}

func (m mockModel) treeRows() int {
	rows := max(1, m.height-4)
	if m.vertical() {
		rows = max(3, rows-m.detailLines())
	}
	return rows
}

// treeTop is the screen row of the tree's first body line, and treeLeft the
// screen column of its first inner cell. Every mouse hit test starts here.
func (m mockModel) treeTop() int {
	if m.placeAt() == placeTop {
		return m.detailLines() + 3
	}
	return 3
}

func (m mockModel) treeLeft() int {
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

func (m mockModel) sized() mockModel {
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

func (m mockModel) detailWidth() int {
	if m.vertical() {
		return m.width
	}
	return m.detailCols()
}

// The side pane is as tall as the tree box, so its viewport takes the same
// inner rows less the three chrome lines paneView always draws.
func (m mockModel) detailRows() int {
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

func (m mockModel) key(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	k := msg.String()
	if isTerminalReply(k) {
		return m, nil
	}
	m.status = ""

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
			m.folded = map[int]bool{}
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
		m.marks = map[int]bool{}
		return m.clamp(), nil
	case " ":
		m.leader = true
		return m, nil
	case "z", "g", "]", "[":
		m.pending = k
		return m, nil
	case "Z":
		// neo-tree parity: bare Z expands every node.
		m.folded = map[int]bool{}
		return m.clamp(), nil
	case "j", "down":
		m.cursor, m.follow = m.cursor+1, false
	case "k", "up":
		m.cursor, m.follow = m.cursor-1, false
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
	case "m":
		m.markSubtree(m.at(m.cursor))
	case "h":
		m.collapse()
	case "l":
		m.expand()
	case "enter":
		m.markTurn(m.at(m.cursor))
	// shift+enter only reaches a v1 app over the kitty keyboard protocol, so
	// "M" carries the same binding for every other terminal.
	case "shift+enter", "M":
		m.markRow(m.at(m.cursor))
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
func (m mockModel) yank() mockModel {
	r := m.rows[m.at(m.cursor)]
	src := r.preview
	if r.kind == kindTurn {
		src = turnPrompt
	}
	m.status = fmt.Sprintf("yanked %d bytes verbatim", len(src))
	return m
}

// halfPage moves the cursor and the view by the same step, which is what vim
// ctrl+d and ctrl+u do. Moving the cursor alone left the offset behind, so the
// page never turned and the cursor only slid down the same screen.
func (m mockModel) halfPage(dir int) mockModel {
	step := max(1, m.bodyHeight()/2)
	m.follow = false
	m.cursor += dir * step
	m.offset += dir * step
	if m.offset < 0 {
		m.offset = 0
	}
	return m.clamp()
}

func (m mockModel) at(i int) int {
	vis := m.visible()
	if len(vis) == 0 {
		return 0
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
func (m *mockModel) markSubtree(idx int) {
	on := !m.marks[idx]
	set := func(i int) {
		if on {
			m.marks[i] = true
		} else {
			delete(m.marks, i)
		}
	}
	set(idx)
	for i := idx + 1; i < len(m.rows) && m.rows[i].depth > m.rows[idx].depth; i++ {
		set(i)
	}
}

// markTurn marks the whole turn the cursor sits in, which is the unit a
// reader thinks in: one thing asked, everything it caused.
func (m *mockModel) markTurn(idx int) {
	for m.rows[idx].depth > 0 {
		a := m.ancestorOf(idx)
		if a < 0 {
			break
		}
		idx = a
	}
	m.markSubtree(idx)
}

func (m *mockModel) markRow(idx int) {
	if m.marks[idx] {
		delete(m.marks, idx)
		return
	}
	m.marks[idx] = true
}

func (m *mockModel) toggleFold() {
	idx := m.at(m.cursor)
	if !m.rows[idx].parent {
		return
	}
	if m.folded[idx] {
		delete(m.folded, idx)
	} else {
		m.folded[idx] = true
	}
}

func (m *mockModel) foldAll() {
	for i, r := range m.rows {
		if r.parent {
			m.folded[i] = true
		}
	}
}

func (m *mockModel) openPath() {
	for i := m.at(m.cursor); i >= 0; i = m.ancestorOf(i) {
		delete(m.folded, i)
		if m.rows[i].depth == 0 {
			break
		}
	}
}

func (m *mockModel) collapse() {
	idx := m.at(m.cursor)
	if m.rows[idx].parent && !m.folded[idx] {
		m.folded[idx] = true
		return
	}
	if a := m.ancestorOf(idx); a >= 0 {
		m.cursor, m.follow = m.indexOf(a), false
	}
}

func (m *mockModel) expand() {
	idx := m.at(m.cursor)
	if m.rows[idx].parent {
		delete(m.folded, idx)
	}
}

func (m *mockModel) jump(d int) {
	vis := m.visible()
	for i := m.cursor + d; i >= 0 && i < len(vis); i += d {
		if m.rows[vis[i]].depth == 0 {
			m.cursor, m.follow = i, false
			return
		}
	}
}

func (m mockModel) clamp() mockModel {
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
func (m mockModel) tailOffset(vis []int, h int) int {
	o := len(vis) - 1
	for o > 0 && m.linesFrom(vis, o-1, len(vis)) <= h {
		o--
	}
	return o
}

func (m mockModel) linesFrom(vis []int, a, b int) int {
	n := 0
	for i := a; i < b && i < len(vis); i++ {
		n += m.rowHeight(i)
	}
	return n
}

// The cursor row is the only row that costs two lines. Two lines for every row
// caps an 87 row terminal near 40 spans, and a real session logged 857.
func (m mockModel) rowHeight(i int) int {
	if i == m.cursor {
		return 2
	}
	return 1
}

// The tree box spends one inner line on the column strip, so the scroll math
// and treeBody have to read the same number or the cursor walks off the pane.
func (m mockModel) bodyHeight() int {
	return max(1, m.treeRows()-1)
}

func (m mockModel) visible() []int {
	out := []int{}
	hide := -1
	for i, r := range m.rows {
		if hide >= 0 && r.depth > m.rows[hide].depth {
			continue
		}
		hide = -1
		out = append(out, i)
		if r.parent && m.folded[i] {
			hide = i
		}
	}
	return out
}

func (m mockModel) indexOf(idx int) int {
	for i, v := range m.visible() {
		if v == idx {
			return i
		}
	}
	return 0
}

func (m mockModel) ancestorOf(idx int) int {
	for i := idx - 1; i >= 0; i-- {
		if m.rows[i].depth < m.rows[idx].depth {
			return i
		}
	}
	return -1
}

func (m mockModel) marked() []int {
	out := []int{}
	for i := range m.rows {
		if m.marks[i] {
			out = append(out, i)
		}
	}
	if len(out) == 0 {
		out = append(out, m.at(m.cursor))
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

// columns holds the text column still and gives the leftover to the track,
// which is the inverse of the first draft. Jaeger and otel-tui both fix the
// label column and let the timeline stretch; the other way round opens a dead
// band that grows with the terminal.
// The actor column is the first thing dropped when the pane narrows. The guide
// tree still carries the nesting, so a narrow frame loses the least here.
func columns(width int) (actor, text, meta, track int) {
	if width < 1 {
		return 0, 0, 0, 0
	}
	if width < minTextW+minTrackW+metaTight+2 {
		return 0, width, 0, 0
	}
	if width >= actorCol+1+minTextW+minTrackW+metaCol+2+20 {
		actor = actorCol
	}
	// The diff cell is the first of the three to go. Tokens and time answer a
	// question every row has an answer to; churn only applies to a write.
	meta = metaTight
	if width >= minTextW+minTrackW+metaCol+2+actor {
		meta = metaCol
	}
	rest := width - actor - meta - 2
	if actor > 0 {
		rest--
	}
	text = rest * 3 / 5
	if text > maxTextW {
		text = maxTextW
	}
	track = rest - text
	if track > maxTrackW {
		track = maxTrackW
		text = rest - track
	}
	if track < minTrackW {
		track = minTrackW
		text = rest - track
	}
	if text < minTextW {
		text = minTextW
		track = rest - text
	}
	if text < 1 {
		text = 1
	}
	if track < 0 {
		track = 0
	}
	return actor, text, meta, track
}

// prefixWidth is the cell count before the label starts: the cursor bar, the
// state gutter, one space, and the actor column when it is on screen. rowLines,
// treeHead and onWedge all have to agree on it.
func prefixWidth(width int) int {
	actor, _, _, _ := columns(width)
	if actor > 0 {
		return 3 + actor + 1
	}
	return 3
}

// The label column is fixed so the preview always starts at the same screen
// column. Letting the label run free makes the preview budget a residual, and
// at 120 columns that shrank one preview to 14 characters.
func labelWidth(text int) int {
	switch {
	case text >= 56:
		return 22
	case text >= 40:
		return 16
	default:
		return 10
	}
}

func previewWidth(text int) int {
	return max(0, text-labelWidth(text)-4)
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
func (m mockModel) rollup(idx int) int {
	total := m.rows[idx].in + m.rows[idx].out
	for i := idx + 1; i < len(m.rows) && m.rows[i].depth > m.rows[idx].depth; i++ {
		total += m.rows[i].in + m.rows[i].out
	}
	return total
}

// churn rolls up the same way tokens do, and for the same reason: a turn row is
// asked what it changed, not what its last child changed.
func (m mockModel) churn(idx int) (add, del, files int) {
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
func (m mockModel) diffCell(idx, width int) string {
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

// Left to right the three cells read as one sentence about the row: what it
// changed, what it cost, how long it took. Time sits last because the gantt
// track to its right measures the same thing, and a number next to the bar it
// scales is one glance, not two.
func (m mockModel) metaCell(idx, width int) string {
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

// gantt inks only the run itself. Drawing the off portion as dashes cost more
// glyphs than the row's own text carried, and read as a horizontal rule.
func gantt(width, at, took int, style lipgloss.Style) string {
	if width < 1 {
		return ""
	}
	if took <= 0 {
		return strings.Repeat(" ", width)
	}
	start := at * width / 100
	if start >= width {
		start = width - 1
	}
	length := took * width / 100
	body := ""
	if length < 1 {
		// Below one cell the bar cannot be proportional, so it says "a point
		// here" rather than pretending to a length it does not have.
		body, length = style.Render(gl.tick), 1
	} else {
		if start+length > width {
			length = width - start
		}
		body = style.Render(strings.Repeat(gl.fill, length))
	}
	return strings.Repeat(" ", start) + body + strings.Repeat(" ", width-start-length)
}

func axis(width int, total string) string {
	if width < 1 {
		return ""
	}
	cells := make([]string, width)
	for i := range cells {
		cells[i] = " "
	}
	for i := 0; i < width; i += 10 {
		cells[i] = gl.tick
	}
	cells[0] = "0"
	if lbl := []rune(total); len(lbl)+2 <= width {
		for i, r := range lbl {
			cells[width-len(lbl)+i] = string(r)
		}
	}
	return strings.Join(cells, "")
}

// The gutter marks a span that is still open. A failure needs no glyph here: the
// whole row is already red, which reads from further away than a symbol does.
func (m mockModel) state(idx int, r mockRow) string {
	if m.running(idx) {
		return accent.Render("\u00b7")
	}
	return " "
}

// A gutter rule rather than a background colour row: lipgloss v1.1.0 resets a
// nested style before the outer background closes, so a filled cursor row tears.
func (m mockModel) bar(idx int) string {
	switch {
	case idx == m.at(m.cursor) && m.marks[idx]:
		// Both states on one column. Without this arm the cursor arm won, so
		// marking the row under the cursor changed no pixel at all.
		return accent.Render(gl.mark)
	case idx == m.at(m.cursor):
		return accent.Render(gl.point)
	case m.marks[idx]:
		return live.Render(gl.mark)
	default:
		return " "
	}
}

// The wedges are reserved for fold state only. Reusing them for role collided
// with the expander the owner already reads as "expand this" in neo-tree.
func (m mockModel) glyph(idx int, r mockRow) string {
	if m.running(idx) {
		return m.spin.View() + " "
	}
	if !r.parent {
		return gl.leaf + " "
	}
	if m.folded[idx] {
		return gl.unfold + " "
	}
	return gl.fold + " "
}

// hasSibling reports whether a later row sits at depth d before the parent
// closes. The earlier draft asked "does the next row go shallower", which is
// "has no children", so every leaf drew the last-child elbow and the tree read
// as a flat list.
func hasSibling(rows []mockRow, idx, d int) bool {
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
func (m mockModel) guide(idx int) string {
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

// Colour answers one question only: red failed, cyan is still going, green
// finished clean. It rides the gutter and the gantt bar, and takes over the
// label too on a failure, so a failed row reads as failed end to end.
func (m mockModel) outcome(idx int, r mockRow) lipgloss.Style {
	switch {
	case r.fail:
		return bad
	case m.running(idx):
		return accent
	default:
		return live
	}
}

func (m mockModel) rowLines(vi, idx, width int) []string {
	r := m.rows[idx]
	actorW, textW, metaW, trackW := columns(width)
	labelW := labelWidth(textW)
	prevW := previewWidth(textW)
	style := roleStyle(roleOf[r.kind])
	stat := m.outcome(idx, r)
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
		track := strings.Repeat(" ", trackW)
		// A turn always spans its own whole duration, so a full width bar on
		// every turn row carries no information and outshouts the real ones.
		if r.kind != kindTurn {
			track = gantt(trackW, r.at, r.took, stat)
		}
		line += " " + track
	}

	if vi == m.cursor {
		rule := m.cursorRule(width)
		return []string{rule, fit(line, width), rule}
	}
	return []string{fit(line, width)}
}

// A rule above and below brackets the cursor row without repainting it, so the
// row keeps its own outcome colour.
func (m mockModel) cursorRule(width int) string {
	return faint.Render(strings.Repeat("\u2500", width))
}

func (m mockModel) treeHead(width int) string {
	actorW, textW, metaW, trackW := columns(width)
	labelW := labelWidth(textW)
	prevW := previewWidth(textW)
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
	if trackW > 0 {
		line += " " + axis(trackW, "7m42s")
	}
	return faint.Render(fit(line, width))
}

func (m mockModel) treeBody(width, height int) string {
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

func (m mockModel) detailTags(r mockRow) [][2]string {
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
	body func(mockModel, mockRow) string
	// A tab that has to see the whole selection at once, like the file tree,
	// sets all instead of body. all wins where both are set.
	all func(mockModel) string
}

var paneTabs = []paneTab{
	{name: "body", body: mockModel.tabBody},
	{name: "diff", raw: true, all: mockModel.tabDiff},
	{name: "calls", body: mockModel.tabCalls},
	{name: "attrs", body: mockModel.tabAttrs},
}

func (m mockModel) tabsFor() []paneTab {
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
func (m mockModel) tabAt() int {
	n := len(m.tabsFor())
	if n < 1 {
		return 0
	}
	return ((m.tab % n) + n) % n
}

func (m mockModel) tabBody(r mockRow) string {
	b := &strings.Builder{}
	fmt.Fprintf(b, "## %s\n\n", r.label)
	switch r.kind {
	case kindTurn:
		fmt.Fprintf(b, "%s\n", turnPrompt)
	case kindPrompt, kindThink, kindSub, kindTeam:
		fmt.Fprintf(b, "%s\n", r.preview)
	case kindHook:
		cmd, out, _ := strings.Cut(r.preview, "  ->  ")
		fmt.Fprintf(b, "configured in `%s`\n\n```sh\n%s\n```\n", r.src, cmd)
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

// calldiff answers a question the unified diff cannot: which calls the edit
// added or removed. Its output is already a plus and minus tree, so the same
// diff fence colours it.
func (m mockModel) tabCalls(r mockRow) string {
	c, ok := fixtureCalls[r.preview]
	if !ok {
		return ""
	}
	return fmt.Sprintf("## %s\n\n%s", r.label+" · call graph delta", c)
}

func (m mockModel) tabAttrs(r mockRow) string {
	b := &strings.Builder{}
	fmt.Fprintf(b, "## %s · attributes\n\n", r.label)
	b.WriteString("| attribute | value |\n| --- | --- |\n")
	for _, kv := range m.detailTags(r) {
		fmt.Fprintf(b, "| %s | %s |\n", kv[0], kv[1])
	}
	return b.String()
}

func (m mockModel) rendered(src string) string {
	if m.md == nil {
		return src
	}
	out, err := m.md.Render(src)
	if err != nil {
		return src
	}
	return strings.TrimRight(out, "\n")
}

func (m mockModel) paneSource() string {
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
func (m mockModel) refresh() mockModel {
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
func (m mockModel) tabCols() []int {
	cols, x := []int{}, 0
	for _, t := range m.tabsFor() {
		cols = append(cols, x)
		x += lipgloss.Width(t.name) + 3
	}
	return cols
}

func (m mockModel) tabBar(width int) string {
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
func (m mockModel) paneStrip(width int) string {
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
func (m mockModel) paneView(inner int) string {
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
func (m mockModel) head() string {
	left := title.Render("reel") + dim.Render("  agent trace")
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

func (m mockModel) footer() string {
	if m.status != "" {
		return fit(accent.Render(m.status), m.width)
	}
	if m.pending != "" {
		return fit(accent.Render(m.pending+"…")+dim.Render("  a fold  R open all  M close all  x focus"), m.width)
	}
	hint := "j k move   d u page   D U inspector   J K size   tab pane   n p turn   enter turn   M row   m subtree   esc clear   Y yank   ? help"
	return fit(dim.Render(hint), m.width)
}

func (m mockModel) leaderBar() string {
	keys := []string{"f follow", "o anchor", "i inspector", "y yank raw", "? help"}
	if m.pending == "i" {
		keys = []string{"i toggle", "h left", "j bottom", "k top", "l right"}
	}
	return fit(accent.Render("<space>")+dim.Render("  "+strings.Join(keys, "   ")), m.width)
}

var mockHelp = [][2]string{
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
	{"enter", "mark the whole turn the cursor sits in"},
	{"M", "mark the one span under the cursor  (shift+enter also works)"},
	{"m", "mark the span and its whole subtree"},
	{"esc", "clear every mark"},
	{"n / p", "next turn / previous turn  (]t and [t also work)"},
	{"Y", "yank the verbatim bytes behind the row"},
	{"o", "anchor newest at bottom, or scroll free"},
	{"- / = , J / K", "move the divider  (dragging it does the same)"},
	{"click / wheel", "select a row, fold on the wedge, pick a tab, scroll either pane"},
	{"<space> i", "inspector: i toggle, h left, j bottom, k top, l right"},
	{"<space>", "leader: f follow, o anchor, i inspector, y yank, ? help"},
	{"q", "quit"},
}

func viewMockHelp(width, height int) string {
	lines := []string{}
	for _, h := range mockHelp {
		lines = append(lines, accent.Render(fit(h[0], 18))+plain.Render(h[1]))
	}
	// m is bound to mark here and to move in neo-tree. reel has no move, so the
	// key is free; v stays open because neo-tree uses it for a vertical split.
	lines = append(lines, "", dim.Render("m marks here and moves in neo-tree; reel has no move, so the key is free."))
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
		fmt.Sprintf("reel needs %dx%d", minWidth, minHeight),
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

func (m mockModel) View() string {
	if m.width < minWidth || m.height < minHeight {
		return viewTooSmall(m.width, m.height)
	}
	if m.help {
		return viewMockHelp(m.width, m.height)
	}
	inner := max(1, m.treeWidth()-2)
	tree := box(fmt.Sprintf("trace  %d shown of %d", len(m.visible()), len(m.rows)),
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

const turnPrompt = "detail should be shown by default. there should b mre info. and i should be able " +
	"to see the **prompt inlined** / thought whatever / tool use specifics previewed on the left.\n\n" +
	"- keybindings should match my nvim bindings\n- space as leader, `zx`, etc\n" +
	"- display the prompt with `glamour`\n- select multiple with shift, like a folder"

// The newest row is still open while the stream has more to append, so it wears
// the spinner in place of a leaf glyph.
func (m mockModel) running(idx int) bool {
	return m.next < len(stream) && idx == len(m.rows)-1
}

// The tree's first body line sits at treeTop, which is Y=3 unless the inspector
// took the top. A cursor row is two lines tall, which rowHeight knows.
func (m mockModel) rowAtY(y int) int {
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
func (m mockModel) onWedge(vi, x int) bool {
	idx := m.at(vi)
	if !m.rows[idx].parent {
		return false
	}
	wedge := m.treeLeft() + 1 + prefixWidth(m.treeWidth()) + 2*m.rows[idx].depth
	return x >= wedge && x <= wedge+1
}

// inPane is the complement of the tree box on whichever edge the inspector
// took, so a wheel event lands in exactly one of the two.
func (m mockModel) inPane(msg tea.MouseMsg) bool {
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
func (m mockModel) paneTop() int {
	if m.placeAt() == placeBottom {
		return m.dividerY() + 2
	}
	return 2
}

func (m mockModel) paneLeft() int {
	if m.placeAt() == placeRight {
		return m.treeWidth()
	}
	return 0
}

func (m mockModel) mouse(msg tea.MouseMsg) (tea.Model, tea.Cmd) {
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

// Real spans from the collector file, joined to the matching transcript for the
// tool bodies. The thinking text is the one gap: every thinking block in all 25
// transcripts carries an empty string, so no preview can show reasoning.
var fixture = []mockRow{
	{depth: 0, kind: kindTurn, actor: "@user", label: "turn 1", preview: "i would love an otel trace view that we build with bubbletea/charm/etc that's for our agents that support otel", ms: 252000, at: 0, took: 100, parent: true},
	{depth: 1, kind: kindHook, actor: "@hook", label: "SessionStart", preview: "~/.claude/hooks/context.sh  ->  loaded MEMORY.md, 14 pointers", src: "~/.claude/settings.json", ms: 212, at: 0, took: 1},
	{depth: 1, kind: kindHook, actor: "@hook", label: "UserPromptSubmit", preview: "~/.claude/hooks/steer.sh  ->  injected 2 reminders", src: "~/.claude/settings.json", ms: 96, at: 0, took: 1},
	{depth: 1, kind: kindThink, actor: "@main", label: "Thinking", preview: "Two shapes fit. A flat span list is cheap but loses the turn. A tree keeps it, so the tree wins.", in: 11200, out: 310, ms: 4100, at: 0, took: 2},
	{depth: 1, kind: kindPrompt, actor: "@main", label: "Prompt", preview: "Facts first, then one fork. Claude Code emits real spans: claude_code.interaction, .llm_request, .tool", in: 12400, out: 486, ms: 9200, at: 2, took: 4},
	{depth: 1, kind: kindTool, actor: "@main", label: "Bash", preview: `ls && echo "--- pkgs ---" && ls pkgs 2>/dev/null | head -50`, ms: 117, at: 6, took: 1},
	{depth: 1, kind: kindTool, actor: "@main", label: "Bash", preview: `grep -ril "otel|opentelemetry|OTEL_EXPORTER" --include=*.nix --include=*.go .`, ms: 240, at: 7, took: 2},
	{depth: 1, kind: kindTool, actor: "@main", label: "Read", preview: "pkgs/go.mod  (42 lines)", ms: 9, at: 9, took: 1},
	{depth: 1, kind: kindSub, actor: "@sub-explore", label: "Task: Explore", preview: "find every otel reference under modules/ and hosts/, report paths only", ms: 31204, at: 10, took: 18, parent: true},
	{depth: 2, kind: kindThink, actor: "@sub-explore", label: "Thinking", preview: "modules/ first. hosts/ only imports it, so a hosts hit without a modules hit would be the surprise.", in: 7400, out: 190, ms: 2600, at: 10, took: 2},
	{depth: 2, kind: kindPrompt, actor: "@sub-explore", label: "Prompt", preview: "I will sweep modules/ first, then hosts/, and return a deduplicated path list.", in: 8100, out: 220, ms: 3900, at: 12, took: 3},
	{depth: 2, kind: kindTool, actor: "@sub-explore", label: "Grep", preview: "OTEL_EXPORTER_OTLP  path=modules/  glob=*.nix", ms: 64, at: 15, took: 1},
	{depth: 2, kind: kindTool, actor: "@sub-explore", label: "Bash", preview: "fd -e nix . modules/home/programs/llm | head -40", ms: 88, at: 17, took: 1},
	{depth: 2, kind: kindHook, actor: "@hook", label: "SubagentStop", preview: "report-shape.sh  ->  allow, paths only", src: "~/.claude/settings.json", ms: 57, at: 26, took: 1},
	{depth: 1, kind: kindMCP, actor: "@main", label: "ast-grep:find_code", preview: "pattern=$ENV.$KEY  lang=nix  path=modules/home/programs/llm", ms: 1840, at: 28, took: 3},
	{depth: 1, kind: kindPrompt, actor: "@main", label: "Prompt", preview: "Now the Claude env block. I will add OTEL_LOG_USER_PROMPTS so the prompt lands on the span.", in: 29700, out: 1200, ms: 11400, at: 31, took: 6},
	{depth: 1, kind: kindHook, actor: "@hook", label: "PreToolUse:Edit", preview: "guard-nix-managed.sh  ->  allow, path is nix source", src: "plugin:hm-guardrails", ms: 34, at: 36, took: 1},
	{depth: 1, kind: kindTool, actor: "@main", label: "Edit", preview: "modules/home/programs/llm/harnesses/claude/default.nix", add: 8, files: 1, ms: 14, at: 37, took: 1},
	{depth: 1, kind: kindHook, actor: "@hook", label: "PostToolUse:Edit", preview: "nix fmt --  ->  reformatted 1 file", src: "~/.claude/settings.json", ms: 1930, at: 37, took: 3},
	{depth: 1, kind: kindTool, actor: "@main", label: "Bash", preview: "nix build .#reel  ->  ShellError: flake output 'reel' not found", ms: 2140, at: 38, took: 4, fail: true},
	{depth: 1, kind: kindTool, actor: "@main", label: "Bash", preview: "nh darwin switch < /dev/null > /tmp/switch.log 2>&1", ms: 181000, at: 43, took: 52},
	{depth: 0, kind: kindTurn, actor: "@user", label: "turn 2", preview: "commit push switch and test", ms: 108000, at: 0, took: 100, parent: true},
	{depth: 1, kind: kindPrompt, actor: "@main", label: "Prompt", preview: "Built clean on lv426. Three files changed, 30 lines added.", in: 31100, out: 640, ms: 7800, at: 0, took: 5},
	{depth: 1, kind: kindSkill, actor: "@main", label: "/writing-commit-message", preview: "one concern per commit, conventional prefix, title only, no body", ms: 3100, at: 5, took: 4, parent: true},
	{depth: 2, kind: kindTool, actor: "@main", label: "Bash", preview: "git diff --cached --stat", ms: 41, at: 5, took: 1},
	{depth: 2, kind: kindPrompt, actor: "@main", label: "Prompt", preview: "One concern here: the collector service. The reel changes go in a second commit.", in: 33800, out: 120, ms: 2600, at: 6, took: 3},
	{depth: 1, kind: kindHook, actor: "@hook", label: "PreToolUse:Bash", preview: "guard-hooks.sh  ->  deny: hook-bypass flags are never allowed, fix the hook", src: "plugin:hm-guardrails", ms: 28, at: 8, took: 1, fail: true},
	{depth: 1, kind: kindTool, actor: "@main", label: "Bash", preview: `git add -A && git commit -m "feat(otel): run an otel collector service"`, ms: 310, at: 10, took: 2},
	{depth: 1, kind: kindTool, actor: "@main", label: "Bash", preview: "git push origin main", ms: 1400, at: 13, took: 4},
	{depth: 0, kind: kindTurn, actor: "@user", label: "turn 3", preview: "detail should be shown by default. there should b mre info. and i should be able to see the prompt inlined", at: 0, took: 100, parent: true},
	{depth: 1, kind: kindThink, actor: "@main", label: "Thinking", preview: "The inspector is already built. The gap is that nothing marks a row on load, so it opens empty.", in: 40100, out: 420, ms: 5200, at: 0, took: 3},
	{depth: 1, kind: kindPrompt, actor: "@main", label: "Prompt", preview: "Surveying your nvim keymap so the mockups propose bindings you already know.", in: 42000, out: 890, ms: 9300, at: 3, took: 9},
	{depth: 1, kind: kindTool, actor: "@main", label: "Read", preview: "neovim/config/lua/plugins/neo-tree.lua  (195 lines)", ms: 11, at: 12, took: 1},
	{depth: 1, kind: kindHook, actor: "@hook", label: "Stop", preview: "ste-line-length.sh  ->  block: 2 sentences over 25 words", src: "~/.claude/settings.json", ms: 143, at: 13, took: 1, fail: true},
}

// Appended one per tick so the autorefresh, the follow and the tail anchor can
// all be judged from a still frame taken a few seconds apart.
var stream = []mockRow{
	{depth: 1, kind: kindTool, actor: "@main", label: "Bash", preview: "python3 - <<EOF   survey span attribute keys across 857 spans", ms: 430, at: 13, took: 3},
	{depth: 1, kind: kindPrompt, actor: "@main", label: "Prompt", preview: "The gantt track now stretches, so the dead band on the right closes.", in: 44200, out: 1100, ms: 12600, at: 16, took: 7},
	{depth: 1, kind: kindTool, actor: "@main", label: "Edit", preview: "pkgs/reel/internal/ui/mockup.go", add: 180, del: 96, files: 1, ms: 22, at: 24, took: 1},
	{depth: 1, kind: kindTool, actor: "@main", label: "Bash", preview: "go build ./...", ms: 3400, at: 26, took: 9},
	{depth: 1, kind: kindSub, actor: "@sub-explore", label: "Task: Explore", preview: "check every charm component we already vendor in the nix store", ms: 18700, at: 36, took: 12, parent: true},
	{depth: 2, kind: kindTool, actor: "@sub-explore", label: "Grep", preview: "charmbracelet/bubbles  path=/nix/store  glob=*.go", ms: 1200, at: 37, took: 3},
	{depth: 2, kind: kindPrompt, actor: "@sub-explore", label: "Prompt", preview: "viewport, table, list and help are all present at v1.0.0.", in: 6400, out: 180, ms: 4300, at: 41, took: 5},
	{depth: 1, kind: kindTeam, actor: "@team-doc", label: "Teammate: doc", preview: "write the key table into pkgs/reel/README.md, keys only, no prose", ms: 22400, at: 49, took: 14, parent: true},
	{depth: 2, kind: kindTool, actor: "@team-doc", label: "Read", preview: "pkgs/reel/README.md  (61 lines)", ms: 7, at: 49, took: 1},
	{depth: 2, kind: kindMCP, actor: "@team-doc", label: "basic-memory:search_notes", preview: "query=reel key bindings  project=sysinit", ms: 940, at: 51, took: 2},
	{depth: 2, kind: kindTool, actor: "@team-doc", label: "Edit", preview: "pkgs/reel/README.md", add: 19, del: 4, files: 1, ms: 16, at: 55, took: 1},
	{depth: 1, kind: kindTool, actor: "@main", label: "Bash", preview: "wezterm cli get-text --pane-id 19 > /tmp/frame.txt", ms: 64, at: 64, took: 1},
	{depth: 1, kind: kindTool, actor: "@main", label: "Bash", preview: "wezterm cli get-text | head -8  ->  Broken pipe (os error 32)", ms: 18, at: 66, took: 1, fail: true},
	{depth: 1, kind: kindPrompt, actor: "@main", label: "Prompt", preview: "Never pipe get-text. Redirect it, then read the file.", in: 45900, out: 210, ms: 6100, at: 68, took: 4},
}

// Both fixtures are real hunks, taken from the two commits this mockup was
// written against, so the pane is exercised over content the renderer will
// actually meet.
var fixtureDiff = map[string]string{
	"modules/home/programs/llm/harnesses/claude/default.nix": `--- a/modules/home/programs/llm/harnesses/claude/default.nix
+++ b/modules/home/programs/llm/harnesses/claude/default.nix
@@ -107,6 +107,10 @@ in
         OTEL_LOGS_EXPORTER = "otlp";
         OTEL_EXPORTER_OTLP_PROTOCOL = "http/json";
         OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4318";
+
+        # Without this, every prompt attribute reads <REDACTED> and a turn row
+        # carries no text. The collector writes to a local file only.
+        OTEL_LOG_USER_PROMPTS = "1";
       };
`,
	"pkgs/reel/internal/ui/mockup.go": `--- a/pkgs/reel/internal/ui/mockup.go
+++ b/pkgs/reel/internal/ui/mockup.go
@@ -66,6 +66,13 @@ func (m mockModel) hunkHead(name string, h diffHunk, width int) string {
 	if h.sym != "" {
 		label += " · " + h.sym
 	}
-	label = clip(label, max(4, width-6))
+	// clip pads to its width, and a padded label would eat the rule, so the
+	// padding comes straight back off.
+	label = strings.TrimRight(clip(label, max(4, width-6)), " ")
 	pad := width - lipgloss.Width(label) - 4
@@ -104,7 +111,7 @@ func (m mockModel) tabDiff() string {
-		title.Render(plural(len(files), "file")),
+		title.Render(fmt.Sprintf("%d %s", len(files), plural(len(files), "file"))),
 		live.Render(fmt.Sprintf("+%d", add)),
 		bad.Render(fmt.Sprintf("-%d", del)))
`,
	"pkgs/reel/README.md": `--- a/pkgs/reel/README.md
+++ b/pkgs/reel/README.md
@@ -18,10 +18,25 @@ reel reads the traces the local collector writes to disk.
-## Keys
-
-Arrow keys move. Enter opens. q quits.
+## Keys
+
+| key | what it does |
+| --- | --- |
+| j k | move the cursor one row |
+| d u | page the trace |
+| D U | scroll the inspector |
+| J K | resize the split |
+| enter | mark the enclosing turn |
+| M | mark one row |
+| <space> i | dock the inspector: i toggle, h j k l edge |
+
+## Inspector
+
+The inspector reads the marked rows. It has one tab per way of reading a
+span: the body, the unified diff, the call graph delta, and the raw
+attributes. A tab with nothing to say is dropped from the bar.
`,
}

// calldiff walks the call graph, so its answer is which calls the edit added or
// removed. A plus and minus tree reads as a diff, so the same fence colours it.
// A path whose language has no bundled grammar is absent here, and tabsFor then
// drops the tab, so the reader never opens a pane that apologises.
var fixtureCalls = map[string]string{
	"pkgs/reel/internal/ui/mockup.go": "```diff\n" + `  Model.View()
  ├─ if m.quitted
  ├─ case modePick
     └─ Model.viewPick()
        ├─ Model.Render()
        ├─ span(count, ch)
        ├─ clip(text, width)
        │  ├─ if width <= 0
        │  ├─ if len(runes) <= width
        │  ├─ if width == 1
        │  └─ string()
        ├─ Model.Title()
        ├─ Model.Sprintf()
+       ├─ plural(n, word)
+       │  └─ if n == 1
        ├─ Model.Render()
        ├─ ago(at, now)
` + "```\n",
}

// The join key is a symbol range: a hunk belongs to the symbol whose range
// holds its first new line, and so does a call site. diffview owns the join;
// the mockup only supplies the two layers a real run reads from ast-grep and
// calldiff. A language outline cannot read, such as Nix or markdown, has no
// entry here, and its file then renders as a flat list of hunks.
var fixtureOutline = map[string][]diffview.Symbol{
	"pkgs/reel/internal/ui/mockup.go": {
		{Kind: "func", Name: "(m mockModel) hunkHead(name string, h diffHunk, width int) string", From: 62, To: 80},
		{Kind: "func", Name: "(m mockModel) tabDiff() string", From: 104, To: 138},
	},
}

var fixtureEdges = map[string][]diffview.Edge{
	"pkgs/reel/internal/ui/mockup.go": {
		{Line: 71, Added: true},  // strings.TrimRight
		{Line: 112, Added: true}, // fmt.Sprintf
	},
}

// The tab reads the marked rows, so a patch a row names is parsed once per
// render and the tree matches whatever is marked right now.
func (m mockModel) tabDiff() string {
	files, seen := []diffview.File{}, map[string]bool{}
	for _, idx := range m.marked() {
		src, ok := fixtureDiff[m.rows[idx].preview]
		if !ok {
			continue
		}
		for _, f := range diffview.Parse(src) {
			if seen[f.Path] {
				continue
			}
			seen[f.Path] = true
			files = append(files, f)
		}
	}
	return diffview.Render(diffview.Options{
		Files:   files,
		Width:   max(20, m.pane.Width),
		Symbols: fixtureOutline,
		Edges:   fixtureEdges,
	})
}
