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
	"time"
)

// Claude drives Claude Code in print mode. It asks for `stream-json`, because a spinner that
// cannot say what the model is doing is a spinner that only says the program has not died.
type Claude struct{}

// Name is what a caller writes to pick it.
func (Claude) Name() string { return "claude" }

// One line of `--output-format stream-json`, to the depth this reads it.
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

// The first line of a tool's arguments, which is all a one-line event has room for.
func summarize(args json.RawMessage) string {
	var fields map[string]any
	if json.Unmarshal(args, &fields) != nil {
		return ""
	}
	// The keys worth showing, in the order a reader would want them.
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

// scanClaude turns one stream-json stream into events and reports the result line it carried,
// or nil when it carried none. It takes a reader rather than the command, so the shape of the
// stream can be exercised without a model behind it.
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
				CostUSD:    event.TotalCostUSD,
				Duration:   time.Duration(event.DurationMS) * time.Millisecond,
				Turns:      event.NumTurns,
				Session:    event.SessionID,
			}
			// A shape was asked for and the harness reported none, so the answer's own text is
			// the last place it can be: a model can write the object into prose. Prose with no
			// object in it is a failed run, as it is for codex, rather than an answer the caller
			// has to notice is the wrong kind.
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

// Run starts one print-mode session and turns its stream into events.
func (c Claude) Run(ctx context.Context, req Request) (<-chan Event, error) {
	binary, err := exec.LookPath("claude")
	if err != nil {
		return nil, errors.New("claude is not on PATH; install Claude Code or pass --provider")
	}

	args := []string{
		"--print",
		"--output-format", "stream-json",
		"--verbose",
		// Every run, without asking: this is a pipe, and a permission prompt on a pipe is a
		// hang that no one is watching.
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
	args = append(args, req.Prompt)

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
		started := time.Now()

		answered := scanClaude(out, req.Schema, events)

		err := cmd.Wait()
		if answered != nil {
			return
		}
		// No result line: the run died, and what it wrote to stderr is the only account of
		// why, so it is reported rather than swallowed.
		reason := strings.TrimSpace(problems.String())
		if reason == "" && err != nil {
			reason = err.Error()
		}
		if reason == "" {
			reason = "claude exited without an answer"
		}
		events <- Event{Kind: Done, Result: &Result{
			Failed:   true,
			Reason:   reason,
			Duration: time.Since(started),
		}}
	}()

	return events, nil
}
