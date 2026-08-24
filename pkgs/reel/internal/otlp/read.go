// Package otlp reads the OTLP JSON that the collector's file exporter writes,
// one export request per line, and follows the file as it grows.
package otlp

import (
	"bufio"
	"encoding/json"
	"io"
	"os"
	"strconv"
	"time"
)

// Span is the flattened shape the rest of reel works in. The OTLP wire types
// nest resource, scope, and span attributes in three separate lists; every
// consumer here wants them as one map keyed by attribute name.
type Span struct {
	TraceID  string
	SpanID   string
	ParentID string
	Name     string
	Service  string
	Session  string
	Start    time.Time
	End      time.Time
	Attrs    map[string]string
	Failed   bool
	Error    string
}

func (s Span) Duration() time.Duration { return s.End.Sub(s.Start) }

// Record is one log record. A harness puts on a log what it cannot put on a
// span: Claude Code emits the prompt text as claude_code.user_prompt rather
// than as an attribute of the turn, so the turn row has no text without this.
type Record struct {
	Event   string
	Body    string
	Service string
	Session string
	At      time.Time
	Attrs   map[string]string
}

// Batch is one read from a source. Metrics are decoded by nothing here: a
// counter says how much happened, and every row in reel is a thing that
// happened at a time.
type Batch struct {
	Spans   []Span
	Records []Record
}

func (b Batch) Empty() bool { return len(b.Spans) == 0 && len(b.Records) == 0 }

type value struct {
	StringValue *string  `json:"stringValue"`
	IntValue    *string  `json:"intValue"`
	BoolValue   *bool    `json:"boolValue"`
	DoubleValue *float64 `json:"doubleValue"`
	ArrayValue  *struct {
		Values []value `json:"values"`
	} `json:"arrayValue"`
}

func (v value) String() string {
	switch {
	case v.StringValue != nil:
		return *v.StringValue
	case v.IntValue != nil:
		return *v.IntValue
	case v.BoolValue != nil:
		return strconv.FormatBool(*v.BoolValue)
	case v.DoubleValue != nil:
		return strconv.FormatFloat(*v.DoubleValue, 'f', -1, 64)
	case v.ArrayValue != nil:
		out := ""
		for at, one := range v.ArrayValue.Values {
			if at > 0 {
				out += ", "
			}
			out += one.String()
		}
		return out
	}
	return ""
}

type keyValue struct {
	Key   string `json:"key"`
	Value value  `json:"value"`
}

type wireSpan struct {
	TraceID      string     `json:"traceId"`
	SpanID       string     `json:"spanId"`
	ParentSpanID string     `json:"parentSpanId"`
	Name         string     `json:"name"`
	Start        string     `json:"startTimeUnixNano"`
	End          string     `json:"endTimeUnixNano"`
	Attributes   []keyValue `json:"attributes"`
	Status       struct {
		Code    int    `json:"code"`
		Message string `json:"message"`
	} `json:"status"`
}

type wireRecord struct {
	Time      string `json:"timeUnixNano"`
	Observed  string `json:"observedTimeUnixNano"`
	EventName string `json:"eventName"`
	Body      struct {
		StringValue string `json:"stringValue"`
	} `json:"body"`
	Attributes []keyValue `json:"attributes"`
}

type request struct {
	ResourceLogs []struct {
		Resource struct {
			Attributes []keyValue `json:"attributes"`
		} `json:"resource"`
		ScopeLogs []struct {
			LogRecords []wireRecord `json:"logRecords"`
		} `json:"scopeLogs"`
	} `json:"resourceLogs"`
	ResourceSpans []struct {
		Resource struct {
			Attributes []keyValue `json:"attributes"`
		} `json:"resource"`
		ScopeSpans []struct {
			Spans []wireSpan `json:"spans"`
		} `json:"scopeSpans"`
	} `json:"resourceSpans"`
}

// Stamp is exported because a provider source parses the same nanosecond
// strings, and two copies of this would drift.
func Stamp(nanos string) time.Time { return stamp(nanos) }

func stamp(nanos string) time.Time {
	count, err := strconv.ParseInt(nanos, 10, 64)
	if err != nil {
		return time.Time{}
	}
	return time.Unix(0, count)
}

