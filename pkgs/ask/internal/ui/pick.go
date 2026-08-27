package ui

import (
	"errors"
	"os"
	"strconv"

	"github.com/charmbracelet/bubbles/help"
	"github.com/charmbracelet/bubbles/key"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/roshbhatia/sysinit/pkgs/ask/internal/provider"
)

type pickKeys struct {
	up     key.Binding
	down   key.Binding
	take   key.Binding
	number key.Binding
	quit   key.Binding
}

func (k pickKeys) ShortHelp() []key.Binding {
	return []key.Binding{k.up, k.down, k.number, k.take, k.quit}
}

var picking = pickKeys{
	up:     key.NewBinding(key.WithKeys("up", "k"), key.WithHelp("↑/k", "up")),
	down:   key.NewBinding(key.WithKeys("down", "j"), key.WithHelp("↓/j", "down")),
	take:   key.NewBinding(key.WithKeys("enter", " "), key.WithHelp("enter", "run it")),
	number: key.NewBinding(key.WithKeys("1", "2", "3", "4", "5", "6", "7", "8", "9"), key.WithHelp("1-9", "jump")),
	quit:   key.NewBinding(key.WithKeys("ctrl+c", "esc", "q"), key.WithHelp("q", "quit")),
}

type picker struct {
	help    help.Model
	offer   []provider.Info
	at      int
	width   int
	took    bool
	dropped bool
}

func (p picker) Init() tea.Cmd { return nil }

func (p picker) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch message := message.(type) {
	case tea.WindowSizeMsg:
		p.width = message.Width
	case tea.KeyMsg:
		switch {
		case key.Matches(message, picking.quit):
			p.dropped = true
			return p, tea.Quit
		case key.Matches(message, picking.up):
			if p.at > 0 {
				p.at--
			}
		case key.Matches(message, picking.down):
			if p.at < len(p.offer)-1 {
				p.at++
			}
		case key.Matches(message, picking.number):
			if wanted, err := strconv.Atoi(message.String()); err == nil && wanted <= len(p.offer) {
				p.at = wanted - 1
				p.took = true
				return p, tea.Quit
			}
		case key.Matches(message, picking.take):
			p.took = true
			return p, tea.Quit
		}
	}
	return p, nil
}

func (p picker) View() string {
	if p.took || p.dropped {
		return ""
	}

	width := inner(p.width)
	shown := frame{title: "ask", width: width, head: dim.Render("which agent?")}

	gutter := 0
	for _, one := range p.offer {
		if size := lipgloss.Width(one.Name); size > gutter {
			gutter = size
		}
	}

	for at, one := range p.offer {
		mark, name := "  ", dim.Render(pad(one.Name, gutter))
		if at == p.at {
			mark, name = accent.Render("❯ "), chosen.Render(pad(one.Name, gutter))
		}

		said := dim.Render(one.Blurb)
		if !one.Ready() {
			said = bad.Render(one.Binary + " is not on PATH")
		}

		shown.rows = append(shown.rows, split(
			mark+dim.Render(strconv.Itoa(at+1)+" ")+name+"  "+said,
			dim.Render(one.Short),
			width,
		))
	}

	return shown.String() + "\n" + dim.Render("  "+p.help.ShortHelpView(picking.ShortHelp())) + "\n"
}

// ready answers with the first agent that is installed, so the cursor opens on
// one that can actually run.
func ready(offer []provider.Info) int {
	for at, one := range offer {
		if one.Ready() {
			return at
		}
	}
	return 0
}

// Pick asks the keyboard which agent to run. It draws on the terminal itself, so
// it still works when stdin is the pipe carrying the input.
func Pick(offer []provider.Info) (provider.Info, error) {
	if len(offer) == 0 {
		return provider.Info{}, errors.New("there are no agents to pick from")
	}

	keyboard := console()
	if keyboard == nil {
		return provider.Info{}, errors.New("there is no terminal to ask on")
	}
	defer func() { _ = keyboard.Close() }()

	start := picker{help: help.New(), offer: offer, at: ready(offer)}
	final, err := tea.NewProgram(start, tea.WithOutput(os.Stderr), tea.WithInput(keyboard)).Run()
	if err != nil {
		return provider.Info{}, err
	}

	done, _ := final.(picker)
	if !done.took {
		return provider.Info{}, ErrStopped
	}
	return done.offer[done.at], nil
}
