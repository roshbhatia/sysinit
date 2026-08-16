package ui

import (
	"errors"
	"os"
	"strings"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
)

type asker struct {
	field    textinput.Model
	question string
	width    int
	took     bool
	dropped  bool
}

func (a asker) Init() tea.Cmd { return textinput.Blink }

func (a asker) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch message := message.(type) {
	case tea.WindowSizeMsg:
		a.width = message.Width
		a.field.Width = inner(a.width) - 2
	case tea.KeyMsg:
		switch message.Type {
		case tea.KeyCtrlC, tea.KeyEsc:
			a.dropped = true
			return a, tea.Quit
		case tea.KeyEnter:
			if strings.TrimSpace(a.field.Value()) == "" {
				return a, nil
			}
			a.took = true
			return a, tea.Quit
		}
	}
	var cmd tea.Cmd
	a.field, cmd = a.field.Update(message)
	return a, cmd
}

func (a asker) View() string {
	if a.took || a.dropped {
		return ""
	}
	width := inner(a.width)
	shown := frame{
		title: "ask",
		width: width,
		head:  accent.Render(clip(a.question, width)),
		rows:  []string{a.field.View()},
	}
	return shown.String() + "\n" + dim.Render("  enter answers, esc gives up") + "\n"
}

// Answer puts the agent's question to the keyboard. It draws on the terminal
// itself, as stdin is usually the pipe holding the input in question.
func Answer(question string) (string, error) {
	keyboard := console()
	if keyboard == nil {
		return "", errors.New("there is no terminal to ask on")
	}
	defer keyboard.Close()

	field := textinput.New()
	field.Placeholder = "your answer"
	field.Prompt = "❯ "
	field.PromptStyle = accent
	field.Focus()

	final, err := tea.NewProgram(
		asker{field: field, question: question},
		tea.WithOutput(os.Stderr),
		tea.WithInput(keyboard),
	).Run()
	if err != nil {
		return "", err
	}

	done, _ := final.(asker)
	if !done.took {
		return "", ErrStopped
	}
	return strings.TrimSpace(done.field.Value()), nil
}
