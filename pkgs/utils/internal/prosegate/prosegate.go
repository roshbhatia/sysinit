package prosegate

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const Summary = "hold a Stop hook until the reply is short and in ASD-STE100"

const usage = `prose-gate: send a reply back when it reads like agent prose

Usage:
  prose-gate check     Stop hook. Reads the event on stdin, blocks a reply that
                       carries the tells.
  prose-gate remind    UserPromptSubmit hook. Prints the shape on the first
                       prompt of a session, and again after the gate has blocked
                       a reply. Silent otherwise.
  prose-gate session   SessionStart hook. Prints the context rules, which a fresh
                       or compacted session has just lost.
  prose-gate subagent  SubagentStop hook. Blocks a teammate report that returns
                       the material instead of the conclusion.
  prose-gate lint      Reads text on stdin, prints the findings, exits 1 on any.

Vale reads the reply as markdown and carries the rule set, so fenced code is
skipped and a list is read as a list. SYSINIT_PROSE_STYLE names the vale config;
without it, or without vale on PATH, the gate passes everything.
Off with SYSINIT_PROSE_GATE=off.
`

const (
	// One tell is a slip. Two is the register the reply was written in, and only
	// the register is worth a turn to fix.
	maxTells = 1
	// A teammate reports into the caller's context, so its report is the whole
	// cost of delegating. Anthropic sizes a useful one at 1,000 to 2,000 tokens;
	// 6 KiB is the top of that range.
	maxReportBytes = 6 * 1024
)

type stopEvent struct {
	LastAssistantMessage string `json:"last_assistant_message"`
	StopHookActive       bool   `json:"stop_hook_active"`
	AgentType            string `json:"agent_type"`
	SessionID            string `json:"session_id"`
}

type blockDecision struct {
	Decision string `json:"decision"`
	Reason   string `json:"reason"`
}

type contextOutput struct {
	HookSpecificOutput injectedContext `json:"hookSpecificOutput"`
}

type injectedContext struct {
	HookEventName     string `json:"hookEventName"`
	AdditionalContext string `json:"additionalContext"`
}

func inject(event, text string) int {
	encoded, err := json.Marshal(contextOutput{injectedContext{event, text}})
	if err != nil {
		return 0
	}
	fmt.Println(string(encoded))
	return 0
}

// The reminder used to go in on every prompt. That is the one injection here
// that grows without bound: 210 bytes times the turn count, restating a rule the
// Stop gate already enforces deterministically. A rule stated twice is worse
// than a rule stated once, because the model spends tokens reconciling the two
// (OpenAI, GPT-5 prompting guide). So the reminder is armed rather than
// constant: it goes in on the first prompt of a session, and again only after
// the gate has actually blocked a reply.
func armDir() string {
	if dir := os.Getenv("SYSINIT_PROSE_GATE_DIR"); dir != "" {
		return dir
	}
	base := os.Getenv("XDG_STATE_HOME")
	if base == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			return ""
		}
		base = filepath.Join(home, ".local", "state")
	}
	return filepath.Join(base, "sysinit", "prose-gate")
}

