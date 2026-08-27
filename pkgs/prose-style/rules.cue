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
		raw: ["[ \\t]*[—–][ \\t]*"]
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
		raw: ["[ \\t]*[—–][ \\t]*"]
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
		// `*` is left out of the bullet-marker class deliberately. The match has
		// to include the marker, and the action strips every `*` inside the
		// match, so a `*` bullet would lose its own marker. A `*` bullet is
		// therefore not checked. Nothing in this repository uses one.
		//
		// `_` is out of the emphasis class for a harder reason: it corrupted
		// content. The interior class excludes the delimiter, so an underscore
		// inside the term ended the match early and the action then deleted it.
		// Measured: `- __snake_case__ is the identifier` was rewritten to
		// `- snakecase__ is the identifier`, on disk, and `check` handed that
		// line back as finished. A `__bold__` bullet is now unchecked, which is
		// the cheaper of the two.
		//
		// `\s` would swallow the preceding newline, which reports the match on
		// the line above and prints a literal "\n" back at the reader.
		action: {
			name: "edit"
			params: ["regex", "[*]", ""]
		}
		raw: ["(?m)^[ \\t]*([-+]|\\d+[.)])[ \\t]+(\\*{1,2})[^*\\n]+(\\*{1,2})"]
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
		raw: ["(?i)(it'?s worth (noting|considering|mentioning|remembering)|it is worth (noting|considering|mentioning|remembering)|this is nuanced|it could be argued|i should note that|it seems|\\bperhaps\\b|\\bsomewhat\\b|more or less|in some sense)"]
	}

	// Announcing the plan instead of reporting the result. Claude Code's built-in
	// Concise style names this and the output style now carries it, so this rule
	// is what makes it hold.
	//
	// One lookahead replaces a 25-verb enumeration. The enumeration existed
	// because this file claimed vale is RE2 and cannot express `(?!know\b)`.
	// That claim was wrong, and the enumeration leaked: over 1805 real replies
	// `let me <word>` appeared 24 times and the list caught 14. The 10 misses
	// included `investigate`, `review`, `show` and `raise`.
	//
	// The double count it was built to avoid never happened either.
	// Slop.Assistant asks for "let me know if you have any", not "let me know".
	Narration: #Existence & {
		message: "narration: report the outcome, not the plan"
		level:   "error"
		raw: ["(?i)(\\blet me\\s+(?!know\\b)\\w+\\b|\\b(?:now|first|next|then),?\\s+(?:i'?ll|i\\s+will|let\\s+me)\\b|\\bi'?ll\\s+(?:now|go\\s+ahead|start\\s+by|begin\\s+by)\\b|\\bi'?m\\s+going\\s+to\\b)"]
	}

	ReasoningArtifact: #Existence & {
		message: "reasoning narration: state the conclusion and its evidence"
		level:   "error"
		raw: ["(?i)\\b(breaking this down|to approach this systematically|here.s my thought process|working through this logically)\\b"]
	}

	LetsConstruction: #Existence & {
		message: "false collaboration: start with the point"
		level:   "error"
		raw: ["(?i)\\blet.s (explore|take a look|break this down|examine|consider|discuss|delve|unpack|walk through)\\b"]
	}

	AcknowledgmentLoop: #Existence & {
		message: "prompt recap: answer without restating the question"
		level:   "error"
		raw: ["(?i)\\b(you.re asking about|to answer your question)\\b"]
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

	ReaderCue: #Existence & {
		message: "reader cue: state why the fact matters"
		level:   "error"
		raw: ["(?i)\\b(here.s what.s interesting|this is the interesting part|here.s where it gets clever)\\b"]
	}

	GenericEnding: #Existence & {
		message: "generic ending: end with the next fact or action"
		level:   "error"
		raw: ["(?i)\\b(one thing is certain|as we move forward)\\b"]
	}

	// Internal citation tokens identify a broken rendered reply, so one match blocks it.
	CitationMarkup: #Existence & {
		message: "internal citation markup: replace it with a usable source link"
		level:   "error"
		raw: ["(?i)(\\bcite(?:turn|news|search|navigation)\\d+(?:search|turn|news|navigation)\\d+\\b|contentReference\\s*\\[oaicite:[^]]+\\]\\s*\\{[^}]*\\}|\\boai_citation\\b|\\[attached_file:\\d+\\]|\\bgrok_card\\b)"]
	}

	SignificanceInflation: #Existence & {
		message: "significance inflation: say what happened, and when"
		level:   "error"
		raw: ["(?i)\\b(pivotal|a significant shift|a broader movement|a paradigm shift|fundamentally (changes|transforms)|sea change|watershed)\\b"]
	}

	MarketingVerb: #Existence & {
		message: "marketing verb: use a concrete verb"
		level:   "error"
		raw: ["(?i)\\b(seamless(ly)?|effortless(ly)?|leverage[sd]?|unlock(s|ed)?|empower(s|ed)?|robust(ly)?|comprehensive(ly)?|powerful|best.in.class|game.chang(er|ing)|streamline[sd]?|delve[sd]?|showcase[sd]?|foster(s|ed)?|boasts?|serves as)\\b"]
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
		raw: ["(?i),\\s+(reflecting|underscoring|highlighting|showcasing|demonstrating|signaling|cementing)\\s+[^.]*\\."]
	}

	// Ported from conorbronsdon/avoid-ai-writing's Tier 1A frequency markers.
	// The source list is not vendored, so no count here is checkable offline and
	// none is stated: an earlier version of this comment claimed a subset of 44
	// and got both the kept count and four of its named exclusions wrong.
	//
	// What is stated instead is why a token is absent, which stays true whatever
	// the source list holds. `harness` is this repository's own domain term, and
	// `verbatim` is one. `realm` is RFC 7235's protection space, which the OAuth
	// work touches. `ecosystem`, `unpack` and `embrace` read as plain English in
	// a technical sentence. `robust` and `comprehensive` moved to MarketingVerb,
	// which is where the output style already states them.
	//
	// The rule fires on its own token list quoted as words, as MarketingVerb has
	// always done. Backtick a token to name it: an inline code span is out of
	// scope, and a fenced block is too.
	//
	// A markdown blockquote is NOT out of scope, and there is no way to put it
	// out of scope here. Vale has no scope negation, and `tokenIgnores` is not a
	// valid key on the existence extension point in vale 3.17.1: adding it made
	// vale abort with E201 and lint nothing at all. Quote an upstream excerpt in
	// a fence rather than a blockquote.
	FrequencyMarker: #Existence & {
		message: "AI frequency marker: name the thing plainly"
		level:   "error"
		raw: ["(?i)\\b(tapestry|paradigm|embark(s|ed|ing)?|beacon|testament to|cutting.edge|watershed moment|nestled|vibrant|thriving|bustling|ever.evolving|thought leader|synergy|symphony|deep dive|learnings|holistic|at its core|meticulous(ly)?|daunting|intricate|interplay|load.bearing|hit differently|landscape|enduring|actionable|best practices|complexities|keen|underscores the)\\b"]
	}

	// ASD-STE100 caps a procedure sentence at 20 words and a descriptive one at
	// 25. Vale cannot tell the two apart, so the ceiling is the looser of them
	// and a long procedure sentence is left to the reader.

	// Tier 1B. These carried `replace` actions and the actions were wrong.
	// `prose-gate fix` returns the parameter verbatim (utils/internal/prosegate
	// /fix.go), so it has no inflection and no case. Measured: "The hook
	// utilizes vale. The overlay utilized cue." became "The hook use vale. The
	// overlay use cue.", and a sentence-initial "Utilize" became "use". The
	// `check` path is worse, because it hands those lines back to the model as
	// finished. The message names the replacement instead.
	//
	// `utilization` and `utilizing` are out of the pattern. CPUUtilization is
	// the CloudWatch metric this repository queries, and "use" is the wrong
	// word for either inflection, so a rule whose only output is that message
	// would be telling the reader something false.
	Utilize: #Existence & {
		message: "utilize: use"
		level:   "error"
		raw: ["(?i)\\butiliz(e|es|ed)\\b"]
	}

	InOrderTo: #Existence & {
		message: "in order to: to"
		level:   "error"
		raw: ["(?i)\\bin order to\\b"]
	}

	DueToTheFactThat: #Existence & {
		message: "due to the fact that: because"
		level:   "error"
		raw: ["(?i)\\bdue to the fact that\\b"]
	}

	// The rest of Tier 1B. No action: the right replacement depends on the
	// sentence, and a wrong mechanical fix costs more than a message.
	Latinate: #Existence & {
		message: "latinate verb: use the plain one"
		level:   "error"
		raw: ["(?i)\\b(commence[sd]?|ascertain(s|ed)?|endeavou?r(s|ed)?)\\b"]
	}

	// A transition that carries no argument. The reader already knows the next
	// sentence follows this one.
	//
	// A lookbehind, not `scope: sentence`. The sentence scope missed 7 of 20
	// realistic `Additionally` openers and none of the `Moreover` ones: vale's
	// segmenter is statistical, so whether it splits after a full stop depends
	// on the following word, and `^` then anchors at the start of whatever it
	// emitted. A lookbehind asserts the punctuation without consuming it, which
	// is also what stops the double report an earlier `[.!?]\s+` version made.
	//
	// Vale is not limited to RE2 for `raw`, despite what this file said in one
	// place. Measured: `(?<!do not )\bblock the reply\b` compiles and fires on
	// the second clause only.
	//
	// A mid-sentence ", moreover," is missed on purpose. Opening a sentence the
	// word is always filler, and inside one it sometimes is not.
	//
	// The trailing comma is load bearing. Without it the lookbehind cannot tell
	// an abbreviation's period from a sentence end, and "Pin the hash, e.g.
	// additionally naming the release tag" alerted. The filler shape always
	// takes the comma.
	Transition: #Existence & {
		message: "transition filler: delete it and state the fact"
		level:   "error"
		raw: ["(?i)(?<=^|[.!?][\"')\\]]?\\s)(moreover|furthermore|additionally),"]
	}

	// Anchored on the nouns the opener actually takes. A bare `in today.s`
	// matched any possessive: "errors I introduced in today's rewrite" alerted,
	// and at maxTells = 1 that one false positive spent a clean reply's whole
	// budget.
	InToday: #Existence & {
		message: "dateline filler: say when, or drop it"
		level:   "error"
		raw: ["(?i)\\bin today.s (fast.paced|world|climate|landscape|market|environment)\\b"]
	}

	// A hedging modal already hedges. A hedge adverb on top of it says the
	// writer does not know, twice.
	//
	// `eventually` and `can` are out. "The retry can eventually succeed" states
	// timing and capability, which is the vocabulary of eventual consistency,
	// not doubt. `can` is capability rather than a hedge, so the rule's own
	// premise did not hold for it.
	HedgeStacking: #Existence & {
		message: "stacked hedge: make the claim, or drop it"
		level:   "error"
		raw: ["(?i)\\b(could|may|might|would)\\s+(potentially|possibly|conceivably|arguably)\\b"]
	}

	// The four rules below came from a hand-written Sysinit style another session
	// wrote under ~/.local/share/vale/styles, because a bare `vale` on this
	// machine found no config at all. It derived them from the writing-tone
	// skill and the output style, which is the same source this file has, and it
	// covered four patterns this file did not.
	//
	// A callout box and an emoji are both stated bans that nothing enforced.
	CalloutBox: #Existence & {
		message: "callout block: put the content in the prose, or cut it"
		level:   "error"
		scope:   "raw"
		raw: ["(?m)<callout|^> \\[!(NOTE|TIP|WARNING|IMPORTANT|CAUTION)\\]"]
	}

	Emoji: #Existence & {
		message: "emoji: remove it"
		level:   "error"
		scope:   "raw"
		raw: ["[\\x{1F300}-\\x{1FAFF}\\x{2600}-\\x{27BF}\\x{2B00}-\\x{2BFF}\\x{FE0F}]"]
	}

	// A label announcing the shape of the next clause, in place of the clause.
	// The output style names the sandwich ending and the hedge before the claim;
	// this is the same move at the head of a sentence.
	RhetoricalLabel: #Existence & {
		message: "rhetorical label: delete the label and state the thing"
		level:   "error"
		raw: ["(?i)\\b(the asymmetry(:| is)|the irony (is|here)|what this really means|the real question|the thing is|here.s the (thing|rub|kicker)|make no mistake|let.s be clear|the bottom line is that)\\b"]
	}

	// FillerOpener covers the chat openers. This covers the document ones, which
	// a doc or a PR body reaches for instead.
	DocPreamble: #Existence & {
		message: "preamble: start with the substance"
		level:   "error"
		raw: ["(?i)\\b(this document (describes|outlines|covers|presents)|this (section|page) (describes|outlines|will)|in this section|as (we|you) can see|it is important to (note|understand)|in order to better)\\b"]
	}

	// STE.Ambiguity's true half. Upstream bans `and/or`, `etc.`, `and so on`,
	// `e.g.` and `i.e.` together. The first three hand the reader an unfinished
	// list; the last two are compact and exact, and this file's own comments use
	// `e.g.` on purpose, so they stay.
	//
	// The period on `etc.` is load bearing. Upstream matches `\betc\.?`, and the
	// 13 hits of `etc` on this tree are all `/etc/` paths in Nix.
	Unfinished: #Existence & {
		message: "unfinished list: name the alternatives"
		level:   "error"
		raw: ["(?i)(\\band\\s*/\\s*or\\b|\\betc\\.|\\band so (on|forth)\\b)"]
	}

	// STE.Dictionary's safe half, as this repository's own rule rather than a
	// promotion. Upstream swaps roughly 60 words and about a third of them are
	// correct here: `component`, `implement`, `monitor`, `provide`, `require`,
	// `maintain`, `operate`, `request`, `objective`. `monitor` names a Laurel
	// skill. Its own header says it is plain-language advice and not the ASD
	// dictionary, which is copyrighted and absent upstream.
	//
	// Every token below measures 0 over the tracked .md, .nix and .go files, so
	// none is part of this repository's vocabulary. The ones that measured 1 to 9
	// are deliberately out: `attempt` and `additional` were nouns, `identical`
	// read correctly, and `fabricate` is a rule word meaning invent, which
	// upstream would swap to `make`.
	//
	// Three more came out after the first build measured them: `advised` is right
	// for a linter's advice, and `comprises` and `retained` both read correctly
	// where this repository uses them. An inflection is what my first count
	// missed, so the measurement now runs against the built rule.
	//
	// `ascertain`, `commence`, `endeavor`, `utilize` and `in order to` are not
	// repeated here. Latinate, Utilize and InOrderTo already own them, and a
	// second rule on one span would spend two tells on one slip.
	LongWord: #Existence & {
		message: "long word: use the short one"
		level:   "error"
		raw: ["(?i)\\b(approximately|cease[sd]?|demonstrate[sd]?|desire[sd]?|discontinue[sd]?|eliminate[sd]?|employ(s|ed)?|expedite[sd]?|facilitate[sd]?|frequently|furnish(es|ed)?|numerous|optimum|possess(es|ed)?|prior to|procure[sd]?|purchase[sd]?|regarding|adjacent to|exhibit(s|ed)?|in the event that|in the vicinity of)\\b"]
	}

	// The rest of avoid-ai-writing's Tier 2 and Tier 3, as a plain existence rule.
	// An earlier revision made Tier 2 a per-paragraph density rule and deleted
	// it: vale makes each list item and each table cell its own paragraph, so
	// five inflated words in a bulleted reply gave 0 alerts. A flat token list
	// has no such hole.
	//
	// Every token measures 0 over the tracked .md, .nix, .go and .lua files.
	// The ones left out were measured too: `harness` 39 and `verbatim` 8 are this
	// repository's own terms, `impactful` 8 is a term of art in the openspec
	// schema's human-verification rule, and `significant`, `effective`,
	// `dynamic` and `scalable` are ordinary technical words here. `navigate` and
	// `elevate` are pane and latency verbs. `nuanced` is HedgeBeforeClaim's.
	InflatedWord: #Existence & {
		message: "inflated word: use a plainer one"
		level:   "error"
		raw: ["(?i)\\b(unleash(es|ed)?|bolster(s|ed)?|spearhead(s|ed)?|resonate[sd]?|revolutionize[sd]?|multifaceted|myriad|plethora|catalyze[sd]?|reimagine[sd]?|galvanize[sd]?|elucidate[sd]?|juxtapose[sd]?|poised|burgeoning|nascent|quintessential|overarching|innovative|compelling|unprecedented|exceptional|remarkable|sophisticated|instrumental|world.class|crucial)\\b"]
	}

	// avoid-ai-writing's phrase clusters. Each names a relationship without
	// naming either side of it, so the sentence survives deleting the phrase.
	PhraseCluster: #Existence & {
		message: "empty phrase: name the two things and the relation"
		level:   "error"
		raw: ["(?i)\\b(the integration of|the intersection of|community.driven|long.term sustainability|user engagement|emerging (sector|space)|designed for long.term)\\b"]
	}

	// Code given intentions or possessions. Slop.Anthropomorphism covers the
	// obvious half, "the parser wants a newline" and "vale decides to", and
	// misses the half this repository writes: a rule that owns a token, a check
	// that spends a turn, a rule that earns its line.
	//
	// Measured 6 hits over the tracked files and every one is mine, in a comment
	// I wrote. `reader` and `writer` are deliberately absent from the subject
	// list, because both are people and a person may want something.
	CodeAgency: #Existence & {
		message: "code has no intent: state the behaviour"
		level:   "error"
		raw: ["(?i)\\b(rules?|parsers?|gates?|hooks?|checks?|linters?|derivations?|overlays?|binar(y|ies)|commands?|tools?|configs?|styles?|regexe?s?|patterns?|spans?|builds?|scripts?|wrappers?|exporters?|collectors?|providers?)\\s+(owns?|wants?|prefers?|decides?|knows?|likes?|cares?|refuses?|insists?|earns?|buys?|spends?|chooses?|expects?)\\b"]
	}

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
auditStyles: ["proselint", "write-good", "alex", "Slop", "STE"]

