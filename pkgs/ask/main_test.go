package main

import (
	"io"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"testing"
	"time"

	"github.com/spf13/cobra"

	"github.com/roshbhatia/sysinit/pkgs/ask/internal/config"
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
	if got := read(t, "-p", "cdx", "--", "classify", "this").prompt; got != "classify this" {
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
	opts := read(t, "-j", "-q", "--replay", "-m", "opus", "-s", "a:string", "-p", "cdx", "--timeout", "30s", "hi")
	if !opts.json || !opts.quiet || !opts.replay {
		t.Errorf("the switches are %+v", opts)
	}
	if opts.model != "opus" || opts.spec != "a:string" || opts.provider != "cdx" {
		t.Errorf("the values are %+v", opts)
	}
	if opts.timeout != 30*time.Second {
		t.Errorf("the timeout is %v", opts.timeout)
	}
	if opts.prompt != "hi" {
		t.Errorf("the prompt is %q", opts.prompt)
	}
}

func TestAProviderIsNamedByTheOneFlagThatNamesOne(t *testing.T) {
	for _, one := range []struct {
		args []string
		want string
	}{
		{[]string{"hi"}, ""},
		{[]string{"-p", "cld", "hi"}, "cld"},
		{[]string{"--provider", "codex", "hi"}, "codex"},
	} {
		if got := read(t, one.args...).provider; got != one.want {
			t.Errorf("%v named %q, want %q", one.args, got, one.want)
		}
	}
}

func TestTheDroppedProviderLettersAreGone(t *testing.T) {
	for _, flag := range []string{"-c", "-o"} {
		if _, err := parse([]string{flag, "hi"}); err == nil {
			t.Errorf("%s is still a flag", flag)
		}
	}
}

func TestAFlagWithNoValueIsRejected(t *testing.T) {
	for _, flag := range []string{"-m", "-s", "-p", "--provider", "--timeout", "--set-config", "--get-config"} {
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

func TestTheProvidersCompleteByEitherNameTheyGoBy(t *testing.T) {
	var opts options
	cmd := command(&opts)
	for _, one := range []struct {
		flag string
		want string
	}{
		{"provider", "codex"},
		{"provider", "cdx"},
		{"provider", "cld"},
		{"model", "opus"},
		{"get-config", config.ProviderDefault},
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

func TestSetConfigCompletesTheKeyFirstAndThenItsValues(t *testing.T) {
	keys := pairs("")
	if !hasString(keys, config.ProviderDefault+"=") {
		t.Errorf("the keys complete to %v", keys)
	}
	values := pairs(config.ProviderDefault + "=")
	for _, want := range []string{config.ProviderDefault + "=claude", config.ProviderDefault + "=cdx"} {
		if !hasString(values, want) {
			t.Errorf("the values complete to %v, want them to offer %q", values, want)
		}
	}
	if got := pairs("provider.nope="); got != nil {
		t.Errorf("an unknown key completed to %v", got)
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
	err := run(options{prompt: "do it", provider: "claude", replay: true})
	if err == nil {
		t.Fatal("a replay with nothing saved was accepted")
	}
	if !strings.Contains(err.Error(), "nothing to replay") {
		t.Errorf("the error is %q", err)
	}
}

func TestAPromptIsRequired(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	err := run(options{provider: "claude"})
	if err == nil || !strings.Contains(err.Error(), "say what to ask") {
		t.Errorf("a run with no prompt gave %v", err)
	}
}

func TestAPromptWithNothingPipedInStillRuns(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())

	null, err := os.Open(os.DevNull)
	if err != nil {
		t.Fatal(err)
	}
	was := os.Stdin
	os.Stdin = null
	t.Cleanup(func() { os.Stdin = was; null.Close() })

	dir := t.TempDir()
	script := "#!/bin/sh\ncat > " + filepath.Join(dir, "stdin") + "\n" +
		`echo '{"type":"result","subtype":"success","result":"the answer","num_turns":1}'` + "\n"
	if err := os.WriteFile(filepath.Join(dir, "claude"), []byte(script), 0o755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PATH", dir+string(os.PathListSeparator)+os.Getenv("PATH"))

	if err := run(options{prompt: "what does git rebase do", provider: "cld", quiet: true, timeout: time.Minute}); err != nil {
		t.Fatalf("a run with nothing piped in failed: %v", err)
	}

	out, err := store.Output()
	if err != nil {
		t.Fatal(err)
	}
	if string(out) != "the answer" {
		t.Errorf("the saved answer is %q", out)
	}

	stdin, err := os.ReadFile(filepath.Join(dir, "stdin"))
	if err != nil {
		t.Fatal(err)
	}
	if len(stdin) != 0 {
		t.Errorf("the agent was given %q on stdin", stdin)
	}
}

func TestASpecThatWillNotBuildStopsTheRun(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	err := run(options{prompt: "do it", spec: "name:notatype", replay: true})
	if err == nil || !strings.Contains(err.Error(), "notatype") {
		t.Errorf("a bad spec gave %v", err)
	}
}

// answerTo runs the rest of the test as though the binary were called by name.
func answerTo(t *testing.T, name string) {
	t.Helper()
	was := os.Args[0]
	os.Args[0] = filepath.Join(t.TempDir(), name)
	t.Cleanup(func() { os.Args[0] = was })
}

func TestAWrapperNameNamesItsAgentAndItsShape(t *testing.T) {
	for _, one := range []struct {
		called string
		short  string
		asJSON bool
		known  bool
	}{
		{"ask", "", false, false},
		{"_", "", false, true},
		{"_j", "", true, true},
		{"_cld", "cld", false, true},
		{"_cldj", "cld", true, true},
		{"_cdx", "cdx", false, true},
		{"_cdxj", "cdx", true, true},
		{"_nope", "", false, false},
	} {
		short, asJSON, known := wrapper(one.called)
		if short != one.short || asJSON != one.asJSON || known != one.known {
			t.Errorf("%s read as (%q, %v, %v), want (%q, %v, %v)",
				one.called, short, asJSON, known, one.short, one.asJSON, one.known)
		}
	}
}

// The overlay makes one symlink per line of wrappers.txt, so a provider added to
// the registry without a line there ships with no wrapper on PATH.
func TestTheWrappersOnPathMatchTheListTheOverlayReads(t *testing.T) {
	raw, err := os.ReadFile("wrappers.txt")
	if err != nil {
		t.Fatal(err)
	}
	listed := strings.Fields(string(raw))

	if got := wrappers(); !slices.Equal(got, listed) {
		t.Errorf("the binary answers to %v, and wrappers.txt lists %v", got, listed)
	}
	for _, name := range listed {
		if _, _, known := wrapper(name); !known {
			t.Errorf("wrappers.txt lists %q, which the binary does not answer to", name)
		}
	}
}

func TestTheNameTheBinaryWasCalledByPicksTheAgent(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", t.TempDir())
	t.Setenv("ASK_PROVIDER", "")
	answerTo(t, "_cdx")

	agent, err := chosen(options{})
	if err != nil {
		t.Fatal(err)
	}
	if agent.Name() != "codex" {
		t.Errorf("_cdx ran %s", agent.Name())
	}
}

func TestTheFlagBeatsTheNameTheEnvironmentAndTheSetting(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", t.TempDir())
	t.Setenv("ASK_PROVIDER", "codex")
	answerTo(t, "_cdx")

	if _, _, err := config.Set(config.ProviderDefault + "=codex"); err != nil {
		t.Fatal(err)
	}

	agent, err := chosen(options{provider: "cld"})
	if err != nil {
		t.Fatal(err)
	}
	if agent.Name() != "claude" {
		t.Errorf("-p cld ran %s", agent.Name())
	}
}

func TestTheEnvironmentBeatsTheSetting(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", t.TempDir())
	t.Setenv("ASK_PROVIDER", "cdx")
	answerTo(t, "ask")

	if _, _, err := config.Set(config.ProviderDefault + "=claude"); err != nil {
		t.Fatal(err)
	}

	agent, err := chosen(options{})
	if err != nil {
		t.Fatal(err)
	}
	if agent.Name() != "codex" {
		t.Errorf("$ASK_PROVIDER ran %s", agent.Name())
	}
}

func TestTheSettingIsUsedWhenNothingElseSaysAnything(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", t.TempDir())
	t.Setenv("ASK_PROVIDER", "")
	answerTo(t, "ask")

	if _, _, err := config.Set(config.ProviderDefault + "=cdx"); err != nil {
		t.Fatal(err)
	}

	agent, err := chosen(options{})
	if err != nil {
		t.Fatal(err)
	}
	if agent.Name() != "codex" {
		t.Errorf("the setting ran %s", agent.Name())
	}
}

// The picker needs a terminal, so a run with no terminal has to say what to pass
// rather than hang or open one.
func TestWithNoAgentAndNoTerminalTheRunSaysWhatToPass(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", t.TempDir())
	t.Setenv("ASK_PROVIDER", "")
	answerTo(t, "ask")

	was := os.Stderr
	quiet, err := os.OpenFile(os.DevNull, os.O_WRONLY, 0)
	if err != nil {
		t.Fatal(err)
	}
	os.Stderr = quiet
	t.Cleanup(func() { os.Stderr = was; quiet.Close() })

	_, err = chosen(options{})
	if err == nil {
		t.Fatal("a run with no agent named was accepted")
	}
	if !strings.Contains(err.Error(), config.ProviderDefault) {
		t.Errorf("the error %q does not say what to set", err)
	}
}

func TestAJSONWrapperAsksForJSONWithNoFlag(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	answerTo(t, "_cldj")

	dir := t.TempDir()
	script := "#!/bin/sh\n" +
		"printf '%s\\n' \"$@\" > " + filepath.Join(dir, "args") + "\n" +
		`echo '{"type":"result","subtype":"success","result":"{\"a\":1}","num_turns":1}'` + "\n"
	if err := os.WriteFile(filepath.Join(dir, "claude"), []byte(script), 0o755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PATH", dir+string(os.PathListSeparator)+os.Getenv("PATH"))

	if err := run(options{prompt: "count them", quiet: true, timeout: time.Minute}); err != nil {
		t.Fatal(err)
	}

	args, err := os.ReadFile(filepath.Join(dir, "args"))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(args), "--json-schema") {
		t.Errorf("_cldj ran claude with %q", args)
	}
}

func TestASettingIsWrittenAndReadBackThroughTheFlags(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", t.TempDir())

	handled, err := settings(options{setConfig: config.ProviderDefault + "=cdx"})
	if !handled || err != nil {
		t.Fatalf("the write was handled %v, %v", handled, err)
	}
	if got, _ := config.Get(config.ProviderDefault); got != "codex" {
		t.Errorf("the setting is %q", got)
	}

	if handled, err := settings(options{getConfig: config.ProviderDefault}); !handled || err != nil {
		t.Errorf("the read was handled %v, %v", handled, err)
	}
	if handled, err := settings(options{listConfig: true}); !handled || err != nil {
		t.Errorf("the list was handled %v, %v", handled, err)
	}
	if handled, err := settings(options{prompt: "hi"}); handled || err != nil {
		t.Errorf("a plain run was taken as a settings run: %v, %v", handled, err)
	}
}

func TestASettingsRunNeverReachesAnAgent(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", t.TempDir())
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	t.Setenv("PATH", t.TempDir())
	answerTo(t, "ask")

	if err := run(options{setConfig: config.ProviderDefault + "=cld"}); err != nil {
		t.Fatalf("a settings run failed: %v", err)
	}
	if _, err := store.Prompt(); err == nil {
		t.Error("a settings run was saved as a run")
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
