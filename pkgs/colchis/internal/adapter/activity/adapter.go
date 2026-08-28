package activity

import (
	"bufio"
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/external"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
)

const (
	AdapterID         = "sysinit.activity"
	OperationImport   = "activity.import"
	OperationObserve  = "activity.observe"
	SourceTraces      = "traces"
	SourceEdits       = "agent-edit-event"
	defaultMaxBytes   = 8 << 20
	defaultMaxRecords = 250
	maximumMaxRecords = 1000
)

type CommandRunner interface {
	Run(context.Context, external.Request) (external.Result, error)
}

type Config struct {
	TracesExecutable    string
	EditEventExecutable string
	Directory           string
	Environment         []string
	MaxSourceBytes      uint64
}

type Adapter struct {
	runner CommandRunner
	config Config
}

type ImportRequest struct {
	Workspace       string   `json:"workspace,omitempty"`
	Session         string   `json:"session,omitempty"`
	Sources         []string `json:"sources"`
	AfterUnixMillis int64    `json:"afterUnixMillis,omitempty"`
	MaxRecords      uint32   `json:"maxRecords,omitempty"`
}

type ObserveRequest struct {
	SourceID string `json:"sourceId"`
	ImportRequest
}

type Record struct {
	Source         string          `json:"source"`
	SourceID       string          `json:"sourceId"`
	ParentSourceID string          `json:"parentSourceId,omitempty"`
	Kind           string          `json:"kind"`
	Provider       string          `json:"provider,omitempty"`
	Session        string          `json:"session,omitempty"`
	Basis          string          `json:"basis"`
	Authority      string          `json:"authority"`
	StartedAt      time.Time       `json:"startedAt"`
	EndedAt        *time.Time      `json:"endedAt,omitempty"`
	OpaqueData     json.RawMessage `json:"opaqueData"`
}

type ImportResult struct {
	Records      []Record `json:"records"`
	SourceDigest string   `json:"sourceDigest"`
	TotalRecords uint32   `json:"totalRecords"`
	Truncated    bool     `json:"truncated"`
}

type traceLine struct {
	Event    string            `json:"event"`
	TraceID  string            `json:"traceId"`
	SpanID   string            `json:"spanId"`
	ParentID string            `json:"parentId"`
	Name     string            `json:"name"`
	Service  string            `json:"service"`
	Session  string            `json:"session"`
	Start    string            `json:"startUnixNano"`
	End      string            `json:"endUnixNano"`
	Attrs    map[string]string `json:"attrs"`
	Failed   bool              `json:"failed"`
	Error    string            `json:"error"`
}

type editLine struct {
	Version int    `json:"version"`
	TS      int64  `json:"ts"`
	Harness string `json:"harness"`
	Kind    string `json:"kind"`
	File    string `json:"file"`
	CWD     string `json:"cwd"`
	Session string `json:"session"`
	Delta   string `json:"delta"`
}

func New(config Config, runner CommandRunner) (*Adapter, error) {
	if runner == nil {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "runner", "runner is nil", nil)
	}
	var err error
	if config.TracesExecutable == "" {
		config.TracesExecutable, err = exec.LookPath("traces")
		if err != nil {
			return nil, adapterError(domain.ErrorCodeNotFound, "traces", err.Error(), err)
		}
	}
	if config.EditEventExecutable == "" {
		config.EditEventExecutable, err = exec.LookPath("agent-edit-event")
		if err != nil {
			return nil, adapterError(domain.ErrorCodeNotFound, "agent-edit-event", err.Error(), err)
		}
	}
	config.TracesExecutable, err = filepath.Abs(config.TracesExecutable)
	if err != nil {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "traces", "executable path is invalid", err)
	}
	config.EditEventExecutable, err = filepath.Abs(config.EditEventExecutable)
	if err != nil {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "agent-edit-event", "executable path is invalid", err)
	}
	config.Directory, err = filepath.Abs(config.Directory)
	if err != nil || config.Directory == "" {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "activity", "working directory is invalid", err)
	}
	if config.MaxSourceBytes == 0 {
		config.MaxSourceBytes = defaultMaxBytes
	}
	if config.MaxSourceBytes > 1<<30 {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "activity", "source byte limit is too large", nil)
	}
	config.Environment = append([]string(nil), config.Environment...)
	return &Adapter{runner: runner, config: config}, nil
}

func NewLocal(directory string, maxSourceBytes uint64) (*Adapter, error) {
	return New(Config{
		Directory: directory, Environment: os.Environ(), MaxSourceBytes: maxSourceBytes,
	}, external.NewRunner(maxSourceBytes))
}

