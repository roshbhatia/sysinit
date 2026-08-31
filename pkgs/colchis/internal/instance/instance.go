package instance

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	"golang.org/x/sys/unix"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/api/socket"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/config"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
	gitutil "github.com/roshbhatia/sysinit/pkgs/internal/git"
	"github.com/roshbhatia/sysinit/pkgs/internal/paths"
)

const Version = 1

const SessionVersion = 1

var ErrSessionNotRegistered = errors.New("session is not registered with Orc")

type Record struct {
	Version        int    `json:"version"`
	Key            string `json:"key"`
	Scope          string `json:"scope"`
	StateDirectory string `json:"stateDirectory"`
	Socket         string `json:"socket"`
	Service        string `json:"service,omitempty"`
	Executable     string `json:"executable,omitempty"`
	Automatic      bool   `json:"automatic,omitempty"`
	Stopping       bool   `json:"stopping,omitempty"`
	PID            int    `json:"pid"`
	StartedAt      string `json:"startedAt"`
}

// Session is a harness-owned conversation registered with an Orc workspace.
type Session struct {
	Version         int      `json:"version"`
	ID              string   `json:"id"`
	Role            string   `json:"role"`
	Harness         string   `json:"harness"`
	NativeSessionID string   `json:"nativeSessionId,omitempty"`
	TraceSessionID  string   `json:"traceSessionId,omitempty"`
	Title           string   `json:"title,omitempty"`
	Purpose         string   `json:"purpose,omitempty"`
	AgentRole       string   `json:"agentRole,omitempty"`
	Goal            string   `json:"goal,omitempty"`
	ExpectedOutput  string   `json:"expectedOutput,omitempty"`
	SuccessCriteria []string `json:"successCriteria,omitempty"`
	ReviewBy        string   `json:"reviewBy,omitempty"`
	Handoff         string   `json:"handoff,omitempty"`
	Scope           string   `json:"scope"`
	Directory       string   `json:"directory,omitempty"`
	Pane            string   `json:"pane,omitempty"`
	Mux             int      `json:"mux,omitempty"`
	ZMXSession      string   `json:"zmxSession,omitempty"`
	PID             int      `json:"pid,omitempty"`
	ProcessIdentity uint64   `json:"processIdentity,omitempty"`
	Status          string   `json:"status"`
	Reason          string   `json:"reason,omitempty"`
	Registration    string   `json:"registration"`
	Origin          string   `json:"origin,omitempty"`
	Capabilities    []string `json:"capabilities"`
	StartedAt       string   `json:"startedAt"`
	UpdatedAt       string   `json:"updatedAt"`
}

type SessionRegistration struct {
	ID              string
	Harness         string
	NativeSessionID string
	TraceSessionID  string
	Title           string
	Purpose         string
	AgentRole       string
	Goal            string
	ExpectedOutput  string
	SuccessCriteria []string
	ReviewBy        string
	Handoff         string
	Directory       string
	Pane            string
	Mux             int
	ZMXSession      string
	PID             int
	ProcessIdentity uint64
	Status          string
	Reason          string
	Registration    string
	Capabilities    []string
}

func BaseDirectory() string {
	return filepath.Join(paths.StateHome(), "orc", "w")
}

func Physical(path string) (string, error) {
	absolute, err := filepath.Abs(path)
	if err != nil {
		return "", err
	}
	resolved, err := filepath.EvalSymlinks(absolute)
	if err != nil {
		return "", err
	}
	return filepath.Clean(resolved), nil
}

func DefaultScope(directory string) (string, error) {
	physical, err := Physical(directory)
	if err != nil {
		return "", err
	}
	root, err := gitutil.Root(physical)
	if err != nil {
		return physical, nil
	}
	return Physical(root)
}

func Candidate(scope string) (Record, config.Paths, error) {
	physical, err := Physical(scope)
	if err != nil {
		return Record{}, config.Paths{}, err
	}
	digest := sha256.Sum256([]byte(physical))
	key := hex.EncodeToString(digest[:8])
	stateDirectory := filepath.Join(BaseDirectory(), key)
	resolved, err := config.ResolvePaths(stateDirectory)
	if err != nil {
		return Record{}, config.Paths{}, err
	}
	return Record{
		Version: Version, Key: key, Scope: physical,
		StateDirectory: resolved.StateDirectory, Socket: resolved.Socket,
	}, resolved, nil
}

