package agentstate

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/internal/paths"
)

const Summary = "record this pane's agent status for the wezterm surfaces"

const reasonLimit = 60

const SchemaVersion = 1

type state struct {
	Version  int    `json:"version"`
	Mux      int    `json:"mux"`
	Pane     any    `json:"pane"`
	Session  string `json:"session"`
	Repo     string `json:"repo"`
	Branch   string `json:"branch"`
	Dirty    bool   `json:"dirty"`
	Worktree string `json:"worktree"`

	Repos  []string `json:"repos,omitempty"`
	Agent  string   `json:"agent"`
	Status string   `json:"status"`
	Reason string   `json:"reason"`
	Since  int64    `json:"since"`
}

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
		Mux:     MuxID(),
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
	reapDeadMuxes(stateDir, record.Mux, pane)
	id := identify(cwd())
	record.Session = id.session
	record.Repo = id.repo
	record.Branch = id.branch
	record.Dirty = id.dirty
	record.Worktree = id.worktree
	record.Repos = id.repos

	publish(stateFile, record)
	return 0
}

func PaneRecord(pane string) (record, start string) {
	dir := paths.AgentPanes()
	return filepath.Join(dir, pane+".json"), filepath.Join(dir, pane+".start")
}

func PaneStatus(pane string) (status, reason string) {
	if pane == "" {
		return "", ""
	}
	file, _ := PaneRecord(pane)
	body, err := os.ReadFile(file)
	if err != nil {
		return "", ""
	}
	var record state
	if json.Unmarshal(body, &record) != nil {
		return "", ""
	}
	if now := MuxID(); record.Mux != 0 && now != 0 && record.Mux != now {
		return "", ""
	}
	return record.Status, record.Reason
}

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

var emitUserVar = writeUserVar

func writeUserVar(encoded string) {
	tty, err := os.OpenFile("/dev/tty", os.O_WRONLY, 0)
	if err != nil {
		return
	}
	defer tty.Close()
	fmt.Fprintf(tty, "\033]1337;SetUserVar=agent_state=%s\007", encoded)
}

func MuxID() int {
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

func muxAlive(pid int) bool {
	if pid <= 0 {
		return false
	}
	return syscall.Kill(pid, 0) == nil
}

const markerPrefix = ".mux-"

func reapDeadMuxes(stateDir string, mux int, self string) {
	if mux <= 0 {
		return
	}
	marker := filepath.Join(stateDir, fmt.Sprintf("%s%d", markerPrefix, mux))
	if _, err := os.Stat(marker); err == nil {
		return
	}

	entries, err := os.ReadDir(stateDir)
	if err != nil {
		return
	}
	live := map[string]bool{}
	for _, entry := range entries {
		name := entry.Name()
		if strings.HasPrefix(name, markerPrefix) {
			pid, convErr := strconv.Atoi(strings.TrimPrefix(name, markerPrefix))
			if convErr == nil && pid != mux && !muxAlive(pid) {
				os.Remove(filepath.Join(stateDir, name))
			}
			continue
		}
		if !strings.HasSuffix(name, ".json") {
			continue
		}
		pane := strings.TrimSuffix(name, ".json")
		body, err := os.ReadFile(filepath.Join(stateDir, name))
		if err != nil {
			continue
		}
		var record struct {
			Mux int `json:"mux"`
		}
		// A record with no mux id cannot be attributed to a GUI that is still
		// running, so it is unverifiable rather than current. Keeping it made
		// every record from a mux-server GUI immortal.
		if json.Unmarshal(body, &record) == nil && (record.Mux == mux || muxAlive(record.Mux)) {
			live[pane] = true
			continue
		}
		os.Remove(filepath.Join(stateDir, name))
		os.Remove(filepath.Join(stateDir, pane+".start"))
	}

	// A turn that starts and never reports leaves a lone .start behind, which
	// the pass above never sees because it walks records.
	for _, entry := range entries {
		name := entry.Name()
		if !strings.HasSuffix(name, ".start") {
			continue
		}
		// self is skipped because a `working submit` writes .start before it
		// publishes the record this pass would look for.
		if pane := strings.TrimSuffix(name, ".start"); !live[pane] && pane != self {
			if _, err := os.Stat(filepath.Join(stateDir, pane+".json")); os.IsNotExist(err) {
				os.Remove(filepath.Join(stateDir, name))
			}
		}
	}

	if f, err := os.Create(marker); err == nil {
		f.Close()
	}
}

func paneValue(pane string) any {
	if n, err := strconv.ParseInt(pane, 10, 64); err == nil && pane != "" {
		return n
	}
	return pane
}

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
	repos    []string
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
		id.repos = childRepos(dir)
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

func childRepos(dir string) []string {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil
	}
	var out []string
	for _, entry := range entries {
		if !entry.IsDir() || strings.HasPrefix(entry.Name(), ".") {
			continue
		}

		if _, err := os.Stat(filepath.Join(dir, entry.Name(), ".git")); err == nil {
			out = append(out, entry.Name())
		}
	}
	sort.Strings(out)
	return out
}

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
