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
	up       key.Binding
	down     key.Binding
	left     key.Binding
	right    key.Binding
	toggle   key.Binding
	open     key.Binding
	resume   key.Binding
	replay   key.Binding
	pageUp   key.Binding
	pageDown key.Binding
	refresh  key.Binding
	showHelp key.Binding
	quit     key.Binding
}

func (keys orcKeyMap) ShortHelp() []key.Binding {
	return []key.Binding{keys.open, keys.refresh, keys.showHelp, keys.quit}
}

func (keys orcKeyMap) FullHelp() [][]key.Binding {
	return [][]key.Binding{
		{keys.up, keys.down, keys.left, keys.right},
		{keys.pageUp, keys.pageDown, keys.open, keys.resume, keys.replay},
		{keys.toggle},
		{keys.refresh, keys.showHelp, keys.quit},
	}
}

var orcKeys = orcKeyMap{
	up:       key.NewBinding(key.WithKeys("up", "k"), key.WithHelp("up/k", "previous")),
	down:     key.NewBinding(key.WithKeys("down", "j"), key.WithHelp("down/j", "next")),
	left:     key.NewBinding(key.WithKeys("left", "h"), key.WithHelp("left/h", "previous restart point")),
	right:    key.NewBinding(key.WithKeys("right", "l"), key.WithHelp("right/l", "next restart point")),
	toggle:   key.NewBinding(key.WithKeys("s"), key.WithHelp("s", "start or stop")),
	open:     key.NewBinding(key.WithKeys("enter"), key.WithHelp("enter", "attach")),
	resume:   key.NewBinding(key.WithKeys("R"), key.WithHelp("R", "resume session")),
	replay:   key.NewBinding(key.WithKeys("f"), key.WithHelp("f", "fork from restart point")),
	pageUp:   key.NewBinding(key.WithKeys("pgup", "ctrl+u"), key.WithHelp("pgup/^u", "graph up")),
	pageDown: key.NewBinding(key.WithKeys("pgdown", "ctrl+d"), key.WithHelp("pgdn/^d", "graph down")),
	refresh:  key.NewBinding(key.WithKeys("r"), key.WithHelp("r", "refresh")),
	showHelp: key.NewBinding(key.WithKeys("?"), key.WithHelp("?", "more keys")),
	quit:     key.NewBinding(key.WithKeys("q", "ctrl+c"), key.WithHelp("q", "quit")),
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
	helpOffset           int
	view                 int
	workflows            []domain.WorkflowRun
	workflow             workflowViewResult
	definition           workflowmodel.Definition
	workflowCursor       int
	nodeCursor           int
	selectedNodeID       domain.NodeRunID
	workflowRootSelected bool
	restartPoints        []domain.RestartPoint
	restartCursor        int
	forks                []domain.RunFork
	workers              []domain.Session
	workerCursor         int
	confirmReplay        bool
	graphOffset          int
	refreshing           bool
	refreshRevision      uint64
	requestedWorkflow    domain.WorkflowRunID
	pendingRefreshStatus string
	sessions             []instance.Session
	sessionCursor        int
	focus                int
	leader               bool
	controllerPicker     bool
	graphMode            bool
	pendingTop           bool
	inspectorHidden      bool
	inspectorOffset      int
	explorer             bool
	filter               textinput.Model
	filtering            bool
	query                string
	openSession          string
}

const (
	orcSessionsView = iota
	orcWorkflowsView
)

const (
	orcGraphFocus = iota
	orcDetailFocus
	orcExplorerFocus
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
	filter := textinput.New()
	filter.Prompt = "/"
	filter.CharLimit = 80
	model := orcUIModel{help: help.New(), filter: filter, width: 92, height: 26, view: orcSessionsView}
	resizeTextInput(&model.filter, orcFilterInputWidth(model.width))
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
	return model, nil
}

func (model orcUIModel) Init() tea.Cmd {
	return orcRefreshCommand()
}

