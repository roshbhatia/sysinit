package ui

import (
	"fmt"
	"os"
	"strconv"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
)

// A colon line, the way vim has one. Every action here has a key already, and
// the key is faster; the line exists for the things a key cannot carry. `:w
// out.md` names a file, `:session 9df` names a run, `:turn 40` names a number,
// and none of the three fits on a keystroke.
//
// A name may be abbreviated to any unambiguous prefix, which is vim's own rule:
// `:se not` is `:set notimeline`.

type command struct {
	name string
	// args is the argument summary for the completion hint, empty when the
	// command takes none.
	args string
	help string
	run  func(Model, string) (Model, tea.Cmd)
}

// Ordered, because a prefix resolves to the first match and the order is what
// decides which. The short and common ones come first.
var commands = []command{
	{name: "quit", help: "leave traces", run: func(m Model, _ string) (Model, tea.Cmd) {
		return m, tea.Quit
	}},
	{name: "help", help: "the key list", run: func(m Model, _ string) (Model, tea.Cmd) {
		m.help = true
		return m, nil
	}},
	{name: "write", args: "<path>", help: "write the row's text to a file", run: Model.writeRow},
	{name: "yank", help: "the row's text to the clipboard", run: func(m Model, _ string) (Model, tea.Cmd) {
		return m.yank()
	}},
	{name: "edit", help: "open the row's text in $EDITOR", run: func(m Model, _ string) (Model, tea.Cmd) {
		return m.edit()
	}},
	{name: "set", args: "[no]<option>", help: "timeline, follow, anchor", run: Model.setOption},
	{name: "turn", args: "<n>", help: "jump to a turn by number", run: Model.gotoTurn},
	{name: "session", args: "<id>", help: "attach to another run", run: Model.attachTo},
	{name: "nohlsearch", help: "clear the filter", run: func(m Model, _ string) (Model, tea.Cmd) {
		m.typed, m.query = "", ""
		m.rebuild()
		return m.clamp(), nil
	}},
	{name: "split", help: "inspector along the bottom", run: func(m Model, _ string) (Model, tea.Cmd) {
		return m.dock(placeBottom), nil
	}},
	{name: "vsplit", help: "inspector down the right", run: func(m Model, _ string) (Model, tea.Cmd) {
		return m.dock(placeRight), nil
	}},
	{name: "close", help: "hide the inspector", run: func(m Model, _ string) (Model, tea.Cmd) {
		return m.dock(placeHidden), nil
	}},
	{name: "only", help: "close every fold but this row's path", run: func(m Model, _ string) (Model, tea.Cmd) {
		m.foldAll()
		m.openPath()
		return m.clamp(), nil
	}},
}

func (m Model) commandKey(msg tea.KeyMsg, k string) (tea.Model, tea.Cmd) {
	switch k {
	case "esc", "ctrl+c":
		m.cmd, m.cmdText, m.cmdAt = false, "", 0
		return m.clamp(), nil
	case "enter":
		text := strings.TrimSpace(m.cmdText)
		m.cmd, m.cmdText, m.cmdAt = false, "", 0
		if text == "" {
			return m.clamp(), nil
		}
		// A repeat is not worth a second history entry, and vim does the same.
		if len(m.cmdHist) == 0 || m.cmdHist[len(m.cmdHist)-1] != text {
			m.cmdHist = append(m.cmdHist, text)
		}
		return m.runCommand(text)
	case "backspace":
		if m.cmdText != "" {
			m.cmdText = m.cmdText[:len(m.cmdText)-1]
		}
		m.cmdCands = nil
		return m, nil
	case "up", "ctrl+p":
		return m.recall(1), nil
	case "down", "ctrl+n":
		return m.recall(-1), nil
	case "tab":
		return m.complete(), nil
	}
	if len(msg.Runes) > 0 {
		m.cmdText += string(msg.Runes)
		m.cmdCands = nil
	}
	return m, nil
}

// recall walks back through what was run before, which is the whole reason a
// command line beats a keystroke for anything repeated.
func (m Model) recall(back int) Model {
	m.cmdAt += back
	if m.cmdAt < 0 {
		m.cmdAt = 0
	}
	if m.cmdAt > len(m.cmdHist) {
		m.cmdAt = len(m.cmdHist)
	}
	if m.cmdAt == 0 {
		m.cmdText = ""
		return m
	}
	m.cmdText = m.cmdHist[len(m.cmdHist)-m.cmdAt]
	return m
}

