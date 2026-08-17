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
	BoldFirstTerm: #Existence & {
		message: "bold first term in a bullet: use a sub-bullet for the detail"
		level:   "error"
		scope: "raw"
		// The match spans both `**` pairs so the fix can drop them together.
		// Matching only the opening pair would leave the closing one behind and
		// produce broken markdown.
		//
		// `\s` would swallow the preceding newline, which reports the match on
		// the line above and prints a literal "\n" back at the reader.
		action: {
			name: "edit"
			params: ["regex", "\\*\\*", ""]
		}
		raw: ["(?m)^[ \\t]*[-*+][ \\t]+\\*\\*[^*\\n]+\\*\\*"]
	}

	// State the thing you mean and drop the half you dismissed.
	//
	// "rather than a" was in this list and was wrong every time it fired. All
	// four hits in this repository were plain comparisons, as in "prints nothing
	// rather than a blank line". The frame this rule is after always negates
	// first, so only the negating forms stay.
	NegativeParallelism: #Existence & {
		message: "negative parallelism: state only the thing you mean"
		level:   "error"
		raw: ["(?i)\\b(not just|not only|isn'?t just|is not just|it'?s not that)\\b"]
	}

	HedgeBeforeClaim: #Existence & {
		message: "hedge before the claim: make the claim and defend it"
		level:   "error"
		raw: ["(?i)(it'?s worth noting|it is worth noting|this is nuanced|it could be argued|i should note that)"]
	}

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
borrowed: ["proselint", "write-good", "alex"]

// Two configs, because the two jobs want different noise floors.
//
// The hook config is Sysinit alone. prose-gate spends the user's turn on what
// it reports, so a rule here has to be one this repository actually decided.
// proselint and write-good are advisory by design and would block most replies.
ini: """
	StylesPath = styles
	MinAlertLevel = error

	[*.md]
	BasedOnStyles = Sysinit
	"""

// The audit config adds the borrowed styles and drops the floor to suggestion.
// Nothing blocks on it. Point vale at it by hand to read docs and skills:
//   vale --config=$(dirname "$SYSINIT_PROSE_STYLE")/vale-audit.ini <path>
// which is where a slow, chatty, advisory pass belongs.
auditIni: """
	StylesPath = styles
	MinAlertLevel = suggestion

	[*.md]
	BasedOnStyles = Sysinit, \(strings.Join(borrowed, ", "))
	"""
