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
	"slices"
	"strings"
	"syscall"
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

func TestLinuxSandboxStateDirectoryAccepted(t *testing.T) {
	if runtime.GOOS != "linux" {
		t.Skip("requires Linux")
	}
	prepareErr := sqlite.PrepareStateDirectory(t.TempDir())
	if prepareErr == nil {
		return
	}
	info, err := os.Lstat(string(os.PathSeparator))
	if err != nil {
		t.Fatalf("Lstat(/) returned %v", err)
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok {
		t.Fatal("Lstat(/) returned no syscall metadata")
	}
	mountInfo, mountErr := os.ReadFile("/proc/self/mountinfo")
	overflow, overflowErr := os.ReadFile("/proc/sys/kernel/overflowuid")
	uidMap, uidMapErr := os.ReadFile("/proc/self/uid_map")
	rootMounts := make([]string, 0)
	for _, line := range strings.Split(string(mountInfo), "\n") {
		fields := strings.Fields(line)
		if len(fields) > 5 && fields[4] == string(os.PathSeparator) {
			rootMounts = append(rootMounts, line)
		}
	}
	t.Fatalf(
		"PrepareStateDirectory() error=%v; sandbox root observed: uid=%d euid=%d mode=%v mountErr=%v overflow=%q overflowErr=%v uidMap=%q uidMapErr=%v rootMounts=%q",
		prepareErr, stat.Uid, os.Geteuid(), info.Mode(), mountErr, overflow, overflowErr, uidMap, uidMapErr, rootMounts,
	)
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
	waitForSocket(t, paths.Socket, cancel, errors)
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
	branchRequest := struct {
		ID                      domain.RunForkID            `json:"id"`
		ParentWorkflowRunID     domain.WorkflowRunID        `json:"parentWorkflowRunId"`
		ChildWorkflowRunID      domain.WorkflowRunID        `json:"childWorkflowRunId"`
		RestartPointID          domain.RestartPointID       `json:"restartPointId"`
		TargetDefinitionID      domain.WorkflowDefinitionID `json:"targetWorkflowDefinitionId"`
		TargetDefinitionVersion uint64                      `json:"targetDefinitionVersion"`
		ExpectedParentVersion   domain.ResourceVersion      `json:"expectedParentVersion"`
	}{
		ID: "fork-smoke", ParentWorkflowRunID: "run-smoke", ChildWorkflowRunID: "run-smoke-branch",
		RestartPointID: "restart-smoke", TargetDefinitionID: "definition-smoke-patched",
		TargetDefinitionVersion: 2, ExpectedParentVersion: parent.Run.Metadata.ResourceVersion,
	}
	branchPayload, err := json.Marshal(branchRequest)
	if err != nil {
		t.Fatalf("Marshal() branch payload returned %v", err)
	}
	runCommand("branch", "run", branchPayload)
	resultCommand := runCommand("verification", "submit", mustJSON(t, sqlite.TaskResultRequest{
		ID: "result-smoke", NodeRunID: reserved[0].ID, Attempt: reserved[0].Attempt,
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
	branchRequest.ID = "fork-smoke-view"
	branchRequest.ChildWorkflowRunID = "run-smoke-branch-view"
	branchRequest.ExpectedParentVersion = parent.Run.Metadata.ResourceVersion
	branchPayload, err = json.Marshal(branchRequest)
	if err != nil {
		t.Fatalf("Marshal() view branch payload returned %v", err)
	}
	stdout.Reset()
	stderr.Reset()
	if exitCode := runWorkflowView([]string{
		"--state-dir", stateDirectory, "--run", "run-smoke", "--control", "branch run",
		"--payload", string(branchPayload),
	}, &stdout, &stderr); exitCode != 0 {
		t.Fatalf("branch runWorkflowView() exit = %d, stderr = %q", exitCode, stderr.String())
	}
	if !strings.Contains(stdout.String(), "control workflow.branch [succeeded]") ||
		!strings.Contains(stdout.String(), "run run-smoke-branch-view [pending]") {
		t.Fatalf("branch workflow view = %q", stdout.String())
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
	t.Setenv("ORC_STATE_DIR", stateDirectory)
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
	brokerRecord := instance.Record{
		Version: instance.Version, Scope: t.TempDir(), StateDirectory: paths.StateDirectory,
		Socket: paths.Socket, Executable: "/old/orc", PID: os.Getpid(),
	}
	if err := instance.Write(brokerRecord); err != nil {
		cancel()
		<-serveErrors
		t.Fatalf("Write(old broker) returned %v", err)
	}
	client, active, err = resolveMCPClient(stateDirectory)
	if err != nil || active || client != nil {
		cancel()
		<-serveErrors
		t.Fatalf("resolveMCPClient(unregistered) = %#v, %v, %v", client, active, err)
	}
	brokerRecord.Executable, err = orcExecutable()
	if err == nil {
		err = instance.Write(brokerRecord)
	}
	if err != nil {
		cancel()
		<-serveErrors
		t.Fatalf("update broker generation returned %v", err)
	}
	registerMCPTestSession(t, stateDirectory)
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
	registerMCPTestSession(t, stateDirectory)
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
		"orc_current_session", "workflow_list", "workflow_restart_points", "workflow_forks",
		"workflow_pause", "workflow_resume", "stage_retry", "workflow_branch", "workflow_revise",
		"worker_list", "worker_attach",
	} {
		if !names[expected] {
			t.Fatalf("MCP tools omitted %q", expected)
		}
	}
	for _, rejected := range []string{
		"planning_discover", "planning_snapshot", "planning_action", "agent_list", "agent_attach", "workflow_replay",
	} {
		if names[rejected] {
			t.Fatalf("MCP tools retained %q", rejected)
		}
	}
}

func TestMCPBindsWorkflowToCurrentOrcSession(t *testing.T) {
	stateDirectory := shortStateDirectory(t)
	paths, err := config.ResolvePaths(stateDirectory)
	if err != nil {
		t.Fatalf("ResolvePaths() returned %v", err)
	}
	record := instance.Record{
		Version: instance.Version, Scope: t.TempDir(), StateDirectory: paths.StateDirectory, Socket: paths.Socket,
	}
	if err := instance.Write(record); err != nil {
		t.Fatalf("Write() returned %v", err)
	}
	identity, found, err := plugin.ProcessIdentity(os.Getpid())
	if err != nil || !found {
		t.Fatalf("ProcessIdentity() = %d, %t, %v", identity, found, err)
	}
	session, err := instance.RegisterSession(record, instance.SessionRegistration{
		ID: "session-current", Harness: "codex", PID: os.Getpid(), ProcessIdentity: identity,
		Registration: "spawned",
	})
	if err != nil {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	t.Setenv("ORC_STATE_DIR", stateDirectory)
	t.Setenv("ORC_SESSION_ID", session.ID)

	bound := bindCurrentWorkflowSession(json.RawMessage(`{"definitionId":"plan"}`))
	var payload map[string]string
	if err := json.Unmarshal(bound, &payload); err != nil || payload["orchestrationSessionId"] != session.ID {
		t.Fatalf("bound payload = %s, %v", bound, err)
	}
	params, err := json.Marshal(mcpCallParams{
		Name: "orc_current_session", Arguments: json.RawMessage(`{"payload":{}}`),
	})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	response := callMCPTool(context.Background(), nil, mcpRequest{
		JSONRPC: mcpJSONRPCVersion, ID: json.RawMessage(`1`), Method: "tools/call", Params: params,
	})
	var result mcpCallResult
	if err := json.Unmarshal(response.Result, &result); err != nil {
		t.Fatalf("tool result = %s, %v", response.Result, err)
	}
	var current instance.Session
	if err := json.Unmarshal(result.StructuredContent, &current); err != nil || current.ID != session.ID {
		t.Fatalf("current session = %#v, %v", current, err)
	}
}

func TestMCPCallsNativeBrokerCommand(t *testing.T) {
	stateDirectory := shortStateDirectory(t)
	registerMCPTestSession(t, stateDirectory)
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
		"controls: graph patch | branch run | workflow pause | workflow resume | stage retry",
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

func registerMCPTestSession(t *testing.T, stateDirectory string) {
	t.Helper()
	identity, found, err := plugin.ProcessIdentity(os.Getpid())
	if err != nil || !found {
		t.Fatalf("ProcessIdentity() = %d, %t, %v", identity, found, err)
	}
	record := instance.Record{Version: instance.Version, StateDirectory: stateDirectory}
	session, err := instance.RegisterSession(record, instance.SessionRegistration{
		ID: "mcp-test-session", Harness: "codex", PID: os.Getpid(), ProcessIdentity: identity,
		Registration: "injected",
	})
	if err != nil {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	t.Setenv("ORC_SESSION_ID", session.ID)
}

func TestOrcPromptUsesControllerEnvironment(t *testing.T) {
	t.Setenv("ORC_SCOPE", "")
	var output bytes.Buffer
	if code := runOrcPrompt(nil, &output, io.Discard); code != 0 || output.Len() != 0 {
		t.Fatalf("inactive prompt = %q with code %d", output.String(), code)
	}

	t.Setenv("ORC_SCOPE", "/workspace/project")
	if code := runOrcPrompt(nil, &output, io.Discard); code != 0 || output.String() != "|⚔|" {
		t.Fatalf("active prompt = %q with code %d", output.String(), code)
	}
}

func TestResumeHookReusesNativeSessionIdentity(t *testing.T) {
	record := instance.Record{Version: instance.Version, Scope: "/workspace", StateDirectory: t.TempDir()}
	previous, err := instance.RegisterSession(record, instance.SessionRegistration{
		ID: "session-old", Harness: "codex", NativeSessionID: "thread-42",
		Status: "disconnected", Registration: "spawned",
	})
	if err != nil {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	t.Setenv("ORC_SESSION_ENROLL_PID", "42")
	resumed, err := instance.RegisterSession(record, instance.SessionRegistration{
		Harness: "codex", NativeSessionID: "thread-42", PID: 42,
		Status: "working", Registration: orcSessionRegistrationSource("hook", 42),
	})
	if err != nil || resumed.ID != previous.ID || resumed.NativeSessionID != "thread-42" {
		t.Fatalf("resumed session = %#v, %v", resumed, err)
	}
}

func TestSessionHookInputFindsHarnessIdentityAndDirectory(t *testing.T) {
	t.Parallel()

	for _, test := range []struct {
		name  string
		input string
		want  string
	}{
		{name: "claude", input: `{"session_id":"claude-42","cwd":"/workspace/claude"}`, want: "claude-42"},
		{name: "codex", input: `{"thread_id":"codex-42","cwd":"/workspace/codex"}`, want: "codex-42"},
	} {
		t.Run(test.name, func(t *testing.T) {
			registration, err := readOrcSessionHookInput(strings.NewReader(test.input))
			if err != nil || registration.NativeSessionID != test.want ||
				registration.Directory != "/workspace/"+test.name {
				t.Fatalf("readOrcSessionHookInput() = %#v, %v", registration, err)
			}
		})
	}
}

func TestResumeHookEnrollsUnseenNativeSession(t *testing.T) {
	record := instance.Record{Version: instance.Version, Scope: "/workspace", StateDirectory: t.TempDir()}
	t.Setenv("ORC_SESSION_ENROLL_PID", "42")
	registered, err := instance.RegisterSession(record, instance.SessionRegistration{
		Harness: "codex", NativeSessionID: "thread-new", PID: 42,
		Status: "working", Registration: orcSessionRegistrationSource("hook", 42),
	})
	if err != nil || registered.ID == "" || registered.NativeSessionID != "thread-new" {
		t.Fatalf("registered session = %#v, %v", registered, err)
	}
}

func TestResumeEnrollmentDoesNotAuthorizeAnotherProcess(t *testing.T) {
	record := instance.Record{Version: instance.Version, Scope: "/workspace", StateDirectory: t.TempDir()}
	t.Setenv("ORC_SESSION_ENROLL_PID", "42")
	_, err := instance.RegisterSession(record, instance.SessionRegistration{
		Harness: "codex", NativeSessionID: "thread-other", PID: 43,
		Status: "working", Registration: orcSessionRegistrationSource("hook", 43),
	})
	if !errors.Is(err, instance.ErrSessionNotRegistered) {
		t.Fatalf("RegisterSession() returned %v", err)
	}
}

func TestControllerEnvironmentClearsInheritedSessionIdentities(t *testing.T) {
	record := instance.Record{Scope: "/workspace", Socket: "/state/broker.sock", StateDirectory: "/state"}
	parent := []string{
		"ORC_SESSION_ID=parent-orc", "ORC_SESSION_ENROLL_PID=11",
		"CLAUDE_CODE_SESSION_ID=parent-claude", "CODEX_SESSION_ID=parent-codex",
		"CODEX_THREAD_ID=parent-thread", "KEEP=value",
	}
	for _, test := range []struct {
		name      string
		resume    bool
		sessionID string
		wantOrc   string
		wantPID   string
	}{
		{name: "run", sessionID: "session-run", wantOrc: "ORC_SESSION_ID=session-run", wantPID: "ORC_SESSION_ENROLL_PID="},
		{name: "resume", resume: true, wantOrc: "ORC_SESSION_ID=", wantPID: "ORC_SESSION_ENROLL_PID=42"},
	} {
		t.Run(test.name, func(t *testing.T) {
			environment := withEnvironment(parent,
				orcControllerEnvironmentValues("codex", record, test.sessionID, test.resume, 42))
			for _, expected := range []string{
				test.wantOrc, test.wantPID, "CLAUDE_CODE_SESSION_ID=", "CODEX_SESSION_ID=", "CODEX_THREAD_ID=", "KEEP=value",
			} {
				if !slices.Contains(environment, expected) {
					t.Fatalf("%s environment omitted %q: %#v", test.name, expected, environment)
				}
			}
			joined := strings.Join(environment, "\n")
			for _, inherited := range []string{"parent-orc", "parent-claude", "parent-codex", "parent-thread"} {
				if strings.Contains(joined, inherited) {
					t.Fatalf("%s environment kept %q: %#v", test.name, inherited, environment)
				}
			}
		})
	}
}

func TestOrcPickerUsesRecentAgentAndResponsiveLayout(t *testing.T) {
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

	model := orcUIModel{
		record: instance.Record{Scope: "/workspace/project", PID: 42},
		active: true,
		agents: available,
		help:   help.New(),
	}
	resized, _ := model.Update(tea.WindowSizeMsg{Width: 110, Height: 30})
	model = resized.(orcUIModel)
	view := ansi.Strip(model.View())
	for _, expected := range []string{"⚔ orc", "running", "graph  0 sessions", "<space> actions"} {
		if !strings.Contains(view, expected) {
			t.Fatalf("View() omitted %q:\n%s", expected, view)
		}
	}
	withLeader, _ := model.Update(tea.KeyMsg{Type: tea.KeySpace})
	picker, _ := withLeader.(orcUIModel).Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'n'}})
	if pickerView := ansi.Strip(picker.(orcUIModel).View()); !strings.Contains(pickerView, "new session") ||
		!strings.Contains(pickerView, "Codex") {
		t.Fatalf("controller picker = %q", pickerView)
	}
	selected, command := picker.(orcUIModel).Update(tea.KeyMsg{Type: tea.KeyEnter})
	if command == nil || selected.(orcUIModel).selected != "codex" {
		t.Fatalf("enter selected %#v", selected)
	}
	resumed, command := picker.(orcUIModel).Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'R'}})
	if command == nil || resumed.(orcUIModel).selected != "codex" || !resumed.(orcUIModel).selectedResume {
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
	model.graphMode = true
	graph := ansi.Strip(model.View())
	for _, expected := range []string{"run · plan-42", "stage · draft", "depends on  research.notes -> draft.context"} {
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
	if command != nil || !confirmation.(orcUIModel).confirmReplay {
		t.Fatalf("first replay key = %#v, command = %#v", confirmation, command)
	}
	confirmed, command := confirmation.(orcUIModel).Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'f'}})
	if command == nil || confirmed.(orcUIModel).confirmReplay {
		t.Fatalf("second replay key = %#v, command = %#v", confirmed, command)
	}

	model.view = orcSessionsView
	model.sessions = []instance.Session{{
		ID: "worker-42", Role: "worker", Harness: "pi", Status: "running", Registration: "managed",
		Capabilities: []string{"native-attachment"},
	}}
	workerView := ansi.Strip(model.View())
	for _, expected := range []string{"graph  1 sessions", "worker-42", "worker", "managed", "enter attach"} {
		if !strings.Contains(workerView, expected) {
			t.Fatalf("worker View() omitted %q:\n%s", expected, workerView)
		}
	}
	if details := ansi.Strip(model.inspectorBody(12)); !strings.Contains(details, "native-attachment") {
		t.Fatalf("worker details omitted capability:\n%s", details)
	}
	attached, command := model.Update(tea.KeyMsg{Type: tea.KeyEnter})
	if command == nil || attached.(orcUIModel).messageError {
		t.Fatalf("enter attachment = %#v, command = %#v", attached, command)
	}
}

func TestOrcSessionGraphNestsWorkflowWorkersUnderOrchestrator(t *testing.T) {
	rootID := domain.SessionID("root-session")
	model := orcUIModel{
		view: orcSessionsView, help: help.New(), width: 100, height: 24,
		workflows: []domain.WorkflowRun{{ID: "run-1", OrchestrationSession: &rootID}},
		workers:   []domain.Session{{ID: "worker-session", WorkflowRunID: "run-1"}},
		sessions: []instance.Session{
			{ID: "worker-session", Role: "worker", Harness: "codex", Status: "running", Registration: "managed"},
			{ID: "root-session", Role: "controller", Harness: "claude", Status: "working", Registration: "observed"},
		},
	}

	entries := model.sessionTreeEntries()
	if len(entries) != 2 || model.sessions[entries[0].sessionIndex].ID != "root-session" ||
		model.sessions[entries[1].sessionIndex].ID != "worker-session" || entries[1].depth != 1 {
		t.Fatalf("session tree = %#v", entries)
	}
	view := ansi.Strip(model.View())
	for _, expected := range []string{"orchestrator · claude", "id  root-session", "worker · codex", "id  worker-session", "└─"} {
		if !strings.Contains(view, expected) {
			t.Fatalf("session graph omitted %q:\n%s", expected, view)
		}
	}
}

func TestOrcSessionTreeKeepsSiblingOrderAndFilteredAncestor(t *testing.T) {
	rootID := domain.SessionID("root-session")
	model := orcUIModel{
		view: orcSessionsView, sessionCursor: 1,
		workflows: []domain.WorkflowRun{{ID: "run-1", OrchestrationSession: &rootID}},
		workers: []domain.Session{
			{ID: "worker-b", WorkflowRunID: "run-1"},
			{ID: "worker-a", WorkflowRunID: "run-1"},
		},
		sessions: []instance.Session{
			{ID: "worker-b", Role: "worker"},
			{ID: "root-session", Role: "controller"},
			{ID: "worker-a", Role: "worker"},
		},
	}
	want := []string{"root-session", "worker-b", "worker-a"}
	for range 20 {
		entries := model.sessionTreeEntries()
		for index, entry := range entries {
			if got := model.sessions[entry.sessionIndex].ID; got != want[index] {
				t.Fatalf("session tree order = %#v", entries)
			}
		}
	}
	if strip := ansi.Strip(model.resourceStrip()); !strings.Contains(strip, "session 1/3") {
		t.Fatalf("root resource position = %q", strip)
	}
	model.query = "worker-a"
	entries := model.matchingSessionTreeEntries()
	if len(entries) != 2 || model.sessions[entries[0].sessionIndex].ID != "root-session" ||
		model.sessions[entries[1].sessionIndex].ID != "worker-a" {
		t.Fatalf("filtered session tree = %#v", entries)
	}
}

func TestOrcExplorerUsesWideSplitAndPaneFocus(t *testing.T) {
	model := orcUIModel{
		view: orcSessionsView, help: help.New(), width: 100, height: 24, explorer: true,
		sessions: []instance.Session{{ID: "session-1", Harness: "codex", Status: "working"}},
	}
	view := ansi.Strip(model.View())
	if lines := strings.Count(view, "\n") + 1; lines != 24 || !strings.Contains(view, "explorer") ||
		!strings.Contains(view, "graph  1 sessions") || !strings.Contains(view, "details") {
		t.Fatalf("wide explorer has %d lines:\n%s", lines, view)
	}
	focused, _ := model.Update(tea.KeyMsg{Type: tea.KeyCtrlH})
	if focused.(orcUIModel).focus != orcExplorerFocus {
		t.Fatalf("ctrl+h focus = %d", focused.(orcUIModel).focus)
	}
	focused, _ = focused.(orcUIModel).Update(tea.KeyMsg{Type: tea.KeyCtrlL})
	if focused.(orcUIModel).focus != orcGraphFocus {
		t.Fatalf("ctrl+l focus = %d", focused.(orcUIModel).focus)
	}
	model.width = 40
	model.height = 10
	narrow := ansi.Strip(model.View())
	if lines := strings.Count(narrow, "\n") + 1; lines != 10 || strings.Contains(narrow, "explorer") ||
		strings.Contains(narrow, "details") || !strings.Contains(narrow, "session-1") {
		t.Fatalf("narrow graph has %d lines:\n%s", lines, narrow)
	}
}

func TestOrcNarrowDetailsReplaceGraphPane(t *testing.T) {
	model := orcUIModel{
		view: orcSessionsView, help: help.New(), width: 60, height: 16, focus: orcDetailFocus,
		sessions: []instance.Session{{ID: "session-1", Harness: "codex", Status: "working", Registration: "injected"}},
	}
	view := ansi.Strip(model.View())
	if !strings.Contains(view, "details") || !strings.Contains(view, "session-1") || strings.Contains(view, "graph  1 sessions") {
		t.Fatalf("narrow details view:\n%s", view)
	}
}

func TestOrcNarrowExplorerUsesOnePane(t *testing.T) {
	model := orcUIModel{
		view: orcSessionsView, help: help.New(), width: 60, height: 16, explorer: true,
		focus:    orcExplorerFocus,
		sessions: []instance.Session{{ID: "session-1", Harness: "codex", Status: "working"}},
	}
	explorer := ansi.Strip(model.View())
	if lines := strings.Count(explorer, "\n") + 1; lines != 16 || !strings.Contains(explorer, "explorer") ||
		strings.Contains(explorer, "details") {
		t.Fatalf("narrow explorer has %d lines:\n%s", lines, explorer)
	}
	model.message = "Session is unavailable"
	model.messageError = true
	explorer = ansi.Strip(model.View())
	if !strings.Contains(explorer, "Session is unavailable") || strings.Count(explorer, "\n")+1 != 16 {
		t.Fatalf("narrow explorer omitted error:\n%s", explorer)
	}
	updated, _ := model.Update(tea.KeyMsg{Type: tea.KeyCtrlL})
	graph := ansi.Strip(updated.(orcUIModel).View())
	if strings.Contains(graph, "╭─ explorer") || !strings.Contains(graph, "graph  1 sessions") {
		t.Fatalf("ctrl+l did not restore graph:\n%s", graph)
	}
}

func TestOrcNarrowDetailsFooterDescribesScrolling(t *testing.T) {
	model := orcUIModel{width: 60, focus: orcDetailFocus}
	footer := ansi.Strip(model.controlFooter())
	if !strings.Contains(footer, "j/k scroll") || !strings.Contains(footer, "ctrl+k graph") ||
		strings.Contains(footer, "j/k select") {
		t.Fatalf("narrow details footer = %q", footer)
	}
}

func TestOrcNarrowExplorerFooterShowsGraphReturn(t *testing.T) {
	model := orcUIModel{width: 60, focus: orcExplorerFocus, explorer: true}
	footer := ansi.Strip(model.controlFooter())
	if !strings.Contains(footer, "ctrl+l graph") {
		t.Fatalf("narrow explorer footer = %q", footer)
	}
}

func TestOrcCompactFooterKeepsHelpAndQuit(t *testing.T) {
	for _, width := range []int{70, 80} {
		model := orcUIModel{
			view: orcSessionsView, help: help.New(), width: width, height: 24,
			sessions: []instance.Session{{
				ID: "session-with-a-long-identifier", Harness: "codex", Status: "working",
				Registration: "observed", Pane: "7", Mux: 42,
			}},
		}
		footer := ansi.Strip(model.bottomFooter())
		if !strings.Contains(footer, "? help") || !strings.Contains(footer, "q quit") || ansi.StringWidth(footer) > width {
			t.Fatalf("%d-column footer = %q", width, footer)
		}
		header := ansi.Strip(model.header(width))
		if !strings.Contains(header, "broker stopped") || ansi.StringWidth(header) > width {
			t.Fatalf("%d-column header = %q", width, header)
		}
		model.active = true
		header = ansi.Strip(model.header(width))
		if !strings.Contains(header, "broker running · 1 sessions") || ansi.StringWidth(header) > width {
			t.Fatalf("%d-column active header = %q", width, header)
		}
		model.leader = true
		leader := ansi.Strip(model.bottomFooter())
		if !strings.Contains(leader, "? help") || ansi.StringWidth(leader) > width {
			t.Fatalf("%d-column leader footer = %q", width, leader)
		}
	}
}

func TestOrcMinimumWidthFooterKeepsAttachmentHelpAndQuit(t *testing.T) {
	model := orcUIModel{
		view: orcSessionsView, width: 40, height: 10,
		sessions: []instance.Session{{
			ID: "session-1", Registration: "observed", Status: "working", Pane: "7", Mux: 42,
		}},
	}
	footer := ansi.Strip(model.bottomFooter())
	for _, expected := range []string{"enter attach", "? help", "q quit"} {
		if !strings.Contains(footer, expected) {
			t.Fatalf("40-column footer omitted %q: %q", expected, footer)
		}
	}
	if ansi.StringWidth(footer) > 40 {
		t.Fatalf("40-column footer has width %d: %q", ansi.StringWidth(footer), footer)
	}
	model.message = "Connected session-1"
	view := ansi.Strip(model.View())
	for _, expected := range []string{"enter attach", "? help", "q quit"} {
		if !strings.Contains(view, expected) {
			t.Fatalf("40-column message view omitted %q: %q", expected, view)
		}
	}
	if !strings.Contains(view, "Connected session-1") || strings.Count(view, "\n")+1 != 10 {
		t.Fatalf("40-column message view = %q", view)
	}
}

func TestOrcMinimumWidthPickerKeepsCancel(t *testing.T) {
	model := orcUIModel{controllerPicker: true, width: 40, height: 10}
	view := ansi.Strip(model.View())
	for _, expected := range []string{"enter new", "R resume", "esc cancel"} {
		if !strings.Contains(view, expected) {
			t.Fatalf("40-column picker omitted %q: %q", expected, view)
		}
	}
	if lines := strings.Count(view, "\n") + 1; lines != 10 {
		t.Fatalf("40-column picker has %d lines: %q", lines, view)
	}
}

func TestOrcMinimumWidthFilterKeepsControls(t *testing.T) {
	filter := textinput.New()
	filter.Prompt = "/"
	model := orcUIModel{view: orcSessionsView, filtering: true, filter: filter, width: 40, height: 10}
	resizeTextInput(&model.filter, orcFilterInputWidth(model.width))
	model.filter.SetValue("abcdefghijklmnopqrstuvwxyz0123456789")
	model.filter.Focus()
	view := ansi.Strip(model.View())
	for _, expected := range []string{"6789", "enter apply", "esc cancel"} {
		if !strings.Contains(view, expected) {
			t.Fatalf("40-column filter omitted %q: %q", expected, view)
		}
	}
	if lines := strings.Count(view, "\n") + 1; lines != 10 {
		t.Fatalf("40-column filter has %d lines: %q", lines, view)
	}
}

func TestOrcCompactLeaderAdvertisesVisiblePanes(t *testing.T) {
	model := orcUIModel{view: orcSessionsView, leader: true, width: 40, height: 10}
	footer := ansi.Strip(model.controlFooter())
	if strings.Contains(footer, "e tree") || strings.Contains(footer, "i details") {
		t.Fatalf("40-column leader advertises hidden panes: %q", footer)
	}
	model.width = 44
	footer = ansi.Strip(model.controlFooter())
	if !strings.Contains(footer, "e tree") || strings.Contains(footer, "i details") ||
		!strings.Contains(footer, "? help") || ansi.StringWidth(footer) > 44 {
		t.Fatalf("44-column leader actions = %q", footer)
	}
	model.width = 72
	model.height = 18
	footer = ansi.Strip(model.controlFooter())
	if !strings.Contains(footer, "e tree") || !strings.Contains(footer, "i details") {
		t.Fatalf("72-column leader actions = %q", footer)
	}
}

func TestOrcLeaderQuestionMarkOpensHelp(t *testing.T) {
	model := orcUIModel{view: orcWorkflowsView, leader: true, help: help.New(), width: 80, height: 24}
	updated, command := model.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'?'}})
	result := updated.(orcUIModel)
	if command != nil || result.leader || !result.help.ShowAll {
		t.Fatalf("leader help = %#v, command = %#v", result, command)
	}
}

