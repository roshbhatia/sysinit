package plugin

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
)

const (
	fixtureEnabled  = "COLCHIS_PLUGIN_FIXTURE"
	fixtureMode     = "COLCHIS_PLUGIN_FIXTURE_MODE"
	treeFixtureRole = "COLCHIS_TREE_FIXTURE_ROLE"
	treeFixturePID  = "COLCHIS_TREE_FIXTURE_PID"
	treeFixtureDeny = "COLCHIS_TREE_FIXTURE_DENIED_PATH"
)

type fixtureIsolation struct {
	plan  LaunchPlan
	err   error
	calls atomic.Uint32
}

func (isolation *fixtureIsolation) Prepare(context.Context, IsolationProfile) (LaunchPlan, error) {
	isolation.calls.Add(1)
	return isolation.plan, isolation.err
}

type recordedEvents struct {
	mu     sync.Mutex
	events []OperationEvent
	err    error
}

func (sink *recordedEvents) RecordPluginEvent(
	_ context.Context,
	_ domain.PluginID,
	event OperationEvent,
) error {
	sink.mu.Lock()
	defer sink.mu.Unlock()
	sink.events = append(sink.events, event)
	return sink.err
}

func (sink *recordedEvents) count() int {
	sink.mu.Lock()
	defer sink.mu.Unlock()
	return len(sink.events)
}

func TestPluginFixtureProcess(t *testing.T) {
	if os.Getenv(fixtureEnabled) != "1" {
		return
	}
	os.Exit(runPluginFixture(os.Getenv(fixtureMode)))
}

func TestProcessTreeFixture(t *testing.T) {
	role := os.Getenv(treeFixtureRole)
	if role == "" {
		return
	}
	if role == "child" {
		for {
			time.Sleep(time.Hour)
		}
	}
	if role == "sandbox-child" {
		if _, err := os.ReadFile(os.Getenv(treeFixtureDeny)); err != nil {
			os.Exit(23)
		}
		os.Exit(0)
	}
	if role == "setsid-probe" || role == "setpgid-probe" {
		executable, err := os.Executable()
		if err != nil {
			os.Exit(24)
		}
		child := exec.Command(executable, "-test.run=^TestProcessTreeFixture$")
		child.Env = replaceTestEnvironment(treeFixtureRole, "sandbox-child")
		child.SysProcAttr = &syscall.SysProcAttr{Setsid: role == "setsid-probe", Setpgid: role == "setpgid-probe"}
		if err := child.Run(); err == nil {
			os.Exit(0)
		} else if exitErr, ok := err.(*exec.ExitError); ok && exitErr.ExitCode() == 23 {
			os.Exit(23)
		}
		os.Exit(24)
	}
	executable, err := os.Executable()
	if err != nil {
		os.Exit(2)
	}
	child := exec.Command(executable, "-test.run=^TestProcessTreeFixture$")
	child.Env = append(os.Environ(), treeFixtureRole+"=child")
	if role != "root-exit" {
		child.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
	}
	if err := child.Start(); err != nil {
		os.Exit(3)
	}
	if err := os.WriteFile(os.Getenv(treeFixturePID), []byte(fmt.Sprintf("%d", child.Process.Pid)), 0o600); err != nil {
		os.Exit(4)
	}
	if role == "root-exit" {
		return
	}
	for {
		time.Sleep(time.Hour)
	}
}

func replaceTestEnvironment(name string, value string) []string {
	prefix := name + "="
	environment := make([]string, 0, len(os.Environ())+1)
	for _, entry := range os.Environ() {
		if !strings.HasPrefix(entry, prefix) {
			environment = append(environment, entry)
		}
	}
	return append(environment, prefix+value)
}

