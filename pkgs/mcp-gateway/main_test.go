package main

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

type rpcMessage struct {
	Version string          `json:"jsonrpc"`
	ID      json.RawMessage `json:"id,omitempty"`
	Method  string          `json:"method,omitempty"`
	Result  json.RawMessage `json:"result,omitempty"`
	Error   json.RawMessage `json:"error,omitempty"`
}

func TestBackend(t *testing.T) {
	if os.Getenv("SYSINIT_MCP_FIXTURE") != "1" {
		return
	}
	decoder := json.NewDecoder(os.Stdin)
	encoder := json.NewEncoder(os.Stdout)
	for {
		var request rpcMessage
		if err := decoder.Decode(&request); err != nil {
			os.Exit(0)
		}
		if len(request.ID) == 0 {
			continue
		}
		result := `{}`
		switch request.Method {
		case "initialize":
			result = `{"protocolVersion":"2025-03-26","capabilities":{"tools":{},"resources":{},"prompts":{}},"serverInfo":{"name":"fixture","version":"1"}}`
		case "tools/list":
			result = `{"tools":[{"name":"context","description":"Return fixture context","inputSchema":{"type":"object","properties":{}}}]}`
		case "tools/call":
			cwd, _ := os.Getwd()
			text, _ := json.Marshal(cwd + "|" + os.Getenv("ORC_SESSION_ID"))
			result = fmt.Sprintf(`{"content":[{"type":"text","text":%s}]}`, text)
		case "resources/list":
			result = `{"resources":[{"uri":"fixture://context","name":"context"}]}`
		case "resources/templates/list":
			result = `{"resourceTemplates":[]}`
		case "prompts/list":
			result = `{"prompts":[]}`
		}
		if err := encoder.Encode(rpcMessage{Version: "2.0", ID: request.ID, Result: json.RawMessage(result)}); err != nil {
			os.Exit(1)
		}
	}
}

func TestGatewayRoundTrip(t *testing.T) {
	gateway, proxy := os.Getenv("AGENTGATEWAY_BINARY"), os.Getenv("MCP_REMOTE_BINARY")
	if gateway == "" || proxy == "" {
		t.Skip("Nix check supplies gateway and proxy binaries")
	}
	executable, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	for _, session := range []string{"first", "second"} {
		t.Run(session, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
			defer cancel()
			input, writer := io.Pipe()
			reader, output := io.Pipe()
			defer func() { _ = input.Close() }()
			defer func() { _ = writer.Close() }()
			defer func() { _ = reader.Close() }()
			defer func() { _ = output.Close() }()
			log, err := os.Create(filepath.Join(t.TempDir(), "gateway.log"))
			if err != nil {
				t.Fatal(err)
			}
			defer func() { _ = log.Close() }()
			done := make(chan error, 1)
			go func() {
				done <- run(ctx, definition{Name: "fixture", Command: executable, Args: []string{"-test.run=^TestBackend$"}, Env: map[string]string{"SYSINIT_MCP_FIXTURE": "1", "ORC_SESSION_ID": session}}, gateway, proxy, input, output, log)
				_ = output.Close()
			}()
			scanner := bufio.NewScanner(reader)
			scanner.Buffer(make([]byte, 4096), 1024*1024)
			request := func(message string) rpcMessage {
				t.Helper()
				if _, err := fmt.Fprintln(writer, message); err != nil {
					t.Fatal(err)
				}
				for scanner.Scan() {
					var reply rpcMessage
					if err := json.Unmarshal(scanner.Bytes(), &reply); err != nil {
						t.Fatal(err)
					}
					if len(reply.ID) == 0 {
						continue
					}
					if len(reply.Error) > 0 {
						t.Fatalf("RPC error: %s", reply.Error)
					}
					return reply
				}
				data, _ := os.ReadFile(log.Name())
				t.Fatalf("transport closed: %v\n%s", scanner.Err(), data)
				return rpcMessage{}
			}
			request(`{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"fixture-client","version":"1"}}}`)
			if _, err := fmt.Fprintln(writer, `{"jsonrpc":"2.0","method":"notifications/initialized"}`); err != nil {
				t.Fatal(err)
			}
			tools := request(`{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}`)
			if !strings.Contains(string(tools.Result), `"context"`) {
				t.Fatalf("missing tool: %s", tools.Result)
			}
			result := request(`{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"context","arguments":{}}}`)
			cwd, _ := os.Getwd()
			if !strings.Contains(string(result.Result), cwd+"|"+session) {
				t.Fatalf("lost client context: %s", result.Result)
			}
			resources := request(`{"jsonrpc":"2.0","id":4,"method":"resources/list","params":{}}`)
			if !strings.Contains(string(resources.Result), "fixture://context") {
				t.Fatalf("missing resource: %s", resources.Result)
			}
			_ = writer.Close()
			select {
			case err := <-done:
				if err != nil {
					t.Fatal(err)
				}
			case <-time.After(6 * time.Second):
				t.Fatal("stdin EOF did not stop gateway")
			}
		})
	}
}

func TestRejectGatewayBypass(t *testing.T) {
	err := run(context.Background(), definition{Gateway: true, URL: "https://example.com/mcp"}, "unused", "unused", strings.NewReader(""), io.Discard, io.Discard)
	if err == nil {
		t.Fatal("accepted non-gateway endpoint")
	}
}

func TestConfigTransports(t *testing.T) {
	for _, transport := range []string{"local", "http", "sse"} {
		config, err := makeConfig(definition{Name: "fixture", Type: transport, Command: "fixture", URL: "https://example.com/mcp"}, 18000, "secret")
		if err != nil {
			t.Fatal(err)
		}
		if config.MCP.Policies.APIKey.Mode != "strict" {
			t.Fatal("gateway must require its session key")
		}
		if !config.MCP.DNSProtection {
			t.Fatal("DNS protection is disabled")
		}
	}
}
