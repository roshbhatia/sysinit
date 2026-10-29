package threads

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func TestThreadsProcess(t *testing.T) {
	if os.Getenv("THREADS_TEST_CHILD") == "1" {
		os.Exit(Run(strings.Fields(os.Getenv("THREADS_TEST_ARGS"))))
	}
}

func TestThreadActions(t *testing.T) {
	for _, tc := range []struct {
		name, action, target, cancel, arguments, want, prompts string
	}{
		{"resume", "1", "", "", "", "resume\nthread-b\n--as-is\n", "thread> action> "},
		{"resume-switch", "2", "1", "", "--print", "resume\nthread-b\n--print\n--in\nclaude\n", "thread> action> harness> "},
		{"resume-original", "2", "2", "", "", "resume\nthread-b\n--as-is\n", "thread> action> harness> "},
		{"fork", "3", "", "", "--print", "resume\nthread-b\n--print\n--fork\n", "thread> action> "},
		{"fork-switch", "4", "1", "", "", "resume\nthread-b\n--in\nclaude\n", "thread> action> harness> "},
		{"fork-original", "4", "2", "", "", "resume\nthread-b\n--fork\n", "thread> action> harness> "},
		{"claude-resume-original", "2", "1", "", "", "resume\nthread-b\n--as-is\n", "thread> action> harness> "},
		{"claude-fork-original", "4", "1", "", "", "resume\nthread-b\n--fork\n", "thread> action> harness> "},
		{"inspect", "5", "", "", "--print", "threads\nshow\nthread-b\n", "thread> action> "},
		{"cancel-thread", "", "", "thread> ", "", "", "thread> "},
		{"cancel-action", "", "", "action> ", "", "", "thread> action> "},
		{"cancel-harness", "2", "", "harness> ", "", "", "thread> action> harness> "},
		{"passthrough", "", "", "", "list --style json", "", ""},
	} {
		t.Run(tc.name, func(t *testing.T) {
			root := t.TempDir()
			write := func(name, text string, mode os.FileMode) {
				t.Helper()
				if err := os.WriteFile(filepath.Join(root, name), []byte(text), mode); err != nil {
					t.Fatal(err)
				}
			}
			write("atuin", `#!/bin/sh
set -eu
if [ "$*" = 'threads list --style json' ]; then
  cat "$THREADS_TEST_ROOT/sessions.json"
else
  printf '%s\n' "$@"
  exit 23
fi
`, 0o700)
			write("fzf", `#!/bin/sh
set -eu
while [ "$#" -gt 0 ]; do
  if [ "$1" = --prompt ]; then shift; prompt="$1"; fi
  shift
done
printf '%s' "$prompt" >> "$THREADS_TEST_ROOT/prompts"
stage="${prompt%%>*}"
cat > "$THREADS_TEST_ROOT/$stage"
if [ "$prompt" = "$THREADS_TEST_CANCEL" ]; then exit 130; fi
case "$stage" in
  thread) row=2 ;;
  action) row="$THREADS_TEST_ACTION" ;;
  harness) row="$THREADS_TEST_TARGET" ;;
esac
sed -n "${row}p" "$THREADS_TEST_ROOT/$stage"
`, 0o700)
			write("claude", "#!/bin/sh\nexit 0\n", 0o700)
			write("codex", "#!/bin/sh\nexit 0\n", 0o700)
			sessions := `[{"atuin_id":"thread-a","harness":"claude-code","preview":"first"},{"atuin_id":"thread-b","harness":"codex","preview":"second\nline\u001b","cwd":"/repo with spaces"}]`
			if strings.HasPrefix(tc.name, "claude-") {
				sessions = strings.ReplaceAll(sessions, `"harness":"codex"`, `"harness":"claude-code"`)
			}
			write("sessions.json", sessions, 0o600)
			config := filepath.Join(root, "sysinit")
			if err := os.Mkdir(config, 0o700); err != nil {
				t.Fatal(err)
			}
			registry := `{"version":1,"agents":[{"name":"claude","label":"Claude Code","command":"` + root + `/claude"},{"name":"codex","label":"Codex","command":"` + root + `/codex"},{"name":"goose","label":"Goose","command":"` + root + `/codex"},{"name":"pi","label":"Pi","command":"` + root + `/missing"}]}`
			if err := os.WriteFile(filepath.Join(config, "agents.json"), []byte(registry), 0o600); err != nil {
				t.Fatal(err)
			}
			cmd := exec.Command(os.Args[0], "-test.run=^TestThreadsProcess$")
			cmd.Env = append(os.Environ(),
				"THREADS_TEST_CHILD=1", "THREADS_TEST_ROOT="+root,
				"THREADS_TEST_ACTION="+tc.action, "THREADS_TEST_TARGET="+tc.target,
				"THREADS_TEST_CANCEL="+tc.cancel, "THREADS_TEST_ARGS="+tc.arguments,
				"XDG_CONFIG_HOME="+root, "PATH="+root+string(os.PathListSeparator)+os.Getenv("PATH"))
			output, err := cmd.CombinedOutput()
			wantCode := 0
			if tc.want != "" {
				wantCode = 23
			}
			code := 0
			if err != nil {
				if exit, ok := err.(*exec.ExitError); ok {
					code = exit.ExitCode()
				} else {
					t.Fatal(err)
				}
			}
			if code != wantCode {
				t.Fatalf("exit %d, want %d: %s", code, wantCode, output)
			}
			if tc.name == "passthrough" {
				var sessions []session
				if err := json.Unmarshal(output, &sessions); err != nil || len(sessions) != 2 {
					t.Fatalf("native JSON output changed: %s (%v)", output, err)
				}
			} else if string(output) != tc.want {
				t.Fatalf("native arguments = %q, want %q", output, tc.want)
			}
			prompts, _ := os.ReadFile(filepath.Join(root, "prompts"))
			if string(prompts) != tc.prompts {
				t.Fatalf("picker order = %q, want %q", prompts, tc.prompts)
			}
			if strings.Contains(tc.prompts, "action>") {
				choices, _ := os.ReadFile(filepath.Join(root, "action"))
				if string(choices) != "0\tResume\n1\tResume (Switch)\n2\tFork\n3\tFork (Switch)\n4\tInspect\n" {
					t.Fatalf("action menu = %q", choices)
				}
			}
			if strings.Contains(tc.prompts, "harness>") {
				choices, _ := os.ReadFile(filepath.Join(root, "harness"))
				if string(choices) != "0\tClaude Code\n1\tCodex\n" {
					t.Fatalf("unsupported or missing harness in menu: %q", choices)
				}
			}
		})
	}
}
