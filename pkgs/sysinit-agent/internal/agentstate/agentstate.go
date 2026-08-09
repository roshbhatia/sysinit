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
	"syscall"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/paths"
)

const Summary = "record this pane's agent status for the wezterm surfaces"

// reasonLimit is the width the surfaces render. Truncated here rather than at
// read time, so every consumer sees the same string.
const reasonLimit = 60

// SchemaVersion is the pane record's schema version. Bump it when a field
// changes meaning or disappears, never for an added field: every reader looks
// fields up by name, so an addition is invisible to a reader that does not want
// it.
//
// The schema itself is SCHEMA.md, next to this file. Every reader cites it.
const SchemaVersion = 1

// state is the file-bus record. Field order is the serialized order and the
// names are read by lua, so this struct is a published interface. SCHEMA.md
// states the rules a reader cannot see here.
type state struct {
	Version  int    `json:"version"`
	Mux      int    `json:"mux"`
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

// Run records the status and always returns 0.
func Run(args []string) int {
	agent := arg(args, 0, "agent")
	status := arg(args, 1, "working")
	reasonSrc := arg(args, 2, "")

	pane := os.Getenv("WEZTERM_PANE")
	if pane == "" {
		return 0
	}

	stateDir := paths.AgentPanes()
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

	// Built before either encoding is emitted, so both are rendered from one
	// value. The two used to be assembled separately from the same four
	// variables, which is the same fact with two owners.
	record := state{
		Version: SchemaVersion,
		Mux:     muxID(),
		Pane:    paneValue(pane),
		Agent:   agent,
		Status:  status,
		Reason:  reason,
		Since:   since,
	}

	// The user variable is what the tab bar reads live. Written before the
	// file, and before the identity lookup below, because that lookup forks git
	// and this is the half the owner sees.
	if encoded := base64.StdEncoding.EncodeToString([]byte(userVar(record))); encoded != "" {
		emitUserVar(encoded)
	}

	if os.MkdirAll(stateDir, 0o755) != nil {
		return 0
	}
	reapDeadMuxes(stateDir, record.Mux)
	id := identify(cwd())
	record.Session = id.session
	record.Repo = id.repo
	record.Branch = id.branch
	record.Dirty = id.dirty
	record.Worktree = id.worktree

	publish(stateFile, record)
	return 0
}

// userVar renders the OSC payload from the record, so the two encodings cannot
// disagree about the four fields they share.
//
// The record carries more than this. SCHEMA.md says which reader is entitled to
// which encoding, and why the user variable is the shorter one.
func userVar(r state) string {
	return fmt.Sprintf("%s|%s|%d|%s", r.Status, r.Reason, r.Since, r.Agent)
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
// emitUserVar is the seam the agreement test reads. Production writes the OSC;
// a test swaps it to capture the payload the code actually emits, rather than
// re-deriving one and comparing it to itself.
var emitUserVar = writeUserVar

func writeUserVar(encoded string) {
	tty, err := os.OpenFile("/dev/tty", os.O_WRONLY, 0)
	if err != nil {
		return
	}
	defer tty.Close()
	fmt.Fprintf(tty, "\033]1337;SetUserVar=agent_state=%s\007", encoded)
}

// muxID is the pane record's generation marker: the pid of the wezterm mux the
// pane belongs to, read from the socket path wezterm sets in every pane.
//
// Pane ids restart at 0 in each mux, observed by reading WEZTERM_PANE in a
// running instance and in two freshly started ones, so a pane id alone cannot
// tell yesterday's record from today's. The mux pid can.
//
// This is not the writer's pid, which would be useless: `agent-state` is a
// one-shot and its own pid is dead microseconds after it publishes. The mux
// outlives every record it is stamped on.
//
// Returns 0 when the socket path is absent or shaped differently, which readers
// treat as "no marker" rather than as a mismatch.
func muxID() int {
	socket := os.Getenv("WEZTERM_UNIX_SOCKET")
	if socket == "" {
		return 0
	}
	name := filepath.Base(socket)
	const prefix = "gui-sock-"
	if !strings.HasPrefix(name, prefix) {
		return 0
	}
	pid, err := strconv.Atoi(strings.TrimPrefix(name, prefix))
	if err != nil || pid <= 0 {
		return 0
	}
	return pid
}

// muxAlive reports whether a mux pid is still running. Signal 0 checks for the
// process without delivering anything.
func muxAlive(pid int) bool {
	if pid <= 0 {
		return false
	}
	return syscall.Kill(pid, 0) == nil
}

// reapDeadMuxes removes records left by a mux that is no longer running.
//
// This is the routine trigger, not an edge case: the state directory outlives
// the mux, nothing clears it at mux start, and a fresh mux hands out the same
// low pane ids, so the first pane of a restarted terminal inherits yesterday's
// record and pane existence cannot tell.
//
// Gated on a marker file so it runs once per mux rather than on every tool
// call, which is the hottest path in this binary. One stat is the steady-state
// cost.
func reapDeadMuxes(stateDir string, mux int) {
	if mux <= 0 {
		return
	}
	marker := filepath.Join(stateDir, fmt.Sprintf(".mux-%d", mux))
	if _, err := os.Stat(marker); err == nil {
		return
	}

	entries, err := os.ReadDir(stateDir)
	if err != nil {
		return
	}
	for _, entry := range entries {
		name := entry.Name()
		if !strings.HasSuffix(name, ".json") {
			continue
		}
		body, err := os.ReadFile(filepath.Join(stateDir, name))
		if err != nil {
			continue
		}
		var record struct {
			Mux int `json:"mux"`
		}
		if json.Unmarshal(body, &record) != nil {
			continue
		}
		// A record with no marker predates this field. Left alone: it cannot be
		// shown to be stale, and deleting a live pane's record is the worse
		// failure.
		if record.Mux == 0 || record.Mux == mux || muxAlive(record.Mux) {
			continue
		}
		os.Remove(filepath.Join(stateDir, name))
		os.Remove(filepath.Join(stateDir, strings.TrimSuffix(name, ".json")+".start"))
	}

	// Written last. A failed reap then retries on the next tool call rather
	// than being skipped forever.
	if f, err := os.Create(marker); err == nil {
		f.Close()
	}
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

func identify(dir string) identity {
	var id identity

	// A seshy session directory names the session in its path. That is the only
	// session source here now.
	//
	// The wezterm workspace used to be the fallback, resolved by forking
	// `wezterm cli list` on every tool call. That fork is gone. It cost a
	// process per call to answer a question the readers can already answer for
	// themselves, and caching it would have been worse: a workspace is a
	// per-pane fact recorded under a bare pane id, so a reused id would serve
	// the previous occupant's value.
	//
	// A reader that wants the fallback resolves it live. ui.lua already does
	// (pkg/ui.lua:357, :731) and agent-sessions.sh does it from the
	// `wezterm cli list` it already runs.
	seshyRoot := paths.SeshySessions()
	if rest := strings.TrimPrefix(dir, seshyRoot+"/"); rest != dir {
		id.session = strings.SplitN(rest, "/", 2)[0]
	}

	// Then the zmx session, which is an environment lookup: no fork, no
	// terminal, and inherited by every child of the session, confirmed by probe
	// rather than by documentation.
	//
	// The prefix is stripped, because it is a namespace and not part of the
	// name. `sy list` reports unprefixed names and this record is joined
	// against that list, so leaving the prefix on makes a set difference that
	// removes nothing and emits every live session twice.
	if id.session == "" {
		id.session = zmxSession()
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

// zmxSession reads the current zmx session with the namespace removed.
//
// Empty when the variable is unset, which is a pane that is not in a session,
// and the readers resolve their own fallback from there.
func zmxSession() string {
	name := os.Getenv("ZMX_SESSION")
	if name == "" {
		return ""
	}
	return strings.TrimPrefix(name, os.Getenv("ZMX_SESSION_PREFIX"))
}

func gitOut(dir string, args ...string) string {
	out, err := exec.Command("git", append([]string{"-C", dir}, args...)...).Output()
	if err != nil {
		return ""
	}
	return strings.TrimRight(string(out), "\n")
}
