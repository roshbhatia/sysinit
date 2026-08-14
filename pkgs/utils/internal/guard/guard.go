package guard

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

const (
	BashSummary     = "deny destructive Bash commands via a PreToolUse decision"
	ExitCodeSummary = "deny destructive commands via a non-zero exit code"
	NixSummary      = "deny an edit that resolves into the Nix store"
)

const fallbackReason = "blocked by sysinit destructive-command guard"

type Rule struct {
	Regex  string `json:"regex"`
	Reason string `json:"reason"`
}

type compiled struct {
	pattern *regexp.Regexp
	reason  string
}

type event struct {
	ToolInput struct {
		Command      string `json:"command"`
		FilePath     string `json:"file_path"`
		NotebookPath string `json:"notebook_path"`
	} `json:"tool_input"`
}

type decision struct {
	HookSpecificOutput struct {
		HookEventName            string `json:"hookEventName"`
		PermissionDecision       string `json:"permissionDecision"`
		PermissionDecisionReason string `json:"permissionDecisionReason"`
	} `json:"hookSpecificOutput"`
}

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

const storePrefix = "/nix/store/"

func readPath(stdin io.Reader) (string, bool) {
	data, err := io.ReadAll(stdin)
	if err != nil {
		return "", false
	}
	var ev event
	if json.Unmarshal(data, &ev) != nil {
		return "", false
	}
	path := ev.ToolInput.FilePath
	if path == "" {
		path = ev.ToolInput.NotebookPath
	}
	if path == "" {
		return "", false
	}
	return path, true
}

func resolve(path string) (string, bool) {
	if resolved, err := filepath.EvalSymlinks(path); err == nil {
		return resolved, true
	}
	resolved, err := filepath.EvalSymlinks(filepath.Dir(path))
	if err != nil {
		return "", false
	}
	return resolved, true
}

func RunNix(args []string) int {
	if len(args) > 0 {
		fmt.Fprintf(os.Stderr, "nix-guard: unknown argument: %s\n", args[0])
		return 1
	}
	path, ok := readPath(os.Stdin)
	if !ok {
		return 0
	}
	resolved, ok := resolve(path)
	if !ok {
		return 0
	}
	if !strings.HasPrefix(resolved, storePrefix) {
		return 0
	}

	var out decision
	out.HookSpecificOutput.HookEventName = "PreToolUse"
	out.HookSpecificOutput.PermissionDecision = "deny"
	out.HookSpecificOutput.PermissionDecisionReason = fmt.Sprintf(
		"%s resolves to %s, which is Nix-managed and read-only. Edit the Nix source that generates it (under modules/), then run: nh darwin switch. Editing the store path directly is discarded on the next switch.",
		path, resolved,
	)
	encoded, err := json.Marshal(out)
	if err != nil {
		fmt.Fprintf(os.Stderr, "nix-guard: %s\n", err)
		return 1
	}
	fmt.Println(string(encoded))
	return 0
}

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
	return 2
}
