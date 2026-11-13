package threads

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

func TestThreadActions(t *testing.T) {
	for _, tc := range []struct {
		name    string
		choices []int
		print   bool
		want    []string
	}{
		{"resume", []int{1, 0}, false, []string{"resume", "thread-b", "--as-is"}},
		{"resume-switch", []int{1, 1, 0}, true, []string{"resume", "thread-b", "--print", "--in", "claude-code"}},
		{"resume-original", []int{1, 1, 1}, false, []string{"resume", "thread-b", "--as-is"}},
		{"fork", []int{1, 2}, true, []string{"resume", "thread-b", "--print", "--fork"}},
		{"fork-switch", []int{1, 3, 0}, false, []string{"resume", "thread-b", "--in", "claude-code"}},
		{"fork-original", []int{1, 3, 1}, false, []string{"resume", "thread-b", "--fork"}},
		{"claude-resume-original", []int{0, 1, 0}, false, []string{"resume", "thread-a", "--as-is"}},
		{"claude-fork-original", []int{0, 3, 0}, false, []string{"resume", "thread-a", "--fork"}},
		{"inspect", []int{1, 4}, true, []string{"threads", "show", "thread-b"}},
		{"queue-attempts", []int{1, 5}, false, []string{"task-queue", "browse", "--thread", "thread-b"}},
		{"cancel-thread", []int{-1}, false, nil},
		{"cancel-action", []int{1, -1}, false, nil},
		{"cancel-harness", []int{1, 1, -1}, false, nil},
	} {
		t.Run(tc.name, func(t *testing.T) {
			root := t.TempDir()
			write := func(name, text string, mode os.FileMode) {
				t.Helper()
				if err := os.WriteFile(filepath.Join(root, name), []byte(text), mode); err != nil {
					t.Fatal(err)
				}
			}
			write("atuin", "#!/bin/sh\nprintf '%s' '[{\"atuin_id\":\"thread-a\",\"harness\":\"claude-code\",\"preview\":\"first\",\"cwd\":\"/repo with spaces\"},{\"atuin_id\":\"thread-b\",\"harness\":\"codex\",\"preview\":\"second\",\"cwd\":\"/repo with spaces\"}]'\n", 0o700)
			write("claude", "#!/bin/sh\nexit 0\n", 0o700)
			write("codex", "#!/bin/sh\nexit 0\n", 0o700)
			write("task-queue", "#!/bin/sh\nexit 0\n", 0o700)
			if err := os.Mkdir(filepath.Join(root, "sysinit"), 0o700); err != nil {
				t.Fatal(err)
			}
			registry := `{"version":1,"agents":[{"name":"claude","label":"Claude Code","command":"` + root + `/claude"},{"name":"codex","label":"Codex","command":"` + root + `/codex"},{"name":"goose","label":"Goose","command":"` + root + `/codex"},{"name":"pi","label":"Pi","command":"` + root + `/missing"}]}`
			write("sysinit/agents.json", registry, 0o600)
			t.Setenv("XDG_CONFIG_HOME", root)
			t.Setenv("PATH", root+string(os.PathListSeparator)+os.Getenv("PATH"))
			step := 0
			choose := func(labels []string, prompt string) (int, error) {
				t.Helper()
				if step >= len(tc.choices) {
					t.Fatal("unexpected picker", prompt)
				}
				wantPrompt := []string{"thread> ", "action> ", "harness> "}[step]
				if prompt != wantPrompt {
					t.Fatalf("picker order: %q, want %q", prompt, wantPrompt)
				}
				if step == 1 && !reflect.DeepEqual(labels, []string{"Resume", "Resume (Switch)", "Fork", "Fork (Switch)", "Inspect", "Queue attempts"}) {
					t.Fatalf("actions: %q", labels)
				}
				if step == 2 && !reflect.DeepEqual(labels, []string{"Claude Code", "Codex"}) {
					t.Fatalf("harnesses: %q", labels)
				}
				choice := tc.choices[step]
				step++
				return choice, nil
			}
			var args []string
			if tc.print {
				args = []string{"--print"}
			}
			got, err := prepareInFolder(args, choose, "/repo with spaces")
			if err != nil || !reflect.DeepEqual(got, tc.want) || step != len(tc.choices) {
				t.Fatalf("argv=%q err=%v steps=%d, want %q", got, err, step, tc.want)
			}
		})
	}
}

func TestThreadsProcess(t *testing.T) {
	if os.Getenv("THREADS_TEST_CHILD") == "1" {
		var args []string
		if err := json.Unmarshal([]byte(os.Getenv("THREADS_TEST_ARGS")), &args); err != nil {
			t.Fatal(err)
		}
		os.Exit(Run(args))
	}
}

func TestNativePassthrough(t *testing.T) {
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, "atuin"), []byte("#!/bin/sh\nprintf '%s\\n' \"$@\"\nexit 23\n"), 0o700); err != nil {
		t.Fatal(err)
	}
	cmd := exec.Command(os.Args[0], "-test.run=^TestThreadsProcess$")
	cmd.Env = append(os.Environ(), "THREADS_TEST_CHILD=1", `THREADS_TEST_ARGS=["show","thread with spaces"]`, "PATH="+root+string(os.PathListSeparator)+os.Getenv("PATH"))
	output, err := cmd.CombinedOutput()
	exit, ok := err.(*exec.ExitError)
	if !ok || exit.ExitCode() != 23 || strings.TrimSpace(string(output)) != "threads\nshow\nthread with spaces" {
		t.Fatalf("output=%q err=%v", output, err)
	}
}

func TestWithFullAccess(t *testing.T) {
	access := map[string]fullAccess{
		"claude": {Args: []string{"--dangerously-skip-permissions"}},
		"goose":  {Env: map[string]string{"GOOSE_MODE": "auto"}},
		"amp":    {},
	}
	for _, tc := range []struct{ line, want string }{
		{"cd -- '/repo with spaces' && claude --resume abc", "cd -- '/repo with spaces' && claude --dangerously-skip-permissions --resume abc"},
		{"cd -- /repo && goose session --resume", "cd -- /repo && GOOSE_MODE=auto goose session --resume"},
		{"cd -- /repo && amp threads continue", "cd -- /repo && amp threads continue"},
		{"cd -- /repo && unknown --resume x", "cd -- /repo && unknown --resume x"},
		{"claude --resume abc", "claude --dangerously-skip-permissions --resume abc"},
	} {
		if got := withFullAccess(tc.line, access); got != tc.want {
			t.Fatalf("withFullAccess(%q) = %q, want %q", tc.line, got, tc.want)
		}
	}
}

func TestLoadFullAccess(t *testing.T) {
	path := filepath.Join(t.TempDir(), "agents.json")
	data := `{"agents":[{"command":"codex","launch":{"fullAccess":{"args":["--dangerously-bypass-approvals-and-sandbox"],"env":{}}}}]}`
	if err := os.WriteFile(path, []byte(data), 0o600); err != nil {
		t.Fatal(err)
	}
	access, err := loadFullAccess(path)
	if err != nil || len(access["codex"].Args) != 1 || access["codex"].Args[0] != "--dangerously-bypass-approvals-and-sandbox" {
		t.Fatalf("access=%v err=%v", access, err)
	}
}
