package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/help"
	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/x/ansi"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/broker"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/instance"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/store/sqlite"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
	"github.com/roshbhatia/sysinit/pkgs/internal/agents"
)

type orcaActionMessage struct {
	text       string
	err        error
	workflowID domain.WorkflowRunID
}

type orcaKeyMap struct {
	up         key.Binding
	down       key.Binding
	left       key.Binding
	right      key.Binding
	toggle     key.Binding
	open       key.Binding
	resume     key.Binding
	replay     key.Binding
	refresh    key.Binding
	switchView key.Binding
	showHelp   key.Binding
	quit       key.Binding
}

func (keys orcaKeyMap) ShortHelp() []key.Binding {
	return []key.Binding{keys.switchView, keys.open, keys.refresh, keys.showHelp, keys.quit}
}

func (keys orcaKeyMap) FullHelp() [][]key.Binding {
	return [][]key.Binding{
		{keys.up, keys.down, keys.left, keys.right},
		{keys.open, keys.resume, keys.replay, keys.switchView, keys.toggle},
		{keys.refresh, keys.showHelp, keys.quit},
	}
}

var orcaKeys = orcaKeyMap{
	up:         key.NewBinding(key.WithKeys("up", "k"), key.WithHelp("up/k", "previous")),
	down:       key.NewBinding(key.WithKeys("down", "j"), key.WithHelp("down/j", "next")),
	left:       key.NewBinding(key.WithKeys("left", "h"), key.WithHelp("left/h", "previous restart point")),
	right:      key.NewBinding(key.WithKeys("right", "l"), key.WithHelp("right/l", "next restart point")),
	toggle:     key.NewBinding(key.WithKeys("s"), key.WithHelp("s", "start or stop")),
	open:       key.NewBinding(key.WithKeys("enter"), key.WithHelp("enter", "open")),
	resume:     key.NewBinding(key.WithKeys("R"), key.WithHelp("R", "resume controller")),
	replay:     key.NewBinding(key.WithKeys("f"), key.WithHelp("f", "fork from restart point")),
	refresh:    key.NewBinding(key.WithKeys("r"), key.WithHelp("r", "refresh")),
	switchView: key.NewBinding(key.WithKeys("tab"), key.WithHelp("tab", "change view")),
	showHelp:   key.NewBinding(key.WithKeys("?"), key.WithHelp("?", "more keys")),
	quit:       key.NewBinding(key.WithKeys("q", "ctrl+c"), key.WithHelp("q", "quit")),
}

type orcaUIModel struct {
	record         instance.Record
	active         bool
	agents         []agents.Agent
	cursor         int
	message        string
	messageError   bool
	selected       string
	selectedResume bool
	selectedWorker domain.SessionID
	width          int
	height         int
	help           help.Model
	view           int
	workflows      []domain.WorkflowRun
	workflow       workflowViewResult
	definition     workflowmodel.Definition
	workflowCursor int
	restartPoints  []domain.RestartPoint
	restartCursor  int
	forks          []domain.RunFork
	workers        []domain.Session
	workerHistory  sqlite.SessionHistory
	workerCursor   int
	confirmReplay  bool
}

const (
	orcaControllersView = iota
	orcaWorkflowsView
	orcaWorkersView
)

var (
	// These ANSI roles match traces, so the terminal palette owns the hue in both tools.
	orcaTitleStyle    = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("4"))
	orcaTagStyle      = lipgloss.NewStyle().Foreground(lipgloss.Color("8"))
	orcaLabelStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("8"))
	orcaValueStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("7"))
	orcaActiveStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("2"))
	orcaInactiveStyle = lipgloss.NewStyle().Faint(true).Foreground(lipgloss.Color("8"))
	orcaRuleStyle     = lipgloss.NewStyle().Faint(true).Foreground(lipgloss.Color("8"))
	orcaSelectedStyle = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("6"))
	orcaMessageStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("6"))
	orcaErrorStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("1"))
)

func runOrcaUI(stdout io.Writer, stderr io.Writer) int {
	model, err := newOrcaUIModel()
	if err != nil {
		fmt.Fprintf(stderr, "open UI: %v\n", err)
		return 1
	}
	program := tea.NewProgram(model, tea.WithInput(os.Stdin), tea.WithOutput(stdout), tea.WithAltScreen())
	result, err := program.Run()
	if err != nil {
		fmt.Fprintf(stderr, "run UI: %v\n", err)
		return 1
	}
	finished, ok := result.(orcaUIModel)
	if !ok {
		return 0
	}
	if finished.selected != "" {
		return runOrcaController([]string{finished.selected}, stderr, finished.selectedResume)
	}
	if finished.selectedWorker != "" {
		return runOrcaWorkerUI(finished.record, finished.selectedWorker, stdout, stderr)
	}
	return 0
}

func newOrcaUIModel() (orcaUIModel, error) {
	model := orcaUIModel{help: help.New(), width: 92, height: 26}
	model.help.ShortSeparator = "   "
	model.help.Styles.ShortKey = orcaTitleStyle
	model.help.Styles.FullKey = orcaTitleStyle
	model.help.Styles.ShortDesc = orcaTagStyle
	model.help.Styles.FullDesc = orcaTagStyle
	model.help.Styles.ShortSeparator = orcaTagStyle
	model.help.Styles.FullSeparator = orcaTagStyle
	if err := model.refresh(); err != nil {
		return model, err
	}
	registry, err := agents.Load()
	if err != nil {
		return model, err
	}
	for _, agent := range registry.Agents {
		if agent.Command == "" {
			continue
		}
		if _, err := exec.LookPath(agent.Command); err == nil {
			model.agents = append(model.agents, agent)
		}
	}
	sortAgentsByRecency(model.agents)
	if len(model.workflows) > 0 {
		model.view = orcaWorkflowsView
	}
	return model, nil
}

