package graph

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"

	"github.com/roshbhatia/specutil/internal/ir"
)

// SupportedHarnesses lists the known AI harness names. Any binary on PATH also
// works; this list is for documentation and flag completion hints only.
var SupportedHarnesses = []string{"claude", "gemini", "codex", "openai", "pi"}

// HarnessSuggest sends change metadata to an AI harness CLI subprocess and
// returns the suggested dependency edges. The harness must write a JSON object
// to stdout with a "suggestions" array; each element needs "from" and "to"
// string fields (both must be known change names) and an optional "reason".
func HarnessSuggest(changes []*ir.Change, harness string) ([]Candidate, error) {
	if harness == "" {
		return nil, fmt.Errorf("harness name is required")
	}
	prompt := buildSuggestPrompt(changes)
	out, err := runHarness(harness, prompt)
	if err != nil {
		return nil, fmt.Errorf("harness %q: %w", harness, err)
	}
	known := make(map[string]bool, len(changes))
	for _, c := range changes {
		known[c.Name] = true
	}
	return parseHarnessOutput(out, known)
}

func buildSuggestPrompt(changes []*ir.Change) string {
	var b strings.Builder
	b.WriteString(`You are analyzing a set of software changes to suggest dependency relationships.

A dependency edge "A depends on B" means: change A cannot be started until change B is complete.
Common signals: A uses types/APIs that B introduces; A modifies something B creates; A's proposal mentions B's capability.

Output ONLY a JSON object with this exact shape (no prose, no markdown fences):
{"suggestions": [{"from": "prereq-change", "to": "dependent-change", "reason": "one sentence"}]}

If you find no dependencies, output: {"suggestions": []}

Changes to analyze:
`)
	for _, c := range changes {
		b.WriteString("\n--- " + c.Name + " ---\n")
		if c.Proposal != nil {
			if c.Proposal.Why != "" {
				b.WriteString("Why: " + c.Proposal.Why + "\n")
			}
			if c.Proposal.WhatChanges != "" {
				b.WriteString("What changes: " + c.Proposal.WhatChanges + "\n")
			}
			for _, cap := range c.Proposal.Capabilities.New {
				b.WriteString("Adds capability: " + cap.Name + "\n")
			}
			for _, cap := range c.Proposal.Capabilities.Modified {
				b.WriteString("Modifies capability: " + cap.Name + "\n")
			}
		}
	}
	return b.String()
}

// runHarness invokes the harness binary with the prompt. Tries -p flag first
// (claude/gemini convention), falls back to piping via stdin.
func runHarness(harness, prompt string) ([]byte, error) {
	cmd := exec.Command(harness, "-p", prompt) //nolint:gosec
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	if err := cmd.Run(); err == nil {
		return stdout.Bytes(), nil
	}

	// Fallback: pipe prompt via stdin (codex, openai, pi, etc.)
	cmd2 := exec.Command(harness) //nolint:gosec
	cmd2.Stdin = strings.NewReader(prompt)
	stdout.Reset()
	stderr.Reset()
	cmd2.Stdout = &stdout
	cmd2.Stderr = &stderr
	if err := cmd2.Run(); err != nil {
		return nil, fmt.Errorf("exit error: %w\nstderr: %s", err, stderr.String())
	}
	return stdout.Bytes(), nil
}

type harnessSuggestion struct {
	From   string `json:"from"`
	To     string `json:"to"`
	Reason string `json:"reason"`
}

type harnessOutput struct {
	Suggestions []harnessSuggestion `json:"suggestions"`
}

// parseHarnessOutput extracts Candidate edges from the harness JSON output.
// Strips markdown code fences if the harness wrapped the response. Unknown
// change names are silently dropped — the harness may hallucinate.
func parseHarnessOutput(raw []byte, known map[string]bool) ([]Candidate, error) {
	trimmed := bytes.TrimSpace(raw)
	if bytes.HasPrefix(trimmed, []byte("```")) {
		lines := bytes.Split(trimmed, []byte("\n"))
		if len(lines) > 2 {
			trimmed = bytes.Join(lines[1:len(lines)-1], []byte("\n"))
		}
	}
	var ho harnessOutput
	if err := json.Unmarshal(trimmed, &ho); err != nil {
		return nil, fmt.Errorf("parsing harness JSON: %w\nraw output: %s", err, string(raw))
	}
	var out []Candidate
	for _, s := range ho.Suggestions {
		if !known[s.From] || !known[s.To] || s.From == s.To {
			continue
		}
		out = append(out, Candidate{From: s.From, To: s.To, Capability: s.Reason})
	}
	return out, nil
}
