package statusline

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"

	"github.com/roshbhatia/go-utils/paths"
)

const Summary = "render the claude status line"

const separator = " · "

type payload struct {
	Model struct {
		DisplayName string `json:"display_name"`
	} `json:"model"`
	Workspace struct {
		CurrentDir string `json:"current_dir"`
	} `json:"workspace"`
	CWD           string `json:"cwd"`
	ContextWindow struct {
		UsedPercentage json.Number `json:"used_percentage"`
	} `json:"context_window"`
}

func Run(_ []string) int {
	data, err := io.ReadAll(os.Stdin)
	if err != nil {
		return 0
	}
	var doc payload
	if json.Unmarshal(data, &doc) != nil {
		return 0
	}

	dir := doc.Workspace.CurrentDir
	if dir == "" {
		dir = doc.CWD
	}

	var parts []string
	if doc.Model.DisplayName != "" {
		parts = append(parts, doc.Model.DisplayName)
	}
	if pct := wholePercent(doc.ContextWindow.UsedPercentage.String()); pct != "" {
		parts = append(parts, pct+"% ctx")
	}
	if dir != "" {
		if branch := gitBranch(dir); branch != "" {
			parts = append(parts, "git:"+branch)
		}
		if session := seshySession(dir); session != "" {
			parts = append(parts, "seshy:"+session)
		}
	}

	fmt.Print(strings.Join(parts, separator))
	return 0
}

func wholePercent(raw string) string {
	if raw == "" {
		return ""
	}
	if i := strings.Index(raw, "."); i >= 0 {
		raw = raw[:i]
	}
	return raw
}

func gitBranch(dir string) string {
	out, err := exec.Command("git", "-C", dir, "branch", "--show-current").Output()
	if err != nil {
		return ""
	}
	return strings.TrimRight(string(out), "\n")
}

func seshySession(dir string) string {
	root := paths.SeshySessions()
	rest := strings.TrimPrefix(dir, root+"/")
	if rest == dir {
		return ""
	}
	return strings.SplitN(rest, "/", 2)[0]
}
