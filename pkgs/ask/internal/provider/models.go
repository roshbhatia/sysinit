package provider

import (
	"context"
	"os/exec"
	"regexp"
	"strings"
	"time"
)

// patience bounds the help run behind a tab press; `claude --help` takes 150ms.
const patience = time.Second

// named allows no spaces, so the apostrophe in "a model's full name" cannot pair
// with a real quote.
var named = regexp.MustCompile(`'([A-Za-z0-9][A-Za-z0-9.\[\]-]*)'`)

// Models answers the model names this agent accepts, read from the installed
// CLI so no list here can go stale.
func (i Info) Models() []string {
	if i.models == nil || !i.Ready() {
		return nil
	}
	return i.models()
}

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

// claudeModels parses `claude --help`, as the CLI has no command that lists
// models. `TestAliases` pins the help shape it reads.
func claudeModels() []string {
	return aliases(help("claude", "--help"), "--model <model>")
}

// aliases pulls the quoted names out of the one help paragraph under header.
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