func (model orcaUIModel) Init() tea.Cmd {
	return nil
}

func (model orcaUIModel) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch typed := message.(type) {
	case orcaActionMessage:
		model.messageError = typed.err != nil
		if typed.err != nil {
			model.message = typed.err.Error()
		} else {
			model.message = typed.text
		}
		if err := model.refresh(); err != nil {
			model.message = err.Error()
			model.messageError = true
		}
		if typed.workflowID != "" {
			model.selectWorkflow(typed.workflowID)
		}
	case tea.WindowSizeMsg:
		model.width = typed.Width
		model.height = typed.Height
		model.help.Width = typed.Width - 6
	case tea.KeyMsg:
		if !key.Matches(typed, orcaKeys.replay) {
			model.confirmReplay = false
		}
		switch {
		case key.Matches(typed, orcaKeys.quit):
			return model, tea.Quit
		case key.Matches(typed, orcaKeys.up):
			if err := model.moveCursor(-1); err != nil {
				model.message = err.Error()
				model.messageError = true
			}
		case key.Matches(typed, orcaKeys.down):
			if err := model.moveCursor(1); err != nil {
				model.message = err.Error()
				model.messageError = true
			}
		case key.Matches(typed, orcaKeys.left):
			model.moveRestartPoint(-1)
		case key.Matches(typed, orcaKeys.right):
			model.moveRestartPoint(1)
		case key.Matches(typed, orcaKeys.switchView):
			model.view = (model.view + 1) % 3
			model.message = ""
		case key.Matches(typed, orcaKeys.showHelp):
			model.help.ShowAll = !model.help.ShowAll
		case key.Matches(typed, orcaKeys.refresh):
			if err := model.refresh(); err != nil {
				model.message = err.Error()
				model.messageError = true
			} else {
				model.message = "Status refreshed"
				model.messageError = false
			}
		case key.Matches(typed, orcaKeys.toggle):
			active := model.active
			model.message = "Updating broker state"
			model.messageError = false
			return model, func() tea.Msg {
				var stdout, stderr bytes.Buffer
				var code int
				if active {
					code = runOrcaStop(nil, &stdout, &stderr)
				} else {
					code = runOrcaStart(nil, &stdout, &stderr)
				}
				text := strings.TrimSpace(stdout.String())
				if code != 0 {
					return orcaActionMessage{err: errors.New(strings.TrimSpace(stderr.String()))}
				}
				return orcaActionMessage{text: text}
			}
		case key.Matches(typed, orcaKeys.resume):
			if model.view == orcaControllersView && len(model.agents) > 0 &&
				len(model.agents[model.cursor].Launch.ResumeArgs) > 0 {
				model.selected = model.agents[model.cursor].Name
				model.selectedResume = true
				return model, tea.Quit
			}
		case key.Matches(typed, orcaKeys.replay):
			if model.view == orcaWorkflowsView && len(model.restartPoints) > 0 {
				if !model.confirmReplay {
					model.confirmReplay = true
					model.message = "Press f again to fork a child run from this restart point"
					model.messageError = false
					return model, nil
				}
				model.confirmReplay = false
				return model, model.replaySelectedWorkflow()
			}
		case key.Matches(typed, orcaKeys.open):
			switch model.view {
			case orcaControllersView:
				if len(model.agents) > 0 {
					model.selected = model.agents[model.cursor].Name
					return model, tea.Quit
				}
			case orcaWorkersView:
				if len(model.workers) > 0 {
					model.selectedWorker = model.workers[model.workerCursor].ID
					return model, tea.Quit
				}
			}
		}
	}
	return model, nil
}

func (model orcaUIModel) View() string {
	if model.width < 40 || model.height < 10 {
		return fmt.Sprintf("orca needs 40x10\nthis pane is %dx%d", model.width, model.height)
	}
	contentWidth := model.width

	header := model.header(contentWidth)
	scope := model.scopeLine(contentWidth)
	navigation := model.navigation()
	body := model.agentView(contentWidth)
	switch model.view {
	case orcaWorkflowsView:
		body = model.workflowView(contentWidth)
	case orcaWorkersView:
		body = model.workerView(contentWidth)
	}

	parts := []string{header, scope, navigation, body}
	if model.message != "" {
		style := orcaMessageStyle
		if model.messageError {
			style = orcaErrorStyle
		}
		parts = append(parts, style.Render(ansi.Truncate(model.message, contentWidth, "…")))
	}
	parts = append(parts, model.help.View(orcaKeys))

	return strings.Join(parts, "\n\n")
}

func (model orcaUIModel) header(width int) string {
	status := orcaInactiveStyle.Render("broker stopped")
	if model.active {
		status = orcaActiveStyle.Render("broker running")
	}
	left := orcaTitleStyle.Render("🫍 orca") + "  " + orcaTagStyle.Render("local agent orchestrator")
	gap := width - lipgloss.Width(left) - lipgloss.Width(status)
	if gap < 1 {
		gap = 1
	}
	return left + strings.Repeat(" ", gap) + status
}

func (model orcaUIModel) scopeLine(width int) string {
	scope := model.record.Scope
	if scope == "" {
		if current, err := os.Getwd(); err == nil {
			scope = current
		} else {
			scope = "."
		}
	}
	label := orcaLabelStyle.Render("workspace ")
	return label + orcaValueStyle.Render(ansi.Truncate(filepath.Clean(scope), width-lipgloss.Width(label), "…"))
}

