package main

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"sort"
	"strings"
	"syscall"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/api/socket"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/broker"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/config"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/instance"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/store/sqlite"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
)

func main() {
	os.Exit(run(os.Args[1:], os.Stdout, os.Stderr))
}

func run(args []string, stdout io.Writer, stderr io.Writer) int {
	if len(args) == 0 {
		return runOrcaAutoUI(stdout, stderr)
	}
	command := args[0]
	if isOrcaCommand(command) {
		return runOrcaCommand(args, stdout, stderr)
	}
	if command == "mcp" {
		return runMCP(args[1:], os.Stdin, stdout, stderr)
	}
	if command == "view" {
		return runWorkflowView(args[1:], stdout, stderr)
	}
	if command == "events" {
		return runEvents(args[1:], stdout, stderr)
	}
	if kind, offset, found := controlCommandKind(args); found {
		return runControlCommand(kind, args[offset:], stdout, stderr)
	}
	if command != "serve" && command != "inspect" && command != "export" {
		fmt.Fprintf(stderr, "unknown command %q\n", args[0])
		return 2
	}
	flags := flag.NewFlagSet(command, flag.ContinueOnError)
	flags.SetOutput(stderr)
	stateDirectory := flags.String("state-dir", "", "state directory")
	outputPath := flags.String("output", "", "export database path")
	workspace := flags.String("workspace", "", "workspace scope")
	service := flags.String("service", "", "background service identity")
	automatic := flags.Bool("automatic", false, "stop after temporary clients exit")
	if err := flags.Parse(args[1:]); err != nil {
		return 2
	}
	if flags.NArg() != 0 {
		fmt.Fprintf(stderr, "%s accepts no positional arguments\n", command)
		return 2
	}
	if command != "export" && *outputPath != "" {
		fmt.Fprintf(stderr, "%s does not accept --output\n", command)
		return 2
	}
	if command != "serve" && (*workspace != "" || *service != "" || *automatic) {
		fmt.Fprintf(stderr, "%s does not accept serve options\n", command)
		return 2
	}
	if command == "export" && *outputPath == "" {
		fmt.Fprintln(stderr, "export requires --output")
		return 2
	}
	paths, err := resolveOrcaPaths(*stateDirectory)
	if err != nil {
		fmt.Fprintf(stderr, "resolve state paths: %v\n", err)
		return 1
	}
	if command == "serve" {
		scope := *workspace
		if scope == "" {
			scope, err = os.Getwd()
		}
		if err == nil {
			scope, err = instance.Physical(scope)
		}
		if err != nil {
			fmt.Fprintf(stderr, "resolve workspace: %v\n", err)
			return 1
		}
		if err := os.Chdir(scope); err != nil {
			fmt.Fprintf(stderr, "enter workspace: %v\n", err)
			return 1
		}
		record, _, err := instance.NewRecord(scope, *service, *automatic)
		if err != nil {
			fmt.Fprintf(stderr, "prepare instance record: %v\n", err)
			return 1
		}
		record.StateDirectory = paths.StateDirectory
		record.Socket = paths.Socket
		ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
		defer stop()
		if *automatic {
			go monitorAutomaticBroker(ctx, paths.StateDirectory, stop)
		}
		published := false
		serveErr := serveWithReady(ctx, paths, func() error {
			if err := instance.Write(record); err != nil {
				return err
			}
			published = true
			return nil
		})
		if published {
			_ = instance.Remove(record)
		}
		if serveErr != nil {
			fmt.Fprintf(stderr, "serve broker: %v\n", serveErr)
			return 1
		}
		return 0
	}
	encoder := json.NewEncoder(stdout)
	encoder.SetIndent("", "  ")
	if command == "inspect" {
		store, err := sqlite.OpenReadOnly(context.Background(), paths.Database)
		if err != nil {
			fmt.Fprintf(stderr, "open database: %v\n", err)
			return 1
		}
		defer store.Close()
		inspection, err := store.Inspect(context.Background())
		if err != nil {
			fmt.Fprintf(stderr, "inspect database: %v\n", err)
			return 1
		}
		if err := encoder.Encode(inspection); err != nil {
			fmt.Fprintf(stderr, "write inspection: %v\n", err)
			return 1
		}
		return 0
	}
	if err := sqlite.ExportReadOnly(context.Background(), paths.Database, *outputPath); err != nil {
		fmt.Fprintf(stderr, "export database: %v\n", err)
		return 1
	}
	fmt.Fprintln(stdout, *outputPath)
	return 0
}

