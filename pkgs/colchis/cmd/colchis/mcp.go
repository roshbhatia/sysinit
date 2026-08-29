package main

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"sync"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/api/socket"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/config"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/instance"
)

const (
	mcpJSONRPCVersion    = "2.0"
	mcpCurrentVersion    = "2026-07-28"
	mcpCompatibleVersion = "2025-11-25"
)

type mcpRequest struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      json.RawMessage `json:"id,omitempty"`
	Method  string          `json:"method"`
	Params  json.RawMessage `json:"params,omitempty"`
}

type mcpResponse struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      json.RawMessage `json:"id"`
	Result  json.RawMessage `json:"result,omitempty"`
	Error   *mcpError       `json:"error,omitempty"`
}

type mcpNotification struct {
	JSONRPC string `json:"jsonrpc"`
	Method  string `json:"method"`
}

type mcpError struct {
	Code    int             `json:"code"`
	Message string          `json:"message"`
	Data    json.RawMessage `json:"data,omitempty"`
}

type mcpTool struct {
	Name         string          `json:"name"`
	Title        string          `json:"title"`
	Description  string          `json:"description"`
	InputSchema  json.RawMessage `json:"inputSchema"`
	OutputSchema json.RawMessage `json:"outputSchema"`
	Annotations  json.RawMessage `json:"annotations"`
	nativeKind   string
}

type mcpCallParams struct {
	Name      string          `json:"name"`
	Arguments json.RawMessage `json:"arguments"`
	Meta      json.RawMessage `json:"_meta,omitempty"`
}

type mcpToolArguments struct {
	Payload         json.RawMessage         `json:"payload"`
	CommandID       domain.CommandID        `json:"commandId,omitempty"`
	IdempotencyKey  string                  `json:"idempotencyKey,omitempty"`
	ExpectedVersion *domain.ResourceVersion `json:"expectedVersion,omitempty"`
}

type mcpTextContent struct {
	Type string `json:"type"`
	Text string `json:"text"`
}

type mcpCallResult struct {
	Content           []mcpTextContent `json:"content"`
	StructuredContent json.RawMessage  `json:"structuredContent,omitempty"`
	IsError           bool             `json:"isError,omitempty"`
}

var mcpInputSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object",
  "properties":{
    "payload":{"type":"object"},
    "commandId":{"type":"string","minLength":1,"maxLength":128},
    "idempotencyKey":{"type":"string","minLength":1,"maxLength":128},
    "expectedVersion":{"type":"integer","minimum":1}
  },
  "required":["payload"],"additionalProperties":false
}`)

var mcpOutputSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object",
  "required":["metadata","id","idempotencyKey","principal","kind","state","payload","result"],
  "properties":{
    "metadata":{"type":"object"},"id":{"type":"string"},"idempotencyKey":{"type":"string"},
    "principal":{"type":"string"},"kind":{"type":"string"},"state":{"const":"succeeded"},
    "payload":{},"result":{}
  }
}`)

var mcpReadOnlyAnnotations = json.RawMessage(`{
  "readOnlyHint":true,"destructiveHint":false,"idempotentHint":true,"openWorldHint":false
}`)

var mcpMutatingAnnotations = json.RawMessage(`{
  "readOnlyHint":false,"destructiveHint":true,"idempotentHint":true,"openWorldHint":false
}`)

