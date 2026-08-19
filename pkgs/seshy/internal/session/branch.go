package session

import (
	"fmt"
	"os/user"
	"strings"

	"github.com/roshbhatia/seshy/internal/tmpl"
)

// RenderBranchName evaluates a Go template string with the given session and repo names.
// Uses tmpl.RenderString for consistent template handling across the codebase.
func RenderBranchName(tmplStr string, sessionName string, repo string) (string, error) {
	username := ""
	if u, err := user.Current(); err == nil {
		username = u.Username
	}

	data := tmpl.TemplateData{
		Session: sessionName,
		Repo:    repo,
		User:    username,
	}

	name, err := tmpl.RenderString(tmplStr, data)
	if err != nil {
		return "", fmt.Errorf("invalid branch template %q: %w", tmplStr, err)
	}

	if err := ValidateBranchName(name); err != nil {
		return "", err
	}

	return name, nil
}

// ValidateBranchName checks that a branch name is valid for git.
func ValidateBranchName(name string) error {
	if name == "" {
		return fmt.Errorf("branch name cannot be empty")
	}
	if strings.Contains(name, " ") {
		return fmt.Errorf("branch name %q contains spaces", name)
	}
	if strings.Contains(name, "..") {
		return fmt.Errorf("branch name %q contains '..'", name)
	}
	for _, c := range name {
		if c < 32 || c == 127 {
			return fmt.Errorf("branch name %q contains control characters", name)
		}
	}
	for _, bad := range []string{"~", "^", ":", "\\", "?", "*", "["} {
		if strings.Contains(name, bad) {
			return fmt.Errorf("branch name %q contains invalid character %q", name, bad)
		}
	}
	if strings.HasSuffix(name, ".lock") {
		return fmt.Errorf("branch name %q ends with .lock", name)
	}
	if strings.HasSuffix(name, ".") {
		return fmt.Errorf("branch name %q ends with '.'", name)
	}
	return nil
}