type workflowViewResult struct {
	Run        domain.WorkflowRun        `json:"run"`
	Definition domain.WorkflowDefinition `json:"definition"`
	Nodes      []domain.NodeRun          `json:"nodes"`
}

func runWorkflowView(args []string, stdout io.Writer, stderr io.Writer) int {
	flags := flag.NewFlagSet("view", flag.ContinueOnError)
	flags.SetOutput(stderr)
	stateDirectory := flags.String("state-dir", "", "state directory")
	runID := flags.String("run", "", "workflow run identifier")
	control := flags.String("control", "", "control action")
	payloadValue := flags.String("payload", "", "control JSON payload or @file")
	if err := flags.Parse(args); err != nil {
		return 2
	}
	if flags.NArg() != 0 || *runID == "" {
		fmt.Fprintln(stderr, "view requires --run and accepts no positional arguments")
		return 2
	}
	if *control == "" && *payloadValue != "" {
		fmt.Fprintln(stderr, "view requires --control when --payload is set")
		return 2
	}
	view, definition, err := loadWorkflowView(*stateDirectory, *runID)
	if err != nil {
		fmt.Fprintf(stderr, "inspect workflow: %v\n", err)
		return 1
	}
	if *control != "" {
		kind, found := workflowViewControlKind(*control)
		if !found {
			fmt.Fprintf(stderr, "view control %q is unsupported\n", *control)
			return 2
		}
		controlPayload, err := readControlPayload(*payloadValue)
		if err != nil {
			fmt.Fprintf(stderr, "read view control payload: %v\n", err)
			return 2
		}
		if err := validateWorkflowViewControl(kind, controlPayload, view); err != nil {
			fmt.Fprintf(stderr, "validate view control %s: %v\n", kind, err)
			return 2
		}
		result, err := executeNativeCommand(*stateDirectory, kind, controlPayload)
		if err != nil {
			fmt.Fprintf(stderr, "execute view control %s: %v\n", kind, err)
			return 1
		}
		fmt.Fprintf(stdout, "control %s [%s]\n", kind, result.State)
		if kind == "workflow.replay" {
			var replay struct {
				Run domain.WorkflowRun `json:"run"`
			}
			if err := json.Unmarshal(result.Result, &replay); err != nil || replay.Run.ID == "" {
				fmt.Fprintf(stderr, "decode replay control result: %v\n", err)
				return 1
			}
			*runID = string(replay.Run.ID)
		}
		view, definition, err = loadWorkflowView(*stateDirectory, *runID)
		if err != nil {
			fmt.Fprintf(stderr, "inspect controlled workflow: %v\n", err)
			return 1
		}
	}
	renderWorkflowView(stdout, view, definition)
	return 0
}

func loadWorkflowView(
	stateDirectory string,
	runID string,
) (workflowViewResult, workflowmodel.Definition, error) {
	payload, err := json.Marshal(struct {
		RunID string `json:"runId"`
	}{RunID: runID})
	if err != nil {
		return workflowViewResult{}, workflowmodel.Definition{}, err
	}
	record, err := executeNativeCommand(stateDirectory, "workflow.inspect", payload)
	if err != nil {
		return workflowViewResult{}, workflowmodel.Definition{}, err
	}
	var view workflowViewResult
	if err := json.Unmarshal(record.Result, &view); err != nil {
		return workflowViewResult{}, workflowmodel.Definition{}, err
	}
	var definition workflowmodel.Definition
	if err := json.Unmarshal(view.Definition.ResolvedDocument, &definition); err != nil {
		return workflowViewResult{}, workflowmodel.Definition{}, err
	}
	if view.Definition.DefinitionSchemaVersion == workflowmodel.LegacyDefinitionSchemaVersion {
		if err := workflowmodel.UpgradeLegacyDefinition(
			view.Definition.DefinitionSchemaVersion, view.Definition.EvaluatorVersion, &definition,
		); err != nil {
			return workflowViewResult{}, workflowmodel.Definition{}, err
		}
	}
	return view, definition, nil
}

