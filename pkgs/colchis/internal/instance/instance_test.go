package instance

import (
	"errors"
	"os"
	"path/filepath"
	"testing"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
)

func TestCandidateUsesPhysicalScope(t *testing.T) {
	real := t.TempDir()
	physical, err := filepath.EvalSymlinks(real)
	if err != nil {
		t.Fatalf("EvalSymlinks() returned %v", err)
	}
	link := filepath.Join(t.TempDir(), "scope")
	if err := os.Symlink(real, link); err != nil {
		t.Fatalf("Symlink() returned %v", err)
	}
	record, _, err := Candidate(link)
	if err != nil {
		t.Fatalf("Candidate() returned %v", err)
	}
	if record.Scope != physical {
		t.Fatalf("scope = %q, want %q", record.Scope, physical)
	}
}

func TestContainsHonorsPathBoundaries(t *testing.T) {
	root := filepath.Join(t.TempDir(), "repo")
	for _, test := range []struct {
		path string
		want bool
	}{
		{path: root, want: true},
		{path: filepath.Join(root, "nested"), want: true},
		{path: root + "-other", want: false},
	} {
		if got := Contains(root, test.path); got != test.want {
			t.Fatalf("Contains(%q, %q) = %t, want %t", root, test.path, got, test.want)
		}
	}
}

func TestNewRecordCapturesBrokerExecutable(t *testing.T) {
	record, _, err := NewRecord(t.TempDir(), "manual", false)
	if err != nil {
		t.Fatalf("NewRecord() returned %v", err)
	}
	executable, err := os.Executable()
	if err != nil {
		t.Fatalf("os.Executable() returned %v", err)
	}
	executable, err = filepath.EvalSymlinks(executable)
	if err != nil {
		t.Fatalf("EvalSymlinks() returned %v", err)
	}
	if record.Executable != executable {
		t.Fatalf("executable = %q, want %q", record.Executable, executable)
	}
}

