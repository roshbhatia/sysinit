package main

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
	"time"

	"github.com/charmbracelet/bubbles/help"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/x/ansi"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/nix"
	openspecadapter "github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/openspec"
	piadapter "github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/pi"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/seshy"
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
	restartPayload, err := json.Marshal(sqlite.RestartPointRequest{
		ID: "restart-smoke", Kind: domain.RestartPointRunAdmission, WorkflowRunID: "run-smoke",
		SnapshotID:   snapshot.ID,
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
	}{
		ID: "fork-smoke", ParentWorkflowRunID: "run-smoke", ChildWorkflowRunID: "run-smoke-replay",
		RestartPointID: "restart-smoke", TargetDefinitionID: "definition-smoke-patched",
		TargetDefinitionVersion: 2, ExpectedParentVersion: parent.Run.Metadata.ResourceVersion,
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

func TestMCPInitializeIgnoresMalformedBrokerRecord(t *testing.T) {
	stateDirectory := shortStateDirectory(t)
	paths, err := config.ResolvePaths(stateDirectory)
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	if err := os.MkdirAll(paths.StateDirectory, 0o700); err != nil {
		t.Fatalf("MkdirAll() returned %v", err)
	}
	if err := os.WriteFile(filepath.Join(paths.StateDirectory, "instance.json"), []byte("{"), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	t.Setenv("ORCA_STATE_DIR", stateDirectory)
	input := strings.NewReader(
		`{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25"}}` + "\n",
	)
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	if exit := runMCP(nil, input, &stdout, &stderr); exit != 0 {
		t.Fatalf("runMCP() exit = %d, stderr = %q", exit, stderr.String())
	}
	var response mcpResponse
	if err := json.Unmarshal(stdout.Bytes(), &response); err != nil || response.Error != nil {
		t.Fatalf("initialize response = %#v, %v", response, err)
	}
}

func TestMCPResolvesBrokerStateForEachRequest(t *testing.T) {
	stateDirectory := shortStateDirectory(t)
	client, active, err := resolveMCPClient(stateDirectory)
	if err != nil || active || client != nil {
		t.Fatalf("resolveMCPClient(inactive) = %#v, %v, %v", client, active, err)
	}
	paths, err := config.ResolvePaths(stateDirectory)
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	serveErrors := make(chan error, 1)
	go func() { serveErrors <- serve(ctx, paths) }()
	waitForSocket(t, paths.Socket, cancel, serveErrors)
	client, active, err = resolveMCPClient(stateDirectory)
	if err != nil || !active || client == nil {
		cancel()
		<-serveErrors
		t.Fatalf("resolveMCPClient(active) = %#v, %v, %v", client, active, err)
	}
	client.Close()
	cancel()
	if err := <-serveErrors; err != nil {
		t.Fatalf("serve() returned %v", err)
	}
	client, active, err = resolveMCPClient(stateDirectory)
	if err != nil || active || client != nil {
		t.Fatalf("resolveMCPClient(stopped) = %#v, %v, %v", client, active, err)
	}
}

func TestMCPNotifiesWhenBrokerToolsBecomeAvailable(t *testing.T) {
	stateDirectory := shortStateDirectory(t)
	inputReader, inputWriter := io.Pipe()
	outputReader, outputWriter := io.Pipe()
	var stderr bytes.Buffer
	mcpExit := make(chan int, 1)
	go func() {
		mcpExit <- runMCP([]string{"--state-dir", stateDirectory}, inputReader, outputWriter, &stderr)
		_ = outputWriter.Close()
	}()
	defer inputWriter.Close()

	if _, err := fmt.Fprintln(
		inputWriter,
		`{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25"}}`,
	); err != nil {
		t.Fatalf("write initialize request: %v", err)
	}
	decoder := json.NewDecoder(outputReader)
	var initialized mcpResponse
	if err := decoder.Decode(&initialized); err != nil {
		t.Fatalf("decode initialize response: %v", err)
	}
	var capabilities struct {
		Capabilities struct {
			Tools struct {
				ListChanged bool `json:"listChanged"`
			} `json:"tools"`
		} `json:"capabilities"`
	}
	if err := json.Unmarshal(initialized.Result, &capabilities); err != nil ||
		!capabilities.Capabilities.Tools.ListChanged {
		t.Fatalf("initialize capabilities = %#v, %v", capabilities, err)
	}
	if _, err := fmt.Fprintln(
		inputWriter, `{"jsonrpc":"2.0","method":"notifications/initialized"}`,
	); err != nil {
		t.Fatalf("write initialized notification: %v", err)
	}

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
		_ = inputWriter.Close()
		if exit := <-mcpExit; exit != 0 {
			t.Errorf("runMCP() exit = %d, stderr = %q", exit, stderr.String())
		}
	}()

	notifications := make(chan mcpNotification, 1)
	decodeErrors := make(chan error, 1)
	go func() {
		var notification mcpNotification
		if err := decoder.Decode(&notification); err != nil {
			decodeErrors <- err
			return
		}
		notifications <- notification
	}()
	select {
	case notification := <-notifications:
		if notification.Method != "notifications/tools/list_changed" {
			t.Fatalf("notification = %#v", notification)
		}
	case err := <-decodeErrors:
		t.Fatalf("decode tool-list notification: %v", err)
	case <-time.After(3 * time.Second):
		t.Fatal("MCP did not report the broker tool-list change")
	}
}

func TestMCPAcknowledgesModernToolSubscription(t *testing.T) {
	input := strings.NewReader(strings.Join([]string{
		`{"jsonrpc":"2.0","id":"tools","method":"subscriptions/listen","params":{"notifications":{"toolsListChanged":true},"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientCapabilities":{}}}}`,
		`{"jsonrpc":"2.0","method":"notifications/cancelled","params":{"requestId":"tools"}}`,
	}, "\n"))
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	if exit := runMCP([]string{"--state-dir", shortStateDirectory(t)}, input, &stdout, &stderr); exit != 0 {
		t.Fatalf("runMCP() exit = %d, stderr = %q", exit, stderr.String())
	}
	var acknowledgement struct {
		Method string `json:"method"`
		Params struct {
			Notifications mcpSubscriptionFilter `json:"notifications"`
			Meta          map[string]string     `json:"_meta"`
		} `json:"params"`
	}
	decoder := json.NewDecoder(&stdout)
	if err := decoder.Decode(&acknowledgement); err != nil {
		t.Fatalf("Decode() returned %v", err)
	}
	if acknowledgement.Method != "notifications/subscriptions/acknowledged" ||
		!acknowledgement.Params.Notifications.ToolsListChanged ||
		acknowledgement.Params.Meta["io.modelcontextprotocol/subscriptionId"] != "tools" {
		t.Fatalf("subscription acknowledgement = %#v", acknowledgement)
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		t.Fatalf("subscription emitted an extra response: %v", err)
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
		"controls: graph patch | replay run | worker attach | worker detach",
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
	if strings.Contains(graph, "enter open") {
		t.Fatalf("workflow View() advertised an unavailable action:\n%s", graph)
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
		Capabilities: []string{"native-attachment"},
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
	model.workers[0].Capabilities = nil
	unavailable, command := model.Update(tea.KeyMsg{Type: tea.KeyEnter})
	if command != nil || unavailable.(orcaUIModel).selectedWorker != "" ||
		!strings.Contains(unavailable.(orcaUIModel).message, "no interactive attachment") {
		t.Fatalf("unavailable attachment = %#v, command = %#v", unavailable, command)
	}
}

func TestOrcaWorkflowGraphUsesViewport(t *testing.T) {
	model := orcaUIModel{
		view: orcaWorkflowsView, width: 100, height: 24, help: help.New(),
		workflows: []domain.WorkflowRun{{ID: "run-large", State: domain.WorkflowRunStateRunning}},
		workflow:  workflowViewResult{Run: domain.WorkflowRun{ID: "run-large"}},
	}
	for index := 0; index < 20; index++ {
		key := domain.NodeKey(fmt.Sprintf("node-%02d", index))
		model.workflow.Nodes = append(model.workflow.Nodes, domain.NodeRun{NodeKey: key})
		if index > 0 {
			model.definition.Edges = append(model.definition.Edges, workflowmodel.Edge{
				From: domain.NodeKey(fmt.Sprintf("node-%02d", index-1)), To: key,
			})
		}
	}
	view := ansi.Strip(model.View())
	if !strings.Contains(view, "pgup/pgdn scroll") || strings.Count(view, "node-") >= 39 {
		t.Fatalf("large graph has no viewport:\n%s", view)
	}
	scrolled, _ := model.Update(tea.KeyMsg{Type: tea.KeyPgDown})
	if scrolled.(orcaUIModel).graphOffset == 0 {
		t.Fatal("page down did not scroll the graph")
	}
	for range 10 {
		scrolled, _ = scrolled.(orcaUIModel).Update(tea.KeyMsg{Type: tea.KeyPgDown})
	}
	bottom := scrolled.(orcaUIModel).graphOffset
	scrolled, _ = scrolled.(orcaUIModel).Update(tea.KeyMsg{Type: tea.KeyPgUp})
	if moved := bottom - scrolled.(orcaUIModel).graphOffset; moved <= 1 {
		t.Fatalf("page up moved %d rows from offset %d", moved, bottom)
	}
}

func TestOrcaUIRejectsPaneThatHidesControls(t *testing.T) {
	model := orcaUIModel{width: 40, height: 10, help: help.New()}
	view := ansi.Strip(model.View())
	if strings.Count(view, "\n") != 2 || !strings.Contains(view, "orca needs 76x20") ||
		!strings.Contains(view, "q quits") {
		t.Fatalf("small main UI = %q", view)
	}
	worker := orcaWorkerUIModel{width: 40, height: 10}
	view = ansi.Strip(worker.View())
	if strings.Count(view, "\n") != 2 || !strings.Contains(view, "orca needs 60x16") ||
		!strings.Contains(view, "q detaches") {
		t.Fatalf("small worker UI = %q", view)
	}
}

func TestOrcaWorkerAttachmentFitsEightyByTwentyFour(t *testing.T) {
	model := orcaWorkerUIModel{
		record:  instance.Record{Scope: "/workspace/project"},
		width:   80,
		height:  24,
		message: "Worker refreshed",
		history: sqlite.SessionHistory{Session: domain.Session{
			ID: "worker-fit", WorkflowRunID: "run-fit", NodeRunID: "node-fit",
			State: domain.SessionStateRunning,
		}},
	}
	for sequence := uint64(1); sequence <= 11; sequence++ {
		model.history.RuntimeEvents = append(model.history.RuntimeEvents, domain.RuntimeEvent{
			Sequence: sequence, Kind: "tool_call", ProviderEventType: "tool_execution_start",
		})
	}
	view := ansi.Strip(model.View())
	if lines := strings.Count(view, "\n") + 1; lines > 24 || !strings.Contains(view, "q detach") {
		t.Fatalf("80x24 worker attachment has %d lines:\n%s", lines, view)
	}
}

func TestOrcaFullHelpOnlyShowsActionsForCurrentView(t *testing.T) {
	model := orcaUIModel{help: help.New()}
	model.help.ShowAll = true
	model.help.Width = 120
	controllerHelp := model.help.View(model.helpKeys())
	if !strings.Contains(controllerHelp, "resume controller") || strings.Contains(controllerHelp, "fork from restart point") {
		t.Fatalf("controller help = %q", controllerHelp)
	}
	model.view = orcaWorkersView
	workerHelp := model.help.View(model.helpKeys())
	if strings.Contains(workerHelp, "resume controller") || strings.Contains(workerHelp, "graph down") {
		t.Fatalf("worker help = %q", workerHelp)
	}
	model.view = orcaWorkflowsView
	model.width = 80
	model.height = 24
	model.help.Width = 80
	workflowView := ansi.Strip(model.View())
	if lines := strings.Count(workflowView, "\n") + 1; lines > 24 || !strings.Contains(workflowView, "f fork") {
		t.Fatalf("80x24 workflow help has %d lines:\n%s", lines, workflowView)
	}
}

func TestRestartPointCursorDoesNotLeakAcrossWorkflows(t *testing.T) {
	points := []domain.RestartPoint{{ID: "new-first"}, {ID: "new-second"}}
	if cursor := restartPointCursor(points, "old-second"); cursor != 0 {
		t.Fatalf("restart point cursor = %d, want 0", cursor)
	}
	if cursor := restartPointCursor(points, "new-second"); cursor != 1 {
		t.Fatalf("preserved restart point cursor = %d, want 1", cursor)
	}
}

func TestOrcaWorkerPreventsDuplicateSendAndShowsFailure(t *testing.T) {
	input := textinput.New()
	input.SetValue("Review this failure")
	model := orcaWorkerUIModel{
		typing: true, input: input,
		history: sqlite.SessionHistory{Session: domain.Session{ID: "worker-send"}},
	}
	updated, command := model.Update(tea.KeyMsg{Type: tea.KeyEnter})
	model = updated.(orcaWorkerUIModel)
	if command == nil || model.typing || model.message != "Sending message" {
		t.Fatalf("first enter = %#v, command = %#v", model, command)
	}
	updated, duplicate := model.Update(tea.KeyMsg{Type: tea.KeyEnter})
	if duplicate != nil {
		t.Fatalf("second enter returned command %#v", duplicate)
	}
	failed, _ := updated.(orcaWorkerUIModel).Update(orcaWorkerActionMessage{err: errors.New("send failed")})
	model = failed.(orcaWorkerUIModel)
	if !model.messageError || model.message != "send failed" || model.typing {
		t.Fatalf("failed send state = %#v", model)
	}
}

func TestOrcaRefreshTickClearsStoppedBrokerState(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	t.Setenv("ORCA_STATE_DIR", "")
	model := orcaUIModel{
		active:    true,
		workflows: []domain.WorkflowRun{{ID: "stale-run"}},
		help:      help.New(),
	}
	updated, command := model.Update(orcaRefreshTick(time.Now()))
	model = updated.(orcaUIModel)
	if command == nil || !model.refreshing {
		t.Fatalf("refresh tick state = %#v, command = %#v", model, command)
	}
	batch, ok := command().(tea.BatchMsg)
	if !ok || len(batch) != 2 {
		t.Fatalf("refresh tick command = %#v", batch)
	}
	updated, _ = model.Update(batch[0]())
	model = updated.(orcaUIModel)
	if model.active || len(model.workflows) != 0 || model.refreshing {
		t.Fatalf("refresh result state = %#v", model)
	}
}

func TestPlanningPrimitivesAreNotPublicCLICommands(t *testing.T) {
	for _, args := range [][]string{{"planning", "discover"}, {"planning", "snapshot"}, {"planning", "action"}} {
		if kind, _, found := controlCommandKind(args); found || kind != "" {
			t.Fatalf("controlCommandKind(%q) = %q, %v", args, kind, found)
		}
	}
}

func TestWorkflowRestartMetadataHasNativeCLICommands(t *testing.T) {
	for args, expected := range map[string]string{
		"workflow restart-points": "workflow.restart-points",
		"workflow forks":          "workflow.forks",
	} {
		kind, offset, found := controlCommandKind(strings.Fields(args))
		if !found || kind != expected || offset != 2 {
			t.Fatalf("controlCommandKind(%q) = %q, %d, %v", args, kind, offset, found)
		}
	}
}

func TestWorkerTerminologyHasNativeCLIAliases(t *testing.T) {
	for args, expected := range map[string]string{
		"worker start": "agent.start", "worker list": "agent.list", "worker attach": "agent.attach",
		"worker detach": "agent.detach", "worker intervene": "agent.intervene", "worker policy": "agent.policy",
		"worker cancel": "agent.cancel", "worker history": "agent.history",
	} {
		kind, offset, found := controlCommandKind(strings.Fields(args))
		if !found || kind != expected || offset != 2 {
			t.Fatalf("controlCommandKind(%q) = %q, %d, %v", args, kind, offset, found)
		}
	}
}

func TestWorkflowViewAcceptsAdvertisedWorkerControls(t *testing.T) {
	for control, expected := range map[string]string{
		"worker attach": "agent.attach", "worker detach": "agent.detach",
		"worker intervene": "agent.intervene", "worker policy": "agent.policy",
	} {
		kind, found := workflowViewControlKind(control)
		if !found || kind != expected {
			t.Fatalf("workflowViewControlKind(%q) = %q, %v", control, kind, found)
		}
	}
	if !strings.Contains(orcaUsage, "orca view --run") || !strings.Contains(orcaUsage, "orca events") {
		t.Fatalf("orca help omits read-only commands:\n%s", orcaUsage)
	}
}

func TestOrcaHelpListsNativeCommands(t *testing.T) {
	for _, command := range []string{"workflow <create|run", "graph patch", "replay run", "worker <start|list"} {
		if !strings.Contains(orcaUsage, command) {
			t.Fatalf("orca help omits %q", command)
		}
	}
}

func TestParseOrcaControllerUsesControllerTerminology(t *testing.T) {
	_, _, _, err := parseOrcaController(nil, "resume")
	if err == nil || !strings.Contains(err.Error(), "orca resume <controller>") {
		t.Fatalf("resume usage error = %v", err)
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

func TestCompletedWorkerDoesNotAdvertiseAttachment(t *testing.T) {
	session := domain.Session{
		State: domain.SessionStateCompleted, Capabilities: []string{"native-attachment"},
	}
	if supportsWorkerAttachment(session) {
		t.Fatal("completed worker supports attachment")
	}
	session.State = domain.SessionStateRunning
	if !supportsWorkerAttachment(session) {
		t.Fatal("running worker lost attachment")
	}
}

func TestFilterWorkerEventsUsesReadOnlyEventStream(t *testing.T) {
	runtimePayload, err := json.Marshal(domain.RuntimeEvent{
		Sequence: 9, Kind: "message", ProviderEventType: "assistant_message",
	})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	envelopes := []domain.EventEnvelope{
		{Cursor: 6, Aggregate: domain.ResourceReference{Kind: "session", ID: "other"}},
		{
			Cursor: 7, Aggregate: domain.ResourceReference{Kind: "session", ID: "worker-42"},
			Type: "session.runtime.event", Payload: runtimePayload,
		},
		{
			Cursor: 8, Aggregate: domain.ResourceReference{Kind: "session", ID: "worker-42"},
			Type: "session.state.changed", Payload: json.RawMessage(`{"state":"completed"}`),
		},
	}
	events, state, cursor, err := filterWorkerEvents(envelopes, 5, "worker-42")
	if err != nil || len(events) != 1 || events[0].Sequence != 9 || state == nil ||
		*state != domain.SessionStateCompleted || cursor != 8 {
		t.Fatalf("filterWorkerEvents() = %#v, %v, %d, %v", events, state, cursor, err)
	}
}

func TestCleanOrcaLeasesRemovesExitedProcesses(t *testing.T) {
	stateDirectory := t.TempDir()
	directory := orcaLeaseDirectory(stateDirectory)
	if err := os.Mkdir(directory, 0o700); err != nil {
		t.Fatalf("Mkdir() returned %v", err)
	}
	active, err := createOrcaLease(directory)
	if err != nil {
		t.Fatalf("createOrcaLease() returned %v", err)
	}
	stale := filepath.Join(directory, "stale")
	if err := os.WriteFile(stale, []byte(`{"pid":2147483647,"identity":1}`), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	reused := filepath.Join(directory, "reused")
	if err := os.WriteFile(
		reused, []byte(fmt.Sprintf(`{"pid":%d,"identity":1}`, os.Getpid())), 0o600,
	); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	remaining, err := cleanOrcaLeases(stateDirectory)
	if err != nil {
		t.Fatalf("cleanOrcaLeases() returned %v", err)
	}
	if remaining != 1 {
		t.Fatalf("remaining leases = %d, want 1", remaining)
	}
	if _, err := os.Stat(active); err != nil {
		t.Fatalf("active lease stat error = %v", err)
	}
	if _, err := os.Stat(stale); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("stale lease stat error = %v", err)
	}
	if _, err := os.Stat(reused); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("reused PID lease stat error = %v", err)
	}
}

func TestOrcaCandidateUsesContainingWorkspace(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	t.Setenv("ORCA_STATE_DIR", "")
	parent := t.TempDir()
	nested := filepath.Join(parent, "nested")
	if err := os.Mkdir(nested, 0o700); err != nil {
		t.Fatalf("Mkdir() returned %v", err)
	}
	record, _, err := instance.Candidate(parent)
	if err != nil {
		t.Fatalf("Candidate() returned %v", err)
	}
	record.PID = os.Getpid()
	record.StartedAt = time.Now().UTC().Format(time.RFC3339Nano)
	if err := instance.Write(record); err != nil {
		t.Fatalf("Write() returned %v", err)
	}
	t.Chdir(nested)
	candidate, err := orcaStartCandidate("")
	if err != nil || candidate.Scope != record.Scope {
		t.Fatalf("orcaStartCandidate() = %#v, %v", candidate, err)
	}
}

func TestAutomaticMonitorMarksBrokerStoppingBeforeCancellation(t *testing.T) {
	stateDirectory := t.TempDir()
	record := instance.Record{
		Version: instance.Version, Scope: t.TempDir(), StateDirectory: stateDirectory,
		Socket: filepath.Join(stateDirectory, "broker.sock"), Automatic: true,
		PID: os.Getpid(), StartedAt: time.Now().UTC().Format(time.RFC3339Nano),
	}
	if err := instance.Write(record); err != nil {
		t.Fatalf("Write() returned %v", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	stopped := make(chan instance.Record, 1)
	go monitorAutomaticBroker(ctx, stateDirectory, func() {
		current, _ := instance.Read(filepath.Join(stateDirectory, "instance.json"))
		stopped <- current
		cancel()
	})
	select {
	case current := <-stopped:
		if !current.Stopping {
			t.Fatalf("monitor cancellation record = %#v", current)
		}
	case <-time.After(3 * time.Second):
		t.Fatal("automatic monitor did not stop an idle broker")
	}
}

func TestInactiveOrcaStatusOmitsStaleProcess(t *testing.T) {
	record := instance.Record{
		Scope: "/workspace", StateDirectory: "/state", Socket: "/state/broker.sock",
		Service: "launchd:stale", PID: 42, StartedAt: "stale",
	}
	status := statusOf(record, false)
	if status.Service != "" || status.PID != 0 || status.StartedAt != "" {
		t.Fatalf("inactive status = %#v", status)
	}
}

func TestPinnedBrokerIgnoresAutomaticServiceArgument(t *testing.T) {
	stateDirectory := t.TempDir()
	if automatic, err := automaticOrcaBroker(stateDirectory, true); err != nil || !automatic {
		t.Fatalf("automaticOrcaBroker(unpinned) = %v, %v", automatic, err)
	}
	if err := setOrcaPinned(stateDirectory, true); err != nil {
		t.Fatalf("setOrcaPinned() returned %v", err)
	}
	if automatic, err := automaticOrcaBroker(stateDirectory, true); err != nil || automatic {
		t.Fatalf("automaticOrcaBroker(pinned) = %v, %v", automatic, err)
	}
}

func TestStartFailurePreservesExistingPin(t *testing.T) {
	record := instance.Record{StateDirectory: t.TempDir()}
	if err := setOrcaPinned(record.StateDirectory, true); err != nil {
		t.Fatalf("setOrcaPinned() returned %v", err)
	}
	startError := errors.New("start failed")
	_, _, err := startPinnedOrca(record, func(instance.Record, bool) (bool, string, error) {
		return false, "", startError
	})
	if !errors.Is(err, startError) {
		t.Fatalf("startPinnedOrca() error = %v", err)
	}
	if pinned, err := orcaPinned(record.StateDirectory); err != nil || !pinned {
		t.Fatalf("orcaPinned() = %v, %v", pinned, err)
	}
}

func TestStopRemovesInactiveInstanceRecord(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	t.Setenv("ORCA_STATE_DIR", "")
	scope := t.TempDir()
	record, _, err := instance.Candidate(scope)
	if err != nil {
		t.Fatalf("Candidate() returned %v", err)
	}
	record.PID = 2147483647
	record.StartedAt = time.Now().UTC().Format(time.RFC3339Nano)
	if err := instance.Write(record); err != nil {
		t.Fatalf("Write() returned %v", err)
	}
	if err := setOrcaPinned(record.StateDirectory, true); err != nil {
		t.Fatalf("setOrcaPinned() returned %v", err)
	}
	t.Setenv("ORCA_STATE_DIR", record.StateDirectory)
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	if exit := runOrcaStop(nil, &stdout, &stderr); exit != 0 {
		t.Fatalf("runOrcaStop() exit = %d, stderr = %q", exit, stderr.String())
	}
	if _, err := instance.Read(filepath.Join(record.StateDirectory, "instance.json")); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("instance record read error = %v", err)
	}
	if pinned, err := orcaPinned(record.StateDirectory); err != nil || pinned {
		t.Fatalf("orcaPinned() = %v, %v", pinned, err)
	}
}

func TestScopedStatusResolvesBrokerOutsideItsWorkspace(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	t.Setenv("ORCA_STATE_DIR", "")
	scope := t.TempDir()
	record, _, err := instance.Candidate(scope)
	if err != nil {
		t.Fatalf("Candidate() returned %v", err)
	}
	record.PID = 2147483647
	record.StartedAt = time.Now().UTC().Format(time.RFC3339Nano)
	if err := instance.Write(record); err != nil {
		t.Fatalf("Write() returned %v", err)
	}
	outside := t.TempDir()
	t.Chdir(outside)
	resolved, active, err := activeOrca(scope)
	if err != nil || active || resolved.StateDirectory != record.StateDirectory {
		t.Fatalf("activeOrca(%q) = %#v, %v, %v", scope, resolved, active, err)
	}
}

func TestPinnedLeaseChecksBrokerExecutable(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	candidate, _, err := instance.Candidate(t.TempDir())
	if err != nil {
		t.Fatalf("Candidate() returned %v", err)
	}
	called := false
	record, err := refreshPinnedOrca(candidate, func(record instance.Record, automatic bool) (bool, string, error) {
		called = true
		if automatic {
			t.Fatal("pinned broker started as automatic")
		}
		record.PID = os.Getpid()
		record.StartedAt = time.Now().UTC().Format(time.RFC3339Nano)
		return true, "test", instance.Write(record)
	})
	if err != nil || !called || record.PID != os.Getpid() {
		t.Fatalf("refreshPinnedOrca() = %#v, %v, called = %v", record, err, called)
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