func TestPluginCloseCleansGroupAfterRootExit(t *testing.T) {
	t.Parallel()

	executable, err := os.Executable()
	if err != nil {
		t.Fatalf("os.Executable() returned %v", err)
	}
	pidPath := filepath.Join(t.TempDir(), "child.pid")
	root := exec.Command(executable, "-test.run=^TestProcessTreeFixture$")
	root.Env = append(os.Environ(), treeFixtureRole+"=root-exit", treeFixturePID+"="+pidPath)
	root.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	if err := root.Start(); err != nil {
		t.Fatalf("Start() returned %v", err)
	}
	supervisor, err := SuperviseStartedCommand(root)
	if err != nil {
		t.Fatalf("SuperviseStartedCommand() returned %v", err)
	}
	childPID := waitForFixturePID(t, pidPath)
	done := make(chan struct{})
	process := &pluginProcess{command: root, done: done, supervisor: supervisor}
	go func() {
		_ = supervisor.Wait()
		close(done)
	}()
	<-done
	if err := process.close(); err != nil {
		t.Fatalf("close() returned %v", err)
	}
	waitForProcessExit(t, childPID)
}

func TestOwnedProcessTreeRejectsReusedRootIdentity(t *testing.T) {
	t.Parallel()

	identity, found, err := currentProcessIdentity(os.Getpid())
	if err != nil || !found {
		t.Fatalf("currentProcessIdentity() = %d, %t, %v", identity, found, err)
	}
	tree := ownedProcessTree{rootPID: os.Getpid(), rootIdentity: identity + 1}
	if err := tree.terminate(); err != nil {
		t.Fatalf("terminate() returned %v", err)
	}
	if _, found, err := currentProcessIdentity(os.Getpid()); err != nil || !found {
		t.Fatalf("current process after terminate() = %t, %v", found, err)
	}
}

