package prosegate

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/internal/paths"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/hookfmt"
)

const Summary = "hold a Stop hook until the reply is short and in ASD-STE100"

const usage = `prose-gate: send a reply back when it reads like agent prose

Usage:
  prose-gate check     Stop hook. Reads the event on stdin, blocks a reply that
                       carries the tells. The block carries the corrected lines,
                       so only a fault with no mechanical rewrite costs thought.
  prose-gate remind    UserPromptSubmit hook. Prints the shape on the first
                       prompt of a session, and again after the gate has blocked
                       a reply. Silent otherwise. A prompt ending in "noterse"
                       skips the reminder and the next check.
  prose-gate session   SessionStart hook. Prints the context rules, which a fresh
                       or compacted session has just lost.
  prose-gate subagent  SubagentStop hook. Blocks a teammate report that returns
                       the material instead of the conclusion.
  prose-gate lint      Reads text on stdin, prints the findings, exits 1 on any.
  prose-gate fix       Rewrites the .md files under the given paths in place,
                       applying every rule that carries an action. --dry-run
                       counts without writing.

check, remind, session, and subagent take --format claude|exit-code|json. It
defaults to claude, which is the shape Claude Code's hook runner reads.

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
	Prompt               string `json:"prompt"`
}

func inject(event, text string) hookfmt.Outcome {
	return hookfmt.Outcome{Kind: hookfmt.Context, Event: event, Message: text}
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
	return filepath.Join(paths.StateHome(), "sysinit", "prose-gate")
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

// The escape word comes from bigskysoftware/be-terse, which drops its injection
// when a prompt ends in "noterse". Here the injection is only half the gate, so
// the word has to reach the Stop hook as well: a reminder the user opted out of,
// followed by a block for the style they opted out of, is worse than neither.
// remind writes the marker and check spends it, so the escape lasts one turn.
func escapePath(session string) string {
	path := armPath(session)
	if path == "" {
		return ""
	}
	return path + ".noterse"
}

// noterse reports whether the prompt's last word is the escape word.
func noterse(prompt string) bool {
	fields := strings.Fields(prompt)
	if len(fields) == 0 {
		return false
	}
	return strings.EqualFold(fields[len(fields)-1], "noterse")
}

func escape(session string) {
	path := escapePath(session)
	if path == "" {
		return
	}
	if os.MkdirAll(filepath.Dir(path), 0o755) != nil {
		return
	}
	_ = os.WriteFile(path, []byte("noterse\n"), 0o644)
}

// release reports whether this reply is exempt, and spends the exemption.
func release(session string) bool {
	path := escapePath(session)
	if path == "" {
		return false
	}
	if _, err := os.Stat(path); err != nil {
		return false
	}
	_ = os.Remove(path)
	return true
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
	Span     []int  `json:"Span"`
}

// at is the alert's position, for deduplication. Two rules that own one span
// are one fault.
func (a valeAlert) at() [3]int {
	from, to := 0, 0
	if len(a.Span) > 0 {
		from = a.Span[0]
	}
	if len(a.Span) > 1 {
		to = a.Span[1]
	}
	return [3]int{a.Line, from, to}
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
	// Every path out of this function that is not "vale ran and found nothing"
	// says so. A gate that opens quietly is worse than no gate, because it is
	// trusted: one unsupported key on one rule already turned the whole check
	// into a pass with no sign of it.
	config := stylePath()
	if config == "" {
		fmt.Fprintln(os.Stderr, "prose-gate: $SYSINIT_PROSE_STYLE is unset, so nothing was checked")
		return nil
	}
	binary, err := exec.LookPath("vale")
	if err != nil {
		fmt.Fprintln(os.Stderr, "prose-gate: vale is not on PATH, so nothing was checked")
		return nil
	}

	// --no-global is what makes the rule set this repository's. Vale merges the
	// user config at ~/.vale.ini into every run, and a hand-written Sysinit
	// style under ~/.local/share/vale/styles then replaced these rules
	// wholesale: the gate ran 12 foreign rules and reported their messages.
	// Nothing in the output said the rule set had changed.
	cmd := exec.Command(binary, "--config="+config, "--no-global", "--output=JSON", "--ext=.md", "--no-exit")
	cmd.Stdin = strings.NewReader(undirect(text))
	// A malformed rule makes vale lint nothing, which read as "no alerts"
	// silently disabled every check: one invalid key on one rule turned the
	// whole gate into a pass. Measured on vale 3.17.1 with an unsupported
	// `tokenIgnores` key.
	//
	// `--no-exit` suppresses only the alert-driven status. A config error still
	// exits 2, so the exit code is the signal and not the body. An earlier
	// revision warned on an unparseable body instead, which is a path vale
	// never takes.
	//
	// The reply still goes through, because a broken rule set is the
	// repository's fault and not the reader's. The warning is what makes it
	// visible instead of silent.
	out, err := cmd.Output()
	if err != nil {
		fmt.Fprintf(os.Stderr, "prose-gate: vale could not run, so nothing was checked: %s\n", valeError(err, out))
		return nil
	}

	var byFile map[string][]valeAlert
	if json.Unmarshal(out, &byFile) != nil {
		fmt.Fprintf(os.Stderr, "prose-gate: vale returned no alert set, so nothing was checked: %s\n",
			firstLine(strings.TrimSpace(string(out))))
		return nil
	}
	var all []valeAlert
	for _, list := range byFile {
		all = append(all, list...)
	}
	return all
}

// findings decides whether the reply is sent back. It is separate from the fix
// list, because the block is judged on the raw reply and the fix list is built
// from what the applier could not repair.
func findings(text string) []valeAlert {
	found := oneAlertPerSpan(alerts(text))
	// One tell is a slip, and spending the user's turn on a slip is worse than
	// letting it through.
	if len(found) <= maxTells {
		return nil
	}
	return found
}

// reason is the whole message the model gets back. It leads with the lines the
// gate already rewrote, because those need no judgement and reading them is
// cheaper than deriving them again. What is left needs a person's decision, so
// it is listed second and the shape rules come last.
func reason(fixes []correction, manual []valeAlert) string {
	var b strings.Builder
	b.WriteString("That reply reads like agent prose.\n")

	if len(fixes) > 0 {
		b.WriteString("\nThese lines are already rewritten. Send them exactly as they are:\n\n")
		for i, f := range fixes {
			if i == maxCorrections {
				fmt.Fprintf(&b, "  ... and %d more line(s), same rules\n", len(fixes)-maxCorrections)
				break
			}
			fmt.Fprintf(&b, "  line %d: %s\n", f.Line, f.Text)
		}
	}

	if len(manual) > 0 {
		fmt.Fprintf(&b, "\n%d faults have no mechanical rewrite. Fix every one before sending:\n\n", len(manual))
		for _, g := range groupByRule(manual) {
			fmt.Fprintf(&b, "  - %s\n", g)
		}
	}

	b.WriteString(`