func (model orcaUIModel) navigation() string {
	agentsTab := fmt.Sprintf(" controllers %d ", len(model.agents))
	workflowsTab := fmt.Sprintf(" workflows %d ", len(model.workflows))
	workersTab := fmt.Sprintf(" workers %d ", len(model.workers))
	switch model.view {
	case orcaControllersView:
		agentsTab = orcaSelectedStyle.Render(agentsTab)
	case orcaWorkflowsView:
		workflowsTab = orcaSelectedStyle.Render(workflowsTab)
	case orcaWorkersView:
		workersTab = orcaSelectedStyle.Render(workersTab)
	}
	if model.view != orcaControllersView {
		agentsTab = orcaTagStyle.Render(agentsTab)
	}
	if model.view != orcaWorkflowsView {
		workflowsTab = orcaTagStyle.Render(workflowsTab)
	}
	if model.view != orcaWorkersView {
		workersTab = orcaTagStyle.Render(workersTab)
	}
	return agentsTab + "  " + workflowsTab + "  " + workersTab
}

func (model orcaUIModel) agentView(width int) string {
	rows := model.visibleAgentRows()
	listWidth := 30
	list := orcaBox("controllers", listWidth, strings.Join(rows, "\n"), model.view == orcaControllersView)
	detailWidth := width - lipgloss.Width(list) - 4
	details := model.agentDetails(detailWidth)
	body := lipgloss.JoinHorizontal(lipgloss.Top, list, "  ", details)
	if width < 76 {
		list = orcaBox("controllers", width-2, strings.Join(rows, "\n"), model.view == orcaControllersView)
		details = model.agentDetails(width - 2)
		body = lipgloss.JoinVertical(lipgloss.Left, list, "", details)
	}
	return body
}

func (model orcaUIModel) workflowView(width int) string {
	rows := model.visibleWorkflowRows()
	listWidth := 34
	list := orcaBox("runs", listWidth, strings.Join(rows, "\n"), model.view == orcaWorkflowsView)
	detailWidth := width - lipgloss.Width(list) - 4
	details := model.workflowDetails(detailWidth)
	body := lipgloss.JoinHorizontal(lipgloss.Top, list, "  ", details)
	if width < 82 {
		list = orcaBox("runs", width-2, strings.Join(rows, "\n"), model.view == orcaWorkflowsView)
		details = model.workflowDetails(width - 2)
		body = lipgloss.JoinVertical(lipgloss.Left, list, "", details)
	}
	return body
}

func (model orcaUIModel) visibleWorkflowRows() []string {
	if len(model.workflows) == 0 {
		return []string{orcaTagStyle.Render("No workflow runs")}
	}
	limit := model.height - 16
	if limit < 4 {
		limit = 4
	}
	if limit > 10 {
		limit = 10
	}
	start := model.workflowCursor - limit/2
	if start < 0 {
		start = 0
	}
	if start+limit > len(model.workflows) {
		start = len(model.workflows) - limit
		if start < 0 {
			start = 0
		}
	}
	end := start + limit
	if end > len(model.workflows) {
		end = len(model.workflows)
	}
	rows := make([]string, 0, end-start)
	for index := start; index < end; index++ {
		run := model.workflows[index]
		row := fmt.Sprintf(" %-19s %-9s", ansi.Truncate(string(run.ID), 19, "…"), run.State)
		if index == model.workflowCursor {
			row = orcaSelectedStyle.Width(29).Render(">" + row)
		} else {
			row = orcaValueStyle.Render(" " + row)
		}
		rows = append(rows, row)
	}
	return rows
}

func (model orcaUIModel) workflowDetails(width int) string {
	if width < 34 {
		width = 34
	}
	if len(model.workflows) == 0 {
		return orcaBox("graph", width, "Planning and spec work appears here as dedicated workflow runs.", false)
	}
	lines := []string{
		orcaTitleStyle.Render(string(model.workflow.Run.ID)),
		orcaLabelStyle.Render("state    ") + orcaValueStyle.Render(string(model.workflow.Run.State)),
		orcaLabelStyle.Render("version  ") + orcaValueStyle.Render(fmt.Sprintf("%d", model.workflow.Run.DefinitionVersion)),
	}
	if len(model.restartPoints) > 0 {
		point := model.restartPoints[model.restartCursor]
		lines = append(lines,
			orcaLabelStyle.Render("restart  ")+orcaValueStyle.Render(fmt.Sprintf(
				"%d/%d %s @ %d", model.restartCursor+1, len(model.restartPoints), point.Kind, point.EventCursor,
			)),
			orcaTagStyle.Render("          h/l selects, f forks a child run"),
		)
	} else {
		lines = append(lines, orcaLabelStyle.Render("restart  ")+orcaInactiveStyle.Render("none"))
	}
	for _, fork := range model.forks {
		relation := "child " + string(fork.ChildWorkflowRunID)
		if fork.ChildWorkflowRunID == model.workflow.Run.ID {
			relation = "parent " + string(fork.ParentWorkflowRunID)
		}
		lines = append(lines, orcaLabelStyle.Render("lineage  ")+orcaValueStyle.Render(
			relation+" via "+string(fork.RestartPointID),
		))
	}
	lines = append(lines, "", orcaLabelStyle.Render("nodes"))
	nodes := append([]domain.NodeRun(nil), model.workflow.Nodes...)
	sort.Slice(nodes, func(first int, second int) bool { return nodes[first].NodeKey < nodes[second].NodeKey })
	for _, node := range nodes {
		lines = append(lines, fmt.Sprintf("  %-18s [%s]", node.NodeKey, node.State))
	}
	if len(model.definition.Edges) > 0 {
		lines = append(lines, "", orcaLabelStyle.Render("edges"))
		for _, edge := range model.definition.Edges {
			lines = append(lines, fmt.Sprintf("  %s.%s -> %s.%s", edge.From, edge.FromPort, edge.To, edge.ToPort))
		}
	}
	for index, line := range lines {
		lines[index] = ansi.Truncate(line, width-6, "…")
	}
	return orcaBox("graph", width, strings.Join(lines, "\n"), false)
}

