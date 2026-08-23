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
	case Claude, ExitCode, JSON:
		return format, rest, nil
	default:
		return "", nil, fmt.Errorf("unknown --format: %s; expected claude, exit-code, or json", format)
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
	Decision string `json:"decision"`
	Reason   string `json:"reason"`
}

// envelope is the JSON format: the Outcome itself, with no harness vocabulary.
type envelope struct {
	Decision     Kind           `json:"decision"`
	Event        string         `json:"event,omitempty"`
	Message      string         `json:"message,omitempty"`
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
			UpdatedInput: out.UpdatedInput,
		})
	default:
		return emitClaude(stdout, stderr, out)
	}
}

func emitExitCode(stderr io.Writer, out Outcome) int {
	switch out.Kind {
	case Deny, Block:
		fmt.Fprintln(stderr, out.Message)
		return 2
	case Context:
		if out.Message != "" {
			fmt.Fprintln(stderr, out.Message)
		}
		return 0
	default:
		return 0
	}
}

func emitClaude(stdout, stderr io.Writer, out Outcome) int {
	switch out.Kind {
	case Block:
		return write(stdout, stderr, claudeBlock{Decision: "block", Reason: out.Message})
	case Context:
		return write(stdout, stderr, claudeOutput{claudeHook{
			HookEventName:     out.Event,
			AdditionalContext: out.Message,
		}})
	default:
		return write(stdout, stderr, claudeOutput{claudeHook{
			HookEventName:            out.Event,
			PermissionDecision:       string(out.Kind),
			PermissionDecisionReason: out.Message,
			UpdatedInput:             out.UpdatedInput,
		}})
	}
}

func write(stdout, stderr io.Writer, v any) int {
	encoded, err := json.Marshal(v)
	if err != nil {
		fmt.Fprintln(stderr, err)
		return 1
	}
	fmt.Fprintln(stdout, string(encoded))
	return 0
}
