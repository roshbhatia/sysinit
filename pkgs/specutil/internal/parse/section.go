package parse

import (
	"strings"
)

type Node struct {
	Level     int
	Title     string
	Body      string
	Raw       string
	StartLine int
	Children  []*Node
}

type heading struct {
	level int
	title string
	line  int
}

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

	if first := headings[0].line; first > 0 {
		preamble = strings.Join(lines[:first], "\n")
	}

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

	if after != "" && after[0] != ' ' && after[0] != '\t' {
		return 0, "", false
	}
	title = strings.TrimSpace(after)
	title = strings.TrimRight(title, "#")
	title = strings.TrimSpace(title)
	return hashes, title, true
}

func findChild(n *Node, title string) *Node {
	for _, c := range n.Children {
		if strings.EqualFold(strings.TrimSpace(c.Title), title) {
			return c
		}
	}
	return nil
}

func findRoot(roots []*Node, title string) *Node {
	for _, r := range roots {
		if strings.EqualFold(strings.TrimSpace(r.Title), title) {
			return r
		}
	}
	return nil
}
