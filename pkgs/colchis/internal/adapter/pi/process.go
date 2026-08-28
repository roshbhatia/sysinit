package pi

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
)

const (
	defaultMaxRPCBytes   = 1 << 20
	maxEventJournalBytes = 64 << 20
)

type SessionOptions struct {
	SessionID      string
	SessionFile    string
	Directory      string
	Provider       string
	Model          string
	Name           string
	ApproveProject bool
	EventFile      string
}

type SessionSnapshot struct {
	State        string
	SessionID    string
	SessionFile  string
	IsStreaming  bool
	MessageCount uint64
}

type Event = domain.RuntimeEvent
type EventBatch = domain.RuntimeEventBatch

type RPCSession interface {
	Command(context.Context, string, string) (rpcResponse, error)
	Snapshot(context.Context) (SessionSnapshot, error)
	Events(uint64, uint32) (EventBatch, error)
	Close() error
}

type SessionFactory interface {
	Start(context.Context, SessionOptions) (RPCSession, error)
}

type ProcessFactoryConfig struct {
	Executable       string
	Directory        string
	SessionDirectory string
	Environment      []string
	Offline          bool
	MaxMessageBytes  uint64
}

type ProcessFactory struct {
	config ProcessFactoryConfig
}

type rpcResponse struct {
	ID      string          `json:"id"`
	Type    string          `json:"type"`
	Command string          `json:"command"`
	Success bool            `json:"success"`
	Data    json.RawMessage `json:"data"`
	Error   json.RawMessage `json:"error"`
}

type rpcProcess struct {
	command    *exec.Cmd
	supervisor *plugin.ProcessSupervisor
	stdin      io.WriteCloser

	writeMu      sync.Mutex
	mu           sync.Mutex
	pending      map[string]chan rpcResponse
	lastSequence uint64
	nextID       uint64
	state        string
	waitErr      error
	done         chan struct{}
	readDone     chan struct{}
	stderr       *boundedBuffer
	journal      *os.File
	journalPath  string
	journalBytes uint64
	maxLineBytes uint64
}

type boundedBuffer struct {
	mu        sync.Mutex
	remaining uint64
	buffer    bytes.Buffer
}

func NewProcessFactory(config ProcessFactoryConfig) (*ProcessFactory, error) {
	var err error
	if config.Executable == "" {
		config.Executable, err = exec.LookPath("pi")
		if err != nil {
			return nil, adapterError(domain.ErrorCodeNotFound, "pi", err.Error(), err)
		}
	}
	config.Executable, err = filepath.Abs(config.Executable)
	if err != nil {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "pi", "executable path is invalid", err)
	}
	config.Directory, err = filepath.Abs(config.Directory)
	if err != nil || config.Directory == "" {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "pi", "working directory is invalid", err)
	}
	config.SessionDirectory, err = filepath.Abs(config.SessionDirectory)
	if err != nil || config.SessionDirectory == "" {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "pi", "session directory is invalid", err)
	}
	info, err := os.Stat(config.SessionDirectory)
	if err != nil || !info.IsDir() {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "pi", "session directory is unavailable", err)
	}
	if config.MaxMessageBytes == 0 {
		config.MaxMessageBytes = defaultMaxRPCBytes
	}
	if config.MaxMessageBytes > 1<<30 {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "pi", "message byte limit is too large", nil)
	}
	config.Environment = append([]string(nil), config.Environment...)
	return &ProcessFactory{config: config}, nil
}

