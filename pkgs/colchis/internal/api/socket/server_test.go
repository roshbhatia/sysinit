package socket

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

type commandCall struct {
	principal Principal
	request   CommandRequest
}

func shortSocketTempRoot() string {
	if runtime.GOOS == "darwin" {
		return "/tmp"
	}
	return ""
}

func TestAcquireOwnershipRejectsNonPortableSocketPath(t *testing.T) {
	directory, err := os.MkdirTemp(shortSocketTempRoot(), "colchis-path-")
	if err != nil {
		t.Fatalf("MkdirTemp() returned %v", err)
	}
	t.Cleanup(func() { os.RemoveAll(directory) })
	path := filepath.Join(directory, strings.Repeat("s", maxSocketPathBytes))
	_, err = AcquireOwnership(path)
	if !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("AcquireOwnership() error = %v", err)
	}
}

func TestClientLeavesCommandDeadlineToCaller(t *testing.T) {
	client, err := NewClient(filepath.Join(t.TempDir(), "broker.sock"))
	if err != nil {
		t.Fatalf("NewClient() returned %v", err)
	}
	t.Cleanup(client.Close)
	if client.http.Timeout != 0 {
		t.Fatalf("client timeout = %s", client.http.Timeout)
	}
}

type recordingCommandHandler struct {
	calls chan commandCall
}

type blockingCommandHandler struct {
	started chan struct{}
	release chan struct{}
}

func (handler *blockingCommandHandler) HandleCommand(
	context.Context,
	Principal,
	CommandRequest,
) (domain.CommandRecord, error) {
	close(handler.started)
	<-handler.release
	return domain.CommandRecord{}, nil
}

type recoveringCommandHandler struct {
	recordingCommandHandler
	recoveries int
}

func (handler *recoveringCommandHandler) RecoverInterruptedCommands(context.Context) error {
	handler.recoveries++
	return nil
}

func (handler *recordingCommandHandler) HandleCommand(
	_ context.Context,
	principal Principal,
	request CommandRequest,
) (domain.CommandRecord, error) {
	handler.calls <- commandCall{principal: principal, request: request}
	return domain.CommandRecord{
		Metadata:        testMetadata(),
		ID:              request.ID,
		IdempotencyKey:  request.IdempotencyKey,
		Principal:       principal.Identifier(),
		Kind:            request.Kind,
		ExpectedVersion: request.ExpectedVersion,
		State:           domain.CommandStateAccepted,
		Payload:         request.Payload,
	}, nil
}

type eventCall struct {
	cursor domain.EventCursor
	limit  uint32
}

type recordingEventReader struct {
	calls  chan eventCall
	events []domain.EventEnvelope
}

func (reader *recordingEventReader) EventsAfter(
	_ context.Context,
	cursor domain.EventCursor,
	limit uint32,
) ([]domain.EventEnvelope, error) {
	reader.calls <- eventCall{cursor: cursor, limit: limit}
	return reader.events, nil
}

func TestCommandEndpointBindsPeerPrincipal(t *testing.T) {
	handler := &recordingCommandHandler{calls: make(chan commandCall, 1)}
	reader := &recordingEventReader{calls: make(chan eventCall, 1)}
	client, socketPath := startTestServer(t, handler, reader)

	response := postCommand(t, client, `{
		"id":"command-1",
		"idempotencyKey":"request-1",
		"kind":"workflow.patch",
		"expectedVersion":2,
		"payload":{"edge":"build-to-test"}
	}`)
	defer response.Body.Close()
	if response.StatusCode != http.StatusAccepted {
		body, _ := io.ReadAll(response.Body)
		t.Fatalf("status = %d, body = %s", response.StatusCode, body)
	}

	call := <-handler.calls
	if call.principal.UID != uint32(os.Geteuid()) || call.principal.Role != PrincipalRoleOwner {
		t.Fatalf("principal = %#v", call.principal)
	}
	if call.request.Kind != "workflow.patch" || call.request.ExpectedVersion == nil || *call.request.ExpectedVersion != 2 {
		t.Fatalf("request = %#v", call.request)
	}
	if call.request.ID != "command-1" || call.request.IdempotencyKey != "request-1" {
		t.Fatalf("command identity = %#v", call.request)
	}
	var result commandResponse
	if err := json.NewDecoder(response.Body).Decode(&result); err != nil {
		t.Fatalf("Decode() returned %v", err)
	}
	if result.Command.Principal != call.principal.Identifier() {
		t.Fatalf("command principal = %q", result.Command.Principal)
	}

	info, err := os.Stat(socketPath)
	if err != nil {
		t.Fatalf("Stat() returned %v", err)
	}
	if info.Mode().Perm() != 0o600 {
		t.Fatalf("socket mode = %o", info.Mode().Perm())
	}
}

