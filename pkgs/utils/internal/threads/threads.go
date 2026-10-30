package threads

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"github.com/roshbhatia/go-utils/agents"
)

const Summary = "pick a captured agent thread, then resume, fork, or inspect it"

const help = `Usage: threads [--all|-a] [--print]
       threads <atuin-threads arguments...>

Pick a thread, then choose:
  Resume          Resume its existing local session
  Resume (Switch) Choose a harness and continue there
  Fork            Create a session in the original harness
  Fork (Switch)   Choose a harness and create a session there
  Inspect         Show its captured conversation

Switching harnesses always creates a new session through Atuin conversion.
--print prints the launch command; forks and conversions still create sessions.
Other arguments pass through to atuin threads, including list/search/show/resume.
By default, the picker shows threads captured in the current folder and its
subfolders. Use --all or -a to show threads from every folder.
`

type session struct {
	ID           string `json:"atuin_id"`
	Harness      string `json:"harness"`
	Preview      string `json:"preview"`
	Cwd          string `json:"cwd"`
	UpdatedAt    string `json:"updated_at"`
	MessageCount int    `json:"message_count"`
}

func Run(args []string) int {
	if len(args) == 1 && (args[0] == "--help" || args[0] == "-h") {
		fmt.Print(help)
		return 0
	}
	argv, err := prepare(args, pick)
	if err == nil && len(argv) > 0 {
		var binary string
		binary, err = exec.LookPath("atuin")
		if err == nil {
			err = syscall.Exec(binary, append([]string{"atuin"}, argv...), os.Environ())
		}
	}
	if err != nil {
		fmt.Fprintf(os.Stderr, "threads: %v\n", err)
		return 1
	}
	return 0
}

func prepare(args []string, choose func([]string, string) (int, error)) ([]string, error) {
	root, err := os.Getwd()
	if err != nil {
		return nil, fmt.Errorf("get current folder: %w", err)
	}
	return prepareInFolder(args, choose, root)
}

func prepareInFolder(args []string, choose func([]string, string) (int, error), root string) ([]string, error) {
	all, printCommand := false, false
	var passthrough []string
	for _, arg := range args {
		switch arg {
		case "--all", "-a":
			all = true
		case "--print":
			printCommand = true
		default:
			passthrough = append(passthrough, arg)
		}
	}
	if len(passthrough) > 0 {
		return append([]string{"threads"}, args...), nil
	}
	cmd := exec.Command("atuin", "threads", "list", "--style", "json")
	cmd.Stderr = os.Stderr
	data, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("list captured threads: %w", err)
	}
	var sessions []session
	if err := json.Unmarshal(data, &sessions); err != nil {
		return nil, fmt.Errorf("decode captured threads: %w", err)
	}
	root, err = filepath.Abs(root)
	if err != nil {
		return nil, fmt.Errorf("resolve current folder: %w", err)
	}
	if !all {
		filtered := sessions[:0]
		for _, thread := range sessions {
			if withinFolder(root, thread.Cwd) {
				filtered = append(filtered, thread)
			}
		}
		sessions = filtered
	}
	if len(sessions) == 0 {
		if all {
			fmt.Fprintln(os.Stderr, "No captured threads yet.")
		} else {
			fmt.Fprintf(os.Stderr, "No captured threads in %s. Use threads --all to view all folders.\n", root)
		}
		return nil, nil
	}
	labels := make([]string, len(sessions))
	for i, thread := range sessions {
		preview := []rune(thread.Preview)
		if len(preview) > 160 {
			preview = preview[:160]
		}
		folder := thread.Cwd
		if !all {
			if relative, err := filepath.Rel(root, thread.Cwd); err == nil {
				folder = relative
			}
		}
		if folder == "." || folder == "" {
			folder = filepath.Base(root)
		}
		if home, err := os.UserHomeDir(); err == nil {
			if relative, err := filepath.Rel(home, folder); err == nil && relative != ".." && !strings.HasPrefix(relative, ".."+string(filepath.Separator)) {
				folder = filepath.Join("~", relative)
			}
		}
		updated := thread.UpdatedAt
		if timestamp, err := time.Parse(time.RFC3339Nano, updated); err == nil {
			updated = timestamp.Local().Format("Jan 02 15:04")
		} else if len(updated) >= 16 {
			updated = updated[:16]
		}
		labels[i] = fmt.Sprintf("└─ [%s] %d msgs · %s · %s · %s", thread.Harness, thread.MessageCount, updated, string(preview), folder)
	}
	index, err := choose(labels, "thread> ")
	if err != nil || index < 0 {
		return nil, err
	}
	thread := sessions[index]
	action, err := choose([]string{"Resume", "Resume (Switch)", "Fork", "Fork (Switch)", "Inspect"}, "action> ")
	if err != nil || action < 0 {
		return nil, err
	}
	if action == 4 {
		return []string{"threads", "show", thread.ID}, nil
	}
	argv := []string{"resume", thread.ID}
	if printCommand {
		argv = append(argv, "--print")
	}
	if action == 1 || action == 3 {
		registry, err := agents.Load()
		if err != nil {
			return nil, fmt.Errorf("load harness registry: %w", err)
		}
		var harnesses []agents.Agent
		var labels []string
		for _, agent := range registry.Agents {
			switch agent.Name {
			case "claude", "codex", "opencode", "pi", "omp":
				if _, err := exec.LookPath(agent.Command); err == nil {
					harnesses = append(harnesses, agent)
					labels = append(labels, agent.Label)
				}
			}
		}
		if len(harnesses) == 0 {
			return nil, errors.New("no installed harness supports Atuin thread conversion")
		}
		target, err := choose(labels, "harness> ")
		if err != nil || target < 0 {
			return nil, err
		}
		original := thread.Harness
		if original == "claude-code" {
			original = "claude"
		}
		if harnesses[target].Name != original {
			return append(argv, "--in", harnesses[target].Name), nil
		}
	}
	if action == 2 || action == 3 {
		return append(argv, "--fork"), nil
	}
	return append(argv, "--as-is"), nil
}

func withinFolder(root, candidate string) bool {
	if candidate == "" {
		return false
	}
	candidate, err := filepath.Abs(candidate)
	if err != nil {
		return false
	}
	relative, err := filepath.Rel(root, candidate)
	return err == nil && relative != ".." && !filepath.IsAbs(relative) && !strings.HasPrefix(relative, ".."+string(filepath.Separator))
}