func TestProcessTreeCleanupIncludesDetachedDescendants(t *testing.T) {
	t.Parallel()

	executable, err := os.Executable()
	if err != nil {
		t.Fatalf("os.Executable() returned %v", err)
	}
	pidPath := filepath.Join(t.TempDir(), "child.pid")
	root := exec.Command(executable, "-test.run=^TestProcessTreeFixture$")
	root.Env = append(os.Environ(), treeFixtureRole+"=root", treeFixturePID+"="+pidPath)
	root.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	if err := root.Start(); err != nil {
		t.Fatalf("Start() returned %v", err)
	}
	t.Cleanup(func() { _ = TerminateProcessTree(root.Process.Pid) })
	childPID := waitForFixturePID(t, pidPath)
	if err := TerminateProcessTree(root.Process.Pid); err != nil {
		t.Fatalf("TerminateProcessTree() returned %v", err)
	}
	_ = root.Wait()
	deadline := time.Now().Add(time.Second)
	for time.Now().Before(deadline) {
		if err := syscall.Kill(childPID, 0); errors.Is(err, syscall.ESRCH) {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatalf("detached descendant %d survived process-tree cleanup", childPID)
}

func waitForFixturePID(t *testing.T, path string) int {
	t.Helper()
	deadline := time.Now().Add(5 * time.Second)
	var lastErr error
	for time.Now().Before(deadline) {
		payload, err := os.ReadFile(path)
		if err == nil {
			pid, parseErr := strconv.Atoi(string(payload))
			if parseErr == nil && pid > 0 {
				return pid
			}
			lastErr = parseErr
			time.Sleep(10 * time.Millisecond)
			continue
		}
		if !errors.Is(err, os.ErrNotExist) {
			t.Fatalf("ReadFile() returned %v", err)
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatalf("fixture did not publish a complete PID: %v", lastErr)
	return 0
}

func waitForProcessExit(t *testing.T, pid int) {
	t.Helper()
	deadline := time.Now().Add(time.Second)
	for time.Now().Before(deadline) {
		if err := syscall.Kill(pid, 0); errors.Is(err, syscall.ESRCH) {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatalf("process %d survived cleanup", pid)
}

func TestHostActivatesInvokesAndAdoptsHandles(t *testing.T) {
	t.Parallel()

	isolation := newFixtureIsolation(t, "normal")
	events := &recordedEvents{}
	host, err := NewHost(isolation, events)
	if err != nil {
		t.Fatalf("NewHost() returned %v", err)
	}
	t.Cleanup(func() { _ = host.Close() })
	handle := HandleDescriptor{
		ID: "handle-1", PluginID: "fixture", Port: domain.AdapterPortAgentRuntime, AdapterID: "runtime",
		FormatVersion: 1,
		OpaqueValue:   json.RawMessage(`{"session":"one"}`),
	}
	manifest, err := host.Activate(context.Background(), testHostConfig(t), []HandleDescriptor{handle})
	if err != nil {
		t.Fatalf("Activate() returned %v", err)
	}
	if manifest.PluginID != "fixture" {
		t.Fatalf("plugin ID = %q", manifest.PluginID)
	}
	if capabilities := host.AdapterCapabilities(); len(capabilities["runtime"]) != 1 || capabilities["runtime"][0] != "fixture" {
		t.Fatalf("AdapterCapabilities() = %#v", capabilities)
	}
	envelope := testOperationEnvelope("operation-1")
	envelope.HandleID = &handle.ID
	result, err := host.Invoke(context.Background(), "fixture", envelope)
	if err != nil {
		t.Fatalf("Invoke() returned %v", err)
	}
	if result.State != domain.OperationStateSucceeded || events.count() != 1 {
		t.Fatalf("result state = %q, event count = %d", result.State, events.count())
	}
	reconciled, err := host.Reconcile(context.Background(), "fixture", []HandleDescriptor{handle})
	if err != nil {
		t.Fatalf("Reconcile() returned %v", err)
	}
	if len(reconciled) != 1 || reconciled[0].State != ReconcileStateAdopted {
		t.Fatalf("reconciliation = %#v", reconciled)
	}
	secondHandle := HandleDescriptor{
		ID: "handle-2", PluginID: "fixture", Port: domain.AdapterPortAgentRuntime, AdapterID: "runtime",
		FormatVersion: 1,
		OpaqueValue:   json.RawMessage(`{"session":"two"}`),
	}
	if err := host.TrackHandle("fixture", secondHandle); err != nil {
		t.Fatalf("TrackHandle() returned %v", err)
	}
	if _, err := host.Activate(context.Background(), testHostConfig(t), []HandleDescriptor{handle}); !domain.IsErrorCode(err, domain.ErrorCodeConflict) {
		t.Fatalf("upgrade with stale handles error = %v", err)
	}
	if _, err := host.Reconcile(context.Background(), "fixture", []HandleDescriptor{handle, secondHandle}); err != nil {
		t.Fatalf("Reconcile() after rejected upgrade returned %v", err)
	}
}

func TestHostBoundsPluginInitialization(t *testing.T) {
	t.Parallel()

	host, err := NewHost(newFixtureIsolation(t, "hang-initialize"), &recordedEvents{})
	if err != nil {
		t.Fatalf("NewHost() returned %v", err)
	}
	t.Cleanup(func() { _ = host.Close() })
	config := testHostConfig(t)
	config.Restart.MaxAttempts = 1
	config.Limits.MaxOperationSeconds = 1
	started := time.Now()
	if _, err := host.Activate(context.Background(), config, nil); !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("Activate() error = %v", err)
	}
	if elapsed := time.Since(started); elapsed > 2*time.Second {
		t.Fatalf("Activate() elapsed = %s", elapsed)
	}
}

func TestHostRetainsPriorPluginWhenCandidateRejectsHandle(t *testing.T) {
	t.Parallel()

	isolation := newFixtureIsolation(t, "normal")
	host, err := NewHost(isolation, &recordedEvents{})
	if err != nil {
		t.Fatalf("NewHost() returned %v", err)
	}
	t.Cleanup(func() { _ = host.Close() })
	handle := HandleDescriptor{
		ID: "handle-upgrade", PluginID: "fixture", Port: domain.AdapterPortAgentRuntime,
		AdapterID: "runtime", FormatVersion: 1, OpaqueValue: json.RawMessage(`{"session":"one"}`),
	}
	if _, err := host.Activate(context.Background(), testHostConfig(t), []HandleDescriptor{handle}); err != nil {
		t.Fatalf("initial Activate() returned %v", err)
	}
	isolation.plan = fixtureLaunchPlan(t, "reject-handle")
	config := testHostConfig(t)
	config.Restart.MaxAttempts = 1
	if _, err := host.Activate(context.Background(), config, []HandleDescriptor{handle}); !domain.IsErrorCode(
		err, domain.ErrorCodeInvalidArgument,
	) {
		t.Fatalf("candidate Activate() error = %v", err)
	}
	reconciled, err := host.Reconcile(context.Background(), "fixture", []HandleDescriptor{handle})
	if err != nil || len(reconciled) != 1 || reconciled[0].State != ReconcileStateAdopted {
		t.Fatalf("prior plugin reconciliation = %#v, %v", reconciled, err)
	}
}

func TestHostRecoveryActivatesWithOrphanedHandle(t *testing.T) {
	t.Parallel()

	isolation := newFixtureIsolation(t, "reject-handle")
	host, err := NewHost(isolation, &recordedEvents{})
	if err != nil {
		t.Fatalf("NewHost() returned %v", err)
	}
	t.Cleanup(func() { _ = host.Close() })
	handle := HandleDescriptor{
		ID: "handle-recovery-orphan", PluginID: "fixture", Port: domain.AdapterPortAgentRuntime,
		AdapterID: "runtime", FormatVersion: 1, OpaqueValue: json.RawMessage(`{"session":"one"}`),
	}
	if _, err := host.Recover(context.Background(), testHostConfig(t), []HandleDescriptor{handle}); err != nil {
		t.Fatalf("Recover() returned %v", err)
	}
	reconciled, err := host.Reconcile(context.Background(), "fixture", []HandleDescriptor{handle})
	if err != nil || len(reconciled) != 1 || reconciled[0].State != ReconcileStateOrphaned {
		t.Fatalf("recovery reconciliation = %#v, %v", reconciled, err)
	}
	handleID := handle.ID
	operation := testOperationEnvelope("operation-orphaned-handle")
	operation.HandleID = &handleID
	if _, err := host.Invoke(context.Background(), "fixture", operation); !domain.IsErrorCode(
		err, domain.ErrorCodeNotFound,
	) {
		t.Fatalf("orphaned handle invocation error = %v", err)
	}
}

func TestHostRequiresDurableEventSink(t *testing.T) {
	t.Parallel()

	_, err := NewHost(newFixtureIsolation(t, "normal"), nil)
	if !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("NewHost() error = %v", err)
	}
}

func TestHostUsesQualifiedSelectorsForDuplicateAdapters(t *testing.T) {
	t.Parallel()

	host := &Host{plugins: map[domain.PluginID]*activePlugin{
		"safe": {
			manifest: InitializeResult{Adapters: []AdapterManifest{{
				ID: "pi", Port: domain.AdapterPortAgentRuntime, Capabilities: []string{"job-policy"},
			}}},
		},
		"danger": {
			manifest: InitializeResult{Adapters: []AdapterManifest{{
				ID: "pi", Port: domain.AdapterPortAgentRuntime,
				Capabilities: []string{"job-policy", "danger-full-access"},
			}}},
		},
	}}
	capabilities := host.AdapterCapabilities()
	if _, found := capabilities["pi"]; found || len(capabilities["safe::pi"]) != 1 ||
		len(capabilities["danger::pi"]) != 2 {
		t.Fatalf("AdapterCapabilities() = %#v", capabilities)
	}
	pluginID, resolved, err := host.ResolveAdapter(domain.AdapterPortAgentRuntime, "danger::pi")
	if err != nil || pluginID != "danger" || len(resolved) != 2 {
		t.Fatalf("ResolveAdapter() = %q, %#v, %v", pluginID, resolved, err)
	}
}

func TestHostFailsClosedBeforePluginExecution(t *testing.T) {
	t.Parallel()

	isolationErr := &domain.Error{
		Code: domain.ErrorCodeUnauthorized, Op: "prepare isolation", Resource: "fixture",
		Message: "fixture isolation failed",
	}
	isolation := &fixtureIsolation{err: isolationErr}
	host, err := NewHost(isolation, &recordedEvents{})
	if err != nil {
		t.Fatalf("NewHost() returned %v", err)
	}
	config := testHostConfig(t)
	config.Restart.MaxAttempts = 1
	_, err = host.Activate(context.Background(), config, nil)
	if !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("Activate() error = %v", err)
	}
	if isolation.calls.Load() != 1 {
		t.Fatalf("isolation calls = %d", isolation.calls.Load())
	}
}

func TestHostRejectsForeignHandleBeforePluginExecution(t *testing.T) {
	t.Parallel()

	isolation := newFixtureIsolation(t, "normal")
	host, err := NewHost(isolation, &recordedEvents{})
	if err != nil {
		t.Fatalf("NewHost() returned %v", err)
	}
	_, err = host.Activate(context.Background(), testHostConfig(t), []HandleDescriptor{{
		ID: "foreign-handle", PluginID: "other-plugin",
		Port: domain.AdapterPortAgentRuntime, AdapterID: "runtime", FormatVersion: 1,
		OpaqueValue: json.RawMessage(`{"session":"foreign"}`),
	}})
	if !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("Activate() error = %v", err)
	}
	if isolation.calls.Load() != 0 {
		t.Fatalf("isolation calls = %d", isolation.calls.Load())
	}
}

func TestHostRejectsMalformedOperationOutput(t *testing.T) {
	t.Parallel()

	host := newFixtureHost(t, "malformed", &recordedEvents{})
	_, err := host.Invoke(context.Background(), "fixture", testOperationEnvelope("operation-malformed"))
	if !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("Invoke() error = %v", err)
	}
}

func TestHostRejectsReconciliationForAnotherHandle(t *testing.T) {
	t.Parallel()

	host := newFixtureHost(t, "wrong-reconcile", &recordedEvents{})
	handle := HandleDescriptor{
		ID: "handle-1", PluginID: "fixture", Port: domain.AdapterPortAgentRuntime, AdapterID: "runtime",
		FormatVersion: 1,
		OpaqueValue:   json.RawMessage(`{"session":"one"}`),
	}
	_, err := host.Reconcile(context.Background(), "fixture", []HandleDescriptor{handle})
	if !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("Reconcile() error = %v", err)
	}
}

