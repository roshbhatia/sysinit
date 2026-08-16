package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/spf13/cobra"
	"golang.org/x/term"

	"github.com/roshbhatia/sysinit/pkgs/ask/internal/config"
	"github.com/roshbhatia/sysinit/pkgs/ask/internal/pane"
	"github.com/roshbhatia/sysinit/pkgs/ask/internal/provider"
	"github.com/roshbhatia/sysinit/pkgs/ask/internal/schema"
	"github.com/roshbhatia/sysinit/pkgs/ask/internal/store"
	"github.com/roshbhatia/sysinit/pkgs/ask/internal/ui"
)

const about = `Agents in your shell!

Anything on stdin goes to the agent along with the prompt, so a pipe is optional.

  %[1]s what does git rebase --onto do
  cat main.go | %[1]s summarise this file
  cat log.txt | %[1]s -p cdx --schema 'level:error|warn|info, message:string' -- classify this
  %[1]s --show-input | pbcopy

The prompt is the bare words after the flags, so the -- is only needed when a flag
comes first. Quote a prompt that holds shell metacharacters, as in
%[1]s -p cld 'what does the | operator do', or the shell reads them before %[1]s does.

No agent is the default one. %[1]s takes the first of these that says which to run:
the -p flag, the name it was called by, $ASK_PROVIDER, then provider.default from
the settings. With none of them it opens a picker.

  %[1]s --set-config provider.default=cld
  %[1]s --get-config provider.default
  %[1]s --list-config

The short names are wrappers on PATH: _cld is claude, _cdx is codex, and a
trailing j asks for JSON, so _cldj is claude with --json. Bare _ and _j name no
agent, so they run whichever $ASK_PROVIDER or the settings name; %[1]s --list-config
prints which one that is and where it came from.

Both agents answer --json and --schema in the shape asked for. The answer is
checked against that shape here, so a run that answers outside it is a failure
rather than a wrongly shaped success.

An agent given a shape may answer with one question instead, when guessing would
cost more than asking. With a terminal it asks and waits, up to three times. With
no terminal it prints the question and exits 3, so a script can tell a question
from a failure.

Press tab after --schema and the shell writes the spec for you: a whole example
when nothing is typed, and the list of types after a name and a colon.

  %[1]s --schema <tab>
  %[1]s --schema 'files:<tab>

--last sends what the previous command printed, so a pipe is not needed to hand
an agent an error you have just read.

  cargo build; %[1]s --last why did this fail
  %[1]s --show-last | head`

type options struct {
	prompt   string
	json     bool
	spec     string
	model    string
	provider string
	replay   bool
	last     bool
	quiet    bool
	timeout  time.Duration

	showInput  bool
	showPrompt bool
	showOutput bool
	showLast   bool
	capture    bool

	setConfig  string
	getConfig  string
	listConfig bool
}

func (o options) show() string {
	switch {
	case o.showInput:
		return "input"
	case o.showPrompt:
		return "prompt"
	case o.showOutput:
		return "output"
	case o.showLast:
		return "last"
	}
	return ""
}

func called() string {
	return filepath.Base(os.Args[0])
}

// wrapper reads the name the binary was called by. _cld is claude, _cldj is
// claude answering JSON, and bare _ names no agent at all.
func wrapper(name string) (short string, asJSON bool, known bool) {
	rest, is := strings.CutPrefix(name, "_")
	if !is {
		return "", false, false
	}
	if rest == "" {
		return "", false, true
	}
	if _, found := provider.Lookup(rest); found {
		return rest, false, true
	}
	if trimmed, cut := strings.CutSuffix(rest, "j"); cut {
		if trimmed == "" {
			return "", true, true
		}
		if _, found := provider.Lookup(trimmed); found {
			return trimmed, true, true
		}
	}
	return "", false, false
}

