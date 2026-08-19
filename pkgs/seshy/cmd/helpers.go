package cmd

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/session"
	"github.com/spf13/cobra"
)

var (
	errCancelled       = errors.New("selection cancelled")
	errNothingSelected = errors.New("nothing selected")
)

// runSource executes a command and returns stdout lines.
func runSource(command string) ([]string, error) {
	cmd := exec.Command("sh", "-c", command)
	cmd.Stderr = os.Stderr
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("repo source command failed: %w\n  command: %s", err, command)
	}
	lines := strings.Split(strings.TrimSpace(string(out)), "\n")
	var result []string
	for _, l := range lines {
		l = strings.TrimSpace(l)
		if l != "" {
			result = append(result, l)
		}
	}
	return result, nil
}

// runPicker executes a picker command, piping input to stdin and reading selections from stdout.
func runPicker(command string, input []string) ([]string, error) {
	cmd := exec.Command("sh", "-c", command)
	cmd.Stdin = strings.NewReader(strings.Join(input, "\n") + "\n")
	cmd.Stderr = os.Stderr
	out, err := cmd.Output()
	if err != nil {
		// fzf exits 130 on ctrl-c, 1 on no match
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			code := exitErr.ExitCode()
			if code == 130 || code == 1 {
				return nil, errCancelled
			}
		}
		return nil, fmt.Errorf("picker command failed: %w", err)
	}
	lines := strings.Split(strings.TrimSpace(string(out)), "\n")
	var result []string
	for _, l := range lines {
		l = strings.TrimSpace(l)
		if l != "" {
			result = append(result, l)
		}
	}
	if len(result) == 0 {
		return nil, errNothingSelected
	}
	return result, nil
}

// prependDefaults adds default repos to the front of candidates, deduplicating.
func prependDefaults(defaults, candidates []string) []string {
	if len(defaults) == 0 {
		return candidates
	}
	seen := make(map[string]bool, len(defaults))
	result := make([]string, 0, len(defaults)+len(candidates))
	for _, d := range defaults {
		d = expandTilde(d)
		if !seen[d] {
			seen[d] = true
			result = append(result, d)
		}
	}
	for _, c := range candidates {
		if !seen[c] {
			seen[c] = true
			result = append(result, c)
		}
	}
	return result
}

// sessionNames extracts the names from a session list.
func sessionNames(sessions []session.Session) []string {
	names := make([]string, len(sessions))
	for i, s := range sessions {
		names[i] = s.Name
	}
	return names
}

// selectSessionName resolves the session a command should act on: args[0] when
// given, otherwise a pick from names via the configured session picker.
// An empty name with a nil error means there was nothing to pick or the user
// backed out, and the caller should exit quietly.
func selectSessionName(args []string, picker string, names []string) (string, error) {
	if len(args) > 0 {
		return args[0], nil
	}
	if len(names) == 0 {
		return "", nil
	}
	selected, err := runPicker(picker, names)
	if err != nil {
		if errors.Is(err, errCancelled) || errors.Is(err, errNothingSelected) {
			return "", nil
		}
		return "", err
	}
	return selected[0], nil
}

// completeSessionNames completes the first argument with live session names.
func completeSessionNames(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
	if len(args) != 0 {
		return nil, cobra.ShellCompDirectiveNoFileComp
	}
	sessions, _ := session.List()
	return sessionNames(sessions), cobra.ShellCompDirectiveNoFileComp
}

// completeArchivedNames completes the first argument with archived session names.
func completeArchivedNames(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
	if len(args) != 0 {
		return nil, cobra.ShellCompDirectiveNoFileComp
	}
	sessions, _ := session.ListArchived()
	return sessionNames(sessions), cobra.ShellCompDirectiveNoFileComp
}

func expandTilde(path string) string {
	if strings.HasPrefix(path, "~/") {
		home, _ := os.UserHomeDir()
		return home + path[1:]
	}
	return path
}
