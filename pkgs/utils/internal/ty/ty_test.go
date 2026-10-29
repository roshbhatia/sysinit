package ty

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"reflect"
	"strings"
	"testing"
)

type callRecord struct {
	name  string
	args  []string
	stdin string
}

func runnerFor(t *testing.T, responses map[string][]byte) (commandRunner, *[]callRecord) {
	t.Helper()
	calls := []callRecord{}
	runner := func(_ context.Context, name string, args []string, stdin io.Reader) ([]byte, error) {
		var input []byte
		if stdin != nil {
			var err error
			input, err = io.ReadAll(stdin)
			if err != nil {
				return nil, err
			}
		}
		calls = append(calls, callRecord{name: name, args: append([]string(nil), args...), stdin: string(input)})
		key := name + " " + strings.Join(args, " ")
		response, ok := responses[key]
		if !ok {
			return nil, errors.New("unexpected command: " + key)
		}
		return response, nil
	}
	return runner, &calls
}

func TestCatalogCombinesSeshyAndWezTermJSON(t *testing.T) {
	runner, calls := runnerFor(t, map[string][]byte{
		"sy list --format json":                          []byte(`[{"id":"seshy:demo"}]`),
		"wezterm cli --no-auto-start list --format json": []byte(`[{"pane_id":12}]`),
	})
	var stdout, stderr bytes.Buffer
	if got := run([]string{"catalog"}, strings.NewReader(""), &stdout, &stderr, runner); got != 0 {
		t.Fatalf("run() = %d, stderr %q", got, stderr.String())
	}
	var result catalog
	if err := json.Unmarshal(stdout.Bytes(), &result); err != nil {
		t.Fatal(err)
	}
	if result.Version != protocolVersion || len(result.Sessions) != 1 || len(result.Panes) != 1 {
		t.Fatalf("unexpected catalog: %+v", result)
	}
	if len(*calls) != 2 || !reflect.DeepEqual((*calls)[1].args[:3], []string{"cli", "--no-auto-start", "list"}) {
		t.Fatalf("unexpected calls: %+v", *calls)
	}
}

func TestSessionsReturnsAJSONArrayWithoutContactingWezTerm(t *testing.T) {
	runner, calls := runnerFor(t, map[string][]byte{
		"sy list --format json": []byte(`[ {"id":"seshy:demo"} ]`),
	})
	var stdout, stderr bytes.Buffer
	if got := run([]string{"sessions"}, strings.NewReader(""), &stdout, &stderr, runner); got != 0 {
		t.Fatalf("run() = %d, stderr %q", got, stderr.String())
	}
	var result sessionsResult
	if err := json.Unmarshal(stdout.Bytes(), &result); err != nil {
		t.Fatal(err)
	}
	if result.Version != protocolVersion || len(result.Sessions) != 1 || len(*calls) != 1 {
		t.Fatalf("unexpected session list: %s, calls: %+v", stdout.String(), *calls)
	}
	var session map[string]string
	if err := json.Unmarshal(result.Sessions[0], &session); err != nil {
		t.Fatal(err)
	}
	if session["id"] != "seshy:demo" {
		t.Fatalf("unexpected session list: %s, calls: %+v", stdout.String(), *calls)
	}
}

func TestPanesReturnsVersionedWezTermList(t *testing.T) {
	runner, calls := runnerFor(t, map[string][]byte{
		"wezterm cli --no-auto-start list --format json": []byte(`[ {"pane_id":12} ]`),
	})
	var stdout, stderr bytes.Buffer
	if got := run([]string{"panes"}, strings.NewReader(""), &stdout, &stderr, runner); got != 0 {
		t.Fatalf("run() = %d, stderr %q", got, stderr.String())
	}
	var result panesResult
	if err := json.Unmarshal(stdout.Bytes(), &result); err != nil {
		t.Fatal(err)
	}
	if result.Version != protocolVersion || len(result.Panes) != 1 || len(*calls) != 1 {
		t.Fatalf("unexpected panes list: %+v, calls: %+v", result, *calls)
	}
}

