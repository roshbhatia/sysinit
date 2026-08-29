package main

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
	"time"

	"github.com/charmbracelet/bubbles/help"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/x/ansi"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/nix"
	openspecadapter "github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/openspec"
	piadapter "github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/pi"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/seshy"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/api/socket"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/broker"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/config"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/instance"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/store/sqlite"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
	"github.com/roshbhatia/sysinit/pkgs/internal/agents"
	_ "modernc.org/sqlite"
)

const smokePluginEnvironment = "COLCHIS_SMOKE_PLUGIN"

func TestMain(tests *testing.M) {
	if os.Getenv(smokePluginEnvironment) == "1" {
		os.Exit(runSmokePlugin())
	}
	os.Exit(tests.Run())
}

func runSmokePlugin() int {
	planningManifest, err := openspecadapter.Manifest()
	if err != nil {
		_, _ = fmt.Fprintln(os.Stderr, err)
		return 1
	}
	workspaceManifests, err := seshy.Manifests()
	if err != nil {
		_, _ = fmt.Fprintln(os.Stderr, err)
		return 1
	}
	var workspaceManifest plugin.AdapterManifest
	for _, manifest := range workspaceManifests {
		if manifest.ID == seshy.WorkspaceAdapterID {
			workspaceManifest = manifest
		}
	}
	environmentManifest, err := nix.Manifest()
	if err != nil {
		_, _ = fmt.Fprintln(os.Stderr, err)
		return 1
	}
	runtimeManifests, err := piadapter.Manifests()
	if err != nil {
		_, _ = fmt.Fprintln(os.Stderr, err)
		return 1
	}
	var runtimeManifest plugin.AdapterManifest
	for _, manifest := range runtimeManifests {
		if manifest.ID == piadapter.RuntimeAdapterID {
			runtimeManifest = manifest
		}
	}
	runtimeManifest.Capabilities = []string{"structured-result", "job-policy", "live-input"}
	digest := "sha256:042593f8c06f3af13910448e80b07865b66db137c16a125291699564732eac88"
	server, err := plugin.NewServer(plugin.ServerConfig{
		PluginID: "smoke",
		Adapters: []plugin.AdapterManifest{
			planningManifest, workspaceManifest, environmentManifest, runtimeManifest,
		},
		Invoke: func(
			_ context.Context,
			envelope plugin.OperationEnvelope,
			_ plugin.EventEmitter,
		) (plugin.OperationResult, error) {
			result := plugin.OperationResult{
				ID: envelope.ID, State: domain.OperationStateSucceeded,
			}
			switch envelope.Operation {
			case "planning.discover":
				result.Output = json.RawMessage(`{"framework":"openspec","schemas":[{"id":"spec-driven","declaredArtifacts":[],"templateArtifacts":[],"sourceDigest":"` + digest + `","opaqueSourceData":{}}],"sourceDigest":"` + digest + `","opaqueSourceData":{}}`)
			case "planning.snapshot":
				result.Output = json.RawMessage(`{"framework":"openspec","change":"build-composable-agent-harness","schemaId":"spec-driven","sourceDigest":"` + digest + `","artifacts":[],"actions":[],"context":[],"workItems":[],"gates":[],"opaqueSourceData":{}}`)
			case "workspace.snapshot":
				result.Output = json.RawMessage(`{"workspace":{"name":"smoke","path":"/tmp/smoke","repositories":[]},"sourceDigest":"` + digest + `"}`)
			case "environment.check":
				result.Output = json.RawMessage(`{"environmentId":"` + digest + `","snapshotDigest":"` + digest + `","checks":[{"name":"unit-tests","exitCode":0,"build":[],"stderr":""}]}`)
			case "agent-runtime.start":
				result.Output = json.RawMessage(`{"state":"running","capabilities":{"liveInput":true,"queuedInput":true,"interrupt":true,"resume":true,"nativeAttachment":true}}`)
				result.Handle = &plugin.AdapterHandleValue{
					FormatVersion: 1, OpaqueValue: json.RawMessage(`{"session":"smoke-pi"}`),
				}
				result.SessionState = domain.SessionStateRunning
			default:
				return plugin.OperationResult{}, fmt.Errorf("unsupported smoke operation %s", envelope.Operation)
			}
			return result, nil
		},
	})
	if err != nil {
		_, _ = fmt.Fprintln(os.Stderr, err)
		return 1
	}
	if err := server.Serve(context.Background(), os.Stdin, os.Stdout); err != nil {
		_, _ = fmt.Fprintln(os.Stderr, err)
		return 1
	}
	return 0
}

func TestDefaultPluginProfileExcludesBrokerState(t *testing.T) {
	executable, err := os.Executable()
	if err != nil {
		t.Fatalf("os.Executable() returned %v", err)
	}
	t.Setenv("COLCHIS_SYSINIT_PLUGIN", executable)
	paths, err := config.ResolvePaths(t.TempDir())
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	if err := os.MkdirAll(paths.StateDirectory, 0o700); err != nil {
		t.Fatalf("MkdirAll() returned %v", err)
	}
	if err := os.WriteFile(paths.Database, []byte("fixture"), 0o600); err != nil {
		t.Fatalf("WriteFile() database returned %v", err)
	}
	configured, err := resolveDefaultSysinitPluginConfig(paths)
	if err != nil {
		t.Fatalf("resolveDefaultSysinitPluginConfig() returned %v", err)
	}
	for _, path := range append(configured.Profile.ReadPaths, configured.Profile.WritePaths...) {
		containsDatabase, err := directoryContains(path, paths.Database)
		if err == nil && containsDatabase {
			t.Fatalf("plugin path %q contains broker database", path)
		}
	}
	if endpoint, found := configured.Profile.Environment["NIX_SENTRY_ENDPOINT"]; !found || endpoint != "" {
		t.Fatalf("NIX_SENTRY_ENDPOINT = %q, %t", endpoint, found)
	}
	for _, name := range []string{"TMPDIR", "XDG_CACHE_HOME", "XDG_CONFIG_HOME"} {
		value := configured.Profile.Environment[name]
		if !strings.HasPrefix(value, filepath.Join(paths.StateDirectory, "runtime")+string(filepath.Separator)) {
			t.Fatalf("%s = %q", name, value)
		}
	}
	if !strings.HasPrefix(configured.Profile.HomeDirectory, filepath.Join(paths.StateDirectory, "runtime")) {
		t.Fatalf("home directory = %q", configured.Profile.HomeDirectory)
	}
	if socket := resolveNixDaemonSocket(); socket != "" && len(configured.Profile.LocalSocketPaths) != 1 {
		t.Fatalf("local socket paths = %#v", configured.Profile.LocalSocketPaths)
	}
	readPaths := make(map[string]struct{}, len(configured.Profile.ReadPaths))
	for _, path := range configured.Profile.ReadPaths {
		readPaths[path] = struct{}{}
	}
	for _, path := range resolveGitAdministrativePaths(configured.Profile.WorkingDirectory) {
		if _, found := readPaths[path]; !found {
			t.Fatalf("plugin profile cannot read Git administrative path %q", path)
		}
	}
}

