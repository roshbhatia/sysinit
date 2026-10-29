package threads

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"syscall"

	"github.com/roshbhatia/go-utils/agents"
)

const Summary = "pick a captured agent thread, then resume, fork, or inspect it"

const help = `Usage: threads [--print]
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
`

type session struct {
	ID      string `json:"atuin_id"`
	Harness string `json:"harness"`
	Preview string `json:"preview"`
	Cwd     string `json:"cwd"`
}

func Run(args []string) int {
	if len(args) == 1 && (args[0] == "--help" || args[0] == "-h") {
		fmt.Print(help)
		return 0
	}
	argv, err := prepare(args)
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

func prepare(args []string) ([]string, error) {
	printCommand := len(args) == 1 && args[0] == "--print"
	if len(args) > 0 && !printCommand {
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
	if len(sessions) == 0 {
		fmt.Fprintln(os.Stderr, "No captured threads yet.")
		return nil, nil
	}
	labels := make([]string, len(sessions))
	for i, thread := range sessions {
		preview := []rune(thread.Preview)
		if len(preview) > 160 {
			preview = preview[:160]
		}
		labels[i] = fmt.Sprintf("[%s] %s  %s", thread.Harness, string(preview), thread.Cwd)
	}
	index, err := pick(labels, "thread> ")
	if err != nil || index < 0 {
		return nil, err
	}
	thread := sessions[index]
	action, err := pick([]string{"Resume", "Resume (Switch)", "Fork", "Fork (Switch)", "Inspect"}, "action> ")
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
		target, err := pick(labels, "harness> ")
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

func pick(labels []string, prompt string) (int, error) {
	var input strings.Builder
	for i, label := range labels {
		label = strings.Map(func(r rune) rune {
			if r < 32 || r == 127 {
				return ' '
			}
			return r
		}, label)
		fmt.Fprintf(&input, "%d\t%s\n", i, label)
	}
	cmd := exec.Command("fzf", "--height=8", "--layout=reverse", "--no-preview", "--no-multi", "--delimiter=\t", "--with-nth=2..", "--prompt", prompt)
	cmd.Stdin = strings.NewReader(input.String())
	cmd.Stderr = os.Stderr
	var output bytes.Buffer
	cmd.Stdout = &output
	if err := cmd.Run(); err != nil {
		var exit *exec.ExitError
		if errors.As(err, &exit) && (exit.ExitCode() == 1 || exit.ExitCode() == 130) {
			return -1, nil
		}
		return -1, fmt.Errorf("%s picker: %w", strings.TrimSpace(prompt), err)
	}
	value, _, _ := strings.Cut(strings.TrimSpace(output.String()), "\t")
	index, err := strconv.Atoi(value)
	if err != nil || index < 0 || index >= len(labels) {
		return -1, fmt.Errorf("%s picker returned an invalid selection", strings.TrimSpace(prompt))
	}
	return index, nil
}
