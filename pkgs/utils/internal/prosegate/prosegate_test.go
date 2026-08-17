package prosegate

import (
	"bytes"
	"encoding/json"
	"os"
	"strings"
	"testing"
)

func runRemind(t *testing.T, session string) string {
	t.Helper()
	var out bytes.Buffer
	stdout := os.Stdout
	r, w, err := os.Pipe()
	if err != nil {
		t.Fatalf("pipe: %v", err)
	}
	os.Stdout = w
	event, err := json.Marshal(map[string]string{"session_id": session})
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}
	remind(bytes.NewReader(event))
	w.Close()
	os.Stdout = stdout
	if _, err := out.ReadFrom(r); err != nil {
		t.Fatalf("read: %v", err)
	}
	return out.String()
}

func TestRemindIsArmedNotConstant(t *testing.T) {
	t.Setenv("SYSINIT_PROSE_GATE_DIR", t.TempDir())
	const session = "s1"

	if first := runRemind(t, session); !strings.Contains(first, "Answer shape") {
		t.Fatalf("first prompt of a session must carry the reminder, got %q", first)
	}
	if second := runRemind(t, session); strings.TrimSpace(second) != "" {
		t.Fatalf("an unblocked turn must stay silent, got %q", second)
	}

	arm(session)
	if third := runRemind(t, session); !strings.Contains(third, "Answer shape") {
		t.Fatalf("the prompt after a block must carry the reminder, got %q", third)
	}
	if fourth := runRemind(t, session); strings.TrimSpace(fourth) != "" {
		t.Fatalf("the reminder must disarm after one injection, got %q", fourth)
	}
}

func TestRemindWithoutSessionAlwaysInjects(t *testing.T) {
	t.Setenv("SYSINIT_PROSE_GATE_DIR", t.TempDir())
	for i := 0; i < 2; i++ {
		if out := runRemind(t, ""); !strings.Contains(out, "Answer shape") {
			t.Fatalf("an unknown session must always inject, run %d got %q", i, out)
		}
	}
}

func TestRemindHonoursTheOffSwitch(t *testing.T) {
	t.Setenv("SYSINIT_PROSE_GATE_DIR", t.TempDir())
	t.Setenv("SYSINIT_PROSE_GATE", "off")
	if out := runRemind(t, "s2"); strings.TrimSpace(out) != "" {
		t.Fatalf("SYSINIT_PROSE_GATE=off must silence the reminder, got %q", out)
	}
}

func TestSessionIDCannotEscapeTheStateDir(t *testing.T) {
	dir := t.TempDir()
	t.Setenv("SYSINIT_PROSE_GATE_DIR", dir)
	if path := armPath("../escape"); path != "" {
		t.Fatalf("a session id with a separator must not resolve to a path, got %q", path)
	}
}
