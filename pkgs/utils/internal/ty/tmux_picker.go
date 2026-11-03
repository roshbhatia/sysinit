package ty

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/roshbhatia/go-utils/cell"
	"github.com/roshbhatia/go-utils/paths"
	"github.com/roshbhatia/go-utils/terminal"
	"github.com/roshbhatia/go-utils/ui"
)

type providerConfig struct {
	Name     string `json:"name"`
	Key      string `json:"key"`
	Manifest string `json:"manifest"`
}

type pickerConfig struct {
	Version   string           `json:"version"`
	Providers []providerConfig `json:"providers"`
}

type providerManifest struct {
	Version string   `json:"version"`
	Command []string `json:"command"`
	Actions map[string]struct {
		Argv []string `json:"argv"`
	} `json:"actions"`
}

type providerFrame struct {
	Version   string          `json:"version"`
	Kind      string          `json:"kind"`
	RequestID string          `json:"requestId"`
	Status    string          `json:"status"`
	Output    json.RawMessage `json:"output"`
	Message   string          `json:"message"`
}

type pickerDescriptor struct {
	Title  string `json:"title"`
	Create struct {
		Label  string `json:"label"`
		Prompt string `json:"prompt"`
	} `json:"create"`
}

type pickerItem struct {
	ID       string `json:"id"`
	Segments []struct {
		Text string `json:"text"`
		Role string `json:"role"`
	} `json:"segments"`
}

type pickerList struct {
	Items []pickerItem `json:"items"`
}

type spawnPlan struct {
	Kind        string            `json:"kind"`
	Label       string            `json:"label"`
	CWD         string            `json:"cwd"`
	Command     []string          `json:"command"`
	Environment map[string]string `json:"environment"`
}

type pickerChoice struct {
	label    string
	kind     string
	target   string
	window   string
	provider providerConfig
	item     pickerItem
	create   bool
}

type choiceModel struct {
	labels       []string
	input        textinput.Model
	matches      []int
	cursor       int
	selected     int
	width        int
	height       int
	insert       bool
	done         bool
	closeTargets bool
	action       string
	shortcuts    map[string]int
}

func newChoiceModel(labels []string, prompt string) choiceModel {
	input := textinput.New()
	input.Prompt = prompt
	input.CharLimit = 256
	input.Focus()
	m := choiceModel{input: input, selected: -1, width: 80, height: 12, insert: true}
	for _, label := range labels {
		m.labels = append(m.labels, strings.Map(func(r rune) rune {
			if r < 32 || r == 127 {
				return ' '
			}
			return r
		}, label))
	}
	m.filter()
	return m
}

func (m *choiceModel) filter() {
	m.matches = nil
	if m.input.Value() == "" {
		for i := range m.labels {
			m.matches = append(m.matches, i)
		}
	} else {
		for _, match := range list.DefaultFilter(m.input.Value(), m.labels) {
			m.matches = append(m.matches, match.Index)
		}
	}
	m.cursor = 0
}

func (m choiceModel) Init() tea.Cmd { return textinput.Blink }

func (m choiceModel) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := message.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = max(1, msg.Width), max(1, msg.Height)
		m.input.Width = max(1, m.width-cell.Width(m.input.Prompt)-1)
		return m, nil
	case tea.KeyMsg:
		if !m.insert && msg.Type == tea.KeyRunes && len(msg.Runes) > 1 {
			for _, r := range msg.Runes {
				next, _ := m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{r}})
				m = next.(choiceModel)
				if m.done {
					break
				}
			}
			return m, nil
		}
		key := msg.String()
		if terminal.IsControlReply(key) {
			return m, nil
		}
		switch key {
		case "ctrl+c", "ctrl+g":
			m.done = true
			return m, tea.Quit
		case "enter":
			if len(m.matches) > 0 {
				m.selected, m.done = m.matches[m.cursor], true
				return m, tea.Quit
			}
			return m, nil
		case "tab", "down", "ctrl+j", "ctrl+n":
			m.cursor = min(m.cursor+1, max(0, len(m.matches)-1))
			return m, nil
		case "shift+tab", "up", "ctrl+k", "ctrl+p":
			m.cursor = max(0, m.cursor-1)
			return m, nil
		case "esc":
			if !m.insert {
				m.done = true
				return m, tea.Quit
			}
			m.insert = false
			m.input.Blur()
			return m, nil
		}
		if !m.insert {
			if selected, ok := m.shortcuts[key]; ok {
				m.selected, m.done = selected, true
				return m, tea.Quit
			}
			if key == "x" && m.closeTargets && len(m.matches) > 0 {
				m.selected, m.done, m.action = m.matches[m.cursor], true, "close"
				return m, tea.Quit
			}
			if key == "i" || key == "/" {
				m.insert = true
				return m, m.input.Focus()
			}
			if action, ok := ui.ActionFor(ui.Key{Name: key}); ok {
				switch action {
				case ui.ActionDown:
					m.cursor = min(m.cursor+1, max(0, len(m.matches)-1))
				case ui.ActionUp:
					m.cursor = max(0, m.cursor-1)
				case ui.ActionQuit:
					m.done = true
					return m, tea.Quit
				}
			}
			return m, nil
		}
	}
	before := m.input.Value()
	var cmd tea.Cmd
	m.input, cmd = m.input.Update(message)
	if before != m.input.Value() {
		m.filter()
	}
	return m, cmd
}