func TestOpenFencesRecoveryWithSocketOwnership(t *testing.T) {
	private, err := os.MkdirTemp(shortSocketTempRoot(), "colchis-fence-")
	if err != nil {
		t.Fatalf("MkdirTemp() returned %v", err)
	}
	path := filepath.Join(private, "colchis.sock")
	t.Cleanup(func() {
		os.Remove(path + ".lock")
		if err := os.Remove(private); err != nil {
			t.Errorf("Remove() returned %v", err)
		}
	})
	reader := &recordingEventReader{calls: make(chan eventCall, 1)}
	firstHandler := &recoveringCommandHandler{
		recordingCommandHandler: recordingCommandHandler{calls: make(chan commandCall, 1)},
	}
	first, err := Open(path, firstHandler, reader)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer first.listener.Close()
	defer first.lock.Close()
	if firstHandler.recoveries != 1 {
		t.Fatalf("first recovery count = %d", firstHandler.recoveries)
	}

	secondHandler := &recoveringCommandHandler{
		recordingCommandHandler: recordingCommandHandler{calls: make(chan commandCall, 1)},
	}
	if _, err := Open(path, secondHandler, reader); !domain.IsErrorCode(err, domain.ErrorCodeConflict) {
		t.Fatalf("second Open() error = %v", err)
	}
	if secondHandler.recoveries != 0 {
		t.Fatalf("second recovery count = %d", secondHandler.recoveries)
	}
}

func TestCommandRequestRequiresIdempotencyKey(t *testing.T) {
	request := CommandRequest{
		ID:             "command-1",
		Kind:           "workflow.patch",
		Payload:        json.RawMessage(`{}`),
		IdempotencyKey: "",
	}
	if err := request.Validate(); !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("Validate() error = %v", err)
	}
}

func TestCommandEndpointRejectsCallerPrincipal(t *testing.T) {
	handler := &recordingCommandHandler{calls: make(chan commandCall, 1)}
	reader := &recordingEventReader{calls: make(chan eventCall, 1)}
	client, _ := startTestServer(t, handler, reader)

	response := postCommand(t, client, `{
		"id":"command-1",
		"idempotencyKey":"request-1",
		"kind":"workflow.patch",
		"principal":"owner",
		"payload":{}
	}`)
	defer response.Body.Close()
	if response.StatusCode != http.StatusBadRequest {
		body, _ := io.ReadAll(response.Body)
		t.Fatalf("status = %d, body = %s", response.StatusCode, body)
	}
	select {
	case call := <-handler.calls:
		t.Fatalf("handler received %#v", call)
	default:
	}
}

func TestEventEndpointReturnsCursorBasedNDJSON(t *testing.T) {
	handler := &recordingCommandHandler{calls: make(chan commandCall, 1)}
	reader := &recordingEventReader{
		calls: make(chan eventCall, 1),
		events: []domain.EventEnvelope{
			testEvent(5, "node.started"),
			testEvent(6, "node.completed"),
		},
	}
	client, _ := startTestServer(t, handler, reader)

	request, err := http.NewRequest(http.MethodGet, "http://colchis/v1/events?after=4&limit=2", nil)
	if err != nil {
		t.Fatalf("NewRequest() returned %v", err)
	}
	response, err := client.Do(request)
	if err != nil {
		t.Fatalf("Do() returned %v", err)
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(response.Body)
		t.Fatalf("status = %d, body = %s", response.StatusCode, body)
	}
	if got := response.Header.Get("Content-Type"); got != "application/x-ndjson" {
		t.Fatalf("content type = %q", got)
	}
	if got := response.Header.Get("X-Colchis-Next-Cursor"); got != "6" {
		t.Fatalf("next cursor = %q", got)
	}
	call := <-reader.calls
	if call.cursor != 4 || call.limit != 2 {
		t.Fatalf("event query = %#v", call)
	}

	scanner := bufio.NewScanner(response.Body)
	var cursors []domain.EventCursor
	for scanner.Scan() {
		var event domain.EventEnvelope
		if err := json.Unmarshal(scanner.Bytes(), &event); err != nil {
			t.Fatalf("Unmarshal() returned %v", err)
		}
		if err := event.Validate(); err != nil {
			t.Fatalf("Validate() returned %v", err)
		}
		cursors = append(cursors, event.Cursor)
	}
	if err := scanner.Err(); err != nil {
		t.Fatalf("Scan() returned %v", err)
	}
	if len(cursors) != 2 || cursors[0] != 5 || cursors[1] != 6 {
		t.Fatalf("cursors = %v", cursors)
	}
}

