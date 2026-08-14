package provider

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
	"time"
)

// Codex drives the Codex CLI in exec mode. It asks for `--json` for the reason Claude is asked
// for `stream-json`: a spinner that cannot say what the model is doing only says the program
// has not died.
type Codex struct{}

// Name is what a caller writes to pick it.
func (Codex) Name() string { return "codex" }

// One item of a `codex exec --json` stream, to the depth this reads it.
type codexItem struct {
	ID      string `json:"id"`
	Type    string `json:"type"`
	Text    string `json:"text"`
	Message string `json:"message"`
	Command string `json:"command"`
	Server  string `json:"server"`
	Tool    string `json:"tool"`
	Query   string `json:"query"`
	Changes []struct {
		Path string `json:"path"`
	} `json:"changes"`
}

// One line of `codex exec --json`.
type codexLine struct {
	Type     string `json:"type"`
	ThreadID string `json:"thread_id"`
	Message  string `json:"message"`
	Error    struct {
		Message string `json:"message"`
	} `json:"error"`
	Item codexItem `json:"item"`
}

// clip is the opening line of a description, since a one-line event has no room for the rest.
func clip(text string) string {
	line := strings.TrimSpace(strings.SplitN(strings.TrimSpace(text), "\n", 2)[0])
	if len(line) > 90 {
		line = line[:90] + "…"
	}
	return line
}

// toolOf names the item as a tool, or reports that it is not one.
func toolOf(item codexItem) (string, string, bool) {
	switch item.Type {
	case "command_execution":
		return "shell", clip(item.Command), true
	case "file_change":
		var paths []string
		for _, change := range item.Changes {
			paths = append(paths, change.Path)
		}
		return "edit", clip(strings.Join(paths, " ")), true
	case "mcp_tool_call":
		name := item.Server
		if item.Tool != "" {
			name += "." + item.Tool
		}
		return "mcp", clip(name), true
	case "web_search":
		return "search", clip(item.Query), true
	}
	return "", "", false
}

// schemaFile writes the shape out, because codex takes it as a path rather than as a string.
func schemaFile(shape map[string]any) (string, error) {
	encoded, err := json.Marshal(shape)
	if err != nil {
		return "", fmt.Errorf("the schema will not encode: %w", err)
	}
	file, err := os.CreateTemp("", "ask-schema-*.json")
	if err != nil {
		return "", err
	}
	if _, err := file.Write(encoded); err != nil {
		file.Close()
		os.Remove(file.Name())
		return "", err
	}
	return file.Name(), file.Close()
}

// codexRun is what one stream said, read back once it has ended.
type codexRun struct {
	Answer  string
	Session string
	Failure string
	Turns   int
}

// scanCodex turns one `codex exec --json` stream into events. It takes a reader rather than
// the command, so the shape of the stream can be exercised without a model behind it.
func scanCodex(from io.Reader, model string, events chan<- Event) codexRun {
	var run codexRun
	// A tool arrives twice, as started and as completed, and is worth one line.
	announced := map[string]bool{}

	reader := lines(from)
	for reader.Scan() {
		var event codexLine
		if json.Unmarshal(reader.Bytes(), &event) != nil {
			continue
		}
		switch event.Type {
		case "thread.started":
			run.Session = event.ThreadID
			if model == "" {
				model = "default model"
			}
			events <- Event{Kind: Started, Text: model}
		case "item.started", "item.completed":
			done := event.Type == "item.completed"
			item := event.Item
			switch {
			case item.Type == "agent_message" && done:
				if text := strings.TrimSpace(item.Text); text != "" {
					// The last message is the answer; the earlier ones are the model thinking
					// out loud.
					run.Answer = text
					events <- Event{Kind: Text, Text: text}
				}
			case item.Type == "reasoning" && done:
				if text := strings.TrimSpace(item.Text); text != "" {
					events <- Event{Kind: Text, Text: text}
				}
			case item.Type == "error" && done:
				events <- Event{Kind: Notice, Text: clip(item.Message)}
			case !announced[item.ID]:
				if name, text, ok := toolOf(item); ok {
					announced[item.ID] = true
					events <- Event{Kind: Tool, Tool: name, Text: text}
				}
			}
		case "turn.completed":
			run.Turns++
		case "turn.failed":
			run.Failure = event.Error.Message
		case "error":
			events <- Event{Kind: Notice, Text: clip(event.Message)}
		}
	}
	return run
}

// Run starts one exec session and turns its stream into events.
func (c Codex) Run(ctx context.Context, req Request) (<-chan Event, error) {
	binary, err := exec.LookPath("codex")
	if err != nil {
		return nil, errors.New("codex is not on PATH; install the Codex CLI or pass --provider")
	}

	args := []string{
		"exec",
		"--json",
		// Every run, without asking: this is a pipe, and an approval prompt on a pipe is a hang
		// that no one is watching.
		"--dangerously-bypass-approvals-and-sandbox",
		// A caller pipes from wherever they are, and codex otherwise refuses to leave a repo.
		"--skip-git-repo-check",
	}
	if req.Model != "" {
		args = append(args, "--model", req.Model)
	}
	var schemaPath string
	if req.Schema != nil {
		if schemaPath, err = schemaFile(req.Schema); err != nil {
			return nil, err
		}
		args = append(args, "--output-schema", schemaPath)
	}
	args = append(args, req.Prompt)

	discard := func() {
		if schemaPath != "" {
			os.Remove(schemaPath)
		}
	}

	cmd := exec.CommandContext(ctx, binary, args...)
	cmd.Dir = req.Dir
	// With a prompt in the arguments, codex reads stdin and appends it to the prompt.
	cmd.Stdin = bytes.NewReader(req.Input)

	out, err := cmd.StdoutPipe()
	if err != nil {
		discard()
		return nil, err
	}
	var problems bytes.Buffer
	cmd.Stderr = &problems

	if err := cmd.Start(); err != nil {
		discard()
		return nil, err
	}

	events := make(chan Event, 64)
	go func() {
		defer close(events)
		defer discard()
		started := time.Now()

		run := scanCodex(out, req.Model, events)

		err := cmd.Wait()
		// Codex reports no cost, so the summary carries the turns and the time and nothing else.
		result := &Result{
			Text:     run.Answer,
			Duration: time.Since(started),
			Turns:    run.Turns,
			Session:  run.Session,
		}
		switch {
		case run.Failure != "":
			result.Failed, result.Reason = true, run.Failure
		case run.Answer == "":
			// No message at all: what codex wrote to stderr is the only account of why, so it is
			// reported rather than swallowed.
			reason := strings.TrimSpace(problems.String())
			if reason == "" && err != nil {
				reason = err.Error()
			}
			if reason == "" {
				reason = "codex exited without an answer"
			}
			result.Failed, result.Reason = true, reason
		case req.Schema != nil:
			// A shape was asked for, so prose in its place is a failed run rather than an answer
			// the caller has to notice is the wrong kind.
			if result.Structured = structured(run.Answer); result.Structured == nil {
				result.Failed, result.Reason = true, offShape
			}
		}
		events <- Event{Kind: Done, Result: result}
	}()

	return events, nil
}
