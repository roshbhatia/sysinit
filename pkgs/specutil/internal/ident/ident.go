package ident

import (
	"crypto/sha256"
	"encoding/hex"
	"regexp"
	"strings"
)

var emphasisRe = regexp.MustCompile("[*_`]")

var wsRe = regexp.MustCompile(`\s+`)

var trailingPunctRe = regexp.MustCompile(`[.,;:!?\s]+$`)

func Normalize(s string) string {
	s = strings.ToLower(s)
	s = emphasisRe.ReplaceAllString(s, "")
	s = wsRe.ReplaceAllString(s, " ")
	s = strings.TrimSpace(s)
	s = trailingPunctRe.ReplaceAllString(s, "")
	return s
}

func Identity(phaseName, text string) string {
	return Hash(Normalize(phaseName) + "\n" + Normalize(text))
}

func ContentHash(text string) string { return Hash(text) }

func Hash(s string) string {
	sum := sha256.Sum256([]byte(s))
	return hex.EncodeToString(sum[:])[:16]
}

const FuzzyThreshold = 0.5

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
