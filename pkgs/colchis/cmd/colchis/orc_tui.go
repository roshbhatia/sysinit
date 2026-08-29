package main

import (
	"bytes"
	"context"
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
	"github.com/muesli/termenv"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/api/socket"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/broker"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/config"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/instance"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/store/sqlite"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
	"github.com/roshbhatia/sysinit/pkgs/internal/agents"
)

type orcActionMessage struct {
	text       string
	err        error
	workflowID domain.WorkflowRunID
}

type orcRefreshTick time.Time

type orcRefreshResult struct {
	model    orcUIModel
	revision uint64
	success  string
	err      error
}

type orcKeyMap struct {
	up         key.Binding
	down       key.Binding
	left       key.Binding
	right      key.Binding
	toggle     key.Binding
	open       key.Binding
	resume     key.Binding
	replay     key.Binding
	pageUp     key.Binding
	pageDown   key.Binding
	refresh    key.Binding
	switchView key.Binding
	showHelp   key.Binding
	quit       key.Binding
}

func (keys orcKeyMap) ShortHelp() []key.Binding {
	return []key.Binding{keys.switchView, keys.open, keys.refresh, keys.showHelp, keys.quit}
}

func (keys orcKeyMap) FullHelp() [][]key.Binding {
	return [][]key.Binding{
		{keys.up, keys.down, keys.left, keys.right},
		{keys.pageUp, keys.pageDown, keys.open, keys.resume, keys.replay},
		{keys.switchView, keys.toggle},
		{keys.refresh, keys.showHelp, keys.quit},
	}
}

type orcHelpKeyMap struct {
	orcKeyMap
	short []key.Binding
	full  [][]key.Binding
}

func (keys orcHelpKeyMap) ShortHelp() []key.Binding {
	return keys.short
}

func (keys orcHelpKeyMap) FullHelp() [][]key.Binding {
	return keys.full
}

var orcKeys = orcKeyMap{
	up:         key.NewBinding(key.WithKeys("up", "k"), key.WithHelp("up/k", "previous")),
	down:       key.NewBinding(key.WithKeys("down", "j"), key.WithHelp("down/j", "next")),
	left:       key.NewBinding(key.WithKeys("left", "h"), key.WithHelp("left/h", "previous restart point")),
	right:      key.NewBinding(key.WithKeys("right", "l"), key.WithHelp("right/l", "next restart point")),
	toggle:     key.NewBinding(key.WithKeys("s"), key.WithHelp("s", "start or stop")),
	open:       key.NewBinding(key.WithKeys("enter"), key.WithHelp("enter", "open")),
	resume:     key.NewBinding(key.WithKeys("R"), key.WithHelp("R", "resume controller")),
	replay:     key.NewBinding(key.WithKeys("f"), key.WithHelp("f", "fork from restart point")),
	pageUp:     key.NewBinding(key.WithKeys("pgup", "ctrl+u"), key.WithHelp("pgup/^u", "graph up")),
	pageDown:   key.NewBinding(key.WithKeys("pgdown", "ctrl+d"), key.WithHelp("pgdn/^d", "graph down")),
	refresh:    key.NewBinding(key.WithKeys("r"), key.WithHelp("r", "refresh")),
	switchView: key.NewBinding(key.WithKeys("tab"), key.WithHelp("tab", "change view")),
	showHelp:   key.NewBinding(key.WithKeys("?"), key.WithHelp("?", "more keys")),
	quit:       key.NewBinding(key.WithKeys("q", "ctrl+c"), key.WithHelp("q", "quit")),
}

type orcUIModel struct {
	record               instance.Record
	active               bool
	agents               []agents.Agent
	cursor               int
	message              string
	messageError         bool
	selected             string
	selectedResume       bool
	selectedWorker       domain.SessionID
	width                int
	height               int
	help                 help.Model
	view                 int
	workflows            []domain.WorkflowRun
	workflow             workflowViewResult
	definition           workflowmodel.Definition
	workflowCursor       int
	restartPoints        []domain.RestartPoint
	restartCursor        int
	forks                []domain.RunFork
	workers              []domain.Session
	workerHistory        sqlite.SessionHistory
	workerCursor         int
	confirmReplay        bool
	graphOffset          int
	refreshing           bool
	refreshRevision      uint64
	requestedWorkflow    domain.WorkflowRunID
	pendingWorkerHistory bool
	pendingRefreshStatus string
}

const (
	orcControllersView = iota
	orcWorkflowsView
	orcWorkersView
)

var (
	// These ANSI roles match traces, so the terminal palette owns the hue in both tools.
	orcTitleStyle    = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("4"))
	orcTagStyle      = lipgloss.NewStyle().Foreground(lipgloss.Color("8"))
	orcLabelStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("8"))
	orcValueStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("7"))
	orcActiveStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("2"))
	orcInactiveStyle = lipgloss.NewStyle().Faint(true).Foreground(lipgloss.Color("8"))
	orcRuleStyle     = lipgloss.NewStyle().Faint(true).Foreground(lipgloss.Color("8"))
	orcSelectedStyle = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("6"))
	orcMessageStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("6"))
	orcErrorStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("1"))
)

func runOrcUI(stdout io.Writer, stderr io.Writer) int {
	model, err := newOrcUIModel()
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
	finished, ok := result.(orcUIModel)
	if !ok {
		return 0
	}
	if finished.selected != "" {
		return runOrcController([]string{finished.selected}, stderr, finished.selectedResume)
	}
	if finished.selectedWorker != "" {
		return runOrcWorkerUI(finished.record, finished.selectedWorker, stdout, stderr)
	}
	return 0
}

