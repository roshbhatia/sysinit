package git

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// An inherited GIT_DIR silently retargets a command that names its own
// repository, so every helper here scrubs the three that do it.
var inherited = []string{"GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE"}

func CleanEnv() []string {
	env := os.Environ()
	kept := make([]string, 0, len(env))
	for _, entry := range env {
		drop := false
		for _, name := range inherited {
			if strings.HasPrefix(entry, name+"=") {
				drop = true
				break
			}
		}
		if !drop {
			kept = append(kept, entry)
		}
	}
	return kept
}

func ShadowEnv(gitDir, workTree string) []string {
	return append(CleanEnv(),
		"GIT_DIR="+gitDir,
		"GIT_WORK_TREE="+workTree,
		"GIT_TERMINAL_PROMPT=0",
	)
}

func command(dir string, args ...string) *exec.Cmd {
	cmd := exec.Command("git", args...)
	cmd.Dir = dir
	cmd.Env = CleanEnv()
	return cmd
}

// Output runs git in dir and returns its trimmed stdout. The error carries
// stderr, which is the only place git explains itself.
func Output(dir string, args ...string) (string, error) {
	cmd := command(dir, args...)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		verb := ""
		if len(args) > 0 {
			verb = args[0]
		}
		return "", fmt.Errorf("git %s failed in %s: %s: %w", verb, dir, strings.TrimSpace(stderr.String()), err)
	}
	return strings.TrimSpace(stdout.String()), nil
}

func Run(dir string, args ...string) error {
	_, err := Output(dir, args...)
	return err
}

func Succeeds(dir string, args ...string) bool {
	_, err := Output(dir, args...)
	return err == nil
}

func IsRepo(dir string) bool { return Succeeds(dir, "rev-parse", "--git-dir") }

func Root(dir string) (string, error) {
	root, err := Output(dir, "rev-parse", "--show-toplevel")
	if err != nil || root == "" {
		return "", errors.New("not inside a git repository")
	}
	return root, nil
}

func Head(dir string) (string, error) { return Output(dir, "rev-parse", "HEAD") }

func Branch(dir string) (string, error) {
	return Output(dir, "rev-parse", "--abbrev-ref", "HEAD")
}
