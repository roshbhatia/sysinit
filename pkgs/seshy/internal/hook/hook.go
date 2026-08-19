// Package hook executes lifecycle hooks for seshy sessions.
package hook

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/roshbhatia/seshy/internal/config"
	"github.com/roshbhatia/seshy/internal/tmpl"
	"github.com/roshbhatia/seshy/internal/ui"
)

// Run executes hook commands for the given event.
// Commands are Go-template-rendered, then executed via sh -c.
// SESHY_* env vars are set. cwd = sessionPath.
// Non-fatal: failures produce warnings on stderr but don't abort.
// After inline commands, checks for executable $XDG_CONFIG_HOME/seshy/hooks/<event>.
func Run(event string, commands []string, data tmpl.TemplateData, sessionPath string) []error {
	var errs []error

	env := buildEnv(event, data)

	for _, cmd := range commands {
		rendered, err := tmpl.RenderString(cmd, data)
		if err != nil {
			fmt.Fprintln(os.Stderr, ui.Warningf("hook template error: %v", err))
			errs = append(errs, err)
			continue
		}
		if err := runShell(rendered, env, sessionPath); err != nil {
			fmt.Fprintln(os.Stderr, ui.Warningf("hook %q failed: %v", rendered, err))
			errs = append(errs, err)
		}
	}

	// Check for executable hook script
	scriptPath := filepath.Join(config.ConfigDir(), "hooks", event)
	if info, err := os.Stat(scriptPath); err == nil && info.Mode()&0111 != 0 {
		if err := runShell(scriptPath, env, sessionPath); err != nil {
			fmt.Fprintln(os.Stderr, ui.Warningf("hook script %s failed: %v", scriptPath, err))
			errs = append(errs, err)
		}
	}

	return errs
}

func buildEnv(event string, data tmpl.TemplateData) []string {
	env := os.Environ()

	repoNames := make([]string, len(data.Repos))
	for i, r := range data.Repos {
		repoNames[i] = r.Name
	}

	env = append(env,
		"SESHY_SESSION="+data.Session,
		"SESHY_SESSION_PATH="+data.SessionPath,
		"SESHY_REPOS="+strings.Join(repoNames, ","),
		"SESHY_REPO_COUNT="+strconv.Itoa(len(data.Repos)),
		"SESHY_EVENT="+event,
	)

	return env
}

func runShell(command string, env []string, dir string) error {
	cmd := exec.Command("sh", "-c", command)
	cmd.Dir = dir
	cmd.Env = env
	cmd.Stdout = os.Stderr // hooks output to stderr, not stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
