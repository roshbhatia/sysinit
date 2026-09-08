// Package hookfmt encodes a gate's decision for one harness.
//
// Every gate here used to write Claude Code's hook JSON inline, so the decision
// and the wire shape were the same code and no other harness could call one.
// A gate now returns an Outcome and this package turns it into bytes.
package hookfmt

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
)

type Format string

const (
	// Claude is Claude Code's hook JSON on stdout, always exit 0.
	Claude Format = "claude"
	// ExitCode carries the message on stderr and the verdict in the status.
	ExitCode Format = "exit-code"
	// JSON is the harness-agnostic envelope an adapter can read.
	JSON Format = "json"
	// Provider is the gate dispatcher's provider/v1 frames: a request on stdin
	// carrying the harness payload as `input.event.raw`, a result frame on
	// stdout carrying the outcome. A gate that speaks this is a chain step.
	Provider Format = "provider"
)

type Kind string

const (
	Pass    Kind = "pass"
	Deny    Kind = "deny"
	Allow   Kind = "allow"
	Block   Kind = "block"
	Context Kind = "context"
)

// Outcome is what a gate decided, with no harness in it.
type Outcome struct {
	Kind Kind
	// Event names the hook point. Only the Claude encoder reads it.
	Event   string
	Message string
	// UpdatedInput rewrites the tool call. Only Claude and JSON carry it; the
	// exit-code channel has no way to hand an input back, so an Allow that
	// rewrites passes silently there rather than claiming a rewrite that did
	// not happen.
	UpdatedInput map[string]any
	// Context is a note the model reads, riding beside any decision. Message
	// is not that: on an allow, Claude Code shows permissionDecisionReason to
	// the user and not to Claude, so a gate that rewrote the input and said so
	// only in Message was silent where it mattered. Put what the model must
	// know here.
	Context string
}

func PassOutcome() Outcome { return Outcome{Kind: Pass} }

// ParseFormat pulls `--format <name>` out of args and returns the rest.
func ParseFormat(args []string, fallback Format) (Format, []string, error) {
	format := fallback
	rest := make([]string, 0, len(args))
	for i := 0; i < len(args); i++ {
		if args[i] != "--format" {
			rest = append(rest, args[i])
			continue
		}
		if i+1 >= len(args) {
			return "", nil, fmt.Errorf("--format needs a value")
		}
		format = Format(args[i+1])
		i++
	}
	switch format {
	case Claude, ExitCode, JSON, Provider:
		return format, rest, nil
	default:
		return "", nil, fmt.Errorf("unknown --format: %s; expected claude, exit-code, json, or provider", format)
	}
}

type claudeHook struct {
	HookEventName            string         `json:"hookEventName"`
	PermissionDecision       string         `json:"permissionDecision,omitempty"`
	PermissionDecisionReason string         `json:"permissionDecisionReason,omitempty"`
	AdditionalContext        string         `json:"additionalContext,omitempty"`
	UpdatedInput             map[string]any `json:"updatedInput,omitempty"`
}

type claudeOutput struct {
	HookSpecificOutput claudeHook `json:"hookSpecificOutput"`
}

type claudeBlock struct {
	Decision           string      `json:"decision"`
	Reason             string      `json:"reason"`
	HookSpecificOutput *claudeHook `json:"hookSpecificOutput,omitempty"`
}

// envelope is the JSON format: the Outcome itself, with no harness vocabulary.
type envelope struct {
	Decision     Kind           `json:"decision"`
	Event        string         `json:"event,omitempty"`
	Message      string         `json:"message,omitempty"`
	Context      string         `json:"context,omitempty"`
	UpdatedInput map[string]any `json:"updatedInput,omitempty"`
}

// Emit writes the outcome in the given format and returns the exit status.
func Emit(format Format, out Outcome) int {
	return EmitTo(os.Stdout, os.Stderr, format, out)
}

func EmitTo(stdout, stderr io.Writer, format Format, out Outcome) int {
	if out.Kind == Pass || out.Kind == "" {
		return 0
	}
	switch format {
	case ExitCode:
		return emitExitCode(stderr, out)
	case JSON:
		return write(stdout, stderr, envelope{
			Decision:     out.Kind,
			Event:        out.Event,
			Message:      out.Message,
			Context:      out.Context,
			UpdatedInput: out.UpdatedInput,
		})
	default:
		return emitClaude(stdout, stderr, out)
	}
}