func TestPluginConfigurationLoadsMultipleProviders(t *testing.T) {
	configurationPath := filepath.Join(t.TempDir(), "plugins.json")
	configured := []plugin.Config{
		{ID: "sysinit", Profile: plugin.IsolationProfile{Executable: "/bin/one"}},
		{
			ID:      "external-runtime",
			Profile: plugin.IsolationProfile{Executable: "/bin/two", DangerouslyAllowAll: true},
		},
	}
	payload, err := json.Marshal(configured)
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	if err := os.WriteFile(configurationPath, payload, 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	t.Setenv("COLCHIS_PLUGIN_CONFIG", configurationPath)
	paths, err := config.ResolvePaths(t.TempDir())
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	loaded, err := resolvePluginConfigs(paths)
	if err != nil {
		t.Fatalf("resolvePluginConfigs() returned %v", err)
	}
	if len(loaded) != 2 || loaded[0].ID != "sysinit" || loaded[1].ID != "external-runtime" ||
		!loaded[1].Profile.DangerouslyAllowAll {
		t.Fatalf("loaded plugin configuration = %#v", loaded)
	}
}

func TestDefaultPluginProfileRequiresDangerousOptIn(t *testing.T) {
	executable, err := os.Executable()
	if err != nil {
		t.Fatalf("os.Executable() returned %v", err)
	}
	t.Setenv("COLCHIS_SYSINIT_PLUGIN", executable)
	paths, err := config.ResolvePaths(t.TempDir())
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	configured, err := resolveDefaultSysinitPluginConfig(paths)
	if err != nil {
		t.Fatalf("resolveDefaultSysinitPluginConfig() returned %v", err)
	}
	if configured.Profile.DangerouslyAllowAll {
		t.Fatal("default plugin profile bypasses isolation")
	}
	t.Setenv("COLCHIS_DANGEROUSLY_ALLOW_ALL", "1")
	configured, err = resolveDefaultSysinitPluginConfig(paths)
	if err != nil {
		t.Fatalf("dangerous resolveDefaultSysinitPluginConfig() returned %v", err)
	}
	if !configured.Profile.DangerouslyAllowAll {
		t.Fatal("dangerous plugin profile remains confined")
	}
}

func TestControlCommandMapsAgentPolicy(t *testing.T) {
	t.Parallel()

	kind, consumed, found := controlCommandKind([]string{"agent", "policy"})
	if !found || kind != "agent.policy" || consumed != 2 {
		t.Fatalf("controlCommandKind() = %q, %d, %t", kind, consumed, found)
	}
}

func TestControlCommandMapsEffectReconciliation(t *testing.T) {
	t.Parallel()

	kind, consumed, found := controlCommandKind([]string{"effect", "reconcile"})
	if !found || kind != "effect.reconcile" || consumed != 2 {
		t.Fatalf("controlCommandKind() = %q, %d, %t", kind, consumed, found)
	}
}

func TestRunInspectsConfiguredDatabase(t *testing.T) {
	t.Parallel()

	stateDirectory := t.TempDir()
	paths, err := config.ResolvePaths(stateDirectory)
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	store, err := sqlite.Open(context.Background(), paths.Database)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}

	var stdout bytes.Buffer
	var stderr bytes.Buffer
	if exitCode := run([]string{"inspect", "--state-dir", stateDirectory}, &stdout, &stderr); exitCode != 0 {
		t.Fatalf("run() exit code = %d, stderr = %q", exitCode, stderr.String())
	}
	var inspection sqlite.Inspection
	if err := json.Unmarshal(stdout.Bytes(), &inspection); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if inspection.Path != filepath.Join(stateDirectory, "broker.db") || inspection.Integrity != "ok" {
		t.Fatalf("run() output = %#v", inspection)
	}
}

func TestRunAvoidsPersistentInspectionCache(t *testing.T) {
	cacheHome := t.TempDir()
	t.Setenv("HOME", cacheHome)
	t.Setenv("XDG_CACHE_HOME", cacheHome)
	stateDirectory := t.TempDir()
	paths, err := config.ResolvePaths(stateDirectory)
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	store, err := sqlite.Open(context.Background(), paths.Database)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}

	var stdout bytes.Buffer
	var stderr bytes.Buffer
	if exitCode := run([]string{"inspect", "--state-dir", stateDirectory}, &stdout, &stderr); exitCode != 0 {
		t.Fatalf("run() exit code = %d, stderr = %q", exitCode, stderr.String())
	}
	if _, err := os.Stat(filepath.Join(cacheHome, "colchis")); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("owner cache stat error = %v", err)
	}
}

func TestRunAvoidsPersistentExportCache(t *testing.T) {
	cacheHome := t.TempDir()
	t.Setenv("HOME", cacheHome)
	t.Setenv("XDG_CACHE_HOME", cacheHome)
	stateDirectory := t.TempDir()
	paths, err := config.ResolvePaths(stateDirectory)
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	store, err := sqlite.Open(context.Background(), paths.Database)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}

	var stdout bytes.Buffer
	var stderr bytes.Buffer
	exportPath := filepath.Join(t.TempDir(), "export.sqlite3")
	if exitCode := run(
		[]string{"export", "--state-dir", stateDirectory, "--output", exportPath},
		&stdout,
		&stderr,
	); exitCode != 0 {
		t.Fatalf("run() exit code = %d, stderr = %q", exitCode, stderr.String())
	}
	if _, err := os.Stat(filepath.Join(cacheHome, "colchis")); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("owner cache stat error = %v", err)
	}
}

func TestRunInspectsReadOnlyStateDirectory(t *testing.T) {
	t.Parallel()

	stateDirectory := t.TempDir()
	paths, err := config.ResolvePaths(stateDirectory)
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	store, err := sqlite.Open(context.Background(), paths.Database)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	if err := os.Chmod(stateDirectory, 0o500); err != nil {
		t.Fatalf("Chmod() returned %v", err)
	}
	defer os.Chmod(stateDirectory, 0o700)

	var stdout bytes.Buffer
	var stderr bytes.Buffer
	if exitCode := run([]string{"inspect", "--state-dir", stateDirectory}, &stdout, &stderr); exitCode != 0 {
		t.Fatalf("run() exit code = %d, stderr = %q", exitCode, stderr.String())
	}
	if _, err := os.Stat(filepath.Join(stateDirectory, fmt.Sprintf(".colchis-readonly-%d", os.Geteuid()))); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("state scratch stat error = %v", err)
	}
}