func (model orcaUIModel) workerView(width int) string {
	rows := model.visibleWorkerRows()
	listWidth := 34
	list := orcaBox("workers", listWidth, strings.Join(rows, "\n"), model.view == orcaWorkersView)
	detailWidth := width - lipgloss.Width(list) - 4
	details := model.workerDetails(detailWidth)
	body := lipgloss.JoinHorizontal(lipgloss.Top, list, "  ", details)
	if width < 82 {
		list = orcaBox("workers", width-2, strings.Join(rows, "\n"), model.view == orcaWorkersView)
		details = model.workerDetails(width - 2)
		body = lipgloss.JoinVertical(lipgloss.Left, list, "", details)
	}
	return body
}

func (model orcaUIModel) visibleWorkerRows() []string {
	if len(model.workers) == 0 {
		return []string{orcaTagStyle.Render("No workflow workers")}
	}
	limit := model.visibleRowLimit()
	start, end := visibleRange(model.workerCursor, len(model.workers), limit)
	rows := make([]string, 0, end-start)
	for index := start; index < end; index++ {
		worker := model.workers[index]
		row := fmt.Sprintf(" %-19s %-9s", ansi.Truncate(string(worker.ID), 19, "…"), worker.State)
		if index == model.workerCursor {
			row = orcaSelectedStyle.Width(29).Render(">" + row)
		} else {
			row = orcaValueStyle.Render(" " + row)
		}
		rows = append(rows, row)
	}
	return rows
}

func (model orcaUIModel) workerDetails(width int) string {
	if width < 34 {
		width = 34
	}
	if len(model.workers) == 0 {
		return orcaBox("selected", width, "Workers appear after a workflow node starts an agent.", false)
	}
	worker := model.workers[model.workerCursor]
	lines := []string{
		orcaTitleStyle.Render(string(worker.ID)),
		orcaLabelStyle.Render("state     ") + orcaValueStyle.Render(string(worker.State)),
		orcaLabelStyle.Render("workflow  ") + orcaValueStyle.Render(string(worker.WorkflowRunID)),
		orcaLabelStyle.Render("node      ") + orcaValueStyle.Render(string(worker.NodeRunID)),
		orcaLabelStyle.Render("runtime   ") + orcaValueStyle.Render(worker.RuntimeAdapterID),
		orcaLabelStyle.Render("events    ") + orcaValueStyle.Render(fmt.Sprintf("%d", len(model.workerHistory.RuntimeEvents))),
		orcaLabelStyle.Render("actions   ") + orcaValueStyle.Render("enter attaches"),
	}
	if len(model.workerHistory.RuntimeEvents) > 0 {
		lines = append(lines, "", orcaLabelStyle.Render("recent events"))
		start := len(model.workerHistory.RuntimeEvents) - 4
		if start < 0 {
			start = 0
		}
		for _, event := range model.workerHistory.RuntimeEvents[start:] {
			lines = append(lines, fmt.Sprintf("  %d  %s  %s", event.Sequence, event.Kind, event.ProviderEventType))
		}
	}
	for index, line := range lines {
		lines[index] = ansi.Truncate(line, width-6, "…")
	}
	return orcaBox("selected", width, strings.Join(lines, "\n"), false)
}

func (model orcaUIModel) visibleRowLimit() int {
	limit := model.height - 16
	if limit < 4 {
		return 4
	}
	if limit > 10 {
		return 10
	}
	return limit
}

func visibleRange(cursor int, length int, limit int) (int, int) {
	start := cursor - limit/2
	if start < 0 {
		start = 0
	}
	if start+limit > length {
		start = length - limit
		if start < 0 {
			start = 0
		}
	}
	end := start + limit
	if end > length {
		end = length
	}
	return start, end
}

func (model orcaUIModel) visibleAgentRows() []string {
	if len(model.agents) == 0 {
		return []string{orcaTagStyle.Render("No installed controllers")}
	}
	limit := model.height - 16
	if limit < 4 {
		limit = 4
	}
	if limit > 10 {
		limit = 10
	}
	start := model.cursor - limit/2
	if start < 0 {
		start = 0
	}
	if start+limit > len(model.agents) {
		start = len(model.agents) - limit
		if start < 0 {
			start = 0
		}
	}
	end := start + limit
	if end > len(model.agents) {
		end = len(model.agents)
	}
	rows := make([]string, 0, end-start)
	for index := start; index < end; index++ {
		agent := model.agents[index]
		label := agent.Label
		if label == "" {
			label = agent.Name
		}
		glyph := strings.TrimSpace(agent.Glyph)
		if glyph != "" {
			glyph += " "
		}
		row := fmt.Sprintf(" %s%-20s", glyph, ansi.Truncate(label, 20-lipgloss.Width(glyph), "…"))
		if index == model.cursor {
			row = orcaSelectedStyle.Width(25).Render(">" + row)
		} else {
			row = orcaValueStyle.Render(" " + row)
		}
		rows = append(rows, row)
	}
	return rows
}