func Active(directory string) (Record, bool, error) {
	record, found, err := Match(directory)
	if err != nil || !found {
		return record, false, err
	}
	return record, Live(record), nil
}

func Match(directory string) (Record, bool, error) {
	if stateDirectory := os.Getenv("ORC_STATE_DIR"); stateDirectory != "" {
		resolved, err := config.ResolvePaths(stateDirectory)
		if err != nil {
			return Record{}, false, err
		}
		record, err := Read(filepath.Join(resolved.StateDirectory, "instance.json"))
		if err == nil {
			return record, true, nil
		}
		if !errors.Is(err, os.ErrNotExist) {
			return Record{}, false, err
		}
	}
	physical, err := Physical(directory)
	if err != nil {
		return Record{}, false, err
	}
	records, err := List()
	if err != nil {
		return Record{}, false, err
	}
	for _, record := range records {
		if Contains(record.Scope, physical) {
			return record, true, nil
		}
	}
	return Record{}, false, nil
}

func List() ([]Record, error) {
	entries, err := os.ReadDir(BaseDirectory())
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	records := make([]Record, 0, len(entries))
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		record, err := Read(filepath.Join(BaseDirectory(), entry.Name(), "instance.json"))
		if err == nil {
			records = append(records, record)
		}
	}
	sort.Slice(records, func(first, second int) bool {
		if len(records[first].Scope) != len(records[second].Scope) {
			return len(records[first].Scope) > len(records[second].Scope)
		}
		return records[first].Scope < records[second].Scope
	})
	return records, nil
}

func Read(path string) (Record, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return Record{}, err
	}
	var record Record
	if err := json.Unmarshal(data, &record); err != nil {
		return Record{}, err
	}
	if record.Version != Version || record.Scope == "" || record.StateDirectory == "" || record.Socket == "" {
		return Record{}, errors.New("instance record is incomplete")
	}
	return record, nil
}

func Write(record Record) error {
	if record.Version != Version || record.StateDirectory == "" {
		return errors.New("instance record is incomplete")
	}
	if err := os.MkdirAll(record.StateDirectory, 0o700); err != nil {
		return err
	}
	data, err := json.Marshal(record)
	if err != nil {
		return err
	}
	temporary, err := os.CreateTemp(record.StateDirectory, ".instance-*.json")
	if err != nil {
		return err
	}
	name := temporary.Name()
	defer os.Remove(name)
	if err := temporary.Chmod(0o600); err != nil {
		_ = temporary.Close()
		return err
	}
	if _, err := temporary.Write(append(data, '\n')); err != nil {
		_ = temporary.Close()
		return err
	}
	if err := temporary.Close(); err != nil {
		return err
	}
	return os.Rename(name, filepath.Join(record.StateDirectory, "instance.json"))
}

func Remove(record Record) error {
	path := filepath.Join(record.StateDirectory, "instance.json")
	current, err := Read(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil
	}
	if err != nil {
		return err
	}
	if current.PID != record.PID {
		return fmt.Errorf("instance record now belongs to process %d", current.PID)
	}
	return os.Remove(path)
}