func TestOrcCompactLeaderShowsContextActionsWithinWidth(t *testing.T) {
	model := orcUIModel{
		view: orcSessionsView, leader: true, width: 92, height: 24,
		sessions: []instance.Session{{
			ID: "session-1", Registration: "observed", TraceSessionID: "trace-1",
		}},
	}
	footer := ansi.Strip(model.controlFooter())
	if !strings.Contains(footer, "r connect") || !strings.Contains(footer, "t traces") ||
		!strings.Contains(footer, "? help") || ansi.StringWidth(footer) > 92 {
		t.Fatalf("92-column observed actions = %q", footer)
	}
	model.sessions[0].Registration = "injected"
	footer = ansi.Strip(model.controlFooter())
	if !strings.Contains(footer, "x disconnect") || !strings.Contains(footer, "t traces") ||
		!strings.Contains(footer, "? help") || ansi.StringWidth(footer) > 92 {
		t.Fatalf("92-column connected actions = %q", footer)
	}
	model.width = 40
	model.height = 10
	footer = ansi.Strip(model.controlFooter())
	if !strings.Contains(footer, "t traces") || !strings.Contains(footer, "? help") || ansi.StringWidth(footer) > 40 {
		t.Fatalf("40-column trace actions = %q", footer)
	}
}

