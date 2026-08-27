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
