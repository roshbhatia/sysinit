// Package guard implements the two deny-path commands: `bash-guard`, which
// answers a PreToolUse hook with a permission decision, and `exit-code-guard`,
// which carries the same decision to a harness that reads exit codes instead.
//
// The failure mode here is failing OPEN, which is worse than failing closed:
// a guard that cannot reach its rules and exits 0 silently permits everything
// it was installed to refuse. Every path that cannot reach a decision is
// therefore an error, not a silent pass. The one deliberate exception is an
// event carrying no command at all, which is not a Bash call.
package guard

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"regexp"
)

const (
	BashSummary     = "deny destructive Bash commands via a PreToolUse decision"
	ExitCodeSummary = "deny destructive commands via a non-zero exit code"
)

const fallbackReason = "blocked by sysinit destructive-command guard"

// Rule is one deny pattern and the sentence shown when it fires.
type Rule struct {
	Regex  string `json:"regex"`
	Reason string `json:"reason"`
}

type compiled struct {
	pattern *regexp.Regexp
	reason  string
}

// event is the hook payload. Only the command is read: the rules match on
// command text, and every other field varies by harness.
type event struct {
	ToolInput struct {
		Command string `json:"command"`
	} `json:"tool_input"`
}

// decision is the PreToolUse answer shape. The key names are fixed by the
// harness contract, so a rename here silently stops denying anything.
type decision struct {
	HookSpecificOutput struct {
		HookEventName            string `json:"hookEventName"`
		PermissionDecision       string `json:"permissionDecision"`
		PermissionDecisionReason string `json:"permissionDecisionReason"`
	} `json:"hookSpecificOutput"`
}

// loadRules reads the rule file the packaging generated.
//
// An unreadable or unparseable file is fatal. Treating it as "no rules" is the
// exact fail-open shape this package exists to prevent.
func loadRules(path string) ([]compiled, error) {
	if path == "" {
		return nil, fmt.Errorf("no --rules given; refusing to run with no deny rules")
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("cannot read the deny rules at %s: %w", path, err)
	}
	var rules []Rule
	if err := json.Unmarshal(data, &rules); err != nil {
		return nil, fmt.Errorf("the deny rules at %s do not parse: %w", path, err)
	}
	if len(rules) == 0 {
		return nil, fmt.Errorf("the deny rules at %s are empty", path)
	}
	out := make([]compiled, 0, len(rules))
	for _, rule := range rules {
		pattern, err := regexp.Compile(rule.Regex)
		if err != nil {
			return nil, fmt.Errorf("deny rule %q does not compile: %w", rule.Regex, err)
		}
		out = append(out, compiled{pattern: pattern, reason: rule.Reason})
	}
	return out, nil
}

// Decide returns the reason the command is refused, if any.
//
// Rules are tried in order and the first match wins, so the reason a caller
// sees names the specific prohibition rather than the last rule in the list.
func Decide(command string, rules []compiled) (string, bool) {
	for _, rule := range rules {
		if rule.pattern.MatchString(command) {
			reason := rule.reason
			if reason == "" {
				reason = fallbackReason
			}
			return reason, true
		}
	}
	return "", false
}

// parseArgs pulls --rules out of the argument list.
func parseArgs(args []string) (string, error) {
	rules := ""
	for i := 0; i < len(args); i++ {
		if args[i] != "--rules" {
			return "", fmt.Errorf("unknown argument: %s", args[i])
		}
		if i+1 >= len(args) {
			return "", fmt.Errorf("--rules needs a value")
		}
		rules = args[i+1]
		i++
	}
	return rules, nil
}

// readCommand returns the command under review, and whether there is one.
//
// A payload that does not parse, or carries no command, is not a Bash call the
// rules can speak to. Those exit 0 with no decision, which is what the harness
// expects for an event it forwarded indiscriminately.
func readCommand(stdin io.Reader) (string, bool) {
	data, err := io.ReadAll(stdin)
	if err != nil {
		return "", false
	}
	var ev event
	if json.Unmarshal(data, &ev) != nil {
		return "", false
	}
	if ev.ToolInput.Command == "" {
		return "", false
	}
	return ev.ToolInput.Command, true
}

// RunBash answers a PreToolUse hook on stdout.
func RunBash(args []string) int {
	rulesPath, err := parseArgs(args)
	if err != nil {
		fmt.Fprintf(os.Stderr, "bash-guard: %s\n", err)
		return 1
	}
	rules, err := loadRules(rulesPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "bash-guard: %s\n", err)
		return 1
	}
	command, ok := readCommand(os.Stdin)
	if !ok {
		return 0
	}
	reason, denied := Decide(command, rules)
	if !denied {
		return 0
	}
	var out decision
	out.HookSpecificOutput.HookEventName = "PreToolUse"
	out.HookSpecificOutput.PermissionDecision = "deny"
	out.HookSpecificOutput.PermissionDecisionReason = reason
	encoded, err := json.Marshal(out)
	if err != nil {
		fmt.Fprintf(os.Stderr, "bash-guard: %s\n", err)
		return 1
	}
	fmt.Println(string(encoded))
	return 0
}

// RunExitCode carries the same decision to a harness that reads exit codes.
//
// The decision is made here rather than by shelling out to bash-guard. The
// shell original forked the inner guard and read its stdout, so an inner
// failure produced empty output and the wrapper passed the command through.
func RunExitCode(args []string) int {
	rulesPath, err := parseArgs(args)
	if err != nil {
		fmt.Fprintf(os.Stderr, "exit-code-guard: %s\n", err)
		return 1
	}
	rules, err := loadRules(rulesPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "exit-code-guard: %s\n", err)
		return 1
	}
	command, ok := readCommand(os.Stdin)
	if !ok {
		return 0
	}
	reason, denied := Decide(command, rules)
	if !denied {
		return 0
	}
	fmt.Fprintln(os.Stderr, reason)
	// 2, not 1: the harnesses read this specific code as "refused", and treat
	// 1 as the tool itself having failed.
	return 2
}