func TestSessionOpenUsesSeshyPlanAndCreatesWorkspace(t *testing.T) {
	t.Setenv("SHELL", "/bin/zsh")
	runner, calls := runnerFor(t, map[string][]byte{
		"sy open seshy:demo --format json": []byte(`{"version":"seshy.open/v1","id":"seshy:demo","cwd":"/tmp/demo","command":[],"environment":{"SESHY_SESSION":"demo"}}`),
		"wezterm cli --no-auto-start spawn --new-window --workspace demo --cwd /tmp/demo -- env SESHY_SESSION=demo /bin/zsh -l": []byte("42\n"),
	})
	var stdout, stderr bytes.Buffer
	if got := run([]string{"session", "open", "seshy:demo"}, strings.NewReader(""), &stdout, &stderr, runner); got != 0 {
		t.Fatalf("run() = %d, stderr %q", got, stderr.String())
	}
	var result actionResult
	if err := json.Unmarshal(stdout.Bytes(), &result); err != nil {
		t.Fatal(err)
	}
	if result.Action != "session.open" || result.SessionID != "seshy:demo" || result.PaneID != "42" {
		t.Fatalf("unexpected open result: %+v", result)
	}
	if len(*calls) != 2 {
		t.Fatalf("got %d commands, want 2", len(*calls))
	}
}

func TestSessionOpenRejectsUnsupportedPlanBeforeSpawning(t *testing.T) {
	runner, calls := runnerFor(t, map[string][]byte{
		"sy open demo --format json": []byte(`{"version":"seshy.open/v2","id":"seshy:demo","cwd":"/tmp/demo"}`),
	})
	var stdout, stderr bytes.Buffer
	if got := run([]string{"session", "open", "demo"}, strings.NewReader(""), &stdout, &stderr, runner); got == 0 {
		t.Fatal("run() succeeded for an unsupported plan version")
	}
	if len(*calls) != 1 {
		t.Fatalf("unexpected commands after invalid plan: %+v", *calls)
	}
}

func TestSessionSwitchActivatesExistingWorkspacePane(t *testing.T) {
	runner, calls := runnerFor(t, map[string][]byte{
		"sy open demo --format json":                             []byte(`{"version":"seshy.open/v1","id":"seshy:demo","cwd":"/tmp/demo","command":[],"environment":{}}`),
		"wezterm cli --no-auto-start list --format json":         []byte(`[{"pane_id":42,"workspace":"demo"}]`),
		"wezterm cli --no-auto-start activate-pane --pane-id 42": nil,
	})
	var stdout, stderr bytes.Buffer
	if got := run([]string{"session", "switch", "demo"}, strings.NewReader(""), &stdout, &stderr, runner); got != 0 {
		t.Fatalf("run() = %d, stderr %q", got, stderr.String())
	}
	var result actionResult
	if err := json.Unmarshal(stdout.Bytes(), &result); err != nil {
		t.Fatal(err)
	}
	if result.Action != "session.switch" || result.PaneID != "42" || result.Opened == nil || *result.Opened {
		t.Fatalf("unexpected switch result: %+v", result)
	}
	if len(*calls) != 3 {
		t.Fatalf("unexpected calls: %+v", *calls)
	}
}

func TestPaneSendReadsStdinAndSubmitsOnlyWhenRequested(t *testing.T) {
	calls := []callRecord{}
	runner := func(_ context.Context, name string, args []string, stdin io.Reader) ([]byte, error) {
		var input []byte
		if stdin != nil {
			var err error
			input, err = io.ReadAll(stdin)
			if err != nil {
				return nil, err
			}
		}
		calls = append(calls, callRecord{name: name, args: append([]string(nil), args...), stdin: string(input)})
		return nil, nil
	}
	var stdout, stderr bytes.Buffer
	if got := run([]string{"pane", "send", "--submit", "9"}, strings.NewReader("review this"), &stdout, &stderr, runner); got != 0 {
		t.Fatalf("run() = %d, stderr %q", got, stderr.String())
	}
	if len(calls) != 2 || calls[0].stdin != "review this" {
		t.Fatalf("unexpected paste calls: %+v", calls)
	}
	if !reflect.DeepEqual(calls[1].args, []string{"cli", "--no-auto-start", "send-text", "--no-paste", "--pane-id", "9", "\r"}) {
		t.Fatalf("unexpected submit call: %+v", calls[1])
	}
	var result actionResult
	if err := json.Unmarshal(stdout.Bytes(), &result); err != nil {
		t.Fatal(err)
	}
	if result.Action != "pane.send" || result.PaneID != "9" {
		t.Fatalf("unexpected send result: %+v", result)
	}
}

