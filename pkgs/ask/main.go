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
	"strings"
	"time"

	"golang.org/x/term"

	"github.com/roshbhatia/sysinit/pkgs/ask/internal/provider"
	"github.com/roshbhatia/sysinit/pkgs/ask/internal/schema"
	"github.com/roshbhatia/sysinit/pkgs/ask/internal/store"
	"github.com/roshbhatia/sysinit/pkgs/ask/internal/ui"
)

const usage = `usage: ask [flags] <prompt...>

Pipes stdin into a coding agent and prints the answer on stdout. Everything else,
the spinner and what the model is doing, goes to stderr.

  cat main.go | ask summarise this file
  cat log.txt | ask --schema 'level:error|warn|info, message:string' -- classify this
  ask --show-input | pbcopy

flags:
  -j, --json            answer in JSON, shape unspecified
  -s, --schema SPEC     answer in JSON, in this shape. A field spec such as
                        'name:string, tags:[]string, count:int?', where a trailing
                        question mark makes a field optional and a bar makes an
                        enum, or @path to a JSON Schema file
  -m, --model NAME      model alias, such as opus or sonnet
      --provider NAME   which agent to run (default claude)
      --replay          rerun the last input, with this prompt or the last one
      --show-input      print the last input and exit
      --show-prompt     print the last prompt and exit
      --show-output     print the last answer and exit
  -q, --quiet           no progress output at all
      --timeout DUR     give up after this long (default 10m)
  -h, --help            this
`

// options are what the flags said.
type options struct {
	prompt   string
	json     bool
	spec     string
	model    string
	provider string
	replay   bool
	quiet    bool
	timeout  time.Duration
	show     string
}

// parse reads the arguments by hand rather than through `flag`, so a prompt can be written
// as bare words after the flags without quoting and without a mandatory `--`.
func parse(args []string) (options, error) {
	opts := options{timeout: 10 * time.Minute}
	var words []string

	for at := 0; at < len(args); at++ {
		arg := args[at]
		// Everything after a bare `--` is the prompt, whatever it looks like.
		if arg == "--" {
			words = append(words, args[at+1:]...)
			break
		}
		value := func() (string, error) {
			if at+1 >= len(args) {
				return "", fmt.Errorf("%s wants a value", arg)
			}
			at++
			return args[at], nil
		}

		var err error
		switch arg {
		case "-h", "--help":
			return options{show: "help"}, nil
		case "-j", "--json":
			opts.json = true
		case "-q", "--quiet":
			opts.quiet = true
		case "--replay":
			opts.replay = true
		case "--show-input":
			opts.show = "input"
		case "--show-prompt":
			opts.show = "prompt"
		case "--show-output":
			opts.show = "output"
		case "-s", "--schema":
			opts.spec, err = value()
		case "-m", "--model":
			opts.model, err = value()
		case "--provider":
			opts.provider, err = value()
		case "--timeout":
			var text string
			if text, err = value(); err == nil {
				opts.timeout, err = time.ParseDuration(text)
			}
		default:
			if strings.HasPrefix(arg, "-") && opts.show == "" && len(words) == 0 {
				return opts, fmt.Errorf("unknown flag %s", arg)
			}
			words = append(words, arg)
		}
		if err != nil {
			return opts, err
		}
	}

	opts.prompt = strings.Join(words, " ")
	return opts, nil
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

// show prints one of the saved pieces of the last run.
func show(which string) error {
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

func run(args []string) error {
	opts, err := parse(args)
	if err != nil {
		return err
	}
	if opts.show == "help" {
		fmt.Fprint(os.Stderr, usage)
		return nil
	}
	if opts.show != "" {
		return show(opts.show)
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

	var shape map[string]any
	switch {
	case opts.spec != "":
		if shape, err = schema.Resolve(opts.spec); err != nil {
			return err
		}
	case opts.json:
		shape = schema.Any()
	}

	// Saved before the run, so a run that dies still leaves the input to try again with.
	if err := store.SaveRun(input, prompt); err != nil {
		return err
	}

	agent, err := provider.Find(opts.provider)
	if err != nil {
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
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "ask: "+err.Error())
		os.Exit(1)
	}
}