func TestServeCreatesBrokerSocket(t *testing.T) {
	stateDirectory := shortStateDirectory(t)
	paths, err := config.ResolvePaths(stateDirectory)
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	errors := make(chan error, 1)
	go func() {
		errors <- serve(ctx, paths)
	}()
	deadline := time.Now().Add(5 * time.Second)
	for {
		if info, err := os.Stat(paths.Socket); err == nil && info.Mode()&os.ModeSocket != 0 {
			break
		}
		if time.Now().After(deadline) {
			cancel()
			<-errors
			t.Fatal("serve() did not create the broker socket")
		}
		time.Sleep(10 * time.Millisecond)
	}
	cancel()
	if err := <-errors; err != nil {
		t.Fatalf("serve() returned %v", err)
	}
}

func TestRunUsesNativeBrokerCommandsAndEvents(t *testing.T) {
	stateDirectory := shortStateDirectory(t)
	paths, err := config.ResolvePaths(stateDirectory)
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	serveErrors := make(chan error, 1)
	go func() { serveErrors <- serve(ctx, paths) }()
	waitForSocket(t, paths.Socket, cancel, serveErrors)
	defer func() {
		cancel()
		if err := <-serveErrors; err != nil {
			t.Errorf("serve() returned %v", err)
		}
	}()
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	exitCode := run([]string{
		"broker", "inspect", "--state-dir", stateDirectory,
		"--id", "command-native-inspect", "--idempotency-key", "native-inspect",
	}, &stdout, &stderr)
	if exitCode != 0 {
		t.Fatalf("broker inspect exit = %d, stderr = %q", exitCode, stderr.String())
	}
	var command domain.CommandRecord
	if err := json.Unmarshal(stdout.Bytes(), &command); err != nil {
		t.Fatalf("broker inspect command = %#v, %v", command, err)
	}
	var inspection sqlite.Inspection
	if err := json.Unmarshal(command.Result, &inspection); err != nil ||
		command.State != domain.CommandStateSucceeded || inspection.Integrity != "ok" {
		t.Fatalf("broker inspect result = %#v, %v", inspection, err)
	}
	stdout.Reset()
	stderr.Reset()
	if exitCode := run([]string{
		"events", "--state-dir", stateDirectory, "--after", "0", "--limit", "20",
	}, &stdout, &stderr); exitCode != 0 || !strings.Contains(stdout.String(), `"type":"command.succeeded"`) {
		t.Fatalf("events exit = %d, stdout = %q, stderr = %q", exitCode, stdout.String(), stderr.String())
	}
}

