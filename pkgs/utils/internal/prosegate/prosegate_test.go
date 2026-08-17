package prosegate

import (
	"bytes"
	"encoding/json"
	"os"
	"os/exec"
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
	for i := range 2 {
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

// useStyle reads the rule set the way the installed wrapper does. The styles
// are built by overlays/vale-styles.nix, so `nix develop` supplies both this
// variable and vale; a bare checkout skips rather than fails, because the
// binary is expected to fail open there too.
func useStyle(t *testing.T) {
	t.Helper()
	config := os.Getenv("SYSINIT_PROSE_STYLE")
	if config == "" {
		t.Skip("SYSINIT_PROSE_STYLE is unset; run under nix develop")
	}
	if _, err := exec.LookPath("vale"); err != nil {
		t.Skip("vale is not on PATH")
	}
	if _, err := os.Stat(config); err != nil {
		t.Fatalf("stat %s: %v", config, err)
	}
}

func TestCleanReplyPasses(t *testing.T) {
	useStyle(t)
	got := findings("The build failed. I fixed the overlay.\n\n- one\n- two\n")
	if len(got) != 0 {
		t.Fatalf("clean reply blocked: %v", got)
	}
}

// The old matcher stripped every bullet before it looked for tells, so a bullet
// was the one place a tell could hide.
func TestTellInsideABulletIsCaught(t *testing.T) {
	useStyle(t)
	got := findings("Intro.\n\n- this will seamlessly unlock the thing\n")
	if len(got) == 0 {
		t.Fatal("a marketing verb inside a bullet was not caught")
	}
}

// The old matcher could never reach this rule, because it ran after the bullets
// were removed.
func TestBoldFirstTermIsReachable(t *testing.T) {
	useStyle(t)
	got := findings("Intro.\n\n- **Term**: detail\n- **Other**: detail\n")
	if len(got) == 0 {
		t.Fatal("a bold first term in a bullet was not caught")
	}
}

func TestFencedCodeIsNotReadForTells(t *testing.T) {
	useStyle(t)
	got := findings("Intro.\n\n```\nseamlessly leverage the pivotal unlock\n```\n")
	if len(got) != 0 {
		t.Fatalf("code block was read for tells: %v", got)
	}
}

// One tell is a slip, and a slip is not worth the user's turn.
func TestOneTellDoesNotBlock(t *testing.T) {
	useStyle(t)
	got := findings("This reply leverages one bad verb and nothing else at all.\n")
	if len(got) != 0 {
		t.Fatalf("a single tell blocked: %v", got)
	}
}

func TestMissingStyleFailsOpen(t *testing.T) {
	t.Setenv("SYSINIT_PROSE_STYLE", "")
	got := findings("seamlessly leverage the pivotal unlock, empowering the streamlined delve")
	if len(got) != 0 {
		t.Fatalf("gate blocked without a style: %v", got)
	}
}

// A bad Span silently destroyed prose before `locate` existed. Vale reports a
// default-scope span against markdown-stripped text and a raw-scope span
// against the line as written, so the two disagree on a line carrying both.
func TestLocateRefusesASpanThatDoesNotHoldTheMatch(t *testing.T) {
	line := []rune("- **gantt** - schedule. `task :id, start, dur`. Path B.")
	a := fileAlert{Span: []int{1, 4}}
	a.Match = "XX"
	if _, _, ok := locate(line, a); ok {
		t.Fatal("locate accepted a span whose text is not the match")
	}
}

// The span is a hint. When it is wrong but the match is unambiguous on the
// line, the match itself decides where the edit lands.
func TestLocateFallsBackToTheUniqueMatch(t *testing.T) {
	line := []rune("- gantt - schedule.")
	a := fileAlert{Span: []int{99, 120}}
	a.Match = "schedule"
	start, end, ok := locate(line, a)
	if !ok {
		t.Fatal("locate rejected a unique match")
	}
	if got := string(line[start-1 : end]); got != "schedule" {
		t.Fatalf("located %q, want %q", got, "schedule")
	}
}

// Two occurrences give no way to tell which one vale meant, and guessing is
// what corrupts a file.
func TestLocateRefusesAnAmbiguousMatch(t *testing.T) {
	line := []rune("path and path")
	a := fileAlert{Span: []int{99, 120}}
	a.Match = "path"
	if _, _, ok := locate(line, a); ok {
		t.Fatal("locate accepted an ambiguous match")
	}
}

// Vale reports the match against the text the rule saw, and that match does not
// always take the whole gap with it. A replacement carrying its own spacing then
// doubles a space or strands one behind.
func TestSpliceDoesNotDoubleASpace(t *testing.T) {
	cases := []struct {
		name        string
		line        string
		start, end  int
		replacement string
		want        string
	}{
		{"match keeps the trailing space", "schema.yaml —  name", 13, 14, ": ", "schema.yaml: name"},
		{"match takes the whole gap", "schema.yaml — name", 12, 14, ": ", "schema.yaml: name"},
		{"match leaves the leading space", "a top , b", 7, 7, ", ", "a top, b"},
		{"removal keeps the line", "drop junk here", 6, 10, "", "drop here"},
		{"a wrapped line keeps no trailing space", "in isolation —", 14, 14, ", ", "in isolation,"},
	}
	for _, c := range cases {
		got, _ := splice([]rune(c.line), c.start, c.end, c.replacement)
		if string(got) != c.want {
			t.Fatalf("%s: got %q, want %q", c.name, string(got), c.want)
		}
	}
}

func TestApplyActions(t *testing.T) {
	cases := []struct {
		name   string
		match  string
		action valeAlertAction
		want   string
		ok     bool
	}{
		{"replace", " — ", valeAlertAction{Name: "replace", Params: []string{", "}}, ", ", true},
		{"remove", "junk", valeAlertAction{Name: "remove"}, "", true},
		{"edit", "- **Term**", valeAlertAction{Name: "edit", Params: []string{"regex", `\*\*`, ""}}, "- Term", true},
		{"replace with no params", "x", valeAlertAction{Name: "replace"}, "", false},
		{"unknown", "x", valeAlertAction{Name: "rewrite"}, "", false},
	}
	for _, c := range cases {
		got, ok := apply(c.match, c.action)
		if ok != c.ok {
			t.Fatalf("%s: ok=%v, want %v", c.name, ok, c.ok)
		}
		if ok && got != c.want {
			t.Fatalf("%s: got %q, want %q", c.name, got, c.want)
		}
	}
}