func (factory *ProcessFactory) Start(ctx context.Context, options SessionOptions) (RPCSession, error) {
	directory := options.Directory
	if directory == "" {
		directory = factory.config.Directory
	}
	directory, err := filepath.Abs(directory)
	if err != nil || !filepath.IsAbs(directory) {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, directory, "working directory is invalid", err)
	}
	info, err := os.Stat(directory)
	if err != nil || !info.IsDir() {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, directory, "working directory is unavailable", err)
	}
	eventFile := options.EventFile
	if eventFile == "" {
		eventFile = filepath.Join(factory.config.SessionDirectory, options.SessionID+".events.jsonl")
	}
	eventFile, err = filepath.Abs(eventFile)
	if err != nil || !pathWithin(factory.config.SessionDirectory, eventFile) {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, eventFile, "event journal path is invalid", err)
	}
	lastSequence, journalBytes, err := loadEventJournal(eventFile, factory.config.MaxMessageBytes)
	if err != nil {
		return nil, err
	}
	journal, err := os.OpenFile(eventFile, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0o600)
	if err != nil {
		return nil, adapterError(domain.ErrorCodeInternal, eventFile, "open event journal failed", err)
	}
	arguments := []string{"--mode", "rpc", "--session-dir", factory.config.SessionDirectory}
	if options.SessionFile != "" {
		arguments = append(arguments, "--session", options.SessionFile)
	} else {
		arguments = append(arguments, "--session-id", options.SessionID)
	}
	if options.Provider != "" {
		arguments = append(arguments, "--provider", options.Provider)
	}
	if options.Model != "" {
		arguments = append(arguments, "--model", options.Model)
	}
	if options.Name != "" {
		arguments = append(arguments, "--name", options.Name)
	}
	if options.ApproveProject {
		arguments = append(arguments, "--approve")
	} else {
		arguments = append(arguments, "--no-approve")
	}
	if factory.config.Offline {
		arguments = append(arguments, "--offline")
	}
	command := exec.Command(factory.config.Executable, arguments...)
	command.Dir = directory
	command.Env = append([]string(nil), factory.config.Environment...)
	command.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	stdin, err := command.StdinPipe()
	if err != nil {
		_ = journal.Close()
		return nil, adapterError(domain.ErrorCodeInternal, "pi", "open RPC input failed", err)
	}
	stdout, err := command.StdoutPipe()
	if err != nil {
		_ = stdin.Close()
		_ = journal.Close()
		return nil, adapterError(domain.ErrorCodeInternal, "pi", "open RPC output failed", err)
	}
	diagnostics := &boundedBuffer{remaining: factory.config.MaxMessageBytes}
	command.Stderr = diagnostics
	if err := command.Start(); err != nil {
		_ = stdin.Close()
		_ = journal.Close()
		return nil, adapterError(domain.ErrorCodeInternal, "pi", "start RPC process failed", err)
	}
	supervisor, err := plugin.SuperviseStartedCommand(command)
	if err != nil {
		_ = command.Process.Kill()
		_ = command.Wait()
		_ = stdin.Close()
		_ = journal.Close()
		return nil, adapterError(domain.ErrorCodeInternal, "pi", "supervise RPC process failed", err)
	}
	process := &rpcProcess{
		command: command, supervisor: supervisor, stdin: stdin, pending: make(map[string]chan rpcResponse),
		lastSequence: lastSequence, state: "idle", done: make(chan struct{}),
		readDone: make(chan struct{}), stderr: diagnostics,
		journal: journal, journalPath: eventFile, journalBytes: journalBytes,
		maxLineBytes: factory.config.MaxMessageBytes,
	}
	go process.readLoop(stdout, factory.config.MaxMessageBytes)
	go process.wait()
	if _, err := process.Snapshot(ctx); err != nil {
		_ = process.Close()
		return nil, err
	}
	return process, nil
}

func (process *rpcProcess) Command(ctx context.Context, commandType string, message string) (rpcResponse, error) {
	process.mu.Lock()
	process.nextID++
	id := fmt.Sprintf("command-%d", process.nextID)
	responseChannel := make(chan rpcResponse, 1)
	process.pending[id] = responseChannel
	process.mu.Unlock()
	defer func() {
		process.mu.Lock()
		delete(process.pending, id)
		process.mu.Unlock()
	}()
	request := struct {
		ID      string `json:"id"`
		Type    string `json:"type"`
		Message string `json:"message,omitempty"`
	}{ID: id, Type: commandType, Message: message}
	encoded, err := json.Marshal(request)
	if err != nil {
		return rpcResponse{}, err
	}
	process.writeMu.Lock()
	_, writeErr := process.stdin.Write(append(encoded, '\n'))
	process.writeMu.Unlock()
	if writeErr != nil {
		return rpcResponse{}, adapterError(domain.ErrorCodeInternal, "pi", "write RPC command failed", writeErr)
	}
	select {
	case response := <-responseChannel:
		if !response.Success {
			message := strings.TrimSpace(string(response.Error))
			if message == "" || message == "null" {
				message = "Pi rejected the RPC command"
			}
			return rpcResponse{}, adapterError(domain.ErrorCodeInvalidArgument, commandType, message, nil)
		}
		return response, nil
	case <-process.done:
		return rpcResponse{}, process.exitError()
	case <-ctx.Done():
		return rpcResponse{}, ctx.Err()
	}
}

