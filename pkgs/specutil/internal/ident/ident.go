// Package ident computes the stable, content-addressed handles every other
// package uses to talk about the same task without agreeing on its position in
// a file. Identity survives renumbering and minor edits; ContentHash flips on
// any byte change. Both are pure functions of their input, so a review record
// and the rendered web page name a task identically without coordinating.
package ident

import (
	"crypto/sha256"
	"encoding/hex"
	"regexp"
	"strings"
)

// emphasisRe strips markdown emphasis/code markers so they do not perturb the
// normalized identity key.
var emphasisRe = regexp.MustCompile("[*_`]")

// wsRe collapses internal whitespace runs to a single space.
var wsRe = regexp.MustCompile(`\s+`)

// trailingPunctRe trims trailing sentence punctuation that minor edits add or
// drop without changing meaning.
var trailingPunctRe = regexp.MustCompile(`[.,;:!?\s]+$`)

// Normalize produces the position-independent, edit-tolerant key used for
// identity: lowercased, emphasis-stripped, whitespace-collapsed, trailing
// punctuation removed. It deliberately discards leading task numbers (the
// caller passes already number-free text) so renumbering preserves identity.
func Normalize(s string) string {
	s = strings.ToLower(s)
	s = emphasisRe.ReplaceAllString(s, "")
	s = wsRe.ReplaceAllString(s, " ")
	s = strings.TrimSpace(s)
	s = trailingPunctRe.ReplaceAllString(s, "")
	return s
}

// Identity is the stable key for an item. It is built from the normalized phase
// name and normalized item text, so it survives task renumbering and minor text
// edits (which the normalization absorbs) while still distinguishing genuinely
// different items. The phase name disambiguates identically-worded tasks living
// in different phases.
func Identity(phaseName, text string) string {
	return Hash(Normalize(phaseName) + "\n" + Normalize(text))
}

// ContentHash is the exact-content fingerprint. Unlike Identity it is NOT
// normalized: any byte change flips it. That is what lets a consumer tell an
// untouched item from an edited one that kept its identity.
func ContentHash(text string) string { return Hash(text) }

// Hash is the shared 64-bit hex digest used by every fingerprint here. It is
// truncated because these values are collision-resistance-for-humans handles in
// a single repository, not cryptographic commitments.
func Hash(s string) string {
	sum := sha256.Sum256([]byte(s))
	return hex.EncodeToString(sum[:])[:16]
}

// FuzzyThreshold is the minimum Similarity at which two texts are treated as
// the same item reworded, rather than one item removed and another added.
const FuzzyThreshold = 0.5

// Similarity is the Jaccard index over normalized token sets of two texts, in
// [0,1]. It is symmetric and order-independent. Identity absorbs edits that do
// not change words; this is what recognizes an edit that does.
func Similarity(a, b string) float64 {
	ta, tb := tokenSet(a), tokenSet(b)
	if len(ta) == 0 && len(tb) == 0 {
		return 1
	}
	inter := 0
	for t := range ta {
		if tb[t] {
			inter++
		}
	}
	union := len(ta) + len(tb) - inter
	if union == 0 {
		return 0
	}
	return float64(inter) / float64(union)
}

func tokenSet(s string) map[string]bool {
	set := make(map[string]bool)
	for _, tok := range strings.Fields(Normalize(s)) {
		set[tok] = true
	}
	return set
}