func RegisterSession(record Record, registration SessionRegistration) (Session, error) {
	if registration.Harness == "" {
		return Session{}, errors.New("session harness is empty")
	}
	if !safeSessionIdentifier(registration.Harness) ||
		registration.ID != "" && !safeSessionIdentifier(registration.ID) {
		return Session{}, errors.New("session harness or id contains an unsupported character")
	}
	if registration.ID == "" && registration.NativeSessionID == "" && registration.Pane == "" {
		return Session{}, errors.New("session needs an id, native id, or pane")
	}
	directory := filepath.Join(record.StateDirectory, "controller-sessions")
	if err := os.MkdirAll(directory, 0o700); err != nil {
		return Session{}, err
	}
	lock, err := os.OpenFile(filepath.Join(directory, ".lock"), os.O_CREATE|os.O_RDWR, 0o600)
	if err != nil {
		return Session{}, err
	}
	defer lock.Close()
	if err := unix.Flock(int(lock.Fd()), unix.LOCK_EX); err != nil {
		return Session{}, err
	}
	defer unix.Flock(int(lock.Fd()), unix.LOCK_UN)
	sessions, err := Sessions(record)
	if err != nil {
		return Session{}, err
	}
	current := Session{}
	for _, candidate := range sessions {
		matches := false
		if registration.ID != "" {
			matches = candidate.ID == registration.ID
		} else if registration.NativeSessionID != "" {
			matches = candidate.Harness == registration.Harness &&
				(candidate.NativeSessionID == registration.NativeSessionID ||
					candidate.NativeSessionID == "" && candidate.Status != "disconnected" &&
						candidate.Pane != "" && candidate.Pane == registration.Pane &&
						candidate.Mux == registration.Mux)
		} else if registration.Pane != "" && registration.Registration != "spawned" {
			matches = candidate.Harness == registration.Harness && candidate.Pane == registration.Pane &&
				candidate.Mux == registration.Mux && candidate.Status != "disconnected"
		}
		if matches {
			if registration.Harness != "" && candidate.Harness != "" && candidate.Harness != registration.Harness {
				return Session{}, fmt.Errorf("session %q belongs to harness %q", candidate.ID, candidate.Harness)
			}
			current = candidate
			break
		}
	}
	if current.ID == "" && registration.Registration == "hook" {
		return Session{}, ErrSessionNotRegistered
	}
	if current.ID == "" {
		current.ID = registration.ID
		if current.ID == "" {
			current.ID = availableSessionID(sessions, registration)
		}
		now := time.Now().UTC().Format(time.RFC3339Nano)
		current.Version = SessionVersion
		current.Role = "controller"
		current.Scope = record.Scope
		current.StartedAt = now
	}
	current.Harness = registration.Harness
	if registration.NativeSessionID != "" {
		current.NativeSessionID = registration.NativeSessionID
	}
	if registration.TraceSessionID != "" {
		current.TraceSessionID = registration.TraceSessionID
	} else if current.TraceSessionID == "" && current.NativeSessionID != "" {
		current.TraceSessionID = current.NativeSessionID
	}
	if registration.Title != "" {
		current.Title = registration.Title
	}
	if registration.Purpose != "" {
		current.Purpose = registration.Purpose
	}
	if registration.AgentRole != "" {
		current.AgentRole = registration.AgentRole
	}
	if registration.Goal != "" {
		current.Goal = registration.Goal
	}
	if registration.ExpectedOutput != "" {
		current.ExpectedOutput = registration.ExpectedOutput
	}
	if len(registration.SuccessCriteria) > 0 {
		current.SuccessCriteria = uniqueStrings(registration.SuccessCriteria)
	}
	if registration.ReviewBy != "" {
		current.ReviewBy = registration.ReviewBy
	}
	if registration.Handoff != "" {
		current.Handoff = registration.Handoff
	}
	if registration.Directory != "" {
		current.Directory = registration.Directory
	}
	if registration.Pane != "" {
		current.Pane = registration.Pane
	}
	if registration.Mux > 0 {
		current.Mux = registration.Mux
	}
	if registration.ZMXSession != "" {
		current.ZMXSession = registration.ZMXSession
	}
	preserveProcess := false
	if registration.Registration == "hook" && current.ZMXSession == "" && current.PID > 0 && current.ProcessIdentity > 0 {
		identity, found, identityErr := plugin.ProcessIdentity(current.PID)
		preserveProcess = identityErr == nil && found && identity == current.ProcessIdentity
	}
	if registration.PID > 0 && !preserveProcess {
		current.PID = registration.PID
		current.ProcessIdentity = registration.ProcessIdentity
	}
	if registration.Status != "" {
		current.Status = registration.Status
	} else if current.Status == "" {
		current.Status = "working"
	}
	if registration.Reason != "" {
		current.Reason = registration.Reason
	}
	source := registration.Registration
	switch source {
	case "observed", "managed":
		current.Registration = source
	default:
		current.Registration = "registered"
	}
	if current.Origin == "" || source == "spawned" || source == "injected" {
		current.Origin = source
	}
	if len(registration.Capabilities) > 0 {
		current.Capabilities = uniqueStrings(registration.Capabilities)
	}
	current.UpdatedAt = time.Now().UTC().Format(time.RFC3339Nano)
	if err := writeSession(record, current); err != nil {
		return Session{}, err
	}
	if registration.ID != "" && current.PID > 0 && current.ProcessIdentity > 0 {
		for _, duplicate := range sessions {
			if duplicate.ID == current.ID || duplicate.Harness != current.Harness ||
				duplicate.PID != current.PID || duplicate.ProcessIdentity != current.ProcessIdentity {
				continue
			}
			if err := removeSessionLocked(record, duplicate.ID); err != nil {
				return Session{}, err
			}
		}
	}
	return current, nil
}