func TestHostOpensCircuitAfterRestartLimit(t *testing.T) {
	t.Parallel()

	host := newFixtureHost(t, "crash-invoke", &recordedEvents{})
	_, firstErr := host.Invoke(context.Background(), "fixture", testOperationEnvelope("operation-crash"))
	if firstErr == nil {
		t.Fatal("Invoke() returned no error")
	}
	_, secondErr := host.Invoke(context.Background(), "fixture", testOperationEnvelope("operation-circuit"))
	if !domain.IsErrorCode(secondErr, domain.ErrorCodeBudgetExhausted) {
		t.Fatalf("second Invoke() error = %v", secondErr)
	}
}

func TestHostKillsPluginAtCancellationDeadline(t *testing.T) {
	t.Parallel()

	host := newFixtureHost(t, "ignore-cancel", &recordedEvents{})
	deadline := time.Now().Add(100 * time.Millisecond)
	err := host.Cancel(context.Background(), "fixture", CancelParams{
		OperationID: "operation-cancel", Deadline: deadline,
	})
	if err != nil {
		t.Fatalf("Cancel() error = %v", err)
	}
	if elapsed := time.Since(deadline); elapsed > time.Second {
		t.Fatalf("cancellation exceeded deadline by %v", elapsed)
	}
}

func TestHostKillsPluginWhenInvocationIgnoresDeadline(t *testing.T) {
	t.Parallel()

	host, err := NewHost(newFixtureIsolation(t, "hang-invoke"), &recordedEvents{})
	if err != nil {
		t.Fatalf("NewHost() returned %v", err)
	}
	t.Cleanup(func() { _ = host.Close() })
	config := testHostConfig(t)
	config.Restart.MaxAttempts = 1
	config.Limits.MaxOperationSeconds = 1
	if _, err := host.Activate(context.Background(), config, nil); err != nil {
		t.Fatalf("Activate() returned %v", err)
	}
	active, err := host.active("fixture")
	if err != nil {
		t.Fatalf("active() returned %v", err)
	}
	pid := active.process.command.Process.Pid
	envelope := testOperationEnvelope("operation-deadline")
	envelope.Deadline = time.Now().Add(100 * time.Millisecond)
	if _, err := host.Invoke(context.Background(), "fixture", envelope); !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("Invoke() returned %v", err)
	}
	select {
	case <-active.process.done:
	case <-time.After(time.Second):
		t.Fatal("timed-out plugin process remained active")
	}
	if err := syscall.Kill(pid, 0); !errors.Is(err, syscall.ESRCH) {
		t.Fatalf("timed-out plugin process %d remains addressable: %v", pid, err)
	}
}

