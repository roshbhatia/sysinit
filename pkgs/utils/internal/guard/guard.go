package guard

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/hookfmt"
)

const (
	BashSummary     = "deny destructive Bash commands, bound one that prints without a limit, and route a whole-file read of a large file to the cheap reader"
	ExitCodeSummary = "deny destructive commands via a non-zero exit code"
	NixSummary      = "deny an edit that resolves into the Nix store"
	ReadSummary     = "deny an unbounded Read of a large file and name the cheap reader"
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

func parseArgs(args []string, fallback hookfmt.Format) (string, hookfmt.Format, error) {
	format, rest, err := hookfmt.ParseFormat(args, fallback)
	if err != nil {
		return "", "", err
	}
	rules := ""
	for i := 0; i < len(rest); i++ {
		if rest[i] != "--rules" {
			return "", "", fmt.Errorf("unknown argument: %s", rest[i])
		}
		if i+1 >= len(rest) {
			return "", "", fmt.Errorf("--rules needs a value")
		}
		rules = rest[i+1]
		i++
	}
	return rules, format, nil
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

// bashBudget bounds what one Bash call can print into the window. read-guard
// clips a Read at 12 KiB, but it gets to stat the file first. A command has no
// file to stat, so the bound has to ride on the command itself.
const bashBudget = 16 * 1024

// The rewrite only applies to a single simple command. Any of these characters
// means the caller composed something, and appending a pipe would bound the last
// stage alone or change precedence. A quote is not here on purpose: `rg "a b" .`
// is still one simple command.
const shellOperators = "|&;<>()$`\\\n"

// Commands that print all of what they are pointed at. None has a natural
// stopping point, so the output size is the input size.
var unboundedCommands = map[string]bool{
	"cat": true, "fd": true, "find": true, "grep": true, "jq": true,
	"printenv": true, "rg": true, "tree": true, "yq": true,
}

// git subcommands with the same property. `git status` and `git branch` are
// bounded by the working tree, so they are not here.
var unboundedGitSubcommands = map[string]bool{
	"blame": true, "diff": true, "log": true, "reflog": true, "shortlog": true,
}

// find actions that write instead of print. A bound would not help them and the
// rewrite has no business touching a command that deletes.
var findWriteActions = map[string]bool{
	"-delete": true, "-exec": true, "-execdir": true, "-ok": true, "-okdir": true,
}

func isAllDigits(s string) bool {
	if s == "" {
		return false
	}
	for _, r := range s {
		if r < '0' || r > '9' {
			return false
		}
	}
	return true
}

// alreadyBounded reports whether the caller picked a limit. It matches exact
// flags rather than prefixes: `-n` as a prefix also matches find's `-name`, which
// would exempt every `find . -name '*.go'` from the bound.
func alreadyBounded(args []string) bool {
	for _, arg := range args {
		switch {
		case arg == "-n" || arg == "-m" || arg == "--max-count" || arg == "--limit":
			return true
		case strings.HasPrefix(arg, "--max-count=") || strings.HasPrefix(arg, "--limit="):
			return true
		case strings.HasPrefix(arg, "-") && isAllDigits(arg[1:]):
			return true
		case len(arg) > 2 && arg[0] == '-' && (arg[1] == 'n' || arg[1] == 'm') && isAllDigits(arg[2:]):
			return true
		}
	}
	return false
}

// boundCommand rewrites a command that can print without a limit so that it
// cannot. It returns false whenever the command is anything other than one plain
// invocation of a known-unbounded tool with no limit of its own.
func boundCommand(command string) (string, bool) {
	trimmed := strings.TrimSpace(command)
	if trimmed == "" || strings.ContainsAny(trimmed, shellOperators) {
		return "", false
	}
	fields := strings.Fields(trimmed)
	name := filepath.Base(fields[0])
	args := fields[1:]
	switch {
	case name == "git":
		if len(args) == 0 || !unboundedGitSubcommands[args[0]] {
			return "", false
		}
	case unboundedCommands[name]:
		// No argument means the command reads stdin, and there is no stdin here:
		// a pipe would have failed the operator check above.
		if len(args) == 0 {
			return "", false
		}
		if name == "find" {
			for _, arg := range args {
				if findWriteActions[arg] {
					return "", false
				}
			}
		}
	default:
		return "", false
	}
	if alreadyBounded(args) {
		return "", false
	}
	// A subshell, so pipefail does not leak into the shell the Bash tool reuses
	// across calls. `cat >/dev/null` drains the remainder instead of letting head
	// close the pipe, so the command still reports its own exit status rather
	// than 141 from SIGPIPE.
	return fmt.Sprintf(
		"( set -o pipefail; %s | { head -c %d; cat >/dev/null; } )",
		trimmed, bashBudget,
	), true
}

type bashEvent struct {
	Cwd       string         `json:"cwd"`
	ToolInput map[string]any `json:"tool_input"`
}

// Commands whose whole purpose is to print a file. `head` and `tail` are not
// here: with -n they are the targeted read the redirect asks for.
var wholeFileReaders = map[string]bool{
	"cat": true, "less": true, "more": true, "bat": true,
}

// largeFileRead reports whether the command prints one large file whole. It
// matches the same shape as boundCommand, one plain invocation and no shell
// operators, and resolves a relative path against cwd because the hook runs
// where the harness does, which is not always where the command will.
func largeFileRead(command, cwd string) (string, int64, bool) {
	trimmed := strings.TrimSpace(command)
	if trimmed == "" || strings.ContainsAny(trimmed, shellOperators) {
		return "", 0, false
	}
	fields := strings.Fields(trimmed)
	if !wholeFileReaders[filepath.Base(fields[0])] {
		return "", 0, false
	}
	var paths []string
	for _, arg := range fields[1:] {
		if strings.HasPrefix(arg, "-") {
			continue
		}
		paths = append(paths, arg)
	}
	if len(paths) != 1 {
		return "", 0, false
	}
	path := paths[0]
	if !filepath.IsAbs(path) && cwd != "" {
		path = filepath.Join(cwd, path)
	}
	info, err := os.Stat(path)
	if err != nil || !info.Mode().IsRegular() || info.Size() <= readTrigger {
		return "", 0, false
	}
	return path, info.Size(), true
}

// DecideBash is the whole bash-guard decision, with no harness in it. cwd is
// the harness's working directory from the hook event.
func DecideBash(input map[string]any, cwd string, rules []compiled) hookfmt.Outcome {
	command, _ := input["command"].(string)
	if command == "" {
		return hookfmt.PassOutcome()
	}
	if reason, denied := Decide(command, rules); denied {
		return hookfmt.Outcome{Kind: hookfmt.Deny, Event: "PreToolUse", Message: reason}
	}
	if path, size, whole := largeFileRead(command, cwd); whole {
		return redirect(path, size)
	}

	// A backgrounded command writes to a log file, not into the window, so the
	// bound would buy nothing and would hide the tail from the log too.
	if background, ok := input["run_in_background"].(bool); ok && background {
		return hookfmt.PassOutcome()
	}
	bounded, rewritten := boundCommand(command)
	if !rewritten {
		return hookfmt.PassOutcome()
	}
	// The whole tool_input is carried forward with only the command replaced.
	// updatedInput substitutes the input rather than merging into it, so dropping
	// the map would drop the timeout the caller chose.
	updated := make(map[string]any, len(input))
	for key, value := range input {
		updated[key] = value
	}
	updated["command"] = bounded

	// The note goes in Context, not Message: on an allow the harness shows
	// Message to the user and nothing to the model, and a model that reads a
	// cut diff without knowing it was cut reports what is missing from the
	// cut as missing from the tree.
	note := fmt.Sprintf(
		"bash-guard: this command can print without a limit, so its output is capped at %d KiB. If the end is missing, narrow it with a filter, a path, or a flag such as -n or --max-count.",
		bashBudget/1024,
	)
	return hookfmt.Outcome{
		Kind:         hookfmt.Allow,
		Event:        "PreToolUse",
		Message:      note,
		Context:      note,
		UpdatedInput: updated,
	}
}

func RunBash(args []string) int {
	rulesPath, format, err := parseArgs(args, hookfmt.Claude)
	if err != nil {
		fmt.Fprintf(os.Stderr, "bash-guard: %s\n", err)
		return 1
	}
	rules, err := loadRules(rulesPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "bash-guard: %s\n", err)
		return 1
	}
	raw, err := io.ReadAll(os.Stdin)
	if err != nil {
		return 0
	}
	var ev bashEvent
	if json.Unmarshal(raw, &ev) != nil {
		return 0
	}
	return hookfmt.Emit(format, DecideBash(ev.ToolInput, ev.Cwd, rules))
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

// DecideNix reports whether the path resolves into the Nix store.
func DecideNix(path string) hookfmt.Outcome {
	resolved, ok := resolve(path)
	if !ok || !strings.HasPrefix(resolved, storePrefix) {
		return hookfmt.PassOutcome()
	}
	return hookfmt.Outcome{
		Kind:  hookfmt.Deny,
		Event: "PreToolUse",
		Message: fmt.Sprintf(
			"%s resolves to %s, which is Nix-managed and read-only. Edit the Nix source that generates it (under modules/), then run: nh darwin switch. Editing the store path directly is discarded on the next switch.",
			path, resolved,
		),
	}
}

func RunNix(args []string) int {
	format, rest, err := hookfmt.ParseFormat(args, hookfmt.Claude)
	if err != nil {
		fmt.Fprintf(os.Stderr, "nix-guard: %s\n", err)
		return 1
	}
	if len(rest) > 0 {
		fmt.Fprintf(os.Stderr, "nix-guard: unknown argument: %s\n", rest[0])
		return 1
	}
	path, ok := readPath(os.Stdin)
	if !ok {
		return 0
	}
	return hookfmt.Emit(format, DecideNix(path))
}

// 23 of this repository's 647 tracked files are over 16 KiB, so the trigger
// fires on 4% of reads and leaves the rest alone. Spotify measured the
// break-even for handing a read to a cheap model at about 350 lines, which is
// what 16 KiB of source is; below it the round trip costs more than it saves.
const readTrigger = 16 * 1024

// bulkReadCommand is the cheap reader the redirect names. It is spelled out in
// full until ask carries a per-provider light model, at which point the
// template alone selects it.
const bulkReadCommand = "ask -p claude -m haiku -t bulk-read"

// Read handles these by page or by pixel, so a line limit means nothing on them.
var opaqueToLineLimits = map[string]bool{
	".pdf": true, ".png": true, ".jpg": true, ".jpeg": true,
	".gif": true, ".webp": true, ".bmp": true, ".ipynb": true,
}

type readEvent struct {
	ToolInput struct {
		FilePath string `json:"file_path"`
		Offset   *int   `json:"offset"`
		Limit    *int   `json:"limit"`
	} `json:"tool_input"`
}

// sampleBytes bounds what estimateLines reads. The guard used to read the whole
// file to count it, which paid the cost it exists to prevent.
const sampleBytes = 64 * 1024

// estimateLines scales the newline density of the first sample over the size.
func estimateLines(path string, size int64) int {
	f, err := os.Open(path)
	if err != nil {
		return 0
	}
	defer f.Close()
	buf := make([]byte, sampleBytes)
	n, _ := io.ReadFull(f, buf)
	if n == 0 {
		return 0
	}
	newlines := strings.Count(string(buf[:n]), "\n")
	if newlines == 0 {
		return 1
	}
	return int(float64(newlines) * float64(size) / float64(n))
}

// redirect is the deny a whole-file read of a large file gets. A deny is the
// one PreToolUse decision whose reason the model reads, so the alternatives
// live in it: the ranged read for an edit, the cheap reader for an answer.
func redirect(path string, size int64) hookfmt.Outcome {
	return hookfmt.Outcome{
		Kind:  hookfmt.Deny,
		Event: "PreToolUse",
		Message: fmt.Sprintf(`%s is %d KiB (about %d lines). A whole-file read is blocked.
  - Need a range: Grep for it, then Read with offset and limit.
  - Need the shape or an answer: %s --var question='<what you need>' < %s
    It returns bullets only, each leading with a name or a line; the file never enters your context.`,
			filepath.Base(path), size/1024, estimateLines(path, size), bulkReadCommand, path),
	}
}

// DecideRead denies an unbounded Read of a large file and names the alternatives.
func DecideRead(ev readEvent) hookfmt.Outcome {
	// An explicit range is the caller having already decided what it needs.
	if ev.ToolInput.FilePath == "" || ev.ToolInput.Offset != nil || ev.ToolInput.Limit != nil {
		return hookfmt.PassOutcome()
	}
	if opaqueToLineLimits[strings.ToLower(filepath.Ext(ev.ToolInput.FilePath))] {
		return hookfmt.PassOutcome()
	}
	info, err := os.Stat(ev.ToolInput.FilePath)
	if err != nil || info.IsDir() || info.Size() <= readTrigger {
		return hookfmt.PassOutcome()
	}
	return redirect(ev.ToolInput.FilePath, info.Size())
}

func RunRead(args []string) int {
	format, rest, err := hookfmt.ParseFormat(args, hookfmt.Claude)
	if err != nil {
		fmt.Fprintf(os.Stderr, "read-guard: %s\n", err)
		return 1
	}
	if len(rest) > 0 {
		fmt.Fprintf(os.Stderr, "read-guard: unknown argument: %s\n", rest[0])
		return 1
	}
	raw, err := io.ReadAll(os.Stdin)
	if err != nil {
		return 0
	}
	var ev readEvent
	if json.Unmarshal(raw, &ev) != nil {
		return 0
	}
	return hookfmt.Emit(format, DecideRead(ev))
}

// RunExitCode is bash-guard's deny half. It defaults to the exit-code format
// because that is the channel its callers read; --format still overrides.
func RunExitCode(args []string) int {
	rulesPath, format, err := parseArgs(args, hookfmt.ExitCode)
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
	return hookfmt.Emit(format, hookfmt.Outcome{
		Kind: hookfmt.Deny, Event: "PreToolUse", Message: reason,
	})
}