func newOrcUIModel() (orcUIModel, error) {
	lipgloss.SetColorProfile(termenv.ANSI)
	lipgloss.SetHasDarkBackground(true)
	model := orcUIModel{help: help.New(), width: 92, height: 26}
	model.help.ShortSeparator = "   "
	model.help.Styles.ShortKey = orcTitleStyle
	model.help.Styles.FullKey = orcTitleStyle
	model.help.Styles.ShortDesc = orcTagStyle
	model.help.Styles.FullDesc = orcTagStyle
	model.help.Styles.ShortSeparator = orcTagStyle
	model.help.Styles.FullSeparator = orcTagStyle
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
		model.view = orcWorkflowsView
	}
	return model, nil
}

func (model orcUIModel) Init() tea.Cmd {
	return orcRefreshCommand()
}

func (model orcUIModel) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch typed := message.(type) {
	case orcRefreshTick:
		refresh := model.beginRefresh(false, "")
		return model, tea.Batch(refresh, orcRefreshCommand())
	case orcRefreshResult:
		model.refreshing = false
		if typed.err != nil {
			model.message = typed.err.Error()
			model.messageError = true
		} else if typed.revision == model.refreshRevision {
			model.applyRefresh(typed.model)
			if typed.success != "" {
				model.message = typed.success
				model.messageError = false
			}
		}
		if typed.revision != model.refreshRevision || model.pendingWorkerHistory || model.pendingRefreshStatus != "" {
			return model, model.beginRefresh(false, "")
		}
	case orcActionMessage:
		model.messageError = typed.err != nil
		if typed.err != nil {
			model.message = typed.err.Error()
		} else {
			model.message = typed.text
		}
		if typed.workflowID != "" {
			model.requestedWorkflow = typed.workflowID
			model.refreshRevision++
		}
		return model, model.beginRefresh(true, "")
	case tea.WindowSizeMsg:
		model.width = typed.Width
		model.height = typed.Height
		model.help.Width = typed.Width
	case tea.KeyMsg:
		if !key.Matches(typed, orcKeys.replay) {
			model.confirmReplay = false
		}
		switch {
		case key.Matches(typed, orcKeys.quit):
			return model, tea.Quit
		case key.Matches(typed, orcKeys.up):
			if model.moveCursor(-1) {
				model.refreshRevision++
				return model, model.beginRefresh(true, "")
			}
		case key.Matches(typed, orcKeys.down):
			if model.moveCursor(1) {
				model.refreshRevision++
				return model, model.beginRefresh(true, "")
			}
		case key.Matches(typed, orcKeys.left):
			model.moveRestartPoint(-1)
		case key.Matches(typed, orcKeys.right):
			model.moveRestartPoint(1)
		case key.Matches(typed, orcKeys.pageUp):
			model.scrollGraph(-1)
		case key.Matches(typed, orcKeys.pageDown):
			model.scrollGraph(1)
		case key.Matches(typed, orcKeys.switchView):
			model.view = (model.view + 1) % 3
			model.message = ""
			model.refreshRevision++
			return model, model.beginRefresh(true, "")
		case key.Matches(typed, orcKeys.showHelp):
			model.help.ShowAll = !model.help.ShowAll
		case key.Matches(typed, orcKeys.refresh):
			return model, model.beginRefresh(true, "Status refreshed")
		case key.Matches(typed, orcKeys.toggle):
			active := model.active
			model.message = "Updating broker state"
			model.messageError = false
			return model, func() tea.Msg {
				var stdout, stderr bytes.Buffer
				var code int
				if active {
					code = runOrcStop(nil, &stdout, &stderr)
				} else {
					code = runOrcStart(nil, &stdout, &stderr)
				}
				text := strings.TrimSpace(stdout.String())
				if code != 0 {
					return orcActionMessage{err: errors.New(strings.TrimSpace(stderr.String()))}
				}
				return orcActionMessage{text: text}
			}
		case key.Matches(typed, orcKeys.resume):
			if model.view == orcControllersView && len(model.agents) > 0 &&
				len(model.agents[model.cursor].Launch.ResumeArgs) > 0 {
				model.selected = model.agents[model.cursor].Name
				model.selectedResume = true
				return model, tea.Quit
			}
		case key.Matches(typed, orcKeys.replay):
			if model.view == orcWorkflowsView && len(model.restartPoints) > 0 {
				if model.restartPoints[model.restartCursor].Kind == domain.RestartPointOrchestrationCheckpoint {
					model.message = "Checkpoint continuation is unavailable; choose a run or node point"
					model.messageError = true
					return model, nil
				}
				if !model.confirmReplay {
					model.confirmReplay = true
					model.message = "Press f again to fork from this snapshot; every node reruns"
					model.messageError = false
					return model, nil
				}
				model.confirmReplay = false
				return model, model.replaySelectedWorkflow()
			}
		case key.Matches(typed, orcKeys.open):
			switch model.view {
			case orcControllersView:
				if len(model.agents) > 0 {
					model.selected = model.agents[model.cursor].Name
					return model, tea.Quit
				}
			case orcWorkersView:
				if len(model.workers) > 0 {
					if !supportsWorkerAttachment(model.workers[model.workerCursor]) {
						model.message = "This worker has no interactive attachment"
						model.messageError = true
						return model, nil
					}
					model.selectedWorker = model.workers[model.workerCursor].ID
					return model, tea.Quit
				}
			}
		}
	}
	return model, nil
}