func Sessions(record Record) ([]Session, error) {
	directory := filepath.Join(record.StateDirectory, "controller-sessions")
	entries, err := os.ReadDir(directory)
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	sessions := make([]Session, 0, len(entries))
	for _, entry := range entries {
		if entry.IsDir() || filepath.Ext(entry.Name()) != ".json" {
			continue
		}
		data, readErr := os.ReadFile(filepath.Join(directory, entry.Name()))
		if readErr != nil {
			continue
		}
		var session Session
		if json.Unmarshal(data, &session) == nil && session.Version == SessionVersion && session.ID != "" {
			sessions = append(sessions, session)
		}
	}
	sort.Slice(sessions, func(first, second int) bool {
		return sessions[first].UpdatedAt > sessions[second].UpdatedAt
	})
	return sessions, nil
}

func SessionByID(record Record, id string) (Session, bool, error) {
	sessions, err := Sessions(record)
	if err != nil {
		return Session{}, false, err
	}
	for _, session := range sessions {
		if session.ID == id {
			return session, true, nil
		}
	}
	return Session{}, false, nil
}

func CurrentSession(record Record) (Session, bool, error) {
	sessions, err := Sessions(record)
	if err != nil {
		return Session{}, false, err
	}
	id := os.Getenv("ORC_SESSION_ID")
	pane := os.Getenv("WEZTERM_PANE")
	mux := wezTermMuxID()
	native := ""
	nativeHarness := ""
	for _, candidate := range []struct {
		key     string
		harness string
	}{
		{key: "CLAUDE_CODE_SESSION_ID", harness: "claude"},
		{key: "CODEX_SESSION_ID", harness: "codex"},
		{key: "CODEX_THREAD_ID", harness: "codex"},
	} {
		if native = os.Getenv(candidate.key); native != "" {
			nativeHarness = candidate.harness
			break
		}
	}
	for _, session := range sessions {
		if session.Status == "disconnected" {
			continue
		}
		if id != "" && session.ID == id ||
			native != "" && session.Harness == nativeHarness && session.NativeSessionID == native {
			if sessionProcessMatches(session) {
				return session, true, nil
			}
			continue
		}
		if pane != "" && session.Pane == pane && session.Mux > 0 && mux == session.Mux {
			if sessionProcessMatches(session) {
				return session, true, nil
			}
		}
	}
	return Session{}, false, nil
}

func sessionProcessMatches(session Session) bool {
	if session.PID <= 0 || session.ProcessIdentity == 0 {
		return false
	}
	identity, found, err := plugin.ProcessIdentity(session.PID)
	return err == nil && found && identity == session.ProcessIdentity
}

func RemoveSession(record Record, id string) error {
	directory := filepath.Join(record.StateDirectory, "controller-sessions")
	if err := os.MkdirAll(directory, 0o700); err != nil {
		return err
	}
	lock, err := os.OpenFile(filepath.Join(directory, ".lock"), os.O_CREATE|os.O_RDWR, 0o600)
	if err != nil {
		return err
	}
	defer lock.Close()
	if err := unix.Flock(int(lock.Fd()), unix.LOCK_EX); err != nil {
		return err
	}
	defer unix.Flock(int(lock.Fd()), unix.LOCK_UN)
	return removeSessionLocked(record, id)
}