func validateWorkflowViewControl(
	kind string,
	payload json.RawMessage,
	view workflowViewResult,
) error {
	var document map[string]json.RawMessage
	if err := json.Unmarshal(payload, &document); err != nil {
		return err
	}
	wantRunID := string(view.Run.ID)
	switch kind {
	case "graph.patch":
		return requireViewTarget(document, "workflowRunId", wantRunID)
	case "workflow.replay":
		return requireViewTarget(document, "parentWorkflowRunId", wantRunID)
	case "effect.reconcile":
		return requireViewTarget(document, "workflowRunId", wantRunID)
	case "agent.attach", "agent.detach", "agent.intervene", "agent.policy":
		var intervention map[string]json.RawMessage
		if err := json.Unmarshal(document["intervention"], &intervention); err != nil {
			return errors.New("control intervention is required")
		}
		var sessionID string
		if err := json.Unmarshal(intervention["sessionId"], &sessionID); err != nil {
			return errors.New("control session is required")
		}
		for _, node := range view.Nodes {
			if node.SessionID != nil && string(*node.SessionID) == sessionID {
				return nil
			}
		}
		return errors.New("control session does not belong to the displayed run")
	case "provenance.relation":
		for _, field := range []string{"from", "to"} {
			var reference domain.ResourceReference
			if err := json.Unmarshal(document[field], &reference); err == nil &&
				reference.Kind == "workflow-run" && reference.ID == wantRunID {
				return nil
			}
		}
		return errors.New("provenance relation does not name the displayed run")
	default:
		return errors.New("view control is unsupported")
	}
}

func requireViewTarget(document map[string]json.RawMessage, field string, want string) error {
	var value string
	if err := json.Unmarshal(document[field], &value); err != nil || value != want {
		return fmt.Errorf("%s must equal the displayed run", field)
	}
	return nil
}

func workflowViewControlKind(control string) (string, bool) {
	kinds := map[string]string{
		"graph patch": "graph.patch", "replay run": "workflow.replay",
		"agent attach": "agent.attach", "agent detach": "agent.detach",
		"agent intervene": "agent.intervene", "agent policy": "agent.policy",
		"provenance relation": "provenance.relation", "effect reconcile": "effect.reconcile",
	}
	kind, found := kinds[control]
	return kind, found
}

func executeNativeCommand(
	stateDirectory string,
	kind string,
	payload json.RawMessage,
) (domain.CommandRecord, error) {
	commandID, err := localCommandID()
	if err != nil {
		return domain.CommandRecord{}, err
	}
	paths, err := resolveOrcaPaths(stateDirectory)
	if err != nil {
		return domain.CommandRecord{}, err
	}
	client, err := socket.NewClient(paths.Socket)
	if err != nil {
		return domain.CommandRecord{}, err
	}
	defer client.Close()
	return client.Command(context.Background(), domain.CommandRequest{
		ID: domain.CommandID(commandID), IdempotencyKey: "view-" + commandID,
		Kind: kind, Payload: payload,
	})
}

