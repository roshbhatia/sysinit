package plugin

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os/exec"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

type RestartPolicy struct {
	MaxAttempts       uint32        `json:"maxAttempts"`
	InitialBackoff    time.Duration `json:"initialBackoff"`
	MaxBackoff        time.Duration `json:"maxBackoff"`
	CircuitOpenPeriod time.Duration `json:"circuitOpenPeriod"`
}

type Config struct {
	ID      domain.PluginID  `json:"id"`
	Profile IsolationProfile `json:"profile"`
	Restart RestartPolicy    `json:"restart"`
	Limits  WireLimits       `json:"limits"`
}

type EventSink interface {
	RecordPluginEvent(context.Context, domain.PluginID, OperationEvent) error
}

type EventSinkFunc func(context.Context, domain.PluginID, OperationEvent) error

func (sink EventSinkFunc) RecordPluginEvent(
	ctx context.Context,
	pluginID domain.PluginID,
	event OperationEvent,
) error {
	return sink(ctx, pluginID, event)
}

type Host struct {
	isolation IsolationBackend
	events    EventSink

	mu       sync.Mutex
	plugins  map[domain.PluginID]*activePlugin
	circuits map[domain.PluginID]*circuitState
}

type activePlugin struct {
	config     Config
	manifest   InitializeResult
	process    *pluginProcess
	handles    []HandleDescriptor
	orphaned   map[domain.AdapterHandleID]HandleDescriptor
	generation uint64
}

type circuitState struct {
	failures  uint32
	openUntil time.Time
}

func NewHost(isolation IsolationBackend, events EventSink) (*Host, error) {
	if isolation == nil {
		return nil, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "plugin host", Message: "isolation backend is nil",
		}
	}
	if events == nil {
		return nil, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "plugin host", Message: "event sink is nil",
		}
	}
	return &Host{
		isolation: isolation, events: events,
		plugins: make(map[domain.PluginID]*activePlugin), circuits: make(map[domain.PluginID]*circuitState),
	}, nil
}

func (host *Host) Activate(
	ctx context.Context,
	config Config,
	activeHandles []HandleDescriptor,
) (InitializeResult, error) {
	return host.activate(ctx, config, activeHandles, false)
}

func (host *Host) Recover(
	ctx context.Context,
	config Config,
	activeHandles []HandleDescriptor,
) (InitializeResult, error) {
	return host.activate(ctx, config, activeHandles, true)
}

func (host *Host) activate(
	ctx context.Context,
	config Config,
	activeHandles []HandleDescriptor,
	recovery bool,
) (InitializeResult, error) {
	if err := validateHostConfig(config); err != nil {
		return InitializeResult{}, err
	}
	if err := host.circuitAllows(config.ID); err != nil {
		return InitializeResult{}, err
	}
	var candidate *pluginProcess
	var manifest InitializeResult
	var err error
	for attempt := uint32(1); attempt <= config.Restart.MaxAttempts; attempt++ {
		candidate, manifest, err = host.startCandidate(ctx, config, activeHandles, recovery)
		if err == nil {
			break
		}
		host.recordFailure(config)
		if attempt == config.Restart.MaxAttempts {
			return InitializeResult{}, err
		}
		if err := waitBackoff(ctx, config.Restart, attempt); err != nil {
			return InitializeResult{}, err
		}
	}
	host.mu.Lock()
	prior := host.plugins[config.ID]
	if prior != nil && (recovery || !sameHandleDescriptors(prior.handles, activeHandles)) {
		host.mu.Unlock()
		_ = candidate.close()
		return InitializeResult{}, &domain.Error{
			Code: domain.ErrorCodeConflict, Op: "activate plugin", Resource: string(config.ID),
			Message: "active handles changed during plugin activation",
		}
	}
	host.plugins[config.ID] = &activePlugin{
		config: config, manifest: manifest, process: candidate,
		handles:  candidateActiveHandles(activeHandles, candidate.orphanedHandles),
		orphaned: cloneOrphanedHandles(candidate.orphanedHandles),
	}
	host.circuits[config.ID] = &circuitState{}
	host.mu.Unlock()
	if prior != nil {
		_ = prior.process.close()
	}
	return manifest, nil
}

