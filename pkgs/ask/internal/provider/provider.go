// Package provider runs one question against one coding agent and reports what it does as
// it does it. The interface is here rather than in the caller, so a second provider is a
// file rather than a rewrite.
package provider

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"strings"
	"time"
)

// Request is one question.
type Request struct {
	// What to do with the input.
	Prompt string
	// What was piped in. May be empty.
	Input []byte
	// The model alias, or empty for the provider's own default.
	Model string
	// The shape the answer must take, or nil for prose.
	Schema map[string]any
	// How long to wait before giving up.
	Timeout time.Duration
	// Where to run, which is where the caller ran.
	Dir string
}

// Kind is what an event says.
type Kind int

const (
	// Started carries the model and the tool count the provider woke up with.
	Started Kind = iota
	// Text is prose the model wrote.
	Text
	// Tool is the provider reaching for something.
	Tool
	// Notice is anything else worth a line, such as a rate limit.
	Notice
	// Done carries the answer.
	Done
)

// Event is one thing that happened.
type Event struct {
	Kind Kind
	// The line to show, for every kind but Done.
	Text string
	// The tool's name, for Tool.
	Tool string
	// The answer, for Done.
	Result *Result
}

// Result is the answer and what it cost.
type Result struct {
	// The answer as the provider wrote it.
	Text string
	// The parsed answer, when a schema was asked for.
	Structured map[string]any
	// Whether the provider itself called this a failure.
	Failed bool
	// What the failure was, when it failed.
	Reason string

	CostUSD  float64
	Duration time.Duration
	Turns    int
	Session  string
}

// Provider is one coding agent this can drive.
type Provider interface {
	// Name is what a caller writes to pick it.
	Name() string
	// Run starts the question and returns the events it produces. The channel closes when
	// the run is over, whether it answered or not.
	Run(ctx context.Context, req Request) (<-chan Event, error)
}

// offShape is what a run is called when a shape was asked for and something else came back.
// One wording for both providers, because the caller cannot act on the difference.
const offShape = "answered outside the shape --schema asked for"

// lines reads a provider's stream. The buffer is raised because one line carries a whole
// message or a whole command's output, which is larger than the scanner's own limit.
func lines(from io.Reader) *bufio.Scanner {
	reader := bufio.NewScanner(from)
	reader.Buffer(make([]byte, 0, 64*1024), 8*1024*1024)
	return reader
}

// structured is the JSON object inside an answer, since a model told to answer in a shape can
// still wrap it in a fence or a sentence.
func structured(text string) map[string]any {
	start := strings.Index(text, "{")
	end := strings.LastIndex(text, "}")
	if start < 0 || end < start {
		return nil
	}
	var shape map[string]any
	if json.Unmarshal([]byte(text[start:end+1]), &shape) != nil {
		return nil
	}
	return shape
}

// Find returns the provider a caller named, by its name or by the letter its flag uses.
func Find(name string) (Provider, error) {
	switch name {
	case "", "claude", "c":
		return Claude{}, nil
	case "codex", "o":
		return Codex{}, nil
	}
	return nil, fmt.Errorf("unknown provider %q, known: claude, codex", name)
}