func TestEventEndpointRejectsInvalidOrder(t *testing.T) {
	handler := &recordingCommandHandler{calls: make(chan commandCall, 1)}
	reader := &recordingEventReader{
		calls:  make(chan eventCall, 1),
		events: []domain.EventEnvelope{testEvent(4, "node.started")},
	}
	client, _ := startTestServer(t, handler, reader)

	request, err := http.NewRequest(http.MethodGet, "http://colchis/v1/events?after=4", nil)
	if err != nil {
		t.Fatalf("NewRequest() returned %v", err)
	}
	response, err := client.Do(request)
	if err != nil {
		t.Fatalf("Do() returned %v", err)
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusInternalServerError {
		body, _ := io.ReadAll(response.Body)
		t.Fatalf("status = %d, body = %s", response.StatusCode, body)
	}
}

func TestOpenRejectsAccessibleDirectoryAndNonSocketPath(t *testing.T) {
	handler := &recordingCommandHandler{calls: make(chan commandCall, 1)}
	reader := &recordingEventReader{calls: make(chan eventCall, 1)}

	accessible := filepath.Join(t.TempDir(), "accessible")
	if err := os.Mkdir(accessible, 0o700); err != nil {
		t.Fatalf("Mkdir() returned %v", err)
	}
	if err := os.Chmod(accessible, 0o755); err != nil {
		t.Fatalf("Chmod() returned %v", err)
	}
	server, err := Open(filepath.Join(accessible, "broker.sock"), handler, reader)
	if server != nil || !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("Open() = %#v, %v", server, err)
	}

	unsafeAncestor := filepath.Join(t.TempDir(), "unsafe")
	if err := os.Mkdir(unsafeAncestor, 0o777); err != nil {
		t.Fatalf("Mkdir() returned %v", err)
	}
	if err := os.Chmod(unsafeAncestor, 0o777); err != nil {
		t.Fatalf("Chmod() returned %v", err)
	}
	unsafePrivate := filepath.Join(unsafeAncestor, "private")
	if err := os.Mkdir(unsafePrivate, 0o700); err != nil {
		t.Fatalf("Mkdir() returned %v", err)
	}
	server, err = Open(filepath.Join(unsafePrivate, "broker.sock"), handler, reader)
	if server != nil || !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("unsafe ancestor Open() = %#v, %v", server, err)
	}

	private, err := os.MkdirTemp(shortSocketTempRoot(), "colchis-private-")
	if err != nil {
		t.Fatalf("MkdirTemp() returned %v", err)
	}
	t.Cleanup(func() { os.RemoveAll(private) })
	path := filepath.Join(private, "broker.sock")
	if err := os.WriteFile(path, []byte("keep"), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	server, err = Open(path, handler, reader)
	if server != nil || !domain.IsErrorCode(err, domain.ErrorCodeConflict) {
		t.Fatalf("Open() = %#v, %v", server, err)
	}
	body, readErr := os.ReadFile(path)
	if readErr != nil || string(body) != "keep" {
		t.Fatalf("existing path changed: body = %q, error = %v", body, readErr)
	}
}