Send the whole reply again in ASD-STE100, in this shape and nothing else:

  1. What changed, in one sentence per change.
  2. Why, only where the change is not self-explaining.
  3. The next concrete action.

One instruction per sentence, active voice, one term per concept. Numbers, not
adjectives. Keep a sentence under 25 words. Use a list or a table when it
carries the answer better than a sentence.`)
	return b.String()
}

// Check decides whether the reply is sent back. It is the whole prose-gate
// decision, with no harness in it.
func Check(stdin io.Reader) hookfmt.Outcome {
	if os.Getenv("SYSINIT_PROSE_GATE") == "off" {
		return hookfmt.PassOutcome()
	}

	data, err := io.ReadAll(stdin)
	if err != nil {
		return hookfmt.PassOutcome()
	}
	var ev stopEvent
	if json.Unmarshal(data, &ev) != nil {
		return hookfmt.PassOutcome()
	}
	// The rewrite gets one pass. A gate that fires on its own correction is a
	// loop the user cannot interrupt.
	if ev.StopHookActive || ev.LastAssistantMessage == "" {
		return hookfmt.PassOutcome()
	}
	if release(ev.SessionID) {
		return hookfmt.PassOutcome()
	}

	if len(findings(ev.LastAssistantMessage)) == 0 {
		return hookfmt.PassOutcome()
	}

	// The gate cannot rewrite the reply, so it rewrites what it can and hands
	// the result back. Every mechanical fault comes back already corrected, and
	// only the ones needing a decision cost the model any thought.
	fixes, manual := corrections(stylePath(), ev.LastAssistantMessage)
	arm(ev.SessionID)
	return hookfmt.Outcome{Kind: hookfmt.Block, Event: "Stop", Message: reason(fixes, manual)}
}

// Claude Code re-states a built-in output style on every turn, from that style's
// `turnReminder` field. It does not do this for a custom style: the renderer
// looks the active style up in the built-in table and returns nothing when the
// name is absent, so `sysinit-ste` is stated once at session start and never
// again. This reminder is that missing per-turn line, which is why it names the
// style rather than only its rules.
func remind(stdin io.Reader) hookfmt.Outcome {
	if os.Getenv("SYSINIT_PROSE_GATE") == "off" {
		return hookfmt.PassOutcome()
	}
	var ev stopEvent
	if data, err := io.ReadAll(stdin); err == nil {
		_ = json.Unmarshal(data, &ev)
	}
	if noterse(ev.Prompt) {
		escape(ev.SessionID)
		return hookfmt.PassOutcome()
	}
	if !disarm(ev.SessionID) {
		return hookfmt.PassOutcome()
	}
	return inject("UserPromptSubmit",
		"The sysinit-ste output style is active. Follow it. Answer shape: what changed, why, next action. One sentence under 25 words per instruction. No em-dash, no preamble, no plan announcement, no closing summary. Keep an error, a failing test, or a destructive-action confirmation whole.")
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
func session() hookfmt.Outcome {
	if os.Getenv("SYSINIT_PROSE_GATE") == "off" {
		return hookfmt.PassOutcome()
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
func subagent(stdin io.Reader) hookfmt.Outcome {
	if os.Getenv("SYSINIT_PROSE_GATE") == "off" {
		return hookfmt.PassOutcome()
	}
	data, err := io.ReadAll(stdin)
	if err != nil {
		return hookfmt.PassOutcome()
	}
	var ev stopEvent
	if json.Unmarshal(data, &ev) != nil {
		return hookfmt.PassOutcome()
	}
	if ev.StopHookActive || len(ev.LastAssistantMessage) <= maxReportBytes {
		return hookfmt.PassOutcome()
	}

	return hookfmt.Outcome{
		Kind:  hookfmt.Block,
		Event: "SubagentStop",
		Message: fmt.Sprintf(`That report is %d KiB and the budget is %d KiB. It lands whole in the caller's
