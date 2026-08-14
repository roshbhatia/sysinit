package main

import (
	"strings"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/ask/internal/provider"
	"github.com/roshbhatia/sysinit/pkgs/ask/internal/store"
)

// read parses the arguments or fails the test saying which ones.
func read(t *testing.T, args ...string) options {
	t.Helper()
	opts, err := parse(args)
	if err != nil {
		t.Fatalf("%v: %v", args, err)
	}
	return opts
}

// The prompt is bare words after the flags, so the common case needs no quoting and no `--`.
func TestThePromptIsTheBareWordsAfterTheFlags(t *testing.T) {
	if got := read(t, "summarise", "this", "file").prompt; got != "summarise this file" {
		t.Errorf("the prompt is %q", got)
	}
	if got := read(t, "-o", "--", "classify", "this").prompt; got != "classify this" {
		t.Errorf("after a flag the prompt is %q", got)
	}
}

// Everything after a bare `--` is the prompt, whatever it looks like, or a prompt about
// flags could never be written.
func TestEverythingAfterADoubleDashIsThePrompt(t *testing.T) {
	opts := read(t, "--", "what", "does", "--json", "do")
	if opts.prompt != "what does --json do" {
		t.Errorf("the prompt is %q", opts.prompt)
	}
	if opts.json {
		t.Error("a flag inside the prompt was read as a flag")
	}
}

func TestEveryFlagIsRead(t *testing.T) {
	opts := read(t, "-j", "-q", "--replay", "-m", "opus", "-s", "a:string", "--timeout", "30s", "hi")
	if !opts.json || !opts.quiet || !opts.replay {
		t.Errorf("the switches are %+v", opts)
	}
	if opts.model != "opus" || opts.spec != "a:string" {
		t.Errorf("the values are %+v", opts)
	}
	if opts.timeout != 30*time.Second {
		t.Errorf("the timeout is %v", opts.timeout)
	}
	if opts.prompt != "hi" {
		t.Errorf("the prompt is %q", opts.prompt)
	}
}

func TestAProviderIsPickedByItsLetterOrItsName(t *testing.T) {
	for _, one := range []struct {
		args []string
		want string
	}{
		{[]string{"hi"}, ""},
		{[]string{"-c", "hi"}, "claude"},
		{[]string{"-o", "hi"}, "codex"},
		{[]string{"--provider", "codex", "hi"}, "codex"},
	} {
		if got := read(t, one.args...).provider; got != one.want {
			t.Errorf("%v picked %q, want %q", one.args, got, one.want)
		}
	}
}

func TestAFlagWithNoValueIsRejected(t *testing.T) {
	for _, flag := range []string{"-m", "-s", "--provider", "--timeout"} {
		if _, err := parse([]string{flag}); err == nil {
			t.Errorf("%s was accepted with no value", flag)
		}
	}
}

func TestATimeoutThatIsNotADurationIsRejected(t *testing.T) {
	if _, err := parse([]string{"--timeout", "soon", "hi"}); err == nil {
		t.Error("a timeout that is not a duration was accepted")
	}
}

// A leading flag no one knows is a typo, and running the prompt anyway would spend a model
// call on it.
func TestAFlagNoOneKnowsIsRejected(t *testing.T) {
	_, err := parse([]string{"--nope", "hi"})
	if err == nil {
		t.Fatal("an unknown flag was accepted")
	}
	if !strings.Contains(err.Error(), "--nope") {
		t.Errorf("the error %q does not name the flag", err)
	}
}

// Once the prompt has started, a word that looks like a flag belongs to it: `ask what does -v
// mean` is a question, not a mistake.
func TestAFlagInsideThePromptStaysInThePrompt(t *testing.T) {
	if got := read(t, "what", "does", "-v", "mean").prompt; got != "what does -v mean" {
		t.Errorf("the prompt is %q", got)
	}
}

func TestTheTimeoutHasADefault(t *testing.T) {
	if got := read(t, "hi").timeout; got != 10*time.Minute {
		t.Errorf("the default timeout is %v", got)
	}
}

func TestHelpEndsTheParseWhereverItAppears(t *testing.T) {
	if got := read(t, "-o", "--help", "ignored").show; got != "help" {
		t.Errorf("--help set show to %q", got)
	}
}

func TestEachSavedPieceIsAskedForByName(t *testing.T) {
	for _, one := range []struct {
		flag string
		want string
	}{
		{"--show-input", "input"},
		{"--show-prompt", "prompt"},
		{"--show-output", "output"},
	} {
		if got := read(t, one.flag).show; got != one.want {
			t.Errorf("%s set show to %q, want %q", one.flag, got, one.want)
		}
	}
}

// Indented, because the common next step is a person reading it and `jq` does not mind.
func TestAStructuredAnswerIsPrintedAsIndentedJSON(t *testing.T) {
	got, err := answer(&provider.Result{
		Text:       "ignored",
		Structured: map[string]any{"level": "error"},
	}, true)
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != "{\n  \"level\": \"error\"\n}" {
		t.Errorf("the answer is %q", got)
	}
}

// The answer is the only thing on stdout, so the trailing newline of a prose answer is cut:
// the one from Println is the only one wanted.
func TestAProseAnswerLosesItsTrailingNewlines(t *testing.T) {
	got, err := answer(&provider.Result{Text: "the answer\n\n"}, false)
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != "the answer" {
		t.Errorf("the answer is %q", got)
	}
}

// A shape was asked for and none came back: the prose is printed rather than nothing at all,
// since the caller can still read it.
func TestAnAnswerWithNoShapeFallsBackToItsProse(t *testing.T) {
	got, err := answer(&provider.Result{Text: "no object here"}, true)
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != "no object here" {
		t.Errorf("the answer is %q", got)
	}
}

// A run that never starts must not overwrite the last one that did, or `--replay` loses the
// input a caller was about to try again with.
func TestAProviderNoOneKnowsLeavesTheLastRunAlone(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	if err := store.SaveRun([]byte("the run that worked"), "the prompt that worked"); err != nil {
		t.Fatal(err)
	}

	if err := run([]string{"--provider", "bogus", "--replay", "do it"}); err == nil {
		t.Fatal("an unknown provider was accepted")
	}

	input, err := store.Input()
	if err != nil {
		t.Fatal(err)
	}
	if string(input) != "the run that worked" {
		t.Errorf("the saved input is now %q", input)
	}
	prompt, err := store.Prompt()
	if err != nil {
		t.Fatal(err)
	}
	if string(prompt) != "the prompt that worked" {
		t.Errorf("the saved prompt is now %q", prompt)
	}
}

func TestNothingToReplayIsSaidRatherThanRun(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	err := run([]string{"--replay", "do it"})
	if err == nil {
		t.Fatal("a replay with nothing saved was accepted")
	}
	if !strings.Contains(err.Error(), "nothing to replay") {
		t.Errorf("the error is %q", err)
	}
}

func TestAPromptIsRequired(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	err := run(nil)
	if err == nil || !strings.Contains(err.Error(), "say what to do") {
		t.Errorf("a run with no prompt gave %v", err)
	}
}

func TestASpecThatWillNotBuildStopsTheRun(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	err := run([]string{"-s", "name:notatype", "--replay", "do it"})
	if err == nil || !strings.Contains(err.Error(), "notatype") {
		t.Errorf("a bad spec gave %v", err)
	}
}