func (host *Host) startCandidate(
	ctx context.Context,
	config Config,
	activeHandles []HandleDescriptor,
	allowOrphaned bool,
) (*pluginProcess, InitializeResult, error) {
	params := InitializeParams{
		SupportedProtocolVersions: []uint32{ProtocolVersion}, ActiveHandles: activeHandles, Limits: config.Limits,
	}
	if err := ValidateInitializeParams(params); err != nil {
		return nil, InitializeResult{}, err
	}
	for _, handle := range activeHandles {
		if handle.PluginID != config.ID {
			return nil, InitializeResult{}, invalidProtocol(
				string(handle.ID), "active handle belongs to another plugin",
			)
		}
	}
	plan, err := host.isolation.Prepare(ctx, config.Profile)
	if err != nil {
		return nil, InitializeResult{}, err
	}
	process, err := startPluginProcess(ctx, config.ID, plan, config.Limits, host.events)
	if err != nil {
		_ = plan.Cleanup()
		return nil, InitializeResult{}, err
	}
	var result InitializeResult
	paramsPayload, err := json.Marshal(params)
	if err != nil {
		_ = process.close()
		return nil, InitializeResult{}, wrapHost("encode plugin initialization", string(config.ID), err)
	}
	lifecycleContext, cancelLifecycle := pluginLifecycleContext(ctx, config.Limits)
	resultPayload, err := process.call(lifecycleContext, "initialize", MethodInitialize, paramsPayload)
	cancelLifecycle()
	if err != nil {
		_ = process.close()
		return nil, InitializeResult{}, err
	}
	if err := json.Unmarshal(resultPayload, &result); err != nil {
		_ = process.close()
		return nil, InitializeResult{}, wrapHost("decode plugin initialization", string(config.ID), err)
	}
	if result.PluginID != config.ID {
		_ = process.close()
		return nil, InitializeResult{}, invalidProtocol(string(config.ID), "plugin identity changed during initialization")
	}
	if err := ValidateInitializeResult(result, activeHandles); err != nil {
		_ = process.close()
		return nil, InitializeResult{}, err
	}
	adoption := make(map[domain.AdapterHandleID]HandleAdoption, len(result.HandleAdoption))
	for _, decision := range result.HandleAdoption {
		adoption[decision.HandleID] = decision
	}
	adoptedHandles := make([]HandleDescriptor, 0, len(activeHandles))
	process.orphanedHandles = make(map[domain.AdapterHandleID]HandleDescriptor)
	for _, handle := range activeHandles {
		if adoption[handle.ID].Adopted {
			adoptedHandles = append(adoptedHandles, handle)
			continue
		}
		process.orphanedHandles[handle.ID] = handle
	}
	if len(process.orphanedHandles) > 0 && !allowOrphaned {
		_ = process.close()
		return nil, InitializeResult{}, invalidProtocol(
			string(config.ID), "candidate plugin rejected active handles",
		)
	}
	if len(adoptedHandles) > 0 {
		reconcilePayload, marshalErr := json.Marshal(ReconcileParams{Handles: adoptedHandles})
		if marshalErr != nil {
			_ = process.close()
			return nil, InitializeResult{}, wrapHost("encode candidate reconciliation", string(config.ID), marshalErr)
		}
		lifecycleContext, cancelLifecycle := pluginLifecycleContext(ctx, config.Limits)
		responsePayload, callErr := process.call(
			lifecycleContext, "activation-reconcile", MethodReconcile, reconcilePayload,
		)
		cancelLifecycle()
		if callErr != nil {
			_ = process.close()
			return nil, InitializeResult{}, callErr
		}
		var reconciled []ReconcileResult
		if unmarshalErr := json.Unmarshal(responsePayload, &reconciled); unmarshalErr != nil {
			_ = process.close()
			return nil, InitializeResult{}, wrapHost(
				"decode candidate reconciliation", string(config.ID), unmarshalErr,
			)
		}
		if validateErr := validateReconciliation(config.ID, adoptedHandles, reconciled); validateErr != nil {
			_ = process.close()
			return nil, InitializeResult{}, validateErr
		}
		for _, item := range reconciled {
			if item.State == ReconcileStateOrphaned {
				for _, handle := range adoptedHandles {
					if handle.ID == item.HandleID {
						process.orphanedHandles[handle.ID] = handle
						break
					}
				}
			}
		}
		if len(process.orphanedHandles) > 0 && !allowOrphaned {
			_ = process.close()
			return nil, InitializeResult{}, invalidProtocol(
				string(config.ID), "candidate adapter cannot adopt active handles",
			)
		}
	}
	return process, result, nil
}