func renderWorkflowView(stdout io.Writer, view workflowViewResult, definition workflowmodel.Definition) {
	fmt.Fprintf(
		stdout, "run %s [%s] definition=%s version=%d\n",
		view.Run.ID, view.Run.State, view.Run.WorkflowDefinition, view.Run.DefinitionVersion,
	)
	nodes := append([]domain.NodeRun(nil), view.Nodes...)
	sort.Slice(nodes, func(first int, second int) bool { return nodes[first].NodeKey < nodes[second].NodeKey })
	fmt.Fprintln(stdout, "nodes:")
	for _, node := range nodes {
		session := "-"
		if node.SessionID != nil {
			session = string(*node.SessionID)
		}
		policy := definition.Nodes[node.NodeKey].Policy
		fmt.Fprintf(
			stdout, "  %s [%s] adapter=%s policy=%s/%s/%s attempt=%d repair=%d session=%s\n",
			node.NodeKey, node.State, node.Adapter,
			policy.Approvals, policy.Filesystem, policy.Network,
			node.Attempt, node.RepairAttempt, session,
		)
	}
	edges := append([]workflowmodel.Edge(nil), definition.Edges...)
	sort.Slice(edges, func(first int, second int) bool { return edges[first].ID < edges[second].ID })
	fmt.Fprintln(stdout, "edges:")
	for _, edge := range edges {
		requirement := "optional"
		if edge.Required {
			requirement = "required"
		}
		fmt.Fprintf(
			stdout, "  %s: %s.%s -> %s.%s [%s]\n",
			edge.ID, edge.From, edge.FromPort, edge.To, edge.ToPort, requirement,
		)
	}
	loops := append([]workflowmodel.Loop(nil), definition.Loops...)
	sort.Slice(loops, func(first int, second int) bool { return loops[first].ID < loops[second].ID })
	if len(loops) != 0 {
		fmt.Fprintln(stdout, "loops:")
		for _, loop := range loops {
			fmt.Fprintf(
				stdout, "  %s: back-edge=%s iterations=%d stalls=%d\n",
				loop.ID, loop.BackEdge, loop.IterationLimit, loop.StallLimit,
			)
		}
	}
	fmt.Fprintln(stdout, "controls: graph patch | replay run | agent attach | agent detach | agent intervene | agent policy | provenance relation | effect reconcile")
}

func controlCommandKind(args []string) (string, int, bool) {
	if len(args) < 2 {
		return "", 0, false
	}
	key := args[0] + " " + args[1]
	kinds := map[string]string{
		"planning discover":        "planning.discover",
		"planning snapshot":        "planning.snapshot",
		"planning action":          "planning.action",
		"adapter invoke":           "adapter.invoke",
		"workflow create":          "workflow.create",
		"workflow run":             "workflow.run",
		"workflow list":            "workflow.list",
		"workflow schedule":        "workflow.schedule",
		"workflow inspect":         "workflow.inspect",
		"workflow export":          "workflow.export",
		"workflow restart-point":   "workflow.restart-point",
		"graph patch":              "graph.patch",
		"replay run":               "workflow.replay",
		"agent start":              "agent.start",
		"agent attach":             "agent.attach",
		"agent detach":             "agent.detach",
		"agent intervene":          "agent.intervene",
		"agent policy":             "agent.policy",
		"agent cancel":             "agent.cancel",
		"agent history":            "agent.history",
		"workspace snapshot":       "workspace.snapshot",
		"artifact resolve":         "artifact.resolve",
		"verification submit":      "verification.submit",
		"verification task-record": "verification.task-record",
		"verification record":      "verification.record",
		"verification admit":       "verification.admit",
		"effect reconcile":         "effect.reconcile",
		"provenance commit":        "provenance.commit",
		"provenance relation":      "provenance.relation",
		"provenance inspect":       "provenance.inspect",
		"broker inspect":           "broker.inspect",
	}
	kind, found := kinds[key]
	return kind, 2, found
}