func (model orcUIModel) View() string {
	if model.width < 76 || model.height < 20 {
		return fmt.Sprintf("orc needs 76x20\nthis pane is %dx%d\nq quits", model.width, model.height)
	}
	contentWidth := model.width

	header := model.header(contentWidth)
	scope := model.scopeLine(contentWidth)
	navigation := model.navigation()
	body := model.agentView(contentWidth)
	switch model.view {
	case orcWorkflowsView:
		body = model.workflowView(contentWidth)
	case orcWorkersView:
		body = model.workerView(contentWidth)
	}

	before := []string{header, scope, navigation}
	after := make([]string, 0, 2)
	if model.message != "" {
		style := orcMessageStyle
		if model.messageError {
			style = orcErrorStyle
		}
		after = append(after, style.Render(ansi.Truncate(model.message, contentWidth, "…")))
	}
	after = append(after, model.helpView())
	separator := "\n\n"
	separatorHeight := 2
	if model.height <= 24 {
		separator = "\n"
		separatorHeight = 1
	}
	fixedHeight := separatorHeight * (len(before) + len(after))
	for _, part := range append(append([]string(nil), before...), after...) {
		fixedHeight += lipgloss.Height(part)
	}
	body = orcFitBlockHeight(body, max(3, model.height-fixedHeight))
	parts := append(before, body)
	parts = append(parts, after...)
	return strings.Join(parts, separator)
}

func (model orcUIModel) helpView() string {
	if !model.help.ShowAll || model.width > 90 {
		return model.help.View(model.helpKeys())
	}
	var lines []string
	switch model.view {
	case orcControllersView:
		lines = []string{"up/down select   enter open   R resume", "tab view   s broker   r refresh   ? less   q quit"}
	case orcWorkflowsView:
		lines = []string{"up/down run   h/l restart   pgup/pgdn graph   f fork", "tab view   s broker   r refresh   ? less   q quit"}
	case orcWorkersView:
		lines = []string{"up/down select   enter attach", "tab view   s broker   r refresh   ? less   q quit"}
	}
	for index := range lines {
		lines[index] = orcTagStyle.Render(ansi.Truncate(lines[index], model.width, "…"))
	}
	return strings.Join(lines, "\n")
}

func orcFitBlockHeight(value string, height int) string {
	lines := strings.Split(value, "\n")
	if len(lines) <= height {
		return value
	}
	visible := append([]string(nil), lines[:height-1]...)
	return strings.Join(append(visible, lines[len(lines)-1]), "\n")
}

func orcRefreshCommand() tea.Cmd {
	return tea.Tick(time.Second, func(now time.Time) tea.Msg { return orcRefreshTick(now) })
}

func (model *orcUIModel) beginRefresh(loadWorkerHistory bool, success string) tea.Cmd {
	if loadWorkerHistory {
		model.pendingWorkerHistory = true
	}
	if success != "" {
		model.pendingRefreshStatus = success
	}
	if model.refreshing {
		return nil
	}
	model.refreshing = true
	loadWorkerHistory = model.pendingWorkerHistory
	success = model.pendingRefreshStatus
	model.pendingWorkerHistory = false
	model.pendingRefreshStatus = ""
	snapshot := *model
	revision := model.refreshRevision
	return func() tea.Msg {
		err := snapshot.refreshState(loadWorkerHistory)
		return orcRefreshResult{model: snapshot, revision: revision, success: success, err: err}
	}
}

func (model *orcUIModel) applyRefresh(updated orcUIModel) {
	model.record = updated.record
	model.active = updated.active
	model.workflows = updated.workflows
	model.workflow = updated.workflow
	model.definition = updated.definition
	model.workflowCursor = updated.workflowCursor
	model.restartPoints = updated.restartPoints
	model.restartCursor = updated.restartCursor
	model.forks = updated.forks
	model.workers = updated.workers
	model.workerHistory = updated.workerHistory
	model.workerCursor = updated.workerCursor
	model.requestedWorkflow = updated.requestedWorkflow
}

func (model orcUIModel) helpKeys() orcHelpKeyMap {
	short := []key.Binding{orcKeys.switchView, orcKeys.refresh, orcKeys.showHelp, orcKeys.quit}
	full := [][]key.Binding{
		{orcKeys.up, orcKeys.down},
		{orcKeys.switchView, orcKeys.toggle, orcKeys.refresh, orcKeys.showHelp, orcKeys.quit},
	}
	switch model.view {
	case orcControllersView:
		short = []key.Binding{orcKeys.switchView, orcKeys.open, orcKeys.refresh, orcKeys.showHelp, orcKeys.quit}
		full = [][]key.Binding{
			{orcKeys.up, orcKeys.down, orcKeys.open, orcKeys.resume},
			{orcKeys.switchView, orcKeys.toggle, orcKeys.refresh, orcKeys.showHelp, orcKeys.quit},
		}
	case orcWorkflowsView:
		full = [][]key.Binding{
			{orcKeys.up, orcKeys.down, orcKeys.left, orcKeys.right},
			{orcKeys.pageUp, orcKeys.pageDown, orcKeys.replay},
			{orcKeys.switchView, orcKeys.toggle, orcKeys.refresh, orcKeys.showHelp, orcKeys.quit},
		}
	case orcWorkersView:
		short = []key.Binding{orcKeys.switchView, orcKeys.open, orcKeys.refresh, orcKeys.showHelp, orcKeys.quit}
		full = [][]key.Binding{
			{orcKeys.up, orcKeys.down, orcKeys.open},
			{orcKeys.switchView, orcKeys.toggle, orcKeys.refresh, orcKeys.showHelp, orcKeys.quit},
		}
	}
	return orcHelpKeyMap{orcKeyMap: orcKeys, short: short, full: full}
}

func (model orcUIModel) header(width int) string {
	status := orcInactiveStyle.Render("broker stopped")
	if model.active {
		status = orcActiveStyle.Render("broker running")
	}
	left := orcTitleStyle.Render("🫍 orc") + "  " + orcTagStyle.Render("local orchestrator")
	gap := width - lipgloss.Width(left) - lipgloss.Width(status)
	if gap < 1 {
		gap = 1
	}
	return left + strings.Repeat(" ", gap) + status
}