func TestOrcControlPlaneOrchestratorOffersTraces(t *testing.T) {
	model := orcUIModel{
		view: orcWorkflowsView, workflowRootSelected: true, leader: true, width: 80, height: 24,
		orchestratorID: "controller",
		sessions: []instance.Session{{
			ID: "controller", Role: "controller", TraceSessionID: "trace-controller",
		}},
	}
	session, found := model.selectedTrace()
	if !found || session.ID != "controller" {
		t.Fatalf("selectedTrace() = %#v, %t", session, found)
	}
	if footer := ansi.Strip(model.controlFooter()); !strings.Contains(footer, "t traces") {
		t.Fatalf("control-plane leader actions = %q", footer)
	}
}

func TestOrcWorkflowGraphUsesOrchestratorAndWorkerCards(t *testing.T) {
	rootID := domain.SessionID("root-session")
	workerID := domain.SessionID("worker-session")
	secondWorkerID := domain.SessionID("review-session")
	model := orcUIModel{
		view: orcWorkflowsView, graphMode: true, help: help.New(), width: 100, height: 24, explorer: true,
		orchestratorID: string(rootID),
		workflows:      []domain.WorkflowRun{{ID: "run-1", State: domain.WorkflowRunStateRunning, OrchestrationSession: &rootID}},
		workflow: workflowViewResult{
			Run: domain.WorkflowRun{ID: "run-1", State: domain.WorkflowRunStateRunning, OrchestrationSession: &rootID},
			Nodes: []domain.NodeRun{
				{ID: "node-1", NodeKey: "build", Adapter: "codex", SessionID: &workerID},
				{ID: "node-2", NodeKey: "review", Adapter: "claude", SessionID: &secondWorkerID},
			},
		},
		definition: workflowmodel.Definition{Edges: []workflowmodel.Edge{{From: "build", To: "review"}}},
		sessions: []instance.Session{
			{ID: string(rootID), Role: "controller", Harness: "codex", Status: "working"},
			{ID: string(workerID), Role: "worker", Harness: "codex", Status: "running", Registration: "managed"},
			{ID: string(secondWorkerID), Role: "worker", Harness: "claude", Status: "running", Registration: "managed"},
		},
	}
	view := ansi.Strip(model.View())
	for _, expected := range []string{
		"orchestrator root-session", "run run-1", "stage build", "worker worker-session",
		"stage review", "worker review-session", "adapter     codex", "explorer",
	} {
		if !strings.Contains(view, expected) {
			t.Fatalf("workflow graph omitted %q:\n%s", expected, view)
		}
	}
}

