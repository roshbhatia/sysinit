// Package agentstate implements `agent-state`: the per-pane status the wezterm
// surfaces read.
//
// This runs on every tool call, so it is the hottest path in the binary. The
// on-disk layout and the OSC user variable are both read by code that is not
// in this repository's Go tree: modules/home/programs/wezterm reads the file
// bus, so neither may change shape here.
//
// Every failure is silent and exits 0. A status update that cannot be written
// must never fail the tool call it is annotating.
package agentstate

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

const Summary = "record this pane's agent status for the wezterm surfaces"

// reasonLimit is the width the surfaces render. Truncated here rather than at
// read time, so every consumer sees the same string.
const reasonLimit = 60

// state is the file-bus record. Field order is the serialized order and the
// names are read by lua, so this struct is a published interface.
type state struct {
	Pane     any    `json:"pane"`
	Session  string `json:"session"`
	Repo     string `json:"repo"`
	Branch   string `json:"branch"`
	Dirty    bool   `json:"dirty"`
	Worktree string `json:"worktree"`
	Agent    string `json:"agent"`
	Status   string `json:"status"`
	Reason   string `json:"reason"`
	Since    int64  `json:"since"`
}

func stateHome() string {
	if home := strings.TrimRight(os.Getenv("XDG_STATE_HOME"), "/"); home != "" {
		return home
	}
	return filepath.Join(os.Getenv("HOME"), ".local", "state")
}

// Run records the status and always returns 0.
func Run(args []string) int {
	agent := arg(args, 0, "agent")
	status := arg(args, 1, "working")
	reasonSrc := arg(args, 2, "")

	pane := os.Getenv("WEZTERM_PANE")
	if pane == "" {
		return 0
	}

	stateDir := filepath.Join(stateHome(), "agents", "panes")
	stateFile := filepath.Join(stateDir, pane+".json")

	if status == "exit" {
		os.Remove(stateFile)
		os.Remove(filepath.Join(stateDir, pane+".start"))
		return 0
	}

	input := readStdin()
	since := time.Now().Unix()

	reason := deriveReason(reasonSrc, status, input, stateDir, pane, since)
	reason = tidy(reason)
	if reason == "" {
		reason = status
	}
	reason = truncate(reason, reasonLimit)

	// The user variable is what the tab bar reads live. Written before the
	// file, because it is the half the owner sees.
	payload := fmt.Sprintf("%s|%s|%d|%s", status, reason, since, agent)
	if encoded := base64.StdEncoding.EncodeToString([]byte(payload)); encoded != "" {
		writeUserVar(encoded)
	}

	if os.MkdirAll(stateDir, 0o755) != nil {
		return 0
	}
	id := identify(cwd(), pane)
	record := state{
		Pane:     paneValue(pane),
		Session:  id.session,
		Repo:     id.repo,
		Branch:   id.branch,
		Dirty:    id.dirty,
		Worktree: id.worktree,
		Agent:    agent,
		Status:   status,
		Reason:   reason,
		Since:    since,
	}
	publish(stateFile, record)
	return 0
}

func arg(args []string, i int, fallback string) string {
	if i < len(args) && args[i] != "" {
		return args[i]
	}
	return fallback
}

func cwd() string {
	dir, err := os.Getwd()
	if err != nil {
		return os.Getenv("PWD")
	}
	return dir
}

// readStdin returns the hook payload, or nothing when stdin is a terminal.
//
// The terminal test matters: called by hand with no redirect, a blocking read
// would hang the pane it is reporting on.
func readStdin() map[string]any {
	info, err := os.Stdin.Stat()
	if err != nil || info.Mode()&os.ModeCharDevice != 0 {
		return nil
	}
	data, err := io.ReadAll(os.Stdin)
	if err != nil || len(data) == 0 {
		return nil
	}
	var parsed map[string]any
	if json.Unmarshal(data, &parsed) != nil {
		return nil
	}
	return parsed
}

// dig walks a dotted path and returns the first non-empty string it finds.
func dig(doc map[string]any, paths ...string) string {
	for _, path := range paths {
		var cur any = doc
		ok := true
		for _, part := range strings.Split(path, ".") {
			node, isMap := cur.(map[string]any)
			if !isMap {
				ok = false
				break
			}
			cur, ok = node[part]
			if !ok {
				break
			}
		}
		if !ok {
			continue
		}
		if text, isString := cur.(string); isString && text != "" {
			return text
		}
	}
	return ""
}