// Decode turns one exported request into flat spans and log records. The
// collector writes one request per line and a request carries one signal, so a
// line answers with one or the other.
func Decode(line []byte) Batch {
	var req request
	if err := json.Unmarshal(line, &req); err != nil {
		return Batch{}
	}

	out := Batch{}
	for _, resource := range req.ResourceLogs {
		shared := map[string]string{}
		for _, one := range resource.Resource.Attributes {
			shared[one.Key] = one.Value.String()
		}
		for _, scope := range resource.ScopeLogs {
			for _, raw := range scope.LogRecords {
				attrs := map[string]string{}
				for key, held := range shared {
					attrs[key] = held
				}
				for _, one := range raw.Attributes {
					attrs[one.Key] = one.Value.String()
				}
				at := stamp(raw.Time)
				if at.IsZero() {
					at = stamp(raw.Observed)
				}
				event := attrs["event.name"]
				if event == "" {
					event = raw.EventName
				}
				out.Records = append(out.Records, Record{
					Event:   event,
					Body:    raw.Body.StringValue,
					Service: attrs["service.name"],
					Session: attrs["session.id"],
					At:      at,
					Attrs:   attrs,
				})
			}
		}
	}
	for _, resource := range req.ResourceSpans {
		shared := map[string]string{}
		for _, one := range resource.Resource.Attributes {
			shared[one.Key] = one.Value.String()
		}

		for _, scope := range resource.ScopeSpans {
			for _, raw := range scope.Spans {
				attrs := map[string]string{}
				for key, held := range shared {
					attrs[key] = held
				}
				for _, one := range raw.Attributes {
					attrs[one.Key] = one.Value.String()
				}

				span := Span{
					TraceID:  raw.TraceID,
					SpanID:   raw.SpanID,
					ParentID: raw.ParentSpanID,
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
				out.Spans = append(out.Spans, span)
			}
		}
	}
	return out
}

// Follow reads path to its end, then keeps watching for new lines. It sends one
// batch per read so the caller redraws once per poll rather than once per span.
// The collector rotates the file at 64 MB; a size that went backwards means the
// rotation happened, so reopen from the start of the new file.
func Follow(path string, every time.Duration, out chan<- Batch, stop <-chan struct{}) {
	defer close(out)

	var (
		file   *os.File
		reader *bufio.Reader
		offset int64
		rest   []byte
	)

	closeFile := func() {
		if file != nil {
			_ = file.Close()
			file, reader = nil, nil
		}
	}
	defer closeFile()

	for {
		if file == nil {
			opened, err := os.Open(path)
			if err == nil {
				file, reader, offset, rest = opened, bufio.NewReaderSize(opened, 1<<16), 0, nil
			}
		} else if info, err := os.Stat(path); err == nil && info.Size() < offset {
			closeFile()
			continue
		}

		if reader != nil {
			var batch Batch
			for {
				chunk, err := reader.ReadBytes('\n')
				offset += int64(len(chunk))
				if err == io.EOF {
					// A partial line means the collector is mid-write. Hold it
					// and finish it on the next poll.
					rest = append(rest, chunk...)
					break
				}
				if err != nil {
					closeFile()
					break
				}
				full := chunk
				if len(rest) > 0 {
					full = append(rest, chunk...)
					rest = nil
				}
				one := Decode(full)
				batch.Spans = append(batch.Spans, one.Spans...)
				batch.Records = append(batch.Records, one.Records...)
			}
			if !batch.Empty() {
				select {
				case out <- batch:
				case <-stop:
					return
				}
			}
		}

		select {
		case <-stop:
			return
		case <-time.After(every):
		}
	}
}

// ReadAll decodes the whole file once, for the non-interactive paths.
func ReadAll(path string) (Batch, error) {
	file, err := os.Open(path)
	if err != nil {
		return Batch{}, err
	}
	defer file.Close()

	out := Batch{}
	lines := bufio.NewScanner(file)
	lines.Buffer(make([]byte, 1<<20), 1<<26)
	for lines.Scan() {
		one := Decode(lines.Bytes())
		out.Spans = append(out.Spans, one.Spans...)
		out.Records = append(out.Records, one.Records...)
	}
	return out, lines.Err()
}
