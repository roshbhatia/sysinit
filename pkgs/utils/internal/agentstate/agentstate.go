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

// toolKeys names where one harness puts the tool and its detail in the hook
// payload it pipes to stdin. Only the `tool` and `message` reason sources read
// them, and the shape is the harness's, not this tool's.
type toolKeys struct {
	Name    []string
	Detail  []string
	Message []string
}

// orElse fills each field the caller left unset, so overriding one key does not
// silently blank the others.
func (k toolKeys) orElse(fallback toolKeys) toolKeys {
	if len(k.Name) == 0 {
		k.Name = fallback.Name
	}
	if len(k.Detail) == 0 {
		k.Detail = fallback.Detail
	}
	if len(k.Message) == 0 {
		k.Message = fallback.Message
	}
	return k
}

// claudeKeys is also the fallback. Every harness that reports a tool today
// sends Claude Code's shape, so an unlisted one is read as that rather than as
// nothing, and --tool-key overrides it without a code change.
var claudeKeys = toolKeys{
	Name: []string{"tool_name"},
	Detail: []string{
		"tool_input.command",
		"tool_input.file_path",
		"tool_input.path",
		"tool_input.description",
		"tool_input.pattern",
	},
	Message: []string{"message"},
}

var byHarness = map[string]toolKeys{
	"claude": claudeKeys,
}

func keysFor(agent string) toolKeys {
	if keys, ok := byHarness[agent]; ok {
		return keys
	}
	return claudeKeys
}

// parseArgs splits the positional agent/status/reason from the key overrides.
// Each --tool-key, --detail-key, and --message-key is a dotted path into the
// payload, and may repeat; the first one that answers wins.
func parseArgs(args []string) ([]string, toolKeys, error) {
	var positional []string
	var keys toolKeys
	for i := 0; i < len(args); i++ {
		var into *[]string
		switch args[i] {
		case "--tool-key":
			into = &keys.Name
		case "--detail-key":
			into = &keys.Detail
		case "--message-key":
			into = &keys.Message
		default:
			positional = append(positional, args[i])
			continue
		}
		if i+1 >= len(args) {
			return nil, toolKeys{}, fmt.Errorf("%s needs a value", args[i])
		}
		*into = append(*into, args[i+1])
		i++
	}
	return positional, keys, nil
}

func Run(args []string) int {
	positional, keys, err := parseArgs(args)
	if err != nil {
		fmt.Fprintf(os.Stderr, "agent-state: %s\n", err)
		return 1
	}
	agent := arg(positional, 0, "agent")
	status := arg(positional, 1, "working")
	reasonSrc := arg(positional, 2, "")
	keys = keys.orElse(keysFor(agent))

	pane := os.Getenv("WEZTERM_PANE")
	input := readStdin()
	if pane == "" {
		reason := reasonSrc
		if reason == "" {
			reason = status
		}
		registerOrcSession(agent, status, reason, input, pane)
		return 0
	}

	stateDir := paths.AgentPanes()
	stateFile := filepath.Join(stateDir, pane+".json")

	if status == "exit" {
		registerOrcSession(agent, "disconnected", "session ended", input, pane)
		_ = os.Remove(stateFile)
		_ = os.Remove(filepath.Join(stateDir, pane+".start"))
		return 0
	}

	since := time.Now().Unix()

	reason := deriveReason(reasonSrc, status, input, keys, stateDir, pane, since)
	reason = tidy(reason)
	if reason == "" {
		reason = status
	}
	reason = truncate(reason, reasonLimit)
	registerOrcSession(agent, status, reason, input, pane)

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

func registerOrcSession(agent string, status string, reason string, input map[string]any, pane string) {
	executable, err := exec.LookPath("orc")
	if err != nil {
		return
	}
	args := []string{
		"session", "register", "--harness", agent, "--pane", pane, "--pid", strconv.Itoa(os.Getppid()),
		"--status", status, "--reason", reason, "--source", "hook",
	}
	if mux := MuxID(); mux > 0 {
		args = append(args, "--mux", strconv.Itoa(mux))
	}
	if native := dig(input,
		"session_id", "sessionId", "session.id", "thread_id", "threadId", "conversation_id",
	); native != "" {
		args = append(args, "--native-id", native, "--trace-id", native)
	}
	command := exec.Command(executable, args...)
	command.Stdin = nil
	command.Stdout = io.Discard
	command.Stderr = io.Discard
	_ = command.Run()
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

func deriveReason(src, status string, input map[string]any, keys toolKeys, stateDir, pane string, since int64) string {
	switch src {
	case "submit":
		if os.MkdirAll(stateDir, 0o755) == nil {
			_ = os.WriteFile(filepath.Join(stateDir, pane+".start"),
				[]byte(strconv.FormatInt(since, 10)), 0o644)
		}
		return "thinking"
	case "tool":
		tool := dig(input, keys.Name...)
		detail := dig(input, keys.Detail...)
		switch {
		case tool != "" && detail != "":
			return tool + ": " + detail
		case tool != "":
			return tool
		default:
			return status
		}
	case "message":
		if text := dig(input, keys.Message...); text != "" {
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
	defer func() { _ = tty.Close() }()
	_, _ = fmt.Fprintf(tty, "\033]1337;SetUserVar=agent_state=%s\007", encoded)
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
				_ = os.Remove(filepath.Join(stateDir, name))
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
		_ = os.Remove(filepath.Join(stateDir, name))
		_ = os.Remove(filepath.Join(stateDir, pane+".start"))
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
				_ = os.Remove(filepath.Join(stateDir, name))
			}
		}
	}

	if f, err := os.Create(marker); err == nil {
		_ = f.Close()
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
		_ = tmp.Close()
		_ = os.Remove(name)
		return
	}
	if tmp.Close() != nil || os.Rename(name, path) != nil {
		_ = os.Remove(name)
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