func (model orcUIModel) scopeLine(width int) string {
	scope := model.record.Scope
	if scope == "" {
		if current, err := os.Getwd(); err == nil {
			scope = current
		} else {
			scope = "."
		}
	}
	label := orcLabelStyle.Render("workspace ")
	return label + orcValueStyle.Render(ansi.Truncate(filepath.Clean(scope), width-lipgloss.Width(label), "…"))
}

func (model orcUIModel) navigation() string {
	agentsTab := fmt.Sprintf(" controllers %d ", len(model.agents))
	workflowsTab := fmt.Sprintf(" workflows %d ", len(model.workflows))
	workersTab := fmt.Sprintf(" workers %d ", len(model.workers))
	switch model.view {
	case orcControllersView:
		agentsTab = orcSelectedStyle.Render(agentsTab)
	case orcWorkflowsView:
		workflowsTab = orcSelectedStyle.Render(workflowsTab)
	case orcWorkersView:
		workersTab = orcSelectedStyle.Render(workersTab)
	}
	if model.view != orcControllersView {
		agentsTab = orcTagStyle.Render(agentsTab)
	}
	if model.view != orcWorkflowsView {
		workflowsTab = orcTagStyle.Render(workflowsTab)
	}
	if model.view != orcWorkersView {
		workersTab = orcTagStyle.Render(workersTab)
	}
	return agentsTab + "  " + workflowsTab + "  " + workersTab
}

func (model orcUIModel) agentView(width int) string {
	rows := model.visibleAgentRows()
	listWidth := 30
	list := orcBox("controllers", listWidth, strings.Join(rows, "\n"), model.view == orcControllersView)
	detailWidth := width - lipgloss.Width(list) - 4
	details := model.agentDetails(detailWidth)
	body := lipgloss.JoinHorizontal(lipgloss.Top, list, "  ", details)
	if width < 76 {
		list = orcBox("controllers", width-2, strings.Join(rows, "\n"), model.view == orcControllersView)
		details = model.agentDetails(width - 2)
		body = lipgloss.JoinVertical(lipgloss.Left, list, "", details)
	}
	return body
}

func (model orcUIModel) workflowView(width int) string {
	rows := model.visibleWorkflowRows()
	listWidth := 34
	list := orcBox("runs", listWidth, strings.Join(rows, "\n"), model.view == orcWorkflowsView)
	detailWidth := width - lipgloss.Width(list) - 4
	detailHeight := max(6, model.height-10)
	details := model.workflowDetails(detailWidth, detailHeight)
	body := lipgloss.JoinHorizontal(lipgloss.Top, list, "  ", details)
	if width < 76 {
		list = orcBox("runs", width-2, strings.Join(rows, "\n"), model.view == orcWorkflowsView)
		detailHeight = max(4, model.height-11-lipgloss.Height(list))
		details = model.workflowDetails(width-2, detailHeight)
		body = lipgloss.JoinVertical(lipgloss.Left, list, "", details)
	}
	return body
}

func (model orcUIModel) visibleWorkflowRows() []string {
	if len(model.workflows) == 0 {
		return []string{orcTagStyle.Render("No workflow runs")}
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
			row = orcSelectedStyle.Width(29).Render(">" + row)
		} else {
			row = orcValueStyle.Render(" " + row)
		}
		rows = append(rows, row)
	}
	return rows
}

func (model orcUIModel) workflowDetails(width int, height int) string {
	if width < 34 {
		width = 34
	}
	if len(model.workflows) == 0 {
		return orcBox("graph", width, "Planning and spec work appears here as dedicated workflow runs.", false)
	}
	lines := model.workflowDetailLines()
	limit := max(2, height-2)
	if len(lines) > limit {
		maximum := len(lines) - limit + 1
		offset := min(model.graphOffset, maximum)
		end := min(len(lines), offset+limit-1)
		visible := append([]string(nil), lines[offset:end]...)
		visible = append(visible, orcTagStyle.Render(fmt.Sprintf(
			"rows %d-%d/%d  pgup/pgdn scroll", offset+1, end, len(lines),
		)))
		lines = visible
	}
	for index, line := range lines {
		lines[index] = ansi.Truncate(line, width-6, "…")
	}
	return orcBox("graph", width, strings.Join(lines, "\n"), false)
}

func (model orcUIModel) workflowDetailLines() []string {
	lines := []string{
		orcTitleStyle.Render(string(model.workflow.Run.ID)),
		orcLabelStyle.Render("state    ") + orcValueStyle.Render(string(model.workflow.Run.State)),
		orcLabelStyle.Render("version  ") + orcValueStyle.Render(fmt.Sprintf("%d", model.workflow.Run.DefinitionVersion)),
	}
	if len(model.restartPoints) > 0 {
		point := model.restartPoints[model.restartCursor]
		lines = append(lines,
			orcLabelStyle.Render("restart  ")+orcValueStyle.Render(fmt.Sprintf(
				"%d/%d %s @ %d", model.restartCursor+1, len(model.restartPoints), point.Kind, point.EventCursor,
			)),
			orcTagStyle.Render("          h/l selects, f forks snapshot and reruns nodes"),
		)
	} else {
		lines = append(lines, orcLabelStyle.Render("restart  ")+orcInactiveStyle.Render("none"))
	}
	for _, fork := range model.forks {
		relation := "child " + string(fork.ChildWorkflowRunID)
		if fork.ChildWorkflowRunID == model.workflow.Run.ID {
			relation = "parent " + string(fork.ParentWorkflowRunID)
		}
		lines = append(lines, orcLabelStyle.Render("lineage  ")+orcValueStyle.Render(
			relation+" via "+string(fork.RestartPointID),
		))
	}
	lines = append(lines, "", orcLabelStyle.Render("nodes"))
	nodes := append([]domain.NodeRun(nil), model.workflow.Nodes...)
	sort.Slice(nodes, func(first int, second int) bool { return nodes[first].NodeKey < nodes[second].NodeKey })
	for _, node := range nodes {
		lines = append(lines, fmt.Sprintf("  %-18s [%s]", node.NodeKey, node.State))
	}
	if len(model.definition.Edges) > 0 {
		lines = append(lines, "", orcLabelStyle.Render("edges"))
		for _, edge := range model.definition.Edges {
			lines = append(lines, fmt.Sprintf("  %s.%s -> %s.%s", edge.From, edge.FromPort, edge.To, edge.ToPort))
		}
	}
	return lines
}

