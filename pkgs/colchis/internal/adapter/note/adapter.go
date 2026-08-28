package note

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/external"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
)

const (
	AdapterID       = "sysinit.note"
	OperationSync   = "annotation.sync"
	OperationAnswer = "annotation.answer"
	Source          = "utils-note"
	defaultMaxBytes = 4 << 20
)

type CommandRunner interface {
	Run(context.Context, external.Request) (external.Result, error)
}

type Config struct {
	Executable     string
	Directory      string
	Environment    []string
	MaxSourceBytes uint64
}

type Adapter struct {
	runner CommandRunner
	config Config
}

type SyncRequest struct {
	File     string `json:"file,omitempty"`
	OpenOnly bool   `json:"openOnly,omitempty"`
}

type AnswerRequest struct {
	ID        string `json:"id"`
	Summary   string `json:"summary"`
	Rationale string `json:"rationale,omitempty"`
	Author    string `json:"author,omitempty"`
}

type Anchor struct {
	File string `json:"file"`
	Line int64  `json:"line"`
	Text string `json:"text"`
}

type Record struct {
	Source    string `json:"source"`
	SourceID  string `json:"sourceId"`
	ReplyTo   string `json:"replyTo,omitempty"`
	Kind      string `json:"kind"`
	Summary   string `json:"summary"`
	Rationale string `json:"rationale,omitempty"`
	Author    string `json:"author"`
	Origin    string `json:"origin"`
	State     string `json:"state"`
	Authority string `json:"authority"`
	Anchor    Anchor `json:"anchor"`
}

type Result struct {
	Records      []Record `json:"records"`
	SourceDigest string   `json:"sourceDigest"`
}

type sourceDocument struct {
	Version int          `json:"version"`
	Notes   []sourceNote `json:"notes"`
}

type sourceNote struct {
	ID        string  `json:"id"`
	File      string  `json:"file"`
	Line      int64   `json:"line"`
	Summary   string  `json:"summary"`
	Rationale *string `json:"rationale"`
	Author    string  `json:"author"`
	Origin    string  `json:"origin"`
	Anchor    string  `json:"anchor"`
	State     string  `json:"state"`
	ReplyTo   string  `json:"reply_to"`
}

func New(config Config, runner CommandRunner) (*Adapter, error) {
	if runner == nil {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "runner", "runner is nil", nil)
	}
	var err error
	if config.Executable == "" {
		config.Executable, err = exec.LookPath("utils")
		if err != nil {
			return nil, adapterError(domain.ErrorCodeNotFound, "utils", err.Error(), err)
		}
	}
	config.Executable, err = filepath.Abs(config.Executable)
	if err != nil {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "utils", "executable path is invalid", err)
	}
	config.Directory, err = filepath.Abs(config.Directory)
	if err != nil || config.Directory == "" {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, Source, "working directory is invalid", err)
	}
	if config.MaxSourceBytes == 0 {
		config.MaxSourceBytes = defaultMaxBytes
	}
	if config.MaxSourceBytes > 1<<30 {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, Source, "source byte limit is too large", nil)
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
	var result Result
	var err error
	switch envelope.Operation {
	case OperationSync:
		request, decodeErr := decodeRequest[SyncRequest](envelope.Input)
		if decodeErr != nil {
			return plugin.OperationResult{}, decodeErr
		}
		result, err = adapter.sync(ctx, request)
	case OperationAnswer:
		request, decodeErr := decodeRequest[AnswerRequest](envelope.Input)
		if decodeErr != nil {
			return plugin.OperationResult{}, decodeErr
		}
		result, err = adapter.answer(ctx, request)
	default:
		return plugin.OperationResult{}, adapterError(
			domain.ErrorCodeNotFound, envelope.Operation, "operation is unknown", nil,
		)
	}
	if err != nil {
		return plugin.OperationResult{}, err
	}
	output, err := json.Marshal(result)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	return plugin.OperationResult{ID: envelope.ID, State: domain.OperationStateSucceeded, Output: output}, nil
}

func (adapter *Adapter) sync(ctx context.Context, request SyncRequest) (Result, error) {
	arguments := []string{"note", "list", "--json"}
	if request.File != "" {
		arguments = append(arguments, "--file", request.File)
	}
	if request.OpenOnly {
		arguments = append(arguments, "--open")
	}
	payload, err := adapter.run(ctx, arguments)
	if err != nil {
		return Result{}, err
	}
	return normalize(payload, "")
}

