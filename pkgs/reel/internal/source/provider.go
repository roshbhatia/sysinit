// Package source reads spans from wherever this machine keeps them. The
// collector's file is the default, and a provider binary is the escape hatch
// for a machine whose harness exports somewhere reel cannot reach.
//
// A provider is any executable that prints newline delimited JSON on stdout and
// exits. One line is one span:
//
//	{"traceId":"…","spanId":"…","parentId":"…","name":"…",
//	 "startUnixNano":"…","endUnixNano":"…",
//	 "attrs":{"service.name":"…","session.id":"…"}}
//
// Only traceId, spanId, name and the two stamps are required. service and
// session come off the attributes when the line omits them, so a provider that
// forwards the attributes it already has needs no extra fields.
//
// A line carrying an event is a log record instead, which is how a harness
// reports what it cannot put on a span:
//
//	{"event":"user_prompt","startUnixNano":"…",
//	 "attrs":{"service.name":"…","session.id":"…","prompt":"…"}}
//
// A line reel cannot parse is skipped rather than fatal, because a provider
// that prints a warning should not take the view down with it.
//
// reel runs the provider once per poll with a --since window, and deduplicates
// by span id. A provider is therefore stateless: it answers "which spans ended
// in the last N", and reel decides what is new. That suits a source that has to
// be queried, which is the case this exists for.
package source

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/reel/internal/otlp"
)

// Env names the provider without a flag, so a machine can carry the choice in
// its own configuration rather than in every command line.
const Env = "REEL_PROVIDER"

// A name resolves to this prefix on PATH. A value holding a separator is taken
// as the path itself, which is what a provider outside PATH needs.
const prefix = "reel-"

type Provider struct {
	// Binary is the resolved executable.
	Binary string
	// Name is what the caller asked for, for error text and the header.
	Name string
	// Session narrows the read when the provider can do it. reel resolves a
	// prefix itself, so a provider may ignore this.
	Session string
}

// Resolve turns a name or a path into a provider. An empty ask, with nothing in
// the environment either, means the caller wants the collector file.
func Resolve(ask string) (*Provider, error) {
	if ask == "" {
		ask = strings.TrimSpace(os.Getenv(Env))
	}
	if ask == "" {
		return nil, nil
	}
	binary := ask
	if !strings.ContainsRune(ask, filepath.Separator) {
		binary = prefix + ask
	}
	found, err := exec.LookPath(binary)
	if err != nil {
		return nil, fmt.Errorf("provider %q: %w", ask, err)
	}
	return &Provider{Binary: found, Name: ask}, nil
}

// Fetch runs the provider once over the window ending now.
func (p Provider) Fetch(ctx context.Context, window time.Duration) (otlp.Batch, error) {
	args := []string{"--since", window.Round(time.Second).String()}
	if p.Session != "" {
		args = append(args, "--session", p.Session)
	}
	cmd := exec.CommandContext(ctx, p.Binary, args...)
	stderr := &strings.Builder{}
	cmd.Stderr = stderr
	out, err := cmd.Output()
	if err != nil {
		return otlp.Batch{}, fmt.Errorf("%s: %w: %s", p.Name, err, strings.TrimSpace(stderr.String()))
	}
	return Decode(out), nil
}

// line is the shape a provider prints. It is deliberately flatter than the OTLP
// wire format, because a provider is often a shell script and the keyValue
// lists are what makes that painful to emit.
type line struct {
	// event marks the line as a log record rather than a span. A harness puts
	// on a log what it cannot put on a span, and the prompt is the one reel
	// needs.
	Event    string            `json:"event"`
	TraceID  string            `json:"traceId"`
	SpanID   string            `json:"spanId"`
	ParentID string            `json:"parentId"`
	Name     string            `json:"name"`
	Service  string            `json:"service"`
	Session  string            `json:"session"`
	Start    string            `json:"startUnixNano"`
	End      string            `json:"endUnixNano"`
	Attrs    map[string]string `json:"attrs"`
	Failed   bool              `json:"failed"`
	Error    string            `json:"error"`
}

func Decode(blob []byte) otlp.Batch {
	out := otlp.Batch{}
	rows := bufio.NewScanner(bytes.NewReader(blob))
	rows.Buffer(make([]byte, 1<<20), 1<<26)
	for rows.Scan() {
		text := strings.TrimSpace(rows.Text())
		if text == "" || text[0] != '{' {
			continue
		}
		var one line
		if json.Unmarshal([]byte(text), &one) != nil {
			continue
		}
		attrs := one.Attrs
		if attrs == nil {
			attrs = map[string]string{}
		}
		if one.Event != "" {
			out.Records = append(out.Records, otlp.Record{
				Event:   one.Event,
				Body:    one.Name,
				Service: orAttr(one.Service, attrs, "service.name"),
				Session: orAttr(one.Session, attrs, "session.id"),
				At:      otlp.Stamp(one.Start),
				Attrs:   attrs,
			})
			continue
		}
		if one.SpanID == "" {
			continue
		}
		span := otlp.Span{
			TraceID:  one.TraceID,
			SpanID:   one.SpanID,
			ParentID: one.ParentID,
			Name:     one.Name,
			Service:  orAttr(one.Service, attrs, "service.name"),
			Session:  orAttr(one.Session, attrs, "session.id"),
			Start:    otlp.Stamp(one.Start),
			End:      otlp.Stamp(one.End),
			Attrs:    attrs,
			Failed:   one.Failed,
			Error:    one.Error,
		}
		if attrs["success"] == "false" || attrs["error"] != "" {
			span.Failed = true
			if span.Error == "" {
				span.Error = attrs["error"]
			}
		}
		out.Spans = append(out.Spans, span)
	}
	return out
}

func orAttr(given string, attrs map[string]string, key string) string {
	if given != "" {
		return given
	}
	return attrs[key]
}

// Follow polls the provider and sends only the spans it has not sent before.
// The window overlaps every poll by lag, because a span is written when it ends
// and a queried source indexes it a moment later; the span id set is what keeps
// the overlap from arriving twice.
func Follow(p Provider, every, back, lag time.Duration, out chan<- otlp.Batch, stop <-chan struct{}) {
	defer close(out)

	seen := map[string]bool{}
	window := back
	for {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
		read, err := p.Fetch(ctx, window)
		cancel()

		if err == nil {
			batch := otlp.Batch{}
			for _, one := range read.Spans {
				if seen[one.SpanID] {
					continue
				}
				seen[one.SpanID] = true
				batch.Spans = append(batch.Spans, one)
			}
			// A log record has no id of its own, so its own time and event
			// stand in. Two records of one event at one instant are the same
			// record read twice.
			for _, one := range read.Records {
				key := one.Session + "/" + one.Event + "/" + one.At.Format(time.RFC3339Nano)
				if seen[key] {
					continue
				}
				seen[key] = true
				batch.Records = append(batch.Records, one)
			}
			if !batch.Empty() {
				select {
				case out <- batch:
				case <-stop:
					return
				}
			}
			// The first read covers the whole history the caller asked for.
			// Every read after it only has to cover the poll plus the lag.
			window = every + lag
		}

		select {
		case <-stop:
			return
		case <-time.After(every):
		}
	}
}
