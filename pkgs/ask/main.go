// Command ask pipes something into a coding agent and prints what comes back. It exists
// because the same three problems come up every time one is used from a shell: the answer
// has to be the only thing on stdout, a structured answer has to be asked for in JSON
// Schema, and the input that produced a bad answer is gone by the time the answer is read.
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

	"github.com/roshbhatia/sysinit/pkgs/ask/internal/provider"
	"github.com/roshbhatia/sysinit/pkgs/ask/internal/schema"
	"github.com/roshbhatia/sysinit/pkgs/ask/internal/store"
	"github.com/roshbhatia/sysinit/pkgs/ask/internal/ui"
)

// The long help, with %[1]s standing in for the name the command was called by: it is
// installed under more than one, and help that spells a name the caller did not type is
// help they have to translate.
const about = `Pipes stdin into a coding agent and prints the answer on stdout. Everything else,
the spinner and what the model is doing, goes to stderr.

  cat main.go | %[1]s summarise this file
  cat log.txt | %[1]s -o --schema 'level:error|warn|info, message:string' -- classify this
  %[1]s --show-input | pbcopy

The prompt is the bare words after the flags, so the -- is only needed when a flag
comes first. Quote a prompt that holds shell metacharacters, as in
%[1]s -c 'what does the | operator do', or the shell reads them before %[1]s does.

Both providers answer --json and --schema in the shape asked for, and a run that
answers outside it is reported as a failure. Codex reports no cost, so the line
after a codex run says $0.0000.`

// options are what the flags said.
type options struct {
	prompt   string
	json     bool
	spec     string
	model    string
	provider string
	claude   bool
	codex    bool
	replay   bool
	quiet    bool
	timeout  time.Duration

	showInput  bool
	showPrompt bool
	showOutput bool
}

// show is which piece of the last run to print instead of making a new one, or empty for a
// run of its own.
func (o options) show() string {
	switch {
	case o.showInput:
		return "input"
	case o.showPrompt:
		return "prompt"
	case o.showOutput:
		return "output"
	}
	return ""
}

// called is the name the command was invoked by, which is the name to print in its own help
// and in its own errors.
func called() string {
	return filepath.Base(os.Args[0])
}

// command builds the root command. The prompt is bare words, so flag parsing stops at the
// first of them: `ask what does -v mean` is a question rather than an unknown flag.
func command(opts *options) *cobra.Command {
	name := called()

	cmd := &cobra.Command{
		Use:   name + " [flags] [prompt...]",
		Short: "Pipe something into a coding agent and print the answer, and only the answer",
		Long:  fmt.Sprintf(about, name),
		Args:  cobra.ArbitraryArgs,
		// The error is printed by main, in the same shape every other message takes, and a
		// wall of usage after it buries the one line that matters.
		SilenceUsage:  true,
		SilenceErrors: true,
		RunE: func(_ *cobra.Command, args []string) error {
			opts.prompt = strings.Join(args, " ")
			return run(*opts)
		},
		// A prompt is words, so completing it with the names of files in the directory is
		// noise rather than help.
		ValidArgsFunction: func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
			return nil, cobra.ShellCompDirectiveNoFileComp
		},
	}

	flags := cmd.Flags()
	flags.SetInterspersed(false)
	flags.BoolVarP(&opts.json, "json", "j", false, "answer in JSON, shape unspecified")
	flags.StringVarP(&opts.spec, "schema", "s", "", "answer in JSON, in this shape: a field spec such as 'name:string, tags:[]string, count:int?', where a trailing question mark makes a field optional and a bar makes an enum, or @path to a JSON Schema file")
	flags.StringVarP(&opts.model, "model", "m", "", "model alias, such as opus or sonnet")
	flags.BoolVarP(&opts.claude, "claude", "c", false, "run claude, which is the default")
	flags.BoolVarP(&opts.codex, "codex", "o", false, "run codex")
	flags.StringVar(&opts.provider, "provider", "", "which agent to run by name, claude or codex")
	flags.BoolVar(&opts.replay, "replay", false, "rerun the last input, with this prompt or the last one")
	flags.BoolVarP(&opts.quiet, "quiet", "q", false, "no progress output at all")
	flags.DurationVar(&opts.timeout, "timeout", 10*time.Minute, "give up after this long")
	flags.BoolVar(&opts.showInput, "show-input", false, "print the last input and exit")
	flags.BoolVar(&opts.showPrompt, "show-prompt", false, "print the last prompt and exit")
	flags.BoolVar(&opts.showOutput, "show-output", false, "print the last answer and exit")

	_ = cmd.RegisterFlagCompletionFunc("provider", func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
		return []string{"claude", "codex"}, cobra.ShellCompDirectiveNoFileComp
	})
	_ = cmd.RegisterFlagCompletionFunc("model", func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
		return []string{"opus", "sonnet", "haiku"}, cobra.ShellCompDirectiveNoFileComp
	})

	return cmd
}

