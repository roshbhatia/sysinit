package provider

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os/exec"
	"strings"
)

type Claude struct{}

func (Claude) Name() string { return "claude" }

type line struct {
	Type    string `json:"type"`
	Subtype string `json:"subtype"`
	Message struct {
		Content []struct {
			Type string          `json:"type"`
			Text string          `json:"text"`
			Name string          `json:"name"`
			ID   string          `json:"id"`
			Args json.RawMessage `json:"input"`
		} `json:"content"`
	} `json:"message"`
	Model            string         `json:"model"`
	Tools            []string       `json:"tools"`
	SessionID        string         `json:"session_id"`
	Result           string         `json:"result"`
	StructuredOutput map[string]any `json:"structured_output"`
	IsError          bool           `json:"is_error"`
	TotalCostUSD     float64        `json:"total_cost_usd"`
	DurationMS       int64          `json:"duration_ms"`
	NumTurns         int            `json:"num_turns"`
}

func summarize(args json.RawMessage) string {
	var fields map[string]any
	if json.Unmarshal(args, &fields) != nil {
		return ""
	}

	for _, key := range []string{"command", "file_path", "pattern", "path", "url", "prompt", "description"} {
		if value, ok := fields[key].(string); ok && value != "" {
			value = strings.TrimSpace(strings.SplitN(value, "\n", 2)[0])
			if len(value) > 90 {
				value = value[:90] + "…"
			}
			return value
		}
	}
	return ""
}

func scanClaude(from io.Reader, wanted map[string]any, events chan<- Event) *Result {
	var result *Result

	reader := lines(from)
	for reader.Scan() {
		var event line
		if json.Unmarshal(reader.Bytes(), &event) != nil {
			continue
		}
		switch event.Type {
		case "system":
			if event.Subtype == "init" {
				events <- Event{
					Kind: Started,
					Text: fmt.Sprintf("%s, %d tools", event.Model, len(event.Tools)),
				}
			}
		case "assistant":
			for _, block := range event.Message.Content {
				switch block.Type {
				case "text":
					if text := strings.TrimSpace(block.Text); text != "" {
						events <- Event{Kind: Text, Text: text}
					}
				case "tool_use":
					events <- Event{Kind: Tool, Tool: block.Name, Text: summarize(block.Args)}
				}
			}
		case "rate_limit_event":
			events <- Event{Kind: Notice, Text: "rate limited, waiting"}
		case "result":
			result = &Result{
				Text:       event.Result,
				Structured: event.StructuredOutput,
				Failed:     event.IsError,
				Reason:     event.Subtype,
			}

			if wanted != nil && !result.Failed && result.Structured == nil {
				if result.Structured = structured(result.Text); result.Structured == nil {
					result.Failed, result.Reason = true, offShape
				}
			}
			events <- Event{Kind: Done, Result: result}
		}
	}
	return result
}

func (c Claude) Run(ctx context.Context, req Request) (<-chan Event, error) {
	binary, err := exec.LookPath("claude")
	if err != nil {
		return nil, errors.New("claude is not on PATH; install Claude Code or pass --provider")
	}

	args := []string{
		"--print",
		"--output-format", "stream-json",
		"--verbose",

		"--dangerously-skip-permissions",
	}
	if req.Model != "" {
		args = append(args, "--model", req.Model)
	}
	if req.Schema != nil {
		encoded, err := json.Marshal(req.Schema)
		if err != nil {
			return nil, fmt.Errorf("the schema will not encode: %w", err)
		}
		args = append(args, "--json-schema", string(encoded))
	}

	args = append(args, "--", req.Prompt)

	cmd := exec.CommandContext(ctx, binary, args...)
	cmd.Dir = req.Dir
	cmd.Stdin = bytes.NewReader(req.Input)

	out, err := cmd.StdoutPipe()
	if err != nil {
		return nil, err
	}
	var problems bytes.Buffer
	cmd.Stderr = &problems

	if err := cmd.Start(); err != nil {
		return nil, err
	}

	events := make(chan Event, 64)
	go func() {
		defer close(events)

		answered := scanClaude(out, req.Schema, events)

		err := cmd.Wait()
		if answered != nil {
			return
		}

		reason := strings.TrimSpace(problems.String())
		if reason == "" && err != nil {
			reason = err.Error()
		}
		if reason == "" {
			reason = "claude exited without an answer"
		}
		events <- Event{Kind: Done, Result: &Result{
			Failed: true,
			Reason: reason,
		}}
	}()

	return events, nil
}