var mcpToolDefinitions = []mcpTool{
	newMCPTool("workflow_create", "Create a dedicated workflow definition, including planning and spec work", "workflow.create", false),
	newMCPTool("workflow_run", "Create a dedicated workflow run", "workflow.run", false),
	newMCPTool("workflow_list", "List workflow runs", "workflow.list", true),
	newMCPTool("workflow_restart_points", "List restart points for a workflow run", "workflow.restart-points", true),
	newMCPTool("workflow_forks", "List replay lineage for a workflow run", "workflow.forks", true),
	newMCPTool("workflow_schedule", "Reserve ready workflow nodes", "workflow.schedule", false),
	newMCPTool("workflow_inspect", "Inspect a workflow run", "workflow.inspect", true),
	newMCPTool("workflow_export", "Export a workflow definition", "workflow.export", true),
	newMCPTool("workflow_restart_point", "Create a workflow restart point", "workflow.restart-point", false),
	newMCPTool("graph_patch", "Patch a workflow graph", "graph.patch", false),
	newMCPTool("workflow_replay", "Replay from a restart point", "workflow.replay", false),
	newMCPTool("worker_start", "Start a workflow worker", "agent.start", false),
	newMCPTool("worker_list", "List workflow workers", "agent.list", true),
	newMCPTool("worker_attach", "Attach to a workflow worker", "agent.attach", false),
	newMCPTool("worker_detach", "Detach from a workflow worker", "agent.detach", false),
	newMCPTool("worker_intervene", "Send a workflow worker intervention", "agent.intervene", false),
	newMCPTool("worker_policy", "Change a workflow worker job policy", "agent.policy", false),
	newMCPTool("worker_cancel", "Cancel a workflow worker", "agent.cancel", false),
	newMCPTool("worker_history", "Read workflow worker history", "agent.history", true),
	newMCPTool("workspace_snapshot", "Snapshot a workspace", "workspace.snapshot", false),
	newMCPTool("artifact_resolve", "Resolve an artifact", "artifact.resolve", false),
	newMCPTool("verification_submit", "Submit a typed task result", "verification.submit", false),
	newMCPTool("verification_task_record", "Bind a result to a snapshot", "verification.task-record", false),
	newMCPTool("verification_record", "Record verification evidence", "verification.record", false),
	newMCPTool("verification_admit", "Decide result admission", "verification.admit", false),
	newMCPTool("effect_reconcile", "Reconcile an indeterminate effect", "effect.reconcile", false),
	newMCPTool("provenance_commit", "Record a commit observation", "provenance.commit", false),
	newMCPTool("provenance_relation", "Record a provenance relation", "provenance.relation", false),
	newMCPTool("provenance_inspect", "Inspect provenance records", "provenance.inspect", true),
	newMCPTool("broker_inspect", "Inspect broker state", "broker.inspect", true),
}

func newMCPTool(name string, title string, nativeKind string, readOnly bool) mcpTool {
	annotations := mcpMutatingAnnotations
	if readOnly {
		annotations = mcpReadOnlyAnnotations
	}
	return mcpTool{
		Name: name, Title: title,
		Description: "Execute the native " + nativeKind + " broker command.",
		InputSchema: mcpInputSchema, OutputSchema: mcpOutputSchema,
		Annotations: annotations, nativeKind: nativeKind,
	}
}

func runMCP(args []string, stdin io.Reader, stdout io.Writer, stderr io.Writer) int {
	flags := flag.NewFlagSet("mcp", flag.ContinueOnError)
	flags.SetOutput(stderr)
	stateDirectory := flags.String("state-dir", "", "state directory")
	if err := flags.Parse(args); err != nil {
		return 2
	}
	if flags.NArg() != 0 {
		fmt.Fprintln(stderr, "mcp accepts no positional arguments")
		return 2
	}
	scanner := bufio.NewScanner(stdin)
	scanner.Buffer(make([]byte, 4096), 1<<20)
	encoder := json.NewEncoder(stdout)
	encoder.SetEscapeHTML(false)
	var outputMu sync.Mutex
	encode := func(value interface{}) error {
		outputMu.Lock()
		defer outputMu.Unlock()
		return encoder.Encode(value)
	}
	watchContext, stopWatch := context.WithCancel(context.Background())
	var watchGroup sync.WaitGroup
	defer func() {
		stopWatch()
		watchGroup.Wait()
	}()
	watching := false
	for scanner.Scan() {
		var request mcpRequest
		if err := json.Unmarshal(scanner.Bytes(), &request); err != nil {
			if err := encode(mcpResponse{
				JSONRPC: mcpJSONRPCVersion, ID: json.RawMessage(`null`),
				Error: &mcpError{Code: -32700, Message: "request is not valid JSON"},
			}); err != nil {
				fmt.Fprintf(stderr, "write MCP response: %v\n", err)
				return 1
			}
			continue
		}
		client, active, err := resolveMCPClient(*stateDirectory)
		if err != nil {
			response := mcpToolError(request, err)
			if encodeErr := encode(response); encodeErr != nil {
				fmt.Fprintf(stderr, "write MCP response: %v\n", encodeErr)
				return 1
			}
			continue
		}
		response, send := handleMCPRequest(context.Background(), client, active, request)
		if client != nil {
			client.Close()
		}
		if send {
			if err := encode(response); err != nil {
				fmt.Fprintf(stderr, "write MCP response: %v\n", err)
				return 1
			}
		}
		if request.Method == "initialize" && !watching {
			watching = true
			watchGroup.Add(1)
			go func(initial bool) {
				defer watchGroup.Done()
				watchMCPToolList(watchContext, *stateDirectory, initial, encode)
			}(active)
		}
	}
	if err := scanner.Err(); err != nil {
		fmt.Fprintf(stderr, "read MCP request: %v\n", err)
		return 1
	}
	return 0
}