func armPath(session string) string {
	dir := armDir()
	if dir == "" || session == "" || strings.ContainsAny(session, `/\`) {
		return ""
	}
	return filepath.Join(dir, session)
}

// arm records that this session's last reply was blocked, so the next prompt
// carries the reminder again.
func arm(session string) {
	path := armPath(session)
	if path == "" {
		return
	}
	if os.MkdirAll(filepath.Dir(path), 0o755) != nil {
		return
	}
	_ = os.WriteFile(path, []byte("armed\n"), 0o644)
}

// disarm reports whether the reminder is due, and clears the arming if it is.
// An unknown session is always due: injecting 210 bytes costs less than a
// blocked reply.
func disarm(session string) bool {
	path := armPath(session)
	if path == "" {
		return true
	}
	if _, err := os.Stat(path); err == nil {
		_ = os.Remove(path)
		return true
	}
	seen := path + ".seen"
	if _, err := os.Stat(seen); err == nil {
		return false
	}
	if os.MkdirAll(filepath.Dir(seen), 0o755) != nil {
		return true
	}
	_ = os.WriteFile(seen, []byte("seen\n"), 0o644)
	return true
}

// One alert as vale reports it. The rule set lives in pkgs/prose-style, not
// here, so a rule change is a cue edit and a regenerate rather than a rebuild
// of this binary.
type valeAlert struct {
	Check    string `json:"Check"`
	Message  string `json:"Message"`
	Severity string `json:"Severity"`
	Match    string `json:"Match"`
	Line     int    `json:"Line"`
}

// stylePath names the vale config. The Nix wrapper sets it; a developer running
// the binary from a checkout can point it at pkgs/prose-style/vale.ini.
func stylePath() string {
	return os.Getenv("SYSINIT_PROSE_STYLE")
}

// vale parses the reply as markdown, so a fenced block is skipped and a list is
// read as a list. The old hand-rolled matcher stripped every bullet before it
// looked for tells, which made a bullet the one place a tell could hide and
// made the bold-first-term rule unreachable.
//
// Every failure here returns no alerts. A gate that blocks because vale is
// missing costs the user a turn for a fault that is not in their reply.
func alerts(text string) []valeAlert {
	config := stylePath()
	if config == "" {
		return nil
	}
	binary, err := exec.LookPath("vale")
	if err != nil {
		return nil
	}

	cmd := exec.Command(binary, "--config="+config, "--output=JSON", "--ext=.md", "--no-exit")
	cmd.Stdin = strings.NewReader(text)
	out, err := cmd.Output()
	if err != nil {
		return nil
	}

	var byFile map[string][]valeAlert
	if json.Unmarshal(out, &byFile) != nil {
		return nil
	}
	var all []valeAlert
	for _, list := range byFile {
		all = append(all, list...)
	}
	return all
}

func findings(text string) []string {
	found := alerts(text)
	// One tell is a slip, and spending the user's turn on a slip is worse than
	// letting it through.
	if len(found) <= maxTells {
		return nil
	}
	var lines []string
	for _, a := range found {
		if a.Match == "" {
			lines = append(lines, fmt.Sprintf("%s (line %d)", a.Message, a.Line))
			continue
		}
		lines = append(lines, fmt.Sprintf("%s: %q (line %d)", a.Message, a.Match, a.Line))
	}
	return lines
}

func reason(found []string) string {
	return fmt.Sprintf(`That reply reads like agent prose. What the gate found:

  - %s

Send it again in ASD-STE100, in this shape and nothing else:

  1. What changed, in one sentence per change.
  2. Why, only where the change is not self-explaining.
  3. The next concrete action.

One instruction per sentence, active voice, one term per concept. Numbers, not
adjectives. Keep a sentence under 25 words. Use a list or a table when it
carries the answer better than a sentence.`,
		strings.Join(found, "\n  - "))
}

func check(stdin io.Reader) int {
	if os.Getenv("SYSINIT_PROSE_GATE") == "off" {
		return 0
	}

	data, err := io.ReadAll(stdin)
	if err != nil {
		return 0
	}
	var ev stopEvent
	if json.Unmarshal(data, &ev) != nil {
		return 0
	}
	// The rewrite gets one pass. A gate that fires on its own correction is a
	// loop the user cannot interrupt.
	if ev.StopHookActive || ev.LastAssistantMessage == "" {
		return 0
	}

	found := findings(ev.LastAssistantMessage)
	if len(found) == 0 {
		return 0
	}

	encoded, err := json.Marshal(blockDecision{Decision: "block", Reason: reason(found)})
	if err != nil {
		return 0
	}
	arm(ev.SessionID)
	fmt.Println(string(encoded))
	return 0
}

func remind(stdin io.Reader) int {
	if os.Getenv("SYSINIT_PROSE_GATE") == "off" {
		return 0
	}
	var ev stopEvent
	if data, err := io.ReadAll(stdin); err == nil {
		_ = json.Unmarshal(data, &ev)
	}
	if !disarm(ev.SessionID) {
		return 0
	}
	return inject("UserPromptSubmit",
		"Answer shape: what changed, why, next action. ASD-STE100, one sentence under 25 words per instruction. No em-dash, no preamble, no closing summary. Use a list when it carries the answer better.")
}

// The output style is already loaded at this point and sits in the same position
// in the window, so restating it here buys nothing. These three rules are not
// stated anywhere else, and a fresh or compacted session has no other way to
// learn them.
//
// A fourth rule used to sit here: give any command that can print without bound a
// limit. bash-guard now rewrites such a command through `updatedInput`, so the
// bound holds whether or not the rule is read. A stated rule the model may skip
// is strictly worse than a hook that cannot be skipped, and it costs bytes on
// every session start.
func session() int {
	if os.Getenv("SYSINIT_PROSE_GATE") == "off" {
		return 0
	}
	return inject("SessionStart", `IMPORTANT: context is the budget that runs out first. YOU MUST spend it on purpose.

  - Grep or Glob to find the lines. Read the range, not the file.
  - Delegate a search that spans many files to a subagent, which reads in its own
    window and reports back the conclusion.
  - Never re-read a file to confirm an edit that Edit or Write already reported.`)
}

// A teammate's report is the entire cost of delegating: the caller pays for it
// in the window the delegation was meant to protect. Size is the only thing
// worth gating here, because a report is data and the style rules are not.
func subagent(stdin io.Reader) int {
	if os.Getenv("SYSINIT_PROSE_GATE") == "off" {
		return 0
	}
	data, err := io.ReadAll(stdin)
	if err != nil {
		return 0
	}
	var ev stopEvent
	if json.Unmarshal(data, &ev) != nil {
		return 0
	}
	if ev.StopHookActive || len(ev.LastAssistantMessage) <= maxReportBytes {
		return 0
	}

	encoded, err := json.Marshal(blockDecision{
		Decision: "block",
		Reason: fmt.Sprintf(`That report is %d KiB and the budget is %d KiB. It lands whole in the caller's
context window, so it has to carry the conclusion, not the material.

Send it again with:

  1. The answer, in one or two sentences.
  2. The evidence as file:line pointers. The caller can read what it needs.
  3. What you could not determine, and where you stopped.

Quote a file only where the exact text is the finding.`,
			len(ev.LastAssistantMessage)/1024, maxReportBytes/1024),
	})
	if err != nil {
		return 0
	}
	fmt.Println(string(encoded))
	return 0
}

func lint(stdin io.Reader) int {
	data, err := io.ReadAll(stdin)
	if err != nil {
		fmt.Fprintf(os.Stderr, "prose-gate: %v\n", err)
		return 2
	}
	if stylePath() == "" {
		fmt.Fprintln(os.Stderr, "prose-gate: SYSINIT_PROSE_STYLE is unset, so nothing was checked")
		return 2
	}
	// lint reports every alert. check spends the user's turn on what it reports,
	// so it stays quiet until there is more than one, and the two counts differ
	// on purpose.
	all := alerts(string(data))
	for _, a := range all {
		fmt.Printf("  - %s: %q (line %d) [%s]\n", a.Message, a.Match, a.Line, a.Check)
	}
	if len(all) <= maxTells {
		fmt.Printf("%d alerts; check blocks above %d, so this passes\n", len(all), maxTells)
		return 0
	}
	fmt.Printf("%d alerts; check blocks above %d, so this is sent back\n", len(all), maxTells)
	return 1
}

func Run(args []string) int {
	if len(args) == 0 {
		fmt.Fprint(os.Stderr, usage)
		return 2
	}
	switch args[0] {
	case "check":
		return check(os.Stdin)
	case "remind":
		return remind(os.Stdin)
	case "session":
		return session()
	case "subagent":
		return subagent(os.Stdin)
	case "lint":
		return lint(os.Stdin)
	case "-h", "--help", "help":
		fmt.Print(usage)
		return 0
	default:
		fmt.Fprint(os.Stderr, usage)
		return 2
	}
}
