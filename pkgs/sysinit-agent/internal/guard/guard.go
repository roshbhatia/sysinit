// Package guard implements the two deny-path commands: `bash-guard`, which
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
type event struct {
	ToolInput struct {
		Command string `json:"command"`
	} `json:"tool_input"`
}

// decision is the PreToolUse answer shape. The key names are fixed by the
type decision struct {
	HookSpecificOutput struct {
		HookEventName            string `json:"hookEventName"`
		PermissionDecision       string `json:"permissionDecision"`
		PermissionDecisionReason string `json:"permissionDecisionReason"`
	} `json:"hookSpecificOutput"`
}

// loadRules reads the rule file the packaging generated.
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
	return 2
}