context window, so it has to carry the conclusion, not the material.

Send it again with:

  1. The answer, in one or two sentences.
  2. The evidence as file:line pointers. The caller can read what it needs.
  3. What you could not determine, and where you stopped.

Quote a file only where the exact text is the finding.`,
			len(ev.LastAssistantMessage)/1024, maxReportBytes/1024),
	}
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
	// The same dedupe `findings` applies, so `lint` reports the number that
	// actually decides the block. Without it the operator-facing command and
	// the gate disagreed: a heading em-dash read as 2 in lint and 1 in check.
	all := oneAlertPerSpan(alerts(string(data)))
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
	// lint and fix write for a person, not for a hook, so they take no --format.
	switch args[0] {
	case "lint":
		return lint(os.Stdin)
	case "fix":
		return fix(args[1:])
	case "-h", "--help", "help":
		fmt.Print(usage)
		return 0
	}

	format, rest, err := hookfmt.ParseFormat(args[1:], hookfmt.Claude)
	if err != nil {
		fmt.Fprintf(os.Stderr, "prose-gate: %s\n", err)
		return 1
	}
	if len(rest) > 0 {
		fmt.Fprintf(os.Stderr, "prose-gate: unknown argument: %s\n", rest[0])
		return 1
	}
	switch args[0] {
	case "check":
		return hookfmt.Emit(format, Check(os.Stdin))
	case "remind":
		return hookfmt.Emit(format, remind(os.Stdin))
	case "session":
		return hookfmt.Emit(format, session())
	case "subagent":
		return hookfmt.Emit(format, subagent(os.Stdin))
	default:
		fmt.Fprint(os.Stderr, usage)
		return 2
	}
}

// firstLine keeps the warning to one line. Vale's config errors are one line
// each and the first names the rule.
func firstLine(text string) string {
	if at := strings.IndexByte(text, '\n'); at >= 0 {
		return text[:at]
	}
	return text
}

// valeError reads the reason out of vale's own error object. On a config error
// vale writes one JSON object to stderr, whose Text field carries the E-code
// and the explanation over several lines. The first line of that field is the
// one the operator needs.
func valeError(err error, stdout []byte) string {
	body := stdout
	var exit *exec.ExitError
	if errors.As(err, &exit) && len(exit.Stderr) > 0 {
		body = exit.Stderr
	}
	// Text already opens with the code, so the Code field would only repeat it.
	var held struct {
		Text string `json:"Text"`
	}
	if json.Unmarshal(body, &held) == nil && held.Text != "" {
		return firstLine(strings.TrimSpace(held.Text))
	}
	return fmt.Sprintf("%v: %s", err, firstLine(strings.TrimSpace(string(body))))
}

// undirect removes vale's own inline control comments. The gate reads the text
// the model wrote, and vale obeys a directive it finds there: one
// `<!-- vale off -->` at the top of a reply took 4 alerts to 0, and an HTML
// comment renders invisibly, so nothing showed. A gate the governed party can
// switch off is not a gate.
//
// The comment is dropped rather than escaped, because a reply that names a
// directive on purpose does so in a fence, and a fence is not what vale reads
// a directive from.
var valeDirective = regexp.MustCompile(`(?is)<!--\s*vale\b.*?-->`)

func undirect(text string) string {
	return valeDirective.ReplaceAllString(text, "")
}

// oneAlertPerSpan keeps the first alert on each span. Two rules can own one
// slip, and counting both spent two tells on one fault: every em-dash in a
// heading matched DashInHeading and EmDash on the same span, so it always
// reached maxTells and always blocked. Measured over 1805 real replies, all 81
// heading-dash alerts were such a pair.
//
// The first alert wins because `alerts` returns vale's order, and
// `prose-gate fix` already breaks a same-span tie by rule name for the same
// reason.
func oneAlertPerSpan(in []valeAlert) []valeAlert {
	seen := make(map[[3]int]bool, len(in))
	out := make([]valeAlert, 0, len(in))
	for _, one := range in {
		if seen[one.at()] {
			continue
		}
		seen[one.at()] = true
		out = append(out, one)
	}
	return out
}

// groupByRule folds the manual list to one line per rule, with every match on
// it. Seventeen faults over nine rules printed seventeen lines, and only the
// first three survived the trip back to the model, so a rewrite fixed three and
// the next attempt blocked on the rest. One line per rule is the whole set in a
// third of the bytes, and it reads as one instruction rather than as a list of
// incidents.
//
// Rule order follows first appearance, so the reply is fixed top down.
func groupByRule(in []valeAlert) []string {
	order := []string{}
	byRule := map[string][]string{}
	message := map[string]string{}
	for _, a := range in {
		if _, seen := byRule[a.Check]; !seen {
			order = append(order, a.Check)
			message[a.Check] = a.Message
		}
		hit := a.Match
		if hit == "" {
			hit = fmt.Sprintf("line %d", a.Line)
		}
		byRule[a.Check] = append(byRule[a.Check], fmt.Sprintf("%q", hit))
	}
	out := make([]string, 0, len(order))
	for _, rule := range order {
		hits := byRule[rule]
		line := message[rule]
		if len(hits) > 1 {
			line = fmt.Sprintf("%s (%d)", line, len(hits))
		}
		out = append(out, line+": "+strings.Join(hits, ", "))
	}
	return out
}