func TestPaneReadWritesRawTerminalText(t *testing.T) {
	runner, _ := runnerFor(t, map[string][]byte{
		"wezterm cli --no-auto-start get-text --pane-id 12": []byte("hello\n"),
	})
	var stdout, stderr bytes.Buffer
	if got := run([]string{"pane", "read", "12"}, strings.NewReader(""), &stdout, &stderr, runner); got != 0 {
		t.Fatalf("run() = %d, stderr %q", got, stderr.String())
	}
	if stdout.String() != "hello\n" {
		t.Fatalf("stdout = %q, want raw pane text", stdout.String())
	}
}

func TestPaneSplitUsesExplicitPaneAndDirection(t *testing.T) {
	runner, calls := runnerFor(t, map[string][]byte{
		"wezterm cli --no-auto-start split-pane --pane-id 12 --bottom --cwd /tmp/demo": []byte("13\n"),
	})
	var stdout, stderr bytes.Buffer
	if got := run([]string{"pane", "split", "12", "--direction", "down", "--cwd", "/tmp/demo"}, strings.NewReader(""), &stdout, &stderr, runner); got != 0 {
		t.Fatalf("run() = %d, stderr %q", got, stderr.String())
	}
	if len(*calls) != 1 {
		t.Fatalf("unexpected calls: %+v", *calls)
	}
	var result actionResult
	if err := json.Unmarshal(stdout.Bytes(), &result); err != nil {
		t.Fatal(err)
	}
	if result.Action != "pane.split" || result.PaneID != "13" {
		t.Fatalf("unexpected split result: %+v", result)
	}
}

func TestPaneSpawnPassesCommandAsSeparateArguments(t *testing.T) {
	runner, calls := runnerFor(t, map[string][]byte{
		"wezterm cli --no-auto-start split-pane --pane-id 12 --right --cwd /tmp/demo -- codex --model gpt": []byte("13\n"),
	})
	var stdout, stderr bytes.Buffer
	if got := run([]string{"pane", "spawn", "12", "--direction", "right", "--cwd", "/tmp/demo", "--", "codex", "--model", "gpt"}, strings.NewReader(""), &stdout, &stderr, runner); got != 0 {
		t.Fatalf("run() = %d, stderr %q", got, stderr.String())
	}
	if len(*calls) != 1 {
		t.Fatalf("unexpected calls: %+v", *calls)
	}
	var result actionResult
	if err := json.Unmarshal(stdout.Bytes(), &result); err != nil {
		t.Fatal(err)
	}
	if result.Action != "pane.spawn" || result.PaneID != "13" {
		t.Fatalf("unexpected spawn result: %+v", result)
	}
}

func TestPaneCommandsRejectImplicitOrInvalidIdentifiers(t *testing.T) {
	runner, calls := runnerFor(t, nil)
	for _, args := range [][]string{
		{"pane", "read"},
		{"pane", "read", "-1"},
		{"pane", "focus", "not-a-pane"},
		{"pane", "send", "--submit"},
	} {
		var stdout, stderr bytes.Buffer
		if got := run(args, strings.NewReader(""), &stdout, &stderr, runner); got != 2 {
			t.Errorf("run(%v) = %d, want usage exit 2", args, got)
		}
	}
	if len(*calls) != 0 {
		t.Fatalf("invalid commands reached WezTerm: %+v", *calls)
	}
}

func TestOperationalErrorsUseExitCodeOne(t *testing.T) {
	runner := func(_ context.Context, name string, args []string, _ io.Reader) ([]byte, error) {
		return nil, errors.New(name + " unavailable: " + strings.Join(args, " "))
	}
	var stdout, stderr bytes.Buffer
	if got := run([]string{"sessions"}, strings.NewReader(""), &stdout, &stderr, runner); got != 1 {
		t.Fatalf("run() = %d, want operational error exit 1", got)
	}
}