func command(opts *options) *cobra.Command {
	name := called()

	cmd := &cobra.Command{
		Use:   name + " [flags] [prompt...]",
		Short: "Agents in your shell!",
		Long:  fmt.Sprintf(about, name),
		Args:  cobra.ArbitraryArgs,

		SilenceUsage:  true,
		SilenceErrors: true,
		RunE: func(_ *cobra.Command, args []string) error {
			opts.prompt = strings.Join(args, " ")
			return run(*opts)
		},

		ValidArgsFunction: func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
			return nil, cobra.ShellCompDirectiveNoFileComp
		},
	}

	flags := cmd.Flags()
	flags.SetInterspersed(false)
	flags.BoolVarP(&opts.json, "json", "j", false, "answer in JSON, shape unspecified")
	flags.StringVarP(&opts.spec, "schema", "s", "", "answer in JSON, in this shape: a field spec such as 'name:string, tags:[]string, count:int?', where a trailing question mark makes a field optional and a bar makes an enum, or @path to a JSON Schema file")
	flags.StringVarP(&opts.model, "model", "m", "", "which model to run; press tab for the ones this agent names")
	flags.StringVarP(&opts.provider, "provider", "p", "", "which agent to run: "+strings.Join(provider.Names(), ", "))
	flags.BoolVar(&opts.replay, "replay", false, "rerun the last input, with this prompt or the last one")
	flags.BoolVarP(&opts.last, "last", "l", false, "send what the previous command printed, instead of stdin")
	flags.BoolVarP(&opts.quiet, "quiet", "q", false, "no progress output at all")
	flags.DurationVar(&opts.timeout, "timeout", 10*time.Minute, "give up after this long")
	flags.BoolVar(&opts.showInput, "show-input", false, "print the last input and exit")
	flags.BoolVar(&opts.showPrompt, "show-prompt", false, "print the last prompt and exit")
	flags.BoolVar(&opts.showOutput, "show-output", false, "print the last answer and exit")
	flags.BoolVar(&opts.showLast, "show-last", false, "print what --last would send and exit")
	// A hidden flag rather than a subcommand, because the root command takes a
	// bare prompt, so a `capture` subcommand would eat `ask capture the flag`.
	flags.BoolVar(&opts.capture, "capture", false, "snapshot the terminal and exit")
	_ = flags.MarkHidden("capture")
	flags.StringVar(&opts.setConfig, "set-config", "", "write one setting, as KEY=VALUE, and exit")
	flags.StringVar(&opts.getConfig, "get-config", "", "print one setting and exit")
	flags.BoolVar(&opts.listConfig, "list-config", false, "print every setting and exit")

	_ = cmd.RegisterFlagCompletionFunc("provider", func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
		return agents(), cobra.ShellCompDirectiveNoFileComp
	})
	_ = cmd.RegisterFlagCompletionFunc("model", func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
		return models(*opts), cobra.ShellCompDirectiveNoFileComp
	})
	_ = cmd.RegisterFlagCompletionFunc("get-config", func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
		return config.Keys(), cobra.ShellCompDirectiveNoFileComp
	})
	_ = cmd.RegisterFlagCompletionFunc("set-config", func(_ *cobra.Command, _ []string, typed string) ([]string, cobra.ShellCompDirective) {
		return pairs(typed), cobra.ShellCompDirectiveNoSpace | cobra.ShellCompDirectiveNoFileComp
	})
	_ = cmd.RegisterFlagCompletionFunc("schema", func(_ *cobra.Command, _ []string, typed string) ([]string, cobra.ShellCompDirective) {
		offer, paths := schema.Complete(typed)
		if paths {
			return nil, cobra.ShellCompDirectiveDefault
		}
		return offer, cobra.ShellCompDirectiveNoSpace | cobra.ShellCompDirectiveNoFileComp
	})
	_ = cmd.RegisterFlagCompletionFunc("timeout", func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
		return []string{
			"30s\ta quick question",
			"2m\tone file",
			"10m\tthe default",
			"30m\ta whole repository",
		}, cobra.ShellCompDirectiveNoFileComp
	})

	return cmd
}

// models offers the models the agent about to run accepts, read from that CLI's
// own help. Nothing here names a model, so a list cannot go stale; a CLI that
// names none of its models offers nothing.
func models(opts options) []string {
	named, _ := source()
	if opts.provider != "" {
		named = opts.provider
	}
	one, found := provider.Lookup(named)
	if !found {
		return nil
	}

	offer := one.Models()
	for at, name := range offer {
		offer[at] = name + "\t" + one.Blurb
	}
	return offer
}

// agents offers every name an agent answers to, long and short, with a word
// saying which agent it is and whether it is installed.
func agents() []string {
	offer := make([]string, 0, len(provider.Known())*2)
	for _, one := range provider.Known() {
		says := one.Blurb
		if !one.Ready() {
			says = one.Binary + " is not on PATH"
		}
		offer = append(offer, one.Name+"\t"+says, one.Short+"\t"+says)
	}
	return offer
}