func TestHostStopsWhenEventCannotBeRecorded(t *testing.T) {
	t.Parallel()

	sink := &recordedEvents{err: errors.New("fixture event storage failed")}
	host := newFixtureHost(t, "normal", sink)
	_, err := host.Invoke(context.Background(), "fixture", testOperationEnvelope("operation-event-failure"))
	if err == nil {
		t.Fatal("Invoke() returned no error")
	}
}

func newFixtureHost(t *testing.T, mode string, events EventSink) *Host {
	t.Helper()
	isolation := newFixtureIsolation(t, mode)
	host, err := NewHost(isolation, events)
	if err != nil {
		t.Fatalf("NewHost() returned %v", err)
	}
	t.Cleanup(func() { _ = host.Close() })
	if _, err := host.Activate(context.Background(), testHostConfig(t), nil); err != nil {
		t.Fatalf("Activate() returned %v", err)
	}
	return host
}

func newFixtureIsolation(t *testing.T, mode string) *fixtureIsolation {
	t.Helper()
	return &fixtureIsolation{plan: fixtureLaunchPlan(t, mode)}
}

func fixtureLaunchPlan(t *testing.T, mode string) LaunchPlan {
	t.Helper()
	executable, err := os.Executable()
	if err != nil {
		t.Fatalf("os.Executable() returned %v", err)
	}
	return LaunchPlan{
		Executable:       executable,
		Arguments:        []string{"-test.run=^TestPluginFixtureProcess$"},
		WorkingDirectory: t.TempDir(),
		Environment:      []string{fixtureEnabled + "=1", fixtureMode + "=" + mode},
	}
}