func (adapter *Adapter) answer(ctx context.Context, request AnswerRequest) (Result, error) {
	if strings.TrimSpace(request.ID) == "" || strings.TrimSpace(request.Summary) == "" {
		return Result{}, adapterError(
			domain.ErrorCodeInvalidArgument, "answer", "note identifier and summary are required", nil,
		)
	}
	arguments := []string{"note", "answer", "--id", request.ID, "--summary", request.Summary}
	if request.Rationale != "" {
		arguments = append(arguments, "--rationale", request.Rationale)
	}
	if request.Author != "" {
		arguments = append(arguments, "--author", request.Author)
	}
	if _, err := adapter.run(ctx, arguments); err != nil {
		return Result{}, err
	}
	payload, err := adapter.run(ctx, []string{"note", "list", "--json"})
	if err != nil {
		return Result{}, err
	}
	return normalize(payload, request.ID)
}

func (adapter *Adapter) run(ctx context.Context, arguments []string) ([]byte, error) {
	result, err := adapter.runner.Run(ctx, external.Request{
		Executable: adapter.config.Executable, Arguments: arguments,
		Directory: adapter.config.Directory, Environment: adapter.config.Environment,
	})
	if err != nil {
		return nil, err
	}
	if result.ExitCode != 0 {
		message := strings.TrimSpace(string(result.Stderr))
		if message == "" {
			message = fmt.Sprintf("utils exited with status %d", result.ExitCode)
		}
		return nil, adapterError(domain.ErrorCodeInternal, Source, message, nil)
	}
	return append([]byte(nil), result.Stdout...), nil
}

func normalize(payload []byte, answerTo string) (Result, error) {
	decoder := json.NewDecoder(bytes.NewReader(payload))
	var document sourceDocument
	if err := decoder.Decode(&document); err != nil {
		return Result{}, adapterError(domain.ErrorCodeInvalidArgument, Source, "note document is invalid", err)
	}
	var trailing json.RawMessage
	if err := decoder.Decode(&trailing); err != io.EOF {
		return Result{}, adapterError(domain.ErrorCodeInvalidArgument, Source, "note document has trailing JSON", err)
	}
	if document.Version != 1 {
		return Result{}, adapterError(domain.ErrorCodeUnsupportedVersion, Source, "note document version is unsupported", nil)
	}
	records := make([]Record, 0, len(document.Notes))
	for _, note := range document.Notes {
		if answerTo != "" && note.ID != answerTo && note.ReplyTo != answerTo {
			continue
		}
		record, err := normalizeNote(note)
		if err != nil {
			return Result{}, err
		}
		records = append(records, record)
	}
	if answerTo != "" && len(records) < 2 {
		return Result{}, adapterError(domain.ErrorCodeNotFound, answerTo, "answered note or reply is missing", nil)
	}
	hash := sha256.Sum256(payload)
	return Result{Records: records, SourceDigest: fmt.Sprintf("sha256:%x", hash)}, nil
}

func normalizeNote(note sourceNote) (Record, error) {
	if note.ID == "" || note.File == "" || note.Line <= 0 || note.Summary == "" || note.Author == "" {
		return Record{}, adapterError(domain.ErrorCodeInvalidArgument, Source, "note identity or anchor is incomplete", nil)
	}
	authority := "advisory"
	if note.Origin == "user" {
		authority = "owner"
	} else if note.Origin != "agent" {
		return Record{}, adapterError(domain.ErrorCodeInvalidArgument, note.ID, "note origin is invalid", nil)
	}
	kind := "annotation"
	state := note.State
	if note.ReplyTo != "" {
		kind = "reply"
		state = "answered"
	}
	if state == "" && note.Origin == "agent" {
		state = "answered"
	}
	if state != "open" && state != "answered" {
		return Record{}, adapterError(domain.ErrorCodeInvalidArgument, note.ID, "note state is invalid", nil)
	}
	rationale := ""
	if note.Rationale != nil {
		rationale = *note.Rationale
	}
	return Record{
		Source: Source, SourceID: note.ID, ReplyTo: note.ReplyTo, Kind: kind,
		Summary: note.Summary, Rationale: rationale, Author: note.Author,
		Origin: note.Origin, State: state, Authority: authority,
		Anchor: Anchor{File: note.File, Line: note.Line, Text: note.Anchor},
	}, nil
}

type requestDocument interface {
	SyncRequest | AnswerRequest
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
	return &domain.Error{Code: code, Op: "use note adapter", Resource: resource, Message: message, Err: err}
}