// STE ships 12 rules and the hook runs 2 of them. Every count below is over the
// 41 tracked .md files at suggestion level, which is why none of the other 10 is
// promoted. They are reachable through the audit config, which blocks nothing.
//
// Four are too noisy to price a turn on:
//   Gerunds 371, ProcedureLength 247, PassiveVoice 216, NounClusters 39.
// STE bans a gerund outright and this repository's prose is full of legitimate
// ones, starting with the skill titled "Writing".
//
// Three fight a rule this repository already decided:
//   Modals 45 swaps `shall` to `must` and `may` to `can`. CLAUDE.md cites
//   RFC 2119 and the openspec specs use SHALL on purpose.
//   Contractions 13 bans every contraction. The output style uses them.
//   SentenceLength 10 duplicates Sysinit.SentenceLength, which owns the 25-word
//   ceiling and states it in this repository's own message.
//
// Two are real candidates and neither is the author's call:
//   Ambiguity 34 bans `and/or`, `etc.`, `e.g.` and `i.e.` outright. Promoting it
//   changes how every reply and every rule comment here is written.
//   Dictionary 42 is plain-English substitution, not the ASD dictionary, which is
//   copyrighted and absent upstream. It overlaps Latinate, InOrderTo and
//   DueToTheFactThat, and it swaps words that are correct here: `component`,
//   `implement`, `monitor`, `provide`, `require`, `maintain`, `operate`.
//   `monitor` is a Laurel domain term with a skill named after it.
//
// Articles 13 is the remainder: a warning about a missing article, correct but
// not worth a blocked turn.

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
	// Adverb, comparative and more/less triples only. Its own header says a
	// plain three-item list is out of scope, so the output style's own example,
	// "fast, robust, and comprehensive", is not caught by it: that line blocks
	// on two MarketingVerb hits instead. The adjective triple the style names is
	// unimplemented, here and upstream. 0 hits on the tracked files and 0 over
	// 1805 real replies.
	"Slop.Tricolon": "error"
	// A virtue the reader cannot check: "ensures correctness", "gracefully".
	"Slop.SelfPraise": "error"
	// "this is by design", standing in for the reason. 0 hits.
	"Slop.VagueReasons": "error"
	// Metaphor standing in for mechanism. This is the rule that would have caught
	// "the period is load bearing" and "reads as the provenance". 19 hits, all in
	// the writing skills, which quote the pattern they ban.
	"Slop.Metaphor": "error"
	// Code given intentions: "the parser wants", "vale decides to". 9 hits.
	"Slop.Anthropomorphism": "error"
	// Slop.Overused is deliberately NOT promoted. Its token list is nearly this
	// file's own: robust, seamless, comprehensive, meticulous, intricate,
	// multifaceted, nuanced, pivotal, crucial, elevate, empower, foster,
	// facilitate, leverage, utilize, showcase, spearhead, streamline, bolster.
	// It also holds `utilization`, which is the CloudWatch metric this
	// repository queries and which Utilize drops for that reason. The corpus
	// check caught it on good.md.
	// Ceremony around the answer instead of the answer. 4 hits.
	"Slop.Ceremony": "error"
	// "very", "quite", "rather": a qualifier carrying no quantity. 2 hits.
	"Slop.EmptyQualifiers": "error"
	// A comment restating the line below it. 0 hits.
	"Slop.RestatesCode": "error"
	// A header that announces rather than names. 0 hits.
	"Slop.Headers": "error"
	// ASD-STE100 caps a paragraph at six sentences. 11 hits.
	"STE.ParagraphLength": "error"
	// One instruction per sentence, scoped to list items. 5 hits.
	"STE.OneInstruction": "error"
}

