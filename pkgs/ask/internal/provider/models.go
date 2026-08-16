package provider

import (
	"context"
	"os/exec"
	"regexp"
	"strings"
	"time"
)

// patience bounds the help run behind a completion. `claude --help` takes about
// 150ms; anything past a second means the CLI is wedged and a shell waiting on
// a tab press should not wait with it.
const patience = time.Second

// named matches a quoted alias. It allows no spaces, which is what keeps the
// apostrophe in "a model's full name" from pairing with a real quote.
var named = regexp.MustCompile(`'([A-Za-z0-9][A-Za-z0-9.\[\]-]*)'`)

// Models answers the model names this agent accepts, or nil when the CLI says
// nothing about them. They are read from the installed CLI rather than listed
// here, so a model released tomorrow needs no change to this repository.
func (i Info) Models() []string {
	if i.models == nil || !i.Ready() {
		return nil
	}
	return i.models()
}

// help runs a CLI's own help and answers what it printed.
func help(binary string, args ...string) string {
	found, err := exec.LookPath(binary)
	if err != nil {
		return ""
	}
	ctx, stop := context.WithTimeout(context.Background(), patience)
	defer stop()

	out, err := exec.CommandContext(ctx, found, args...).Output()
	if err != nil {
		return ""
	}
	return string(out)
}

// claudeModels reads the aliases out of `claude --help`. The CLI has no command
// that lists models, and its --model paragraph names them in quotes:
//
//	--model <model>   Model for the current session. Provide an alias for the
//	                  latest model (e.g. 'fable', 'opus', or 'sonnet') or a
//	                  model's full name (e.g. 'claude-fable-5').
func claudeModels() []string {
	return aliases(help("claude", "--help"), "--model <model>")
}

// aliases pulls the quoted names out of the one help paragraph that starts at
// header. Reading the whole help would collect every quoted word in it.
func aliases(text string, header string) []string {
	at := strings.Index(text, header)
	if at < 0 {
		return nil
	}

	block := text[at:]
	// A help paragraph ends where the next flag starts its own line.
	if end := regexp.MustCompile(`\n\s+-\S`).FindStringIndex(block[1:]); end != nil {
		block = block[:end[0]+1]
	}

	var found []string
	seen := map[string]bool{}
	for _, match := range named.FindAllStringSubmatch(block, -1) {
		if seen[match[1]] {
			continue
		}
		seen[match[1]] = true
		found = append(found, match[1])
	}
	return found
}
