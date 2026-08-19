// The prose rule set, stated once.
//
// `overlays/vale-styles.nix` exports every entry in `rules` to one Vale rule
// file under `styles/Sysinit/`, and exports `ini` to `vale.ini`. Generation
// runs inside the derivation, so nothing is checked in and nothing can drift.
//
// Vale is Go, so a pattern here is a Go regexp and ports from the old
// hand-rolled table unchanged.
package prosestyle

import "strings"

#Level: "error" | "warning" | "suggestion"

// Vale carries an action through `--output=JSON` but never applies one: the CLI
// has no fix flag, and only editor integrations consume these. `prose-gate fix`
// reads the JSON and applies them, so an action here is a real edit.
//
// Only a rule with one correct mechanical rewrite gets an action. A marketing
// verb has no single replacement and a long sentence has no mechanical split,
// so those stay advisory and a person fixes them.
#Action: {
	name: "replace" | "remove" | "edit"
	params?: [...string]
}

// `raw` takes the pattern verbatim. `tokens` would wrap each entry in word
// boundaries, which breaks a pattern that is already anchored or that has to
// match punctuation.
//
// One entry per rule, always. Vale concatenates the entries of `raw`; it does
// not alternate them. Two complete patterns therefore compile into one that
// matches nothing, and vale reports no error. Alternate inside a single entry.
// A rule that wants many independent patterns should use `tokens` with
// `nonword: true` instead, because `tokens` IS joined with `|`.
//
// Vale is not limited to RE2 here: `(?!...)` and `(?<!...)` both work, which is
// how BoldPseudoHeading carries an allowlist.
#Existence: {
	extends: "existence"
	message: string
	level:   #Level
	scope?:  string
	action?: #Action
	raw: [...string]
}

// Vale counts matches of `token` inside each instance of `scope`, so this
// bounds one sentence rather than the whole reply.
#Occurrence: {
	extends: "occurrence"
	message: string
	level:   #Level
	scope:   string
	max:     int
	token:   string
}

rules: [string]: #Existence | #Occurrence