func TestRunSmokeWorkflowFromCleanState(t *testing.T) {
	stateDirectory := shortStateDirectory(t)
	executable, err := os.Executable()
	if err != nil {
		t.Fatalf("os.Executable() returned %v", err)
	}
	workingDirectory, err := os.Getwd()
	if err != nil {
		t.Fatalf("os.Getwd() returned %v", err)
	}
	pluginConfig, err := json.Marshal([]plugin.Config{{
		ID: "smoke",
		Profile: plugin.IsolationProfile{
			Executable: executable, WorkingDirectory: workingDirectory,
			Environment: map[string]string{smokePluginEnvironment: "1"}, DangerouslyAllowAll: true,
		},
		Restart: plugin.RestartPolicy{
			MaxAttempts: 1, InitialBackoff: time.Millisecond,
			MaxBackoff: time.Millisecond, CircuitOpenPeriod: time.Second,
		},
		Limits: plugin.WireLimits{
			MaxMessageBytes: 1 << 20, MaxEventsPerSecond: 100, MaxOperationSeconds: 60,
		},
	}})
	if err != nil {
		t.Fatalf("Marshal() plugin configuration returned %v", err)
	}
	pluginConfigPath := filepath.Join(t.TempDir(), "plugins.json")
	if err := os.WriteFile(pluginConfigPath, pluginConfig, 0o600); err != nil {
		t.Fatalf("WriteFile() plugin configuration returned %v", err)
	}
	t.Setenv("COLCHIS_PLUGIN_CONFIG", pluginConfigPath)
	paths, err := config.ResolvePaths(stateDirectory)
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	serveErrors := make(chan error, 1)
	go func() { serveErrors <- serve(ctx, paths) }()
	waitForSocket(t, paths.Socket, cancel, serveErrors)
	defer func() {
		cancel()
		if err := <-serveErrors; err != nil {
			t.Errorf("serve() returned %v", err)
		}
	}()

	document, err := os.ReadFile("../../examples/openspec-pi.json")
	if err != nil {
		t.Fatalf("ReadFile() returned %v", err)
	}
	var workflowDefinition workflowmodel.Definition
	if err := json.Unmarshal(document, &workflowDefinition); err != nil {
		t.Fatalf("Unmarshal() workflow returned %v", err)
	}
	runCommand := func(group string, action string, payload []byte) domain.CommandRecord {
		t.Helper()
		var stdout bytes.Buffer
		var stderr bytes.Buffer
		exitCode := run([]string{
			group, action, "--state-dir", stateDirectory, "--payload", string(payload),
		}, &stdout, &stderr)
		if exitCode != 0 {
			t.Fatalf("%s %s exit = %d, stderr = %q", group, action, exitCode, stderr.String())
		}
		var command domain.CommandRecord
		if err := json.Unmarshal(stdout.Bytes(), &command); err != nil {
			t.Fatalf("%s %s command = %#v, %v", group, action, command, err)
		}
		if command.State != domain.CommandStateSucceeded {
			t.Fatalf("%s %s state = %q", group, action, command.State)
		}
		return command
	}
	runCommand("planning", "discover", []byte(`{"pluginId":"smoke","adapterId":"openspec","input":{}}`))
	runCommand("planning", "snapshot", []byte(`{"pluginId":"smoke","adapterId":"openspec","input":{"change":"build-composable-agent-harness"}}`))
	invokeAdapter := func(
		id string,
		adapterID string,
		port domain.AdapterPort,
		operation string,
		input json.RawMessage,
	) {
		t.Helper()
		payload, err := json.Marshal(struct {
			PluginID  domain.PluginID          `json:"pluginId"`
			Operation plugin.OperationEnvelope `json:"operation"`
		}{
			PluginID: "smoke",
			Operation: plugin.OperationEnvelope{
				ID: domain.OperationID(id), AdapterID: adapterID, Port: port,
				Operation: operation, Input: input, Deadline: time.Now().Add(time.Minute),
			},
		})
		if err != nil {
			t.Fatalf("Marshal() adapter payload returned %v", err)
		}
		runCommand("adapter", "invoke", payload)
	}
	invokeAdapter(
		"workspace-smoke", "seshy.workspace", domain.AdapterPortWorkspace, "workspace.snapshot", json.RawMessage(`{}`),
	)
	invokeAdapter(
		"nix-smoke", "nix", domain.AdapterPortEnvironment, "environment.check",
		json.RawMessage(`{"checks":["unit-tests"],"expectedSnapshotDigest":"sha256:042593f8c06f3af13910448e80b07865b66db137c16a125291699564732eac88"}`),
	)
	createPayload, err := json.Marshal(struct {
		DefinitionID string          `json:"definitionId"`
		Document     json.RawMessage `json:"document"`
	}{DefinitionID: "definition-smoke", Document: document})
	if err != nil {
		t.Fatalf("Marshal() create payload returned %v", err)
	}
	runCommand("workflow", "create", createPayload)
	runCommand("workflow", "run", []byte(`{"runId":"run-smoke","definitionId":"definition-smoke"}`))
	workspaceDirectory := t.TempDir()
	if err := os.WriteFile(filepath.Join(workspaceDirectory, "result.txt"), []byte("verified\n"), 0o600); err != nil {
		t.Fatalf("WriteFile() workspace returned %v", err)
	}
	snapshotCommand := runCommand("workspace", "snapshot", []byte(
		`{"id":"snapshot-smoke","workspaceId":"workspace-smoke","workspacePath":`+
			fmt.Sprintf("%q", workspaceDirectory)+`}`,
	))
	var snapshot domain.Snapshot
	if err := json.Unmarshal(snapshotCommand.Result, &snapshot); err != nil {
		t.Fatalf("Unmarshal() snapshot returned %v", err)
	}
	client, err := socket.NewClient(paths.Socket)
	if err != nil {
		t.Fatalf("NewClient() returned %v", err)
	}
	events, err := client.Events(ctx, 0, 200)
	client.Close()
	if err != nil {
		t.Fatalf("Events() returned %v", err)
	}
	var restartCursor domain.EventCursor
	for _, event := range events {
		if event.Aggregate.Kind == "workflow-run" && event.Aggregate.ID == "run-smoke" {
			restartCursor = event.Cursor
		}
	}
	if restartCursor == 0 {
		t.Fatal("workflow restart cursor is missing")
	}
	restartPayload, err := json.Marshal(sqlite.RestartPointRequest{
		ID: "restart-smoke", Kind: domain.RestartPointRunAdmission, WorkflowRunID: "run-smoke",
		EventCursor: restartCursor, SnapshotID: snapshot.ID,
		AdmissionIDs: []domain.AdmissionID{}, CheckpointIDs: []domain.CheckpointID{},
	})
	if err != nil {
		t.Fatalf("Marshal() restart payload returned %v", err)
	}
	runCommand("workflow", "restart-point", restartPayload)
	scheduled := runCommand("workflow", "schedule", []byte(`{"runId":"run-smoke","adapterCapacity":{"pi":1}}`))
	var reserved []domain.NodeRun
	if err := json.Unmarshal(scheduled.Result, &reserved); err != nil || len(reserved) != 1 {
		t.Fatalf("scheduled nodes = %#v, %v", reserved, err)
	}
	startPayload, err := json.Marshal(broker.StartSessionRequest{
		Session: sqlite.CreateSessionRequest{
			ID: "session-smoke", WorkflowRunID: "run-smoke", NodeRunID: reserved[0].ID,
			RuntimePluginID: "caller-plugin", RuntimeAdapterID: "caller-runtime",
		},
		HandleID: "handle-smoke",
		Operation: plugin.OperationEnvelope{
			ID: "operation-agent-smoke", AdapterID: "caller-runtime", Port: domain.AdapterPortAgentRuntime,
			Operation: "agent-runtime.start", Input: json.RawMessage(`{"sessionId":"session-smoke"}`),
			Deadline: time.Now().Add(time.Minute),
		},
		PromptMediaType: "text/plain", TemplateDigest: "sha256:smoke-template", RenderedPrompt: []byte("Implement the task."),
	})
	if err != nil {
		t.Fatalf("Marshal() start payload returned %v", err)
	}
	started := runCommand("agent", "start", startPayload)
	var startedSession broker.StartSessionResult
	if err := json.Unmarshal(started.Result, &startedSession); err != nil ||
		startedSession.Session.RuntimeAdapterID != "pi" ||
		startedSession.Session.JobPolicy.Filesystem != domain.FilesystemPolicyWorkspaceWrite {
		t.Fatalf("agent start result = %#v, %v", startedSession, err)
	}
	judgeKey := domain.NodeKey("judge")
	auditKey := domain.NodeKey("audit")
	auditTemplateKey := domain.StageTemplateKey("audit")
	operationValue, err := json.Marshal(workflowmodel.StageOperationValue{
		Template: workflowDefinition.Templates["judge"], Adapter: "pi",
		SourcePort: "revision", InputPort: "candidate", OutputPort: "revision",
	})
	if err != nil {
		t.Fatalf("Marshal() graph operation value returned %v", err)
	}
	patchPayload, err := json.Marshal(struct {
		ID                        domain.GraphPatchID          `json:"id"`
		RunID                     domain.WorkflowRunID         `json:"workflowRunId"`
		ResultDefinitionID        domain.WorkflowDefinitionID  `json:"resultWorkflowDefinitionId"`
		ExpectedDefinitionVersion uint64                       `json:"expectedDefinitionVersion"`
		Operations                []domain.GraphPatchOperation `json:"operations"`
	}{
		ID: "patch-smoke", RunID: "run-smoke", ResultDefinitionID: "definition-smoke-patched",
		ExpectedDefinitionVersion: 1,
		Operations: []domain.GraphPatchOperation{{
			Kind: domain.GraphPatchOperationAddBranch, TargetNodeKey: &judgeKey,
			InstanceNodeKey: &auditKey, StageTemplateKey: &auditTemplateKey, Value: operationValue,
		}},
	})
	if err != nil {
		t.Fatalf("Marshal() patch payload returned %v", err)
	}
	runCommand("graph", "patch", patchPayload)
	inspectionCommand := runCommand("workflow", "inspect", []byte(`{"runId":"run-smoke"}`))
	var parent workflowViewResult
	if err := json.Unmarshal(inspectionCommand.Result, &parent); err != nil {
		t.Fatalf("Unmarshal() parent inspection returned %v", err)
	}
	replayRequest := struct {
		ID                      domain.RunForkID            `json:"id"`
		ParentWorkflowRunID     domain.WorkflowRunID        `json:"parentWorkflowRunId"`
		ChildWorkflowRunID      domain.WorkflowRunID        `json:"childWorkflowRunId"`
		RestartPointID          domain.RestartPointID       `json:"restartPointId"`
		TargetDefinitionID      domain.WorkflowDefinitionID `json:"targetWorkflowDefinitionId"`
		TargetDefinitionVersion uint64                      `json:"targetDefinitionVersion"`
		ExpectedParentVersion   domain.ResourceVersion      `json:"expectedParentVersion"`
		ReusedAdmissionIDs      []domain.AdmissionID        `json:"reusedAdmissionIds"`
		EnvironmentIDs          map[string]string           `json:"environmentIds"`
	}{
		ID: "fork-smoke", ParentWorkflowRunID: "run-smoke", ChildWorkflowRunID: "run-smoke-replay",
		RestartPointID: "restart-smoke", TargetDefinitionID: "definition-smoke-patched",
		TargetDefinitionVersion: 2, ExpectedParentVersion: parent.Run.Metadata.ResourceVersion,
		ReusedAdmissionIDs: []domain.AdmissionID{}, EnvironmentIDs: map[string]string{},
	}
	replayPayload, err := json.Marshal(replayRequest)
	if err != nil {
		t.Fatalf("Marshal() replay payload returned %v", err)
	}
	runCommand("replay", "run", replayPayload)
	resultCommand := runCommand("verification", "submit", mustJSON(t, sqlite.TaskResultRequest{
		ID: "result-smoke", NodeRunID: reserved[0].ID,
		SchemaDigest: workflowDefinition.Templates["implement"].OutputSchemaDigest,
		Value:        json.RawMessage(`{"status":"complete"}`), ArtifactIDs: []domain.ArtifactID{},
	}))
	if !strings.Contains(string(resultCommand.Result), `"accepted"`) {
		t.Fatalf("task result = %s", resultCommand.Result)
	}
	runCommand("verification", "task-record", mustJSON(t, sqlite.TaskRecordRequest{
		ID: "task-smoke", TaskResultID: "result-smoke", SnapshotID: snapshot.ID,
	}))
	exitCode := 0
	runCommand("verification", "record", mustJSON(t, sqlite.ValidationRequest{
		ID: "validation-smoke", TaskRecordID: "task-smoke", Key: "unit-tests",
		State: domain.ValidationStatePassed, Authority: domain.AuthorityHarness,
		EnvironmentID: "sha256:042593f8c06f3af13910448e80b07865b66db137c16a125291699564732eac88",
		ExitCode:      &exitCode,
	}))
	admissionCommand := runCommand("verification", "admit", mustJSON(t, sqlite.AdmissionRequest{
		ID: "admission-smoke", TaskRecordID: "task-smoke", ValidationIDs: []domain.ValidationID{"validation-smoke"},
	}))
	var admission domain.Admission
	if err := json.Unmarshal(admissionCommand.Result, &admission); err != nil ||
		admission.State != domain.AdmissionStateAdmitted {
		t.Fatalf("admission result = %#v, %v", admission, err)
	}
	runCommand("provenance", "inspect", []byte(`{}`))

	var stdout bytes.Buffer
	var stderr bytes.Buffer
	if exitCode := runWorkflowView(
		[]string{"--state-dir", stateDirectory, "--run", "run-smoke"}, &stdout, &stderr,
	); exitCode != 0 {
		t.Fatalf("runWorkflowView() exit = %d, stderr = %q", exitCode, stderr.String())
	}
	for _, expected := range []string{
		"run run-smoke [running] definition=definition-smoke-patched version=2",
		"implement [succeeded] adapter=pi policy=never/workspace-write/deny",
		"judge [ready] adapter=pi policy=never/workspace-write/deny",
		"audit [ready] adapter=pi policy=never/workspace-write/deny",
	} {
		if !strings.Contains(stdout.String(), expected) {
			t.Fatalf("workflow view = %q, missing %q", stdout.String(), expected)
		}
	}
	latestInspection := runCommand("workflow", "inspect", []byte(`{"runId":"run-smoke"}`))
	if err := json.Unmarshal(latestInspection.Result, &parent); err != nil {
		t.Fatalf("Unmarshal() latest parent inspection returned %v", err)
	}
	replayRequest.ID = "fork-smoke-view"
	replayRequest.ChildWorkflowRunID = "run-smoke-replay-view"
	replayRequest.ExpectedParentVersion = parent.Run.Metadata.ResourceVersion
	replayPayload, err = json.Marshal(replayRequest)
	if err != nil {
		t.Fatalf("Marshal() view replay payload returned %v", err)
	}
	stdout.Reset()
	stderr.Reset()
	if exitCode := runWorkflowView([]string{
		"--state-dir", stateDirectory, "--run", "run-smoke", "--control", "replay run",
		"--payload", string(replayPayload),
	}, &stdout, &stderr); exitCode != 0 {
		t.Fatalf("replay runWorkflowView() exit = %d, stderr = %q", exitCode, stderr.String())
	}
	if !strings.Contains(stdout.String(), "control workflow.replay [succeeded]") ||
		!strings.Contains(stdout.String(), "run run-smoke-replay-view [pending]") {
		t.Fatalf("replay workflow view = %q", stdout.String())
	}
}