promotedIni: strings.Join([for k, v in promoted {"\(k) = \(v)"}], "\n")

// The rules that testdata/bad.md is expected to trip, one line each. The build
// asserts every name here appears in vale's output for that file.
//
// A total alert count cannot do this job. The first version of the check
// required 8 alerts, bad.md produced 12, and deleting a whole rule still
// passed. Worse, a rule can go dead without any error: adding a second entry to
// a `raw` list concatenates the two into a pattern that matches nothing, and
// vale reports that as a clean file.
//
// A rule absent from this list is untested. Add the line and the case together.
covered: [
	"AcknowledgmentLoop",
	"CalloutBox",
	"CitationMarkup",
	"CodeAgency",
	"DocPreamble",
	"DueToTheFactThat",
	"EmDash",
	"Emoji",
	"EmphasisInBullet",
	"FillerOpener",
	"FrequencyMarker",
	"GenericEnding",
	"HedgeStacking",
	"InflatedWord",
	"InOrderTo",
	"InToday",
	"Latinate",
	"LetsConstruction",
	"LongWord",
	"MarketingVerb",
	"Narration",
	"NegativeParallelism",
	"PhraseCluster",
	"ReaderCue",
	"ReasoningArtifact",
	"RhetoricalLabel",
	"SentenceLength",
	"SignificanceInflation",
	"Transition",
	"Unfinished",
	"Utilize",
]

coveredList: strings.Join(covered, "\n")

// The promoted rule names, for the build's existence check.
promotedList: strings.Join([for k, _ in promoted {k}], "\n")

// Both configs carry a placeholder for the styles directory, which the
// derivation replaces with its own absolute `$out/styles`.
//
// A relative `StylesPath = styles` was silently wrong. Vale resolves it against
// the working directory, and the hook runs from wherever the session is, so the
// path never existed and vale fell back to its user default at
// ~/.local/share/vale/styles. A hand-written Sysinit style left there by another
// session then won, and the hook ran 12 foreign rules instead of these. The
// build's own check missed it because the derivation does `cd "$out"` first.
stylesPlaceholder: "@STYLES@"

// Two configs, because the two jobs want different noise floors.
//
// The hook config is Sysinit plus the six rules in `promoted`. prose-gate spends
// the user's turn on what it reports, so a rule here has to be one this
// repository actually decided. proselint and write-good are advisory by design
// and would block most replies, so neither style goes in wholesale.
ini: """
	StylesPath = \(stylesPlaceholder)
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
	StylesPath = \(stylesPlaceholder)
	MinAlertLevel = suggestion

	[*.md]
	BasedOnStyles = Sysinit, \(strings.Join(auditStyles, ", "))
	"""
