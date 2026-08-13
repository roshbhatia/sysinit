// Package loopgate holds a Stop hook to a declared condition: it runs the armed command
// and blocks the stop until that command exits 0, gives identical output twice, or the
// iteration cap is reached.
package loopgate

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

const Summary = "hold a Stop hook until a declared command passes"

const usage = "usage: loop-gate arm --until '<command>' [--max n] [--stall n] | status | clear | check"

// state is the armed gate, as it is written between iterations.
type state struct {
	Until     string `json:"until"`
	Max       int    `json:"max"`
	Stall     int    `json:"stall"`
	Iter      int    `json:"iter"`
	SameCount int    `json:"sameCount"`
	LastHash  string `json:"lastHash"`
}

// stopEvent is the part of the Stop payload that matters: a hook already stopping once
// must not block again, or the harness never returns.
type stopEvent struct {
	StopHookActive bool `json:"stop_hook_active"`
}

// blockDecision is the Stop answer shape.
type blockDecision struct {
	Decision string `json:"decision"`
	Reason   string `json:"reason"`
}

func stateDir() string {
	if dir := os.Getenv("SYSINIT_LOOP_GATE_DIR"); dir != "" {
		return dir
	}
	cwd, err := os.Getwd()
	if err != nil {
		return ".sysinit"
	}
	return filepath.Join(cwd, ".sysinit")
}

func stateFile() string {
	return filepath.Join(stateDir(), "loop-gate.json")
}

func read(path string) (state, bool) {
	data, err := os.ReadFile(path)
	if err != nil {
		return state{}, false
	}
	var s state
	if json.Unmarshal(data, &s) != nil {
		return state{}, false
	}
	return s, true
}

func write(path string, s state) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	data, err := json.Marshal(s)
	if err != nil {
		return err
	}
	return os.WriteFile(path, data, 0o644)
}

func arm(args []string) int {
	s := state{Max: 4, Stall: 2}
	for i := 0; i < len(args); i++ {
		if i+1 >= len(args) {
			fmt.Fprintf(os.Stderr, "loop-gate: %s needs a value\n", args[i])
			return 1
		}
		value := args[i+1]
		var err error
		switch args[i] {
		case "--until":
			s.Until = value
		case "--max":
			s.Max, err = strconv.Atoi(value)
		case "--stall":
			s.Stall, err = strconv.Atoi(value)
		default:
			fmt.Fprintf(os.Stderr, "loop-gate: unknown flag: %s\n", args[i])
			return 1
		}
		if err != nil {
			fmt.Fprintln(os.Stderr, "loop-gate: --max and --stall must be integers")
			return 1
		}
		i++
	}
	if s.Until == "" {
		fmt.Fprintln(os.Stderr, "loop-gate: arm requires --until '<command>'")
		return 1
	}
	if err := write(stateFile(), s); err != nil {
		fmt.Fprintf(os.Stderr, "loop-gate: %s\n", err)
		return 1
	}
	fmt.Fprintf(os.Stderr, "loop-gate: armed. STOP is `%s`; CAPPED at %d, STALLED after %d unchanged.\n",
		s.Until, s.Max, s.Stall)
	return 0
}

func status() int {
	path := stateFile()
	s, ok := read(path)
	if !ok {
		fmt.Printf("loop-gate: disarmed (no state at %s)\n", path)
		return 0
	}
	fmt.Printf("loop-gate: armed\n  STOP:    %s\n  iter:    %d/%d\n  unchanged: %d/%d\n",
		s.Until, s.Iter, s.Max, s.SameCount, s.Stall)
	return 0
}

func clear() int {
	if err := os.Remove(stateFile()); err != nil && !os.IsNotExist(err) {
		fmt.Fprintf(os.Stderr, "loop-gate: %s\n", err)
		return 1
	}
	fmt.Fprintln(os.Stderr, "loop-gate: disarmed.")
	return 0
}

// shell is what the armed command is run by. bash when there is one, because a command
// armed by hand may hold a bash-only test.
func shell() string {
	if path, err := exec.LookPath("bash"); err == nil {
		return path
	}
	return "sh"
}

// run executes the armed command and returns its combined output with trailing newlines
// dropped, so the hash is over the text a reader sees.
func run(command string) (string, int) {
	cmd := exec.Command(shell(), "-c", command)
	out, err := cmd.CombinedOutput()
	text := strings.TrimRight(string(out), "\n")
	if err == nil {
		return text, 0
	}
	var exit *exec.ExitError
	if errors.As(err, &exit) {
		return text, exit.ExitCode()
	}
	return text, 1
}

func check(stdin io.Reader) int {
	path := stateFile()
	s, ok := read(path)
	if !ok {
		return 0
	}

	stopActive := false
	if data, err := io.ReadAll(stdin); err == nil {
		var ev stopEvent
		if json.Unmarshal(data, &ev) == nil {
			stopActive = ev.StopHookActive
		}
	}

	out, code := run(s.Until)
	if code == 0 {
		os.Remove(path)
		fmt.Fprintf(os.Stderr, "loop-gate: CLEAN after %d iteration(s) — `%s` exited 0.\n", s.Iter, s.Until)
		return 0
	}

	s.Iter++
	sum := sha256.Sum256([]byte(out))
	hash := hex.EncodeToString(sum[:])
	if hash == s.LastHash {
		s.SameCount++
	} else {
		s.SameCount = 0
	}
	s.LastHash = hash

	if s.SameCount >= s.Stall {
		os.Remove(path)
		fmt.Fprintf(os.Stderr, "loop-gate: STALLED — %d iterations produced identical output from `%s`. Open work, not a pass.\n",
			s.SameCount, s.Until)
		return 0
	}
	if s.Iter >= s.Max {
		os.Remove(path)
		fmt.Fprintf(os.Stderr, "loop-gate: CAPPED at %d iterations; `%s` still failing. Open work, not a pass.\n",
			s.Max, s.Until)
		return 0
	}

	if err := write(path, s); err != nil {
		fmt.Fprintf(os.Stderr, "loop-gate: %s\n", err)
		return 1
	}

	if stopActive {
		return 0
	}

	reason := fmt.Sprintf(`The declared STOP condition is not met (iteration %d/%d).

Command: %s
Exit code: %d

Output:
%s

Fix the cause and continue. Do not report this phase as done while the command fails.`,
		s.Iter, s.Max, s.Until, code, out)
	encoded, err := json.Marshal(blockDecision{Decision: "block", Reason: reason})
	if err != nil {
		fmt.Fprintf(os.Stderr, "loop-gate: %s\n", err)
		return 1
	}
	fmt.Println(string(encoded))
	return 0
}

// Run dispatches the subcommand.
func Run(args []string) int {
	if len(args) == 0 {
		fmt.Fprintln(os.Stderr, usage)
		return 2
	}
	switch args[0] {
	case "arm":
		return arm(args[1:])
	case "status":
		return status()
	case "clear":
		return clear()
	case "check":
		return check(os.Stdin)
	default:
		fmt.Fprintln(os.Stderr, usage)
		return 2
	}
}