func runControlCommand(kind string, args []string, stdout io.Writer, stderr io.Writer) int {
	flags := flag.NewFlagSet(kind, flag.ContinueOnError)
	flags.SetOutput(stderr)
	stateDirectory := flags.String("state-dir", "", "state directory")
	payloadValue := flags.String("payload", "", "JSON payload or @file")
	commandID := flags.String("id", "", "command identifier")
	idempotencyKey := flags.String("idempotency-key", "", "idempotency key")
	expectedVersion := flags.Uint64("expected-version", 0, "expected resource version")
	if err := flags.Parse(args); err != nil {
		return 2
	}
	if flags.NArg() != 0 {
		fmt.Fprintf(stderr, "%s accepts no positional arguments\n", kind)
		return 2
	}
	payload, err := readControlPayload(*payloadValue)
	if err != nil {
		fmt.Fprintf(stderr, "read command payload: %v\n", err)
		return 2
	}
	if *commandID == "" {
		*commandID, err = localCommandID()
		if err != nil {
			fmt.Fprintf(stderr, "create command identifier: %v\n", err)
			return 1
		}
	}
	if *idempotencyKey == "" {
		*idempotencyKey = "cli-" + *commandID
	}
	paths, err := resolveOrcaPaths(*stateDirectory)
	if err != nil {
		fmt.Fprintf(stderr, "resolve state paths: %v\n", err)
		return 1
	}
	client, err := socket.NewClient(paths.Socket)
	if err != nil {
		fmt.Fprintf(stderr, "create broker client: %v\n", err)
		return 1
	}
	defer client.Close()
	request := domain.CommandRequest{
		ID: domain.CommandID(*commandID), IdempotencyKey: *idempotencyKey,
		Kind: kind, Payload: payload,
	}
	if *expectedVersion != 0 {
		value := domain.ResourceVersion(*expectedVersion)
		request.ExpectedVersion = &value
	}
	record, err := client.Command(context.Background(), request)
	if err != nil {
		fmt.Fprintf(stderr, "execute %s: %v\n", kind, err)
		return 1
	}
	encoder := json.NewEncoder(stdout)
	encoder.SetEscapeHTML(false)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(record); err != nil {
		fmt.Fprintf(stderr, "write command result: %v\n", err)
		return 1
	}
	return 0
}

func readControlPayload(value string) (json.RawMessage, error) {
	if value == "" {
		return json.RawMessage(`{}`), nil
	}
	var payload []byte
	if strings.HasPrefix(value, "@") {
		file, err := os.Open(strings.TrimPrefix(value, "@"))
		if err != nil {
			return nil, err
		}
		defer file.Close()
		payload, err = io.ReadAll(io.LimitReader(file, 1<<20+1))
		if err != nil {
			return nil, err
		}
		if len(payload) > 1<<20 {
			return nil, fmt.Errorf("payload exceeds 1048576 bytes")
		}
	} else {
		payload = []byte(value)
	}
	if !json.Valid(payload) {
		return nil, fmt.Errorf("payload is not valid JSON")
	}
	return append(json.RawMessage(nil), payload...), nil
}

func localCommandID() (string, error) {
	value := make([]byte, 12)
	if _, err := rand.Read(value); err != nil {
		return "", err
	}
	return fmt.Sprintf("command-%x", value), nil
}

func runEvents(args []string, stdout io.Writer, stderr io.Writer) int {
	flags := flag.NewFlagSet("events", flag.ContinueOnError)
	flags.SetOutput(stderr)
	stateDirectory := flags.String("state-dir", "", "state directory")
	after := flags.Uint64("after", 0, "event cursor")
	limit := flags.Uint("limit", 100, "event limit")
	if err := flags.Parse(args); err != nil {
		return 2
	}
	if flags.NArg() != 0 || *limit == 0 || *limit > 1000 {
		fmt.Fprintln(stderr, "events requires a limit from 1 through 1000")
		return 2
	}
	paths, err := resolveOrcaPaths(*stateDirectory)
	if err != nil {
		fmt.Fprintf(stderr, "resolve state paths: %v\n", err)
		return 1
	}
	client, err := socket.NewClient(paths.Socket)
	if err != nil {
		fmt.Fprintf(stderr, "create broker client: %v\n", err)
		return 1
	}
	defer client.Close()
	events, err := client.Events(context.Background(), domain.EventCursor(*after), uint32(*limit))
	if err != nil {
		fmt.Fprintf(stderr, "read broker events: %v\n", err)
		return 1
	}
	encoder := json.NewEncoder(stdout)
	encoder.SetEscapeHTML(false)
	for _, event := range events {
		if err := encoder.Encode(event); err != nil {
			fmt.Fprintf(stderr, "write broker event: %v\n", err)
			return 1
		}
	}
	return 0
}