func TestOrcWorkflowGraphBoundsCyclesAndExplorerWidth(t *testing.T) {
	model := orcUIModel{
		view: orcWorkflowsView, graphMode: true, help: help.New(), width: 72, height: 18, explorer: true,
		workflowRootSelected: true,
		workflows:            []domain.WorkflowRun{{ID: "run-1"}},
		workflow: workflowViewResult{
			Run: domain.WorkflowRun{ID: "run-1"},
			Nodes: []domain.NodeRun{
				{ID: "node-a", NodeKey: "a", Adapter: "codex"},
				{ID: "node-b", NodeKey: "b", Adapter: "claude"},
			},
		},
		definition: workflowmodel.Definition{Edges: []workflowmodel.Edge{{From: "a", To: "b"}, {From: "b", To: "a"}}},
	}
	for node, depth := range model.workflowNodeDepths(model.workflowNodes()) {
		if depth < 1 || depth > 2 {
			t.Fatalf("cycle depth for %s = %d", node, depth)
		}
	}
	view := ansi.Strip(model.View())
	for _, line := range strings.Split(view, "\n") {
		if ansi.StringWidth(line) > 72 {
			t.Fatalf("72-column graph line has width %d: %q", ansi.StringWidth(line), line)
		}
	}
	if explorer := ansi.Strip(model.workflowExplorerBody(1)); !strings.Contains(explorer, "run-1") {
		t.Fatalf("selected workflow root scrolled out of explorer: %q", explorer)
	}
}

func TestOrcWorkflowGraphUsesTopologicalOrderAndOneSelection(t *testing.T) {
	model := orcUIModel{
		view: orcWorkflowsView, graphMode: true, explorer: true, workflowRootSelected: true,
		width: 100, height: 24,
		workflows: []domain.WorkflowRun{{ID: "run-1"}},
		workflow: workflowViewResult{
			Run: domain.WorkflowRun{ID: "run-1"},
			Nodes: []domain.NodeRun{
				{ID: "child", NodeKey: "a-child"},
				{ID: "parent", NodeKey: "z-parent"},
			},
		},
		definition: workflowmodel.Definition{Edges: []workflowmodel.Edge{{From: "z-parent", To: "a-child"}}},
	}
	nodes := model.workflowNodes()
	if len(nodes) != 2 || nodes[0].NodeKey != "z-parent" || nodes[1].NodeKey != "a-child" {
		t.Fatalf("workflow order = %#v", nodes)
	}
	view := ansi.Strip(model.View())
	if strings.Count(view, "▸") != 1 {
		t.Fatalf("workflow root selection = %q", view)
	}
	if parents := model.workflowNodeParents("a-child"); len(parents) != 1 || parents[0] != "z-parent" {
		t.Fatalf("workflow child parents = %#v", parents)
	}
}

func TestOrcNarrowWorkflowKeepsSelectedNodeVisible(t *testing.T) {
	model := orcUIModel{
		view: orcWorkflowsView, graphMode: true, workflowRootSelected: true,
		width: 60, height: 16,
		workflows: []domain.WorkflowRun{{ID: "run-many"}},
		workflow:  workflowViewResult{Run: domain.WorkflowRun{ID: "run-many"}},
	}
	for index := 0; index < 20; index++ {
		model.workflow.Nodes = append(model.workflow.Nodes, domain.NodeRun{
			ID: domain.NodeRunID(fmt.Sprintf("node-%02d", index)), NodeKey: domain.NodeKey(fmt.Sprintf("node-%02d", index)),
		})
	}
	updated, _ := model.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'G'}})
	view := ansi.Strip(updated.(orcUIModel).View())
	if !strings.Contains(view, "node-19") || !strings.Contains(view, "▸") {
		t.Fatalf("narrow selected node is outside viewport:\n%s", view)
	}
}

func TestOrcHelpHasOneAttachActionAndNoPlaceholderTab(t *testing.T) {
	model := orcUIModel{view: orcSessionsView, help: help.New(), width: 90, height: 24}
	helpText := ansi.Strip(strings.Join(model.fullHelpLines(), "\n"))
	if strings.Contains(helpText, "<space>c") || strings.Contains(helpText, "events") ||
		strings.Contains(helpText, "tab") || !strings.Contains(helpText, "/                 filter resources") ||
		!strings.Contains(helpText, "connect an observed session") || strings.Contains(helpText, "select a restart point") ||
		strings.Count(helpText, "open or attach the selected object") != 1 {
		t.Fatalf("help exposes duplicate or placeholder actions:\n%s", helpText)
	}
}

func TestOrcHelpUsesConnectionTerms(t *testing.T) {
	if strings.Contains(orcUsage, "orc inject") || strings.Contains(orcUsage, "orc eject") ||
		!strings.Contains(orcUsage, "orc connect") || !strings.Contains(orcUsage, "orc disconnect") {
		t.Fatalf("Orc help uses inconsistent connection terms:\n%s", orcUsage)
	}
	for _, registration := range []string{"registered", "spawned", "resume", "injected"} {
		if connection := sessionConnection(instance.Session{Registration: registration}); connection != "connected" {
			t.Fatalf("%s registration displays as %q", registration, connection)
		}
		if !canDisconnectOrcSession(instance.Session{Registration: registration}) {
			t.Fatalf("%s registration cannot disconnect", registration)
		}
	}
	for origin, expected := range map[string]string{"injected": "connected", "spawned": "launched", "resume": "resumed"} {
		if displayed := sessionOrigin(instance.Session{Origin: origin}); displayed != expected {
			t.Fatalf("%s origin displays as %q", origin, displayed)
		}
	}
	model := orcUIModel{
		view: orcSessionsView, query: "connected",
		sessions: []instance.Session{
			{ID: "connected", Registration: "injected"},
			{ID: "observed", Registration: "observed"},
		},
	}
	entries := model.matchingSessionTreeEntries()
	if len(entries) != 1 || model.sessions[entries[0].sessionIndex].ID != "connected" {
		t.Fatalf("connected filter = %#v", entries)
	}
}

func TestOrcDisconnectUsesTopLevelErrors(t *testing.T) {
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	if exit := runOrcCommand([]string{"disconnect"}, &stdout, &stderr); exit != 2 ||
		stderr.String() != "usage: orc disconnect <session-id>\n" {
		t.Fatalf("disconnect usage exit = %d, stderr = %q", exit, stderr.String())
	}
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	t.Setenv("ORC_STATE_DIR", t.TempDir())
	t.Chdir(t.TempDir())
	stderr.Reset()
	if exit := runOrcCommand([]string{"disconnect", "session-1"}, &stdout, &stderr); exit != 1 ||
		!strings.Contains(stderr.String(), "disconnect session: orc is inactive") {
		t.Fatalf("inactive disconnect exit = %d, stderr = %q", exit, stderr.String())
	}
}

func TestOrcDisconnectActionHandlesInjectedSession(t *testing.T) {
	record := instance.Record{Version: instance.Version, Scope: t.TempDir(), StateDirectory: t.TempDir()}
	created, err := instance.RegisterSession(record, instance.SessionRegistration{
		ID: "session-injected", Harness: "codex", Status: "working", Registration: "injected",
	})
	if err != nil {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	model := orcUIModel{
		view: orcSessionsView, leader: true, record: record,
		sessions: []instance.Session{created},
	}
	updated, command := model.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'x'}})
	if command == nil {
		t.Fatalf("disconnect action = %#v, command = nil", updated)
	}
	message := command()
	if action, ok := message.(orcActionMessage); !ok || action.err != nil {
		t.Fatalf("disconnect result = %#v", message)
	}
	if _, found, err := instance.SessionByID(record, created.ID); err != nil || found {
		t.Fatalf("SessionByID() found = %v, error = %v", found, err)
	}
}

func TestOrcEnterAttachesSelectedWorkflowNode(t *testing.T) {
	sessionID := domain.SessionID("node-session")
	model := orcUIModel{
		view: orcWorkflowsView, graphMode: true, help: help.New(), width: 90, height: 24,
		workflows: []domain.WorkflowRun{{ID: "run-1"}},
		workflow: workflowViewResult{
			Run:   domain.WorkflowRun{ID: "run-1"},
			Nodes: []domain.NodeRun{{ID: "node-1", NodeKey: "build", SessionID: &sessionID}},
		},
		sessions: []instance.Session{{
			ID: "node-session", Harness: "codex", Registration: "observed", Pane: "7", Mux: 42,
		}},
	}

	view := ansi.Strip(model.View())
	if !strings.Contains(view, "enter attach") {
		t.Fatalf("workflow node omitted attachment action:\n%s", view)
	}
	updated, command := model.Update(tea.KeyMsg{Type: tea.KeyEnter})
	if command == nil || updated.(orcUIModel).messageError {
		t.Fatalf("enter attachment = %#v, command = %#v", updated, command)
	}
}

func TestOrcControlPlaneAttachesOrchestratorAndOpensRun(t *testing.T) {
	rootID := domain.SessionID("root-session")
	model := orcUIModel{
		view: orcWorkflowsView, help: help.New(), width: 90, height: 24,
		orchestratorID: string(rootID), workflowRootSelected: true,
		workflows: []domain.WorkflowRun{{ID: "run-1", OrchestrationSession: &rootID}},
		workflow: workflowViewResult{
			Run:   domain.WorkflowRun{ID: "run-1", OrchestrationSession: &rootID},
			Nodes: []domain.NodeRun{{ID: "node-1", NodeKey: "build"}},
		},
		sessions: []instance.Session{{
			ID: "root-session", Harness: "codex", Registration: "observed", Pane: "7", Mux: 42,
		}},
	}

	if footer := ansi.Strip(model.controlFooter()); !strings.Contains(footer, "enter attach") {
		t.Fatalf("orchestrator footer = %q", footer)
	}
	attached, command := model.Update(tea.KeyMsg{Type: tea.KeyEnter})
	if command == nil || attached.(orcUIModel).messageError {
		t.Fatalf("orchestrator attachment = %#v, command = %#v", attached, command)
	}

	model.workflowRootSelected = false
	if footer := ansi.Strip(model.controlFooter()); !strings.Contains(footer, "enter open") {
		t.Fatalf("run footer = %q", footer)
	}
	opened, command := model.Update(tea.KeyMsg{Type: tea.KeyEnter})
	model = opened.(orcUIModel)
	if command == nil || !model.graphMode || !model.workflowRootSelected {
		t.Fatalf("run open = %#v, command = %#v", model, command)
	}
	if footer := ansi.Strip(model.controlFooter()); !strings.Contains(footer, "enter details") {
		t.Fatalf("open run footer = %q", footer)
	}
}