func (model orcaUIModel) agentDetails(width int) string {
	if width < 28 {
		width = 28
	}
	if len(model.agents) == 0 {
		return orcaBox("selected", width, "Install a controller to launch it here.", false)
	}
	agent := model.agents[model.cursor]
	label := agent.Label
	if label == "" {
		label = agent.Name
	}
	modelSupport := "uses command default"
	if agent.Launch.ModelFlag != "" {
		modelSupport = "accepts orca run --model"
	}
	mcp := "unavailable"
	if model.active {
		mcp = "available in this scope"
	}
	lines := []string{
		orcaTitleStyle.Render(label),
		orcaTagStyle.Render(agent.Name),
		"",
		orcaLabelStyle.Render("command  ") + orcaValueStyle.Render(agent.Command),
		orcaLabelStyle.Render("model    ") + orcaValueStyle.Render(modelSupport),
		orcaLabelStyle.Render("mcp      ") + orcaValueStyle.Render(mcp),
		orcaLabelStyle.Render("new      ") + orcaValueStyle.Render("enter"),
	}
	resume := "unavailable"
	if len(agent.Launch.ResumeArgs) > 0 {
		resume = "R, native conversation picker"
	}
	lines = append(lines, orcaLabelStyle.Render("resume   ")+orcaValueStyle.Render(resume))
	if model.active && model.record.PID > 0 {
		lines = append(lines, orcaLabelStyle.Render("broker   ")+orcaValueStyle.Render(fmt.Sprintf("pid %d", model.record.PID)))
	}
	return orcaBox("selected", width, strings.Join(lines, "\n"), false)
}

func orcaBox(name string, inner int, body string, focused bool) string {
	if inner < 1 {
		return body
	}
	edge := orcaRuleStyle
	if focused {
		edge = orcaTitleStyle
	}
	dashes := inner - 3 - lipgloss.Width(name)
	if dashes < 0 {
		dashes = 0
	}
	top := edge.Render("╭─ ") + orcaTitleStyle.Render(name) + edge.Render(" "+strings.Repeat("─", dashes)+"╮")
	lines := []string{orcaFit(top, inner+2)}
	for _, line := range strings.Split(body, "\n") {
		lines = append(lines, edge.Render("│")+orcaFit(line, inner)+edge.Render("│"))
	}
	lines = append(lines, edge.Render("╰"+strings.Repeat("─", inner)+"╯"))
	return strings.Join(lines, "\n")
}

func orcaFit(value string, width int) string {
	if width < 1 {
		return ""
	}
	value = ansi.Truncate(value, width, "…")
	if missing := width - ansi.StringWidth(value); missing > 0 {
		value += strings.Repeat(" ", missing)
	}
	return value
}

func (model *orcaUIModel) refresh() error {
	record, active, err := activeOrca()
	if err != nil {
		return err
	}
	model.record = record
	model.active = active
	if !active {
		model.workflows = nil
		model.workflow = workflowViewResult{}
		model.definition = workflowmodel.Definition{}
		model.restartPoints = nil
		model.forks = nil
		model.workers = nil
		model.workerHistory = sqlite.SessionHistory{}
		return nil
	}
	if err := model.loadWorkflows(); err != nil {
		return err
	}
	return model.loadWorkers()
}

func (model *orcaUIModel) moveCursor(delta int) error {
	if model.view == orcaControllersView {
		next := model.cursor + delta
		if next >= 0 && next < len(model.agents) {
			model.cursor = next
		}
		return nil
	}
	if model.view == orcaWorkflowsView {
		next := model.workflowCursor + delta
		if next < 0 || next >= len(model.workflows) {
			return nil
		}
		model.workflowCursor = next
		return model.loadSelectedWorkflow()
	}
	next := model.workerCursor + delta
	if next < 0 || next >= len(model.workers) {
		return nil
	}
	model.workerCursor = next
	return model.loadSelectedWorker()
}

func (model *orcaUIModel) loadWorkflows() error {
	command, err := executeNativeCommand(model.record.StateDirectory, "workflow.list", json.RawMessage(`{}`))
	if err != nil {
		return err
	}
	if err := json.Unmarshal(command.Result, &model.workflows); err != nil {
		return err
	}
	if len(model.workflows) == 0 {
		model.workflowCursor = 0
		model.workflow = workflowViewResult{}
		model.definition = workflowmodel.Definition{}
		model.restartPoints = nil
		model.forks = nil
		return nil
	}
	if model.workflowCursor >= len(model.workflows) {
		model.workflowCursor = len(model.workflows) - 1
	}
	return model.loadSelectedWorkflow()
}

func (model *orcaUIModel) loadSelectedWorkflow() error {
	if len(model.workflows) == 0 {
		return nil
	}
	view, definition, err := loadWorkflowView(
		model.record.StateDirectory, string(model.workflows[model.workflowCursor].ID),
	)
	if err != nil {
		return err
	}
	model.workflow = view
	model.definition = definition
	if err := model.loadRestartPoints(); err != nil {
		return err
	}
	return model.loadWorkflowForks()
}

func (model *orcaUIModel) loadRestartPoints() error {
	if len(model.workflows) == 0 {
		model.restartPoints = nil
		model.restartCursor = 0
		return nil
	}
	payload, err := json.Marshal(struct {
		RunID domain.WorkflowRunID `json:"runId"`
	}{RunID: model.workflows[model.workflowCursor].ID})
	if err != nil {
		return err
	}
	command, err := executeNativeCommand(model.record.StateDirectory, "workflow.restart-points", payload)
	if err != nil {
		return err
	}
	if err := json.Unmarshal(command.Result, &model.restartPoints); err != nil {
		return err
	}
	if model.restartCursor >= len(model.restartPoints) {
		model.restartCursor = max(0, len(model.restartPoints)-1)
	}
	return nil
}

