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

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/hookfmt"
)

const Summary = "hold a Stop hook until a declared command passes"

const usage = "usage: loop-gate arm --until '<command>' [--max n] [--stall n] | status | clear | check [--format claude|exit-code|json]"

type state struct {
	Until     string `json:"until"`
	Max       int    `json:"max"`
	Stall     int    `json:"stall"`
	Iter      int    `json:"iter"`
	SameCount int    `json:"sameCount"`
	LastHash  string `json:"lastHash"`
}

type stopEvent struct {
	StopHookActive bool `json:"stop_hook_active"`
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

func shell() string {
	if path, err := exec.LookPath("bash"); err == nil {
		return path
	}
	return "sh"
}

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

// Decide advances the loop by one iteration and reports what the caller owes.
// It is the whole loop-gate decision, with no harness in it: the state file is
// removed on a pass, a stall, or a cap, and written back otherwise.
func Decide(stdin io.Reader) hookfmt.Outcome {
	path := stateFile()
	s, ok := read(path)
	if !ok {
		return hookfmt.PassOutcome()
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
		return hookfmt.PassOutcome()
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
		return hookfmt.PassOutcome()
	}
	if s.Iter >= s.Max {
		os.Remove(path)
		fmt.Fprintf(os.Stderr, "loop-gate: CAPPED at %d iterations; `%s` still failing. Open work, not a pass.\n",
			s.Max, s.Until)
		return hookfmt.PassOutcome()
	}

	if err := write(path, s); err != nil {
		fmt.Fprintf(os.Stderr, "loop-gate: %s\n", err)
		return hookfmt.PassOutcome()
	}

	if stopActive {
		return hookfmt.PassOutcome()
	}

	return hookfmt.Outcome{
		Kind:  hookfmt.Block,
		Event: "Stop",
		Message: fmt.Sprintf(`The declared STOP condition is not met (iteration %d/%d).

Command: %s
Exit code: %d

Output:
%s

Fix the cause and continue. Do not report this phase as done while the command fails.`,
			s.Iter, s.Max, s.Until, code, out),
	}
}

func check(args []string) int {
	format, rest, err := hookfmt.ParseFormat(args, hookfmt.Claude)
	if err != nil {
		fmt.Fprintf(os.Stderr, "loop-gate: %s\n", err)
		return 1
	}
	if len(rest) > 0 {
		fmt.Fprintf(os.Stderr, "loop-gate: unknown argument: %s\n", rest[0])
		return 1
	}
	return hookfmt.Emit(format, Decide(os.Stdin))
}

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
		return check(args[1:])
	default:
		fmt.Fprintln(os.Stderr, usage)
		return 2
	}
}