func TestOrcWorkflowGraphHidesStaleRun(t *testing.T) {
	model := orcUIModel{
		view: orcWorkflowsView, graphMode: true, explorer: true, width: 90, height: 24,
		workflowCursor: 1,
		workflows:      []domain.WorkflowRun{{ID: "run-old"}, {ID: "run-new"}},
		workflow: workflowViewResult{
			Run:   domain.WorkflowRun{ID: "run-old"},
			Nodes: []domain.NodeRun{{ID: "old-node", NodeKey: "old-node"}},
		},
	}
	view := ansi.Strip(model.View())
	if !strings.Contains(view, "Loading run graph") || strings.Contains(view, "old-node") {
		t.Fatalf("stale workflow graph is visible:\n%s", view)
	}
}

func TestOrcWorkflowListHidesStaleDetails(t *testing.T) {
	model := orcUIModel{
		view: orcWorkflowsView, width: 90, height: 24,
		workflowCursor: 1,
		workflows:      []domain.WorkflowRun{{ID: "run-old"}, {ID: "run-new"}},
		workflow: workflowViewResult{
			Run: domain.WorkflowRun{ID: "run-old", State: domain.WorkflowRunStateSucceeded},
		},
	}
	details := ansi.Strip(model.inspectorBody(8))
	if !strings.Contains(details, "run-new") || strings.Contains(details, "succeeded") {
		t.Fatalf("stale workflow details are visible:\n%s", details)
	}
}

func TestOrcWorkflowRootDetailsExposeSelectedRestartPoint(t *testing.T) {
	model := orcUIModel{
		view: orcWorkflowsView, graphMode: true, workflowRootSelected: true,
		workflows: []domain.WorkflowRun{{ID: "run-1"}},
		workflow:  workflowViewResult{Run: domain.WorkflowRun{ID: "run-1"}},
		restartPoints: []domain.RestartPoint{{
			ID: "restart-1", Kind: domain.RestartPointNodeAdmission, WorkflowRunID: "run-1",
			WorkflowDefinitionID: "definition-1", DefinitionVersion: 3, EventCursor: 42,
			SnapshotID: "snapshot-1",
		}},
		forks: []domain.RunFork{{
			ParentWorkflowRunID: "run-0", ChildWorkflowRunID: "run-1", RestartPointID: "restart-1",
		}},
	}

	details := ansi.Strip(strings.Join(model.workflowRootDetailLines(), "\n"))
	for _, value := range []string{"selection     1/1", "point         restart-1", "event cursor  42",
		"definition    definition-1@3", "snapshot      snapshot-1", "parent run-0 via restart-1"} {
		if !strings.Contains(details, value) {
			t.Fatalf("restart details omitted %q:\n%s", value, details)
		}
	}
}

func TestOrcWorkflowGraphMovesBetweenRootAndWorkers(t *testing.T) {
	model := orcUIModel{
		view: orcWorkflowsView, graphMode: true, workflowRootSelected: true,
		workflows: []domain.WorkflowRun{{ID: "run-1"}},
		workflow: workflowViewResult{
			Run:   domain.WorkflowRun{ID: "run-1"},
			Nodes: []domain.NodeRun{{ID: "node-1", NodeKey: "build"}},
		},
	}
	down, _ := model.Update(tea.KeyMsg{Type: tea.KeyDown})
	model = down.(orcUIModel)
	if model.workflowRootSelected || model.selectedNodeID != "node-1" {
		t.Fatalf("down selection = %#v", model)
	}
	up, _ := model.Update(tea.KeyMsg{Type: tea.KeyUp})
	model = up.(orcUIModel)
	if !model.workflowRootSelected || model.selectedNodeID != "" {
		t.Fatalf("up selection = %#v", model)
	}
}

func TestOrcWorkflowExplorerMovesAcrossVisibleTreeRows(t *testing.T) {
	firstID := domain.SessionID("root-1")
	secondID := domain.SessionID("root-2")
	model := orcUIModel{
		view: orcWorkflowsView, explorer: true, focus: orcExplorerFocus, workflowRootSelected: true,
		orchestratorID: string(firstID), width: 100,
		sessions: []instance.Session{
			{ID: string(firstID), Role: "controller", Status: "working", Registration: "registered"},
			{ID: string(secondID), Role: "controller", Status: "waiting", Registration: "registered"},
		},
		workflows: []domain.WorkflowRun{
			{ID: "run-1", OrchestrationSession: &firstID},
			{ID: "run-2", OrchestrationSession: &secondID},
		},
	}

	updated, _ := model.Update(tea.KeyMsg{Type: tea.KeyDown})
	model = updated.(orcUIModel)
	if model.workflowRootSelected || model.workflowCursor != 0 || model.orchestratorID != string(firstID) {
		t.Fatalf("run selection = %#v", model)
	}
	if explorer := ansi.Strip(model.workflowExplorerBody(8)); !strings.Contains(explorer, "▸  └─ · run-1") {
		t.Fatalf("selected run is not visible in explorer:\n%s", explorer)
	}

	updated, _ = model.Update(tea.KeyMsg{Type: tea.KeyDown})
	model = updated.(orcUIModel)
	if !model.workflowRootSelected || model.orchestratorID != string(secondID) {
		t.Fatalf("next orchestrator selection = %#v", model)
	}
}

func TestOrcGraphExplorerMovesAcrossRunStages(t *testing.T) {
	model := orcUIModel{
		view: orcWorkflowsView, graphMode: true, explorer: true, focus: orcExplorerFocus,
		workflowRootSelected: true,
		workflows:            []domain.WorkflowRun{{ID: "run-1"}},
		workflow: workflowViewResult{
			Run:   domain.WorkflowRun{ID: "run-1"},
			Nodes: []domain.NodeRun{{ID: "node-1", NodeKey: "build"}},
		},
	}

	updated, _ := model.Update(tea.KeyMsg{Type: tea.KeyDown})
	model = updated.(orcUIModel)
	if model.workflowRootSelected || model.selectedNodeID != "node-1" {
		t.Fatalf("explorer stage selection = %#v", model)
	}
}

func TestOrcGraphExplorerKeepsSelectedStageVisibleWithWorkers(t *testing.T) {
	nodes := make([]domain.NodeRun, 12)
	for index := range nodes {
		sessionID := domain.SessionID(fmt.Sprintf("worker-%02d", index))
		nodes[index] = domain.NodeRun{
			ID: domain.NodeRunID(fmt.Sprintf("node-%02d", index)), NodeKey: domain.NodeKey(fmt.Sprintf("stage-%02d", index)),
			SessionID: &sessionID,
		}
	}
	model := orcUIModel{
		view: orcWorkflowsView, graphMode: true, explorer: true, focus: orcExplorerFocus, width: 100,
		workflowRootSelected: false, nodeCursor: 10,
		workflows: []domain.WorkflowRun{{ID: "run-1"}},
		workflow:  workflowViewResult{Run: domain.WorkflowRun{ID: "run-1"}, Nodes: nodes},
	}
	if explorer := ansi.Strip(model.workflowExplorerBody(5)); !strings.Contains(explorer, "stage-10") {
		t.Fatalf("selected stage scrolled out of explorer:\n%s", explorer)
	}
}

func TestOrcWorkflowLifecycleActionsFollowSelection(t *testing.T) {
	pauseID := domain.InterventionID("pause-1")
	model := orcUIModel{
		view: orcWorkflowsView, graphMode: true, workflowRootSelected: true,
		workflows: []domain.WorkflowRun{{ID: "run-1", State: domain.WorkflowRunStateRunning}},
		workflow:  workflowViewResult{Run: domain.WorkflowRun{ID: "run-1", State: domain.WorkflowRunStateRunning}},
		leader:    true, width: 120, height: 30,
	}
	if footer := ansi.Strip(model.controlFooter()); !strings.Contains(footer, "p pause") {
		t.Fatalf("running run footer = %q", footer)
	}
	model.workflows[0].State = domain.WorkflowRunStateWaiting
	model.workflows[0].ActivePauseID = &pauseID
	model.workflow.Run = model.workflows[0]
	if footer := ansi.Strip(model.controlFooter()); !strings.Contains(footer, "u resume") || strings.Contains(footer, "p pause") {
		t.Fatalf("waiting run footer = %q", footer)
	}
	model.workflowRootSelected = false
	model.workflow.Nodes = []domain.NodeRun{{ID: "node-1", NodeKey: "build", State: domain.NodeRunStateFailed}}
	if footer := ansi.Strip(model.controlFooter()); !strings.Contains(footer, "r retry") {
		t.Fatalf("failed stage footer = %q", footer)
	}
	model.workflow.Nodes[0].State = domain.NodeRunStateCapped
	if footer := ansi.Strip(model.controlFooter()); strings.Contains(footer, "r retry") {
		t.Fatalf("capped stage footer = %q", footer)
	}
}

func TestOrcControlPlaneKeepsUnassignedRunsVisible(t *testing.T) {
	model := orcUIModel{
		view: orcWorkflowsView, help: help.New(), width: 100, height: 24,
		workflows: []domain.WorkflowRun{{ID: "run-unassigned", State: domain.WorkflowRunStatePending}},
	}
	if err := model.ensureOrchestratorSelection(); err != nil {
		t.Fatalf("ensureOrchestratorSelection() returned %v", err)
	}
	indices := model.matchingWorkflowIndices()
	if model.orchestratorID != orcUnassignedOrchestratorID || len(indices) != 1 || indices[0] != 0 {
		t.Fatalf("unassigned selection = %q, %#v", model.orchestratorID, indices)
	}
	if view := ansi.Strip(model.View()); !strings.Contains(view, "unassigned runs") || !strings.Contains(view, "run-unassigned") {
		t.Fatalf("unassigned control plane:\n%s", view)
	}
}