func (model *orcaUIModel) loadWorkflowForks() error {
	if len(model.workflows) == 0 {
		model.forks = nil
		return nil
	}
	payload, err := json.Marshal(struct {
		RunID domain.WorkflowRunID `json:"runId"`
	}{RunID: model.workflows[model.workflowCursor].ID})
	if err != nil {
		return err
	}
	command, err := executeNativeCommand(model.record.StateDirectory, "workflow.forks", payload)
	if err != nil {
		return err
	}
	return json.Unmarshal(command.Result, &model.forks)
}

func (model *orcaUIModel) loadWorkers() error {
	command, err := executeNativeCommand(model.record.StateDirectory, "agent.list", json.RawMessage(`{}`))
	if err != nil {
		return err
	}
	if err := json.Unmarshal(command.Result, &model.workers); err != nil {
		return err
	}
	if len(model.workers) == 0 {
		model.workerCursor = 0
		model.workerHistory = sqlite.SessionHistory{}
		return nil
	}
	if model.workerCursor >= len(model.workers) {
		model.workerCursor = len(model.workers) - 1
	}
	return model.loadSelectedWorker()
}

func (model *orcaUIModel) loadSelectedWorker() error {
	if len(model.workers) == 0 {
		return nil
	}
	payload, err := json.Marshal(struct {
		SessionID domain.SessionID `json:"sessionId"`
	}{SessionID: model.workers[model.workerCursor].ID})
	if err != nil {
		return err
	}
	command, err := executeNativeCommand(model.record.StateDirectory, "agent.history", payload)
	if err != nil {
		return err
	}
	return json.Unmarshal(command.Result, &model.workerHistory)
}

func (model *orcaUIModel) moveRestartPoint(delta int) {
	if model.view != orcaWorkflowsView || len(model.restartPoints) == 0 {
		return
	}
	next := model.restartCursor + delta
	if next >= 0 && next < len(model.restartPoints) {
		model.restartCursor = next
	}
}

func (model *orcaUIModel) selectWorkflow(id domain.WorkflowRunID) {
	for index, run := range model.workflows {
		if run.ID == id {
			model.workflowCursor = index
			_ = model.loadSelectedWorkflow()
			return
		}
	}
}

func (model orcaUIModel) replaySelectedWorkflow() tea.Cmd {
	run := model.workflows[model.workflowCursor]
	point := model.restartPoints[model.restartCursor]
	return func() tea.Msg {
		identifier, err := localCommandID()
		if err != nil {
			return orcaActionMessage{err: err}
		}
		childID := domain.WorkflowRunID("run-" + identifier)
		payload, err := json.Marshal(struct {
			ID                      domain.RunForkID            `json:"id"`
			ParentWorkflowRunID     domain.WorkflowRunID        `json:"parentWorkflowRunId"`
			ChildWorkflowRunID      domain.WorkflowRunID        `json:"childWorkflowRunId"`
			RestartPointID          domain.RestartPointID       `json:"restartPointId"`
			TargetDefinitionID      domain.WorkflowDefinitionID `json:"targetWorkflowDefinitionId"`
			TargetDefinitionVersion uint64                      `json:"targetDefinitionVersion"`
			ExpectedParentVersion   domain.ResourceVersion      `json:"expectedParentVersion"`
			ReusedAdmissionIDs      []domain.AdmissionID        `json:"reusedAdmissionIds"`
			EnvironmentIDs          map[string]string           `json:"environmentIds,omitempty"`
		}{
			ID: domain.RunForkID("fork-" + identifier), ParentWorkflowRunID: run.ID,
			ChildWorkflowRunID: childID, RestartPointID: point.ID,
			TargetDefinitionID: run.WorkflowDefinition, TargetDefinitionVersion: run.DefinitionVersion,
			ExpectedParentVersion: run.Metadata.ResourceVersion, ReusedAdmissionIDs: []domain.AdmissionID{},
		})
		if err != nil {
			return orcaActionMessage{err: err}
		}
		if _, err := executeNativeCommand(model.record.StateDirectory, "workflow.replay", payload); err != nil {
			return orcaActionMessage{err: err}
		}
		return orcaActionMessage{text: "Forked " + string(childID), workflowID: childID}
	}
}

type orcaWorkerTick time.Time

type orcaWorkerActionMessage struct {
	text string
	err  error
}

type orcaWorkerUIModel struct {
	record       instance.Record
	history      sqlite.SessionHistory
	attachmentID string
	input        textinput.Model
	typing       bool
	message      string
	messageError bool
	width        int
	height       int
}

func runOrcaWorkerUI(
	record instance.Record,
	sessionID domain.SessionID,
	stdout io.Writer,
	stderr io.Writer,
) int {
	history, err := loadWorkerHistory(record.StateDirectory, sessionID)
	if err != nil {
		fmt.Fprintf(stderr, "read worker: %v\n", err)
		return 1
	}
	attachmentID, err := openWorkerAttachment(record.StateDirectory, history.Session)
	if err != nil {
		fmt.Fprintf(stderr, "attach worker: %v\n", err)
		return 1
	}
	defer func() {
		if err := closeWorkerAttachment(record.StateDirectory, history.Session, attachmentID); err != nil {
			fmt.Fprintf(stderr, "detach worker: %v\n", err)
		}
	}()
	input := textinput.New()
	input.Prompt = "> "
	input.Placeholder = "send a message to this worker"
	input.CharLimit = 4096
	input.TextStyle = orcaValueStyle
	input.PromptStyle = orcaSelectedStyle
	model := orcaWorkerUIModel{
		record: record, history: history, attachmentID: attachmentID,
		input: input, width: 92, height: 26,
	}
	program := tea.NewProgram(model, tea.WithInput(os.Stdin), tea.WithOutput(stdout), tea.WithAltScreen())
	if _, err := program.Run(); err != nil {
		fmt.Fprintf(stderr, "run worker UI: %v\n", err)
		return 1
	}
	return 0
}

