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

// complete fills in the rest of the one command the text can still be. With more
// than one left it says which, rather than guessing.
func (m Model) complete() Model {
	head, rest, hasArgs := strings.Cut(m.cmdText, " ")
	if hasArgs {
		return m
	}
	found := []string{}
	for _, one := range commands {
		if strings.HasPrefix(one.name, head) {
			found = append(found, one.name)
		}
	}
	switch len(found) {
	case 0:
	case 1:
		m.cmdText = found[0]
		if one, _ := lookup(found[0]); one != nil && one.args != "" {
			m.cmdText += " "
		}
	default:
		m.status = strings.Join(found, "  ")
	}
	_ = rest
	return m
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

// commandBar is the footer while the line is open. It shows what the text
// resolves to, so a reader learns the names by typing a prefix of one.
func (m Model) commandBar() string {
	line := accent.Render(":"+m.cmdText) + cursor.Render(" ")
	hint := ""
	head, _, hasArgs := strings.Cut(m.cmdText, " ")
	if one, hits := lookup(head); one != nil {
		switch {
		case hits > 1 && !hasArgs:
			hint = "  " + one.name + "  and " + strconv.Itoa(hits-1) + " more, tab to complete"
		default:
			hint = "  " + one.name + " " + one.args + "  " + one.help
		}
	} else if m.cmdText == "" {
		hint = "  <n> a turn   /text a filter   tab completes   up recalls"
	}
	return fit(line+dim.Render(hint), m.width)
}