func (process *rpcProcess) Snapshot(ctx context.Context) (SessionSnapshot, error) {
	response, err := process.Command(ctx, "get_state", "")
	if err != nil {
		return SessionSnapshot{}, err
	}
	var state struct {
		SessionID    string `json:"sessionId"`
		SessionFile  string `json:"sessionFile"`
		IsStreaming  bool   `json:"isStreaming"`
		MessageCount uint64 `json:"messageCount"`
	}
	if err := json.Unmarshal(response.Data, &state); err != nil {
		return SessionSnapshot{}, adapterError(domain.ErrorCodeInternal, "pi", "state response is invalid", err)
	}
	if state.SessionID == "" || state.SessionFile == "" {
		return SessionSnapshot{}, adapterError(domain.ErrorCodeInternal, "pi", "state response lacks session identity", nil)
	}
	process.mu.Lock()
	current := process.state
	if state.IsStreaming {
		current = "running"
	}
	process.mu.Unlock()
	return SessionSnapshot{
		State: current, SessionID: state.SessionID, SessionFile: state.SessionFile,
		IsStreaming: state.IsStreaming, MessageCount: state.MessageCount,
	}, nil
}

func (process *rpcProcess) Events(cursor uint64, maximum uint32) (EventBatch, error) {
	if maximum == 0 || maximum > 500 {
		maximum = 200
	}
	process.mu.Lock()
	defer process.mu.Unlock()
	return readEventJournalBatch(
		process.journalPath, process.state, cursor, maximum, process.maxLineBytes,
	)
}

func (process *rpcProcess) Close() error {
	_ = process.stdin.Close()
	select {
	case <-process.done:
		<-process.readDone
		return process.closeJournal()
	case <-time.After(2 * time.Second):
	}
	if process.command.Process == nil {
		return process.closeJournal()
	}
	killErr := process.supervisor.Terminate()
	<-process.done
	<-process.readDone
	return errors.Join(killErr, process.closeJournal())
}

func (process *rpcProcess) readLoop(stdout io.Reader, maxMessageBytes uint64) {
	defer close(process.readDone)
	bufferSize := int(maxMessageBytes)
	if bufferSize <= 0 || uint64(bufferSize) != maxMessageBytes {
		bufferSize = defaultMaxRPCBytes
	}
	scanner := bufio.NewScanner(stdout)
	scanner.Buffer(make([]byte, 4096), bufferSize)
	for scanner.Scan() {
		if !process.consume(append([]byte(nil), scanner.Bytes()...)) {
			_ = process.terminate()
			return
		}
	}
	if scanner.Err() != nil {
		_ = process.terminate()
	}
}