func TestInactiveMCPAdvertisesProtocolsWithoutTools(t *testing.T) {
	input := strings.NewReader(strings.Join([]string{
		`{"jsonrpc":"2.0","id":1,"method":"server/discover"}`,
		`{"jsonrpc":"2.0","id":2,"method":"initialize","params":{"protocolVersion":"2025-11-25"}}`,
		`{"jsonrpc":"2.0","id":3,"method":"tools/list"}`,
	}, "\n"))
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	if exitCode := runMCP([]string{"--state-dir", shortStateDirectory(t)}, input, &stdout, &stderr); exitCode != 0 {
		t.Fatalf("runMCP() exit = %d, stderr = %q", exitCode, stderr.String())
	}
	decoder := json.NewDecoder(&stdout)
	var discover mcpResponse
	var initialize mcpResponse
	var toolsResponse mcpResponse
	for _, response := range []*mcpResponse{&discover, &initialize, &toolsResponse} {
		if err := decoder.Decode(response); err != nil {
			t.Fatalf("Decode() returned %v", err)
		}
	}
	var discovery struct {
		SupportedVersions []string `json:"supportedVersions"`
		TTLMilliseconds   uint64   `json:"ttlMs"`
		CacheScope        string   `json:"cacheScope"`
		ResultType        string   `json:"resultType"`
	}
	if err := json.Unmarshal(discover.Result, &discovery); err != nil ||
		len(discovery.SupportedVersions) != 1 || discovery.SupportedVersions[0] != mcpCurrentVersion ||
		discovery.TTLMilliseconds == 0 || discovery.CacheScope != "private" || discovery.ResultType != "complete" {
		t.Fatalf("server discovery = %#v, %v", discovery, err)
	}
	var initialized struct {
		ProtocolVersion string `json:"protocolVersion"`
	}
	if err := json.Unmarshal(initialize.Result, &initialized); err != nil ||
		initialized.ProtocolVersion != mcpCompatibleVersion {
		t.Fatalf("initialize result = %#v, %v", initialized, err)
	}
	var listed struct {
		Tools []mcpTool `json:"tools"`
	}
	if err := json.Unmarshal(toolsResponse.Result, &listed); err != nil || len(listed.Tools) != 0 {
		t.Fatalf("tools list count = %d, %v", len(listed.Tools), err)
	}
}