func TestRegisteredSessionKeepsIdentityAcrossHookUpdates(t *testing.T) {
	record := Record{Version: Version, Scope: "/workspace", StateDirectory: t.TempDir()}
	created, err := RegisterSession(record, SessionRegistration{
		Harness: "codex", Pane: "7", Mux: 41, Status: "working", Registration: "spawned",
	})
	if err != nil {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	updated, err := RegisterSession(record, SessionRegistration{
		ID: created.ID, Harness: "codex", Pane: "7", Mux: 41, NativeSessionID: "thread-42",
		Status: "done", Registration: "hook",
	})
	if err != nil {
		t.Fatalf("RegisterSession() update returned %v", err)
	}
	if updated.ID != created.ID || updated.NativeSessionID != "thread-42" || updated.TraceSessionID != "thread-42" {
		t.Fatalf("updated session = %#v, created = %#v", updated, created)
	}
	sessions, err := Sessions(record)
	if err != nil || len(sessions) != 1 {
		t.Fatalf("Sessions() = %#v, %v", sessions, err)
	}
}

func TestCurrentSessionUsesPaneBinding(t *testing.T) {
	record := Record{Version: Version, Scope: "/workspace", StateDirectory: t.TempDir()}
	identity, found, err := plugin.ProcessIdentity(os.Getpid())
	if err != nil || !found {
		t.Fatalf("ProcessIdentity() = %d, %t, %v", identity, found, err)
	}
	registered, err := RegisterSession(record, SessionRegistration{
		Harness: "claude", Pane: "19", Mux: 73, PID: os.Getpid(), ProcessIdentity: identity,
	})
	if err != nil {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	t.Setenv("ORC_SESSION_ID", "")
	t.Setenv("CLAUDE_CODE_SESSION_ID", "")
	t.Setenv("CODEX_SESSION_ID", "")
	t.Setenv("CODEX_THREAD_ID", "")
	t.Setenv("WEZTERM_PANE", "19")
	t.Setenv("WEZTERM_UNIX_SOCKET", "/tmp/gui-sock-73")
	current, found, err := CurrentSession(record)
	if err != nil || !found || current.ID != registered.ID {
		t.Fatalf("CurrentSession() = %#v, %t, %v", current, found, err)
	}
	t.Setenv("WEZTERM_PANE", "20")
	if _, found, err := CurrentSession(record); err != nil || found {
		t.Fatalf("unbound CurrentSession() found = %t, err = %v", found, err)
	}
}

func TestRegisterSessionSeparatesReusedPaneAcrossMuxes(t *testing.T) {
	record := Record{Version: Version, Scope: "/workspace", StateDirectory: t.TempDir()}
	first, err := RegisterSession(record, SessionRegistration{Harness: "claude", Pane: "19", Mux: 73})
	if err != nil {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	second, err := RegisterSession(record, SessionRegistration{Harness: "claude", Pane: "19", Mux: 74})
	if err != nil {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	if first.ID == second.ID {
		t.Fatalf("reused pane ids match: %q", first.ID)
	}
}

func TestNativeHookPromotesInjectedPaneSession(t *testing.T) {
	record := Record{Version: Version, Scope: "/workspace", StateDirectory: t.TempDir()}
	injected, err := RegisterSession(record, SessionRegistration{
		Harness: "codex", Pane: "19", Mux: 73, Registration: "injected",
	})
	if err != nil {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	registered, err := RegisterSession(record, SessionRegistration{
		Harness: "codex", NativeSessionID: "thread-42", Pane: "19", Mux: 73, Registration: "hook",
	})
	if err != nil {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	if registered.ID != injected.ID || registered.NativeSessionID != "thread-42" {
		t.Fatalf("registered = %#v, injected = %#v", registered, injected)
	}
}

func TestDisconnectedPaneGetsANewSessionID(t *testing.T) {
	record := Record{Version: Version, Scope: "/workspace", StateDirectory: t.TempDir()}
	first, err := RegisterSession(record, SessionRegistration{
		Harness: "atomic", Pane: "19", Mux: 73, Status: "disconnected", Registration: "injected",
	})
	if err != nil {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	second, err := RegisterSession(record, SessionRegistration{
		Harness: "atomic", Pane: "19", Mux: 73, Status: "working", Registration: "injected",
	})
	if err != nil {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	if second.ID == first.ID {
		t.Fatalf("new session reused %q", first.ID)
	}
}

func TestHookCannotEnrollADirectSession(t *testing.T) {
	record := Record{Version: Version, Scope: "/workspace", StateDirectory: t.TempDir()}
	_, err := RegisterSession(record, SessionRegistration{
		Harness: "codex", NativeSessionID: "thread-direct", Pane: "19", Mux: 73, Registration: "hook",
	})
	if !errors.Is(err, ErrSessionNotRegistered) {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	sessions, err := Sessions(record)
	if err != nil || len(sessions) != 0 {
		t.Fatalf("Sessions() = %#v, %v", sessions, err)
	}
}

func TestNativeHookDoesNotPromoteDisconnectedProvisionalSession(t *testing.T) {
	record := Record{Version: Version, Scope: "/workspace", StateDirectory: t.TempDir()}
	if _, err := RegisterSession(record, SessionRegistration{
		Harness: "codex", Pane: "19", Mux: 73, Status: "disconnected", Registration: "injected",
	}); err != nil {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	_, err := RegisterSession(record, SessionRegistration{
		Harness: "codex", NativeSessionID: "thread-42", Pane: "19", Mux: 73, Registration: "hook",
	})
	if !errors.Is(err, ErrSessionNotRegistered) {
		t.Fatalf("RegisterSession() returned %v", err)
	}
}

func TestHookPreservesLiveControllerIdentity(t *testing.T) {
	record := Record{Version: Version, Scope: "/workspace", StateDirectory: t.TempDir()}
	identity, found, err := plugin.ProcessIdentity(os.Getpid())
	if err != nil || !found {
		t.Fatalf("ProcessIdentity() = %d, %t, %v", identity, found, err)
	}
	created, err := RegisterSession(record, SessionRegistration{
		Harness: "codex", Pane: "19", Mux: 73, PID: os.Getpid(), ProcessIdentity: identity,
		Registration: "injected",
	})
	if err != nil {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	updated, err := RegisterSession(record, SessionRegistration{
		ID: created.ID, Harness: "codex", PID: os.Getppid(), ProcessIdentity: 1, Registration: "hook",
	})
	if err != nil {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	if updated.PID != created.PID || updated.ProcessIdentity != created.ProcessIdentity {
		t.Fatalf("updated process = %d/%d, want %d/%d", updated.PID, updated.ProcessIdentity,
			created.PID, created.ProcessIdentity)
	}
}

func TestCurrentSessionRejectsUnverifiedPaneBinding(t *testing.T) {
	record := Record{Version: Version, Scope: "/workspace", StateDirectory: t.TempDir()}
	if _, err := RegisterSession(record, SessionRegistration{Harness: "claude", Pane: "19"}); err != nil {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	t.Setenv("WEZTERM_PANE", "19")
	t.Setenv("WEZTERM_UNIX_SOCKET", "/tmp/gui-sock-73")
	if _, found, err := CurrentSession(record); err != nil || found {
		t.Fatalf("CurrentSession() found = %t, err = %v", found, err)
	}
}

func TestCurrentSessionRejectsStaleProcessIdentity(t *testing.T) {
	record := Record{Version: Version, Scope: "/workspace", StateDirectory: t.TempDir()}
	if _, err := RegisterSession(record, SessionRegistration{
		Harness: "claude", Pane: "19", Mux: 73, PID: os.Getpid(), ProcessIdentity: 1,
	}); err != nil {
		t.Fatalf("RegisterSession() returned %v", err)
	}
	t.Setenv("WEZTERM_PANE", "19")
	t.Setenv("WEZTERM_UNIX_SOCKET", "/tmp/gui-sock-73")
	if _, found, err := CurrentSession(record); err != nil || found {
		t.Fatalf("CurrentSession() found = %t, err = %v", found, err)
	}
}

func TestRemoveSessionRejectsTraversal(t *testing.T) {
	record := Record{Version: Version, Scope: "/workspace", StateDirectory: t.TempDir()}
	if err := RemoveSession(record, "../instance"); err == nil {
		t.Fatal("RemoveSession() accepted a traversal id")
	}
}
