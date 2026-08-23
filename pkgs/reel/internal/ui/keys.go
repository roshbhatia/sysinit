package ui

import "github.com/charmbracelet/bubbles/key"

// The map follows the two habits this repo already has: vim motions for
// movement, and one mnemonic letter for a mode. `pkgs/ask` set the precedent
// for up/k, down/j, 1-9 to jump, and q or esc to leave.
type keymap struct {
	up      key.Binding
	down    key.Binding
	top     key.Binding
	bottom  key.Binding
	pageUp  key.Binding
	pageDwn key.Binding
	fold    key.Binding
	unfold  key.Binding
	toggle  key.Binding
	turn    key.Binding
	follow  key.Binding
	pick    key.Binding
	filter  key.Binding
	detail  key.Binding
	yank    key.Binding
	help    key.Binding
	quit    key.Binding
}

var keys = keymap{
	up:      key.NewBinding(key.WithKeys("up", "k"), key.WithHelp("↑/k", "up")),
	down:    key.NewBinding(key.WithKeys("down", "j"), key.WithHelp("↓/j", "down")),
	top:     key.NewBinding(key.WithKeys("g", "home"), key.WithHelp("g", "top")),
	bottom:  key.NewBinding(key.WithKeys("G", "end"), key.WithHelp("G", "bottom")),
	pageUp:  key.NewBinding(key.WithKeys("ctrl+u", "pgup"), key.WithHelp("ctrl+u", "half page up")),
	pageDwn: key.NewBinding(key.WithKeys("ctrl+d", "pgdown"), key.WithHelp("ctrl+d", "half page down")),
	fold:    key.NewBinding(key.WithKeys("h", "left"), key.WithHelp("h", "fold")),
	unfold:  key.NewBinding(key.WithKeys("l", "right"), key.WithHelp("l", "unfold")),
	toggle:  key.NewBinding(key.WithKeys("enter", " "), key.WithHelp("enter", "fold or unfold")),
	turn:    key.NewBinding(key.WithKeys("1", "2", "3", "4", "5", "6", "7", "8", "9"), key.WithHelp("1-9", "turn")),
	follow:  key.NewBinding(key.WithKeys("f"), key.WithHelp("f", "follow")),
	pick:    key.NewBinding(key.WithKeys("s"), key.WithHelp("s", "session")),
	filter:  key.NewBinding(key.WithKeys("/"), key.WithHelp("/", "filter")),
	detail:  key.NewBinding(key.WithKeys("tab"), key.WithHelp("tab", "detail")),
	yank:    key.NewBinding(key.WithKeys("y"), key.WithHelp("y", "copy id")),
	help:    key.NewBinding(key.WithKeys("?"), key.WithHelp("?", "help")),
	quit:    key.NewBinding(key.WithKeys("q", "esc", "ctrl+c"), key.WithHelp("q", "quit")),
}

func (k keymap) ShortHelp() []key.Binding {
	return []key.Binding{k.up, k.down, k.toggle, k.follow, k.pick, k.filter, k.help, k.quit}
}

func (k keymap) FullHelp() [][]key.Binding {
	return [][]key.Binding{
		{k.up, k.down, k.top, k.bottom, k.pageUp, k.pageDwn},
		{k.fold, k.unfold, k.toggle, k.turn, k.detail, k.yank},
		{k.follow, k.pick, k.filter, k.help, k.quit},
	}
}

var picking = struct {
	up     key.Binding
	down   key.Binding
	take   key.Binding
	number key.Binding
	back   key.Binding
}{
	up:     key.NewBinding(key.WithKeys("up", "k"), key.WithHelp("↑/k", "up")),
	down:   key.NewBinding(key.WithKeys("down", "j"), key.WithHelp("↓/j", "down")),
	take:   key.NewBinding(key.WithKeys("enter", " "), key.WithHelp("enter", "attach")),
	number: key.NewBinding(key.WithKeys("1", "2", "3", "4", "5", "6", "7", "8", "9"), key.WithHelp("1-9", "jump")),
	back:   key.NewBinding(key.WithKeys("esc", "s", "q"), key.WithHelp("esc", "back")),
}