func (m choiceModel) View() string {
	if m.done {
		return ""
	}
	if m.height < 4 {
		return cell.Truncate("Picker needs 4 rows. Ctrl-C cancels.", m.width)
	}
	palette := ui.TerminalPalette()
	accent := lipgloss.NewStyle().Foreground(lipgloss.Color(palette.Accent)).Bold(true)
	muted := lipgloss.NewStyle().Foreground(lipgloss.Color(palette.Muted))
	rows := m.height - 3
	start := max(0, m.cursor-rows+1)
	lines := []string{muted.Render(cell.Truncate(fmt.Sprintf("%d/%d", len(m.matches), len(m.labels)), m.width))}
	for offset := range rows {
		index := start + offset
		line := ""
		if index < len(m.matches) {
			line = cell.Truncate("  "+m.labels[m.matches[index]], m.width)
			if index == m.cursor {
				line = accent.Render(cell.Truncate("> "+m.labels[m.matches[index]], m.width))
			}
		} else if offset == 0 {
			line = muted.Render(cell.Truncate("  No matches", m.width))
		}
		lines = append(lines, line)
	}
	mode, hint := "INSERT", "Tab/Shift-Tab move · Enter choose · Esc normal · Ctrl-C cancel"
	if !m.insert {
		mode, hint = "NORMAL", "j/k move · i or / search · Enter choose · Esc cancel"
		if m.closeTargets {
			hint += " · x close · provider shortcut"
		}
	}
	lines = append(lines, cell.Truncate(m.input.View(), m.width), muted.Render(cell.Truncate(mode+" · "+hint, m.width)))
	return strings.Join(lines, "\n")
}

func choose(labels []string, prompt string) (int, error) {
	if !terminal.IsTTY(os.Stderr) {
		return -1, errors.New("the session picker needs a terminal")
	}
	result, err := tea.NewProgram(newChoiceModel(labels, prompt), tea.WithInputTTY(), tea.WithOutput(os.Stderr)).Run()
	if err != nil {
		return -1, err
	}
	return result.(choiceModel).selected, nil
}

type textModel struct {
	input textinput.Model
	value string
	width int
	done  bool
}

func (m textModel) Init() tea.Cmd { return textinput.Blink }
func (m textModel) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	if size, ok := message.(tea.WindowSizeMsg); ok {
		m.width = max(1, size.Width)
		m.input.Width = max(1, m.width-cell.Width(m.input.Prompt)-1)
		return m, nil
	}
	if key, ok := message.(tea.KeyMsg); ok {
		switch key.String() {
		case "ctrl+c", "ctrl+g", "esc":
			m.done = true
			return m, tea.Quit
		case "enter":
			m.value, m.done = strings.TrimSpace(m.input.Value()), true
			return m, tea.Quit
		}
	}
	var cmd tea.Cmd
	m.input, cmd = m.input.Update(message)
	return m, cmd
}
func (m textModel) View() string {
	if m.done {
		return ""
	}
	return m.input.View() + "\nEsc cancels"
}

func prompt(prompt string) (string, error) {
	if !terminal.IsTTY(os.Stderr) {
		return "", errors.New("the session picker needs a terminal")
	}
	in := textinput.New()
	in.Prompt = prompt + "> "
	in.CharLimit = 128
	in.Focus()
	result, err := tea.NewProgram(textModel{input: in, width: 80}, tea.WithInputTTY(), tea.WithOutput(os.Stderr)).Run()
	if err != nil {
		return "", err
	}
	return result.(textModel).value, nil
}