func (model orcUIModel) workerView(width int) string {
	rows := model.visibleWorkerRows()
	listWidth := 34
	list := orcBox("workers", listWidth, strings.Join(rows, "\n"), model.view == orcWorkersView)
	detailWidth := width - lipgloss.Width(list) - 4
	details := model.workerDetails(detailWidth)
	body := lipgloss.JoinHorizontal(lipgloss.Top, list, "  ", details)
	if width < 76 {
		list = orcBox("workers", width-2, strings.Join(rows, "\n"), model.view == orcWorkersView)
		details = model.workerDetails(width - 2)
		body = lipgloss.JoinVertical(lipgloss.Left, list, "", details)
	}
	return body
}

func (model orcUIModel) visibleWorkerRows() []string {
	if len(model.workers) == 0 {
		return []string{orcTagStyle.Render("No workflow workers")}
	}
	limit := model.visibleRowLimit()
	start, end := visibleRange(model.workerCursor, len(model.workers), limit)
	rows := make([]string, 0, end-start)
	for index := start; index < end; index++ {
		worker := model.workers[index]
		row := fmt.Sprintf(" %-19s %-9s", ansi.Truncate(string(worker.ID), 19, "…"), worker.State)
		if index == model.workerCursor {
			row = orcSelectedStyle.Width(29).Render(">" + row)
		} else {
			row = orcValueStyle.Render(" " + row)
		}
		rows = append(rows, row)
	}
	return rows
}