// emitExitCode has one channel, stderr, and it reaches the user rather than the
// model. A deny carries its message there with exit 2. Anything else prints the
// note it has, so a rewrite or a cap is at least visible to the person watching.
func emitExitCode(stderr io.Writer, out Outcome) int {
	switch out.Kind {
	case Deny, Block:
		if _, err := fmt.Fprintln(stderr, out.Message); err != nil {
			return 1
		}
		return 2
	case Context:
		if out.Message != "" {
			if _, err := fmt.Fprintln(stderr, out.Message); err != nil {
				return 1
			}
		}
		return 0
	default:
		if out.Context != "" {
			if _, err := fmt.Fprintln(stderr, out.Context); err != nil {
				return 1
			}
		}
		return 0
	}
}

func emitClaude(stdout, stderr io.Writer, out Outcome) int {
	switch out.Kind {
	case Block:
		block := claudeBlock{Decision: "block", Reason: out.Message}
		if out.Context != "" {
			block.HookSpecificOutput = &claudeHook{
				HookEventName:     out.Event,
				AdditionalContext: out.Context,
			}
		}
		return write(stdout, stderr, block)
	case Context:
		return write(stdout, stderr, claudeOutput{claudeHook{
			HookEventName:     out.Event,
			AdditionalContext: out.Message,
		}})
	default:
		// additionalContext is honored beside permissionDecision on PreToolUse,
		// and it is the only field of the two that Claude reads on an allow.
		return write(stdout, stderr, claudeOutput{claudeHook{
			HookEventName:            out.Event,
			PermissionDecision:       string(out.Kind),
			PermissionDecisionReason: out.Message,
			AdditionalContext:        out.Context,
			UpdatedInput:             out.UpdatedInput,
		}})
	}
}

func write(stdout, stderr io.Writer, v any) int {
	encoded, err := json.Marshal(v)
	if err != nil {
		_, _ = fmt.Fprintln(stderr, err)
		return 1
	}
	if _, err := fmt.Fprintln(stdout, string(encoded)); err != nil {
		return 1
	}
	return 0
}

// ProviderRequest is what the gate dispatcher writes to a provider's stdin: one
// provider/v1 request frame whose input is the event and the chain step's
// arguments. Only the fields a gate here reads are named; the raw harness
// payload rides along so the existing decision functions parse what they
// always parsed.
type ProviderRequest struct {
	Version    string `json:"version"`
	Kind       string `json:"kind"`
	RequestID  string `json:"requestId"`
	Capability string `json:"capability"`
	Input      struct {
		Event struct {
			Event string          `json:"event"`
			Tool  string          `json:"tool"`
			Raw   json.RawMessage `json:"raw"`
		} `json:"event"`
		Args map[string]any `json:"args"`
	} `json:"input"`
}

// ReadProviderRequest decodes the request frame and checks it is a gate.decide.
func ReadProviderRequest(stdin io.Reader) (ProviderRequest, error) {
	var request ProviderRequest
	if err := json.NewDecoder(stdin).Decode(&request); err != nil {
		return request, fmt.Errorf("decode provider request: %w", err)
	}
	if request.Version != "provider/v1" || request.Kind != "request" {
		return request, fmt.Errorf("unsupported provider frame %s/%s", request.Version, request.Kind)
	}
	if request.Capability != "gate.decide" {
		return request, fmt.Errorf("unsupported capability %q", request.Capability)
	}
	return request, nil
}

type providerResult struct {
	Version   string   `json:"version"`
	Kind      string   `json:"kind"`
	RequestID string   `json:"requestId"`
	Status    string   `json:"status"`
	Output    envelope `json:"output"`
}

// EmitProvider writes the result frame for one decision. A pass is a frame
// too: the dispatcher needs an answer from every step it ran.
func EmitProvider(requestID string, out Outcome) int {
	return EmitProviderTo(os.Stdout, os.Stderr, requestID, out)
}

// EmitProviderTo is EmitProvider over explicit streams.
func EmitProviderTo(stdout, stderr io.Writer, requestID string, out Outcome) int {
	kind := out.Kind
	if kind == "" {
		kind = Pass
	}
	return write(stdout, stderr, providerResult{
		Version: "provider/v1", Kind: "result", RequestID: requestID, Status: "ok",
		Output: envelope{Decision: kind, Message: out.Message, Context: out.Context, UpdatedInput: out.UpdatedInput},
	})
}