rules: {
	// A heading almost always uses the dash to introduce, so a colon reads far
	// better there than the comma running prose wants.
	//
	// `scope: heading` does not stop EmDash from firing on the same text, and
	// Vale has no scope negation. Both alerts land on one span, and
	// `prose-gate fix` breaks the tie by rule name, ascending. This name sorts
	// before EmDash on purpose: rename it and the heading silently gets a
	// comma instead.
	DashInHeading: #Existence & {
		message: "em-dash in a heading: use a colon"
		level:   "error"
		scope:   "heading"
		action: {
			name: "replace"
			params: [": "]
		}
		raw: ["[ \\t]*—[ \\t]*"]
	}

	// A comma, a colon, or a new sentence carries the same break without the
	// typographic tell. A comma is the safe default of the three; a colon or a
	// full stop is a judgement call, so the mechanical fix takes the comma.
	//
	// The match takes the surrounding spaces with it. `prose-gate fix` still
	// collapses a doubled space, because vale reports the match against the
	// text the rule saw and that text does not always carry the whole gap.
	//
	// The scope stays off `raw`. This repository has 65 em-dashes inside fenced
	// blocks, and a raw-scope rule would rewrite sample code and its comments.
	EmDash: #Existence & {
		message: "em-dash: use a comma, a colon, or a new sentence"
		level:   "error"
		action: {
			name: "replace"
			params: [", "]
		}
		raw: ["[ \\t]*—[ \\t]*"]
	}

	// Markdown markup is stripped in the default scope, so this one reads the
	// file as written. The old gate matched this against prose with every
	// bullet already removed, so it could never fire.
	//
	// This replaces an earlier BoldFirstTerm that required `**` right after the
	// marker. It caught 1 of the 4 shapes: `- *x*`, `- __x__` and `1. **x**` all
	// passed. Measured 43 hits across 5 tracked files at the wider pattern.
	EmphasisInBullet: #Existence & {
		message: "emphasis on a bullet's first term: use a sub-bullet for the detail"
		level:   "error"
		scope:   "raw"
		// The match spans both delimiter pairs so the fix drops them together.
		// Matching only the opening pair would leave the closing one behind and
		// produce broken markdown.
		//
		// `*` is left out of the marker class deliberately. The match has to
		// include the marker, and the action strips every `*` and `_` inside the
		// match, so a `*` bullet would lose its own marker. A `*` bullet is
		// therefore not checked. Nothing in this repository uses one.
		//
		// `\s` would swallow the preceding newline, which reports the match on
		// the line above and prints a literal "\n" back at the reader.
		action: {
			name: "edit"
			params: ["regex", "[*_]", ""]
		}
		raw: ["(?m)^[ \\t]*([-+]|\\d+[.)])[ \\t]+([*_]{1,2})[^*_\\n]+([*_]{1,2})"]
	}

	// Bold marks a real exception. A regex cannot judge whether one span earns
	// its place, so this counts instead. `scope: raw` makes the whole reply one
	// instance, which is what bounds a reply rather than a paragraph.
	//
	// 2 is close to current practice: 10 hits across the 41 tracked .md files.
	//
	// The backtick guard keeps an immediately-wrapped literal out of the count,
	// as in "the `**SHAPE**` marker", where the bold is the thing being quoted.
	// It only inspects the one character on each side, so a span that holds more
	// than the bold still counts: "`- **SHAPE** loop|graph`" does.
	//
	// `TokenIgnores` is the general answer to that and does not apply here. It
	// runs in the markup pipeline, and `scope: raw` is defined as bypassing it.
	// openspec-schema/CHANGES.md quotes these markers throughout and keeps one
	// standing alert for the reason.
	//
	// `max` must stay above 0. Vale cannot tell `max: 0` from an unset field, so
	// it drops the bound and the rule goes silent.
	BoldBudget: #Occurrence & {
		message: "more than 2 bold spans: bold marks a real exception, not emphasis"
		level:   "error"
		scope:   "raw"
		max:     2
		token:   "(?<!`)(\\*\\*|__)[^*_\\n]+(\\*\\*|__)(?!`)"
	}

	// A bold label opening a line is a heading that refused to be one. Use a
	// real heading, or drop the label and write the sentence.
	//
	// `**Why:**` and `**How to apply:**` are exempt: the memory format requires
	// them. The gate reads `last_assistant_message` and never a file, so the
	// exemption only matters when vale is pointed at the memory directory by
	// hand. It is stated anyway, because the cost is one lookahead.
	BoldPseudoHeading: #Existence & {
		message: "bold label as a heading: use a real heading or plain prose"
		level:   "error"
		scope:   "raw"
		raw: ["(?m)^[ \\t]*\\*\\*(?!Why:|How to apply:)[^*\\n]+\\*\\*:?([ \\t]*$|[ \\t]+\\S)"]
	}

	// Self-dramatising escalation: the reply announces that the state is worse
	// than the last one said, instead of giving the new fact and its size.
	//
	// "3 more call sites, not 1" carries the same news and is checkable. The
	// frame is banned even when the state really did get worse, because the
	// number says it better.
	//
	// 0 hits across the 41 tracked .md files. This fires in replies, which is
	// where the Stop hook reads, and never in committed prose.
	Escalation: #Existence & {
		message: "escalation frame: give the new fact and its size, not that it is worse"
		level:   "error"
		raw: ["(?i)\\b(and it gets worse|even worse|worse still|worse than (we|i) (thought|expected|said|reported)|worse than (stated|reported|described|first appeared)|far worse|much worse|significantly worse|actually worse|objection \\d+ (upheld|sustained|overruled|withdrawn))\\b"]
	}

	// State the thing you mean and drop the half you dismissed.
	//
	// "rather than a" was in this list and was wrong every time it fired. All
	// four hits in this repository were plain comparisons, as in "prints nothing
	// rather than a blank line". The frame this rule is after always negates
	// first, so only the negating forms stay.
	//
	// The pattern is Slop.NegativeParallelism, ported so the message stays this
	// repository's. It asks for the whole frame: a negation, then a pivot to
	// "it's", "but" or "rather". The five bare tokens it replaces were wrong in
	// both directions. They missed "This isn't a refactor. It's a rewrite.",
	// which crosses a sentence boundary, and they fired on "do not just print
	// nothing rather than a blank line", which is a plain comparison.
	//
	// Five alternations in one entry, because `raw` concatenates its entries.
	NegativeParallelism: #Existence & {
		message: "negative parallelism: state only the thing you mean"
		level:   "error"
		raw: ["(?i)(\\b(?:(?:is|are|was|were|it.s|they.re)\\s+not|isn.t|aren.t|wasn.t|weren.t)\\s+(?:just|only|merely|simply)\\b[^.!?]{0,80}[—–,;:]\\s*(?:it.s|they.re|it\\s+is|they\\s+are|but|rather)\\b|\\b(?:isn.t|aren.t|wasn.t|weren.t|is\\s+not|are\\s+not)\\b[^.!?]{0,60}\\.\\s+(?:it.s|they.re|it\\s+is|they\\s+are)\\b|\\bnot\\s+only\\b[^.!?]{0,80}\\bbut\\s+also\\b|\\bnot\\s+(?:just|merely|simply)\\s+(?:about|a|an|the)\\b[^.!?]{0,60}[—–,]\\s*but\\b|\\bless\\s+about\\b[^.!?]{0,60}\\band\\s+more\\s+about\\b)"]
	}

	HedgeBeforeClaim: #Existence & {
		message: "hedge before the claim: make the claim and defend it"
		level:   "error"
		raw: ["(?i)(it'?s worth noting|it is worth noting|this is nuanced|it could be argued|i should note that)"]
	}

	// Slop.Assistant covers the same ground and is switched on in `ini`, but it
	// does not replace this rule. Measured against the four openers here it
	// caught one: its tokens want `certainly!` and `of course!` with the
	// exclamation mark, and this rule wants the comma that a reply actually
	// uses. Both run.
	FillerOpener: #Existence & {
		message: "filler opener: start with the substance"
		level:   "error"
		raw: ["(?i)^(great question|certainly|of course|absolutely)[,!.]"]
	}

	SignificanceInflation: #Existence & {
		message: "significance inflation: say what happened, and when"
		level:   "error"
		raw: ["(?i)\\b(pivotal|a significant shift|a broader movement|game.changer)\\b"]
	}

	MarketingVerb: #Existence & {
		message: "marketing verb: use a concrete verb"
		level:   "error"
		raw: ["(?i)\\b(seamless(ly)?|effortless(ly)?|leverage[sd]?|unlock(s|ed)?|empower(s|ed)?|streamline[sd]?|delve[sd]?|showcase[sd]?|foster(s|ed)?)\\b"]
	}

	// The rule's own instruction is to delete the clause, so the whole match
	// collapses to the full stop it was standing in front of.
	TrailingIngAnalysis: #Existence & {
		message: "trailing -ing analysis: delete the clause"
		level:   "error"
		action: {
			name: "edit"
			params: ["regex", "^.*$", "."]
		}
		raw: ["(?i),\\s+(reflecting|underscoring|highlighting|showcasing|demonstrating)\\s+[^.]*\\."]
	}

	// ASD-STE100 caps a procedure sentence at 20 words and a descriptive one at
	// 25. Vale cannot tell the two apart, so the ceiling is the looser of them
	// and a long procedure sentence is left to the reader.
	SentenceLength: #Occurrence & {
		message: "sentence over 25 words: split it"
		level:   "error"
		scope:   "sentence"
		max:     25
		token:   "\\b\\w+\\b"
	}
}

