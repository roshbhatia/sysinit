package guard

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

// realRules mirrors modules/home/programs/llm/lib/allowlist.nix verbatim.
var realRules = []Rule{
	{`git[[:space:]]+push\b[^;&|]*([[:space:]]-f([[:space:]]|$)|--force)`, "Force-pushing is prohibited (global CLAUDE.md: no force-push)."},
	{`(--no-verify|--no-gpg-sign)\b`, "Hook-bypass flags are prohibited (global CLAUDE.md: no --no-verify / --no-gpg-sign)."},
	{`git[[:space:]]+reset\b[^;&|]*--hard\b`, "git reset --hard is prohibited without explicit instruction (global CLAUDE.md)."},
	{`git[[:space:]]+clean\b[^;&|]*-[a-zA-Z]*f`, "git clean -f is prohibited without explicit instruction (global CLAUDE.md)."},
	{`git[[:space:]]+branch\b[^;&|]*-D\b`, "git branch -D (force-delete) is prohibited without explicit instruction (global CLAUDE.md)."},
	{`git[[:space:]]+branch\b[^;&|]*--delete[^;&|]*--force\b`, "git branch --delete --force is prohibited without explicit instruction (global CLAUDE.md)."},
}

func compileReal(t *testing.T) []compiled {
	t.Helper()
	out := make([]compiled, 0, len(realRules))
	for _, rule := range realRules {
		pattern, err := regexp.Compile(rule.Regex)
		if err != nil {
			t.Fatalf("rule %q does not compile under RE2: %v", rule.Regex, err)
		}
		out = append(out, compiled{pattern: pattern, reason: rule.Reason})
	}
	return out
}

// denied is every command the guard must refuse, plus two compound forms where
var denied = []string{
	"git push --force",
	"git push --force-with-lease origin main",
	"git push -f",
	"git push origin main -f",
	"git commit --no-verify -m wip",
	"git commit --no-gpg-sign -m wip",
	"git reset --hard HEAD~1",
	"git clean -fd",
	"git branch -D feature",
	"git branch --delete --force feature",
	"git push -f && echo done",
	"git reset --hard HEAD~1; echo done",
}

// allowed is every fixture that must produce no decision at all. The last four
var allowed = []string{
	"git push",
	"git push origin main",
	"git push origin feature-f",
	"git status",
	"git reset HEAD~1",
	"git clean -n",
	"git branch -d feature",
	"nix flake check",
	"git push && rm -f /tmp/x",
	"git push origin main; rm -rf /tmp/x",
	"git reset HEAD~1 && printf -- --hard",
	"git branch -d old && grep -D pattern file",
}

func TestEveryDeniedFixtureIsRefused(t *testing.T) {
	rules := compileReal(t)
	for _, cmd := range denied {
		reason, got := Decide(cmd, rules)
		if !got {
			t.Errorf("expected deny, got none for: %s", cmd)
			continue
		}
		if reason == "" {
			t.Errorf("denied %q with an empty reason", cmd)
		}
	}
}

func TestEveryAllowedFixtureIsPermitted(t *testing.T) {
	rules := compileReal(t)
	for _, cmd := range allowed {
		if reason, got := Decide(cmd, rules); got {
			// A guard that blocks everything is not a fix.
			t.Errorf("expected no decision, got deny (%s) for: %s", reason, cmd)
		}
	}
}

func TestExitCodeGuardFixturesDecideTheSameWay(t *testing.T) {
	rules := compileReal(t)
	// checks/exit-code-guard-blocks.nix drives these through both wrappers.
	for _, cmd := range []string{
		"git reset --hard HEAD~3",
		"git push --force origin main",
		"git commit --no-verify -m x",
	} {
		if _, got := Decide(cmd, rules); !got {
			t.Errorf("exit-code guard would pass a command it must block: %s", cmd)
		}
	}
	for _, cmd := range []string{"ls -la", "git status"} {
		if _, got := Decide(cmd, rules); got {
			t.Errorf("exit-code guard would block an allowed command: %s", cmd)
		}
	}
}

func TestFirstMatchingRuleSuppliesTheReason(t *testing.T) {
	rules := compileReal(t)
	// The reason has to name the specific prohibition, not whichever rule
	reason, got := Decide("git push --force", rules)
	if !got || !strings.Contains(reason, "Force-pushing") {
		t.Fatalf("expected the force-push reason, got %q", reason)
	}
	reason, got = Decide("git commit --no-verify -m x", rules)
	if !got || !strings.Contains(reason, "Hook-bypass") {
		t.Fatalf("expected the hook-bypass reason, got %q", reason)
	}
}

func TestMalformedEventProducesNoDecision(t *testing.T) {
	// The three malformed payloads the fixture check feeds in. A harness
	for _, payload := range []string{"not json at all", "{}", `{"tool_input":{}}`} {
		if _, ok := readCommand(strings.NewReader(payload)); ok {
			t.Errorf("readCommand found a command in: %s", payload)
		}
	}
}

func TestMissingRuleFileIsFatalNotSilent(t *testing.T) {
	// Failing open is the shape that matters: a guard that cannot reach its
	for _, path := range []string{"", filepath.Join(t.TempDir(), "absent.json")} {
		if _, err := loadRules(path); err == nil {
			t.Errorf("loadRules accepted %q", path)
		}
	}
}

func TestUnparseableOrEmptyRuleFileIsFatal(t *testing.T) {
	dir := t.TempDir()
	for name, body := range map[string]string{
		"bad.json":          "not json",
		"empty.json":        "[]",
		"uncompilable.json": `[{"regex":"a(","reason":"x"}]`,
	} {
		path := filepath.Join(dir, name)
		if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
			t.Fatal(err)
		}
		if _, err := loadRules(path); err == nil {
			t.Errorf("loadRules accepted %s: %s", name, body)
		}
	}
}

func TestRulesLoadFromAGeneratedFile(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "rules.json")
	body := `[{"regex":"^danger","reason":"nope"}]`
	if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}
	rules, err := loadRules(path)
	if err != nil {
		t.Fatal(err)
	}
	if reason, got := Decide("danger zone", rules); !got || reason != "nope" {
		t.Fatalf("expected the loaded rule to fire, got %q %v", reason, got)
	}
	if _, got := Decide("safe", rules); got {
		t.Fatal("the loaded rule fired on an unrelated command")
	}
}

func TestReasonFallsBackWhenARuleCarriesNone(t *testing.T) {
	rules := []compiled{{pattern: regexp.MustCompile("^x"), reason: ""}}
	reason, got := Decide("x", rules)
	if !got || reason != fallbackReason {
		t.Fatalf("expected the fallback reason, got %q", reason)
	}
}
