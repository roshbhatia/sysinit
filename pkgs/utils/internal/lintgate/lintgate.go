// Package lintgate runs the edited file's linter and hands the failures back.
//
// A checker only speaks when it exits non-zero, so the gate keeps the 100%
// precision that SWE-agent (Yang et al., NeurIPS 2024) holds its guardrails to.
// Feeding static analysis back each round cut security findings from over 40%
// to 13% in arXiv 2508.14419.
package lintgate

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

const Summary = "run the edited file's linter and hand the failures back"

const (
	patience = 10 * time.Second
	widest   = 4 * 1024
)

type checker struct {
	binary string
	args   []string
	// byOutput marks a checker that reports on stdout and still exits 0.
	byOutput bool
}

var byExtension = map[string][]checker{
	".nix":  {{binary: "statix", args: []string{"check"}}, {binary: "deadnix", args: []string{"--fail"}}},
	".lua":  {{binary: "stylua", args: []string{"--check"}}},
	".sh":   {{binary: "shellcheck", args: []string{"--shell=bash"}}},
	".bash": {{binary: "shellcheck", args: []string{"--shell=bash"}}},
	".go":   {{binary: "gofmt", args: []string{"-l"}, byOutput: true}},
	".py":   {{binary: "ruff", args: []string{"check"}}},
	".toml": {{binary: "taplo", args: []string{"lint"}}},
}

func Run(_ []string) int {
	payload := readStdin()
	input, _ := payload["tool_input"].(map[string]any)
	path, _ := input["file_path"].(string)
	if path == "" {
		return 0
	}
	if info, err := os.Stat(path); err != nil || info.IsDir() {
		return 0
	}

	var found []string
	for _, one := range byExtension[strings.ToLower(filepath.Ext(path))] {
		if report := check(one, path); report != "" {
			found = append(found, report)
		}
	}
	if len(found) == 0 {
		return 0
	}
	return tell(fmt.Sprintf(
		"lint-gate: %s does not pass its own checker. Fix this before you move on.\n\n%s",
		filepath.Base(path), clip(strings.Join(found, "\n\n"))))
}

// A checker writes for a terminal, and the escape codes only cost the agent tokens.
var colour = regexp.MustCompile(`\x1b\[[0-9;]*[A-Za-z]`)

func check(one checker, path string) string {
	binary, err := exec.LookPath(one.binary)
	if err != nil {
		return ""
	}
	ctx, stop := context.WithTimeout(context.Background(), patience)
	defer stop()

	run := exec.CommandContext(ctx, binary, append(append([]string{}, one.args...), path)...)
	run.Dir = filepath.Dir(path)
	out, err := run.CombinedOutput()
	if ctx.Err() != nil {
		return ""
	}

	said := strings.TrimSpace(colour.ReplaceAllString(string(out), ""))
	if one.byOutput {
		if said == "" {
			return ""
		}
		return one.binary + " reports " + said
	}
	if err == nil || said == "" {
		return ""
	}
	return "$ " + one.binary + " " + strings.Join(one.args, " ") + " " + filepath.Base(path) + "\n" + said
}

func clip(text string) string {
	if len(text) <= widest {
		return text
	}
	return text[:widest] + "\n[the rest is cut]"
}

type contextOutput struct {
	HookSpecificOutput injectedContext `json:"hookSpecificOutput"`
}

type injectedContext struct {
	HookEventName     string `json:"hookEventName"`
	AdditionalContext string `json:"additionalContext"`
}

func tell(text string) int {
	encoded, err := json.Marshal(contextOutput{injectedContext{"PostToolUse", text}})
	if err != nil {
		return 0
	}
	fmt.Println(string(encoded))
	return 0
}

func readStdin() map[string]any {
	info, err := os.Stdin.Stat()
	if err != nil || info.Mode()&os.ModeCharDevice != 0 {
		return nil
	}
	data, err := io.ReadAll(os.Stdin)
	if err != nil || len(data) == 0 {
		return nil
	}
	var parsed map[string]any
	if json.Unmarshal(data, &parsed) != nil {
		return nil
	}
	return parsed
}
