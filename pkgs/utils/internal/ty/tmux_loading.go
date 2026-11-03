package ty

import (
	"context"
	"fmt"
	"os"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/roshbhatia/go-utils/cell"
)

type providerPage struct {
	descriptor pickerDescriptor
	listed     pickerList
}
type loadedPicker struct {
	value any
	err   error
}
type loadingTick time.Time
type pickerLoading struct {
	title        string
	load         func() (any, error)
	cancel       context.CancelFunc
	result       loadedPicker
	width, frame int
	done         bool
}

func (m pickerLoading) Init() tea.Cmd {
	return tea.Batch(func() tea.Msg { value, err := m.load(); return loadedPicker{value, err} }, loadingPulse())
}
func loadingPulse() tea.Cmd {
	return tea.Tick(100*time.Millisecond, func(t time.Time) tea.Msg { return loadingTick(t) })
}
func (m pickerLoading) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch value := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = value.Width
	case loadedPicker:
		m.result = value
		m.done = true
		return m, tea.Quit
	case loadingTick:
		m.frame++
		return m, loadingPulse()
	case tea.KeyMsg:
		switch value.String() {
		case "esc", "ctrl+c", "ctrl+g":
			m.cancel()
			m.result.err = errPickerBack
			m.done = true
			return m, tea.Quit
		}
	}
	return m, nil
}
func (m pickerLoading) View() string {
	if m.done {
		return ""
	}
	frames := []string{"⠋", "⠙", "⠹", "⠸"}
	return "\n  " + cell.Truncate(fmt.Sprintf("%s Loading %s…  Esc back", frames[m.frame%len(frames)], m.title), max(1, m.width-4)) + "\n"
}
func loadPickerData(title string, load func() (any, error), cancel context.CancelFunc) (any, error) {
	result, err := tea.NewProgram(pickerLoading{title: title, load: load, cancel: cancel, width: 80}, tea.WithAltScreen(), tea.WithInputTTY(), tea.WithOutput(os.Stderr)).Run()
	if err != nil {
		return nil, err
	}
	loaded := result.(pickerLoading).result
	return loaded.value, loaded.err
}