// pairs completes --set-config on both halves: the keys first, then that key's values.
func pairs(typed string) []string {
	key, _, is := strings.Cut(typed, "=")
	if !is {
		offer := make([]string, 0, len(config.Keys()))
		for _, one := range config.Keys() {
			offer = append(offer, one+"=")
		}
		return offer
	}
	for _, setting := range config.Settings() {
		if setting.Key != key || setting.Values == nil {
			continue
		}
		offer := make([]string, 0)
		for _, value := range setting.Values() {
			offer = append(offer, key+"="+value)
		}
		return offer
	}
	return nil
}

// source names the agent that will run and which of the four ways named it. The
// settings file is the last of the four, so --set-config can report a value that
// nothing reads; this is what lets the settings output say so.
func source() (named string, from string) {
	if short, _, _ := wrapper(called()); short != "" {
		return short, "the name it was called by"
	}
	if named := os.Getenv("ASK_PROVIDER"); named != "" {
		return named, "$ASK_PROVIDER"
	}
	if settled, err := config.Get(config.ProviderDefault); err == nil && settled != "" {
		return settled, config.ProviderDefault
	}
	return "", ""
}

// chosen walks the ways to name an agent, most explicit first, and asks only when
// none of them says anything.
func chosen(opts options) (provider.Provider, error) {
	short, _, _ := wrapper(called())
	for _, named := range []string{opts.provider, short, os.Getenv("ASK_PROVIDER")} {
		if named != "" {
			return provider.Find(named)
		}
	}

	settled, err := config.Get(config.ProviderDefault)
	if err != nil {
		return nil, err
	}
	if settled != "" {
		return provider.Find(settled)
	}

	if !term.IsTerminal(int(os.Stderr.Fd())) {
		return nil, fmt.Errorf("say which agent to run with -p, set $ASK_PROVIDER, or set %s", config.ProviderDefault)
	}
	picked, err := ui.Pick(provider.Known())
	if err != nil {
		return nil, err
	}
	return picked.New(), nil
}

func piped() bool {
	info, err := os.Stdin.Stat()
	if err != nil {
		return false
	}
	return info.Mode()&os.ModeCharDevice == 0
}

func printSaved(which string) error {
	var read func() ([]byte, error)
	switch which {
	case "input":
		read = store.Input
	case "prompt":
		read = store.Prompt
	case "output":
		read = store.Output
	case "last":
		read = pane.Last
	}
	saved, err := read()
	switch {
	case err != nil && which == "last":
		return err
	case err != nil:
		return fmt.Errorf("no saved %s: %w", which, err)
	}
	os.Stdout.Write(saved)
	if len(saved) > 0 && saved[len(saved)-1] != '\n' {
		fmt.Println()
	}
	return nil
}

// settings answers true when the run was about the settings rather than an agent.
func settings(opts options) (bool, error) {
	switch {
	case opts.setConfig != "":
		key, value, err := config.Set(opts.setConfig)
		if err != nil {
			return true, err
		}
		if value == "" {
			fmt.Printf("%s is now unset\n", key)
			return true, nil
		}
		fmt.Printf("%s=%s\n", key, value)
		if outer := os.Getenv("ASK_PROVIDER"); key == config.ProviderDefault && outer != "" {
			fmt.Fprintf(os.Stderr, "note: $ASK_PROVIDER=%s outranks %s, so nothing reads this until that is unset\n", outer, key)
		}
		return true, nil
	case opts.getConfig != "":
		value, err := config.Get(opts.getConfig)
		if err != nil {
			return true, err
		}
		fmt.Println(value)
		return true, nil
	case opts.listConfig:
		lines, err := config.List()
		if err != nil {
			return true, err
		}
		for _, line := range lines {
			fmt.Println(line)
		}
		if named, from := source(); named != "" {
			fmt.Printf("\neffective provider: %s (from %s)\n", named, from)
		}
		return true, nil
	}
	return false, nil
}

func answer(result *provider.Result, structured bool) ([]byte, error) {
	if structured && result.Structured != nil {
		return json.MarshalIndent(result.Structured, "", "  ")
	}
	text := strings.TrimRight(result.Text, "\n")
	return []byte(text), nil
}

// once runs the agent through to one result, drawing whichever view the terminal
// allows.
func once(req provider.Request, opts options, agent provider.Provider) (*provider.Result, error) {
	ctx, stop := context.WithTimeout(context.Background(), opts.timeout)
	defer stop()

	events, err := agent.Run(ctx, req)
	if err != nil {
		return nil, err
	}

	var result *provider.Result
	switch {
	case !opts.quiet && term.IsTerminal(int(os.Stderr.Fd())):
		if result, err = ui.Run(events, stop); err != nil {
			return nil, err
		}
	case opts.quiet:
		result = ui.Drain(events, nil)
	default:
		result = ui.Drain(events, os.Stderr)
	}

	if result == nil {
		return nil, errors.New("the run ended without an answer")
	}
	if result.Failed {
		return nil, fmt.Errorf("%s: %s", agent.Name(), result.Reason)
	}
	return result, nil
}