func watchMCPToolList(
	ctx context.Context,
	stateDirectory string,
	active bool,
	encode func(interface{}) error,
) {
	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			client, current, err := resolveMCPClient(stateDirectory)
			if client != nil {
				client.Close()
			}
			if err != nil || current == active {
				continue
			}
			active = current
			if err := encode(mcpNotification{
				JSONRPC: mcpJSONRPCVersion, Method: "notifications/tools/list_changed",
			}); err != nil {
				return
			}
		}
	}
}

func resolveMCPClient(stateDirectory string) (*socket.Client, bool, error) {
	var record instance.Record
	if stateDirectory != "" {
		paths, err := config.ResolvePaths(stateDirectory)
		if err != nil {
			return nil, false, fmt.Errorf("resolve state paths: %w", err)
		}
		record = instance.Record{StateDirectory: paths.StateDirectory, Socket: paths.Socket}
	} else {
		directory, err := os.Getwd()
		if err != nil {
			return nil, false, fmt.Errorf("resolve current directory: %w", err)
		}
		var found bool
		record, found, err = instance.Match(directory)
		if err != nil {
			return nil, false, fmt.Errorf("resolve Orca instance: %w", err)
		}
		if !found {
			return nil, false, nil
		}
	}
	client, err := socket.NewClient(record.Socket)
	if err != nil {
		return nil, false, fmt.Errorf("create broker client: %w", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 500*time.Millisecond)
	defer cancel()
	if _, err := client.Events(ctx, 0, 1); err != nil {
		client.Close()
		return nil, false, nil
	}
	return client, true, nil
}

func handleMCPRequest(
	ctx context.Context,
	client *socket.Client,
	active bool,
	request mcpRequest,
) (mcpResponse, bool) {
	if request.JSONRPC != mcpJSONRPCVersion || request.Method == "" {
		return mcpProtocolError(request.ID, -32600, "request is invalid"), true
	}
	if len(request.ID) == 0 {
		return mcpResponse{}, false
	}
	switch request.Method {
	case "initialize":
		protocolVersion := mcpCompatibleVersion
		var params struct {
			ProtocolVersion string `json:"protocolVersion"`
		}
		if err := json.Unmarshal(request.Params, &params); err == nil &&
			params.ProtocolVersion == mcpCompatibleVersion {
			protocolVersion = params.ProtocolVersion
		}
		result := json.RawMessage(`{
  "protocolVersion":"` + protocolVersion + `",
  "capabilities":{"tools":{"listChanged":true}},
  "serverInfo":{"name":"orca","version":"0.1.0"}
}`)
		return mcpSuccess(request.ID, result), true
	case "server/discover":
		result := json.RawMessage(`{
  "supportedVersions":["` + mcpCurrentVersion + `"],
  "capabilities":{"tools":{"listChanged":true}},
  "instructions":"Use Orca tools when a local broker is active.",
  "ttlMs":300000,"cacheScope":"private"
}`)
		return mcpRequestSuccess(request, result), true
	case "ping":
		return mcpRequestSuccess(request, json.RawMessage(`{}`)), true
	case "tools/list":
		if !active {
			return mcpRequestSuccess(request, json.RawMessage(`{"tools":[]}`)), true
		}
		tools := make([]mcpTool, len(mcpToolDefinitions))
		copy(tools, mcpToolDefinitions)
		result, err := json.Marshal(struct {
			Tools []mcpTool `json:"tools"`
		}{Tools: tools})
		if err != nil {
			return mcpProtocolError(request.ID, -32603, err.Error()), true
		}
		return mcpRequestSuccess(request, result), true
	case "tools/call":
		if !active || client == nil {
			return mcpToolError(request, errors.New("orca is inactive for this directory")), true
		}
		return callMCPTool(ctx, client, request), true
	default:
		return mcpProtocolError(request.ID, -32601, "method is not supported"), true
	}
}

func callMCPTool(ctx context.Context, client *socket.Client, request mcpRequest) mcpResponse {
	var params mcpCallParams
	if err := decodeMCPStrict(request.Params, &params); err != nil {
		return mcpProtocolError(request.ID, -32602, "tool parameters are invalid")
	}
	var definition *mcpTool
	for index := range mcpToolDefinitions {
		if mcpToolDefinitions[index].Name == params.Name {
			definition = &mcpToolDefinitions[index]
			break
		}
	}
	if definition == nil {
		return mcpProtocolError(request.ID, -32602, "tool is unknown")
	}
	var arguments mcpToolArguments
	if err := decodeMCPStrict(params.Arguments, &arguments); err != nil || !mcpJSONObject(arguments.Payload) {
		return mcpProtocolError(request.ID, -32602, "tool arguments are invalid")
	}
	if arguments.CommandID == "" {
		value, err := localCommandID()
		if err != nil {
			return mcpProtocolError(request.ID, -32603, err.Error())
		}
		arguments.CommandID = domain.CommandID(value)
	}
	if arguments.IdempotencyKey == "" {
		arguments.IdempotencyKey = "mcp-" + string(arguments.CommandID)
	}
	record, err := client.Command(ctx, domain.CommandRequest{
		ID: arguments.CommandID, IdempotencyKey: arguments.IdempotencyKey,
		Kind: definition.nativeKind, ExpectedVersion: arguments.ExpectedVersion,
		Payload: arguments.Payload,
	})
	if err != nil {
		return mcpToolError(request, err)
	}
	structured, err := json.Marshal(record)
	if err != nil {
		return mcpProtocolError(request.ID, -32603, err.Error())
	}
	result, err := json.Marshal(mcpCallResult{
		Content:           []mcpTextContent{{Type: "text", Text: string(structured)}},
		StructuredContent: structured,
	})
	if err != nil {
		return mcpProtocolError(request.ID, -32603, err.Error())
	}
	return mcpRequestSuccess(request, result)
}

func decodeMCPStrict[T mcpCallParams | mcpToolArguments](payload json.RawMessage, target *T) error {
	decoder := json.NewDecoder(bytes.NewReader(payload))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return err
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return fmt.Errorf("trailing JSON data")
	}
	return nil
}