func TestCloseRetainsOwnershipUntilTimedOutHandlerFinishes(t *testing.T) {
	directory, err := os.MkdirTemp(shortSocketTempRoot(), "colchis-close-")
	if err != nil {
		t.Fatalf("MkdirTemp() returned %v", err)
	}
	t.Cleanup(func() { os.RemoveAll(directory) })
	path := filepath.Join(directory, "broker.sock")
	handler := &blockingCommandHandler{started: make(chan struct{}), release: make(chan struct{})}
	reader := &recordingEventReader{calls: make(chan eventCall, 1)}
	server, err := Open(path, handler, reader)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	serveErrors := make(chan error, 1)
	go func() { serveErrors <- server.Serve() }()
	transport := &http.Transport{
		DialContext: func(ctx context.Context, _, _ string) (net.Conn, error) {
			return (&net.Dialer{}).DialContext(ctx, "unix", path)
		},
	}
	t.Cleanup(transport.CloseIdleConnections)
	requestErrors := make(chan error, 1)
	go func() {
		request, requestErr := http.NewRequest(
			http.MethodPost,
			"http://colchis/v1/commands",
			bytes.NewBufferString(`{"id":"command-close","idempotencyKey":"request-close","kind":"event.append","payload":{}}`),
		)
		if requestErr == nil {
			request.Header.Set("Content-Type", "application/json")
			response, doErr := transport.RoundTrip(request)
			if response != nil {
				response.Body.Close()
			}
			requestErr = doErr
		}
		requestErrors <- requestErr
	}()
	<-handler.started
	ctx, cancel := context.WithTimeout(context.Background(), time.Millisecond)
	defer cancel()
	if err := server.Close(ctx); !errors.Is(err, context.DeadlineExceeded) {
		close(handler.release)
		t.Fatalf("Close() error = %v", err)
	}
	if ownership, err := AcquireOwnership(path); ownership != nil || !domain.IsErrorCode(
		err, domain.ErrorCodeConflict,
	) {
		close(handler.release)
		t.Fatalf("AcquireOwnership() = %#v, %v", ownership, err)
	}
	close(handler.release)
	<-requestErrors
	if err := <-serveErrors; err != nil {
		t.Fatalf("Serve() returned %v", err)
	}
	deadline := time.Now().Add(5 * time.Second)
	for {
		ownership, err := AcquireOwnership(path)
		if err == nil {
			if err := ownership.Close(); err != nil {
				t.Fatalf("ownership Close() returned %v", err)
			}
			break
		}
		if time.Now().After(deadline) {
			t.Fatalf("ownership remained held: %v", err)
		}
		time.Sleep(time.Millisecond)
	}
}

func startTestServer(
	t *testing.T,
	handler CommandHandler,
	reader EventReader,
) (*http.Client, string) {
	t.Helper()
	private, err := os.MkdirTemp(shortSocketTempRoot(), "colchis-")
	if err != nil {
		t.Fatalf("MkdirTemp() returned %v", err)
	}
	t.Cleanup(func() {
		os.Remove(filepath.Join(private, "broker.sock.lock"))
		if err := os.Remove(private); err != nil {
			t.Errorf("Remove() returned %v", err)
		}
	})
	socketPath := filepath.Join(private, "broker.sock")
	server, err := Open(socketPath, handler, reader)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	errors := make(chan error, 1)
	go func() {
		errors <- server.Serve()
	}()

	transport := &http.Transport{
		DialContext: func(ctx context.Context, _, _ string) (net.Conn, error) {
			dialer := &net.Dialer{}
			return dialer.DialContext(ctx, "unix", socketPath)
		},
	}
	client := &http.Client{Transport: transport, Timeout: 2 * time.Second}
	t.Cleanup(func() {
		transport.CloseIdleConnections()
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		if err := server.Close(ctx); err != nil {
			t.Errorf("Close() returned %v", err)
		}
		if err := <-errors; err != nil {
			t.Errorf("Serve() returned %v", err)
		}
	})
	return client, socketPath
}

func postCommand(t *testing.T, client *http.Client, body string) *http.Response {
	t.Helper()
	request, err := http.NewRequest(http.MethodPost, "http://colchis/v1/commands", bytes.NewBufferString(body))
	if err != nil {
		t.Fatalf("NewRequest() returned %v", err)
	}
	request.Header.Set("Content-Type", "application/json")
	response, err := client.Do(request)
	if err != nil {
		t.Fatalf("Do() returned %v", err)
	}
	return response
}

func testEvent(cursor domain.EventCursor, eventType string) domain.EventEnvelope {
	return domain.EventEnvelope{
		SchemaVersion: domain.CurrentEventSchemaVersion,
		Cursor:        cursor,
		OccurredAt:    time.Unix(int64(cursor), 0).UTC(),
		Aggregate:     domain.ResourceReference{Kind: "node-run", ID: "node-1"},
		Type:          eventType,
		Payload:       json.RawMessage(`{}`),
	}
}

func testMetadata() domain.RecordMetadata {
	createdAt := time.Unix(10, 0).UTC()
	return domain.RecordMetadata{
		SchemaVersion:   domain.CurrentRecordSchemaVersion,
		ResourceVersion: 1,
		CreatedAt:       createdAt,
		UpdatedAt:       createdAt,
	}
}