func (host *Host) Invoke(
	ctx context.Context,
	pluginID domain.PluginID,
	envelope OperationEnvelope,
) (OperationResult, error) {
	if err := host.circuitAllows(pluginID); err != nil {
		return OperationResult{}, err
	}
	plugin, manifest, err := host.operationManifest(pluginID, envelope)
	if err != nil {
		return OperationResult{}, err
	}
	if envelope.Handle != nil {
		return OperationResult{}, invalidProtocol(string(envelope.ID), "caller supplied an adapter handle value")
	}
	if envelope.HandleID != nil {
		handle, found := activeHandle(plugin.handles, *envelope.HandleID)
		if !found {
			return OperationResult{}, &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "invoke plugin", Resource: string(*envelope.HandleID),
				Message: "active adapter handle does not exist",
			}
		}
		envelope.Handle = &handle
	}
	if err := ValidateOperationEnvelope(envelope, manifest); err != nil {
		return OperationResult{}, err
	}
	contract := manifest.Operations[envelope.Operation]
	attempts := uint32(1)
	if contract.Retryable {
		attempts = plugin.config.Restart.MaxAttempts
	}
	var result OperationResult
	for attempt := uint32(1); attempt <= attempts; attempt++ {
		if err := plugin.process.beginOperation(envelope.ID); err != nil {
			return OperationResult{}, err
		}
		operationContext, cancel := operationDeadline(ctx, envelope.Deadline, plugin.config.Limits)
		payload, encodeErr := json.Marshal(envelope)
		if encodeErr != nil {
			cancel()
			plugin.process.endOperation(envelope.ID)
			return OperationResult{}, wrapHost("encode plugin operation", string(envelope.ID), encodeErr)
		}
		resultPayload, callErr := plugin.process.call(
			operationContext, fmt.Sprintf("%s:%d", envelope.ID, attempt), MethodInvoke, payload,
		)
		cancel()
		plugin.process.endOperation(envelope.ID)
		err = callErr
		if errors.Is(err, context.DeadlineExceeded) || errors.Is(err, context.Canceled) {
			err = errors.Join(err, plugin.process.close())
		}
		if err == nil {
			if err := json.Unmarshal(resultPayload, &result); err != nil {
				return OperationResult{}, wrapHost("decode plugin operation", string(envelope.ID), err)
			}
			if validateErr := ValidateOperationResult(result, envelope, manifest); validateErr != nil {
				return OperationResult{}, validateErr
			}
			host.recordSuccess(pluginID)
			return result, nil
		}
		host.recordFailure(plugin.config)
		if !contract.Retryable || attempt == attempts {
			return OperationResult{}, err
		}
		if err := waitBackoff(ctx, plugin.config.Restart, attempt); err != nil {
			return OperationResult{}, err
		}
		restarted, restartErr := host.restart(ctx, pluginID)
		if restartErr != nil {
			return OperationResult{}, errors.Join(err, restartErr)
		}
		plugin = restarted
	}
	return OperationResult{}, err
}

func operationDeadline(ctx context.Context, requested time.Time, limits WireLimits) (context.Context, context.CancelFunc) {
	maximum := time.Now().Add(time.Duration(limits.MaxOperationSeconds) * time.Second)
	if requested.Before(maximum) {
		maximum = requested
	}
	return context.WithDeadline(ctx, maximum)
}

func pluginLifecycleContext(ctx context.Context, limits WireLimits) (context.Context, context.CancelFunc) {
	return context.WithTimeout(ctx, time.Duration(limits.MaxOperationSeconds)*time.Second)
}

func (host *Host) Cancel(
	ctx context.Context,
	pluginID domain.PluginID,
	params CancelParams,
) error {
	if err := params.OperationID.Validate(); err != nil {
		return err
	}
	if params.Deadline.IsZero() {
		return invalidProtocol(string(params.OperationID), "cancellation deadline is required")
	}
	plugin, err := host.active(pluginID)
	if err != nil {
		return err
	}
	deadlineContext, cancel := context.WithDeadline(ctx, params.Deadline)
	defer cancel()
	var result struct {
		Cancelled bool `json:"cancelled"`
	}
	payload, err := json.Marshal(params)
	if err != nil {
		return wrapHost("encode plugin cancellation", string(params.OperationID), err)
	}
	resultPayload, err := plugin.process.call(
		deadlineContext, "cancel:"+string(params.OperationID), MethodCancel, payload,
	)
	if err != nil {
		killErr := plugin.process.killTree()
		if killErr == nil {
			return nil
		}
		return errors.Join(err, killErr)
	}
	if err := json.Unmarshal(resultPayload, &result); err != nil {
		return wrapHost("decode plugin cancellation", string(params.OperationID), err)
	}
	if !result.Cancelled {
		return invalidProtocol(string(params.OperationID), "plugin did not confirm cancellation")
	}
	return nil
}