func (model orcUIModel) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch typed := message.(type) {
	case orcRefreshTick:
		refresh := model.beginRefresh("")
		return model, tea.Batch(refresh, orcRefreshCommand())
	case orcRefreshResult:
		model.refreshing = false
		if typed.err != nil && typed.revision == model.refreshRevision {
			model.message = typed.err.Error()
			model.messageError = true
		} else if typed.revision == model.refreshRevision {
			model.applyRefresh(typed.model)
			if typed.success != "" {
				model.message = typed.success
				model.messageError = false
			}
		}
		if typed.revision != model.refreshRevision || model.pendingRefreshStatus != "" {
			return model, model.beginRefresh("")
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
		return model, model.beginRefresh("")
	case tea.WindowSizeMsg:
		model.width = typed.Width
		model.height = typed.Height
		resizeTextInput(&model.filter, orcFilterInputWidth(model.width))
		model.help.Width = typed.Width
		if !model.usesWideLayout() {
			model.focus = orcGraphFocus
			model.inspectorOffset = 0
		}
	case tea.KeyMsg:
		pressed := typed.String()
		if model.filtering {
			switch pressed {
			case "esc":
				model.filtering = false
				model.filter.SetValue(model.query)
				return model, nil
			case "enter":
				model.filtering = false
				model.query = strings.TrimSpace(model.filter.Value())
				if model.view == orcWorkflowsView {
					model.setNodeCursor(0)
					model.inspectorOffset = 0
					model.refreshRevision++
					return model, model.beginRefresh("")
				}
				model.moveToStart()
				return model, nil
			}
			var command tea.Cmd
			model.filter, command = model.filter.Update(typed)
			return model, command
		}
		if model.help.ShowAll {
			switch {
			case pressed == "?" || pressed == "esc" || pressed == "q":
				model.help.ShowAll = false
			case key.Matches(typed, orcKeys.up):
				model.helpOffset = max(0, model.helpOffset-1)
			case key.Matches(typed, orcKeys.down):
				model.helpOffset = min(model.maxHelpOffset(), model.helpOffset+1)
			case key.Matches(typed, orcKeys.pageUp):
				model.helpOffset = max(0, model.helpOffset-max(1, model.height/2))
			case key.Matches(typed, orcKeys.pageDown):
				model.helpOffset = min(model.maxHelpOffset(), model.helpOffset+max(1, model.height/2))
			}
			return model, nil
		}
		if model.controllerPicker {
			switch {
			case pressed == "esc" || pressed == "q":
				model.controllerPicker = false
			case key.Matches(typed, orcKeys.up):
				if len(model.agents) > 0 {
					model.cursor = max(0, model.cursor-1)
				}
			case key.Matches(typed, orcKeys.down):
				if len(model.agents) > 0 {
					model.cursor = min(len(model.agents)-1, model.cursor+1)
				}
			case pressed == "R":
				if len(model.agents) > 0 && len(model.agents[model.cursor].Launch.ResumeArgs) > 0 {
					model.selected = model.agents[model.cursor].Name
					model.selectedResume = true
					return model, tea.Quit
				}
			case pressed == "enter":
				if len(model.agents) > 0 {
					model.selected = model.agents[model.cursor].Name
					return model, tea.Quit
				}
			}
			return model, nil
		}
		if model.openSession != "" {
			session, found := model.sessionByID(model.openSession)
			switch pressed {
			case "y":
				model.openSession = ""
				if !found {
					model.message = "This session is no longer available"
					model.messageError = true
					return model, nil
				}
				model.message = "Opening " + model.sessionOpenLabel(session) + " in a right split"
				model.messageError = false
				return model, model.openSessionSplit(session)
			case "n", "esc", "enter", "q":
				model.openSession = ""
				model.message = "Open cancelled"
				model.messageError = false
			}
			return model, nil
		}
		if model.leader {
			model.leader = false
			switch pressed {
			case "v":
				if model.view == orcWorkflowsView {
					model.view = orcSessionsView
				} else {
					model.view = orcWorkflowsView
				}
				model.refreshRevision++
				return model, model.beginRefresh("")
			case "g":
				if model.view == orcWorkflowsView {
					model.graphMode = !model.graphMode
					if model.graphMode {
						model.selectWorkflowRoot()
					}
				}
				return model, nil
			case "e":
				model.explorer = !model.explorer
				if model.explorer && !model.usesWideLayout() && model.width >= 44 {
					model.focus = orcExplorerFocus
				} else if !model.explorer && model.focus == orcExplorerFocus {
					model.focus = orcGraphFocus
				}
				return model, nil
			case "n":
				model.controllerPicker = true
				return model, nil
			case "i":
				model.inspectorHidden = !model.inspectorHidden
				if model.inspectorHidden {
					model.focus = 0
					model.inspectorOffset = 0
				}
				return model, nil
			case "t":
				if session, found := model.selectedTrace(); found {
					id := firstValue(session.TraceSessionID, session.NativeSessionID)
					if id == "" {
						model.message = "This session has no Traces session ID"
						model.messageError = true
						return model, nil
					}
					command := exec.Command("traces", "--session", id)
					return model, tea.ExecProcess(command, func(err error) tea.Msg {
						if err != nil {
							return orcActionMessage{err: fmt.Errorf("open Traces: %w", err)}
						}
						return orcActionMessage{text: "Returned from Traces"}
					})
				}
			case "r":
				if session, found := model.selectedSession(); found && session.Registration == "observed" {
					return model, func() tea.Msg {
						registered, err := instance.RegisterSession(model.record, instance.SessionRegistration{
							ID: session.ID, Harness: session.Harness, Directory: session.Directory, Pane: session.Pane, Mux: session.Mux,
							PID: session.PID, ProcessIdentity: session.ProcessIdentity,
							Status: session.Status, Reason: session.Reason, Registration: "injected",
							Capabilities: session.Capabilities,
						})
						if err != nil {
							return orcActionMessage{err: err}
						}
						return orcActionMessage{text: "Connected " + registered.ID}
					}
				}
			case "x":
				if session, found := model.selectedSession(); found && canDisconnectOrcSession(session) {
					return model, func() tea.Msg {
						if err := instance.RemoveSession(model.record, session.ID); err != nil {
							return orcActionMessage{err: err}
						}
						return orcActionMessage{text: "Disconnected " + session.ID + "; the harness continues independently"}
					}
				}
			case "b":
				active := model.active
				return model, func() tea.Msg {
					var stdout, stderr bytes.Buffer
					code := runOrcStart(nil, &stdout, &stderr)
					if active {
						code = runOrcStop(nil, &stdout, &stderr)
					}
					if code != 0 {
						return orcActionMessage{err: errors.New(strings.TrimSpace(stderr.String()))}
					}
					return orcActionMessage{text: strings.TrimSpace(stdout.String())}
				}
			}
			return model, nil
		}
		if pressed == " " {
			model.leader = true
			return model, nil
		}
		if pressed == "/" {
			resizeTextInput(&model.filter, orcFilterInputWidth(model.width))
			model.filtering = true
			model.filter.SetValue(model.query)
			model.filter.CursorEnd()
			return model, model.filter.Focus()
		}
		if pressed == "ctrl+h" {
			if model.explorer && (model.usesWideLayout() || model.width >= 44) {
				model.focus = orcExplorerFocus
			}
			return model, nil
		}
		if pressed == "ctrl+l" {
			model.focus = orcGraphFocus
			return model, nil
		}
		if pressed == "ctrl+j" {
			if !model.inspectorHidden && model.usesWideLayout() {
				model.focus = orcDetailFocus
			}
			return model, nil
		}
		if pressed == "ctrl+k" {
			model.focus = orcGraphFocus
			return model, nil
		}
		if model.focus == orcDetailFocus && key.Matches(typed, orcKeys.up) {
			model.inspectorOffset = max(0, model.inspectorOffset-1)
			return model, nil
		}
		if model.focus == orcDetailFocus && key.Matches(typed, orcKeys.down) {
			model.inspectorOffset = min(model.maxInspectorOffset(), model.inspectorOffset+1)
			return model, nil
		}
		if key.Matches(typed, orcKeys.pageUp) && (model.focus == orcDetailFocus || model.view == orcSessionsView) {
			if model.focus == orcDetailFocus {
				model.inspectorOffset = max(0, model.inspectorOffset-max(1, model.height/4))
			} else {
				indices := model.matchingSessionIndices()
				position := max(0, indexPosition(indices, model.sessionCursor)-max(1, model.height/3))
				if len(indices) > 0 {
					model.sessionCursor = indices[position]
				}
				model.refreshRevision++
			}
			return model, nil
		}
		if key.Matches(typed, orcKeys.pageDown) && (model.focus == orcDetailFocus || model.view == orcSessionsView) {
			if model.focus == orcDetailFocus {
				model.inspectorOffset = min(model.maxInspectorOffset(),
					model.inspectorOffset+max(1, model.height/4))
			} else {
				indices := model.matchingSessionIndices()
				position := min(max(0, len(indices)-1), indexPosition(indices, model.sessionCursor)+max(1, model.height/3))
				if len(indices) > 0 {
					model.sessionCursor = indices[position]
				}
				model.refreshRevision++
			}
			return model, nil
		}
		if pressed == "G" {
			model.moveToEnd()
			model.refreshRevision++
			return model, model.beginRefresh("")
		}
		if pressed == "g" {
			if model.pendingTop {
				model.moveToStart()
				model.pendingTop = false
				model.refreshRevision++
				return model, model.beginRefresh("")
			}
			model.pendingTop = true
			return model, nil
		}
		model.pendingTop = false
		if !key.Matches(typed, orcKeys.replay) {
			model.confirmReplay = false
		}
		switch {
		case key.Matches(typed, orcKeys.quit):
			return model, tea.Quit
		case key.Matches(typed, orcKeys.up):
			if model.moveCursor(-1) {
				model.refreshRevision++
				return model, model.beginRefresh("")
			}
		case key.Matches(typed, orcKeys.down):
			if model.moveCursor(1) {
				model.refreshRevision++
				return model, model.beginRefresh("")
			}
		case key.Matches(typed, orcKeys.left):
			model.moveRestartPoint(-1)
		case key.Matches(typed, orcKeys.right):
			model.moveRestartPoint(1)
		case key.Matches(typed, orcKeys.pageUp):
			if model.view == orcWorkflowsView && model.graphMode {
				model.moveWorkflowGraphCursor(-max(1, model.height/3))
				model.graphOffset = model.nodeCursor
			} else if model.view == orcWorkflowsView && model.moveWorkflowPage(-max(1, model.height/3)) {
				model.refreshRevision++
				return model, model.beginRefresh("")
			} else {
				model.scrollGraph(-1)
			}
		case key.Matches(typed, orcKeys.pageDown):
			if model.view == orcWorkflowsView && model.graphMode {
				model.moveWorkflowGraphCursor(max(1, model.height/3))
				model.graphOffset = model.nodeCursor
			} else if model.view == orcWorkflowsView && model.moveWorkflowPage(max(1, model.height/3)) {
				model.refreshRevision++
				return model, model.beginRefresh("")
			} else {
				model.scrollGraph(1)
			}
		case key.Matches(typed, orcKeys.showHelp):
			model.help.ShowAll = !model.help.ShowAll
			model.helpOffset = 0
		case key.Matches(typed, orcKeys.refresh):
			return model, model.beginRefresh("Status refreshed")
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
		case key.Matches(typed, orcKeys.replay):
			if model.view == orcWorkflowsView && model.workflowLoaded() && len(model.restartPoints) > 0 {
				if _, found := model.selectedWorkflow(); !found {
					return model, nil
				}
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
			return model.attachSelected()
		}
	}
	return model, nil
}

func (model orcUIModel) View() string {
	if model.width < 40 || model.height < 10 {
		return fmt.Sprintf("orc needs 40x10\nthis pane is %dx%d\nq quits", model.width, model.height)
	}
	if model.controllerPicker {
		return model.controllerPickerView()
	}
	if model.help.ShowAll {
		return model.fullHelpView()
	}
	header := model.header(model.width)
	footer := model.bottomFooter()
	if model.filtering {
		controls := orcTagStyle.Render("  enter apply  esc cancel")
		filter := model.filter
		fieldWidth := orcFilterFieldWidth(model.width)
		filter.Width = orcFilterInputWidth(model.width)
		footer = orcSelectedStyle.Render(ansi.Truncate(filter.View(), fieldWidth, "…")) + controls
	}
	footer = ansi.Truncate(footer, model.width, "")
	workspaceHeight := model.height - 2
	graphHeight := workspaceHeight
	detailHeight := 0
	wide := model.usesWideLayout()
	if wide && !model.inspectorHidden {
		detailHeight = min(12, max(6, workspaceHeight/3))
		graphHeight = workspaceHeight - detailHeight
	}
	rightWidth := model.width
	explorerWidth := 0
	showExplorer := wide && model.explorer
	if showExplorer {
		explorerWidth = min(36, max(24, model.width*28/100))
		rightWidth = model.width - explorerWidth
	}
	graphTitle := model.resourceTitle()
	graphBody := model.resourceBody(graphHeight - 2)
	graphFocused := model.focus == orcGraphFocus
	if !wide && model.explorer && model.focus == orcExplorerFocus && model.width >= 44 {
		graphTitle = "explorer"
		graphBody = model.explorerBody(graphHeight - 2)
		graphFocused = true
	}
	if !wide && model.width < 72 && model.message != "" {
		graphBody = model.compactBodyWithMessage(graphBody, rightWidth-2, graphHeight-2)
	}
	graph := orcPanel(graphTitle, rightWidth, graphHeight, graphBody, graphFocused)
	right := graph
	if detailHeight > 0 {
		details := orcPanel("details", rightWidth, detailHeight,
			model.inspectorBody(detailHeight-2), model.focus == orcDetailFocus)
		right = graph + "\n" + details
	}
	workspace := right
	if showExplorer {
		explorer := orcPanel("explorer", explorerWidth, workspaceHeight,
			model.explorerBody(workspaceHeight-2), model.focus == orcExplorerFocus)
		workspace = lipgloss.JoinHorizontal(lipgloss.Top, explorer, right)
	}
	parts := []string{header, workspace}
	parts = append(parts, footer)
	return strings.Join(parts, "\n")
}

func orcFilterInputWidth(width int) int {
	return max(1, orcFilterFieldWidth(width)-ansi.StringWidth("/")-1)
}

func orcFilterFieldWidth(width int) int {
	return max(1, width-ansi.StringWidth("  enter apply  esc cancel"))
}

func resizeTextInput(input *textinput.Model, width int) {
	position := input.Position()
	input.Width = max(1, width)
	input.SetCursor(position)
}

func (model orcUIModel) resourceTitle() string {
	if model.view == orcWorkflowsView {
		mode := "list"
		if model.graphMode {
			mode = "graph"
		}
		title := fmt.Sprintf("workflows %d  %s", len(model.workflows), mode)
		if model.query != "" {
			title += "  " + orcTagStyle.Render("filter "+model.query)
		}
		return title
	}
	title := fmt.Sprintf("graph  %d sessions", len(model.sessions))
	if model.query != "" {
		title += "  " + orcTagStyle.Render("filter "+model.query)
	}
	return title
}

func (model orcUIModel) resourceBody(height int) string {
	if model.view == orcWorkflowsView {
		indices := model.matchingWorkflowIndices()
		if len(indices) == 0 {
			return orcTagStyle.Render("No workflow runs")
		}
		if model.graphMode {
			if _, found := model.selectedWorkflow(); !found {
				return orcTagStyle.Render("No workflow run matches this filter")
			}
			if !model.workflowLoaded() {
				return orcTagStyle.Render("Loading workflow graph…")
			}
			return strings.Join(model.fitLines(model.workflowGraphLines(height), height), "\n")
		}
		position := indexPosition(indices, model.workflowCursor)
		start, end := visibleRange(position, len(indices), max(1, height-1))
		rows := []string{orcLabelStyle.Render("  state       workflow                    updated")}
		for rowIndex := start; rowIndex < end; rowIndex++ {
			index := indices[rowIndex]
			run := model.workflows[index]
			row := fmt.Sprintf("  %-11s %-27s %s", run.State, ansi.Truncate(string(run.ID), 27, "…"),
				relativeTime(run.Metadata.UpdatedAt))
			rows = append(rows, model.selectedRow(row, index == model.workflowCursor))
		}
		return strings.Join(model.fitLines(rows, height), "\n")
	}
	return strings.Join(model.fitLines(model.sessionGraphLines(height), height), "\n")
}

type orcSessionTreeEntry struct {
	sessionIndex int
	depth        int
	last         bool
}

func (model orcUIModel) sessionTreeEntries() []orcSessionTreeEntry {
	indexByID := make(map[string]int, len(model.sessions))
	for index, session := range model.sessions {
		indexByID[session.ID] = index
	}
	rootByWorkflow := make(map[domain.WorkflowRunID]string, len(model.workflows))
	for _, workflow := range model.workflows {
		if workflow.OrchestrationSession != nil {
			rootByWorkflow[workflow.ID] = string(*workflow.OrchestrationSession)
		}
	}
	parentByIndex := make(map[int]int)
	for _, worker := range model.workers {
		workerIndex, workerFound := indexByID[string(worker.ID)]
		rootID, rootFound := rootByWorkflow[worker.WorkflowRunID]
		rootIndex, sessionFound := indexByID[rootID]
		if workerFound && rootFound && sessionFound && workerIndex != rootIndex {
			parentByIndex[workerIndex] = rootIndex
		}
	}
	children := make(map[int][]int)
	for child := range model.sessions {
		if parent, found := parentByIndex[child]; found {
			children[parent] = append(children[parent], child)
		}
	}
	entries := make([]orcSessionTreeEntry, 0, len(model.sessions))
	seen := make(map[int]bool, len(model.sessions))
	var appendNode func(int, int, bool)
	appendNode = func(index int, depth int, last bool) {
		if seen[index] {
			return
		}
		seen[index] = true
		entries = append(entries, orcSessionTreeEntry{sessionIndex: index, depth: depth, last: last})
		for childPosition, child := range children[index] {
			appendNode(child, depth+1, childPosition == len(children[index])-1)
		}
	}
	var roots []int
	for index := range model.sessions {
		if _, child := parentByIndex[index]; !child {
			roots = append(roots, index)
		}
	}
	for position, root := range roots {
		appendNode(root, 0, position == len(roots)-1)
	}
	for index := range model.sessions {
		appendNode(index, 0, index == len(model.sessions)-1)
	}
	return entries
}

func (model orcUIModel) matchingSessionTreeEntries() []orcSessionTreeEntry {
	query := strings.ToLower(model.query)
	entries := model.sessionTreeEntries()
	if query == "" {
		return entries
	}
	kept := make([]bool, len(entries))
	for index, entry := range entries {
		session := model.sessions[entry.sessionIndex]
		text := strings.ToLower(strings.Join([]string{
			session.ID, session.Harness, model.sessionRole(session), session.Status,
			sessionConnection(session), session.Registration, session.Reason,
		}, " "))
		if strings.Contains(text, query) {
			kept[index] = true
			depth := entry.depth
			for ancestor := index - 1; ancestor >= 0 && depth > 0; ancestor-- {
				if entries[ancestor].depth < depth {
					kept[ancestor] = true
					depth = entries[ancestor].depth
				}
			}
		}
	}
	matching := make([]orcSessionTreeEntry, 0, len(entries))
	for index, entry := range entries {
		if kept[index] {
			matching = append(matching, entry)
		}
	}
	return matching
}

func (model orcUIModel) sessionRole(session instance.Session) string {
	for _, workflow := range model.workflows {
		if workflow.OrchestrationSession != nil && string(*workflow.OrchestrationSession) == session.ID {
			return "orchestrator"
		}
	}
	if session.Role == "controller" {
		return "orchestrator"
	}
	return firstValue(session.Role, "session")
}

func sessionConnection(session instance.Session) string {
	switch session.Registration {
	case "observed":
		return "observed"
	case "managed":
		return "managed"
	default:
		return "connected"
	}
}

func canDisconnectOrcSession(session instance.Session) bool {
	return session.Registration != "observed" && session.Registration != "managed"
}

func sessionOrigin(session instance.Session) string {
	switch session.Origin {
	case "injected":
		return "connected"
	case "spawned":
		return "launched"
	case "resume":
		return "resumed"
	}
	return firstValue(session.Origin, "unknown")
}

func (model orcUIModel) sessionGraphLines(height int) []string {
	entries := model.matchingSessionTreeEntries()
	if len(entries) == 0 {
		return []string{orcTagStyle.Render("No sessions. Use <space>n to start one.")}
	}
	if model.width < 72 || model.height < 18 {
		return model.compactSessionGraphLines(entries, height)
	}
	position := 0
	for index, entry := range entries {
		if entry.sessionIndex == model.sessionCursor {
			position = index
			break
		}
	}
	cardHeight := 4
	start, end := visibleRange(position, len(entries), max(1, height/cardHeight))
	lines := make([]string, 0, (end-start)*cardHeight)
	for _, entry := range entries[start:end] {
		lines = append(lines, model.sessionCardLines(entry)...)
	}
	return lines
}

func (model orcUIModel) graphContentWidth() int {
	width := model.width
	if model.usesWideLayout() && model.explorer {
		width -= min(36, max(24, model.width*28/100))
	}
	return max(1, width-2)
}

func (model orcUIModel) compactSessionGraphLines(entries []orcSessionTreeEntry, height int) []string {
	position := 0
	for index, entry := range entries {
		if entry.sessionIndex == model.sessionCursor {
			position = index
			break
		}
	}
	start, end := visibleRange(position, len(entries), max(1, height))
	lines := make([]string, 0, end-start)
	for _, entry := range entries[start:end] {
		session := model.sessions[entry.sessionIndex]
		connector := ""
		if entry.depth > 0 {
			connector = "└─ "
		}
		row := fmt.Sprintf(" %s%s%s %s  %s", strings.Repeat("  ", max(0, entry.depth-1)), connector,
			sessionGlyph(session.Status), session.ID, session.Status)
		lines = append(lines, model.selectedRow(row, entry.sessionIndex == model.sessionCursor))
	}
	return lines
}

func (model orcUIModel) sessionCardLines(entry orcSessionTreeEntry) []string {
	session := model.sessions[entry.sessionIndex]
	prefix := strings.Repeat("  ", entry.depth)
	continuation := prefix
	if entry.depth > 0 {
		branch := "├─"
		if entry.last {
			branch = "└─"
		}
		prefix = strings.Repeat("  ", entry.depth-1) + branch
		continuation = strings.Repeat("  ", entry.depth)
	}
	cardWidth := max(8, min(48, model.graphContentWidth()-lipgloss.Width(prefix)))
	inner := max(1, cardWidth-2)
	edge := orcRuleStyle
	if entry.sessionIndex == model.sessionCursor {
		edge = orcSelectedStyle
	}
	role := model.sessionRole(session)
	glyph := sessionGlyph(session.Status)
	title := sessionStateStyle(session.Status).Render(glyph) + "  " +
		orcTitleStyle.Render(orcFit(role+" · "+session.Harness, max(1, inner-3)))
	id := ansi.Truncate("id  "+session.ID, inner, "…")
	state := ansi.Truncate(fmt.Sprintf("%s · %s · %s", session.Status, sessionConnection(session),
		relativeTimestamp(session.UpdatedAt)), inner, "…")
	return []string{
		prefix + edge.Render("╭"+strings.Repeat("─", inner)+"╮"),
		continuation + edge.Render("│") + title + edge.Render("│"),
		continuation + edge.Render("│") + orcValueStyle.Render(orcFit(id, inner)) + edge.Render("│"),
		continuation + edge.Render("╰") + orcTagStyle.Render(orcFit(state, inner)) + edge.Render("╯"),
	}
}

func sessionGlyph(status string) string {
	switch status {
	case "running", "working":
		return "●"
	case "waiting", "idle":
		return "○"
	case "completed", "done":
		return "✓"
	case "failed", "disconnected":
		return "×"
	default:
		return "·"
	}
}

func sessionStateStyle(status string) lipgloss.Style {
	switch status {
	case "running", "working", "completed", "done":
		return orcActiveStyle
	case "failed", "disconnected":
		return orcErrorStyle
	default:
		return orcInactiveStyle
	}
}

func (model orcUIModel) explorerBody(height int) string {
	if model.view == orcWorkflowsView {
		return model.workflowExplorerBody(height)
	}
	entries := model.matchingSessionTreeEntries()
	if len(entries) == 0 {
		return strings.Join(model.fitLines([]string{"No sessions"}, height), "\n")
	}
	position := 0
	for index, entry := range entries {
		if entry.sessionIndex == model.sessionCursor {
			position = index
			break
		}
	}
	start, end := visibleRange(position, len(entries), max(1, height))
	lines := make([]string, 0, end-start)
	for _, entry := range entries[start:end] {
		session := model.sessions[entry.sessionIndex]
		branch := ""
		if entry.depth > 0 {
			branch = "└─ "
		}
		row := fmt.Sprintf(" %s%s %s", strings.Repeat("  ", max(0, entry.depth-1)), branch, session.ID)
		lines = append(lines, model.selectedRow(row, entry.sessionIndex == model.sessionCursor))
	}
	return strings.Join(model.fitLines(lines, height), "\n")
}

func (model orcUIModel) workflowExplorerBody(height int) string {
	if !model.graphMode {
		indices := model.matchingWorkflowIndices()
		if len(indices) == 0 {
			return strings.Join(model.fitLines([]string{"No workflows"}, height), "\n")
		}
		position := indexPosition(indices, model.workflowCursor)
		start, end := visibleRange(position, len(indices), max(1, height))
		lines := make([]string, 0, end-start)
		for _, index := range indices[start:end] {
			row := " " + string(model.workflows[index].ID)
			lines = append(lines, model.selectedRow(row, index == model.workflowCursor))
		}
		return strings.Join(model.fitLines(lines, height), "\n")
	}
	nodes := model.workflowNodes()
	rootID := string(model.workflow.Run.ID)
	if model.workflow.Run.OrchestrationSession != nil {
		rootID = string(*model.workflow.Run.OrchestrationSession)
	}
	if !model.workflowLoaded() {
		return strings.Join(model.fitLines([]string{"Loading workflow graph…"}, height), "\n")
	}
	lines := []string{model.selectedRow(" "+rootID, model.workflowRootSelected)}
	depths := model.workflowNodeDepths(nodes)
	for index, node := range nodes {
		depth := max(1, depths[node.NodeKey])
		row := fmt.Sprintf(" %s└─ %s", strings.Repeat("  ", depth-1), node.NodeKey)
		lines = append(lines, model.selectedRow(row, !model.workflowRootSelected && index == model.nodeCursor))
	}
	position := 0
	if !model.workflowRootSelected {
		position = min(model.nodeCursor+1, max(0, len(lines)-1))
	}
	start, end := visibleRange(position, len(lines), max(1, height))
	return strings.Join(model.fitLines(lines[start:end], height), "\n")
}

func (model orcUIModel) selectedRow(row string, selected bool) string {
	if !selected {
		return orcValueStyle.Render(" " + row[1:])
	}
	return orcSelectedStyle.Render("▸" + row[1:])
}

func (model orcUIModel) inspectorBody(height int) string {
	var lines []string
	if model.view == orcWorkflowsView {
		if _, found := model.selectedWorkflow(); !found {
			lines = []string{"Select or create a workflow run."}
		} else if !model.workflowLoaded() {
			lines = []string{"Loading workflow details…"}
		} else if model.graphMode {
			lines = model.selectedNodeDetailLines()
		} else {
			lines = model.workflowDetailLines()
		}
	} else if session, found := model.selectedSession(); found {
		lines = []string{
			orcTitleStyle.Render(session.ID),
			orcLabelStyle.Render("harness       ") + orcValueStyle.Render(session.Harness),
			orcLabelStyle.Render("role          ") + orcValueStyle.Render(model.sessionRole(session)),
			orcLabelStyle.Render("state         ") + orcValueStyle.Render(session.Status),
			orcLabelStyle.Render("connection    ") + orcValueStyle.Render(sessionConnection(session)),
			orcLabelStyle.Render("origin        ") + orcValueStyle.Render(sessionOrigin(session)),
			orcLabelStyle.Render("capabilities  ") + orcValueStyle.Render(strings.Join(session.Capabilities, ", ")),
			orcLabelStyle.Render("native id     ") + orcValueStyle.Render(firstValue(session.NativeSessionID, "unavailable")),
			orcLabelStyle.Render("pane          ") + orcValueStyle.Render(firstValue(session.Pane, "unavailable")),
			orcLabelStyle.Render("directory     ") + orcValueStyle.Render(session.Directory),
		}
	} else {
		lines = []string{"Select a harness session."}
	}
	maximum := max(0, len(lines)-height)
	offset := min(model.inspectorOffset, maximum)
	visible := model.fitLines(lines[offset:], height)
	if height > 0 && offset > 0 {
		visible[0] = orcTagStyle.Render("↑ more")
	}
	if height > 0 && offset+height < len(lines) {
		visible[height-1] = orcTagStyle.Render("↓ more")
	}
	return strings.Join(visible, "\n")
}

func (model orcUIModel) fitLines(lines []string, height int) []string {
	if height < 1 {
		return nil
	}
	if len(lines) > height {
		lines = append([]string(nil), lines[:height]...)
	}
	for len(lines) < height {
		lines = append(lines, "")
	}
	for index := range lines {
		lines[index] = ansi.Truncate(lines[index], max(1, model.width-4), "…")
	}
	return lines
}

func (model orcUIModel) resourceStrip() string {
	if run, found := model.selectedWorkflow(); found {
		if model.graphMode {
			if !model.workflowLoaded() {
				return orcTagStyle.Render("loading " + string(run.ID))
			}
			nodes := model.workflowNodes()
			if node, selected := model.selectedNode(); selected {
				return orcTagStyle.Render(fmt.Sprintf("node %d/%d · %s · %s · attempt %d",
					model.nodeCursor+1, len(nodes), node.NodeKey, node.State, node.Attempt))
			}
		}
		return orcTagStyle.Render(fmt.Sprintf("workflow %d/%d · %s · %s", model.workflowCursor+1,
			len(model.workflows), run.State, relativeTime(run.Metadata.UpdatedAt)))
	}
	if session, found := model.selectedSession(); found {
		entries := model.matchingSessionTreeEntries()
		position := 0
		for index, entry := range entries {
			if entry.sessionIndex == model.sessionCursor {
				position = index
				break
			}
		}
		return orcTagStyle.Render(fmt.Sprintf("session %d/%d · %s · %s · %s", position+1,
			len(entries), session.Harness, session.Status, sessionConnection(session)))
	}
	return orcTagStyle.Render("no resources")
}

func (model orcUIModel) controlFooter() string {
	if model.openSession != "" {
		return orcTagStyle.Render("y open split   n cancel")
	}
	if model.leader {
		if model.width < 100 {
			actions := []string{"v view"}
			if session, found := model.selectedSession(); found && session.Registration == "observed" {
				actions = append(actions, "r connect")
			} else if found && canDisconnectOrcSession(session) {
				actions = append(actions, "x disconnect")
			}
			if model.width >= 44 {
				actions = append(actions, "e tree")
			}
			actions = append(actions, "n new")
			if _, found := model.selectedTrace(); found {
				actions = append(actions, "t traces")
			}
			if model.usesWideLayout() {
				actions = append(actions, "i details")
			}
			actions = append(actions, "b broker", "? help")
			return model.fitCompactLeaderActions(actions)
		}
		actions := []string{"v view"}
		if model.view == orcWorkflowsView {
			actions = append(actions, "g graph")
		}
		actions = append(actions, "e explorer", "n new")
		if _, found := model.selectedTrace(); found {
			actions = append(actions, "t traces")
		}
		if session, found := model.selectedSession(); found && session.Registration == "observed" {
			actions = append(actions, "r connect")
		}
		if session, found := model.selectedSession(); found && canDisconnectOrcSession(session) {
			actions = append(actions, "x disconnect")
		}
		actions = append(actions, "i inspector", "b broker")
		return orcSelectedStyle.Render("<space>") + orcTagStyle.Render("  "+strings.Join(actions, "  "))
	}
	attach := ""
	if model.view == orcWorkflowsView && !model.graphMode {
		attach = "enter open  "
	} else if session, found := model.selectedAttachSession(); found && canAttachOrcSession(session) {
		attach = "enter attach  "
	} else if found && model.canOpenSession(session) {
		attach = "enter reopen  "
	}
	if model.width < 72 {
		if attach != "" {
			return orcTagStyle.Render(attach + "<space>  ? help  q quit")
		}
		return orcTagStyle.Render("j/k select  <space>  ? help  q quit")
	}
	if model.focus == orcDetailFocus {
		return orcTagStyle.Render("j/k scroll  ctrl+k graph  <space> actions  ? help  q quit")
	}
	if model.width >= 72 && model.width < 100 {
		return orcTagStyle.Render(attach + "j/k select  ctrl+j details  <space>  ? help  q quit")
	}
	return orcTagStyle.Render(attach + "j/k select   ctrl+h/l panes   / filter   <space> actions   ? help   q quit")
}

func (model orcUIModel) fitCompactLeaderActions(actions []string) string {
	render := func(values []string) string {
		return orcSelectedStyle.Render("<space>") + orcTagStyle.Render("  "+strings.Join(values, "  "))
	}
	for _, removable := range []string{"b broker", "i details", "n new", "e tree", "r connect", "x disconnect", "v view"} {
		if lipgloss.Width(render(actions)) <= model.width {
			break
		}
		for index, action := range actions {
			if action == removable {
				actions = append(actions[:index:index], actions[index+1:]...)
				break
			}
		}
	}
	return render(actions)
}

func (model orcUIModel) bottomFooter() string {
	left := model.resourceStrip()
	if model.message != "" {
		style := orcMessageStyle
		if model.messageError {
			style = orcErrorStyle
		}
		singleLine := strings.ReplaceAll(strings.ReplaceAll(model.message, "\r", " "), "\n", " ")
		left = style.Render(singleLine)
	}
	right := model.controlFooter()
	if model.width < 72 {
		return right
	}
	gap := model.width - lipgloss.Width(left) - lipgloss.Width(right)
	if gap < 2 {
		left = ansi.Truncate(left, max(0, model.width-lipgloss.Width(right)-2), "…")
		gap = max(2, model.width-lipgloss.Width(left)-lipgloss.Width(right))
	}
	return left + strings.Repeat(" ", gap) + right
}

func (model orcUIModel) compactBodyWithMessage(body string, width int, height int) string {
	if height <= 0 {
		return body
	}
	lines := strings.Split(body, "\n")
	if len(lines) >= height {
		lines = lines[:height-1]
	}
	style := orcMessageStyle
	if model.messageError {
		style = orcErrorStyle
	}
	singleLine := strings.ReplaceAll(strings.ReplaceAll(model.message, "\r", " "), "\n", " ")
	lines = append(lines, style.Render(ansi.Truncate(singleLine, max(1, width), "…")))
	return strings.Join(lines, "\n")
}

func (model orcUIModel) fullHelpView() string {
	lines := model.fullHelpLines()
	bodyHeight := max(1, model.height-3)
	offset := min(model.helpOffset, max(0, len(lines)-bodyHeight))
	visible := lines[offset:]
	footer := orcTagStyle.Render("esc return   j/k scroll   ctrl+d/u page")
	return orcPanel("help", model.width, model.height-1,
		strings.Join(model.fitLines(visible, bodyHeight), "\n"), true) + "\n" +
		ansi.Truncate(footer, model.width, "")
}

func (model orcUIModel) fullHelpLines() []string {
	lines := []string{
		orcTitleStyle.Render("⚔ orc help"), "",
		orcLabelStyle.Render("navigation"),
		"  j/k, arrows       move within the focused pane",
		"  enter             open workflow or attach session",
		"  ctrl+h, ctrl+l    focus explorer or graph",
		"  ctrl+j, ctrl+k    focus details or graph",
		"  gg, G             first or last resource",
		"  ctrl+d, ctrl+u    move by half a page",
		"  /                 filter resources",
		"",
		orcLabelStyle.Render("leader actions"),
		"  <space>v          workflows or sessions",
		"  <space>e          show or hide the explorer",
		"  <space>n          recency-based harness picker",
		"  <space>t          open Traces for this session",
	}
	if model.view == orcWorkflowsView {
		lines = append(lines, "  <space>g          workflow list or graph")
	} else {
		lines = append(lines,
			"  <space>r          connect an observed session",
			"  <space>x          disconnect a connected session",
		)
	}
	lines = append(lines,
		"  <space>i          show or hide the inspector",
		"  <space>b          start or stop the broker",
	)
	if model.view == orcWorkflowsView {
		lines = append(lines,
			"",
			orcLabelStyle.Render("workflow actions"),
			"  h, l              select a restart point",
			"  f                  confirm and fork from the restart point",
		)
	}
	return lines
}

func (model orcUIModel) maxHelpOffset() int {
	return max(0, len(model.fullHelpLines())-max(1, model.height-3))
}

func (model orcUIModel) controllerPickerView() string {
	lines := []string{orcLabelStyle.Render("  harness                  resume")}
	start, end := visibleRange(model.cursor, len(model.agents), max(1, model.height-5))
	for index := start; index < end; index++ {
		agent := model.agents[index]
		label := firstValue(agent.Label, agent.Name)
		resume := "no"
		if len(agent.Launch.ResumeArgs) > 0 {
			resume = "yes"
		}
		row := fmt.Sprintf("  %-24s %s", ansi.Truncate(label, 24, "…"), resume)
		lines = append(lines, model.selectedRow(row, index == model.cursor))
	}
	lines = model.fitLines(lines, model.height-3)
	footerText := "j/k select   enter new   R resume   esc cancel"
	if model.width < 60 {
		footerText = "j/k  enter new  R resume  esc cancel"
	}
	footer := orcTagStyle.Render(footerText)
	return orcPanel("new session · recent first", model.width, model.height-1, strings.Join(lines, "\n"), true) + "\n" +
		ansi.Truncate(footer, model.width, "")
}

func orcPanel(name string, width int, height int, body string, focused bool) string {
	if width < 4 || height < 2 {
		return body
	}
	edge := orcRuleStyle
	if focused {
		edge = orcTitleStyle
	}
	inner := width - 2
	title := "─ " + name + " "
	top := edge.Render("╭" + title + strings.Repeat("─", max(0, inner-ansi.StringWidth(title))) + "╮")
	lines := []string{orcFit(top, width)}
	bodyLines := strings.Split(body, "\n")
	for index := 0; index < height-2; index++ {
		line := ""
		if index < len(bodyLines) {
			line = bodyLines[index]
		}
		lines = append(lines, edge.Render("│")+orcFit(line, inner)+edge.Render("│"))
	}
	lines = append(lines, edge.Render("╰"+strings.Repeat("─", inner)+"╯"))
	return strings.Join(lines, "\n")
}

func relativeTime(value time.Time) string {
	if value.IsZero() {
		return "unknown"
	}
	return shortDuration(time.Since(value))
}

func relativeTimestamp(value string) string {
	parsed, err := time.Parse(time.RFC3339Nano, value)
	if err != nil {
		return "unknown"
	}
	return shortDuration(time.Since(parsed))
}

func shortDuration(value time.Duration) string {
	if value < time.Minute {
		return fmt.Sprintf("%ds ago", max(0, int(value.Seconds())))
	}
	if value < time.Hour {
		return fmt.Sprintf("%dm ago", int(value.Minutes()))
	}
	if value < 24*time.Hour {
		return fmt.Sprintf("%dh ago", int(value.Hours()))
	}
	return fmt.Sprintf("%dd ago", int(value.Hours()/24))
}

func orcRefreshCommand() tea.Cmd {
	return tea.Tick(time.Second, func(now time.Time) tea.Msg { return orcRefreshTick(now) })
}

func (model *orcUIModel) beginRefresh(success string) tea.Cmd {
	if success != "" {
		model.pendingRefreshStatus = success
	}
	if model.refreshing {
		return nil
	}
	model.refreshing = true
	success = model.pendingRefreshStatus
	model.pendingRefreshStatus = ""
	snapshot := *model
	revision := model.refreshRevision
	return func() tea.Msg {
		err := snapshot.refreshState()
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
	model.nodeCursor = min(model.nodeCursor, max(0, len(updated.workflow.Nodes)-1))
	if model.selectedNodeID != "" {
		selectedFound := false
		for index, node := range updated.workflowNodes() {
			if node.ID == model.selectedNodeID {
				model.nodeCursor = index
				model.workflowRootSelected = false
				selectedFound = true
				break
			}
		}
		if !selectedFound {
			model.selectWorkflowRoot()
		}
	}
	model.restartPoints = updated.restartPoints
	model.restartCursor = updated.restartCursor
	model.forks = updated.forks
	model.workers = updated.workers
	model.workerCursor = updated.workerCursor
	model.sessions = updated.sessions
	model.sessionCursor = updated.sessionCursor
	if indices := model.matchingSessionIndices(); len(indices) > 0 && !containsIndex(indices, model.sessionCursor) {
		model.sessionCursor = indices[0]
	}
	model.requestedWorkflow = updated.requestedWorkflow
}

func (model orcUIModel) header(width int) string {
	status := orcInactiveStyle.Render("broker stopped")
	if model.active {
		status = orcActiveStyle.Render(fmt.Sprintf("broker running · %d sessions", len(model.sessions)))
	}
	scope := model.record.Scope
	if scope == "" {
		scope, _ = os.Getwd()
	}
	prefix := orcTitleStyle.Render("⚔ orc") + "  " + orcValueStyle.Render(filepath.Base(scope)) + "  "
	leftWidth := max(1, width-lipgloss.Width(status)-1)
	scopeWidth := max(1, leftWidth-lipgloss.Width(prefix))
	left := prefix + orcTagStyle.Render(ansi.Truncate(scope, scopeWidth, "…"))
	left = ansi.Truncate(left, leftWidth, "")
	gap := width - lipgloss.Width(left) - lipgloss.Width(status)
	if gap < 1 {
		gap = 1
	}
	return ansi.Truncate(left+strings.Repeat(" ", gap)+status, width, "")
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

func (model orcUIModel) workflowNodes() []domain.NodeRun {
	nodes := append([]domain.NodeRun(nil), model.workflow.Nodes...)
	sort.Slice(nodes, func(first int, second int) bool { return nodes[first].NodeKey < nodes[second].NodeKey })
	byKey := make(map[domain.NodeKey]domain.NodeRun, len(nodes))
	indegree := make(map[domain.NodeKey]int, len(nodes))
	children := make(map[domain.NodeKey][]domain.NodeKey, len(nodes))
	for _, node := range nodes {
		byKey[node.NodeKey] = node
	}
	for _, edge := range model.definition.Edges {
		if _, fromFound := byKey[edge.From]; !fromFound {
			continue
		}
		if _, toFound := byKey[edge.To]; !toFound || edge.From == edge.To {
			continue
		}
		children[edge.From] = append(children[edge.From], edge.To)
		indegree[edge.To]++
	}
	queue := make([]domain.NodeKey, 0, len(nodes))
	for _, node := range nodes {
		if indegree[node.NodeKey] == 0 {
			queue = append(queue, node.NodeKey)
		}
	}
	ordered := make([]domain.NodeRun, 0, len(nodes))
	seen := make(map[domain.NodeKey]bool, len(nodes))
	for len(queue) > 0 {
		sort.Slice(queue, func(first int, second int) bool { return queue[first] < queue[second] })
		key := queue[0]
		queue = queue[1:]
		if seen[key] {
			continue
		}
		seen[key] = true
		ordered = append(ordered, byKey[key])
		for _, child := range children[key] {
			indegree[child]--
			if indegree[child] == 0 {
				queue = append(queue, child)
			}
		}
	}
	for _, node := range nodes {
		if !seen[node.NodeKey] {
			ordered = append(ordered, node)
		}
	}
	return ordered
}

func (model orcUIModel) selectedNode() (domain.NodeRun, bool) {
	nodes := model.workflowNodes()
	if !model.graphMode || model.workflowRootSelected || model.nodeCursor < 0 || model.nodeCursor >= len(nodes) {
		return domain.NodeRun{}, false
	}
	return nodes[model.nodeCursor], true
}

func (model *orcUIModel) setNodeCursor(cursor int) {
	nodes := model.workflowNodes()
	if len(nodes) == 0 {
		model.selectWorkflowRoot()
		return
	}
	model.workflowRootSelected = false
	model.nodeCursor = min(max(0, cursor), len(nodes)-1)
	model.selectedNodeID = nodes[model.nodeCursor].ID
	model.inspectorOffset = 0
}

func (model *orcUIModel) selectWorkflowRoot() {
	model.workflowRootSelected = true
	model.nodeCursor = 0
	model.selectedNodeID = ""
	model.inspectorOffset = 0
}

func (model *orcUIModel) moveWorkflowGraphCursor(delta int) {
	nodes := model.workflowNodes()
	if model.workflowRootSelected {
		if delta > 0 && len(nodes) > 0 {
			model.setNodeCursor(min(len(nodes)-1, delta-1))
		}
		return
	}
	next := model.nodeCursor + delta
	if next < 0 {
		model.selectWorkflowRoot()
		return
	}
	model.setNodeCursor(next)
}

func (model orcUIModel) workflowGraphLines(height int) []string {
	nodes := model.workflowNodes()
	rootID := string(model.workflow.Run.ID)
	if model.workflow.Run.OrchestrationSession != nil {
		rootID = string(*model.workflow.Run.OrchestrationSession)
	}
	if model.width < 72 || model.height < 18 || height < 10 {
		root := fmt.Sprintf(" ● %s  %s", rootID, model.workflow.Run.State)
		rows := []string{model.selectedRow(root, model.workflowRootSelected)}
		for index, node := range nodes {
			row := fmt.Sprintf(" └─ %s %s  %s", sessionGlyph(string(node.State)), node.NodeKey, node.State)
			rows = append(rows, model.selectedRow(row, !model.workflowRootSelected && index == model.nodeCursor))
		}
		position := 0
		if !model.workflowRootSelected {
			position = min(model.nodeCursor+1, len(rows)-1)
		}
		start, end := visibleRange(position, len(rows), max(1, height))
		return rows[start:end]
	}
	contentWidth := model.graphContentWidth()
	rootWidth := max(18, min(48, contentWidth))
	rootInner := rootWidth - 2
	rootEdge := orcRuleStyle
	if model.workflowRootSelected {
		rootEdge = orcSelectedStyle
	}
	rootLines := []string{
		orcCardTop(rootEdge, string(model.workflow.Run.State), "orchestrator · workflow", rootInner),
		rootEdge.Render("│") + orcValueStyle.Render(orcFit("id  "+rootID, rootInner)) + rootEdge.Render("│"),
		rootEdge.Render("╰") + orcTagStyle.Render(orcFit(string(model.workflow.Run.State), rootInner)) + rootEdge.Render("╯"),
	}
	if len(nodes) == 0 {
		return append(rootLines, orcTagStyle.Render("  This workflow has no worker nodes."))
	}
	position := min(model.nodeCursor, len(nodes)-1)
	depths := model.workflowNodeDepths(nodes)
	cardHeight := 4
	availableCards := max(1, (height-len(rootLines)-2)/cardHeight)
	start, end := visibleRange(position, len(nodes), availableCards)
	rows := append(rootLines, orcRuleStyle.Render("│"))
	for index := start; index < end; index++ {
		node := nodes[index]
		depth := max(1, depths[node.NodeKey])
		indent := strings.Repeat("  ", depth-1)
		branch := "├─ "
		if index == len(nodes)-1 {
			branch = "└─ "
		}
		edge := orcRuleStyle
		if !model.workflowRootSelected && index == model.nodeCursor {
			edge = orcSelectedStyle
		}
		cardWidth := max(8, min(44, contentWidth-lipgloss.Width(indent)-2))
		inner := cardWidth - 2
		sessionID := "not started"
		if node.SessionID != nil {
			sessionID = string(*node.SessionID)
		}
		parents := model.workflowNodeParents(node.NodeKey)
		if len(parents) == 0 {
			parents = []string{"orchestrator"}
		}
		rows = append(rows,
			indent+orcRuleStyle.Render(branch+strings.Join(parents, ", ")+" →"),
			indent+"  "+orcCardTop(edge, string(node.State), "worker · "+node.Adapter, inner),
			indent+"  "+edge.Render("│")+orcValueStyle.Render(orcFit("id  "+sessionID, inner))+edge.Render("│"),
			indent+"  "+edge.Render("╰")+orcTagStyle.Render(orcFit(
				fmt.Sprintf("%s · attempt %d", node.NodeKey, node.Attempt), inner))+edge.Render("╯"),
		)
	}
	rows = append(rows, orcTagStyle.Render(fmt.Sprintf("rows %d-%d/%d · %d edges", start+1, end,
		len(nodes), len(model.definition.Edges))))
	return rows
}

func orcCardTop(edge lipgloss.Style, status string, label string, inner int) string {
	label = ansi.Truncate(label, max(1, inner-4), "…")
	filler := max(0, inner-4-ansi.StringWidth(label))
	return edge.Render("╭─ ") + sessionStateStyle(status).Render(sessionGlyph(status)) + " " +
		orcTitleStyle.Render(label) + edge.Render(strings.Repeat("─", filler)+"╮")
}

func (model orcUIModel) workflowNodeParents(key domain.NodeKey) []string {
	parents := make([]string, 0)
	for _, edge := range model.definition.Edges {
		if edge.To == key {
			parents = append(parents, string(edge.From))
		}
	}
	sort.Strings(parents)
	return parents
}

func (model orcUIModel) workflowNodeDepths(nodes []domain.NodeRun) map[domain.NodeKey]int {
	known := make(map[domain.NodeKey]bool, len(nodes))
	indegree := make(map[domain.NodeKey]int, len(nodes))
	children := make(map[domain.NodeKey][]domain.NodeKey, len(nodes))
	for _, node := range nodes {
		known[node.NodeKey] = true
	}
	for _, edge := range model.definition.Edges {
		if !known[edge.From] || !known[edge.To] || edge.From == edge.To {
			continue
		}
		children[edge.From] = append(children[edge.From], edge.To)
		indegree[edge.To]++
	}
	depths := make(map[domain.NodeKey]int, len(nodes))
	queue := make([]domain.NodeKey, 0, len(nodes))
	for _, node := range nodes {
		if indegree[node.NodeKey] == 0 {
			depths[node.NodeKey] = 1
			queue = append(queue, node.NodeKey)
		}
	}
	for len(queue) > 0 {
		parent := queue[0]
		queue = queue[1:]
		for _, child := range children[parent] {
			depths[child] = max(depths[child], depths[parent]+1)
			indegree[child]--
			if indegree[child] == 0 {
				queue = append(queue, child)
			}
		}
	}
	for _, node := range nodes {
		depths[node.NodeKey] = max(1, depths[node.NodeKey])
	}
	return depths
}

func (model orcUIModel) selectedNodeDetailLines() []string {
	if model.workflowRootSelected {
		return model.workflowRootDetailLines()
	}
	node, found := model.selectedNode()
	if !found {
		return []string{"Select a workflow node."}
	}
	lines := []string{orcTitleStyle.Render("workflow " + string(model.workflow.Run.ID))}
	if len(model.restartPoints) > 0 {
		point := model.restartPoints[model.restartCursor]
		lines = append(lines, orcLabelStyle.Render("restart     ")+orcValueStyle.Render(string(point.ID)))
	}
	for _, fork := range model.forks {
		relation := "child " + string(fork.ChildWorkflowRunID)
		if fork.ChildWorkflowRunID == model.workflow.Run.ID {
			relation = "parent " + string(fork.ParentWorkflowRunID)
		}
		lines = append(lines, orcLabelStyle.Render("lineage     ")+orcValueStyle.Render(
			relation+" via "+string(fork.RestartPointID)))
	}
	lines = append(lines,
		orcTitleStyle.Render(string(node.NodeKey)),
		orcLabelStyle.Render("state       ")+orcValueStyle.Render(string(node.State)),
		orcLabelStyle.Render("adapter     ")+orcValueStyle.Render(node.Adapter),
		orcLabelStyle.Render("attempt     ")+orcValueStyle.Render(fmt.Sprintf("%d", node.Attempt)),
		orcLabelStyle.Render("repair      ")+orcValueStyle.Render(fmt.Sprintf("%d", node.RepairAttempt)),
		orcLabelStyle.Render("node run    ")+orcValueStyle.Render(string(node.ID)),
	)
	if node.SessionID != nil {
		lines = append(lines, orcLabelStyle.Render("session     ")+orcValueStyle.Render(string(*node.SessionID)))
	} else {
		lines = append(lines, orcLabelStyle.Render("session     ")+orcInactiveStyle.Render("not started"))
	}
	var incoming, outgoing []string
	for _, edge := range model.definition.Edges {
		if edge.To == node.NodeKey {
			incoming = append(incoming, fmt.Sprintf("%s.%s -> %s.%s", edge.From, edge.FromPort, edge.To, edge.ToPort))
		}
		if edge.From == node.NodeKey {
			outgoing = append(outgoing, fmt.Sprintf("%s.%s -> %s.%s", edge.From, edge.FromPort, edge.To, edge.ToPort))
		}
	}
	lines = append(lines,
		orcLabelStyle.Render("depends on  ")+orcValueStyle.Render(firstValue(strings.Join(incoming, ", "), "none")),
		orcLabelStyle.Render("unblocks    ")+orcValueStyle.Render(firstValue(strings.Join(outgoing, ", "), "none")),
	)
	return lines
}

func (model orcUIModel) workflowRootDetailLines() []string {
	run, found := model.selectedWorkflow()
	if !found {
		return []string{"Select a workflow run."}
	}
	lines := []string{
		orcTitleStyle.Render(string(run.ID)),
		orcLabelStyle.Render("role          ") + orcValueStyle.Render("orchestrator"),
		orcLabelStyle.Render("state         ") + orcValueStyle.Render(string(run.State)),
	}
	if run.OrchestrationSession == nil {
		return append(lines, orcLabelStyle.Render("session       ")+orcInactiveStyle.Render("unavailable"))
	}
	sessionID := string(*run.OrchestrationSession)
	lines = append(lines, orcLabelStyle.Render("session       ")+orcValueStyle.Render(sessionID))
	if session, sessionFound := model.sessionByID(sessionID); sessionFound {
		lines = append(lines,
			orcLabelStyle.Render("harness       ")+orcValueStyle.Render(session.Harness),
			orcLabelStyle.Render("session state ")+orcValueStyle.Render(session.Status),
		)
	}
	return lines
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
	return model.refreshState()
}

func (model *orcUIModel) refreshState() error {
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
		model.sessions = nil
		return nil
	}
	switch model.view {
	case orcWorkflowsView:
		if err := model.loadWorkflows(); err != nil {
			return err
		}
		return model.loadSessionResources()
	case orcSessionsView:
		if err := model.loadWorkflowRuns(); err != nil {
			return err
		}
		return model.loadSessionResources()
	default:
		return nil
	}
}

func (model *orcUIModel) loadSessionResources() error {
	selected := ""
	if model.sessionCursor >= 0 && model.sessionCursor < len(model.sessions) {
		selected = model.sessions[model.sessionCursor].ID
	}
	if err := model.loadWorkers(); err != nil {
		return err
	}
	sessions, err := controlPlaneSessions(model.record)
	if err != nil {
		return err
	}
	model.sessions = sessions
	for _, worker := range model.workers {
		model.sessions = append(model.sessions, instance.Session{
			Version: instance.SessionVersion, ID: string(worker.ID), Role: "worker",
			Harness: worker.RuntimeAdapterID, Scope: model.record.Scope, Status: string(worker.State),
			TraceSessionID: worker.TraceSessionID,
			Registration:   "managed", Origin: "workflow", Capabilities: append([]string(nil), worker.Capabilities...),
			StartedAt: worker.Metadata.CreatedAt.Format(time.RFC3339Nano),
			UpdatedAt: worker.Metadata.UpdatedAt.Format(time.RFC3339Nano),
		})
	}
	sort.SliceStable(model.sessions, func(first, second int) bool {
		return model.sessions[first].UpdatedAt > model.sessions[second].UpdatedAt
	})
	if selected != "" {
		for index := range model.sessions {
			if model.sessions[index].ID == selected {
				model.sessionCursor = index
				break
			}
		}
	}
	if model.sessionCursor >= len(model.sessions) {
		model.sessionCursor = max(0, len(model.sessions)-1)
	}
	return nil
}

func (model *orcUIModel) moveCursor(delta int) bool {
	if model.view == orcWorkflowsView {
		if model.graphMode {
			model.moveWorkflowGraphCursor(delta)
			return false
		}
		indices := model.matchingWorkflowIndices()
		next := indexPosition(indices, model.workflowCursor) + delta
		if next < 0 || next >= len(indices) {
			return false
		}
		model.workflowCursor = indices[next]
		model.setNodeCursor(0)
		model.graphOffset = 0
		model.inspectorOffset = 0
		return true
	}
	indices := model.matchingSessionIndices()
	next := indexPosition(indices, model.sessionCursor) + delta
	if next < 0 || next >= len(indices) {
		return false
	}
	model.sessionCursor = indices[next]
	model.inspectorOffset = 0
	return true
}

func (model *orcUIModel) moveWorkflowPage(delta int) bool {
	indices := model.matchingWorkflowIndices()
	position := indexPosition(indices, model.workflowCursor)
	if position < 0 || len(indices) == 0 {
		return false
	}
	next := min(max(0, position+delta), len(indices)-1)
	if next == position {
		return false
	}
	model.workflowCursor = indices[next]
	model.setNodeCursor(0)
	model.graphOffset = 0
	model.inspectorOffset = 0
	return true
}

func (model orcUIModel) selectedSession() (instance.Session, bool) {
	if model.view != orcSessionsView || model.sessionCursor < 0 || model.sessionCursor >= len(model.sessions) {
		return instance.Session{}, false
	}
	if model.query != "" {
		visible := false
		for _, index := range model.matchingSessionIndices() {
			if index == model.sessionCursor {
				visible = true
				break
			}
		}
		if !visible {
			return instance.Session{}, false
		}
	}
	return model.sessions[model.sessionCursor], true
}

func (model orcUIModel) selectedAttachSession() (instance.Session, bool) {
	if session, found := model.selectedSession(); found {
		return session, true
	}
	if model.view != orcWorkflowsView {
		return instance.Session{}, false
	}
	run, found := model.selectedWorkflow()
	if !found {
		return instance.Session{}, false
	}
	if model.graphMode && model.workflow.Run.ID != run.ID {
		return instance.Session{}, false
	}
	if node, found := model.selectedNode(); found {
		if node.SessionID == nil {
			return instance.Session{}, false
		}
		return model.sessionByID(string(*node.SessionID))
	}
	if run.OrchestrationSession == nil {
		return instance.Session{}, false
	}
	return model.sessionByID(string(*run.OrchestrationSession))
}

func (model orcUIModel) sessionByID(id string) (instance.Session, bool) {
	for _, session := range model.sessions {
		if session.ID == id {
			return session, true
		}
	}
	return instance.Session{}, false
}

func canAttachOrcSession(session instance.Session) bool {
	if session.Registration == "managed" {
		if session.Status != string(domain.SessionStateRunning) && session.Status != string(domain.SessionStateWaiting) {
			return false
		}
		for _, capability := range session.Capabilities {
			if capability == "native-attachment" {
				return true
			}
		}
		return false
	}
	return session.Status != "disconnected" && session.Pane != "" && session.Mux > 0
}

func (model orcUIModel) attachSelected() (tea.Model, tea.Cmd) {
	if model.view == orcWorkflowsView && !model.graphMode {
		model.graphMode = true
		model.selectWorkflowRoot()
		model.graphOffset = 0
		return model, nil
	}
	session, found := model.selectedAttachSession()
	if !found {
		model.message = "This selection has no session to attach"
		model.messageError = true
		return model, nil
	}
	if !canAttachOrcSession(session) {
		if model.canOpenSession(session) {
			model.openSession = session.ID
			model.message = model.sessionOpenPrompt(session)
			model.messageError = false
			return model, nil
		}
		model.message = "This session is unavailable for attachment"
		model.messageError = true
		return model, nil
	}
	if session.Registration == "managed" {
		command := exec.Command(os.Args[0], "attach", session.ID)
		return model, tea.ExecProcess(command, func(err error) tea.Msg {
			if err != nil {
				return orcActionMessage{err: fmt.Errorf("attach to session: %w", err)}
			}
			return orcActionMessage{text: "Returned from session"}
		})
	}
	return model, func() tea.Msg {
		var stdout, stderr bytes.Buffer
		if focusOrcSession(session, &stdout, &stderr) != 0 {
			return orcActionMessage{err: errors.New(strings.TrimSpace(stderr.String()))}
		}
		return orcActionMessage{text: strings.TrimSpace(stdout.String())}
	}
}

func (model orcUIModel) canOpenSession(session instance.Session) bool {
	if session.Status != "disconnected" || session.Registration == "managed" || session.Harness == "" {
		return false
	}
	_, found := model.agentByName(session.Harness)
	return found
}

func (model orcUIModel) agentByName(name string) (agents.Agent, bool) {
	for _, agent := range model.agents {
		if agent.Name == name {
			return agent, true
		}
	}
	return agents.Agent{}, false
}

func (model orcUIModel) sessionOpenLabel(session instance.Session) string {
	if agent, found := model.agentByName(session.Harness); found {
		return firstValue(agent.Label, agent.Name)
	}
	return session.Harness
}

func (model orcUIModel) sessionOpenPrompt(session instance.Session) string {
	agent, _ := model.agentByName(session.Harness)
	action := "Start a new"
	if len(agent.Launch.ResumeArgs) > 0 {
		action = "Resume"
	}
	return fmt.Sprintf("%s %s session in a right split? y/N", action, model.sessionOpenLabel(session))
}

func (model orcUIModel) openSessionSplit(session instance.Session) tea.Cmd {
	agent, _ := model.agentByName(session.Harness)
	resume := len(agent.Launch.ResumeArgs) > 0
	return func() tea.Msg {
		if err := openOrcSessionSplit(session, resume); err != nil {
			return orcActionMessage{err: fmt.Errorf("open session split: %w", err)}
		}
		return orcActionMessage{text: "Opened " + model.sessionOpenLabel(session) + " in a right split"}
	}
}

func openOrcSessionSplit(session instance.Session, resume bool) error {
	pane := os.Getenv("WEZTERM_PANE")
	if pane == "" {
		return errors.New("the Orc UI is not running in a WezTerm pane")
	}
	executable, err := os.Executable()
	if err != nil {
		return fmt.Errorf("find Orc executable: %w", err)
	}
	arguments := orcSessionSplitArguments(executable, pane, session, resume)
	command := exec.Command("wezterm", arguments...)
	output, err := command.CombinedOutput()
	if err != nil {
		return fmt.Errorf("wezterm: %s: %w", strings.TrimSpace(string(output)), err)
	}
	return nil
}

func orcSessionSplitArguments(executable string, pane string, session instance.Session, resume bool) []string {
	arguments := []string{
		"cli", "--no-auto-start", "split-pane", "--pane-id", pane, "--right", "--percent", "50",
	}
	if session.Directory != "" {
		arguments = append(arguments, "--cwd", session.Directory)
	}
	action := "run"
	if resume {
		action = "resume"
	}
	arguments = append(arguments, "--", executable, action, session.Harness)
	if resume && session.NativeSessionID != "" {
		arguments = append(arguments, "--", session.NativeSessionID)
	}
	return arguments
}

func (model orcUIModel) selectedWorkflow() (domain.WorkflowRun, bool) {
	if model.view != orcWorkflowsView || model.workflowCursor < 0 || model.workflowCursor >= len(model.workflows) {
		return domain.WorkflowRun{}, false
	}
	if model.query != "" {
		visible := false
		for _, index := range model.matchingWorkflowIndices() {
			if index == model.workflowCursor {
				visible = true
				break
			}
		}
		if !visible {
			return domain.WorkflowRun{}, false
		}
	}
	return model.workflows[model.workflowCursor], true
}

func (model orcUIModel) workflowLoaded() bool {
	run, found := model.selectedWorkflow()
	return found && model.workflow.Run.ID == run.ID
}

func (model orcUIModel) selectedTrace() (instance.Session, bool) {
	if session, found := model.selectedSession(); found && firstValue(session.TraceSessionID, session.NativeSessionID) != "" {
		return session, true
	}
	if model.view != orcWorkflowsView {
		return instance.Session{}, false
	}
	run, found := model.selectedWorkflow()
	if !found || model.graphMode && model.workflow.Run.ID != run.ID {
		return instance.Session{}, false
	}
	if node, found := model.selectedNode(); found {
		if node.SessionID == nil {
			return instance.Session{}, false
		}
		wanted := string(*node.SessionID)
		for _, session := range model.sessions {
			if session.ID == wanted && firstValue(session.TraceSessionID, session.NativeSessionID) != "" {
				return session, true
			}
		}
		return instance.Session{}, false
	}
	if run.OrchestrationSession == nil {
		return instance.Session{}, false
	}
	wanted := string(*run.OrchestrationSession)
	for _, session := range model.sessions {
		if session.ID == wanted && firstValue(session.TraceSessionID, session.NativeSessionID) != "" {
			return session, true
		}
	}
	return instance.Session{}, false
}

func (model orcUIModel) maxInspectorOffset() int {
	lines := 0
	if model.view == orcWorkflowsView {
		if model.graphMode {
			lines = len(model.selectedNodeDetailLines())
		} else {
			lines = len(model.workflowDetailLines())
		}
	} else if _, found := model.selectedSession(); found {
		lines = 10
	}
	return max(0, lines-model.inspectorBodyHeight())
}

func (model orcUIModel) inspectorBodyHeight() int {
	if model.inspectorHidden || !model.usesWideLayout() {
		return 0
	}
	workspaceHeight := model.height - 2
	detailHeight := min(12, max(6, workspaceHeight/3))
	return max(1, detailHeight-2)
}

func (model orcUIModel) usesWideLayout() bool {
	return model.width >= 72 && model.height >= 18
}

func (model *orcUIModel) moveToStart() {
	if model.view == orcWorkflowsView {
		if model.graphMode {
			model.selectWorkflowRoot()
			model.inspectorOffset = 0
			return
		}
		if indices := model.matchingWorkflowIndices(); len(indices) > 0 {
			model.workflowCursor = indices[0]
		}
		model.inspectorOffset = 0
		return
	}
	if indices := model.matchingSessionIndices(); len(indices) > 0 {
		model.sessionCursor = indices[0]
	}
	model.inspectorOffset = 0
}

func (model *orcUIModel) moveToEnd() {
	if model.view == orcWorkflowsView {
		if model.graphMode {
			if len(model.workflowNodes()) == 0 {
				model.selectWorkflowRoot()
			} else {
				model.setNodeCursor(len(model.workflowNodes()) - 1)
			}
			model.inspectorOffset = 0
			return
		}
		if indices := model.matchingWorkflowIndices(); len(indices) > 0 {
			model.workflowCursor = indices[len(indices)-1]
		}
		model.inspectorOffset = 0
		return
	}
	if indices := model.matchingSessionIndices(); len(indices) > 0 {
		model.sessionCursor = indices[len(indices)-1]
	}
	model.inspectorOffset = 0
}

func (model orcUIModel) matchingWorkflowIndices() []int {
	query := strings.ToLower(model.query)
	indices := make([]int, 0, len(model.workflows))
	for index, workflow := range model.workflows {
		text := strings.ToLower(string(workflow.ID) + " " + string(workflow.State))
		if query == "" || strings.Contains(text, query) {
			indices = append(indices, index)
		}
	}
	return indices
}

func (model orcUIModel) matchingSessionIndices() []int {
	entries := model.matchingSessionTreeEntries()
	indices := make([]int, 0, len(entries))
	for _, entry := range entries {
		indices = append(indices, entry.sessionIndex)
	}
	return indices
}

func indexPosition(indices []int, selected int) int {
	for position, index := range indices {
		if index == selected {
			return position
		}
	}
	return 0
}

func containsIndex(indices []int, wanted int) bool {
	for _, index := range indices {
		if index == wanted {
			return true
		}
	}
	return false
}

func (model *orcUIModel) loadWorkflows() error {
	if err := model.loadWorkflowRuns(); err != nil {
		return err
	}
	if len(model.workflows) == 0 {
		model.workflow = workflowViewResult{}
		model.definition = workflowmodel.Definition{}
		model.restartPoints = nil
		model.forks = nil
		return nil
	}
	indices := model.matchingWorkflowIndices()
	if len(indices) == 0 {
		model.workflow = workflowViewResult{}
		model.definition = workflowmodel.Definition{}
		model.restartPoints = nil
		model.forks = nil
		return nil
	}
	if !containsIndex(indices, model.workflowCursor) {
		model.workflowCursor = indices[0]
		model.setNodeCursor(0)
	}
	return model.loadSelectedWorkflow()
}

func (model *orcUIModel) loadWorkflowRuns() error {
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
	return nil
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

func (model *orcUIModel) loadWorkers() error {
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
	return nil
}

func (model *orcUIModel) moveRestartPoint(delta int) {
	if model.view != orcWorkflowsView || !model.workflowLoaded() || len(model.restartPoints) == 0 {
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
	sending      bool
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
		if typed.cursor < model.eventCursor {
			break
		}
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
		model.sending = false
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
		resizeTextInput(&model.input, workerInputWidth(model.width, model.input.Prompt))
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
				model.messageError = false
				model.sending = true
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
			if model.sending {
				model.message = "A message is already being sent"
				model.messageError = true
				return model, nil
			}
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
	left := orcTitleStyle.Render("⚔ orc") + "  " + orcTagStyle.Render("worker attachment")
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
		controls := orcTagStyle.Render("  enter send   esc cancel")
		input := model.input
		fieldWidth := max(1, model.width-lipgloss.Width(controls))
		input.Width = workerInputWidth(model.width, input.Prompt)
		after = append(after, ansi.Truncate(input.View(), fieldWidth, "…")+controls)
	} else if model.message != "" {
		style := orcMessageStyle
		if model.messageError {
			style = orcErrorStyle
		}
		after = append(after, style.Render(ansi.Truncate(model.message, model.width, "…")))
	}
	after = append(after, footer)
	separator := "\n\n"
	separatorBlankRows := 1
	if model.height <= 24 {
		separator = "\n"
		separatorBlankRows = 0
	}
	fixedHeight := separatorBlankRows * (len(before) + len(after))
	for _, part := range append(append([]string(nil), before...), after...) {
		fixedHeight += lipgloss.Height(part)
	}
	lines := model.workerEventLines()
	bodyHeight := max(3, model.height-fixedHeight)
	if len(lines) > bodyHeight-2 {
		lines = lines[len(lines)-(bodyHeight-2):]
	}
	for len(lines) < bodyHeight-2 {
		lines = append(lines, "")
	}
	body := orcBox("events", model.width-2, strings.Join(lines, "\n"), true)
	parts := append(before, body)
	parts = append(parts, after...)
	return strings.Join(parts, separator)
}

func workerInputWidth(width int, prompt string) int {
	return max(1, width-ansi.StringWidth("  enter send   esc cancel")-ansi.StringWidth(prompt)-1)
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