func TestOrcEnterExplainsUnavailableAttachment(t *testing.T) {
	model := orcUIModel{
		view: orcSessionsView, help: help.New(), width: 90, height: 24,
		sessions: []instance.Session{{ID: "detached", Harness: "codex", Registration: "observed"}},
	}

	updated, command := model.Update(tea.KeyMsg{Type: tea.KeyEnter})
	result := updated.(orcUIModel)
	if command != nil || !result.messageError || result.message != "This session is unavailable for attachment" {
		t.Fatalf("unavailable attachment = %#v, command = %#v", result, command)
	}
}

func TestOrcEnterDoesNotAttachDisconnectedSession(t *testing.T) {
	model := orcUIModel{
		view: orcSessionsView, help: help.New(), width: 90, height: 24,
		sessions: []instance.Session{{
			ID: "disconnected", Harness: "codex", Registration: "registered",
			Status: "disconnected", Pane: "7", Mux: 42,
		}},
	}

	if view := ansi.Strip(model.View()); strings.Contains(view, "enter attach") {
		t.Fatalf("disconnected session advertised attachment:\n%s", view)
	}
	updated, command := model.Update(tea.KeyMsg{Type: tea.KeyEnter})
	if command != nil || !updated.(orcUIModel).messageError {
		t.Fatalf("disconnected attachment = %#v, command = %#v", updated, command)
	}
}

func TestOrcEnterPromptsToResumeDisconnectedSessionInSplit(t *testing.T) {
	agent := agents.Agent{Name: "codex", Label: "Codex", Command: "codex"}
	agent.Launch.ResumeArgs = []string{"resume"}
	model := orcUIModel{
		view: orcSessionsView, help: help.New(), width: 90, height: 24,
		agents: []agents.Agent{agent},
		sessions: []instance.Session{{
			ID: "disconnected", Harness: "codex", NativeSessionID: "native-42",
			Directory: "/workspace/project", Registration: "registered", Status: "disconnected",
		}},
	}

	if footer := ansi.Strip(model.controlFooter()); !strings.Contains(footer, "enter reopen") {
		t.Fatalf("disconnected session footer = %q", footer)
	}
	updated, command := model.Update(tea.KeyMsg{Type: tea.KeyEnter})
	model = updated.(orcUIModel)
	if command != nil || model.openSession != "disconnected" || model.messageError ||
		model.message != "Resume Codex: h left, j down, k up, l right, t traces, d details" {
		t.Fatalf("open prompt = %#v, command = %#v", model, command)
	}
	if footer := ansi.Strip(model.controlFooter()); !strings.Contains(footer, "h left") ||
		!strings.Contains(footer, "l right") || !strings.Contains(footer, "esc cancel") {
		t.Fatalf("open prompt footer = %q", footer)
	}
	updated, command = model.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'h'}})
	model = updated.(orcUIModel)
	if command == nil || model.openSession != "" || model.messageError ||
		model.message != "Opening Codex in a left split" {
		t.Fatalf("open confirmation = %#v, command = %#v", model, command)
	}
}

func TestOrcSessionSplitArgumentsResumeExactConversation(t *testing.T) {
	session := instance.Session{
		Harness: "codex", NativeSessionID: "native-42", Directory: "/workspace/project",
	}
	arguments := orcSessionSplitArguments("/nix/store/orc/bin/orc", "7", session, true, "right")
	want := []string{
		"cli", "--no-auto-start", "split-pane", "--pane-id", "7", "--right", "--percent", "50",
		"--cwd", "/workspace/project", "--", "/nix/store/orc/bin/orc", "resume", "codex", "--", "native-42",
	}
	if !slices.Equal(arguments, want) {
		t.Fatalf("split arguments = %q, want %q", arguments, want)
	}
}

func TestOrcSessionSplitUsesPackagedExecutable(t *testing.T) {
	executable := filepath.Join(t.TempDir(), "orc")
	if err := os.WriteFile(executable, []byte("fixture"), 0o700); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	t.Setenv("ORC_EXECUTABLE", executable)
	resolved, err := orcExecutable()
	if err != nil {
		t.Fatalf("orcExecutable() returned %v", err)
	}
	arguments := orcSessionSplitArguments(
		resolved, "7", instance.Session{Harness: "codex"}, false, "right",
	)
	if !slices.Contains(arguments, resolved) {
		t.Fatalf("split arguments omitted packaged executable: %q", arguments)
	}
}

func TestOrcTracesSplitArgumentsKeepDashboardOpen(t *testing.T) {
	want := []string{
		"cli", "--no-auto-start", "split-pane", "--pane-id", "7", "--right", "--percent", "50",
		"--", "traces", "--session", "trace-42",
	}
	if got := orcTracesSplitArguments("7", "trace-42"); !slices.Equal(got, want) {
		t.Fatalf("Traces split arguments = %#v, want %#v", got, want)
	}
}

func TestOrcSessionSplitArgumentsSupportEveryDirection(t *testing.T) {
	session := instance.Session{Harness: "codex"}
	for direction, flag := range map[string]string{
		"left": "--left", "down": "--bottom", "up": "--top", "right": "--right",
	} {
		arguments := orcSessionSplitArguments("orc", "7", session, false, direction)
		if !slices.Contains(arguments, flag) {
			t.Fatalf("%s split arguments omitted %s: %q", direction, flag, arguments)
		}
	}
}

func TestOrcCLIAttachRejectsDisconnectedSession(t *testing.T) {
	session := instance.Session{
		ID: "disconnected", Status: "disconnected", Registration: "registered", Pane: "7", Mux: 42,
	}
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	if exit := focusAvailableOrcSession(session, &stdout, &stderr); exit != 1 ||
		!strings.Contains(stderr.String(), "session is unavailable") {
		t.Fatalf("disconnected attach exit = %d, stderr = %q", exit, stderr.String())
	}
}

func TestOrcEnterOpensWorkflowWithoutRootSession(t *testing.T) {
	model := orcUIModel{
		view: orcWorkflowsView, help: help.New(), width: 90, height: 24,
		workflows: []domain.WorkflowRun{{ID: "run-1"}},
		workflow:  workflowViewResult{Run: domain.WorkflowRun{ID: "run-1"}},
	}

	updated, command := model.Update(tea.KeyMsg{Type: tea.KeyEnter})
	result := updated.(orcUIModel)
	if command == nil || !result.graphMode || result.messageError {
		t.Fatalf("workflow open = %#v, command = %#v", result, command)
	}
}

func TestOrcEnterOpensWorkflowWithDisconnectedRoot(t *testing.T) {
	sessionID := domain.SessionID("root-session")
	model := orcUIModel{
		view: orcWorkflowsView, help: help.New(), width: 90, height: 24,
		workflows: []domain.WorkflowRun{{ID: "run-1", OrchestrationSession: &sessionID}},
		workflow:  workflowViewResult{Run: domain.WorkflowRun{ID: "run-1", OrchestrationSession: &sessionID}},
		sessions: []instance.Session{{
			ID: "root-session", Registration: "registered", Status: "disconnected", Pane: "1", Mux: 42,
		}},
	}

	updated, command := model.Update(tea.KeyMsg{Type: tea.KeyEnter})
	result := updated.(orcUIModel)
	if command == nil || !result.graphMode || result.messageError {
		t.Fatalf("workflow open = %#v, command = %#v", result, command)
	}
}

func TestOrcEnterDoesNotAttachStaleWorkflowDetails(t *testing.T) {
	oldSession := domain.SessionID("old-session")
	newSession := domain.SessionID("new-session")
	model := orcUIModel{
		view: orcWorkflowsView, graphMode: true, help: help.New(), width: 90, height: 24,
		workflowCursor: 1,
		workflows: []domain.WorkflowRun{
			{ID: "old-run", OrchestrationSession: &oldSession},
			{ID: "new-run", OrchestrationSession: &newSession},
		},
		workflow: workflowViewResult{
			Run:   domain.WorkflowRun{ID: "old-run", OrchestrationSession: &oldSession},
			Nodes: []domain.NodeRun{{ID: "old-node", NodeKey: "build", SessionID: &oldSession}},
		},
		sessions: []instance.Session{
			{ID: "old-session", Registration: "observed", Status: "working", Pane: "1", Mux: 42},
			{ID: "new-session", Registration: "observed", Status: "working", Pane: "2", Mux: 42},
		},
	}

	updated, command := model.Update(tea.KeyMsg{Type: tea.KeyEnter})
	result := updated.(orcUIModel)
	if command != nil || !result.messageError || result.message != "This selection has no session to attach" {
		t.Fatalf("stale workflow attachment = %#v, command = %#v", result, command)
	}
}

func TestOrcStaleWorkflowDetailsDoNotExposeTrace(t *testing.T) {
	oldSession := domain.SessionID("old-session")
	newSession := domain.SessionID("new-session")
	model := orcUIModel{
		view: orcWorkflowsView, graphMode: true, workflowCursor: 1,
		workflows: []domain.WorkflowRun{
			{ID: "old-run", OrchestrationSession: &oldSession},
			{ID: "new-run", OrchestrationSession: &newSession},
		},
		workflow: workflowViewResult{
			Run:   domain.WorkflowRun{ID: "old-run", OrchestrationSession: &oldSession},
			Nodes: []domain.NodeRun{{ID: "old-node", NodeKey: "build", SessionID: &oldSession}},
		},
		sessions: []instance.Session{
			{ID: "old-session", TraceSessionID: "trace-old"},
			{ID: "new-session", TraceSessionID: "trace-new"},
		},
	}

	if session, found := model.selectedTrace(); found {
		t.Fatalf("selectedTrace() = %#v, want unavailable while details refresh", session)
	}
}