func (adapter *Adapter) Invoke(
	ctx context.Context,
	envelope plugin.OperationEnvelope,
	_ plugin.EventEmitter,
) (plugin.OperationResult, error) {
	var request ImportRequest
	filter := ""
	switch envelope.Operation {
	case OperationImport:
		decoded, err := decodeRequest[ImportRequest](envelope.Input)
		if err != nil {
			return plugin.OperationResult{}, err
		}
		request = decoded
	case OperationObserve:
		decoded, err := decodeRequest[ObserveRequest](envelope.Input)
		if err != nil {
			return plugin.OperationResult{}, err
		}
		if decoded.SourceID == "" {
			return plugin.OperationResult{}, adapterError(domain.ErrorCodeInvalidArgument, "source", "source identifier is required", nil)
		}
		request = decoded.ImportRequest
		filter = decoded.SourceID
	default:
		return plugin.OperationResult{}, adapterError(domain.ErrorCodeNotFound, envelope.Operation, "operation is unknown", nil)
	}
	result, err := adapter.importRecords(ctx, request)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	if filter != "" {
		filtered := make([]Record, 0, 1)
		for _, record := range result.Records {
			if record.SourceID == filter {
				filtered = append(filtered, record)
			}
		}
		if len(filtered) == 0 {
			return plugin.OperationResult{}, adapterError(domain.ErrorCodeNotFound, filter, "activity source does not exist", nil)
		}
		result.Records = filtered
	}
	result.TotalRecords = uint32(len(result.Records))
	limit := request.MaxRecords
	if limit == 0 {
		limit = defaultMaxRecords
	}
	if limit > maximumMaxRecords {
		return plugin.OperationResult{}, adapterError(
			domain.ErrorCodeInvalidArgument, "maxRecords", "record limit exceeds 1000", nil,
		)
	}
	if len(result.Records) > int(limit) {
		result.Records = result.Records[len(result.Records)-int(limit):]
		result.Truncated = true
	}
	output, err := json.Marshal(result)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	return plugin.OperationResult{ID: envelope.ID, State: domain.OperationStateSucceeded, Output: output}, nil
}

func (adapter *Adapter) importRecords(ctx context.Context, request ImportRequest) (ImportResult, error) {
	if len(request.Sources) == 0 {
		return ImportResult{}, adapterError(domain.ErrorCodeInvalidArgument, "sources", "activity sources are empty", nil)
	}
	workspace := adapter.config.Directory
	if request.Workspace != "" {
		absolute, err := filepath.Abs(request.Workspace)
		if err != nil {
			return ImportResult{}, adapterError(domain.ErrorCodeInvalidArgument, request.Workspace, "workspace is invalid", err)
		}
		workspace = absolute
	}
	seen := make(map[string]struct{}, len(request.Sources))
	records := make([]Record, 0)
	payloads := make([][]byte, 0, len(request.Sources))
	for _, source := range request.Sources {
		if _, found := seen[source]; found {
			return ImportResult{}, adapterError(domain.ErrorCodeInvalidArgument, source, "activity source is duplicated", nil)
		}
		seen[source] = struct{}{}
		switch source {
		case SourceTraces:
			imported, payload, err := adapter.importTraces(ctx, workspace, request)
			if err != nil {
				return ImportResult{}, err
			}
			records = append(records, imported...)
			payloads = append(payloads, payload)
		case SourceEdits:
			if request.Workspace == "" {
				return ImportResult{}, adapterError(
					domain.ErrorCodeInvalidArgument, source, "workspace is required for edit events", nil,
				)
			}
			imported, payload, err := adapter.importEdits(ctx, workspace, request)
			if err != nil {
				return ImportResult{}, err
			}
			records = append(records, imported...)
			payloads = append(payloads, payload)
		default:
			return ImportResult{}, adapterError(domain.ErrorCodeInvalidArgument, source, "activity source is unknown", nil)
		}
	}
	sort.Slice(records, func(first int, second int) bool {
		if records[first].StartedAt.Equal(records[second].StartedAt) {
			return records[first].SourceID < records[second].SourceID
		}
		return records[first].StartedAt.Before(records[second].StartedAt)
	})
	hash := sha256.New()
	for _, payload := range payloads {
		_, _ = fmt.Fprintf(hash, "%d:", len(payload))
		_, _ = hash.Write(payload)
	}
	return ImportResult{Records: records, SourceDigest: fmt.Sprintf("sha256:%x", hash.Sum(nil))}, nil
}