func (host *Host) Reconcile(
	ctx context.Context,
	pluginID domain.PluginID,
	handles []HandleDescriptor,
) ([]ReconcileResult, error) {
	seenHandles := make(map[domain.AdapterHandleID]struct{}, len(handles))
	for _, handle := range handles {
		if err := validateHandleDescriptor(handle); err != nil {
			return nil, err
		}
		if handle.PluginID != pluginID {
			return nil, invalidProtocol(string(handle.ID), "reconciled handle belongs to another plugin")
		}
		if _, found := seenHandles[handle.ID]; found {
			return nil, invalidProtocol(string(handle.ID), "reconciled handles must be unique")
		}
		seenHandles[handle.ID] = struct{}{}
	}
	plugin, err := host.active(pluginID)
	if err != nil {
		return nil, err
	}
	result := make([]ReconcileResult, 0, len(handles))
	supported := make([]HandleDescriptor, 0, len(handles))
	for _, handle := range handles {
		orphaned, found := plugin.orphaned[handle.ID]
		if !found {
			supported = append(supported, handle)
			continue
		}
		if !sameHandleDescriptor(orphaned, handle) {
			return nil, invalidProtocol(string(handle.ID), "orphaned handle descriptor changed")
		}
		result = append(result, ReconcileResult{HandleID: handle.ID, State: ReconcileStateOrphaned})
	}
	if len(supported) > 0 {
		payload, err := json.Marshal(ReconcileParams{Handles: supported})
		if err != nil {
			return nil, wrapHost("encode plugin reconciliation", string(pluginID), err)
		}
		lifecycleContext, cancelLifecycle := pluginLifecycleContext(ctx, plugin.config.Limits)
		resultPayload, err := plugin.process.call(lifecycleContext, "reconcile", MethodReconcile, payload)
		cancelLifecycle()
		if err != nil {
			return nil, err
		}
		var reconciled []ReconcileResult
		if err := json.Unmarshal(resultPayload, &reconciled); err != nil {
			return nil, wrapHost("decode plugin reconciliation", string(pluginID), err)
		}
		if err := validateReconciliation(pluginID, supported, reconciled); err != nil {
			return nil, err
		}
		result = append(result, reconciled...)
	}
	if err := validateReconciliation(pluginID, handles, result); err != nil {
		return nil, err
	}
	return result, nil
}

func validateReconciliation(
	pluginID domain.PluginID,
	handles []HandleDescriptor,
	result []ReconcileResult,
) error {
	if len(result) != len(handles) {
		return invalidProtocol(string(pluginID), "plugin reconciliation omitted active handles")
	}
	seen := make(map[domain.AdapterHandleID]struct{}, len(result))
	requested := make(map[domain.AdapterHandleID]struct{}, len(handles))
	for _, handle := range handles {
		requested[handle.ID] = struct{}{}
	}
	for _, item := range result {
		_, requestedHandle := requested[item.HandleID]
		if _, found := seen[item.HandleID]; found || !requestedHandle || !validReconcileState(item.State) {
			return invalidProtocol(string(item.HandleID), "plugin reconciliation result is invalid")
		}
		seen[item.HandleID] = struct{}{}
	}
	return nil
}

func (host *Host) TrackHandle(pluginID domain.PluginID, handle HandleDescriptor) error {
	if err := validateHandleDescriptor(handle); err != nil {
		return err
	}
	if handle.PluginID != pluginID {
		return invalidProtocol(string(handle.ID), "tracked handle belongs to another plugin")
	}
	host.mu.Lock()
	defer host.mu.Unlock()
	active := host.plugins[pluginID]
	if active == nil {
		return &domain.Error{
			Code: domain.ErrorCodeNotFound, Op: "track plugin handle", Resource: string(pluginID),
			Message: "plugin is not active",
		}
	}
	if _, found := active.orphaned[handle.ID]; found {
		return &domain.Error{
			Code: domain.ErrorCodeConflict, Op: "track plugin handle", Resource: string(handle.ID),
			Message: "orphaned handle identifier cannot be reused",
		}
	}
	if !manifestSupportsHandle(active.manifest.Adapters, handle) {
		return invalidProtocol(string(handle.ID), "tracked handle format was not negotiated")
	}
	for _, existing := range active.handles {
		if existing.ID != handle.ID {
			continue
		}
		if sameHandleDescriptor(existing, handle) {
			return nil
		}
		return &domain.Error{
			Code: domain.ErrorCodeConflict, Op: "track plugin handle", Resource: string(handle.ID),
			Message: "tracked handle descriptor changed",
		}
	}
	handle.OpaqueValue = append(json.RawMessage(nil), handle.OpaqueValue...)
	active.handles = append(active.handles, handle)
	active.generation++
	return nil
}