func deriveReason(src, status string, input map[string]any, stateDir, pane string, since int64) string {
	switch src {
	case "submit":
		// The start stamp is what the surfaces subtract to show elapsed time.
		if os.MkdirAll(stateDir, 0o755) == nil {
			os.WriteFile(filepath.Join(stateDir, pane+".start"),
				[]byte(strconv.FormatInt(since, 10)), 0o644)
		}
		return "thinking"
	case "tool":
		tool := dig(input, "tool_name")
		detail := dig(input,
			"tool_input.command",
			"tool_input.file_path",
			"tool_input.path",
			"tool_input.description",
			"tool_input.pattern")
		switch {
		case tool != "" && detail != "":
			return tool + ": " + detail
		case tool != "":
			return tool
		default:
			return status
		}
	case "message":
		if text := dig(input, "message"); text != "" {
			return text
		}
		return status
	case "":
		return status
	default:
		return src
	}
}

// tidy folds the separators the payload uses into spaces, then squeezes runs.
//
// The pipe is the payload's own field separator, so one in a reason forges a
// field. A newline does the same to the file bus.
func tidy(reason string) string {
	replaced := strings.Map(func(r rune) rune {
		switch r {
		case '|', '\n', '\r', '\t':
			return ' '
		}
		return r
	}, reason)
	return strings.Join(strings.Fields(replaced), " ")
}

func truncate(s string, limit int) string {
	runes := []rune(s)
	if len(runes) <= limit {
		return s
	}
	return string(runes[:limit])
}

// writeUserVar emits the OSC 1337 sequence wezterm reads.
//
// Sent to /dev/tty rather than stdout: the caller's stdout is a hook's, and a
// control sequence in it corrupts the payload the harness is parsing.
func writeUserVar(encoded string) {
	tty, err := os.OpenFile("/dev/tty", os.O_WRONLY, 0)
	if err != nil {
		return
	}
	defer tty.Close()
	fmt.Fprintf(tty, "\033]1337;SetUserVar=agent_state=%s\007", encoded)
}

// paneValue keeps a numeric pane id a JSON number and anything else a string,
// which is what the shell original's case statement did.
func paneValue(pane string) any {
	if n, err := strconv.ParseInt(pane, 10, 64); err == nil && pane != "" {
		return n
	}
	return pane
}

// publish writes through a temp file in the same directory.
//
// A surface reading a half-written record shows garbage in the tab bar, and
// this rewrites on every tool call, so the window is not theoretical.
func publish(path string, record state) {
	data, err := json.Marshal(record)
	if err != nil {
		return
	}
	tmp, err := os.CreateTemp(filepath.Dir(path), filepath.Base(path)+".*")
	if err != nil {
		return
	}
	name := tmp.Name()
	if _, err := tmp.Write(append(data, '\n')); err != nil {
		tmp.Close()
		os.Remove(name)
		return
	}
	if tmp.Close() != nil || os.Rename(name, path) != nil {
		os.Remove(name)
	}
}

type identity struct {
	session  string
	repo     string
	branch   string
	dirty    bool
	worktree string
}

func identify(dir, pane string) identity {
	var id identity
	workspace := paneWorkspace(pane)

	// A seshy session directory names the session in its path. That is
	// authoritative; the wezterm workspace is the fallback.
	seshyRoot := filepath.Join(os.Getenv("HOME"), ".local", "state", "seshy", "sessions")
	if rest := strings.TrimPrefix(dir, seshyRoot+"/"); rest != dir {
		id.session = strings.SplitN(rest, "/", 2)[0]
	}
	if id.session == "" && workspace != "" && workspace != "default" {
		id.session = workspace
	}

	toplevel := gitOut(dir, "rev-parse", "--show-toplevel")
	if toplevel == "" {
		return id
	}
	id.worktree = toplevel
	id.repo = filepath.Base(toplevel)
	if branch := gitOut(dir, "rev-parse", "--abbrev-ref", "HEAD"); branch != "HEAD" {
		id.branch = branch
	}
	id.dirty = gitOut(dir, "status", "--porcelain") != ""
	return id
}

func gitOut(dir string, args ...string) string {
	out, err := exec.Command("git", append([]string{"-C", dir}, args...)...).Output()
	if err != nil {
		return ""
	}
	return strings.TrimRight(string(out), "\n")
}

// paneWorkspace asks wezterm which workspace owns this pane.
//
// Absent wezterm this is simply unknown, not an error: the same command runs
// under other terminals, where the file bus is still worth writing.
func paneWorkspace(pane string) string {
	if pane == "" {
		return ""
	}
	out, err := exec.Command("wezterm", "cli", "list", "--format", "json").Output()
	if err != nil {
		return ""
	}
	var panes []struct {
		PaneID    json.Number `json:"pane_id"`
		Workspace string      `json:"workspace"`
	}
	if json.Unmarshal(out, &panes) != nil {
		return ""
	}
	for _, entry := range panes {
		if entry.PaneID.String() == pane {
			return entry.Workspace
		}
	}
	return ""
}