func (adapter *Adapter) importTraces(
	ctx context.Context,
	workspace string,
	request ImportRequest,
) ([]Record, []byte, error) {
	arguments := []string{"-json"}
	if request.Session != "" {
		arguments = append(arguments, "-session", request.Session)
	}
	if request.Workspace == "" {
		arguments = append(arguments, "-all")
	}
	result, err := adapter.runner.Run(ctx, external.Request{
		Executable: adapter.config.TracesExecutable, Arguments: arguments,
		Directory: workspace, Environment: adapter.config.Environment,
	})
	if err != nil {
		return nil, nil, err
	}
	if result.ExitCode != 0 {
		return nil, nil, commandError(SourceTraces, result)
	}
	records := make([]Record, 0)
	scanner := bufio.NewScanner(bytes.NewReader(result.Stdout))
	scanner.Buffer(make([]byte, 4096), int(adapter.config.MaxSourceBytes))
	for scanner.Scan() {
		raw := append(json.RawMessage(nil), scanner.Bytes()...)
		var line traceLine
		if err := json.Unmarshal(raw, &line); err != nil {
			return nil, nil, adapterError(domain.ErrorCodeInvalidArgument, SourceTraces, "trace line is invalid", err)
		}
		record, err := normalizeTrace(line, raw)
		if err != nil {
			return nil, nil, err
		}
		if record.StartedAt.UnixMilli() >= request.AfterUnixMillis {
			records = append(records, record)
		}
	}
	if err := scanner.Err(); err != nil {
		return nil, nil, adapterError(domain.ErrorCodeBudgetExhausted, SourceTraces, err.Error(), err)
	}
	return records, append([]byte(nil), result.Stdout...), nil
}

func (adapter *Adapter) importEdits(
	ctx context.Context,
	workspace string,
	request ImportRequest,
) ([]Record, []byte, error) {
	result, err := adapter.runner.Run(ctx, external.Request{
		Executable: adapter.config.EditEventExecutable,
		Arguments:  []string{"--print-log", "--cwd", workspace},
		Directory:  workspace, Environment: adapter.config.Environment,
	})
	if err != nil {
		return nil, nil, err
	}
	if result.ExitCode != 0 {
		return nil, nil, commandError(SourceEdits, result)
	}
	path := strings.TrimSpace(string(result.Stdout))
	if !filepath.IsAbs(path) {
		return nil, nil, adapterError(domain.ErrorCodeInvalidArgument, SourceEdits, "edit-event log path is invalid", nil)
	}
	payload, err := readBounded(path, adapter.config.MaxSourceBytes)
	if err != nil {
		if os.IsNotExist(err) {
			return []Record{}, []byte{}, nil
		}
		return nil, nil, err
	}
	records := make([]Record, 0)
	scanner := bufio.NewScanner(bytes.NewReader(payload))
	scanner.Buffer(make([]byte, 4096), int(adapter.config.MaxSourceBytes))
	for scanner.Scan() {
		var line editLine
		if err := json.Unmarshal(scanner.Bytes(), &line); err != nil {
			return nil, nil, adapterError(domain.ErrorCodeInvalidArgument, SourceEdits, "edit event is invalid", err)
		}
		if line.Version != 1 || line.TS < request.AfterUnixMillis {
			continue
		}
		record, err := normalizeEdit(line)
		if err != nil {
			return nil, nil, err
		}
		records = append(records, record)
	}
	if err := scanner.Err(); err != nil {
		return nil, nil, adapterError(domain.ErrorCodeBudgetExhausted, SourceEdits, err.Error(), err)
	}
	return records, payload, nil
}

func normalizeTrace(line traceLine, raw json.RawMessage) (Record, error) {
	startedAt, err := unixNanos(line.Start)
	if err != nil {
		return Record{}, err
	}
	var endedAt *time.Time
	if line.End != "" {
		value, err := unixNanos(line.End)
		if err != nil {
			return Record{}, err
		}
		endedAt = &value
	}
	sourceID := ""
	if line.Event == "" && line.TraceID != "" && line.SpanID != "" {
		sourceID = line.TraceID + ":" + line.SpanID
	} else {
		hash := sha256.Sum256(raw)
		sourceID = fmt.Sprintf("record:%x", hash)
	}
	parent := ""
	if line.TraceID != "" && line.ParentID != "" {
		parent = line.TraceID + ":" + line.ParentID
	}
	return Record{
		Source: SourceTraces, SourceID: sourceID,
		ParentSourceID: parent, Kind: traceKind(line), Provider: line.Service, Session: line.Session,
		Basis: "adapter_reported", Authority: "advisory", StartedAt: startedAt, EndedAt: endedAt,
		OpaqueData: traceOpaqueData(line),
	}, nil
}