func (host *Host) Close() error {
	host.mu.Lock()
	plugins := make([]*activePlugin, 0, len(host.plugins))
	for _, plugin := range host.plugins {
		plugins = append(plugins, plugin)
	}
	host.plugins = make(map[domain.PluginID]*activePlugin)
	host.mu.Unlock()
	var closeErr error
	for _, plugin := range plugins {
		closeErr = errors.Join(closeErr, plugin.process.close())
	}
	return closeErr
}

func (host *Host) AdapterCapabilities() map[string][]string {
	host.mu.Lock()
	defer host.mu.Unlock()
	capabilities := make(map[string][]string)
	counts := make(map[string]int)
	for pluginID, active := range host.plugins {
		for _, adapter := range active.manifest.Adapters {
			selector := string(pluginID) + "::" + adapter.ID
			capabilities[selector] = append([]string(nil), adapter.Capabilities...)
			counts[adapter.ID]++
		}
	}
	for _, active := range host.plugins {
		for _, adapter := range active.manifest.Adapters {
			if counts[adapter.ID] == 1 {
				capabilities[adapter.ID] = append([]string(nil), adapter.Capabilities...)
			}
		}
	}
	return capabilities
}

func (host *Host) ResolveAdapter(
	port domain.AdapterPort,
	adapterID string,
) (domain.PluginID, []string, error) {
	host.mu.Lock()
	defer host.mu.Unlock()
	var pluginID domain.PluginID
	var capabilities []string
	selectedPlugin, resolvedAdapterID := domain.ParseAdapterSelector(adapterID)
	for candidateID, active := range host.plugins {
		if selectedPlugin != "" && candidateID != selectedPlugin {
			continue
		}
		for _, adapter := range active.manifest.Adapters {
			if adapter.Port != port || adapter.ID != resolvedAdapterID {
				continue
			}
			if pluginID != "" {
				return "", nil, &domain.Error{
					Code: domain.ErrorCodeConflict, Op: "resolve adapter", Resource: adapterID,
					Message: "adapter binding is ambiguous",
				}
			}
			pluginID = candidateID
			capabilities = append([]string(nil), adapter.Capabilities...)
		}
	}
	if pluginID == "" {
		return "", nil, &domain.Error{
			Code: domain.ErrorCodeNotFound, Op: "resolve adapter", Resource: adapterID,
			Message: "negotiated adapter does not exist",
		}
	}
	return pluginID, capabilities, nil
}

func (host *Host) operationManifest(
	pluginID domain.PluginID,
	envelope OperationEnvelope,
) (*activePlugin, AdapterManifest, error) {
	plugin, err := host.active(pluginID)
	if err != nil {
		return nil, AdapterManifest{}, err
	}
	for _, manifest := range plugin.manifest.Adapters {
		if manifest.ID == envelope.AdapterID && manifest.Port == envelope.Port {
			return plugin, manifest, nil
		}
	}
	return nil, AdapterManifest{}, &domain.Error{
		Code: domain.ErrorCodeNotFound, Op: "invoke plugin", Resource: envelope.AdapterID,
		Message: "negotiated adapter does not exist",
	}
}

func (host *Host) active(pluginID domain.PluginID) (*activePlugin, error) {
	host.mu.Lock()
	defer host.mu.Unlock()
	plugin := host.plugins[pluginID]
	if plugin == nil {
		return nil, &domain.Error{
			Code: domain.ErrorCodeNotFound, Op: "use plugin", Resource: string(pluginID),
			Message: "plugin is not active",
		}
	}
	return plugin, nil
}

func (host *Host) restart(ctx context.Context, pluginID domain.PluginID) (*activePlugin, error) {
	for retry := 0; retry < 3; retry++ {
		if err := host.circuitAllows(pluginID); err != nil {
			return nil, err
		}
		host.mu.Lock()
		current := host.plugins[pluginID]
		if current == nil {
			host.mu.Unlock()
			return nil, &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "restart plugin", Resource: string(pluginID),
				Message: "plugin is not active",
			}
		}
		config := current.config
		handles := cloneHandleDescriptors(current.handles)
		generation := current.generation
		host.mu.Unlock()
		process, manifest, err := host.startCandidate(ctx, config, handles, false)
		if err != nil {
			return nil, err
		}
		restarted := &activePlugin{
			config: config, manifest: manifest, process: process, handles: handles,
			orphaned: cloneOrphanedHandles(current.orphaned), generation: generation,
		}
		host.mu.Lock()
		if host.plugins[pluginID] == current && current.generation == generation {
			host.plugins[pluginID] = restarted
			host.mu.Unlock()
			_ = current.process.close()
			return restarted, nil
		}
		host.mu.Unlock()
		_ = process.close()
	}
	return nil, &domain.Error{
		Code: domain.ErrorCodeConflict, Op: "restart plugin", Resource: string(pluginID),
		Message: "active handles changed during plugin restart",
	}
}

