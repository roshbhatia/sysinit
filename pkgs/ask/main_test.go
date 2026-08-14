package main

import (
	"io"
	"strings"
	"testing"
	"time"

	"github.com/spf13/cobra"

	"github.com/roshbhatia/sysinit/pkgs/ask/internal/provider"
	"github.com/roshbhatia/sysinit/pkgs/ask/internal/store"
)

func parse(args []string) (options, error) {
	var opts options
	cmd := command(&opts)
	cmd.RunE = func(_ *cobra.Command, rest []string) error {
		opts.prompt = strings.Join(rest, " ")
		return nil
	}
	cmd.SetArgs(args)
	cmd.SetOut(io.Discard)
	cmd.SetErr(io.Discard)
	return opts, cmd.Execute()
}

func read(t *testing.T, args ...string) options {
	t.Helper()
	opts, err := parse(args)
	if err != nil {
		t.Fatalf("%v: %v", args, err)
	}
	return opts
}

func TestThePromptIsTheBareWordsAfterTheFlags(t *testing.T) {
	if got := read(t, "summarise", "this", "file").prompt; got != "summarise this file" {
		t.Errorf("the prompt is %q", got)
	}
	if got := read(t, "-o", "--", "classify", "this").prompt; got != "classify this" {
		t.Errorf("after a flag the prompt is %q", got)
	}
}

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
		if got := read(t, one.args...).pick(); got != one.want {
			t.Errorf("%v picked %q, want %q", one.args, got, one.want)
		}
	}
}

func TestASpelledProviderWinsOverALetter(t *testing.T) {
	if got := read(t, "-c", "--provider", "codex", "hi").pick(); got != "codex" {
		t.Errorf("the provider is %q, want codex", got)
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

func TestAFlagNoOneKnowsIsRejected(t *testing.T) {
	_, err := parse([]string{"--nope", "hi"})
	if err == nil {
		t.Fatal("an unknown flag was accepted")
	}
	if !strings.Contains(err.Error(), "--nope") {
		t.Errorf("the error %q does not name the flag", err)
	}
}

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

func TestEachSavedPieceIsAskedForByName(t *testing.T) {
	for _, one := range []struct {
		flag string
		want string
	}{
		{"--show-input", "input"},
		{"--show-prompt", "prompt"},
		{"--show-output", "output"},
	} {
		if got := read(t, one.flag).show(); got != one.want {
			t.Errorf("%s asked for %q, want %q", one.flag, got, one.want)
		}
	}
	if got := read(t, "hi").show(); got != "" {
		t.Errorf("a plain run asked for %q", got)
	}
}

func TestTheHelpSpellsTheNameTheCommandWasCalledBy(t *testing.T) {
	var opts options
	cmd := command(&opts)
	if !strings.Contains(cmd.Long, called()) {
		t.Errorf("the help does not name %q", called())
	}
	if !strings.HasPrefix(cmd.Use, called()) {
		t.Errorf("the usage line is %q, want it to open with %q", cmd.Use, called())
	}
}

func TestAPromptIsNotCompletedWithFilenames(t *testing.T) {
	var opts options
	cmd := command(&opts)
	if cmd.ValidArgsFunction == nil {
		t.Fatal("the prompt has no completion of its own")
	}
	_, directive := cmd.ValidArgsFunction(cmd, nil, "")
	if directive != cobra.ShellCompDirectiveNoFileComp {
		t.Errorf("the directive is %v", directive)
	}
}

func TestTheProvidersCompleteByName(t *testing.T) {
	var opts options
	cmd := command(&opts)
	for _, one := range []struct {
		flag string
		want string
	}{
		{"provider", "codex"},
		{"model", "opus"},
	} {
		complete, ok := cmd.GetFlagCompletionFunc(one.flag)
		if !ok {
			t.Fatalf("--%s has no completion", one.flag)
		}
		values, _ := complete(cmd, nil, "")
		if !hasString(values, one.want) {
			t.Errorf("--%s completes to %v, want it to offer %q", one.flag, values, one.want)
		}
	}
}

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

func TestAProseAnswerLosesItsTrailingNewlines(t *testing.T) {
	got, err := answer(&provider.Result{Text: "the answer\n\n"}, false)
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != "the answer" {
		t.Errorf("the answer is %q", got)
	}
}

func TestAnAnswerWithNoShapeFallsBackToItsProse(t *testing.T) {
	got, err := answer(&provider.Result{Text: "no object here"}, true)
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != "no object here" {
		t.Errorf("the answer is %q", got)
	}
}

func TestAProviderNoOneKnowsLeavesTheLastRunAlone(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	if err := store.SaveRun([]byte("the run that worked"), "the prompt that worked"); err != nil {
		t.Fatal(err)
	}

	if err := run(options{prompt: "do it", provider: "bogus", replay: true}); err == nil {
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
	err := run(options{prompt: "do it", replay: true})
	if err == nil {
		t.Fatal("a replay with nothing saved was accepted")
	}
	if !strings.Contains(err.Error(), "nothing to replay") {
		t.Errorf("the error is %q", err)
	}
}

func TestAPromptIsRequired(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	err := run(options{})
	if err == nil || !strings.Contains(err.Error(), "say what to do") {
		t.Errorf("a run with no prompt gave %v", err)
	}
}

func TestASpecThatWillNotBuildStopsTheRun(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	err := run(options{prompt: "do it", spec: "name:notatype", replay: true})
	if err == nil || !strings.Contains(err.Error(), "notatype") {
		t.Errorf("a bad spec gave %v", err)
	}
}

func hasString(values []string, want string) bool {
	for _, value := range values {
		if value == want {
			return true
		}
	}
	return false
}
