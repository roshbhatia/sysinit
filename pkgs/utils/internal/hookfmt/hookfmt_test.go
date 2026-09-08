package hookfmt

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"
)

func emit(t *testing.T, format Format, outcome Outcome) (string, string, int) {
	t.Helper()
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	code := EmitTo(&stdout, &stderr, format, outcome)
	return stdout.String(), stderr.String(), code
}

func TestParseFormat(t *testing.T) {
	format, rest, err := ParseFormat([]string{"--rules", "rules.json", "--format", "json"}, Claude)
	if err != nil {
		t.Fatalf("ParseFormat: %v", err)
	}
	if format != JSON || strings.Join(rest, " ") != "--rules rules.json" {
		t.Fatalf("got format %q and rest %v", format, rest)
	}
	for _, args := range [][]string{{"--format"}, {"--format", "yaml"}} {
		if _, _, err := ParseFormat(args, Claude); err == nil {
			t.Fatalf("ParseFormat accepted %v", args)
		}
	}
}

func TestPassIsSilent(t *testing.T) {
	for _, format := range []Format{Claude, ExitCode, JSON} {
		stdout, stderr, code := emit(t, format, PassOutcome())
		if stdout != "" || stderr != "" || code != 0 {
			t.Fatalf("%s pass wrote stdout=%q stderr=%q with code %d", format, stdout, stderr, code)
		}
	}
}

func TestClaudeEncodesEveryOutcome(t *testing.T) {
	cases := []struct {
		out  Outcome
		want string
	}{
		{Outcome{Kind: Deny, Event: "PreToolUse", Message: "stop"}, `"permissionDecision":"deny"`},
		{Outcome{Kind: Block, Event: "Stop", Message: "retry"}, `"decision":"block"`},
		{Outcome{Kind: Context, Event: "PostToolUse", Message: "lint"}, `"additionalContext":"lint"`},
		{Outcome{Kind: Allow, Event: "PreToolUse", UpdatedInput: map[string]any{"command": "bounded"}}, `"updatedInput"`},
	}
	for _, test := range cases {
		stdout, stderr, code := emit(t, Claude, test.out)
		if code != 0 || stderr != "" || !strings.Contains(stdout, test.want) {
			t.Fatalf("%s encoded stdout=%q stderr=%q with code %d", test.out.Kind, stdout, stderr, code)
		}
	}
}

func TestExitCodeAndJSONFormats(t *testing.T) {
	outcome := Outcome{Kind: Deny, Event: "PreToolUse", Message: "stop"}
	stdout, stderr, code := emit(t, ExitCode, outcome)
	if stdout != "" || strings.TrimSpace(stderr) != "stop" || code != 2 {
		t.Fatalf("exit-code deny wrote stdout=%q stderr=%q with code %d", stdout, stderr, code)
	}

	stdout, stderr, code = emit(t, JSON, outcome)
	if stderr != "" || code != 0 {
		t.Fatalf("json deny wrote stderr=%q with code %d", stderr, code)
	}
	var decoded envelope
	if err := json.Unmarshal([]byte(stdout), &decoded); err != nil {
		t.Fatalf("JSON output: %v", err)
	}
	if decoded.Decision != Deny || decoded.Event != "PreToolUse" || decoded.Message != "stop" {
		t.Fatalf("JSON output = %+v", decoded)
	}
}

func TestContextReachesTheModelOnEveryChannel(t *testing.T) {
	allow := Outcome{
		Kind:         Allow,
		Event:        "PreToolUse",
		Message:      "for the user",
		Context:      "output capped",
		UpdatedInput: map[string]any{"command": "bounded"},
	}
	stdout, _, code := emit(t, Claude, allow)
	if code != 0 || !strings.Contains(stdout, `"additionalContext":"output capped"`) ||
		!strings.Contains(stdout, `"permissionDecision":"allow"`) {
		t.Fatalf("claude allow with context = %q", stdout)
	}

	deny := Outcome{Kind: Deny, Event: "PreToolUse", Message: "blocked", Context: "use ask"}
	stdout, _, _ = emit(t, Claude, deny)
	if !strings.Contains(stdout, `"permissionDecisionReason":"blocked"`) ||
		!strings.Contains(stdout, `"additionalContext":"use ask"`) {
		t.Fatalf("claude deny with context = %q", stdout)
	}

	block := Outcome{Kind: Block, Event: "PostToolUse", Message: "fix", Context: "note"}
	stdout, _, _ = emit(t, Claude, block)
	if !strings.Contains(stdout, `"decision":"block"`) || !strings.Contains(stdout, `"additionalContext":"note"`) {
		t.Fatalf("claude block with context = %q", stdout)
	}

	stdout, stderr, code := emit(t, ExitCode, allow)
	if stdout != "" || strings.TrimSpace(stderr) != "output capped" || code != 0 {
		t.Fatalf("exit-code allow with context wrote stdout=%q stderr=%q code %d", stdout, stderr, code)
	}

	stdout, _, _ = emit(t, JSON, allow)
	var decoded envelope
	if err := json.Unmarshal([]byte(stdout), &decoded); err != nil {
		t.Fatal(err)
	}
	if decoded.Context != "output capped" || decoded.UpdatedInput["command"] != "bounded" {
		t.Fatalf("json allow with context = %+v", decoded)
	}
}

func TestProviderFramesRoundTrip(t *testing.T) {
	frame := `{"version":"provider/v1","kind":"request","requestId":"r1","capability":"gate.decide",` +
		`"input":{"event":{"event":"Stop","raw":{"last_assistant_message":"hi","session_id":"s"}},"args":{"mode":"check"}}}`
	request, err := ReadProviderRequest(strings.NewReader(frame))
	if err != nil {
		t.Fatal(err)
	}
	if request.Input.Event.Event != "Stop" || request.Input.Args["mode"] != "check" || !strings.Contains(string(request.Input.Event.Raw), "hi") {
		t.Fatalf("request = %+v", request)
	}
	var stdout, stderr bytes.Buffer
	if code := EmitProviderTo(&stdout, &stderr, "r1", Outcome{Kind: Context, Message: "note"}); code != 0 || stderr.Len() != 0 {
		t.Fatalf("emit code %d stderr %q", code, stderr.String())
	}
	var result providerResult
	if err := json.Unmarshal(stdout.Bytes(), &result); err != nil {
		t.Fatal(err)
	}
	if result.Kind != "result" || result.RequestID != "r1" || result.Output.Decision != Context || result.Output.Message != "note" {
		t.Fatalf("result = %+v", result)
	}
	if _, err := ReadProviderRequest(strings.NewReader(`{"version":"provider/v1","kind":"request","capability":"inference.generate"}`)); err == nil {
		t.Fatal("a foreign capability was accepted")
	}
}