func sameHandleDescriptors(first []HandleDescriptor, second []HandleDescriptor) bool {
	if len(first) != len(second) {
		return false
	}
	byID := make(map[domain.AdapterHandleID]HandleDescriptor, len(first))
	for _, handle := range first {
		byID[handle.ID] = handle
	}
	for _, handle := range second {
		existing, found := byID[handle.ID]
		if !found || !sameHandleDescriptor(existing, handle) {
			return false
		}
	}
	return true
}

func sameHandleDescriptor(first HandleDescriptor, second HandleDescriptor) bool {
	return first.ID == second.ID && first.PluginID == second.PluginID && first.Port == second.Port &&
		first.AdapterID == second.AdapterID && first.FormatVersion == second.FormatVersion &&
		bytes.Equal(first.OpaqueValue, second.OpaqueValue)
}

func cloneHandleDescriptors(handles []HandleDescriptor) []HandleDescriptor {
	cloned := make([]HandleDescriptor, len(handles))
	for index, handle := range handles {
		cloned[index] = handle
		cloned[index].OpaqueValue = append(json.RawMessage(nil), handle.OpaqueValue...)
	}
	return cloned
}

func candidateActiveHandles(
	handles []HandleDescriptor,
	orphaned map[domain.AdapterHandleID]HandleDescriptor,
) []HandleDescriptor {
	active := make([]HandleDescriptor, 0, len(handles)-len(orphaned))
	for _, handle := range handles {
		if _, found := orphaned[handle.ID]; !found {
			active = append(active, handle)
		}
	}
	return cloneHandleDescriptors(active)
}

func cloneOrphanedHandles(
	handles map[domain.AdapterHandleID]HandleDescriptor,
) map[domain.AdapterHandleID]HandleDescriptor {
	cloned := make(map[domain.AdapterHandleID]HandleDescriptor, len(handles))
	for id, handle := range handles {
		handle.OpaqueValue = append(json.RawMessage(nil), handle.OpaqueValue...)
		cloned[id] = handle
	}
	return cloned
}

func activeHandle(handles []HandleDescriptor, id domain.AdapterHandleID) (HandleDescriptor, bool) {
	for _, handle := range handles {
		if handle.ID == id {
			handle.OpaqueValue = append(json.RawMessage(nil), handle.OpaqueValue...)
			return handle, true
		}
	}
	return HandleDescriptor{}, false
}

func (host *Host) circuitAllows(pluginID domain.PluginID) error {
	host.mu.Lock()
	defer host.mu.Unlock()
	state := host.circuits[pluginID]
	if state != nil && time.Now().Before(state.openUntil) {
		return &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "start plugin", Resource: string(pluginID),
			Message: "plugin restart circuit is open",
		}
	}
	return nil
}

func (host *Host) recordFailure(config Config) {
	host.mu.Lock()
	defer host.mu.Unlock()
	state := host.circuits[config.ID]
	if state == nil {
		state = &circuitState{}
		host.circuits[config.ID] = state
	}
	state.failures++
	if state.failures >= config.Restart.MaxAttempts {
		state.openUntil = time.Now().Add(config.Restart.CircuitOpenPeriod)
	}
}

func (host *Host) recordSuccess(pluginID domain.PluginID) {
	host.mu.Lock()
	defer host.mu.Unlock()
	host.circuits[pluginID] = &circuitState{}
}

type pluginProcess struct {
	id              domain.PluginID
	command         *exec.Cmd
	stdin           io.WriteCloser
	plan            LaunchPlan
	limits          WireLimits
	events          EventSink
	orphanedHandles map[domain.AdapterHandleID]HandleDescriptor

	writeMu     sync.Mutex
	mu          sync.Mutex
	pending     map[string]chan Response
	sequence    map[domain.OperationID]uint64
	operations  map[domain.OperationID]struct{}
	eventWindow time.Time
	eventCount  uint32
	done        chan struct{}
	waitErr     error
	diagnostics *boundedWriter
	supervisor  *ProcessSupervisor
}