func runTmuxPicker(stdout io.Writer, runner commandRunner) error {
	if os.Getenv("TMUX") == "" {
		return errors.New("the picker must run inside tmux")
	}
	configPath, err := paths.ConfigHomeE()
	if err != nil {
		return err
	}
	configFile := os.Getenv("SYSINIT_TMUX_PROVIDERS")
	if configFile == "" {
		configFile = filepath.Join(configPath, "sysinit", "tmux-providers.json")
	}
	body, err := os.ReadFile(configFile)
	if err != nil {
		return fmt.Errorf("read tmux provider config: %w", err)
	}
	var config pickerConfig
	if err := json.Unmarshal(body, &config); err != nil || config.Version != "sysinit.tmux-providers/v1" {
		return errors.New("invalid tmux provider config")
	}
	sessions, err := call(runner, "tmux", []string{"list-sessions", "-F", "#{session_name}\t#{session_windows}\t#{session_attached}"}, nil)
	if err != nil {
		return fmt.Errorf("list tmux sessions: %w", err)
	}
	choices := []pickerChoice{{label: "+  New tmux session", kind: "new"}}
	for _, line := range strings.Split(strings.TrimSpace(string(sessions)), "\n") {
		if line == "" {
			continue
		}
		fields := strings.Split(line, "\t")
		if len(fields) != 3 || !validSessionName(fields[0]) {
			return errors.New("tmux returned an invalid session row")
		}
		choices = append(choices, pickerChoice{
			label: fmt.Sprintf("%s  ·  %s windows  ·  %s attached", fields[0], fields[1], fields[2]),
			kind:  "session", target: fields[0],
		})
	}
	panes, err := call(runner, "tmux", []string{"list-panes", "-a", "-F", "#{pane_id}\t#{session_name}\t#{window_index}\t#{pane_index}\t#{pane_current_command}\t#{pane_current_path}"}, nil)
	if err != nil {
		return fmt.Errorf("list tmux panes: %w", err)
	}
	for _, line := range strings.Split(strings.TrimSpace(string(panes)), "\n") {
		if line == "" {
			continue
		}
		fields := strings.Split(line, "\t")
		if len(fields) != 6 {
			return errors.New("tmux returned an invalid pane row")
		}
		if _, err := parseTmuxPaneID(fields[0]); err != nil || !validSessionName(fields[1]) {
			return errors.New("tmux returned an unsafe pane or session identifier")
		}
		choices = append(choices, pickerChoice{
			label: fmt.Sprintf("  %s:%s.%s  ·  %s  ·  %s", fields[1], fields[2], fields[3], fields[4], filepath.Base(fields[5])),
			kind:  "pane", target: fields[0], window: fields[1] + ":" + fields[2],
		})
	}
	for _, provider := range config.Providers {
		if provider.Name == "" || provider.Key == "" || provider.Manifest == "" {
			return errors.New("tmux provider has incomplete configuration")
		}
		choices = append(choices, pickerChoice{label: provider.Key + "  " + provider.Name, kind: "provider", provider: provider})
	}
	labels := make([]string, len(choices))
	for i := range choices {
		labels[i] = choices[i].label
	}
	model := newChoiceModel(labels, "sessions · providers")
	model.insert, model.closeTargets = false, true
	model.input.Blur()
	model.shortcuts = make(map[string]int)
	for index, choice := range choices {
		if choice.kind == "provider" {
			model.shortcuts[choice.provider.Key] = index
		}
	}
	if !terminal.IsTTY(os.Stderr) {
		return errors.New("the session picker needs a terminal")
	}
	result, err := tea.NewProgram(model, tea.WithInputTTY(), tea.WithOutput(os.Stderr)).Run()
	if err != nil {
		return err
	}
	selected := result.(choiceModel).selected
	if selected < 0 {
		return nil
	}
	choice := choices[selected]
	if result.(choiceModel).action == "close" {
		if choice.kind != "session" && choice.kind != "pane" {
			return nil
		}
		confirmation, err := choose([]string{"Cancel", "Close " + choice.label}, "Close live terminal")
		if err != nil || confirmation != 1 {
			return err
		}
		command, target := "kill-session", "="+choice.target
		if choice.kind == "pane" {
			command, target = "kill-pane", choice.target
		}
		_, err = call(runner, "tmux", []string{command, "-t", target}, nil)
		return err
	}
	switch choice.kind {
	case "new":
		name, err := prompt("Session name")
		if err != nil || name == "" {
			return err
		}
		if !validSessionName(name) {
			return errors.New("session name contains characters tmux cannot target safely")
		}
		if _, err := call(runner, "tmux", []string{"new-session", "-d", "-s", name}, nil); err != nil {
			return fmt.Errorf("create tmux session: %w", err)
		}
		return switchSession(runner, name)
	case "session":
		return switchSession(runner, choice.target)
	case "pane":
		if _, err := call(runner, "tmux", []string{"switch-client", "-t", choice.window}, nil); err != nil {
			return fmt.Errorf("switch to tmux window %s: %w", choice.window, err)
		}
		if _, err := call(runner, "tmux", []string{"select-pane", "-t", choice.target}, nil); err != nil {
			return fmt.Errorf("select tmux pane %s: %w", choice.target, err)
		}
		return nil
	case "provider":
		return chooseProvider(runner, choice.provider)
	default:
		return errors.New("unknown picker row")
	}
}