func traceOpaqueData(line traceLine) json.RawMessage {
	attributeNames := []string{
		"cwd", "decision", "event.kind", "exit_code", "model", "success", "tool_name", "traces.action",
	}
	attributes := make(map[string]string, len(attributeNames))
	for _, name := range attributeNames {
		value := line.Attrs[name]
		if value == "" {
			continue
		}
		if len(value) > 1024 {
			value = value[:1024]
		}
		attributes[name] = value
	}
	payload, err := json.Marshal(struct {
		Event    string            `json:"event,omitempty"`
		TraceID  string            `json:"traceId,omitempty"`
		SpanID   string            `json:"spanId,omitempty"`
		ParentID string            `json:"parentId,omitempty"`
		Name     string            `json:"name,omitempty"`
		Failed   bool              `json:"failed,omitempty"`
		Error    string            `json:"error,omitempty"`
		Attrs    map[string]string `json:"attrs,omitempty"`
	}{
		Event: line.Event, TraceID: line.TraceID, SpanID: line.SpanID, ParentID: line.ParentID,
		Name: line.Name, Failed: line.Failed, Error: line.Error, Attrs: attributes,
	})
	if err != nil {
		return json.RawMessage(`{}`)
	}
	return payload
}

func normalizeEdit(line editLine) (Record, error) {
	if line.Harness == "" || line.Kind == "" || line.File == "" || line.TS <= 0 {
		return Record{}, adapterError(domain.ErrorCodeInvalidArgument, SourceEdits, "edit event is incomplete", nil)
	}
	sanitized, err := json.Marshal(struct {
		Version int    `json:"version"`
		Harness string `json:"harness"`
		Kind    string `json:"kind"`
		File    string `json:"file"`
		CWD     string `json:"cwd"`
		Session string `json:"session,omitempty"`
	}{
		Version: line.Version, Harness: line.Harness, Kind: line.Kind,
		File: line.File, CWD: line.CWD, Session: line.Session,
	})
	if err != nil {
		return Record{}, err
	}
	hash := sha256.Sum256([]byte(fmt.Sprintf(
		"%d\x00%s\x00%s\x00%s\x00%s", line.TS, line.Harness, line.Kind, line.File, line.Session,
	)))
	return Record{
		Source: SourceEdits, SourceID: fmt.Sprintf("edit:%x", hash), Kind: "tool_call",
		Provider: line.Harness, Session: line.Session, Basis: "adapter_reported", Authority: "advisory",
		StartedAt: time.UnixMilli(line.TS).UTC(), OpaqueData: sanitized,
	}, nil
}

func traceKind(line traceLine) string {
	switch line.Name {
	case "agent.turn":
		return "turn"
	case "agent.model":
		return "model_call"
	case "agent.tool", "agent.edit":
		return "tool_call"
	default:
		return eventKind(line.Event)
	}
}

func eventKind(event string) string {
	switch {
	case strings.Contains(event, "tool"), strings.Contains(event, "edit"):
		return "tool_call"
	case strings.Contains(event, "model"), strings.Contains(event, "sse"), strings.Contains(event, "websocket"):
		return "model_call"
	case event != "":
		return "turn"
	default:
		return "session"
	}
}

func unixNanos(value string) (time.Time, error) {
	nanos, err := strconv.ParseInt(value, 10, 64)
	if err != nil || nanos <= 0 {
		return time.Time{}, adapterError(domain.ErrorCodeInvalidArgument, SourceTraces, "trace timestamp is invalid", err)
	}
	return time.Unix(0, nanos).UTC(), nil
}

func readBounded(path string, maxBytes uint64) ([]byte, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()
	reader := io.LimitReader(file, int64(maxBytes)+1)
	payload, err := io.ReadAll(reader)
	if err != nil {
		return nil, err
	}
	if uint64(len(payload)) > maxBytes {
		return nil, adapterError(domain.ErrorCodeBudgetExhausted, path, "activity source exceeded its byte limit", nil)
	}
	return payload, nil
}

func commandError(source string, result external.Result) error {
	message := strings.TrimSpace(string(result.Stderr))
	if message == "" {
		message = fmt.Sprintf("source exited with status %d", result.ExitCode)
	}
	return adapterError(domain.ErrorCodeInternal, source, message, nil)
}

type requestDocument interface {
	ImportRequest | ObserveRequest
}

func decodeRequest[Request requestDocument](payload json.RawMessage) (Request, error) {
	var request Request
	decoder := json.NewDecoder(bytes.NewReader(payload))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&request); err != nil {
		return request, adapterError(domain.ErrorCodeInvalidArgument, "request", err.Error(), err)
	}
	var trailing json.RawMessage
	if err := decoder.Decode(&trailing); err != io.EOF {
		return request, adapterError(domain.ErrorCodeInvalidArgument, "request", "request has trailing JSON", err)
	}
	return request, nil
}

func adapterError(code domain.ErrorCode, resource string, message string, err error) error {
	return &domain.Error{Code: code, Op: "use activity adapter", Resource: resource, Message: message, Err: err}
}
