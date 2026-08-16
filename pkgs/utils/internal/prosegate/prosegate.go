package prosegate

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"regexp"
	"strings"
)

const Summary = "hold a Stop hook until the reply is short and in ASD-STE100"

const usage = `prose-gate: send a reply back when it reads like agent prose

Usage:
  prose-gate check     Stop hook. Reads the event on stdin, blocks a reply that
                       is over budget or carries the tells.
  prose-gate remind    UserPromptSubmit hook. Prints the shape and the budget.
  prose-gate lint      Reads text on stdin, prints the findings, exits 1 on any.

The budget counts prose only: fenced code, headings, lists, tables and quotes are
not counted and are not read for tells. Off with SYSINIT_PROSE_GATE=off.
`

const (
	maxParagraphs = 3
	maxWords      = 180
	// One tell is a slip. Two is the register the reply was written in, and only
	// the register is worth a turn to fix.
	maxTells = 1
)

type stopEvent struct {
	LastAssistantMessage string `json:"last_assistant_message"`
	StopHookActive       bool   `json:"stop_hook_active"`
}

type blockDecision struct {
	Decision string `json:"decision"`
	Reason   string `json:"reason"`
}

type promptOutput struct {
	HookSpecificOutput promptContext `json:"hookSpecificOutput"`
}

type promptContext struct {
	HookEventName     string `json:"hookEventName"`
	AdditionalContext string `json:"additionalContext"`
}

type tell struct {
	name    string
	pattern *regexp.Regexp
}

// Every entry is a rule the sysinit-ste output style already states. The
// patterns stay narrow on purpose: a false positive spends a whole turn.
var tells = []tell{
	{"em-dash", regexp.MustCompile(`—`)},
	{"bold-first-term bullet", regexp.MustCompile(`(?m)^\s*[-*+]\s+\*\*`)},
	{"negative parallelism", regexp.MustCompile(`(?i)\b(not just|not only|isn't just|is not just|rather than a)\b`)},
	{"hedge before the claim", regexp.MustCompile(`(?i)(it'?s worth noting|it is worth noting|this is nuanced|it could be argued|i should note that)`)},
	{"filler opener", regexp.MustCompile(`(?i)^(great question|certainly|of course|absolutely)[,!.]`)},
	{"significance inflation", regexp.MustCompile(`(?i)\b(pivotal|a significant shift|a broader movement|game.changer)\b`)},
	{"marketing verb", regexp.MustCompile(`(?i)\b(seamless(ly)?|effortless(ly)?|leverage[sd]?|unlock(s|ed)?|empower(s|ed)?|streamline[sd]?|delve[sd]?|showcase[sd]?|foster(s|ed)?)\b`)},
	{"trailing -ing analysis", regexp.MustCompile(`(?i),\s+(reflecting|underscoring|highlighting|showcasing|demonstrating)\s+[^.]*\.`)},
}

var fence = regexp.MustCompile("(?s)```.*?(```|$)")

func isProse(block string) bool {
	lines := strings.Split(block, "\n")
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" {
			continue
		}
		switch {
		case strings.HasPrefix(trimmed, "#"),
			strings.HasPrefix(trimmed, ">"),
			strings.HasPrefix(trimmed, "|"),
			strings.HasPrefix(trimmed, "- "),
			strings.HasPrefix(trimmed, "* "),
			strings.HasPrefix(trimmed, "+ "):
			continue
		}
		if regexp.MustCompile(`^\d+[.)]\s`).MatchString(trimmed) {
			continue
		}
		return true
	}
	return false
}

// Prose is what the reader has to read as sentences. A list, a heading, a table
// and a code block all carry their own shape, so counting them as prose would
// make a well-shaped reply look like a wall of text.
func prose(text string) []string {
	stripped := fence.ReplaceAllString(text, "")
	var kept []string
	for _, block := range strings.Split(stripped, "\n\n") {
		if strings.TrimSpace(block) == "" {
			continue
		}
		if isProse(block) {
			kept = append(kept, strings.TrimSpace(block))
		}
	}
	return kept
}

func words(blocks []string) int {
	n := 0
	for _, block := range blocks {
		n += len(strings.Fields(block))
	}
	return n
}

func findings(text string) []string {
	blocks := prose(text)
	body := strings.Join(blocks, "\n\n")

	var found []string
	if len(blocks) > maxParagraphs {
		found = append(found, fmt.Sprintf("%d prose paragraphs, budget is %d", len(blocks), maxParagraphs))
	}
	if n := words(blocks); n > maxWords {
		found = append(found, fmt.Sprintf("%d words of prose, budget is %d", n, maxWords))
	}

	tellCount := 0
	for _, t := range tells {
		hits := t.pattern.FindAllString(body, -1)
		if len(hits) == 0 {
			continue
		}
		tellCount += len(hits)
		found = append(found, fmt.Sprintf("%s: %s", t.name, strings.Join(hits, ", ")))
	}

	// A size finding alone blocks. Tells block only once there are enough of them
	// to be the register rather than one slip.
	sized := len(found) > tellCount
	if !sized && tellCount <= maxTells {
		return nil
	}
	return found
}

func reason(found []string) string {
	return fmt.Sprintf(`That reply reads like agent prose. What the gate found:

  - %s

Send it again in ASD-STE100, in this shape and nothing else:

  1. What changed, in one sentence per change.
  2. Why, only where the change is not self-explaining.
  3. The next concrete action.

One instruction per sentence, active voice, one term per concept. Numbers, not
adjectives. No em-dash, no preamble, no recap, no closing summary. At most %d
prose paragraphs and %d words; a list or a table does not count against either,
so use one when it carries the answer better than a sentence.`,
		strings.Join(found, "\n  - "), maxParagraphs, maxWords)
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
	fmt.Println(string(encoded))
	return 0
}

func remind() int {
	if os.Getenv("SYSINIT_PROSE_GATE") == "off" {
		return 0
	}
	text := fmt.Sprintf(
		"Answer shape: what changed, why, next action. ASD-STE100, at most %d prose paragraphs and %d words, lists and tables excluded. No em-dash, no preamble, no closing summary.",
		maxParagraphs, maxWords)
	encoded, err := json.Marshal(promptOutput{promptContext{"UserPromptSubmit", text}})
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
	blocks := prose(string(data))
	fmt.Printf("prose paragraphs: %d/%d\nprose words: %d/%d\n",
		len(blocks), maxParagraphs, words(blocks), maxWords)
	found := findings(string(data))
	if len(found) == 0 {
		fmt.Println("clean")
		return 0
	}
	for _, f := range found {
		fmt.Printf("  - %s\n", f)
	}
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
		return remind()
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