// pick reads which provider the flags asked for, since there are three ways to say it.
func (o options) pick() string {
	switch {
	case o.provider != "":
		return o.provider
	case o.codex:
		return "codex"
	case o.claude:
		return "claude"
	}
	return ""
}

// piped is whether something is on the other end of stdin, since a terminal on stdin means
// there is no input rather than an empty one.
func piped() bool {
	info, err := os.Stdin.Stat()
	if err != nil {
		return false
	}
	return info.Mode()&os.ModeCharDevice == 0
}

// printSaved prints one of the saved pieces of the last run.
func printSaved(which string) error {
	var read func() ([]byte, error)
	switch which {
	case "input":
		read = store.Input
	case "prompt":
		read = store.Prompt
	case "output":
		read = store.Output
	}
	saved, err := read()
	if err != nil {
		return fmt.Errorf("no saved %s: %w", which, err)
	}
	os.Stdout.Write(saved)
	if len(saved) > 0 && saved[len(saved)-1] != '\n' {
		fmt.Println()
	}
	return nil
}

// answer is what gets printed on stdout, and only that.
func answer(result *provider.Result, structured bool) ([]byte, error) {
	if structured && result.Structured != nil {
		// Indented, because the common next step is a person reading it, and `jq` does not
		// mind either way.
		return json.MarshalIndent(result.Structured, "", "  ")
	}
	text := strings.TrimRight(result.Text, "\n")
	return []byte(text), nil
}

func run(opts options) error {
	if which := opts.show(); which != "" {
		return printSaved(which)
	}

	// Everything the arguments alone can settle is settled first, so a typo is a message
	// rather than a run: reading stdin drains a pipe the caller cannot refill, and saving
	// the run overwrites the last one `--replay` would have used.
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

	agent, err := provider.Find(opts.pick())
	if err != nil {
		return err
	}

	// The input: what is piped in, or what the last run was given.
	var input []byte
	switch {
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
		return errors.New("say what to do with the input, or pass --help")
	}
	if len(input) == 0 && !opts.replay {
		return errors.New("nothing on stdin; pipe something in")
	}

	// Saved before the run, so a run that dies still leaves the input to try again with.
	if err := store.SaveRun(input, prompt); err != nil {
		return err
	}

	ctx, stop := context.WithTimeout(context.Background(), opts.timeout)
	defer stop()

	here, _ := os.Getwd()
	events, err := agent.Run(ctx, provider.Request{
		Prompt:  prompt,
		Input:   input,
		Model:   opts.model,
		Schema:  shape,
		Timeout: opts.timeout,
		Dir:     here,
	})
	if err != nil {
		return err
	}

	// The progress view is drawn only for a person: a redirected stderr gets the tool lines
	// as plain text, and a quiet run gets nothing.
	var result *provider.Result
	watching := !opts.quiet && term.IsTerminal(int(os.Stderr.Fd()))
	if watching {
		if result, err = ui.Run(events); err != nil {
			return err
		}
	} else if opts.quiet {
		result = ui.Drain(events, nil)
	} else {
		result = ui.Drain(events, os.Stderr)
	}

	if result == nil {
		return errors.New("the run ended without an answer")
	}
	if result.Failed {
		return fmt.Errorf("%s: %s", agent.Name(), result.Reason)
	}

	out, err := answer(result, shape != nil)
	if err != nil {
		return err
	}
	if err := store.SaveOutput(out); err != nil {
		return err
	}
	fmt.Println(string(out))

	if watching {
		fmt.Fprintln(os.Stderr, ui.Summary(result))
	}
	return nil
}

func main() {
	var opts options
	if err := command(&opts).Execute(); err != nil {
		fmt.Fprintln(os.Stderr, called()+": "+err.Error())
		os.Exit(1)
	}
}
