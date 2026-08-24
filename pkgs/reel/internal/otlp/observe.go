package otlp

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

// The org pushes remote managed settings that force Claude Code's OTLP endpoint
// to its Observe collector, and no local scope overrides them: not the shell
// environment, not a signal specific OTEL_EXPORTER_OTLP_TRACES_ENDPOINT, not
// /Library/Application Support/ClaudeCode/managed-settings.json, not the
// --managed-settings flag. The local collector therefore never sees a span. So
// reel reads them back out of Observe instead of trying to win that fight.
//
// Observe stores one row per span, with the resource and span attributes as
// plain JSON maps rather than the OTLP keyValue lists Decode expects, so this
// source has its own decoder.

// ObserveDataset is the datastream the org's remote settings point Claude Code
// at. Its token is the one in ~/.claude/remote-settings.json.
const ObserveDataset = "LaurelAI.Agents"

// A span is written when it ends, and Observe indexes it a moment later, so a
// poll that asks only for the time since the last poll misses the spans that
// landed late. The window overlaps and the caller deduplicates by span id.
const observeLag = 90 * time.Second

type observeRow struct {
	Stamp  string `json:"BUNDLE_TIMESTAMP"`
	Fields struct {
		Resource struct {
			Attributes map[string]any `json:"attributes"`
		} `json:"resource"`
		Span struct {
			Attributes map[string]any `json:"attributes"`
			Name       string         `json:"name"`
			TraceID    string         `json:"trace_id"`
			SpanID     string         `json:"span_id"`
			ParentID   string         `json:"parent_span_id"`
			Start      string         `json:"start_time_unix_nano"`
			End        string         `json:"end_time_unix_nano"`
			Status     struct {
				Code    int    `json:"code"`
				Message string `json:"message"`
			} `json:"status"`
		} `json:"span"`
	} `json:"FIELDS"`
}

// Observe reads spans back out of the org's datastream.
type Observe struct {
	Binary  string
	Dataset string
	// Email scopes the read to one person. The datastream is shared across the
	// organization, so without it reel would draw other people's sessions.
	Email string
	// Session narrows further to one run, which is what --session already means
	// everywhere else in reel.
	Session string
}

// Fetch reads every span in the window ending now.
func (o Observe) Fetch(ctx context.Context, window time.Duration) ([]Span, error) {
	bin := o.Binary
	if bin == "" {
		bin = "observe"
	}
	dataset := o.Dataset
	if dataset == "" {
		dataset = ObserveDataset
	}

	filters := []string{`OBSERVATION_KIND = "otelspan"`}
	if o.Email != "" {
		filters = append(filters, fmt.Sprintf(`string(FIELDS.span.attributes["user.email"]) = %q`, o.Email))
	}
	// A prefix is what --session usually carries, and reel already resolves one
	// against the store. Only a whole session id can narrow the query itself.
	if len(o.Session) == len("00000000-0000-0000-0000-000000000000") {
		filters = append(filters, fmt.Sprintf(`string(FIELDS.span.attributes["session.id"]) = %q`, o.Session))
	}
	opal := "filter " + strings.Join(filters, " and ") + " | pick_col BUNDLE_TIMESTAMP, FIELDS"

	// -Q is a global flag, so it goes ahead of the subcommand. Without it the
	// info logs land on stdout and the first line fails to parse as JSON.
	cmd := exec.CommandContext(ctx, bin, "-Q",
		"query", "-q", opal, "-i", dataset, "--json",
		"-r", window.Round(time.Second).String())
	stderr := &strings.Builder{}
	cmd.Stderr = stderr
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("observe query: %w: %s", err, strings.TrimSpace(stderr.String()))
	}
	if os.Getenv("REEL_DEBUG") != "" {
		fmt.Fprintf(os.Stderr, "reel: opal=%s\nreel: %d bytes, stderr=%s\n",
			opal, len(out), strings.TrimSpace(stderr.String()))
	}
	return decodeObserve(out), nil
}

func decodeObserve(blob []byte) []Span {
	var out []Span
	for _, line := range strings.Split(string(blob), "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		var row observeRow
		if json.Unmarshal([]byte(line), &row) != nil {
			continue
		}
		raw := row.Fields.Span
		if raw.SpanID == "" {
			continue
		}
		attrs := map[string]string{}
		flatten(row.Fields.Resource.Attributes, attrs)
		flatten(raw.Attributes, attrs)

		span := Span{
			TraceID:  raw.TraceID,
			SpanID:   raw.SpanID,
			ParentID: raw.ParentID,
			Name:     raw.Name,
			Service:  attrs["service.name"],
			Session:  attrs["session.id"],
			Start:    stamp(raw.Start),
			End:      stamp(raw.End),
			Attrs:    attrs,
			Error:    raw.Status.Message,
		}
		if raw.Status.Code == 2 || attrs["success"] == "false" || attrs["error"] != "" {
			span.Failed = true
			if span.Error == "" {
				span.Error = attrs["error"]
			}
		}
		out = append(out, span)
	}
	return out
}

// Observe hands back real JSON types where the wire format hands back tagged
// values, so a number arrives as a float and an array as a slice.
func flatten(in map[string]any, into map[string]string) {
	for key, held := range in {
		into[key] = text(held)
	}
}

func text(held any) string {
	switch v := held.(type) {
	case nil:
		return ""
	case string:
		return v
	case bool:
		return strconv.FormatBool(v)
	case float64:
		return strconv.FormatFloat(v, 'f', -1, 64)
	case []any:
		parts := make([]string, 0, len(v))
		for _, one := range v {
			parts = append(parts, text(one))
		}
		return strings.Join(parts, ", ")
	default:
		blob, err := json.Marshal(v)
		if err != nil {
			return ""
		}
		return string(blob)
	}
}

// FollowObserve polls Observe and sends the spans it has not sent before. The
// window overlaps every poll, so a span indexed late still arrives, and the
// span id set is what keeps it from arriving twice.
func FollowObserve(o Observe, every time.Duration, back time.Duration, out chan<- []Span, stop <-chan struct{}) {
	defer close(out)

	seen := map[string]bool{}
	window := back
	for {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
		spans, err := o.Fetch(ctx, window)
		cancel()

		if err == nil {
			var batch []Span
			for _, one := range spans {
				if seen[one.SpanID] {
					continue
				}
				seen[one.SpanID] = true
				batch = append(batch, one)
			}
			if len(batch) > 0 {
				select {
				case out <- batch:
				case <-stop:
					return
				}
			}
			// The first read reaches back over the whole history the caller
			// asked for; every read after it only has to cover the poll plus
			// the indexing lag.
			window = every + observeLag
		}

		select {
		case <-stop:
			return
		case <-time.After(every):
		}
	}
}
