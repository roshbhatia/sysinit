package plugin

import (
	"bufio"
	"context"
	"encoding/json"
	"io"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

func TestServerNegotiatesInvokesAndEmitsEvents(t *testing.T) {
	t.Parallel()

	manifest := AdapterManifest{
		ID: "runtime", Port: domain.AdapterPortAgentRuntime,
		Capabilities: []string{"fixture"}, HandleVersions: []uint32{1},
		Operations: map[string]SchemaContract{"agent-runtime.start": fixtureSchemaContract()},
	}
	server, err := NewServer(ServerConfig{
		PluginID: "fixture", Adapters: []AdapterManifest{manifest},
		Invoke: func(
			_ context.Context,
			envelope OperationEnvelope,
			emit EventEmitter,
		) (OperationResult, error) {
			if err := emit("output", json.RawMessage(`{"text":"working"}`)); err != nil {
				return OperationResult{}, err
			}
			return OperationResult{
				ID: envelope.ID, State: domain.OperationStateSucceeded,
				Output: json.RawMessage(`{"value":"response"}`),
			}, nil
		},
	})
	if err != nil {
		t.Fatalf("NewServer() returned %v", err)
	}
	inputReader, inputWriter := io.Pipe()
	outputReader, outputWriter := io.Pipe()
	done := make(chan error, 1)
	go func() {
		done <- server.Serve(context.Background(), inputReader, outputWriter)
		_ = outputWriter.Close()
	}()
	encoder := json.NewEncoder(inputWriter)
	scanner := bufio.NewScanner(outputReader)

	initialization, err := json.Marshal(InitializeParams{
		SupportedProtocolVersions: []uint32{ProtocolVersion},
		Limits: WireLimits{
			MaxMessageBytes: 1 << 20, MaxEventsPerSecond: 10, MaxOperationSeconds: 10,
		},
	})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	writeServerRequest(t, encoder, "initialize", MethodInitialize, initialization)
	response := readServerResponse(t, scanner)
	if response.Error != nil {
		t.Fatalf("initialization response = %#v", response)
	}

	envelope := OperationEnvelope{
		ID: "operation-1", AdapterID: manifest.ID, Port: manifest.Port,
		Operation: "agent-runtime.start", Input: json.RawMessage(`{"value":"request"}`),
		Deadline: time.Now().Add(time.Minute),
	}
	payload, err := json.Marshal(envelope)
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	writeServerRequest(t, encoder, "invoke", MethodInvoke, payload)
	if !scanner.Scan() {
		t.Fatalf("event scan failed: %v", scanner.Err())
	}
	var notification Notification
	if err := json.Unmarshal(scanner.Bytes(), &notification); err != nil {
		t.Fatalf("event decode returned %v", err)
	}
	if notification.Method != MethodEvent {
		t.Fatalf("notification = %#v", notification)
	}
	response = readServerResponse(t, scanner)
	if response.Error != nil {
		t.Fatalf("invocation response = %#v", response)
	}
	var result OperationResult
	if err := json.Unmarshal(response.Result, &result); err != nil {
		t.Fatalf("result decode returned %v", err)
	}
	if result.ID != envelope.ID || result.State != domain.OperationStateSucceeded {
		t.Fatalf("operation result = %#v", result)
	}

	_ = inputWriter.Close()
	if err := <-done; err != nil {
		t.Fatalf("Serve() returned %v", err)
	}
}

func TestServerCancelsActiveOperation(t *testing.T) {
	t.Parallel()

	manifest := AdapterManifest{
		ID: "runtime", Port: domain.AdapterPortAgentRuntime,
		Capabilities: []string{"fixture"}, HandleVersions: []uint32{1},
		Operations: map[string]SchemaContract{"agent-runtime.start": fixtureSchemaContract()},
	}
	started := make(chan struct{})
	server, err := NewServer(ServerConfig{
		PluginID: "fixture", Adapters: []AdapterManifest{manifest},
		Invoke: func(
			ctx context.Context,
			_ OperationEnvelope,
			_ EventEmitter,
		) (OperationResult, error) {
			close(started)
			<-ctx.Done()
			return OperationResult{}, ctx.Err()
		},
	})
	if err != nil {
		t.Fatalf("NewServer() returned %v", err)
	}
	inputReader, inputWriter := io.Pipe()
	outputReader, outputWriter := io.Pipe()
	done := make(chan error, 1)
	go func() {
		done <- server.Serve(context.Background(), inputReader, outputWriter)
		_ = outputWriter.Close()
	}()
	encoder := json.NewEncoder(inputWriter)
	scanner := bufio.NewScanner(outputReader)
	initializeFixtureServer(t, encoder, scanner)

	envelope := OperationEnvelope{
		ID: "operation-cancel", AdapterID: manifest.ID, Port: manifest.Port,
		Operation: "agent-runtime.start", Input: json.RawMessage(`{"value":"request"}`),
		Deadline: time.Now().Add(time.Minute),
	}
	payload, err := json.Marshal(envelope)
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	writeServerRequest(t, encoder, "invoke", MethodInvoke, payload)
	<-started
	cancelPayload, err := json.Marshal(CancelParams{
		OperationID: envelope.ID, Deadline: time.Now().Add(time.Second),
	})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	writeServerRequest(t, encoder, "cancel", MethodCancel, cancelPayload)

	responses := make(map[string]Response, 2)
	for len(responses) < 2 {
		response := readServerResponse(t, scanner)
		responses[response.ID] = response
	}
	if responses["cancel"].Error != nil || responses["invoke"].Error == nil {
		t.Fatalf("responses = %#v", responses)
	}
	_ = inputWriter.Close()
	if err := <-done; err != nil {
		t.Fatalf("Serve() returned %v", err)
	}
}

func TestServerRefusesCancellationBeforeHandlerExit(t *testing.T) {
	t.Parallel()

	manifest := AdapterManifest{
		ID: "runtime", Port: domain.AdapterPortAgentRuntime,
		Capabilities: []string{"fixture"}, HandleVersions: []uint32{1},
		Operations: map[string]SchemaContract{"agent-runtime.start": fixtureSchemaContract()},
	}
	started := make(chan struct{})
	release := make(chan struct{})
	server, err := NewServer(ServerConfig{
		PluginID: "fixture", Adapters: []AdapterManifest{manifest},
		Invoke: func(
			_ context.Context,
			_ OperationEnvelope,
			_ EventEmitter,
		) (OperationResult, error) {
			close(started)
			<-release
			return OperationResult{}, context.Canceled
		},
	})
	if err != nil {
		t.Fatalf("NewServer() returned %v", err)
	}
	inputReader, inputWriter := io.Pipe()
	outputReader, outputWriter := io.Pipe()
	done := make(chan error, 1)
	go func() {
		done <- server.Serve(context.Background(), inputReader, outputWriter)
		_ = outputWriter.Close()
	}()
	encoder := json.NewEncoder(inputWriter)
	scanner := bufio.NewScanner(outputReader)
	initializeFixtureServer(t, encoder, scanner)

	envelope := OperationEnvelope{
		ID: "operation-ignore-context", AdapterID: manifest.ID, Port: manifest.Port,
		Operation: "agent-runtime.start", Input: json.RawMessage(`{"value":"request"}`),
		Deadline: time.Now().Add(time.Minute),
	}
	payload, err := json.Marshal(envelope)
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	writeServerRequest(t, encoder, "invoke", MethodInvoke, payload)
	<-started
	cancelPayload, err := json.Marshal(CancelParams{
		OperationID: envelope.ID, Deadline: time.Now().Add(50 * time.Millisecond),
	})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	writeServerRequest(t, encoder, "cancel", MethodCancel, cancelPayload)
	response := readServerResponse(t, scanner)
	if response.ID != "cancel" || response.Error == nil {
		t.Fatalf("cancellation response = %#v", response)
	}
	close(release)
	_ = readServerResponse(t, scanner)
	_ = inputWriter.Close()
	if err := <-done; err != nil {
		t.Fatalf("Serve() returned %v", err)
	}
}

func initializeFixtureServer(t *testing.T, encoder *json.Encoder, scanner *bufio.Scanner) {
	t.Helper()
	payload, err := json.Marshal(InitializeParams{
		SupportedProtocolVersions: []uint32{ProtocolVersion},
		Limits: WireLimits{
			MaxMessageBytes: 1 << 20, MaxEventsPerSecond: 10, MaxOperationSeconds: 10,
		},
	})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	writeServerRequest(t, encoder, "initialize", MethodInitialize, payload)
	if response := readServerResponse(t, scanner); response.Error != nil {
		t.Fatalf("initialization response = %#v", response)
	}
}

func writeServerRequest(
	t *testing.T,
	encoder *json.Encoder,
	id string,
	method string,
	payload json.RawMessage,
) {
	t.Helper()
	request, err := NewRequest(id, method, payload)
	if err != nil {
		t.Fatalf("NewRequest() returned %v", err)
	}
	if err := encoder.Encode(request); err != nil {
		t.Fatalf("Encode() returned %v", err)
	}
}

func readServerResponse(t *testing.T, scanner *bufio.Scanner) Response {
	t.Helper()
	if !scanner.Scan() {
		t.Fatalf("response scan failed: %v", scanner.Err())
	}
	var response Response
	if err := json.Unmarshal(scanner.Bytes(), &response); err != nil {
		t.Fatalf("response decode returned %v", err)
	}
	return response
}