func (model orcaWorkerUIModel) Init() tea.Cmd {
	return workerRefreshTick()
}

func (model orcaWorkerUIModel) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch typed := message.(type) {
	case orcaWorkerTick:
		history, err := loadWorkerHistory(model.record.StateDirectory, model.history.Session.ID)
		if err != nil {
			model.message = err.Error()
			model.messageError = true
		} else {
			model.history = history
		}
		return model, workerRefreshTick()
	case orcaWorkerActionMessage:
		model.messageError = typed.err != nil
		if typed.err != nil {
			model.message = typed.err.Error()
		} else {
			model.message = typed.text
			model.input.SetValue("")
			model.typing = false
			model.input.Blur()
		}
	case tea.WindowSizeMsg:
		model.width = typed.Width
		model.height = typed.Height
	case tea.KeyMsg:
		if model.typing {
			switch typed.Type {
			case tea.KeyEsc:
				model.typing = false
				model.input.Blur()
				return model, nil
			case tea.KeyEnter:
				message := strings.TrimSpace(model.input.Value())
				if message == "" {
					return model, nil
				}
				model.message = "Sending message"
				return model, model.sendMessage(message)
			}
			var command tea.Cmd
			model.input, command = model.input.Update(typed)
			return model, command
		}
		switch typed.String() {
		case "q", "ctrl+c":
			return model, tea.Quit
		case "i":
			model.typing = true
			return model, model.input.Focus()
		case "r":
			history, err := loadWorkerHistory(model.record.StateDirectory, model.history.Session.ID)
			if err != nil {
				model.message = err.Error()
				model.messageError = true
			} else {
				model.history = history
				model.message = "Worker refreshed"
				model.messageError = false
			}
		}
	}
	return model, nil
}

func (model orcaWorkerUIModel) View() string {
	if model.width < 40 || model.height < 10 {
		return fmt.Sprintf("orca needs 40x10\nthis pane is %dx%d", model.width, model.height)
	}
	session := model.history.Session
	status := orcaActiveStyle.Render(string(session.State))
	left := orcaTitleStyle.Render("🫍 orca") + "  " + orcaTagStyle.Render("worker attachment")
	gap := model.width - lipgloss.Width(left) - lipgloss.Width(status)
	if gap < 1 {
		gap = 1
	}
	header := left + strings.Repeat(" ", gap) + status
	scopeLabel := orcaLabelStyle.Render("workspace ")
	scope := scopeLabel + orcaValueStyle.Render(ansi.Truncate(model.record.Scope, model.width-lipgloss.Width(scopeLabel), "…"))
	identity := fmt.Sprintf(
		"%s  %s  %s", session.ID, session.WorkflowRunID, session.NodeRunID,
	)
	lines := model.workerEventLines()
	bodyHeight := model.height - 13
	if bodyHeight < 4 {
		bodyHeight = 4
	}
	if len(lines) > bodyHeight {
		lines = lines[len(lines)-bodyHeight:]
	}
	body := orcaBox("events", model.width-2, strings.Join(lines, "\n"), true)
	footer := orcaTagStyle.Render("i input   r refresh   q detach")
	parts := []string{header, scope, orcaValueStyle.Render(ansi.Truncate(identity, model.width, "…")), body}
	if model.typing {
		parts = append(parts, model.input.View()+"  "+orcaTagStyle.Render("enter send   esc cancel"))
	} else if model.message != "" {
		style := orcaMessageStyle
		if model.messageError {
			style = orcaErrorStyle
		}
		parts = append(parts, style.Render(ansi.Truncate(model.message, model.width, "…")))
	}
	parts = append(parts, footer)
	return strings.Join(parts, "\n\n")
}

func (model orcaWorkerUIModel) workerEventLines() []string {
	if len(model.history.RuntimeEvents) == 0 {
		return []string{orcaTagStyle.Render("Waiting for worker events")}
	}
	lines := make([]string, 0, len(model.history.RuntimeEvents))
	for _, event := range model.history.RuntimeEvents {
		timestamp := event.OccurredAt.Local().Format("15:04:05")
		line := fmt.Sprintf("%s  %4d  %-10s  %s", timestamp, event.Sequence, event.Kind, event.ProviderEventType)
		if detail := runtimeEventDetail(event); detail != "" {
			line += "  " + detail
		}
		lines = append(lines, ansi.Truncate(line, model.width-6, "…"))
	}
	return lines
}

func runtimeEventDetail(event domain.RuntimeEvent) string {
	var data struct {
		Role     string `json:"role"`
		ToolName string `json:"toolName"`
		IsError  bool   `json:"isError"`
	}
	if json.Unmarshal(event.Data, &data) != nil {
		return ""
	}
	detail := data.ToolName
	if detail == "" {
		detail = data.Role
	}
	if data.IsError {
		detail += " error"
	}
	return strings.TrimSpace(detail)
}