func TestMCPUsesWorkflowAndWorkerVocabulary(t *testing.T) {
	names := make(map[string]bool, len(mcpToolDefinitions))
	for _, tool := range mcpToolDefinitions {
		names[tool.Name] = true
	}
	for _, expected := range []string{
		"workflow_list", "workflow_restart_points", "workflow_forks", "worker_list", "worker_attach",
	} {
		if !names[expected] {
			t.Fatalf("MCP tools omitted %q", expected)
		}
	}
	for _, rejected := range []string{"planning_discover", "planning_snapshot", "planning_action", "agent_list", "agent_attach"} {
		if names[rejected] {
			t.Fatalf("MCP tools retained %q", rejected)
		}
	}
}

func TestMCPCallsNativeBrokerCommand(t *testing.T) {
	stateDirectory := shortStateDirectory(t)
	paths, err := config.ResolvePaths(stateDirectory)
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	serveErrors := make(chan error, 1)
	go func() { serveErrors <- serve(ctx, paths) }()
	waitForSocket(t, paths.Socket, cancel, serveErrors)
	defer func() {
		cancel()
		if err := <-serveErrors; err != nil {
			t.Errorf("serve() returned %v", err)
		}
	}()
	input := strings.NewReader(
		`{"jsonrpc":"2.0","id":"call-1","method":"tools/call","params":{"name":"broker_inspect","arguments":{"payload":{}},"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28"}}}` + "\n",
	)
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	if exitCode := runMCP([]string{"--state-dir", stateDirectory}, input, &stdout, &stderr); exitCode != 0 {
		t.Fatalf("runMCP() exit = %d, stderr = %q", exitCode, stderr.String())
	}
	var response mcpResponse
	if err := json.Unmarshal(stdout.Bytes(), &response); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	var result mcpCallResult
	if err := json.Unmarshal(response.Result, &result); err != nil || result.IsError {
		t.Fatalf("tool result = %#v, %v", result, err)
	}
	var modernEnvelope struct {
		ResultType string `json:"resultType"`
	}
	if err := json.Unmarshal(response.Result, &modernEnvelope); err != nil || modernEnvelope.ResultType != "complete" {
		t.Fatalf("modern tool envelope = %#v, %v", modernEnvelope, err)
	}
	var command domain.CommandRecord
	if err := json.Unmarshal(result.StructuredContent, &command); err != nil ||
		command.Kind != "broker.inspect" || command.State != domain.CommandStateSucceeded {
		t.Fatalf("native command = %#v, %v", command, err)
	}
}

func TestMCPReturnsToolErrorsInsideSuccessfulRPC(t *testing.T) {
	stateDirectory := shortStateDirectory(t)
	input := strings.NewReader(
		`{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"broker_inspect","arguments":{"payload":{}}}}` + "\n",
	)
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	if exitCode := runMCP([]string{"--state-dir", stateDirectory}, input, &stdout, &stderr); exitCode != 0 {
		t.Fatalf("runMCP() exit = %d, stderr = %q", exitCode, stderr.String())
	}
	var response mcpResponse
	if err := json.Unmarshal(stdout.Bytes(), &response); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	var result mcpCallResult
	if err := json.Unmarshal(response.Result, &result); err != nil || !result.IsError || len(result.Content) != 1 {
		t.Fatalf("tool error result = %#v, %v", result, err)
	}
}