func (model orcUIModel) workerDetails(width int) string {
	if width < 34 {
		width = 34
	}
	if len(model.workers) == 0 {
		return orcBox("selected", width, "Workers appear after a workflow node starts an agent.", false)
	}
	worker := model.workers[model.workerCursor]
	action := "events only"
	if supportsWorkerAttachment(worker) {
		action = "enter attaches"
	}
	lines := []string{
		orcTitleStyle.Render(string(worker.ID)),
		orcLabelStyle.Render("state     ") + orcValueStyle.Render(string(worker.State)),
		orcLabelStyle.Render("workflow  ") + orcValueStyle.Render(string(worker.WorkflowRunID)),
		orcLabelStyle.Render("node      ") + orcValueStyle.Render(string(worker.NodeRunID)),
		orcLabelStyle.Render("runtime   ") + orcValueStyle.Render(worker.RuntimeAdapterID),
		orcLabelStyle.Render("events    ") + orcValueStyle.Render(fmt.Sprintf("%d", len(model.workerHistory.RuntimeEvents))),
		orcLabelStyle.Render("actions   ") + orcValueStyle.Render(action),
	}
	if len(model.workerHistory.RuntimeEvents) > 0 {
		lines = append(lines, "", orcLabelStyle.Render("recent events"))
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
	return orcBox("selected", width, strings.Join(lines, "\n"), false)
}

func (model orcUIModel) visibleRowLimit() int {
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

func (model orcUIModel) visibleAgentRows() []string {
	if len(model.agents) == 0 {
		return []string{orcTagStyle.Render("No installed controllers")}
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
			row = orcSelectedStyle.Width(25).Render(">" + row)
		} else {
			row = orcValueStyle.Render(" " + row)
		}
		rows = append(rows, row)
	}
	return rows
}

func (model orcUIModel) agentDetails(width int) string {
	if width < 28 {
		width = 28
	}
	if len(model.agents) == 0 {
		return orcBox("selected", width, "Install a controller to launch it here.", false)
	}
	agent := model.agents[model.cursor]
	label := agent.Label
	if label == "" {
		label = agent.Name
	}
	modelSupport := "uses command default"
	if agent.Launch.ModelFlag != "" {
		modelSupport = "accepts orc run --model"
	}
	mcp := "unavailable"
	if model.active {
		mcp = "available in this scope"
	}
	lines := []string{
		orcTitleStyle.Render(label),
		orcTagStyle.Render(agent.Name),
		"",
		orcLabelStyle.Render("command  ") + orcValueStyle.Render(agent.Command),
		orcLabelStyle.Render("model    ") + orcValueStyle.Render(modelSupport),
		orcLabelStyle.Render("mcp      ") + orcValueStyle.Render(mcp),
		orcLabelStyle.Render("new      ") + orcValueStyle.Render("enter"),
	}
	resume := "unavailable"
	if len(agent.Launch.ResumeArgs) > 0 {
		resume = "R, native conversation picker"
	}
	lines = append(lines, orcLabelStyle.Render("resume   ")+orcValueStyle.Render(resume))
	if model.active && model.record.PID > 0 {
		lines = append(lines, orcLabelStyle.Render("broker   ")+orcValueStyle.Render(fmt.Sprintf("pid %d", model.record.PID)))
	}
	return orcBox("selected", width, strings.Join(lines, "\n"), false)
}

func orcBox(name string, inner int, body string, focused bool) string {
	if inner < 1 {
		return body
	}
	edge := orcRuleStyle
	if focused {
		edge = orcTitleStyle
	}
	dashes := inner - 3 - lipgloss.Width(name)
	if dashes < 0 {
		dashes = 0
	}
	top := edge.Render("╭─ ") + orcTitleStyle.Render(name) + edge.Render(" "+strings.Repeat("─", dashes)+"╮")
	lines := []string{orcFit(top, inner+2)}
	for _, line := range strings.Split(body, "\n") {
		lines = append(lines, edge.Render("│")+orcFit(line, inner)+edge.Render("│"))
	}
	lines = append(lines, edge.Render("╰"+strings.Repeat("─", inner)+"╯"))
	return strings.Join(lines, "\n")
}

func orcFit(value string, width int) string {
	if width < 1 {
		return ""
	}
	value = ansi.Truncate(value, width, "…")
	if missing := width - ansi.StringWidth(value); missing > 0 {
		value += strings.Repeat(" ", missing)
	}
	return value
}

func (model *orcUIModel) refresh() error {
	return model.refreshState(true)
}

func (model *orcUIModel) refreshState(loadWorkerHistory bool) error {
	record, active, err := activeOrc("")
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
	switch model.view {
	case orcWorkflowsView:
		return model.loadWorkflows()
	case orcWorkersView:
		return model.loadWorkers(loadWorkerHistory)
	default:
		return nil
	}
}

func (model *orcUIModel) moveCursor(delta int) bool {
	if model.view == orcControllersView {
		next := model.cursor + delta
		if next >= 0 && next < len(model.agents) {
			model.cursor = next
			return true
		}
		return false
	}
	if model.view == orcWorkflowsView {
		next := model.workflowCursor + delta
		if next < 0 || next >= len(model.workflows) {
			return false
		}
		model.workflowCursor = next
		model.graphOffset = 0
		return true
	}
	next := model.workerCursor + delta
	if next < 0 || next >= len(model.workers) {
		return false
	}
	model.workerCursor = next
	return true
}

func (model *orcUIModel) loadWorkflows() error {
	selected := model.requestedWorkflow
	if selected == "" && model.workflowCursor >= 0 && model.workflowCursor < len(model.workflows) {
		selected = model.workflows[model.workflowCursor].ID
	}
	result, err := executeNativeQuery(model.record.StateDirectory, "workflow.list", json.RawMessage(`{}`))
	if err != nil {
		return err
	}
	if err := json.Unmarshal(result, &model.workflows); err != nil {
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
	if selected != "" {
		for index := range model.workflows {
			if model.workflows[index].ID == selected {
				model.workflowCursor = index
				model.requestedWorkflow = ""
				break
			}
		}
	}
	if model.workflowCursor >= len(model.workflows) {
		model.workflowCursor = len(model.workflows) - 1
	}
	return model.loadSelectedWorkflow()
}

func (model *orcUIModel) loadSelectedWorkflow() error {
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

func (model *orcUIModel) loadRestartPoints() error {
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
	var selected domain.RestartPointID
	if model.restartCursor >= 0 && model.restartCursor < len(model.restartPoints) {
		selected = model.restartPoints[model.restartCursor].ID
	}
	result, err := executeNativeQuery(model.record.StateDirectory, "workflow.restart-points", payload)
	if err != nil {
		return err
	}
	if err := json.Unmarshal(result, &model.restartPoints); err != nil {
		return err
	}
	model.restartCursor = restartPointCursor(model.restartPoints, selected)
	return nil
}

func restartPointCursor(points []domain.RestartPoint, selected domain.RestartPointID) int {
	for index := range points {
		if selected != "" && points[index].ID == selected {
			return index
		}
	}
	return 0
}

func (model *orcUIModel) loadWorkflowForks() error {
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
	result, err := executeNativeQuery(model.record.StateDirectory, "workflow.forks", payload)
	if err != nil {
		return err
	}
	return json.Unmarshal(result, &model.forks)
}

func (model *orcUIModel) loadWorkers(loadHistory bool) error {
	var selected domain.SessionID
	if model.workerCursor >= 0 && model.workerCursor < len(model.workers) {
		selected = model.workers[model.workerCursor].ID
	}
	result, err := executeNativeQuery(model.record.StateDirectory, "agent.list", json.RawMessage(`{}`))
	if err != nil {
		return err
	}
	if err := json.Unmarshal(result, &model.workers); err != nil {
		return err
	}
	if len(model.workers) == 0 {
		model.workerCursor = 0
		model.workerHistory = sqlite.SessionHistory{}
		return nil
	}
	if selected != "" {
		for index := range model.workers {
			if model.workers[index].ID == selected {
				model.workerCursor = index
				break
			}
		}
	}
	if model.workerCursor >= len(model.workers) {
		model.workerCursor = len(model.workers) - 1
	}
	if !loadHistory {
		return nil
	}
	return model.loadSelectedWorker()
}

func (model *orcUIModel) loadSelectedWorker() error {
	if len(model.workers) == 0 {
		return nil
	}
	payload, err := json.Marshal(struct {
		SessionID domain.SessionID `json:"sessionId"`
	}{SessionID: model.workers[model.workerCursor].ID})
	if err != nil {
		return err
	}
	result, err := executeNativeQuery(model.record.StateDirectory, "agent.history", payload)
	if err != nil {
		return err
	}
	return json.Unmarshal(result, &model.workerHistory)
}

func (model *orcUIModel) moveRestartPoint(delta int) {
	if model.view != orcWorkflowsView || len(model.restartPoints) == 0 {
		return
	}
	next := model.restartCursor + delta
	if next >= 0 && next < len(model.restartPoints) {
		model.restartCursor = next
	}
}

func (model *orcUIModel) scrollGraph(direction int) {
	if model.view != orcWorkflowsView || len(model.workflows) == 0 {
		return
	}
	limit := max(2, max(6, model.height-10)-2)
	page := max(1, limit-1)
	maximum := max(0, len(model.workflowDetailLines())-limit+1)
	model.graphOffset = min(max(0, model.graphOffset+direction*page), maximum)
}

func (model orcUIModel) replaySelectedWorkflow() tea.Cmd {
	run := model.workflows[model.workflowCursor]
	point := model.restartPoints[model.restartCursor]
	return func() tea.Msg {
		identifier, err := localCommandID()
		if err != nil {
			return orcActionMessage{err: err}
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
		}{
			ID: domain.RunForkID("fork-" + identifier), ParentWorkflowRunID: run.ID,
			ChildWorkflowRunID: childID, RestartPointID: point.ID,
			TargetDefinitionID: run.WorkflowDefinition, TargetDefinitionVersion: run.DefinitionVersion,
			ExpectedParentVersion: run.Metadata.ResourceVersion,
		})
		if err != nil {
			return orcActionMessage{err: err}
		}
		if _, err := executeNativeCommand(model.record.StateDirectory, "workflow.replay", payload); err != nil {
			return orcActionMessage{err: err}
		}
		return orcActionMessage{text: "Forked " + string(childID), workflowID: childID}
	}
}

type orcWorkerTick time.Time

type orcWorkerActionMessage struct {
	text string
	err  error
}

type orcWorkerEventsMessage struct {
	events []domain.RuntimeEvent
	state  *domain.SessionState
	cursor domain.EventCursor
	err    error
}

type orcWorkerUIModel struct {
	record       instance.Record
	history      sqlite.SessionHistory
	attachmentID string
	input        textinput.Model
	typing       bool
	message      string
	messageError bool
	width        int
	height       int
	eventCursor  domain.EventCursor
}

func runOrcWorkerUI(
	record instance.Record,
	sessionID domain.SessionID,
	stdout io.Writer,
	stderr io.Writer,
) int {
	lipgloss.SetColorProfile(termenv.ANSI)
	lipgloss.SetHasDarkBackground(true)
	eventCursor, err := latestBrokerEventCursor(record.StateDirectory)
	if err != nil {
		fmt.Fprintf(stderr, "read broker cursor: %v\n", err)
		return 1
	}
	history, err := loadWorkerHistory(record.StateDirectory, sessionID)
	if err != nil {
		fmt.Fprintf(stderr, "read worker: %v\n", err)
		return 1
	}
	if !supportsWorkerAttachment(history.Session) {
		fmt.Fprintf(stderr, "worker %s has no interactive attachment\n", sessionID)
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
	input.TextStyle = orcValueStyle
	input.PromptStyle = orcSelectedStyle
	model := orcWorkerUIModel{
		record: record, history: history, attachmentID: attachmentID,
		input: input, width: 92, height: 26, eventCursor: eventCursor,
	}
	program := tea.NewProgram(model, tea.WithInput(os.Stdin), tea.WithOutput(stdout), tea.WithAltScreen())
	if _, err := program.Run(); err != nil {
		fmt.Fprintf(stderr, "run worker UI: %v\n", err)
		return 1
	}
	return 0
}

func supportsWorkerAttachment(session domain.Session) bool {
	if session.State != domain.SessionStateRunning && session.State != domain.SessionStateWaiting {
		return false
	}
	for _, capability := range session.Capabilities {
		if capability == "native-attachment" {
			return true
		}
	}
	return false
}

func (model orcWorkerUIModel) Init() tea.Cmd {
	return workerRefreshTick()
}

func (model orcWorkerUIModel) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch typed := message.(type) {
	case orcWorkerTick:
		return model, tea.Batch(model.readEvents(), workerRefreshTick())
	case orcWorkerEventsMessage:
		if typed.err != nil {
			model.message = typed.err.Error()
			model.messageError = true
			break
		}
		model.eventCursor = typed.cursor
		if typed.state != nil {
			model.history.Session.State = *typed.state
		}
		for _, event := range typed.events {
			if event.Sequence > model.history.Session.RuntimeEventCursor {
				model.history.RuntimeEvents = append(model.history.RuntimeEvents, event)
				model.history.Session.RuntimeEventCursor = event.Sequence
			}
		}
	case orcWorkerActionMessage:
		model.messageError = typed.err != nil
		model.typing = false
		model.input.Blur()
		if typed.err != nil {
			model.message = typed.err.Error()
		} else {
			model.message = typed.text
			model.input.SetValue("")
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
				model.typing = false
				model.input.Blur()
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

func (model orcWorkerUIModel) View() string {
	if model.width < 60 || model.height < 16 {
		return fmt.Sprintf("orc needs 60x16\nthis pane is %dx%d\nq detaches", model.width, model.height)
	}
	session := model.history.Session
	statusStyle := orcInactiveStyle
	switch session.State {
	case domain.SessionStateStarting, domain.SessionStateRunning, domain.SessionStateWaiting:
		statusStyle = orcActiveStyle
	case domain.SessionStateFailed, domain.SessionStateCancelled, domain.SessionStateOrphaned:
		statusStyle = orcErrorStyle
	}
	status := statusStyle.Render(string(session.State))
	left := orcTitleStyle.Render("🫍 orc") + "  " + orcTagStyle.Render("worker attachment")
	gap := model.width - lipgloss.Width(left) - lipgloss.Width(status)
	if gap < 1 {
		gap = 1
	}
	header := left + strings.Repeat(" ", gap) + status
	scopeLabel := orcLabelStyle.Render("workspace ")
	scope := scopeLabel + orcValueStyle.Render(ansi.Truncate(model.record.Scope, model.width-lipgloss.Width(scopeLabel), "…"))
	identity := fmt.Sprintf(
		"%s  %s  %s", session.ID, session.WorkflowRunID, session.NodeRunID,
	)
	footer := orcTagStyle.Render("i input   r refresh   q detach")
	before := []string{header, scope, orcValueStyle.Render(ansi.Truncate(identity, model.width, "…"))}
	after := make([]string, 0, 2)
	if model.typing {
		after = append(after, model.input.View()+"  "+orcTagStyle.Render("enter send   esc cancel"))
	} else if model.message != "" {
		style := orcMessageStyle
		if model.messageError {
			style = orcErrorStyle
		}
		after = append(after, style.Render(ansi.Truncate(model.message, model.width, "…")))
	}
	after = append(after, footer)
	separator := "\n\n"
	separatorHeight := 2
	if model.height <= 24 {
		separator = "\n"
		separatorHeight = 1
	}
	fixedHeight := separatorHeight * (len(before) + len(after))
	for _, part := range append(append([]string(nil), before...), after...) {
		fixedHeight += lipgloss.Height(part)
	}
	lines := model.workerEventLines()
	bodyHeight := max(3, model.height-fixedHeight)
	if len(lines) > bodyHeight-2 {
		lines = lines[len(lines)-(bodyHeight-2):]
	}
	body := orcBox("events", model.width-2, strings.Join(lines, "\n"), true)
	parts := append(before, body)
	parts = append(parts, after...)
	return strings.Join(parts, separator)
}

func (model orcWorkerUIModel) workerEventLines() []string {
	if len(model.history.RuntimeEvents) == 0 {
		return []string{orcTagStyle.Render("Waiting for worker events")}
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

func (model orcWorkerUIModel) sendMessage(message string) tea.Cmd {
	session := model.history.Session
	stateDirectory := model.record.StateDirectory
	return func() tea.Msg {
		if err := sendWorkerMessage(stateDirectory, session, message); err != nil {
			return orcWorkerActionMessage{err: err}
		}
		return orcWorkerActionMessage{text: "Message accepted"}
	}
}

func (model orcWorkerUIModel) readEvents() tea.Cmd {
	return func() tea.Msg {
		events, state, cursor, err := readWorkerEvents(
			model.record.Socket, model.eventCursor, model.history.Session.ID,
		)
		return orcWorkerEventsMessage{events: events, state: state, cursor: cursor, err: err}
	}
}

func workerRefreshTick() tea.Cmd {
	return tea.Tick(time.Second, func(now time.Time) tea.Msg { return orcWorkerTick(now) })
}

func loadWorkerHistory(stateDirectory string, sessionID domain.SessionID) (sqlite.SessionHistory, error) {
	paths, err := config.ResolvePaths(stateDirectory)
	if err != nil {
		return sqlite.SessionHistory{}, err
	}
	store, err := sqlite.OpenReadOnly(context.Background(), paths.Database)
	if err != nil {
		return sqlite.SessionHistory{}, err
	}
	defer store.Close()
	return store.SessionHistory(context.Background(), sessionID)
}

func latestBrokerEventCursor(stateDirectory string) (domain.EventCursor, error) {
	paths, err := config.ResolvePaths(stateDirectory)
	if err != nil {
		return 0, err
	}
	store, err := sqlite.OpenReadOnly(context.Background(), paths.Database)
	if err != nil {
		return 0, err
	}
	defer store.Close()
	inspection, err := store.Inspect(context.Background())
	return inspection.LastEventCursor, err
}

func readWorkerEvents(
	socketPath string,
	after domain.EventCursor,
	sessionID domain.SessionID,
) ([]domain.RuntimeEvent, *domain.SessionState, domain.EventCursor, error) {
	client, err := socket.NewClient(socketPath)
	if err != nil {
		return nil, nil, after, err
	}
	defer client.Close()
	envelopes, err := client.Events(context.Background(), after, 1000)
	if err != nil {
		return nil, nil, after, err
	}
	return filterWorkerEvents(envelopes, after, sessionID)
}

func filterWorkerEvents(
	envelopes []domain.EventEnvelope,
	after domain.EventCursor,
	sessionID domain.SessionID,
) ([]domain.RuntimeEvent, *domain.SessionState, domain.EventCursor, error) {
	cursor := after
	var runtimeEvents []domain.RuntimeEvent
	var state *domain.SessionState
	for _, envelope := range envelopes {
		cursor = envelope.Cursor
		if envelope.Aggregate.Kind != "session" || envelope.Aggregate.ID != string(sessionID) {
			continue
		}
		switch envelope.Type {
		case "session.runtime.event":
			var event domain.RuntimeEvent
			if err := json.Unmarshal(envelope.Payload, &event); err != nil {
				return nil, nil, after, err
			}
			runtimeEvents = append(runtimeEvents, event)
		case "session.state.changed":
			var changed struct {
				State domain.SessionState `json:"state"`
			}
			if err := json.Unmarshal(envelope.Payload, &changed); err != nil {
				return nil, nil, after, err
			}
			state = &changed.State
		}
	}
	return runtimeEvents, state, cursor, nil
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
			Kind: kind, Payload: input, Source: "orc-ui",
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
			Kind: domain.InterventionKindMessage, Payload: input, Source: "orc-ui",
		},
		Operation: plugin.OperationEnvelope{
			ID: domain.OperationID("operation-" + identifier), AdapterID: session.RuntimeAdapterID,
			Port: domain.AdapterPortAgentRuntime, Operation: "agent-runtime.input",
			HandleID: session.RuntimeHandle, Input: input, Deadline: time.Now().Add(time.Minute),
		},
	}, nil
}