func serve(ctx context.Context, paths config.Paths) error {
	return serveWithReady(ctx, paths, nil)
}

func serveWithReady(ctx context.Context, paths config.Paths, ready func() error) error {
	if err := sqlite.PrepareStateDirectory(paths.StateDirectory); err != nil {
		return err
	}
	ownership, err := socket.AcquireOwnership(paths.Socket)
	if err != nil {
		return err
	}
	defer ownership.Close()
	store, err := sqlite.Open(ctx, paths.Database)
	if err != nil {
		return err
	}
	defer store.Close()
	eventRecorder, err := broker.NewPluginEventRecorder(store)
	if err != nil {
		return err
	}
	pluginHost, err := plugin.NewHost(plugin.PlatformIsolation{}, eventRecorder)
	if err != nil {
		return err
	}
	defer pluginHost.Close()
	sessions, err := broker.NewSessionService(store, pluginHost)
	if err != nil {
		return err
	}
	pluginConfigs, err := resolvePluginConfigs(paths)
	if err != nil {
		return err
	}
	if err := recoverRuntime(ctx, store, pluginHost, sessions, pluginConfigs); err != nil {
		return err
	}
	adapters, err := broker.NewAdapterService(store, pluginHost)
	if err != nil {
		return err
	}
	control, err := broker.NewControlExecutor(store, adapters, sessions, pluginHost)
	if err != nil {
		return err
	}
	commands, err := broker.NewCommandService(store, control)
	if err != nil {
		return err
	}
	eventSyncErrors := make(chan error, 1)
	go func() {
		if err := sessions.RunEventSync(ctx, 250*time.Millisecond); err != nil && ctx.Err() == nil {
			eventSyncErrors <- err
		}
	}()
	server, err := socket.OpenOwned(paths.Socket, ownership, commands, store)
	if err != nil {
		return err
	}
	if ready != nil {
		if err := ready(); err != nil {
			_ = server.Close(context.Background())
			return err
		}
	}
	serveErrors := make(chan error, 1)
	go func() {
		serveErrors <- server.Serve()
	}()
	select {
	case err := <-serveErrors:
		return err
	case err := <-eventSyncErrors:
		return fmt.Errorf("synchronize runtime events: %w", err)
	case <-ctx.Done():
		shutdownContext, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		return server.Close(shutdownContext)
	}
}

func recoverRuntime(
	ctx context.Context,
	store *sqlite.Store,
	host *plugin.Host,
	sessions *broker.SessionService,
	configured []plugin.Config,
) error {
	storedHandles, err := store.RecoverableAdapterHandles(ctx)
	if err != nil {
		return err
	}
	var activationErr error
	for _, config := range configured {
		handles := make([]plugin.HandleDescriptor, 0)
		for _, handle := range storedHandles {
			if handle.PluginID != config.ID {
				continue
			}
			handles = append(handles, plugin.HandleDescriptor{
				ID: handle.ID, PluginID: handle.PluginID, Port: handle.Port,
				AdapterID: handle.AdapterID, FormatVersion: handle.FormatVersion,
				OpaqueValue: append(json.RawMessage(nil), handle.OpaqueValue...),
			})
		}
		if _, err := host.Recover(ctx, config, handles); err != nil {
			activationErr = errors.Join(activationErr, fmt.Errorf("recover plugin %s: %w", config.ID, err))
		}
	}
	_, recoveryErr := sessions.RecoverSessions(ctx)
	return errors.Join(activationErr, recoveryErr)
}