func TestRunWorkflowViewRendersPinnedGraphAndControls(t *testing.T) {
	stateDirectory := shortStateDirectory(t)
	paths, err := config.ResolvePaths(stateDirectory)
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	store, err := sqlite.Open(context.Background(), paths.Database)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	document, err := os.ReadFile("../../schemas/workflow/v1/testdata/valid.json")
	if err != nil {
		t.Fatalf("ReadFile() returned %v", err)
	}
	evaluator, err := workflowmodel.NewEvaluator(workflowmodel.EvaluatorVersion)
	if err != nil {
		t.Fatalf("NewEvaluator() returned %v", err)
	}
	resolved, err := evaluator.Resolve(document, workflowmodel.CapabilityMap{
		"pi": {"structured-result", "live-input"},
	})
	if err != nil {
		t.Fatalf("Resolve() returned %v", err)
	}
	if _, err := store.CreateWorkflowDefinition(
		context.Background(), "definition-view", nil, document, resolved,
	); err != nil {
		t.Fatalf("CreateWorkflowDefinition() returned %v", err)
	}
	if _, _, err := store.CreateWorkflowRun(
		context.Background(), "run-view", "definition-view", nil,
	); err != nil {
		t.Fatalf("CreateWorkflowRun() returned %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	serveErrors := make(chan error, 1)
	go func() { serveErrors <- serve(ctx, paths) }()
	waitForSocket(t, paths.Socket, cancel, serveErrors)
	defer func() {
		cancel()
		if err := <-serveErrors; err != nil {
			t.Errorf("serve() returned %v", err)
		}
	}()
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	if exitCode := runWorkflowView(
		[]string{"--state-dir", stateDirectory, "--run", "run-view"}, &stdout, &stderr,
	); exitCode != 0 {
		t.Fatalf("runWorkflowView() exit = %d, stderr = %q", exitCode, stderr.String())
	}
	for _, expected := range []string{
		"run run-view [pending] definition=definition-view version=1",
		"implement [ready] adapter=pi",
		"implement.result -> judge.candidate [required]",
		"loops:",
		"controls: graph patch | replay run | agent attach | agent detach",
	} {
		if !strings.Contains(stdout.String(), expected) {
			t.Fatalf("workflow view = %q, missing %q", stdout.String(), expected)
		}
	}
	stdout.Reset()
	stderr.Reset()
	relation := `{"id":"view-relation","kind":"derived_from","from":{"kind":"workflow-run","id":"run-view"},"to":{"kind":"workflow-definition","id":"definition-view"},"basis":"derived","authority":"harness","observedAt":"2026-08-28T12:00:00Z"}`
	if exitCode := runWorkflowView([]string{
		"--state-dir", stateDirectory, "--run", "run-view",
		"--control", "provenance relation", "--payload", relation,
	}, &stdout, &stderr); exitCode != 0 {
		t.Fatalf("controlled runWorkflowView() exit = %d, stderr = %q", exitCode, stderr.String())
	}
	if !strings.Contains(stdout.String(), "control provenance.relation [succeeded]") ||
		!strings.Contains(stdout.String(), "run run-view [pending]") {
		t.Fatalf("controlled workflow view = %q", stdout.String())
	}
	stdout.Reset()
	stderr.Reset()
	if exitCode := runWorkflowView([]string{
		"--state-dir", stateDirectory, "--run", "run-view", "--control", "graph patch",
		"--payload", `{"workflowRunId":"run-other"}`,
	}, &stdout, &stderr); exitCode != 2 || !strings.Contains(stderr.String(), "must equal the displayed run") {
		t.Fatalf("cross-run control exit = %d, stderr = %q", exitCode, stderr.String())
	}
}

func TestServeRejectsSecondBrokerOwner(t *testing.T) {
	stateDirectory := shortStateDirectory(t)
	paths, err := config.ResolvePaths(stateDirectory)
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	errors := make(chan error, 1)
	go func() {
		errors <- serve(ctx, paths)
	}()
	waitForSocket(t, paths.Socket, cancel, errors)
	secondErr := serve(context.Background(), paths)
	if !domain.IsErrorCode(secondErr, domain.ErrorCodeConflict) {
		t.Fatalf("second serve() error = %v", secondErr)
	}
	cancel()
	if err := <-errors; err != nil {
		t.Fatalf("first serve() returned %v", err)
	}
}

func shortStateDirectory(t *testing.T) string {
	t.Helper()
	parent := ""
	if runtime.GOOS == "darwin" {
		parent = "/tmp"
	}
	directory, err := os.MkdirTemp(parent, "colchis-state-")
	if err != nil {
		t.Fatalf("MkdirTemp() returned %v", err)
	}
	t.Cleanup(func() { os.RemoveAll(directory) })
	return directory
}

func TestOrcaPickerUsesRecentAgentAndResponsiveLayout(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	available := []agents.Agent{
		{Name: "claude", Label: "Claude", Command: "claude"},
		{Name: "codex", Label: "Codex", Command: "codex"},
	}
	available[0].Launch.ResumeArgs = []string{"--resume"}
	available[1].Launch.ResumeArgs = []string{"resume"}
	if err := recordAgentUse("codex"); err != nil {
		t.Fatalf("recordAgentUse() returned %v", err)
	}
	sortAgentsByRecency(available)
	if available[0].Name != "codex" {
		t.Fatalf("first agent = %q, want codex", available[0].Name)
	}

	model := orcaUIModel{
		record: instance.Record{Scope: "/workspace/project", PID: 42},
		active: true,
		agents: available,
		help:   help.New(),
	}
	resized, _ := model.Update(tea.WindowSizeMsg{Width: 110, Height: 30})
	model = resized.(orcaUIModel)
	view := ansi.Strip(model.View())
	for _, expected := range []string{"🫍 orca", "running", "controllers 2", "Codex", "pid 42", "enter open"} {
		if !strings.Contains(view, expected) {
			t.Fatalf("View() omitted %q:\n%s", expected, view)
		}
	}
	selected, command := model.Update(tea.KeyMsg{Type: tea.KeyEnter})
	if command == nil || selected.(orcaUIModel).selected != "codex" {
		t.Fatalf("enter selected %#v", selected)
	}
	resumed, command := model.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'R'}})
	if command == nil || resumed.(orcaUIModel).selected != "codex" || !resumed.(orcaUIModel).selectedResume {
		t.Fatalf("resume selected %#v", resumed)
	}

	model.view = 1
	model.workflows = []domain.WorkflowRun{{ID: "plan-42", State: domain.WorkflowRunStateRunning}}
	model.workflow = workflowViewResult{
		Run:   model.workflows[0],
		Nodes: []domain.NodeRun{{NodeKey: "draft", State: domain.NodeRunStateRunning}},
	}
	model.definition = workflowmodel.Definition{
		Edges: []workflowmodel.Edge{{From: "research", FromPort: "notes", To: "draft", ToPort: "context"}},
	}
	graph := ansi.Strip(model.View())
	for _, expected := range []string{"workflows 1", "plan-42", "draft", "research.notes -> draft.context"} {
		if !strings.Contains(graph, expected) {
			t.Fatalf("workflow View() omitted %q:\n%s", expected, graph)
		}
	}
	model.restartPoints = []domain.RestartPoint{{
		ID: "restart-42", WorkflowRunID: "plan-42", EventCursor: 7,
	}}
	model.forks = []domain.RunFork{{
		ParentWorkflowRunID: "plan-original", ChildWorkflowRunID: "plan-42", RestartPointID: "restart-42",
	}}
	lineage := ansi.Strip(model.View())
	if !strings.Contains(lineage, "parent plan-original via restart-42") {
		t.Fatalf("workflow View() omitted lineage:\n%s", lineage)
	}
	confirmation, command := model.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'f'}})
	if command != nil || !confirmation.(orcaUIModel).confirmReplay {
		t.Fatalf("first replay key = %#v, command = %#v", confirmation, command)
	}
	confirmed, command := confirmation.(orcaUIModel).Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'f'}})
	if command == nil || confirmed.(orcaUIModel).confirmReplay {
		t.Fatalf("second replay key = %#v, command = %#v", confirmed, command)
	}

	model.view = orcaWorkersView
	model.workers = []domain.Session{{
		ID: "worker-42", WorkflowRunID: "plan-42", NodeRunID: "node-42",
		RuntimeAdapterID: "pi", State: domain.SessionStateRunning,
	}}
	model.workerHistory = sqlite.SessionHistory{
		Session: model.workers[0],
		RuntimeEvents: []domain.RuntimeEvent{{
			Sequence: 3, Kind: "tool_call", ProviderEventType: "tool_execution_start",
		}},
	}
	workerView := ansi.Strip(model.View())
	for _, expected := range []string{"workers 1", "worker-42", "plan-42", "tool_execution_start", "enter attaches"} {
		if !strings.Contains(workerView, expected) {
			t.Fatalf("worker View() omitted %q:\n%s", expected, workerView)
		}
	}
}