func (process *rpcProcess) consume(line []byte) bool {
	var header struct {
		ID   string `json:"id"`
		Type string `json:"type"`
	}
	if err := json.Unmarshal(line, &header); err != nil || header.Type == "" {
		return false
	}
	if header.Type == "response" {
		var response rpcResponse
		if err := json.Unmarshal(line, &response); err != nil || response.ID == "" {
			return false
		}
		process.mu.Lock()
		pending := process.pending[response.ID]
		process.mu.Unlock()
		if pending != nil {
			pending <- response
		}
		return true
	}
	event, err := normalizeEvent(line)
	if err != nil {
		return false
	}
	process.mu.Lock()
	event.Sequence = process.lastSequence + 1
	encoded, err := json.Marshal(event)
	if err != nil || process.journalBytes+uint64(len(encoded)+1) > maxEventJournalBytes {
		process.mu.Unlock()
		return false
	}
	if _, err := process.journal.Write(append(encoded, '\n')); err != nil {
		process.mu.Unlock()
		return false
	}
	if err := process.journal.Sync(); err != nil {
		process.mu.Unlock()
		return false
	}
	process.journalBytes += uint64(len(encoded) + 1)
	process.lastSequence = event.Sequence
	switch header.Type {
	case "agent_start":
		process.state = "running"
	case "agent_settled":
		process.state = "idle"
	}
	process.mu.Unlock()
	return true
}

func (process *rpcProcess) closeJournal() error {
	process.mu.Lock()
	defer process.mu.Unlock()
	if process.journal == nil {
		return nil
	}
	err := process.journal.Close()
	process.journal = nil
	return err
}

func loadEventJournal(path string, maxLineBytes uint64) (uint64, uint64, error) {
	file, err := os.Open(path)
	if errors.Is(err, os.ErrNotExist) {
		return 0, 0, nil
	}
	if err != nil {
		return 0, 0, adapterError(domain.ErrorCodeInternal, path, "open event journal failed", err)
	}
	defer file.Close()
	info, err := file.Stat()
	if err != nil {
		return 0, 0, err
	}
	if info.Size() < 0 || uint64(info.Size()) > maxEventJournalBytes {
		return 0, 0, adapterError(domain.ErrorCodeBudgetExhausted, path, "event journal byte limit is reached", nil)
	}
	bufferSize := int(maxLineBytes)
	if bufferSize <= 0 || uint64(bufferSize) != maxLineBytes {
		bufferSize = defaultMaxRPCBytes
	}
	scanner := bufio.NewScanner(file)
	scanner.Buffer(make([]byte, 4096), bufferSize)
	previous := uint64(0)
	for scanner.Scan() {
		var event Event
		if err := json.Unmarshal(scanner.Bytes(), &event); err != nil || event.Sequence != previous+1 ||
			event.Kind == "" || event.ProviderEventType == "" || event.OccurredAt.IsZero() || !json.Valid(event.Data) {
			return 0, 0, adapterError(domain.ErrorCodeInvalidArgument, path, "event journal is invalid", err)
		}
		previous = event.Sequence
	}
	if err := scanner.Err(); err != nil {
		return 0, 0, adapterError(domain.ErrorCodeInvalidArgument, path, "event journal cannot be read", err)
	}
	return previous, uint64(info.Size()), nil
}

func readEventJournalBatch(
	path string,
	state string,
	cursor uint64,
	maximum uint32,
	maxLineBytes uint64,
) (EventBatch, error) {
	file, err := os.Open(path)
	if errors.Is(err, os.ErrNotExist) {
		return EventBatch{State: state, Cursor: cursor}, nil
	}
	if err != nil {
		return EventBatch{}, adapterError(domain.ErrorCodeInternal, path, "open event journal failed", err)
	}
	defer file.Close()
	bufferSize := int(maxLineBytes)
	if bufferSize <= 0 || uint64(bufferSize) != maxLineBytes {
		bufferSize = defaultMaxRPCBytes
	}
	scanner := bufio.NewScanner(file)
	scanner.Buffer(make([]byte, 4096), bufferSize)
	batch := EventBatch{State: state, Cursor: cursor}
	previous := uint64(0)
	for scanner.Scan() {
		var event Event
		if err := json.Unmarshal(scanner.Bytes(), &event); err != nil || event.Sequence != previous+1 {
			return EventBatch{}, adapterError(domain.ErrorCodeInvalidArgument, path, "event journal is invalid", err)
		}
		previous = event.Sequence
		if batch.FirstAvailableCursor == 0 {
			batch.FirstAvailableCursor = event.Sequence
		}
		if event.Sequence <= cursor {
			continue
		}
		if len(batch.Events) == int(maximum) {
			batch.More = true
			break
		}
		batch.Events = append(batch.Events, event)
		batch.Cursor = event.Sequence
	}
	if err := scanner.Err(); err != nil {
		return EventBatch{}, adapterError(domain.ErrorCodeInvalidArgument, path, "event journal cannot be read", err)
	}
	return batch, nil
}

