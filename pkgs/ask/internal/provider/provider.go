package provider

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os/exec"
	"slices"
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

type Info struct {
	Name string

	Short string

	Blurb string

	Binary string

	build func() Provider
}

var known = []Info{
	{Name: "claude", Short: "cld", Blurb: "Claude Code", Binary: "claude", build: func() Provider { return Claude{} }},
	{Name: "codex", Short: "cdx", Blurb: "the Codex CLI", Binary: "codex", build: func() Provider { return Codex{} }},
}

func (i Info) New() Provider { return i.build() }

func (i Info) Ready() bool {
	_, err := exec.LookPath(i.Binary)
	return err == nil
}

func Known() []Info { return slices.Clone(known) }

func Lookup(name string) (Info, bool) {
	for _, one := range known {
		if name == one.Name || name == one.Short {
			return one, true
		}
	}
	return Info{}, false
}

func Names() []string {
	names := make([]string, 0, len(known)*2)
	for _, one := range known {
		names = append(names, one.Name, one.Short)
	}
	return names
}

func Find(name string) (Provider, error) {
	if name == "" {
		return nil, errors.New("say which agent to run, with -p")
	}
	if one, ok := Lookup(name); ok {
		return one.New(), nil
	}
	return nil, fmt.Errorf("unknown provider %q, known: %s", name, strings.Join(Names(), ", "))
}