func testHostConfig(t *testing.T) Config {
	t.Helper()
	executable, err := os.Executable()
	if err != nil {
		t.Fatalf("os.Executable() returned %v", err)
	}
	return Config{
		ID: "fixture",
		Profile: IsolationProfile{
			Executable: executable, WorkingDirectory: filepath.Dir(executable),
		},
		Restart: RestartPolicy{
			MaxAttempts: 2, InitialBackoff: time.Millisecond, MaxBackoff: 2 * time.Millisecond,
			CircuitOpenPeriod: time.Minute,
		},
		Limits: WireLimits{
			MaxMessageBytes: 1 << 20, MaxEventsPerSecond: 10, MaxOperationSeconds: 2,
		},
	}
}

func testOperationEnvelope(id domain.OperationID) OperationEnvelope {
	return OperationEnvelope{
		ID: id, AdapterID: "runtime", Port: domain.AdapterPortAgentRuntime,
		Operation: "agent-runtime.start", Input: json.RawMessage(`{"value":"request"}`),
		Deadline: time.Now().Add(time.Minute),
	}
}

func runPluginFixture(mode string) int {
	scanner := bufio.NewScanner(os.Stdin)
	encoder := json.NewEncoder(os.Stdout)
	for scanner.Scan() {
		var request Request
		if json.Unmarshal(scanner.Bytes(), &request) != nil {
			return 2
		}
		switch request.Method {
		case MethodInitialize:
			if mode == "hang-initialize" {
				for {
					time.Sleep(time.Hour)
				}
			}
			if writeFixtureInitialization(encoder, request) != nil {
				return 3
			}
		case MethodInvoke:
			if mode == "crash-invoke" {
				return 17
			}
			if mode == "hang-invoke" {
				for {
					time.Sleep(time.Hour)
				}
			}
			if writeFixtureInvocation(encoder, request, mode) != nil {
				return 4
			}
		case MethodCancel:
			if mode == "ignore-cancel" {
				for {
					time.Sleep(time.Hour)
				}
			}
			if writeFixtureResponse(encoder, request.ID, json.RawMessage(`{"cancelled":true}`)) != nil {
				return 5
			}
		case MethodReconcile:
			if writeFixtureReconciliation(encoder, request, mode) != nil {
				return 6
			}
		default:
			return 7
		}
	}
	if scanner.Err() != nil {
		return 8
	}
	return 0
}

