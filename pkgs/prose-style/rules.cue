// The prose rule set, stated once.
//
// `hack/generate-prose-style.sh` exports every entry in `rules` to one Vale
// rule file under `styles/Sysinit/`, and exports `ini` to `vale.ini`. The
// generated files are checked in so the Nix build stays offline; the hack
// script is what proves they still match this file.
//
// Vale is Go, so a pattern here is a Go regexp and ports from the old
// hand-rolled table unchanged.
package prosestyle

import "strings"

#Level: "error" | "warning" | "suggestion"

// `raw` takes the pattern verbatim. `tokens` would wrap each entry in word
// boundaries, which breaks a pattern that is already anchored or that has to
// match punctuation.
#Existence: {
	extends: "existence"
	message: string
	level:   #Level
	scope?:  string
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
	// A comma, a colon, or a new sentence carries the same break without the
	// typographic tell.
	EmDash: #Existence & {
		message: "em-dash: use a comma, a colon, or a new sentence"
		level:   "error"
		raw: ["—"]
	}

	// Markdown markup is stripped in the default scope, so this one reads the
	// file as written. The old gate matched this against prose with every
	// bullet already removed, so it could never fire.
	BoldFirstTerm: #Existence & {
		message: "bold first term in a bullet: use a sub-bullet for the detail"
		level:   "error"
		scope: "raw"
		// `\s` would swallow the preceding newline, which reports the match on
		// the line above and prints a literal "\n" back at the reader.
		raw: ["(?m)^[ \\t]*[-*+][ \\t]+\\*\\*"]
	}

	// State the thing you mean and drop the half you dismissed.
	NegativeParallelism: #Existence & {
		message: "negative parallelism: state only the thing you mean"
		level:   "error"
		raw: ["(?i)\\b(not just|not only|isn't just|is not just|rather than a)\\b"]
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

	TrailingIngAnalysis: #Existence & {
		message: "trailing -ing analysis: delete the clause"
		level:   "error"
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
