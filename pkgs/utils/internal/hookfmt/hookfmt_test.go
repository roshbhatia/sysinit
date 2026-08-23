package hookfmt

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"
)

func emit(t *testing.T, format Format, out Outcome) (string, string, int) {
	t.Helper()
	var stdout, stderr bytes.Buffer
	code := EmitTo(&stdout, &stderr, format, out)
	return stdout.String(), stderr.String(), code
}

func TestParseFormatDefaults(t *testing.T) {
	format, rest, err := ParseFormat([]string{"--rules", "x"}, Claude)
	if err != nil {
		t.Fatalf("ParseFormat: %v", err)
	}
	if format != Claude {
		t.Errorf("format = %q, want claude", format)
	}
	if strings.Join(rest, " ") != "--rules x" {
		t.Errorf("rest = %v, want the untouched arguments", rest)
	}
}

func TestParseFormatSelects(t *testing.T) {
	for _, want := range []Format{Claude, ExitCode, JSON} {
		format, rest, err := ParseFormat([]string{"--format", string(want)}, Claude)
		if err != nil {
			t.Fatalf("--format %s: %v", want, err)
		}
		if format != want {
			t.Errorf("format = %q, want %q", format, want)
		}
		if len(rest) != 0 {
			t.Errorf("--format left %v behind", rest)
		}
	}
}

func TestParseFormatRejectsUnknown(t *testing.T) {
	if _, _, err := ParseFormat([]string{"--format", "yaml"}, Claude); err == nil {
		t.Fatal("an unknown format was accepted")
	}
	if _, _, err := ParseFormat([]string{"--format"}, Claude); err == nil {
		t.Fatal("a valueless --format was accepted")
	}
}

func TestPassIsSilentInEveryFormat(t *testing.T) {
	for _, format := range []Format{Claude, ExitCode, JSON} {
		stdout, stderr, code := emit(t, format, PassOutcome())
		if stdout != "" || stderr != "" || code != 0 {
			t.Errorf("%s pass: stdout=%q stderr=%q code=%d", format, stdout, stderr, code)
		}
	}
}

func TestDenyPerFormat(t *testing.T) {
	out := Outcome{Kind: Deny, Event: "PreToolUse", Message: "no"}

	stdout, _, code := emit(t, Claude, out)
	if code != 0 {
		t.Errorf("claude deny exited %d, want 0", code)
	}
	var claude struct {
		HookSpecificOutput struct {
			HookEventName            string `json:"hookEventName"`
			PermissionDecision       string `json:"permissionDecision"`
			PermissionDecisionReason string `json:"permissionDecisionReason"`
		} `json:"hookSpecificOutput"`
	}
	if err := json.Unmarshal([]byte(stdout), &claude); err != nil {
		t.Fatalf("claude deny is not JSON: %v (%q)", err, stdout)
	}
	if claude.HookSpecificOutput.PermissionDecision != "deny" {
		t.Errorf("permissionDecision = %q", claude.HookSpecificOutput.PermissionDecision)
	}
	if claude.HookSpecificOutput.PermissionDecisionReason != "no" {
		t.Errorf("reason = %q", claude.HookSpecificOutput.PermissionDecisionReason)
	}
	if claude.HookSpecificOutput.HookEventName != "PreToolUse" {
		t.Errorf("hookEventName = %q", claude.HookSpecificOutput.HookEventName)
	}

	stdout, stderr, code := emit(t, ExitCode, out)
	if code != 2 {
		t.Errorf("exit-code deny exited %d, want 2", code)
	}
	if strings.TrimSpace(stderr) != "no" {
		t.Errorf("exit-code deny stderr = %q", stderr)
	}
	if stdout != "" {
		t.Errorf("exit-code deny wrote %q to stdout", stdout)
	}

	stdout, _, code = emit(t, JSON, out)
	if code != 0 {
		t.Errorf("json deny exited %d, want 0", code)
	}
	var env envelope
	if err := json.Unmarshal([]byte(stdout), &env); err != nil {
		t.Fatalf("json deny is not JSON: %v (%q)", err, stdout)
	}
	if env.Decision != Deny || env.Message != "no" || env.Event != "PreToolUse" {
		t.Errorf("json deny = %+v", env)
	}
}

func TestAllowCarriesUpdatedInputOnlyWhereItCanBeRead(t *testing.T) {
	out := Outcome{
		Kind:         Allow,
		Event:        "PreToolUse",
		Message:      "capped",
		UpdatedInput: map[string]any{"command": "cat x | head -c 16384"},
	}

	stdout, _, _ := emit(t, Claude, out)
	if !strings.Contains(stdout, `"updatedInput"`) {
		t.Errorf("claude allow dropped updatedInput: %q", stdout)
	}

	stdout, _, code := emit(t, JSON, out)
	if code != 0 || !strings.Contains(stdout, `"updatedInput"`) {
		t.Errorf("json allow dropped updatedInput: %q", stdout)
	}

	// The exit-code channel cannot hand an input back, so it stays silent
	// rather than reporting a rewrite that did not happen.
	stdout, stderr, code := emit(t, ExitCode, out)
	if stdout != "" || stderr != "" || code != 0 {
		t.Errorf("exit-code allow: stdout=%q stderr=%q code=%d", stdout, stderr, code)
	}
}

func TestBlockPerFormat(t *testing.T) {
	out := Outcome{Kind: Block, Event: "Stop", Message: "try again"}

	stdout, _, code := emit(t, Claude, out)
	var claude struct {
		Decision string `json:"decision"`
		Reason   string `json:"reason"`
	}
	if err := json.Unmarshal([]byte(stdout), &claude); err != nil {
		t.Fatalf("claude block is not JSON: %v (%q)", err, stdout)
	}
	if claude.Decision != "block" || claude.Reason != "try again" || code != 0 {
		t.Errorf("claude block = %+v, code %d", claude, code)
	}

	_, stderr, code := emit(t, ExitCode, out)
	if code != 2 || strings.TrimSpace(stderr) != "try again" {
		t.Errorf("exit-code block: stderr=%q code=%d", stderr, code)
	}

	stdout, _, code = emit(t, JSON, out)
	var env envelope
	if err := json.Unmarshal([]byte(stdout), &env); err != nil {
		t.Fatalf("json block is not JSON: %v (%q)", err, stdout)
	}
	if env.Decision != Block || code != 0 {
		t.Errorf("json block = %+v, code %d", env, code)
	}
}

func TestContextPerFormat(t *testing.T) {
	out := Outcome{Kind: Context, Event: "PostToolUse", Message: "lint failed"}

	stdout, _, code := emit(t, Claude, out)
	if code != 0 || !strings.Contains(stdout, `"additionalContext":"lint failed"`) {
		t.Errorf("claude context = %q, code %d", stdout, code)
	}
	if !strings.Contains(stdout, `"hookEventName":"PostToolUse"`) {
		t.Errorf("claude context lost the event name: %q", stdout)
	}

	// Advisory, so it reaches the model on stderr without failing the hook.
	_, stderr, code := emit(t, ExitCode, out)
	if code != 0 || strings.TrimSpace(stderr) != "lint failed" {
		t.Errorf("exit-code context: stderr=%q code=%d", stderr, code)
	}

	stdout, _, code = emit(t, JSON, out)
	var env envelope
	if err := json.Unmarshal([]byte(stdout), &env); err != nil {
		t.Fatalf("json context is not JSON: %v (%q)", err, stdout)
	}
	if env.Decision != Context || env.Message != "lint failed" || code != 0 {
		t.Errorf("json context = %+v, code %d", env, code)
	}
}