func mcpJSONObject(payload json.RawMessage) bool {
	var object map[string]json.RawMessage
	return json.Unmarshal(payload, &object) == nil && object != nil
}

func mcpToolError(request mcpRequest, err error) mcpResponse {
	domainError := &domain.Error{
		Code: domain.ErrorCodeInternal, Op: "MCP tool", Message: err.Error(), Err: err,
	}
	var typed *domain.Error
	if errors.As(err, &typed) {
		domainError = typed
	}
	structured, marshalErr := json.Marshal(struct {
		Error *domain.Error `json:"error"`
	}{Error: domainError})
	if marshalErr != nil {
		return mcpProtocolError(request.ID, -32603, marshalErr.Error())
	}
	result, marshalErr := json.Marshal(mcpCallResult{
		Content:           []mcpTextContent{{Type: "text", Text: string(structured)}},
		StructuredContent: structured, IsError: true,
	})
	if marshalErr != nil {
		return mcpProtocolError(request.ID, -32603, marshalErr.Error())
	}
	return mcpRequestSuccess(request, result)
}

func mcpRequestSuccess(request mcpRequest, result json.RawMessage) mcpResponse {
	if request.Method != "server/discover" && mcpRequestVersion(request.Params) != mcpCurrentVersion {
		return mcpSuccess(request.ID, result)
	}
	var object map[string]json.RawMessage
	if err := json.Unmarshal(result, &object); err != nil || object == nil {
		return mcpProtocolError(request.ID, -32603, "modern MCP result must be an object")
	}
	object["resultType"] = json.RawMessage(`"complete"`)
	object["_meta"] = json.RawMessage(`{
  "io.modelcontextprotocol/serverInfo":{"name":"orca","version":"0.1.0"}
}`)
	decorated, err := json.Marshal(object)
	if err != nil {
		return mcpProtocolError(request.ID, -32603, err.Error())
	}
	return mcpSuccess(request.ID, decorated)
}

func mcpRequestVersion(params json.RawMessage) string {
	var envelope struct {
		Meta map[string]json.RawMessage `json:"_meta"`
	}
	if json.Unmarshal(params, &envelope) != nil {
		return ""
	}
	var version string
	if json.Unmarshal(envelope.Meta["io.modelcontextprotocol/protocolVersion"], &version) != nil {
		return ""
	}
	return version
}

func mcpSuccess(id json.RawMessage, result json.RawMessage) mcpResponse {
	return mcpResponse{JSONRPC: mcpJSONRPCVersion, ID: id, Result: result}
}

func mcpProtocolError(id json.RawMessage, code int, message string) mcpResponse {
	if len(id) == 0 {
		id = json.RawMessage(`null`)
	}
	return mcpResponse{
		JSONRPC: mcpJSONRPCVersion, ID: id,
		Error: &mcpError{Code: code, Message: message},
	}
}