func TestOrcWorkflowGraphUsesViewport(t *testing.T) {
	model := orcUIModel{
		view: orcWorkflowsView, width: 100, height: 24, help: help.New(), graphMode: true,
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
	if !strings.Contains(view, "rows ") || strings.Count(view, "node-") >= 39 {
		t.Fatalf("large graph has no viewport:\n%s", view)
	}
	scrolled, _ := model.Update(tea.KeyMsg{Type: tea.KeyPgDown})
	if scrolled.(orcUIModel).graphOffset == 0 {
		t.Fatal("page down did not scroll the graph")
	}
	for range 10 {
		scrolled, _ = scrolled.(orcUIModel).Update(tea.KeyMsg{Type: tea.KeyPgDown})
	}
	bottom := scrolled.(orcUIModel).graphOffset
	scrolled, _ = scrolled.(orcUIModel).Update(tea.KeyMsg{Type: tea.KeyPgUp})
	if moved := bottom - scrolled.(orcUIModel).graphOffset; moved <= 1 {
		t.Fatalf("page up moved %d rows from offset %d", moved, bottom)
	}
}

func TestOrcUIRejectsPaneThatHidesControls(t *testing.T) {
	model := orcUIModel{width: 39, height: 9, help: help.New()}
	view := ansi.Strip(model.View())
	if strings.Count(view, "\n") != 2 || !strings.Contains(view, "orc needs 40x10") ||
		!strings.Contains(view, "q quits") {
		t.Fatalf("small main UI = %q", view)
	}
	model.width = 40
	model.height = 10
	view = ansi.Strip(model.View())
	if lines := strings.Count(view, "\n") + 1; lines != 10 || !strings.Contains(view, "? help") ||
		!strings.Contains(view, "q quit") {
		t.Fatalf("40x10 main UI has %d lines: %q", lines, view)
	}
	worker := orcWorkerUIModel{width: 40, height: 10}
	view = ansi.Strip(worker.View())
	if strings.Count(view, "\n") != 2 || !strings.Contains(view, "orc needs 60x16") ||
		!strings.Contains(view, "q detaches") {
		t.Fatalf("small worker UI = %q", view)
	}
}

func TestOrcWorkerAttachmentFitsEightyByTwentyFour(t *testing.T) {
	model := orcWorkerUIModel{
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
	if lines := strings.Count(view, "\n") + 1; lines != 24 || !strings.Contains(view, "q detach") {
		t.Fatalf("80x24 worker attachment has %d lines:\n%s", lines, view)
	}
}

func TestOrcWorkerPromptKeepsControlsAtMinimumWidth(t *testing.T) {
	input := textinput.New()
	input.SetValue(strings.Repeat("prompt", 20))
	model := orcWorkerUIModel{
		width: 60, height: 16, typing: true, input: input,
		history: sqlite.SessionHistory{Session: domain.Session{
			ID: "worker-prompt", State: domain.SessionStateRunning,
		}},
	}
	view := ansi.Strip(model.View())
	for _, expected := range []string{"enter send", "esc cancel"} {
		if !strings.Contains(view, expected) {
			t.Fatalf("60-column worker prompt omitted %q: %q", expected, view)
		}
	}
	for _, line := range strings.Split(view, "\n") {
		if ansi.StringWidth(line) > 60 {
			t.Fatalf("60-column worker line has width %d: %q", ansi.StringWidth(line), line)
		}
	}
	if lines := strings.Count(view, "\n") + 1; lines != 16 {
		t.Fatalf("60x16 worker prompt has %d lines: %q", lines, view)
	}
}

func TestOrcFullHelpOnlyShowsActionsForCurrentView(t *testing.T) {
	model := orcUIModel{view: orcWorkflowsView, help: help.New(), width: 80, height: 24}
	model.help.ShowAll = true
	workflowHelp := ansi.Strip(strings.Join(model.fullHelpLines(), "\n"))
	workflowView := ansi.Strip(model.View())
	if lines := strings.Count(workflowView, "\n") + 1; lines != 24 || !strings.Contains(workflowHelp, "<space>g") ||
		!strings.Contains(workflowHelp, "select a restart point") || !strings.Contains(workflowHelp, "<space>p") ||
		!strings.Contains(workflowHelp, "<space>u") || !strings.Contains(workflowHelp, "<space>r") {
		t.Fatalf("80x24 workflow help has %d lines:\n%s", lines, workflowView)
	}
	model.view = orcSessionsView
	model.helpOffset = 0
	sessionView := ansi.Strip(model.View())
	sessionHelp := ansi.Strip(strings.Join(model.fullHelpLines(), "\n"))
	if !strings.Contains(sessionHelp, "<space>r") || !strings.Contains(sessionHelp, "<space>x") ||
		strings.Contains(sessionHelp, "<space>g") || strings.Contains(sessionHelp, "<space>p") ||
		strings.Contains(sessionHelp, "<space>u") || strings.Contains(sessionHelp, "select a restart point") {
		t.Fatalf("80x24 session help:\n%s", sessionView)
	}
	model.width = 40
	model.height = 10
	small := ansi.Strip(model.View())
	if lines := strings.Count(small, "\n") + 1; lines != 10 || !strings.Contains(small, "esc return") {
		t.Fatalf("40x10 help has %d lines:\n%s", lines, small)
	}
	updated, _ := model.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'j'}})
	if updated.(orcUIModel).helpOffset == 0 {
		t.Fatal("small help did not scroll")
	}
}

func TestSelectedNodeWithoutTraceDoesNotOpenControllerTrace(t *testing.T) {
	controllerID := domain.SessionID("controller")
	model := orcUIModel{
		view: orcWorkflowsView, graphMode: true,
		workflows: []domain.WorkflowRun{{ID: "run-1"}},
		workflow: workflowViewResult{
			Run:   domain.WorkflowRun{ID: "run-1", OrchestrationSession: &controllerID},
			Nodes: []domain.NodeRun{{ID: "node-1", NodeKey: "build"}},
		},
		sessions: []instance.Session{{ID: "controller", TraceSessionID: "trace-controller"}},
	}
	if session, found := model.selectedTrace(); found {
		t.Fatalf("selectedTrace() = %#v, want unavailable", session)
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

func TestOrcWorkerPreventsDuplicateSendAndShowsFailure(t *testing.T) {
	input := textinput.New()
	input.SetValue("Review this failure")
	model := orcWorkerUIModel{
		typing: true, input: input,
		history: sqlite.SessionHistory{Session: domain.Session{ID: "worker-send"}},
	}
	updated, command := model.Update(tea.KeyMsg{Type: tea.KeyEnter})
	model = updated.(orcWorkerUIModel)
	if command == nil || model.typing || model.message != "Sending message" {
		t.Fatalf("first enter = %#v, command = %#v", model, command)
	}
	updated, duplicate := model.Update(tea.KeyMsg{Type: tea.KeyEnter})
	if duplicate != nil {
		t.Fatalf("second enter returned command %#v", duplicate)
	}
	updated, duplicate = updated.(orcWorkerUIModel).Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'i'}})
	model = updated.(orcWorkerUIModel)
	if duplicate != nil || model.typing || !model.sending || !model.messageError {
		t.Fatalf("input during send = %#v, command = %#v", model, duplicate)
	}
	failed, _ := updated.(orcWorkerUIModel).Update(orcWorkerActionMessage{err: errors.New("send failed")})
	model = failed.(orcWorkerUIModel)
	if !model.messageError || model.message != "send failed" || model.typing || model.sending {
		t.Fatalf("failed send state = %#v", model)
	}
}

func TestOrcWorkerIgnoresOutOfOrderEventResults(t *testing.T) {
	running := domain.SessionStateRunning
	waiting := domain.SessionStateWaiting
	failed := domain.SessionStateFailed
	model := orcWorkerUIModel{
		eventCursor: 10,
		history:     sqlite.SessionHistory{Session: domain.Session{ID: "worker-order", State: running}},
	}
	updated, _ := model.Update(orcWorkerEventsMessage{cursor: 12, state: &waiting})
	model = updated.(orcWorkerUIModel)
	updated, _ = model.Update(orcWorkerEventsMessage{
		cursor: 11, state: &failed,
		events: []domain.RuntimeEvent{{Sequence: 11, Kind: "stale"}},
	})
	model = updated.(orcWorkerUIModel)
	if model.eventCursor != 12 || model.history.Session.State != waiting || len(model.history.RuntimeEvents) != 0 {
		t.Fatalf("out-of-order worker result = %#v", model)
	}
}

func TestOrcRefreshTickClearsStoppedBrokerState(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	t.Setenv("ORC_STATE_DIR", "")
	model := orcUIModel{
		active:    true,
		workflows: []domain.WorkflowRun{{ID: "stale-run"}},
		help:      help.New(),
	}
	updated, command := model.Update(orcRefreshTick(time.Now()))
	model = updated.(orcUIModel)
	if command == nil || !model.refreshing {
		t.Fatalf("refresh tick state = %#v, command = %#v", model, command)
	}
	batch, ok := command().(tea.BatchMsg)
	if !ok || len(batch) != 2 {
		t.Fatalf("refresh tick command = %#v", batch)
	}
	updated, _ = model.Update(batch[0]())
	model = updated.(orcUIModel)
	if model.active || len(model.workflows) != 0 || model.refreshing {
		t.Fatalf("refresh result state = %#v", model)
	}
}

func TestOrcRefreshPreservesCoalescedStatus(t *testing.T) {
	model := orcUIModel{
		view: orcSessionsView, refreshing: true, refreshRevision: 2,
	}
	if command := model.beginRefresh("Status refreshed"); command != nil || model.pendingRefreshStatus == "" {
		t.Fatalf("coalesced refresh = %#v, command = %#v", model, command)
	}
	updated, command := model.Update(orcRefreshResult{revision: 1})
	model = updated.(orcUIModel)
	if command == nil || !model.refreshing || model.pendingRefreshStatus != "" {
		t.Fatalf("retried refresh = %#v, command = %#v", model, command)
	}
}

func TestOrcNavigationInvalidatesOlderRefresh(t *testing.T) {
	model := orcUIModel{
		view: orcSessionsView, refreshing: true, refreshRevision: 7,
		sessions: []instance.Session{{ID: "first"}, {ID: "second"}},
	}
	updated, command := model.Update(tea.KeyMsg{Type: tea.KeyDown})
	model = updated.(orcUIModel)
	if command != nil || model.sessionCursor != 1 || model.refreshRevision != 8 {
		t.Fatalf("session navigation = %#v, command = %#v", model, command)
	}
	snapshot := model
	snapshot.sessionCursor = 0
	updated, command = model.Update(orcRefreshResult{model: snapshot, revision: 7, err: errors.New("stale refresh")})
	model = updated.(orcUIModel)
	if model.sessionCursor != 1 || command == nil || strings.Contains(model.message, "stale refresh") {
		t.Fatalf("stale refresh restored selection = %#v, command = %#v", model, command)
	}
}

func TestOrcWorkflowNavigationDisablesStaleRestartActions(t *testing.T) {
	model := orcUIModel{
		view:      orcWorkflowsView,
		workflows: []domain.WorkflowRun{{ID: "run-old"}, {ID: "run-new"}},
		workflow:  workflowViewResult{Run: domain.WorkflowRun{ID: "run-old"}},
		restartPoints: []domain.RestartPoint{
			{ID: "restart-old", WorkflowRunID: "run-old", Kind: domain.RestartPointNodeAdmission},
			{ID: "restart-second", WorkflowRunID: "run-old", Kind: domain.RestartPointNodeAdmission},
		},
	}
	updated, refresh := model.Update(tea.KeyMsg{Type: tea.KeyDown})
	model = updated.(orcUIModel)
	if refresh == nil || model.workflowCursor != 1 || model.workflowLoaded() {
		t.Fatalf("workflow navigation = %#v, refresh = %#v", model, refresh)
	}
	updated, command := model.Update(tea.KeyMsg{Type: tea.KeyRight})
	model = updated.(orcUIModel)
	if command != nil || model.restartCursor != 0 {
		t.Fatalf("stale restart navigation = %#v, command = %#v", model, command)
	}
	updated, command = model.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'f'}})
	model = updated.(orcUIModel)
	if command != nil || model.confirmReplay {
		t.Fatalf("stale restart replay = %#v, command = %#v", model, command)
	}
}

