package statusline

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/paths"
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
		if change, extra := openspecChange(dir); change != "" {
			if extra > 0 {
				parts = append(parts, fmt.Sprintf("openspec:%s +%d", change, extra))
			} else {
				parts = append(parts, "openspec:"+change)
			}
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

func openspecChange(dir string) (string, int) {
	root := dir
	for root != "" && root != "/" {
		if _, err := os.Stat(filepath.Join(root, "openspec", "config.yaml")); err == nil {
			break
		}
		next := filepath.Dir(root)
		if next == root {
			return "", 0
		}
		root = next
	}
	if root == "" || root == "/" {
		return "", 0
	}

	entries, err := os.ReadDir(filepath.Join(root, "openspec", "changes"))
	if err != nil {
		return "", 0
	}
	type stamped struct {
		name  string
		mtime int64
	}
	var changes []stamped
	for _, entry := range entries {
		if entry.Name() == "archive" {
			continue
		}
		info, err := entry.Info()
		if err != nil {
			continue
		}
		changes = append(changes, stamped{entry.Name(), info.ModTime().UnixNano()})
	}
	if len(changes) == 0 {
		return "", 0
	}
	sort.Slice(changes, func(i, j int) bool { return changes[i].mtime > changes[j].mtime })
	return changes[0].name, len(changes) - 1
}
