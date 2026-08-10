// Package agentstate implements `agent-state`: the per-pane status the wezterm
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

// reasonLimit is the width the surfaces render.
const reasonLimit = 60

// SchemaVersion is the pane record's schema version.
const SchemaVersion = 1

// state is the file-bus record.
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

	record := state{
		Version: SchemaVersion,
		Mux:     muxID(),
		Pane:    paneValue(pane),
		Agent:   agent,
		Status:  status,
		Reason:  reason,
		Since:   since,
	}

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

// muxAlive reports whether a mux pid is still running.
func muxAlive(pid int) bool {
	if pid <= 0 {
		return false
	}
	return syscall.Kill(pid, 0) == nil
}

// reapDeadMuxes removes records left by a mux that is no longer running.
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
		if record.Mux == 0 || record.Mux == mux || muxAlive(record.Mux) {
			continue
		}
		os.Remove(filepath.Join(stateDir, name))
		os.Remove(filepath.Join(stateDir, strings.TrimSuffix(name, ".json")+".start"))
	}

	if f, err := os.Create(marker); err == nil {
		f.Close()
	}
}

// paneValue keeps a numeric pane id a JSON number and anything else a string,
func paneValue(pane string) any {
	if n, err := strconv.ParseInt(pane, 10, 64); err == nil && pane != "" {
		return n
	}
	return pane
}

// publish writes through a temp file in the same directory.
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

	seshyRoot := paths.SeshySessions()
	if rest := strings.TrimPrefix(dir, seshyRoot+"/"); rest != dir {
		id.session = strings.SplitN(rest, "/", 2)[0]
	}

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