func pathWithin(parent string, child string) bool {
	relative, err := filepath.Rel(parent, child)
	return err == nil && relative != ".." && !strings.HasPrefix(relative, ".."+string(filepath.Separator))
}

func normalizeEvent(raw json.RawMessage) (Event, error) {
	var source struct {
		Type       string `json:"type"`
		ToolCallID string `json:"toolCallId"`
		ToolName   string `json:"toolName"`
		IsError    bool   `json:"isError"`
		Message    struct {
			Role string `json:"role"`
			ID   string `json:"id"`
		} `json:"message"`
		AssistantEvent struct {
			Type     string `json:"type"`
			ID       string `json:"id"`
			ToolName string `json:"toolName"`
		} `json:"assistantMessageEvent"`
	}
	if err := json.Unmarshal(raw, &source); err != nil || source.Type == "" {
		return Event{}, adapterError(domain.ErrorCodeInvalidArgument, "pi", "RPC event is invalid", err)
	}
	kind := eventKind(source.Type, source.Message.Role, source.AssistantEvent.Type)
	providerID := source.ToolCallID
	if providerID == "" {
		providerID = source.Message.ID
	}
	if providerID == "" {
		providerID = source.AssistantEvent.ID
	}
	data, err := json.Marshal(struct {
		Role      string `json:"role,omitempty"`
		DeltaType string `json:"deltaType,omitempty"`
		ToolName  string `json:"toolName,omitempty"`
		IsError   bool   `json:"isError,omitempty"`
	}{
		Role: source.Message.Role, DeltaType: source.AssistantEvent.Type,
		ToolName: firstNonempty(source.ToolName, source.AssistantEvent.ToolName), IsError: source.IsError,
	})
	if err != nil {
		return Event{}, err
	}
	return Event{
		Kind: kind, ProviderEventType: source.Type, ProviderID: providerID,
		OccurredAt: time.Now().UTC(), Data: data,
	}, nil
}

func eventKind(eventType string, role string, deltaType string) string {
	switch {
	case strings.HasPrefix(eventType, "tool_execution"):
		return "tool_call"
	case strings.HasPrefix(eventType, "message") && (role == "assistant" || deltaType != ""):
		return "model_call"
	case strings.HasPrefix(eventType, "turn"):
		return "turn"
	default:
		return "session"
	}
}

func firstNonempty(first string, second string) string {
	if first != "" {
		return first
	}
	return second
}

func (process *rpcProcess) wait() {
	err := process.supervisor.Wait()
	process.mu.Lock()
	process.waitErr = err
	if err != nil {
		process.state = "failed"
	} else {
		process.state = "completed"
	}
	process.mu.Unlock()
	close(process.done)
}

func (process *rpcProcess) terminate() error {
	return process.supervisor.Terminate()
}

func (process *rpcProcess) exitError() error {
	process.mu.Lock()
	err := process.waitErr
	process.mu.Unlock()
	message := strings.TrimSpace(process.stderr.String())
	if message == "" && err != nil {
		message = err.Error()
	}
	if message == "" {
		message = "Pi RPC process exited"
	}
	return adapterError(domain.ErrorCodeInternal, "pi", message, err)
}

func (buffer *boundedBuffer) Write(value []byte) (int, error) {
	buffer.mu.Lock()
	defer buffer.mu.Unlock()
	written := len(value)
	if uint64(len(value)) > buffer.remaining {
		value = value[:buffer.remaining]
	}
	_, _ = buffer.buffer.Write(value)
	buffer.remaining -= uint64(len(value))
	return written, nil
}

func (buffer *boundedBuffer) String() string {
	buffer.mu.Lock()
	defer buffer.mu.Unlock()
	return buffer.buffer.String()
}
