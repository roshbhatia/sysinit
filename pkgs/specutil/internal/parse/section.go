// Package parse turns provider markdown into the normalized IR. It is lenient
// by design: malformed structure produces a Warning and a best-effort result
// rather than a hard failure, so a single bad section never blocks a render.
package parse

import (
	"strings"
)

// Node is one ATX-heading section and everything nested beneath it. Raw retains
// the verbatim source (heading line included) so renderers can pass prose
// through untouched; Body is just the text owned directly by this heading,
// before its first child heading.
type Node struct {
	Level     int
	Title     string
	Body      string
	Raw       string
	StartLine int // 1-based line of the heading
	Children  []*Node
}

// heading is an intermediate record of an ATX heading found during the scan.
type heading struct {
	level int
	title string
	line  int // 0-based index into lines
}

// SplitSections parses src into a forest of heading sections. Headings inside
// fenced code blocks are ignored. Content before the first heading is returned
// as preamble. The scan is fence-aware for both ``` and ~~~ fences.
func SplitSections(src string) (preamble string, roots []*Node) {
	lines := strings.Split(src, "\n")
	var headings []heading
	inFence := false
	var fenceMarker string

	for i, ln := range lines {
		trimmed := strings.TrimSpace(ln)
		if inFence {
			if strings.HasPrefix(trimmed, fenceMarker) {
				inFence = false
			}
			continue
		}
		if strings.HasPrefix(trimmed, "```") {
			inFence = true
			fenceMarker = "```"
			continue
		}
		if strings.HasPrefix(trimmed, "~~~") {
			inFence = true
			fenceMarker = "~~~"
			continue
		}
		if lvl, title, ok := atxHeading(ln); ok {
			headings = append(headings, heading{level: lvl, title: title, line: i})
		}
	}

	if len(headings) == 0 {
		return src, nil
	}

	// Preamble is everything before the first heading.
	if first := headings[0].line; first > 0 {
		preamble = strings.Join(lines[:first], "\n")
	}

	// Build each heading's full raw range: from its line to the line before the
	// next heading of equal-or-shallower level.
	nodes := make([]*Node, len(headings))
	for idx, h := range headings {
		end := len(lines)
		for j := idx + 1; j < len(headings); j++ {
			if headings[j].level <= h.level {
				end = headings[j].line
				break
			}
		}
		raw := strings.Join(lines[h.line:end], "\n")

		// Body is the text owned directly by this heading: from the line after
		// the heading to the line before its first child heading (any deeper
		// heading), or to end if it has no children.
		bodyEnd := end
		for j := idx + 1; j < len(headings); j++ {
			if headings[j].line >= end {
				break
			}
			if headings[j].level > h.level {
				bodyEnd = headings[j].line
				break
			}
		}
		var body string
		if h.line+1 < bodyEnd {
			body = strings.Join(lines[h.line+1:bodyEnd], "\n")
		}

		nodes[idx] = &Node{
			Level:     h.level,
			Title:     h.title,
			Body:      strings.TrimRight(body, "\n"),
			Raw:       strings.TrimRight(raw, "\n"),
			StartLine: h.line + 1,
		}
	}

	// Assemble the tree using a stack keyed by heading level.
	var stack []*Node
	for _, n := range nodes {
		for len(stack) > 0 && stack[len(stack)-1].Level >= n.Level {
			stack = stack[:len(stack)-1]
		}
		if len(stack) == 0 {
			roots = append(roots, n)
		} else {
			parent := stack[len(stack)-1]
			parent.Children = append(parent.Children, n)
		}
		stack = append(stack, n)
	}
	return preamble, roots
}

// atxHeading reports whether ln is an ATX heading and returns its level and
// title text (closing #'s and surrounding whitespace stripped). Up to three
// leading spaces of indentation are tolerated per CommonMark.
func atxHeading(ln string) (level int, title string, ok bool) {
	i := 0
	for i < len(ln) && i < 3 && ln[i] == ' ' {
		i++
	}
	rest := ln[i:]
	hashes := 0
	for hashes < len(rest) && rest[hashes] == '#' {
		hashes++
	}
	if hashes == 0 || hashes > 6 {
		return 0, "", false
	}
	after := rest[hashes:]
	// A valid ATX heading requires a space (or end of line) after the #'s.
	if after != "" && after[0] != ' ' && after[0] != '\t' {
		return 0, "", false
	}
	title = strings.TrimSpace(after)
	title = strings.TrimRight(title, "#")
	title = strings.TrimSpace(title)
	return hashes, title, true
}

// findChild returns the first direct child whose title matches (case-insensitive,
// trimmed), or nil.
func findChild(n *Node, title string) *Node {
	for _, c := range n.Children {
		if strings.EqualFold(strings.TrimSpace(c.Title), title) {
			return c
		}
	}
	return nil
}

// findRoot returns the first root section whose title matches, or nil.
func findRoot(roots []*Node, title string) *Node {
	for _, r := range roots {
		if strings.EqualFold(strings.TrimSpace(r.Title), title) {
			return r
		}
	}
	return nil
}