func startPluginProcess(
	ctx context.Context,
	id domain.PluginID,
	plan LaunchPlan,
	limits WireLimits,
	events EventSink,
) (*pluginProcess, error) {
	command := exec.Command(plan.Executable, plan.Arguments...)
	command.Dir = plan.WorkingDirectory
	command.Env = append([]string(nil), plan.Environment...)
	command.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	stdin, err := command.StdinPipe()
	if err != nil {
		return nil, wrapHost("open plugin input", string(id), err)
	}
	stdout, err := command.StdoutPipe()
	if err != nil {
		stdin.Close()
		return nil, wrapHost("open plugin output", string(id), err)
	}
	diagnostics := &boundedWriter{remaining: limits.MaxMessageBytes}
	command.Stderr = diagnostics
	if err := command.Start(); err != nil {
		stdin.Close()
		return nil, wrapHost("start isolated plugin", string(id), err)
	}
	supervisor, err := SuperviseStartedCommand(command)
	if err != nil {
		_ = command.Process.Kill()
		_ = command.Wait()
		stdin.Close()
		return nil, wrapHost("capture isolated plugin process", string(id), err)
	}
	process := &pluginProcess{
		id: id, command: command, stdin: stdin, plan: plan, limits: limits, events: events,
		pending: make(map[string]chan Response), sequence: make(map[domain.OperationID]uint64),
		operations: make(map[domain.OperationID]struct{}),
		done:       make(chan struct{}), diagnostics: diagnostics, supervisor: supervisor,
	}
	go process.readLoop(stdout)
	go func() {
		process.waitErr = supervisor.Wait()
		close(process.done)
	}()
	return process, nil
}

func (process *pluginProcess) call(
	ctx context.Context,
	id string,
	method string,
	paramsValue json.RawMessage,
) (json.RawMessage, error) {
	request, err := NewRequest(id, method, paramsValue)
	if err != nil {
		return nil, err
	}
	responseChannel := make(chan Response, 1)
	process.mu.Lock()
	if _, found := process.pending[id]; found {
		process.mu.Unlock()
		return nil, invalidProtocol(id, "JSON-RPC request identifier is already active")
	}
	process.pending[id] = responseChannel
	process.mu.Unlock()
	defer func() {
		process.mu.Lock()
		delete(process.pending, id)
		process.mu.Unlock()
	}()
	encoded, err := json.Marshal(request)
	if err != nil {
		return nil, wrapHost("encode plugin request", id, err)
	}
	process.writeMu.Lock()
	_, writeErr := process.stdin.Write(append(encoded, '\n'))
	process.writeMu.Unlock()
	if writeErr != nil {
		return nil, wrapHost("write plugin request", id, writeErr)
	}
	select {
	case response := <-responseChannel:
		if response.Error != nil {
			return nil, &domain.Error{
				Code: domain.ErrorCodeInternal, Op: "invoke plugin", Resource: id,
				Message: response.Error.Message,
			}
		}
		return append(json.RawMessage(nil), response.Result...), nil
	case <-process.done:
		return nil, process.exitError(id)
	case <-ctx.Done():
		return nil, ctx.Err()
	}
}

func (process *pluginProcess) readLoop(stdout io.Reader) {
	defer func() { _ = process.killTree() }()
	scanner := bufio.NewScanner(stdout)
	bufferSize := int(process.limits.MaxMessageBytes)
	if bufferSize <= 0 || uint64(bufferSize) != process.limits.MaxMessageBytes {
		bufferSize = maxProtocolJSONBytes
	}
	scanner.Buffer(make([]byte, 4096), bufferSize)
	for scanner.Scan() {
		line := append([]byte(nil), scanner.Bytes()...)
		var header struct {
			ID     string `json:"id"`
			Method string `json:"method"`
		}
		if err := json.Unmarshal(line, &header); err != nil {
			_ = process.killTree()
			return
		}
		if header.Method != "" {
			if !process.handleNotification(line) {
				_ = process.killTree()
				return
			}
			continue
		}
		response, err := DecodeResponse(line, header.ID)
		if err != nil {
			process.mu.Lock()
			pending := process.pending[header.ID]
			process.mu.Unlock()
			if pending == nil {
				_ = process.killTree()
				return
			}
			pending <- Response{
				JSONRPC: JSONRPCVersion, ID: header.ID,
				Error: &RPCError{Code: -32603, Message: err.Error()},
			}
			continue
		}
		process.mu.Lock()
		pending := process.pending[response.ID]
		process.mu.Unlock()
		if pending != nil {
			pending <- response
		}
	}
	if scanner.Err() != nil {
		_ = process.killTree()
	}
}