// complete works the way a shell and vim both do: grow the text to the longest
// prefix every candidate shares, and where that adds nothing, cycle through the
// candidates on each further press. The first version refused to complete "se"
// at all, because set and session both start with it, which is exactly the case
// completion exists for.
func (m Model) complete() Model {
	// An argument is being typed, so the name is settled and there is nothing
	// here to complete. A trailing space alone is not an argument: it is what
	// completing a name that takes one leaves behind.
	if _, rest, cut := strings.Cut(m.cmdText, " "); cut && rest != "" {
		return m
	}
	// A second tab continues the cycle the first one started.
	if len(m.cmdCands) > 1 {
		m.cmdCand = (m.cmdCand + 1) % len(m.cmdCands)
		m.cmdText = m.cmdCands[m.cmdCand]
		return m
	}
	head := strings.TrimSpace(m.cmdText)
	found := candidates(head)
	switch len(found) {
	case 0:
		m.status = "no command starts with " + head
		return m
	case 1:
		m.cmdText = withSpace(found[0])
		m.cmdCands = nil
		return m
	}
	if common := shared(found); len(common) > len(head) {
		m.cmdText = common
		m.cmdCands = nil
		return m
	}
	// Nothing left to grow, so the presses become a walk through the names.
	// Each stays bare: a trailing space would read as an argument and stop the
	// walk after one step.
	m.cmdCands, m.cmdCand = found, 0
	m.cmdText = found[0]
	return m
}

// A name that takes an argument gets the space that separates them, so the
// reader types the argument rather than the space.
func withSpace(name string) string {
	if one, _ := lookup(name); one != nil && one.args != "" {
		return name + " "
	}
	return name
}

func candidates(head string) []string {
	out := []string{}
	for _, one := range commands {
		if strings.HasPrefix(one.name, head) {
			out = append(out, one.name)
		}
	}
	return out
}

// shared is the longest prefix every candidate holds. Growing the text to it is
// free progress: no candidate is ruled out by it.
func shared(in []string) string {
	if len(in) == 0 {
		return ""
	}
	out := in[0]
	for _, one := range in[1:] {
		for !strings.HasPrefix(one, out) {
			out = out[:len(out)-1]
		}
	}
	return out
}

func lookup(head string) (*command, int) {
	found, hits := (*command)(nil), 0
	for i := range commands {
		if commands[i].name == head {
			return &commands[i], 1
		}
		if strings.HasPrefix(commands[i].name, head) {
			if hits == 0 {
				found = &commands[i]
			}
			hits++
		}
	}
	return found, hits
}

func (m Model) runCommand(text string) (tea.Model, tea.Cmd) {
	// `:40` is a line number in vim. Here the numbered thing is a turn, which is
	// what a reader counts a run in.
	if n, err := strconv.Atoi(text); err == nil {
		return m.gotoTurnAt(n)
	}
	// `:/text` is the same filter `/` opens, so a filter can be recalled from
	// history like any other command.
	if after, ok := strings.CutPrefix(text, "/"); ok {
		m.typed, m.query = after, after
		m.rebuild()
		return m.clamp(), nil
	}
	head, args, _ := strings.Cut(text, " ")
	one, hits := lookup(head)
	switch {
	case one == nil:
		m.status = "no command " + head
		return m.clamp(), nil
	case hits > 1 && one.name != head:
		m.status = head + " is ambiguous"
		return m.clamp(), nil
	}
	out, cmd := one.run(m, strings.TrimSpace(args))
	return out.clamp(), cmd
}

func (m Model) setOption(args string) (Model, tea.Cmd) {
	name, on := args, true
	if rest, ok := strings.CutPrefix(args, "no"); ok {
		name, on = rest, false
	}
	switch {
	case name == "":
		m.status = "set timeline | follow | anchor, or no<option>"
	case strings.HasPrefix("timeline", name):
		m.timeline = on
		m.status = "timeline " + onOff(on)
	case strings.HasPrefix("follow", name):
		m.follow = on
		m.status = "follow " + onOff(on)
	case strings.HasPrefix("anchor", name):
		m.anchor = on
		m.status = "anchor " + onOff(on)
	default:
		m.status = "no option " + name
	}
	return m, nil
}