func chooseProvider(runner commandRunner, provider providerConfig) error {
	ctx, cancel := context.WithTimeout(context.Background(), 12*time.Second)
	defer cancel()
	var manifest providerManifest
	data, err := os.ReadFile(provider.Manifest)
	if err != nil {
		return fmt.Errorf("read %s provider manifest: %w", provider.Name, err)
	}
	if err := json.Unmarshal(data, &manifest); err != nil || manifest.Version != "provider/v1" || len(manifest.Command) == 0 {
		return fmt.Errorf("invalid %s provider manifest", provider.Name)
	}
	describe, err := callProvider(ctx, runner, manifest, "picker.describe", "")
	if err != nil {
		return err
	}
	var descriptor pickerDescriptor
	if err := json.Unmarshal(describe, &descriptor); err != nil || descriptor.Title == "" {
		return fmt.Errorf("%s provider returned an invalid description", provider.Name)
	}
	listedJSON, err := callProvider(ctx, runner, manifest, "picker.list", "")
	if err != nil {
		return err
	}
	var listed pickerList
	if err := json.Unmarshal(listedJSON, &listed); err != nil {
		return fmt.Errorf("%s provider returned an invalid item list", provider.Name)
	}
	choices := make([]pickerChoice, 0, len(listed.Items)+1)
	for _, item := range listed.Items {
		if item.ID == "" {
			continue
		}
		parts := make([]string, 0, len(item.Segments))
		for _, segment := range item.Segments {
			parts = append(parts, strings.Join(strings.Fields(segment.Text), " "))
		}
		label := strings.Join(parts, "  ")
		if label == "" {
			label = item.ID
		}
		choices = append(choices, pickerChoice{label: label, kind: "open", provider: provider, item: item})
	}
	if _, canCreate := manifest.Actions["picker.create"]; canCreate {
		label := descriptor.Create.Label
		if label == "" {
			label = "New session"
		}
		choices = append(choices, pickerChoice{label: "+  " + label, kind: "create", provider: provider, create: true})
	}
	if len(choices) == 0 {
		return nil
	}
	labels := make([]string, len(choices))
	for i := range choices {
		labels[i] = choices[i].label
	}
	selected, err := choose(labels, descriptor.Title)
	if err != nil || selected < 0 {
		return err
	}
	var planJSON json.RawMessage
	var actionErr error
	if choices[selected].create {
		name, err := prompt(descriptor.Create.Prompt)
		if err != nil || name == "" {
			return err
		}
		if provider.Name == "seshy" {
			planJSON, actionErr = createSeshySession(ctx, runner, name)
		} else {
			planJSON, actionErr = callProvider(ctx, runner, manifest, "picker.create", name)
		}
	} else {
		planJSON, actionErr = callProvider(ctx, runner, manifest, "picker.open", choices[selected].item.ID)
	}
	if actionErr != nil {
		return actionErr
	}
	var plan spawnPlan
	if err := json.Unmarshal(planJSON, &plan); err != nil || plan.Kind != "spawn" || !filepath.IsAbs(plan.CWD) {
		return fmt.Errorf("%s provider returned an invalid spawn plan", provider.Name)
	}
	for _, arg := range plan.Command {
		if strings.ContainsRune(arg, '\x00') {
			return errors.New("provider command contains a null byte")
		}
	}
	for key, value := range plan.Environment {
		if !validEnvironmentKey(key) || strings.ContainsRune(value, '\x00') {
			return fmt.Errorf("provider returned an invalid environment entry %q", key)
		}
	}
	name := providerSessionName(provider.Name, choices[selected], plan)
	return openPlanInTmux(runner, name, plan)
}