func (process *pluginProcess) handleNotification(line []byte) bool {
	var notification Notification
	if err := json.Unmarshal(line, &notification); err != nil || notification.JSONRPC != JSONRPCVersion ||
		notification.Method != MethodEvent {
		return false
	}
	var event OperationEvent
	if err := json.Unmarshal(notification.Params, &event); err != nil {
		return false
	}
	process.mu.Lock()
	if _, active := process.operations[event.OperationID]; !active {
		process.mu.Unlock()
		return false
	}
	now := time.Now()
	if process.eventWindow.IsZero() || now.Sub(process.eventWindow) >= time.Second {
		process.eventWindow = now
		process.eventCount = 0
	}
	if process.eventCount >= process.limits.MaxEventsPerSecond {
		process.mu.Unlock()
		return false
	}
	previous := process.sequence[event.OperationID]
	if err := ValidateOperationEvent(event, previous); err != nil {
		process.mu.Unlock()
		return false
	}
	process.sequence[event.OperationID] = event.Sequence
	process.eventCount++
	process.mu.Unlock()
	return process.events.RecordPluginEvent(context.Background(), process.id, event) == nil
}

func (process *pluginProcess) beginOperation(operationID domain.OperationID) error {
	process.mu.Lock()
	defer process.mu.Unlock()
	if _, active := process.operations[operationID]; active {
		return &domain.Error{
			Code: domain.ErrorCodeConflict, Op: "invoke plugin", Resource: string(operationID),
			Message: "plugin operation is already active",
		}
	}
	process.operations[operationID] = struct{}{}
	return nil
}

func (process *pluginProcess) endOperation(operationID domain.OperationID) {
	process.mu.Lock()
	defer process.mu.Unlock()
	delete(process.operations, operationID)
}

func (process *pluginProcess) killTree() error {
	return process.supervisor.Terminate()
}

func (process *pluginProcess) close() error {
	_ = process.killTree()
	select {
	case <-process.done:
		return process.plan.Cleanup()
	default:
	}
	<-process.done
	return process.plan.Cleanup()
}

func (process *pluginProcess) exitError(resource string) error {
	message := "plugin process exited"
	if diagnostics := process.diagnostics.String(); diagnostics != "" {
		message += ": " + diagnostics
	}
	return &domain.Error{
		Code: domain.ErrorCodeInternal, Op: "invoke plugin", Resource: resource,
		Message: message, Err: process.waitErr,
	}
}

type boundedWriter struct {
	mu        sync.Mutex
	buffer    bytes.Buffer
	remaining uint64
}

func (writer *boundedWriter) Write(value []byte) (int, error) {
	writer.mu.Lock()
	defer writer.mu.Unlock()
	requested := len(value)
	if uint64(requested) > writer.remaining {
		value = value[:writer.remaining]
	}
	_, _ = writer.buffer.Write(value)
	writer.remaining -= uint64(len(value))
	return requested, nil
}

func (writer *boundedWriter) String() string {
	writer.mu.Lock()
	defer writer.mu.Unlock()
	return writer.buffer.String()
}

func validateHostConfig(config Config) error {
	if err := config.ID.Validate(); err != nil {
		return err
	}
	if strings.Contains(string(config.ID), "::") {
		return invalidProtocol(string(config.ID), "plugin identifier contains the adapter selector delimiter")
	}
	if config.Restart.MaxAttempts == 0 || config.Restart.InitialBackoff <= 0 ||
		config.Restart.MaxBackoff < config.Restart.InitialBackoff || config.Restart.CircuitOpenPeriod <= 0 {
		return invalidProtocol(string(config.ID), "plugin restart policy is invalid")
	}
	if config.Limits.MaxMessageBytes == 0 || config.Limits.MaxEventsPerSecond == 0 ||
		config.Limits.MaxOperationSeconds == 0 {
		return invalidProtocol(string(config.ID), "plugin wire limits are invalid")
	}
	return nil
}

func waitBackoff(ctx context.Context, policy RestartPolicy, attempt uint32) error {
	delay := policy.InitialBackoff
	for count := uint32(1); count < attempt && delay < policy.MaxBackoff; count++ {
		if delay > policy.MaxBackoff/2 {
			delay = policy.MaxBackoff
			break
		}
		delay *= 2
	}
	timer := time.NewTimer(delay)
	defer timer.Stop()
	select {
	case <-timer.C:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}

func validReconcileState(state ReconcileState) bool {
	return state.Valid()
}

func wrapHost(operation string, resource string, err error) error {
	return &domain.Error{
		Code: domain.ErrorCodeInternal, Op: operation, Resource: resource,
		Message: err.Error(), Err: err,
	}
}
