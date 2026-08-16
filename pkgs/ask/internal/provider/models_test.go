package provider

import (
	"strings"
	"testing"
)

// The shape of `claude --help` as of 2026-08-16. The parse reads a paragraph of
// prose, so this pins what it is reading; a help reformat breaks this test
// rather than silently offering nothing.
const claudeHelp = `  --fallback-model <model>              Enable automatic fallback to specified
                                        model(s) when overloaded.
  --model <model>                       Model for the current session. Provide
                                        an alias for the latest model (e.g.
                                        'fable', 'opus', or 'sonnet') or a
                                        model's full name (e.g.
                                        'claude-fable-5').
  -n, --name <name>                     Set a display name for this session
`

func TestAliases(t *testing.T) {
	got := aliases(claudeHelp, "--model <model>")
	want := []string{"fable", "opus", "sonnet", "claude-fable-5"}

	if strings.Join(got, ",") != strings.Join(want, ",") {
		t.Fatalf("got %v, want %v", got, want)
	}
}

// The apostrophe in "a model's full name" sits between two real aliases. It
// must not pair with either, or the list grows a phrase.
func TestAliasesRejectsAPhrase(t *testing.T) {
	for _, one := range aliases(claudeHelp, "--model <model>") {
		if strings.ContainsAny(one, " )(.") {
			t.Errorf("%q is a phrase, not a model", one)
		}
	}
}

// Reading the whole help would collect every quoted word in it, including the
// fallback-model paragraph above the one that matters.
func TestAliasesStopsAtTheNextFlag(t *testing.T) {
	for _, one := range aliases(claudeHelp, "--model <model>") {
		if one == "name" {
			t.Fatal("the parse ran past --model into the next flag")
		}
	}
}

func TestAliasesOnHelpWithoutTheHeader(t *testing.T) {
	if got := aliases(claudeHelp, "--nothing-like-this"); got != nil {
		t.Fatalf("got %v, want nil", got)
	}
}

// Codex names none of its models, so it must offer none rather than borrow
// another agent's list.
func TestCodexOffersNoModels(t *testing.T) {
	one, found := Lookup("codex")
	if !found {
		t.Fatal("codex is not registered")
	}
	if got := one.Models(); got != nil {
		t.Fatalf("got %v, want nil", got)
	}
}