// Borrowed styles carry the rules this repository has no reason to restate.
// They are vendored by `overlays/vale-styles.nix`, because `vale sync` needs
// network and a Nix build has none.
//
// This is the audit config's BasedOnStyles, not the vendor list. The overlay
// vendors STE as well, and STE never appears here: at suggestion level it is
// 1015 alerts against Slop's 38 on the same 41 files. Only the two STE rules in
// `promoted` run, which needs the style on disk and not in BasedOnStyles.
auditStyles: ["proselint", "write-good", "alex", "Slop"]

// Rules borrowed one at a time rather than a style at a time. Vale runs a rule
// named here even when its style is absent from BasedOnStyles, which is what
// lets the hook take six rules out of two noisy styles.
//
// Slop as a whole is 38 alerts across the 41 tracked .md files, low enough for
// the audit config. STE as a whole is 1015 on the same files and never goes in:
// STE.Gerunds alone is 363, and it flags a skill titled "Writing".
promoted: {
	// 12 tokens of chat-assistant voice. FillerOpener stays alongside it.
	"Slop.Assistant": "error"
	// Three parallel modifiers where one would do. The output style names this
	// pattern and nothing here implemented it. 0 hits on the tracked files.
	"Slop.Tricolon": "error"
	// A virtue the reader cannot check: "ensures correctness", "gracefully".
	"Slop.SelfPraise": "error"
	// "this is by design", standing in for the reason. 0 hits.
	"Slop.VagueReasons": "error"
	// ASD-STE100 caps a paragraph at six sentences. 11 hits.
	"STE.ParagraphLength": "error"
	// One instruction per sentence, scoped to list items. 5 hits.
	"STE.OneInstruction": "error"
}

promotedIni: strings.Join([for k, v in promoted {"\(k) = \(v)"}], "\n")

// Two configs, because the two jobs want different noise floors.
//
// The hook config is Sysinit plus the six rules in `promoted`. prose-gate spends
// the user's turn on what it reports, so a rule here has to be one this
// repository actually decided. proselint and write-good are advisory by design
// and would block most replies, so neither style goes in wholesale.
ini: """
	StylesPath = styles
	MinAlertLevel = error

	[*.md]
	BasedOnStyles = Sysinit
	\(promotedIni)
	"""

// The audit config adds the borrowed styles and drops the floor to suggestion.
// Nothing blocks on it. Point vale at it by hand to read docs and skills:
//   vale --config=$(dirname "$SYSINIT_PROSE_STYLE")/vale-audit.ini <path>
// which is where a slow, chatty, advisory pass belongs.
auditIni: """
	StylesPath = styles
	MinAlertLevel = suggestion

	[*.md]
	BasedOnStyles = Sysinit, \(strings.Join(auditStyles, ", "))
	"""
