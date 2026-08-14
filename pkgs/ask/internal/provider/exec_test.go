package provider

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// fake puts a script on PATH under the name a provider looks for, so a run can be exercised
// end to end without a model behind it. The script writes its arguments and its stdin to
// files the test reads back.
func fake(t *testing.T, name, body string) string {
	t.Helper()
	dir := t.TempDir()
	path := filepath.Join(dir, name)
	script := "#!/bin/sh\n" +
		"printf '%s\\n' \"$@\" > " + filepath.Join(dir, "args") + "\n" +
		"cat > " + filepath.Join(dir, "stdin") + "\n" +
		body
	if err := os.WriteFile(path, []byte(script), 0o755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PATH", dir+string(os.PathListSeparator)+os.Getenv("PATH"))
	return dir
}

// drain reads a run to its end and returns the result it finished with.
func drain(t *testing.T, events <-chan Event) *Result {
	t.Helper()
	var result *Result
	for event := range events {
		if event.Kind == Done {
			result = event.Result
		}
	}
	if result == nil {
		t.Fatal("the run ended with no result at all")
	}
	return result
}

func TestAClaudeRunReachesTheBinaryAndReadsItBack(t *testing.T) {
	dir := fake(t, "claude", `echo '{"type":"result","subtype":"success","result":"the answer","num_turns":2,"total_cost_usd":0.5}'`+"\n")

	events, err := Claude{}.Run(context.Background(), Request{
		Prompt:  "summarise this",
		Input:   []byte("piped in"),
		Model:   "opus",
		Timeout: time.Minute,
	})
	if err != nil {
		t.Fatal(err)
	}
	result := drain(t, events)

	if result.Failed {
		t.Fatalf("the run failed: %s", result.Reason)
	}
	if result.Text != "the answer" || result.Turns != 2 || result.CostUSD != 0.5 {
		t.Errorf("the result is %+v", result)
	}

	// What is piped in has to reach the model, since that is the whole point of the command.
	stdin, err := os.ReadFile(filepath.Join(dir, "stdin"))
	if err != nil {
		t.Fatal(err)
	}
	if string(stdin) != "piped in" {
		t.Errorf("the binary was given %q on stdin", stdin)
	}

	raw, err := os.ReadFile(filepath.Join(dir, "args"))
	if err != nil {
		t.Fatal(err)
	}
	args := strings.Split(strings.TrimRight(string(raw), "\n"), "\n")
	// Last, and behind a separator: a prompt that opens with a dash is otherwise read by
	// claude as a flag of its own, and the run dies before the model sees it.
	if args[len(args)-1] != "summarise this" {
		t.Errorf("the prompt is not the last argument: %v", args)
	}
	if args[len(args)-2] != "--" {
		t.Errorf("the prompt is not behind a separator: %v", args)
	}
	for _, want := range []string{"--print", "stream-json", "--dangerously-skip-permissions", "opus"} {
		if !has(args, want) {
			t.Errorf("the arguments %v do not carry %q", args, want)
		}
	}
}

// A run that dies has only what it wrote to stderr to say why, so that is reported rather
// than swallowed behind an empty answer.
func TestAClaudeRunThatDiesReportsWhatItWroteToStderr(t *testing.T) {
	fake(t, "claude", "echo 'the credentials expired' >&2\nexit 1\n")

	events, err := Claude{}.Run(context.Background(), Request{Prompt: "hi", Timeout: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	result := drain(t, events)

	if !result.Failed {
		t.Fatal("a run that exited 1 was reported as an answer")
	}
	if !strings.Contains(result.Reason, "the credentials expired") {
		t.Errorf("the reason is %q", result.Reason)
	}
}

// A run that says nothing at all still has to end in a failure rather than a silence the
// caller has to interpret.
func TestAClaudeRunThatSaysNothingStillEnds(t *testing.T) {
	fake(t, "claude", "exit 0\n")

	events, err := Claude{}.Run(context.Background(), Request{Prompt: "hi", Timeout: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	if result := drain(t, events); !result.Failed || result.Reason == "" {
		t.Errorf("a silent run gave %+v", result)
	}
}

func TestACodexRunReachesTheBinaryAndReadsItBack(t *testing.T) {
	dir := fake(t, "codex", `echo '{"type":"item.completed","item":{"id":"a","type":"agent_message","text":"the answer"}}'`+"\n")

	events, err := Codex{}.Run(context.Background(), Request{
		Prompt:  "summarise this",
		Input:   []byte("piped in"),
		Timeout: time.Minute,
	})
	if err != nil {
		t.Fatal(err)
	}
	result := drain(t, events)

	if result.Failed {
		t.Fatalf("the run failed: %s", result.Reason)
	}
	if result.Text != "the answer" {
		t.Errorf("the result is %+v", result)
	}

	raw, err := os.ReadFile(filepath.Join(dir, "args"))
	if err != nil {
		t.Fatal(err)
	}
	args := strings.Split(strings.TrimRight(string(raw), "\n"), "\n")
	// A caller pipes from wherever they are, and codex otherwise refuses to leave a repo.
	for _, want := range []string{"exec", "--json", "--skip-git-repo-check"} {
		if !has(args, want) {
			t.Errorf("the arguments %v do not carry %q", args, want)
		}
	}
	// Last, and behind a separator, for the same reason claude's is.
	if args[len(args)-1] != "summarise this" || args[len(args)-2] != "--" {
		t.Errorf("the prompt is not behind a separator at the end: %v", args)
	}
}

// The schema goes to codex as a path, and the file has to be gone once the run is over
// rather than left in the temp directory for every run ever made.
func TestACodexRunRemovesItsSchemaFileWhenItEnds(t *testing.T) {
	dir := fake(t, "codex", `echo '{"type":"item.completed","item":{"id":"a","type":"agent_message","text":"{\"a\":1}"}}'`+"\n")

	events, err := Codex{}.Run(context.Background(), Request{
		Prompt:  "hi",
		Schema:  map[string]any{"type": "object"},
		Timeout: time.Minute,
	})
	if err != nil {
		t.Fatal(err)
	}
	if result := drain(t, events); result.Failed {
		t.Fatalf("the run failed: %s", result.Reason)
	}

	raw, err := os.ReadFile(filepath.Join(dir, "args"))
	if err != nil {
		t.Fatal(err)
	}
	args := strings.Split(strings.TrimRight(string(raw), "\n"), "\n")
	at := indexIn(args, "--output-schema")
	if at < 0 || at+1 >= len(args) {
		t.Fatalf("the arguments %v carry no schema path", args)
	}
	if _, err := os.Stat(args[at+1]); !os.IsNotExist(err) {
		t.Errorf("the schema file %s outlived the run", args[at+1])
	}
}

// Prose where a shape was asked for is a failed run, so a caller reading stdout never gets
// something that is not the shape they asked for.
func TestACodexRunThatAnswersOutsideTheShapeFails(t *testing.T) {
	fake(t, "codex", `echo '{"type":"item.completed","item":{"id":"a","type":"agent_message","text":"just prose"}}'`+"\n")

	events, err := Codex{}.Run(context.Background(), Request{
		Prompt:  "hi",
		Schema:  map[string]any{"type": "object"},
		Timeout: time.Minute,
	})
	if err != nil {
		t.Fatal(err)
	}
	result := drain(t, events)
	if !result.Failed || result.Reason != offShape {
		t.Errorf("prose passed for a shape: %+v", result)
	}
}

// A missing binary is said plainly and at once, rather than as a failure inside a run that
// looked like it had started.
func TestAMissingBinaryIsReportedBeforeAnythingStarts(t *testing.T) {
	t.Setenv("PATH", t.TempDir())

	for _, agent := range []Provider{Claude{}, Codex{}} {
		_, err := agent.Run(context.Background(), Request{Prompt: "hi", Timeout: time.Minute})
		if err == nil {
			t.Fatalf("%s ran with no binary on PATH", agent.Name())
		}
		if !strings.Contains(err.Error(), agent.Name()) {
			t.Errorf("the error %q does not name %s", err, agent.Name())
		}
	}
}

func has(args []string, want string) bool {
	return indexIn(args, want) >= 0
}

func indexIn(args []string, want string) int {
	for at, arg := range args {
		if arg == want {
			return at
		}
	}
	return -1
}