func TestOrcaWorkerRequestsTargetRuntimeAndAttachment(t *testing.T) {
	handle := domain.AdapterHandleID("handle-worker")
	session := domain.Session{
		ID: "worker-42", RuntimePluginID: "pi-plugin", RuntimeAdapterID: "pi",
		RuntimeHandle: &handle, State: domain.SessionStateRunning,
	}
	attachment, err := workerAttachmentRequest(
		session, domain.InterventionKindAttach, "attachment.open",
		json.RawMessage(`{"sessionId":"worker-42","cursor":0}`),
	)
	if err != nil || attachment.PluginID != "pi-plugin" ||
		attachment.Operation.AdapterID != "pi.attachment" ||
		attachment.Operation.Port != domain.AdapterPortAttachment ||
		attachment.Intervention.Kind != domain.InterventionKindAttach {
		t.Fatalf("workerAttachmentRequest() = %#v, %v", attachment, err)
	}
	message, err := workerMessageRequest(session, "Check the failing test.")
	if err != nil || message.Operation.AdapterID != "pi" ||
		message.Operation.Port != domain.AdapterPortAgentRuntime ||
		message.Operation.Operation != "agent-runtime.input" ||
		message.Operation.HandleID == nil || *message.Operation.HandleID != handle {
		t.Fatalf("workerMessageRequest() = %#v, %v", message, err)
	}
	if !strings.Contains(string(message.Operation.Input), `"behavior":"steer"`) {
		t.Fatalf("worker message input = %s", message.Operation.Input)
	}
}

func TestCleanOrcaLeasesRemovesExitedProcesses(t *testing.T) {
	stateDirectory := t.TempDir()
	directory := orcaLeaseDirectory(stateDirectory)
	if err := os.Mkdir(directory, 0o700); err != nil {
		t.Fatalf("Mkdir() returned %v", err)
	}
	active := filepath.Join(directory, fmt.Sprintf("%d-active", os.Getpid()))
	stale := filepath.Join(directory, "2147483647-stale")
	for _, path := range []string{active, stale} {
		if err := os.WriteFile(path, nil, 0o600); err != nil {
			t.Fatalf("WriteFile() returned %v", err)
		}
	}
	remaining, err := cleanOrcaLeases(stateDirectory)
	if err != nil {
		t.Fatalf("cleanOrcaLeases() returned %v", err)
	}
	if remaining != 1 {
		t.Fatalf("remaining leases = %d, want 1", remaining)
	}
	if _, err := os.Stat(stale); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("stale lease stat error = %v", err)
	}
}

func waitForSocket(t *testing.T, path string, cancel context.CancelFunc, serveErrors <-chan error) {
	t.Helper()
	deadline := time.Now().Add(5 * time.Second)
	for {
		if info, err := os.Stat(path); err == nil && info.Mode()&os.ModeSocket != 0 {
			return
		}
		if time.Now().After(deadline) {
			cancel()
			<-serveErrors
			t.Fatal("serve() did not create the broker socket")
		}
		time.Sleep(10 * time.Millisecond)
	}
}

func mustJSON[Value sqlite.TaskResultRequest | sqlite.TaskRecordRequest | sqlite.ValidationRequest | sqlite.AdmissionRequest](
	t *testing.T,
	value Value,
) []byte {
	t.Helper()
	encoded, err := json.Marshal(value)
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	return encoded
}

func TestRunDoesNotCreateMissingDatabase(t *testing.T) {
	t.Parallel()

	stateDirectory := filepath.Join(t.TempDir(), "missing")
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	if exitCode := run([]string{"inspect", "--state-dir", stateDirectory}, &stdout, &stderr); exitCode != 1 {
		t.Fatalf("run() exit code = %d", exitCode)
	}
	if !strings.Contains(stderr.String(), "open database") {
		t.Fatalf("run() stderr = %q", stderr.String())
	}
	if _, err := os.Stat(stateDirectory); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("Stat() error = %v", err)
	}
}

func TestRunExportsIncompatibleDatabaseWithoutChangingIt(t *testing.T) {
	t.Parallel()

	stateDirectory := t.TempDir()
	paths, err := config.ResolvePaths(stateDirectory)
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	database, err := sql.Open("sqlite", paths.Database)
	if err != nil {
		t.Fatalf("sql.Open() returned %v", err)
	}
	if _, err := database.Exec(`CREATE TABLE future_data(id INTEGER PRIMARY KEY AUTOINCREMENT, value BLOB)`); err != nil {
		t.Fatalf("creating future table returned %v", err)
	}
	if _, err := database.Exec(`INSERT INTO future_data(id, value) VALUES(1, X'00FF'), (100, X'01')`); err != nil {
		t.Fatalf("inserting future row returned %v", err)
	}
	if _, err := database.Exec(`DELETE FROM future_data WHERE id = 100`); err != nil {
		t.Fatalf("deleting future row returned %v", err)
	}
	if _, err := database.Exec("PRAGMA user_version = 2"); err != nil {
		t.Fatalf("setting user_version returned %v", err)
	}
	if err := database.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	if err := os.Chmod(stateDirectory, 0o700); err != nil {
		t.Fatalf("Chmod() state directory returned %v", err)
	}
	if err := os.Chmod(paths.Database, 0o600); err != nil {
		t.Fatalf("Chmod() database returned %v", err)
	}
	before, err := os.ReadFile(paths.Database)
	if err != nil {
		t.Fatalf("ReadFile() before export returned %v", err)
	}

	var stdout bytes.Buffer
	var stderr bytes.Buffer
	exportPath := filepath.Join(t.TempDir(), "export.sqlite3")
	if exitCode := run(
		[]string{"export", "--state-dir", stateDirectory, "--output", exportPath},
		&stdout,
		&stderr,
	); exitCode != 0 {
		t.Fatalf("run() exit code = %d, stderr = %q", exitCode, stderr.String())
	}
	if stdout.String() != exportPath+"\n" {
		t.Fatalf("run() stdout = %q", stdout.String())
	}
	exportedDatabase, err := sql.Open("sqlite", exportPath)
	if err != nil {
		t.Fatalf("opening exported database returned %v", err)
	}
	defer exportedDatabase.Close()
	var value []byte
	if err := exportedDatabase.QueryRow("SELECT value FROM future_data WHERE id = 1").Scan(&value); err != nil {
		t.Fatalf("reading exported data returned %v", err)
	}
	if !bytes.Equal(value, []byte{0x00, 0xff}) {
		t.Fatalf("exported value = %x", value)
	}
	var sequence int
	if err := exportedDatabase.QueryRow("SELECT seq FROM sqlite_sequence WHERE name = 'future_data'").Scan(&sequence); err != nil {
		t.Fatalf("reading exported sequence returned %v", err)
	}
	if sequence != 100 {
		t.Fatalf("exported sequence = %d", sequence)
	}
	after, err := os.ReadFile(paths.Database)
	if err != nil {
		t.Fatalf("ReadFile() after export returned %v", err)
	}
	if !bytes.Equal(after, before) {
		t.Fatal("export changed the incompatible database")
	}
}