func removeSessionLocked(record Record, id string) error {
	if !safeSessionIdentifier(id) {
		return errors.New("session id contains an unsupported character")
	}
	path := filepath.Join(record.StateDirectory, "controller-sessions", id+".json")
	if err := os.Remove(path); err != nil && !errors.Is(err, os.ErrNotExist) {
		return err
	}
	return nil
}

func writeSession(record Record, session Session) error {
	directory := filepath.Join(record.StateDirectory, "controller-sessions")
	if err := os.MkdirAll(directory, 0o700); err != nil {
		return err
	}
	data, err := json.Marshal(session)
	if err != nil {
		return err
	}
	temporary, err := os.CreateTemp(directory, ".session-*.json")
	if err != nil {
		return err
	}
	name := temporary.Name()
	defer os.Remove(name)
	if err := temporary.Chmod(0o600); err != nil {
		_ = temporary.Close()
		return err
	}
	if _, err := temporary.Write(append(data, '\n')); err != nil {
		_ = temporary.Close()
		return err
	}
	if err := temporary.Close(); err != nil {
		return err
	}
	return os.Rename(name, filepath.Join(directory, session.ID+".json"))
}

func sessionID(harness string, native string, pane string, mux int) string {
	digest := sha256.Sum256([]byte(fmt.Sprintf("%s\x00%s\x00%s\x00%d", harness, native, pane, mux)))
	return harness + "-" + hex.EncodeToString(digest[:6])
}

func availableSessionID(sessions []Session, registration SessionRegistration) string {
	base := sessionID(registration.Harness, registration.NativeSessionID, registration.Pane, registration.Mux)
	for _, session := range sessions {
		if session.ID == base {
			digest := sha256.Sum256([]byte(fmt.Sprintf("%s\x00%d", base, time.Now().UnixNano())))
			return base + "-" + hex.EncodeToString(digest[:3])
		}
	}
	return base
}

func safeSessionIdentifier(value string) bool {
	if value == "" || value == "." || value == ".." {
		return false
	}
	for _, character := range value {
		if character >= 'a' && character <= 'z' || character >= 'A' && character <= 'Z' ||
			character >= '0' && character <= '9' || strings.ContainsRune("._-", character) {
			continue
		}
		return false
	}
	return true
}

func wezTermMuxID() int {
	name := filepath.Base(os.Getenv("WEZTERM_UNIX_SOCKET"))
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

func uniqueStrings(values []string) []string {
	seen := make(map[string]struct{}, len(values))
	result := make([]string, 0, len(values))
	for _, value := range values {
		if value == "" {
			continue
		}
		if _, found := seen[value]; found {
			continue
		}
		seen[value] = struct{}{}
		result = append(result, value)
	}
	sort.Strings(result)
	return result
}

func Live(record Record) bool {
	info, err := os.Stat(record.Socket)
	if err != nil || info.Mode()&os.ModeSocket == 0 {
		return false
	}
	client, err := socket.NewClient(record.Socket)
	if err != nil {
		return false
	}
	defer client.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 150*time.Millisecond)
	defer cancel()
	_, err = client.Events(ctx, 0, 1)
	return err == nil
}

func Contains(scope string, directory string) bool {
	relative, err := filepath.Rel(scope, directory)
	if err != nil {
		return false
	}
	return relative == "." || (relative != ".." && !strings.HasPrefix(relative, ".."+string(filepath.Separator)))
}

func NewRecord(scope string, service string, automatic bool) (Record, config.Paths, error) {
	record, resolved, err := Candidate(scope)
	if err != nil {
		return Record{}, config.Paths{}, err
	}
	executable, err := os.Executable()
	if err != nil {
		return Record{}, config.Paths{}, err
	}
	executable, err = filepath.EvalSymlinks(executable)
	if err != nil {
		return Record{}, config.Paths{}, err
	}
	record.Service = service
	record.Executable = executable
	record.Automatic = automatic
	record.PID = os.Getpid()
	record.StartedAt = time.Now().UTC().Format(time.RFC3339Nano)
	return record, resolved, nil
}