func writeFixtureInitialization(encoder *json.Encoder, request Request) error {
	var params InitializeParams
	if err := json.Unmarshal(request.Params, &params); err != nil {
		return err
	}
	adoption := make([]HandleAdoption, 0, len(params.ActiveHandles))
	for _, handle := range params.ActiveHandles {
		adoption = append(adoption, HandleAdoption{HandleID: handle.ID, Adopted: true})
	}
	result := InitializeResult{
		PluginID: "fixture", ProtocolVersion: ProtocolVersion,
		Adapters: []AdapterManifest{{
			ID: "runtime", Port: domain.AdapterPortAgentRuntime, Capabilities: []string{"fixture"},
			HandleVersions: []uint32{1},
			Operations:     map[string]SchemaContract{"agent-runtime.start": fixtureSchemaContract()},
		}},
		HandleAdoption: adoption,
	}
	payload, err := json.Marshal(result)
	if err != nil {
		return err
	}
	return writeFixtureResponse(encoder, request.ID, payload)
}

func writeFixtureInvocation(encoder *json.Encoder, request Request, mode string) error {
	var envelope OperationEnvelope
	if err := json.Unmarshal(request.Params, &envelope); err != nil {
		return err
	}
	if mode == "normal" {
		eventPayload, err := json.Marshal(OperationEvent{
			OperationID: envelope.ID, Sequence: 1, Kind: "output",
			Payload: json.RawMessage(`{"text":"fixture"}`), OccurredAt: time.Now(),
		})
		if err != nil {
			return err
		}
		event := Notification{
			JSONRPC: JSONRPCVersion, Method: MethodEvent,
			Params: eventPayload,
		}
		if err := encoder.Encode(event); err != nil {
			return err
		}
	}
	result := OperationResult{
		ID: envelope.ID, State: domain.OperationStateSucceeded,
		Output: json.RawMessage(`{"value":"response"}`),
	}
	if mode == "malformed" {
		result.Output = json.RawMessage(`{"missing":"value"}`)
	}
	resultPayload, err := json.Marshal(result)
	if err != nil {
		return err
	}
	return writeFixtureResponse(encoder, request.ID, resultPayload)
}

func writeFixtureReconciliation(encoder *json.Encoder, request Request, mode string) error {
	var params ReconcileParams
	if err := json.Unmarshal(request.Params, &params); err != nil {
		return err
	}
	result := make([]ReconcileResult, 0, len(params.Handles))
	for _, handle := range params.Handles {
		state := ReconcileStateAdopted
		if mode == "reject-handle" {
			state = ReconcileStateOrphaned
		}
		result = append(result, ReconcileResult{HandleID: handle.ID, State: state})
	}
	if mode == "wrong-reconcile" && len(result) != 0 {
		result[0].HandleID = "unrequested-handle"
	}
	resultPayload, err := json.Marshal(result)
	if err != nil {
		return err
	}
	return writeFixtureResponse(encoder, request.ID, resultPayload)
}

func writeFixtureResponse(encoder *json.Encoder, id string, result json.RawMessage) error {
	return encoder.Encode(Response{JSONRPC: JSONRPCVersion, ID: id, Result: result})
}

func fixtureSchemaContract() SchemaContract {
	schema := json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object",
  "properties":{"value":{"type":"string"}},
  "required":["value"],
  "additionalProperties":false
}`)
	digest, err := workflowmodel.JSONSchemaDigest(schema)
	if err != nil {
		panic(err)
	}
	return SchemaContract{
		RequestSchema: schema, RequestSchemaDigest: digest,
		ResponseSchema: schema, ResponseSchemaDigest: digest, Retryable: true, Idempotent: true,
	}
}
