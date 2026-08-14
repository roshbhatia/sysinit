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

type Request struct {
	Prompt string

	Input []byte

	Model string

	Schema map[string]any

	Timeout time.Duration

	Dir string
}

type Kind int

const (
	Started Kind = iota

	Text

	Tool

	Notice

	Done
)

type Event struct {
	Kind Kind

	Text string

	Tool string

	Result *Result
}

type Result struct {
	Text string

	Structured map[string]any

	Failed bool

	Reason string

	CostUSD  float64
	Duration time.Duration
	Turns    int
	Session  string
}

type Provider interface {
	Name() string

	Run(ctx context.Context, req Request) (<-chan Event, error)
}

const offShape = "answered outside the shape --schema asked for"

func lines(from io.Reader) *bufio.Scanner {
	reader := bufio.NewScanner(from)
	reader.Buffer(make([]byte, 0, 64*1024), 8*1024*1024)
	return reader
}

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

func Find(name string) (Provider, error) {
	switch name {
	case "", "claude", "c":
		return Claude{}, nil
	case "codex", "o":
		return Codex{}, nil
	}
	return nil, fmt.Errorf("unknown provider %q, known: claude, codex", name)
}