// converse runs the agent and keeps the exchange going until the answer fits.
// It carries a reply back when the agent asks a question rather than guessing,
// and carries the reason back when the answer is outside the shape. Only a
// person can answer a question, so a run with no terminal reports it and stops.
func converse(req provider.Request, strict map[string]any, opts options, agent provider.Provider) (*provider.Result, error) {
	human := !opts.quiet && term.IsTerminal(int(os.Stderr.Fd()))

	for round := 1; ; round++ {
		result, err := once(req, opts, agent)
		if err != nil {
			return nil, err
		}
		if strict == nil {
			return result, nil
		}

		if question := schema.Question(result.Structured); question != "" {
			if !human || round == rounds {
				return nil, asked{question}
			}
			reply, err := ui.Answer(question)
			if err != nil {
				return nil, err
			}
			req.Prompt += fmt.Sprintf("\n\nYou asked: %s\nThe answer: %s", question, reply)
			continue
		}

		wrong := schema.Check(strict, result.Structured)
		if wrong == nil {
			return result, nil
		}
		if round == rounds {
			return nil, fmt.Errorf("%s: %s", agent.Name(), wrong)
		}
		req.Prompt += "\n\nYour last answer was rejected. " + wrong.Error() +
			"\nAnswer again, in the shape asked for."
	}
}

// rounds is how many times an agent may ask before it has to answer. Three is
// enough for a real ambiguity and short enough that a loop cannot run away.
const rounds = 3

// asked reports a question nobody was there to answer. It leaves by its own exit
// code, so a script can tell "I need to know something" from "I failed".
type asked struct{ question string }

func (a asked) Error() string { return "the agent needs to know: " + a.question }

func run(opts options) error {
	if opts.capture {
		return pane.Capture()
	}
	if handled, err := settings(opts); handled {
		return err
	}
	if which := opts.show(); which != "" {
		return printSaved(which)
	}

	if _, asJSON, _ := wrapper(called()); asJSON {
		opts.json = true
	}

	var shape map[string]any
	var err error
	switch {
	case opts.spec != "":
		if shape, err = schema.Resolve(opts.spec); err != nil {
			return err
		}
	case opts.json:
		shape = schema.Any()
	}

	agent, err := chosen(opts)
	if err != nil {
		return err
	}

	var input []byte
	switch {
	case opts.last:
		if input, err = pane.Last(); err != nil {
			return err
		}
	case opts.replay && !piped():
		if input, err = store.Input(); err != nil {
			return fmt.Errorf("nothing to replay: %w", err)
		}
	case piped():
		if input, err = io.ReadAll(os.Stdin); err != nil {
			return err
		}
	}

	prompt := opts.prompt
	if prompt == "" && opts.replay {
		saved, err := store.Prompt()
		if err != nil {
			return fmt.Errorf("no prompt to replay: %w", err)
		}
		prompt = string(saved)
	}
	if prompt == "" {
		return errors.New("say what to ask, or pass --help")
	}

	if err := store.SaveRun(input, prompt); err != nil {
		return err
	}

	here, _ := os.Getwd()
	loose, mayAsk := schema.Relaxed(shape)
	req := provider.Request{
		Prompt: prompt,
		Input:  input,
		Model:  opts.model,
		Schema: loose,
		Dir:    here,
	}
	if mayAsk {
		req.Prompt += "\n\n" + schema.Rule
	}

	result, err := converse(req, shape, opts, agent)
	if err != nil {
		return err
	}

	out, err := answer(result, shape != nil)
	if err != nil {
		return err
	}
	if err := store.SaveOutput(out); err != nil {
		return err
	}
	fmt.Println(string(out))
	return nil
}

func main() {
	var opts options
	err := command(&opts).Execute()
	var question asked
	switch {
	case err == nil:
		return
	case errors.Is(err, ui.ErrStopped):
		os.Exit(130)
	case errors.As(err, &question):
		fmt.Fprintln(os.Stderr, called()+": "+question.Error())
		os.Exit(3)
	default:
		fmt.Fprintln(os.Stderr, called()+": "+err.Error())
		os.Exit(1)
	}
}