func createSeshySession(ctx context.Context, runner commandRunner, name string) (json.RawMessage, error) {
	if !validSessionName(name) {
		return nil, errors.New("invalid seshy session name")
	}
	cmd := exec.CommandContext(ctx, commandPath("SYSINIT_TY_SY", "sy"), "new", name)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	if err := cmd.Run(); err != nil {
		return nil, fmt.Errorf("create seshy session: %w", err)
	}
	body, err := runner(ctx, "sy", []string{"open", name, "--format", "json"}, nil)
	if err != nil {
		return nil, fmt.Errorf("resolve new seshy session: %w", err)
	}
	var plan openPlan
	if err := json.Unmarshal(body, &plan); err != nil {
		return nil, fmt.Errorf("decode seshy open plan: %w", err)
	}
	if plan.Version != "seshy.open/v1" || !filepath.IsAbs(plan.CWD) || len(plan.Command) != 0 {
		return nil, errors.New("seshy returned an unsupported session plan")
	}
	return json.Marshal(spawnPlan{
		Kind: "spawn", Label: name, CWD: plan.CWD,
		Command: plan.Command, Environment: plan.Environment,
	})
}

func callProvider(ctx context.Context, runner commandRunner, manifest providerManifest, capability, item string) (json.RawMessage, error) {
	action, ok := manifest.Actions[capability]
	if !ok {
		return nil, fmt.Errorf("provider does not support %s", capability)
	}
	args := append(append([]string(nil), manifest.Command...), action.Argv...)
	requestID := fmt.Sprintf("ty-%d-%d", os.Getpid(), time.Now().UnixNano())
	input := map[string]string{}
	if item != "" {
		key := "id"
		if capability == "picker.create" {
			key = "name"
		}
		input[key] = item
	}
	request := map[string]any{
		"version": "provider/v1", "kind": "request", "requestId": requestID,
		"capability": capability, "input": input,
	}
	encoded, err := json.Marshal(request)
	if err != nil {
		return nil, err
	}
	output, err := runner(ctx, args[0], args[1:], strings.NewReader(string(encoded)+"\n"))
	if err != nil {
		return nil, fmt.Errorf("run provider %s: %w", capability, err)
	}
	var result *providerFrame
	for _, line := range strings.Split(strings.TrimSpace(string(output)), "\n") {
		var frame providerFrame
		if err := json.Unmarshal([]byte(line), &frame); err != nil {
			return nil, fmt.Errorf("provider returned malformed JSON: %w", err)
		}
		if frame.Version != "provider/v1" || frame.RequestID != requestID {
			return nil, errors.New("provider returned an unrelated frame")
		}
		if frame.Kind == "event" {
			continue
		}
		if frame.Kind != "result" || result != nil {
			return nil, errors.New("provider returned an invalid result stream")
		}
		result = &frame
	}
	if result == nil || result.Status != "ok" {
		if result != nil && result.Message != "" {
			return nil, errors.New(result.Message)
		}
		return nil, errors.New("provider returned no successful result")
	}
	return result.Output, nil
}

func providerSessionName(name string, choice pickerChoice, plan spawnPlan) string {
	if name == "seshy" {
		if choice.item.ID != "" && validSessionName(choice.item.ID) {
			return choice.item.ID
		}
		if plan.Label != "" && validSessionName(plan.Label) {
			return plan.Label
		}
	}
	base := strings.ToLower(name + "-" + choice.item.ID)
	var builder strings.Builder
	for _, r := range base {
		if r >= 'a' && r <= 'z' || r >= '0' && r <= '9' || r == '-' || r == '_' {
			builder.WriteRune(r)
		} else if r == '/' || r == ' ' || r == '.' {
			builder.WriteRune('-')
		}
	}
	value := strings.Trim(builder.String(), "-")
	if value == "" {
		sum := sha256.Sum256([]byte(plan.CWD))
		value = name + "-" + hex.EncodeToString(sum[:4])
	}
	if len(value) > 48 {
		sum := sha256.Sum256([]byte(value))
		value = strings.TrimRight(value[:39], "-") + "-" + hex.EncodeToString(sum[:4])
	}
	return value
}

func openPlanInTmux(runner commandRunner, name string, plan spawnPlan) error {
	if !validSessionName(name) {
		return fmt.Errorf("invalid tmux session name %q", name)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	if _, err := runner(ctx, "tmux", []string{"has-session", "-t", "=" + name}, nil); err != nil {
		args := []string{"new-session", "-d", "-s", name, "-c", plan.CWD}
		for _, key := range sortedKeys(plan.Environment) {
			args = append(args, "-e", key+"="+plan.Environment[key])
		}
		if len(plan.Command) > 0 {
			args = append(args, shellCommand(plan.Command))
		}
		if _, err := runner(ctx, "tmux", args, nil); err != nil {
			return fmt.Errorf("create tmux provider session %q: %w", name, err)
		}
	}
	return switchSession(runner, name)
}

func switchSession(runner commandRunner, name string) error {
	if _, err := call(runner, "tmux", []string{"switch-client", "-t", "=" + name}, nil); err != nil {
		return fmt.Errorf("switch to tmux session %q: %w", name, err)
	}
	return nil
}