func TestOrcWorkflowListPageNavigationMovesSelection(t *testing.T) {
	model := orcUIModel{view: orcWorkflowsView, width: 90, height: 24, workflowCursor: 10}
	for index := 0; index < 20; index++ {
		model.workflows = append(model.workflows, domain.WorkflowRun{ID: domain.WorkflowRunID(fmt.Sprintf("run-%02d", index))})
	}
	model.workflow.Run.ID = "run-10"
	updated, refresh := model.Update(tea.KeyMsg{Type: tea.KeyCtrlD})
	model = updated.(orcUIModel)
	if refresh == nil || model.workflowCursor <= 10 {
		t.Fatalf("page down selection = %d, refresh = %#v", model.workflowCursor, refresh)
	}
	model.refreshing = false
	model.workflow.Run.ID = model.workflows[model.workflowCursor].ID
	updated, refresh = model.Update(tea.KeyMsg{Type: tea.KeyCtrlU})
	model = updated.(orcUIModel)
	if refresh == nil || model.workflowCursor >= 18 {
		t.Fatalf("page up selection = %d, refresh = %#v", model.workflowCursor, refresh)
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

func TestWorkflowLifecycleHasNativeCLICommands(t *testing.T) {
	for args, expected := range map[string]string{
		"workflow pause": "workflow.pause", "workflow resume": "workflow.resume",
		"workflow revise": "workflow.revise", "stage retry": "workflow.retry",
		"branch run": "workflow.branch",
	} {
		kind, offset, found := controlCommandKind(strings.Fields(args))
		if !found || kind != expected || offset != 2 {
			t.Fatalf("controlCommandKind(%q) = %q, %d, %v", args, kind, offset, found)
		}
	}
	for _, removed := range []string{"replay run", "workflow replay"} {
		if kind, _, found := controlCommandKind(strings.Fields(removed)); found || kind != "" {
			t.Fatalf("removed command %q resolved to %q", removed, kind)
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
	if !strings.Contains(orcUsage, "orc view --run") || !strings.Contains(orcUsage, "orc events") {
		t.Fatalf("orc help omits read-only commands:\n%s", orcUsage)
	}
}

func TestOrcHelpListsNativeCommands(t *testing.T) {
	for _, command := range []string{"workflow <create|run", "stage retry", "branch run", "graph patch", "worker <start|list"} {
		if !strings.Contains(orcUsage, command) {
			t.Fatalf("orc help omits %q", command)
		}
	}
}

func TestParseOrcControllerUsesHarnessTerminology(t *testing.T) {
	_, _, _, err := parseOrcController(nil, "resume")
	if err == nil || !strings.Contains(err.Error(), "orc resume <harness>") {
		t.Fatalf("resume usage error = %v", err)
	}
}

func TestDisconnectOrcSessionRemovesResolvedPrefix(t *testing.T) {
	record := instance.Record{Version: instance.Version, Scope: t.TempDir(), StateDirectory: t.TempDir()}
	created, err := instance.RegisterSession(record, instance.SessionRegistration{
		ID: "session-abcdef", Harness: "codex", Status: "working", Registration: "registered",
	})
	if err != nil {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	if exit := disconnectOrcSessionFrom(record, "session-abc", []instance.Session{created}, &stdout, &stderr); exit != 0 {
		t.Fatalf("disconnectOrcSessionFrom() exit = %d, stderr = %q", exit, stderr.String())
	}
	if _, found, err := instance.SessionByID(record, created.ID); err != nil || found {
		t.Fatalf("SessionByID() found = %v, error = %v", found, err)
	}
	if stdout.String() != "disconnected session-abcdef\n" {
		t.Fatalf("disconnect output = %q", stdout.String())
	}
}

func TestDisconnectOrcSessionRejectsObservedSession(t *testing.T) {
	record := instance.Record{Version: instance.Version, Scope: t.TempDir(), StateDirectory: t.TempDir()}
	session := instance.Session{ID: "session-observed", Registration: "observed"}
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	if exit := disconnectOrcSessionFrom(record, session.ID, []instance.Session{session}, &stdout, &stderr); exit != 1 ||
		!strings.Contains(stderr.String(), "only observed; connect it first") {
		t.Fatalf("observed disconnect exit = %d, stderr = %q", exit, stderr.String())
	}
}

func TestControlPlaneMarksExitedSessionDisconnected(t *testing.T) {
	record := instance.Record{Version: instance.Version, Scope: t.TempDir(), StateDirectory: t.TempDir()}
	created, err := instance.RegisterSession(record, instance.SessionRegistration{
		Harness: "codex", Pane: "19", Mux: 73, PID: os.Getpid(), ProcessIdentity: 1,
		Status: "working", Registration: "injected",
	})
	if err != nil {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	sessions, err := controlPlaneSessions(record)
	if err != nil || len(sessions) != 1 || sessions[0].ID != created.ID || sessions[0].Status != "disconnected" {
		t.Fatalf("controlPlaneSessions() = %#v, %v", sessions, err)
	}
}

func TestOrcWorkerRequestsTargetRuntimeAndAttachment(t *testing.T) {
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

func TestCleanOrcLeasesRemovesExitedProcesses(t *testing.T) {
	stateDirectory := t.TempDir()
	directory := orcLeaseDirectory(stateDirectory)
	if err := os.Mkdir(directory, 0o700); err != nil {
		t.Fatalf("Mkdir() returned %v", err)
	}
	active, err := createOrcLease(directory)
	if err != nil {
		t.Fatalf("createOrcLease() returned %v", err)
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
	remaining, err := cleanOrcLeases(stateDirectory)
	if err != nil {
		t.Fatalf("cleanOrcLeases() returned %v", err)
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

func TestOrcCandidateUsesContainingWorkspace(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	t.Setenv("ORC_STATE_DIR", "")
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
	candidate, err := orcStartCandidate("")
	if err != nil || candidate.Scope != record.Scope {
		t.Fatalf("orcStartCandidate() = %#v, %v", candidate, err)
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
	retired := make(chan instance.Record, 1)
	go monitorAutomaticBrokerWithInterval(ctx, stateDirectory, func(record instance.Record) error {
		retired <- record
		return nil
	}, func() {
		current, _ := instance.Read(filepath.Join(stateDirectory, "instance.json"))
		stopped <- current
		cancel()
	}, 10*time.Millisecond)
	select {
	case current := <-stopped:
		if !current.Stopping {
			t.Fatalf("monitor cancellation record = %#v", current)
		}
		select {
		case retiredRecord := <-retired:
			if !retiredRecord.Stopping {
				t.Fatalf("retired broker record = %#v", retiredRecord)
			}
		default:
			t.Fatal("automatic monitor did not retire its service")
		}
	case <-time.After(time.Second):
		t.Fatal("automatic monitor did not stop an idle broker")
	}
}

func TestInactiveOrcStatusOmitsStaleProcess(t *testing.T) {
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
	if automatic, err := automaticOrcBroker(stateDirectory, true); err != nil || !automatic {
		t.Fatalf("automaticOrcBroker(unpinned) = %v, %v", automatic, err)
	}
	if err := setOrcPinned(stateDirectory, true); err != nil {
		t.Fatalf("setOrcPinned() returned %v", err)
	}
	if automatic, err := automaticOrcBroker(stateDirectory, true); err != nil || automatic {
		t.Fatalf("automaticOrcBroker(pinned) = %v, %v", automatic, err)
	}
}

func TestStartFailurePreservesExistingPin(t *testing.T) {
	record := instance.Record{StateDirectory: t.TempDir()}
	if err := setOrcPinned(record.StateDirectory, true); err != nil {
		t.Fatalf("setOrcPinned() returned %v", err)
	}
	startError := errors.New("start failed")
	_, _, err := startPinnedOrc(record, func(instance.Record, bool) (bool, string, error) {
		return false, "", startError
	})
	if !errors.Is(err, startError) {
		t.Fatalf("startPinnedOrc() error = %v", err)
	}
	if pinned, err := orcPinned(record.StateDirectory); err != nil || !pinned {
		t.Fatalf("orcPinned() = %v, %v", pinned, err)
	}
}

func TestStopRemovesInactiveInstanceRecord(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	t.Setenv("ORC_STATE_DIR", "")
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
	if err := setOrcPinned(record.StateDirectory, true); err != nil {
		t.Fatalf("setOrcPinned() returned %v", err)
	}
	t.Setenv("ORC_STATE_DIR", record.StateDirectory)
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	if exit := runOrcStop(nil, &stdout, &stderr); exit != 0 {
		t.Fatalf("runOrcStop() exit = %d, stderr = %q", exit, stderr.String())
	}
	if _, err := instance.Read(filepath.Join(record.StateDirectory, "instance.json")); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("instance record read error = %v", err)
	}
	if pinned, err := orcPinned(record.StateDirectory); err != nil || pinned {
		t.Fatalf("orcPinned() = %v, %v", pinned, err)
	}
}

func TestScopedStatusResolvesBrokerOutsideItsWorkspace(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	t.Setenv("ORC_STATE_DIR", "")
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
	resolved, active, err := activeOrc(scope)
	if err != nil || active || resolved.StateDirectory != record.StateDirectory {
		t.Fatalf("activeOrc(%q) = %#v, %v, %v", scope, resolved, active, err)
	}
}

func TestPinnedLeaseChecksBrokerExecutable(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	candidate, _, err := instance.Candidate(t.TempDir())
	if err != nil {
		t.Fatalf("Candidate() returned %v", err)
	}
	called := false
	record, err := refreshPinnedOrc(candidate, func(record instance.Record, automatic bool) (bool, string, error) {
		called = true
		if automatic {
			t.Fatal("pinned broker started as automatic")
		}
		record.PID = os.Getpid()
		record.StartedAt = time.Now().UTC().Format(time.RFC3339Nano)
		return true, "test", instance.Write(record)
	})
	if err != nil || !called || record.PID != os.Getpid() {
		t.Fatalf("refreshPinnedOrc() = %#v, %v, called = %v", record, err, called)
	}
}

func waitForSocket(t *testing.T, path string, cancel context.CancelFunc, serveErrors <-chan error) {
	t.Helper()
	deadline := time.Now().Add(5 * time.Second)
	for {
		if info, err := os.Stat(path); err == nil && info.Mode()&os.ModeSocket != 0 {
			return
		}
		select {
		case err := <-serveErrors:
			t.Fatalf("serve() returned before creating the broker socket: %v", err)
		default:
		}
		if time.Now().After(deadline) {
			cancel()
			err := <-serveErrors
			t.Fatalf("serve() did not create the broker socket: %v", err)
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