func (model orcaWorkerUIModel) sendMessage(message string) tea.Cmd {
	session := model.history.Session
	stateDirectory := model.record.StateDirectory
	return func() tea.Msg {
		if err := sendWorkerMessage(stateDirectory, session, message); err != nil {
			return orcaWorkerActionMessage{err: err}
		}
		return orcaWorkerActionMessage{text: "Message accepted"}
	}
}

func workerRefreshTick() tea.Cmd {
	return tea.Tick(time.Second, func(now time.Time) tea.Msg { return orcaWorkerTick(now) })
}

func loadWorkerHistory(stateDirectory string, sessionID domain.SessionID) (sqlite.SessionHistory, error) {
	payload, err := json.Marshal(struct {
		SessionID domain.SessionID `json:"sessionId"`
	}{SessionID: sessionID})
	if err != nil {
		return sqlite.SessionHistory{}, err
	}
	command, err := executeNativeCommand(stateDirectory, "agent.history", payload)
	if err != nil {
		return sqlite.SessionHistory{}, err
	}
	var history sqlite.SessionHistory
	if err := json.Unmarshal(command.Result, &history); err != nil {
		return sqlite.SessionHistory{}, err
	}
	return history, nil
}

func openWorkerAttachment(stateDirectory string, session domain.Session) (string, error) {
	input, err := json.Marshal(struct {
		SessionID domain.SessionID `json:"sessionId"`
		Cursor    uint64           `json:"cursor"`
	}{SessionID: session.ID, Cursor: session.RuntimeEventCursor})
	if err != nil {
		return "", err
	}
	request, err := workerAttachmentRequest(session, domain.InterventionKindAttach, "attachment.open", input)
	if err != nil {
		return "", err
	}
	payload, err := json.Marshal(request)
	if err != nil {
		return "", err
	}
	command, err := executeNativeCommand(stateDirectory, "agent.attach", payload)
	if err != nil {
		return "", err
	}
	var result broker.ForwardAttachmentResult
	if err := json.Unmarshal(command.Result, &result); err != nil {
		return "", err
	}
	var attachment struct {
		AttachmentID string `json:"attachmentId"`
	}
	if err := json.Unmarshal(result.Result.Output, &attachment); err != nil {
		return "", err
	}
	if attachment.AttachmentID == "" {
		return "", errors.New("worker attachment returned no identifier")
	}
	return attachment.AttachmentID, nil
}

func closeWorkerAttachment(stateDirectory string, session domain.Session, attachmentID string) error {
	input, err := json.Marshal(struct {
		AttachmentID string           `json:"attachmentId"`
		SessionID    domain.SessionID `json:"sessionId"`
	}{AttachmentID: attachmentID, SessionID: session.ID})
	if err != nil {
		return err
	}
	request, err := workerAttachmentRequest(session, domain.InterventionKindDetach, "attachment.close", input)
	if err != nil {
		return err
	}
	payload, err := json.Marshal(request)
	if err != nil {
		return err
	}
	_, err = executeNativeCommand(stateDirectory, "agent.detach", payload)
	return err
}

func workerAttachmentRequest(
	session domain.Session,
	kind domain.InterventionKind,
	operation string,
	input json.RawMessage,
) (broker.ForwardAttachmentRequest, error) {
	identifier, err := localCommandID()
	if err != nil {
		return broker.ForwardAttachmentRequest{}, err
	}
	return broker.ForwardAttachmentRequest{
		Intervention: sqlite.InterventionRequest{
			ID: domain.InterventionID("intervention-" + identifier), SessionID: session.ID,
			Kind: kind, Payload: input, Source: "orca-ui",
		},
		PluginID: session.RuntimePluginID,
		Operation: plugin.OperationEnvelope{
			ID:        domain.OperationID("operation-" + identifier),
			AdapterID: session.RuntimeAdapterID + ".attachment", Port: domain.AdapterPortAttachment,
			Operation: operation, Input: input, Deadline: time.Now().Add(time.Minute),
		},
	}, nil
}

func sendWorkerMessage(stateDirectory string, session domain.Session, message string) error {
	request, err := workerMessageRequest(session, message)
	if err != nil {
		return err
	}
	payload, err := json.Marshal(request)
	if err != nil {
		return err
	}
	_, err = executeNativeCommand(stateDirectory, "agent.intervene", payload)
	return err
}

func workerMessageRequest(session domain.Session, message string) (broker.ForwardInterventionRequest, error) {
	if session.RuntimeHandle == nil {
		return broker.ForwardInterventionRequest{}, errors.New("worker has no runtime handle")
	}
	identifier, err := localCommandID()
	if err != nil {
		return broker.ForwardInterventionRequest{}, err
	}
	behavior := "prompt"
	if session.State == domain.SessionStateRunning {
		behavior = "steer"
	}
	input, err := json.Marshal(struct {
		Message  string `json:"message"`
		Behavior string `json:"behavior"`
	}{Message: message, Behavior: behavior})
	if err != nil {
		return broker.ForwardInterventionRequest{}, err
	}
	return broker.ForwardInterventionRequest{
		Intervention: sqlite.InterventionRequest{
			ID: domain.InterventionID("intervention-" + identifier), SessionID: session.ID,
			Kind: domain.InterventionKindMessage, Payload: input, Source: "orca-ui",
		},
		Operation: plugin.OperationEnvelope{
			ID: domain.OperationID("operation-" + identifier), AdapterID: session.RuntimeAdapterID,
			Port: domain.AdapterPortAgentRuntime, Operation: "agent-runtime.input",
			HandleID: session.RuntimeHandle, Input: input, Deadline: time.Now().Add(time.Minute),
		},
	}, nil
}