func (m Model) gotoTurn(args string) (Model, tea.Cmd) {
	n, err := strconv.Atoi(args)
	if err != nil {
		m.status = "turn takes a number"
		return m, nil
	}
	out, cmd := m.gotoTurnAt(n)
	return out.(Model), cmd
}

func (m Model) gotoTurnAt(n int) (tea.Model, tea.Cmd) {
	for at, idx := range m.visible() {
		r := m.rows[idx]
		if r.kind == kindTurn && r.node != nil && r.node.Turn == n {
			m.cursor, m.follow = at, false
			m.paintRange()
			return m.clamp(), nil
		}
	}
	m.status = fmt.Sprintf("no turn %d in view", n)
	return m.clamp(), nil
}

func (m Model) attachTo(args string) (Model, tea.Cmd) {
	if args == "" {
		m.status = "session takes an id or a prefix"
		return m, nil
	}
	found := m.store.Session(args)
	if found == nil {
		m.status = "no session " + args
		return m, nil
	}
	m.pinned, m.current = found.ID, found
	m.cursor, m.offset = 0, 0
	m.rebuild()
	m.status = "attached to " + found.Short()
	return m, nil
}

// writeRow is `:w <path>`. The pane reflows and colours everything it draws, and
// this is the way out for a tool result a reader wants to keep.
func (m Model) writeRow(args string) (Model, tea.Cmd) {
	if args == "" {
		m.status = "write takes a path"
		return m, nil
	}
	at := m.at(m.cursor)
	if at < 0 {
		return m, nil
	}
	body := m.rows[at].raw()
	if body == "" {
		m.status = "nothing to write on this row"
		return m, nil
	}
	path := args
	if after, ok := strings.CutPrefix(path, "~/"); ok {
		if home, err := os.UserHomeDir(); err == nil {
			path = home + "/" + after
		}
	}
	if err := os.WriteFile(path, []byte(body+"\n"), 0o600); err != nil {
		m.status = "write: " + err.Error()
		return m, nil
	}
	m.status = fmt.Sprintf("wrote %s to %s", count(len(body), "byte"), path)
	return m, nil
}

// commandBar draws the line with the rest of the one matching name as ghost text
// after the cursor, so a reader sees where a prefix is going before they commit
// to it. With several names still possible it lists them and marks the part
// already typed, which is what tab will grow.
func (m Model) commandBar(width int) string {
	head, args, hasArgs := strings.Cut(m.cmdText, " ")
	line := accent.Render(":") + plain.Render(m.cmdText)

	found := candidates(head)
	switch {
	case hasArgs:
		if one, _ := lookup(head); one != nil {
			if args == "" {
				line += faint.Render(one.args)
			}
			line += cursor.Render(" ") + dim.Render("  "+one.help)
		} else {
			line += cursor.Render(" ")
		}
	case len(found) == 1:
		// The ghost is the rest of the name, then what it takes. Tab accepts it.
		line += faint.Render(strings.TrimPrefix(found[0], head))
		if one, _ := lookup(found[0]); one != nil {
			if one.args != "" {
				line += faint.Render(" " + one.args)
			}
			line += cursor.Render(" ") + dim.Render("  "+one.help)
		}
	case len(found) > 1:
		grown := shared(found)
		line += faint.Render(strings.TrimPrefix(grown, head)) + cursor.Render(" ") + dim.Render("  ")
		marks := []string{}
		for i, one := range found {
			style := dim
			if len(m.cmdCands) > 1 && i == m.cmdCand {
				style = cursor
			}
			marks = append(marks, accent.Render(grown)+style.Render(strings.TrimPrefix(one, grown)))
		}
		line += strings.Join(marks, dim.Render("  "))
	default:
		line += cursor.Render(" ")
		if m.cmdText == "" {
			line += dim.Render("  <n> a turn   /text a filter   tab completes   up recalls")
		} else {
			line += dim.Render("  no command starts with " + m.cmdText)
		}
	}
	return fit(line, width)
}