func resolvePluginConfigs(paths config.Paths) ([]plugin.Config, error) {
	configurationPath := os.Getenv("COLCHIS_PLUGIN_CONFIG")
	if configurationPath == "" {
		configurationPath = paths.Plugins
	}
	file, err := os.Open(configurationPath)
	if err == nil {
		defer file.Close()
		decoder := json.NewDecoder(io.LimitReader(file, 1<<20))
		decoder.DisallowUnknownFields()
		var configured []plugin.Config
		if err := decoder.Decode(&configured); err != nil {
			return nil, fmt.Errorf("decode plugin configuration: %w", err)
		}
		if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
			return nil, fmt.Errorf("decode plugin configuration: trailing data")
		}
		seen := make(map[domain.PluginID]struct{}, len(configured))
		for _, item := range configured {
			if _, found := seen[item.ID]; found {
				return nil, fmt.Errorf("decode plugin configuration: duplicate plugin %s", item.ID)
			}
			seen[item.ID] = struct{}{}
		}
		return configured, nil
	}
	if !errors.Is(err, os.ErrNotExist) {
		return nil, fmt.Errorf("open plugin configuration: %w", err)
	}
	defaultConfig, err := resolveDefaultSysinitPluginConfig(paths)
	if err != nil || defaultConfig == nil {
		return nil, err
	}
	return []plugin.Config{*defaultConfig}, nil
}

func resolveDefaultSysinitPluginConfig(paths config.Paths) (*plugin.Config, error) {
	executable := os.Getenv("COLCHIS_SYSINIT_PLUGIN")
	if executable == "" {
		ownerExecutable, err := os.Executable()
		if err != nil {
			return nil, fmt.Errorf("resolve broker executable: %w", err)
		}
		candidate := filepath.Join(filepath.Dir(ownerExecutable), "colchis-plugin-sysinit")
		if info, statErr := os.Stat(candidate); statErr == nil && info.Mode().IsRegular() && info.Mode()&0o111 != 0 {
			executable = candidate
		} else {
			executable, _ = exec.LookPath("colchis-plugin-sysinit")
		}
	}
	if executable == "" {
		return nil, nil
	}
	absolute, err := filepath.Abs(executable)
	if err != nil {
		return nil, fmt.Errorf("resolve sysinit plugin: %w", err)
	}
	workingDirectory, err := os.Getwd()
	if err != nil {
		return nil, fmt.Errorf("resolve broker working directory: %w", err)
	}
	runtimeDirectory := filepath.Join(paths.StateDirectory, "runtime")
	cacheDirectory := filepath.Join(runtimeDirectory, "cache")
	configDirectory := filepath.Join(runtimeDirectory, "config")
	homeDirectory := filepath.Join(runtimeDirectory, "home")
	temporaryDirectory := filepath.Join(runtimeDirectory, "tmp")
	if err := os.MkdirAll(cacheDirectory, 0o700); err != nil {
		return nil, fmt.Errorf("create plugin runtime directory: %w", err)
	}
	if err := os.MkdirAll(configDirectory, 0o700); err != nil {
		return nil, fmt.Errorf("create plugin configuration directory: %w", err)
	}
	if err := os.MkdirAll(homeDirectory, 0o700); err != nil {
		return nil, fmt.Errorf("create plugin home directory: %w", err)
	}
	if err := os.MkdirAll(temporaryDirectory, 0o700); err != nil {
		return nil, fmt.Errorf("create plugin temporary directory: %w", err)
	}
	containsState, err := directoryContains(workingDirectory, paths.StateDirectory)
	if err != nil {
		return nil, fmt.Errorf("compare plugin workspace and broker state: %w", err)
	}
	if containsState {
		return nil, fmt.Errorf("broker state directory must be outside the plugin workspace")
	}
	environment := map[string]string{
		"COLCHIS_RUNTIME_DIRECTORY": runtimeDirectory,
		"NIX_CONFIG":                "experimental-features = nix-command flakes",
		"NIX_SENTRY_ENDPOINT":       "",
		"NIX_USER_CONF_FILES":       "",
		"PATH":                      os.Getenv("PATH"),
		"TMPDIR":                    temporaryDirectory,
		"XDG_CACHE_HOME":            cacheDirectory,
		"XDG_CONFIG_HOME":           configDirectory,
	}
	if stateHome := os.Getenv("XDG_STATE_HOME"); stateHome != "" {
		environment["XDG_STATE_HOME"] = stateHome
	}
	readPaths := []string{workingDirectory, runtimeDirectory}
	writePaths := []string{workingDirectory, runtimeDirectory}
	readPaths = append(readPaths, resolveGitAdministrativePaths(workingDirectory)...)
	if seshyDirectory := resolveSeshyStateDirectory(); seshyDirectory != "" {
		readPaths = append(readPaths, seshyDirectory)
		writePaths = append(writePaths, seshyDirectory)
	}
	localSocketPaths := []string{}
	if nixSocket := resolveNixDaemonSocket(); nixSocket != "" {
		localSocketPaths = append(localSocketPaths, nixSocket)
	}
	return &plugin.Config{
		ID: "sysinit",
		Profile: plugin.IsolationProfile{
			Executable: absolute, WorkingDirectory: workingDirectory, HomeDirectory: homeDirectory,
			ReadPaths:           readPaths,
			WritePaths:          writePaths,
			Environment:         environment,
			LocalSocketPaths:    localSocketPaths,
			DangerouslyAllowAll: os.Getenv("COLCHIS_DANGEROUSLY_ALLOW_ALL") == "1",
		},
		Restart: plugin.RestartPolicy{
			MaxAttempts: 3, InitialBackoff: 100 * time.Millisecond, MaxBackoff: time.Second,
			CircuitOpenPeriod: 30 * time.Second,
		},
		Limits: plugin.WireLimits{
			MaxMessageBytes: 1 << 20, MaxEventsPerSecond: 100, MaxOperationSeconds: 3600,
		},
	}, nil
}

