package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"time"
)

type probeResponse struct {
	ID     json.RawMessage `json:"id"`
	Result json.RawMessage `json:"result"`
	Error  json.RawMessage `json:"error"`
}

func probe(parent context.Context, server definition, gateway, proxy string) error {
	ctx, cancel := context.WithTimeout(parent, 90*time.Second)
	defer cancel()
	input, writer, err := os.Pipe()
	if err != nil {
		return err
	}
	defer func() { _ = input.Close() }()
	defer func() { _ = writer.Close() }()
	reader, output, err := os.Pipe()
	if err != nil {
		return err
	}
	defer func() { _ = reader.Close() }()
	defer func() { _ = output.Close() }()
	done := make(chan error, 1)
	go func() {
		done <- run(ctx, server, gateway, proxy, input, output, os.Stderr)
		_ = output.Close()
		close(done)
	}()
	defer func() {
		cancel()
		_ = writer.Close()
		_ = reader.Close()
		<-done
	}()
	go func() {
		<-ctx.Done()
		_ = reader.Close()
		_ = writer.Close()
	}()
	decoder := json.NewDecoder(reader)
	request := func(message string) (json.RawMessage, error) {
		if _, err := fmt.Fprintln(writer, message); err != nil {
			return nil, err
		}
		for {
			var response probeResponse
			if err := decoder.Decode(&response); err != nil {
				return nil, err
			}
			if len(response.ID) == 0 {
				continue
			}
			if len(response.Error) > 0 {
				return nil, fmt.Errorf("RPC error: %s", response.Error)
			}
			return response.Result, nil
		}
	}
	initialized, err := request(`{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"sysinit-mcp-probe","version":"1"}}}`)
	if err != nil {
		return err
	}
	if _, err := fmt.Fprintln(writer, `{"jsonrpc":"2.0","method":"notifications/initialized"}`); err != nil {
		return err
	}
	tools, err := request(`{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}`)
	if err != nil {
		return err
	}
	var catalog struct {
		Tools []struct {
			Name        string          `json:"name"`
			Description string          `json:"description"`
			InputSchema json.RawMessage `json:"inputSchema"`
		} `json:"tools"`
	}
	if err := json.Unmarshal(tools, &catalog); err != nil {
		return fmt.Errorf("invalid tool catalog: %w", err)
	}
	var initResult struct {
		ProtocolVersion string `json:"protocolVersion"`
	}
	if err := json.Unmarshal(initialized, &initResult); err != nil {
		return err
	}
	for _, tool := range catalog.Tools {
		if tool.Name == "" || len(tool.InputSchema) == 0 {
			return fmt.Errorf("tool %q lacks a name or input schema", tool.Name)
		}
	}
	_ = writer.Close()
	select {
	case err := <-done:
		if err != nil {
			return err
		}
	case <-ctx.Done():
		return ctx.Err()
	}
	return json.NewEncoder(os.Stdout).Encode(struct {
		Name     string `json:"name"`
		Protocol string `json:"protocol"`
		Tools    int    `json:"tools"`
	}{server.Name, initResult.ProtocolVersion, len(catalog.Tools)})
}