func resolveNixDaemonSocket() string {
	for _, path := range []string{
		"/nix/var/nix/daemon-socket/socket",
		"/run/nix/daemon-socket/socket",
		"/var/run/nix-daemon.socket",
	} {
		if info, err := os.Stat(path); err == nil && info.Mode()&os.ModeSocket != 0 {
			return path
		}
	}
	return ""
}

func resolveGitAdministrativePaths(workingDirectory string) []string {
	command := exec.Command(
		"git", "-C", workingDirectory, "rev-parse", "--path-format=absolute", "--git-dir", "--git-common-dir",
	)
	output, err := command.Output()
	if err != nil {
		return nil
	}
	paths := make([]string, 0, 2)
	seen := make(map[string]struct{}, 2)
	for _, value := range strings.Fields(string(output)) {
		path := filepath.Clean(value)
		if !filepath.IsAbs(path) {
			continue
		}
		if _, found := seen[path]; found {
			continue
		}
		seen[path] = struct{}{}
		paths = append(paths, path)
	}
	return paths
}

func resolveSeshyStateDirectory() string {
	stateHome := os.Getenv("XDG_STATE_HOME")
	if stateHome == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			return ""
		}
		stateHome = filepath.Join(home, ".local", "state")
	}
	directory := filepath.Join(stateHome, "seshy")
	if info, err := os.Stat(directory); err == nil && info.IsDir() {
		absolute, err := filepath.Abs(directory)
		if err == nil {
			return absolute
		}
	}
	return ""
}

func directoryContains(parent string, child string) (bool, error) {
	canonicalParent, err := filepath.EvalSymlinks(parent)
	if err != nil {
		return false, err
	}
	canonicalChild, err := filepath.EvalSymlinks(child)
	if err != nil {
		return false, err
	}
	relative, err := filepath.Rel(canonicalParent, canonicalChild)
	if err != nil {
		return false, err
	}
	return relative == "." || relative != ".." && !strings.HasPrefix(relative, ".."+string(filepath.Separator)), nil
}
