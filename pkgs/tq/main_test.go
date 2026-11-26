package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"testing"
	"time"
)

var testBinary string

func TestHelpAndInvalidCommandsDoNotOpenQueue(t *testing.T) {
	if testBinary == "" {
		t.Skip("set TQ_TESTS=1 to build tq")
	}
	dir := filepath.Join(t.TempDir(), "attempts")
	for _, tt := range []struct {
		args []string
		want string
		ok   bool
	}{
		{[]string{"--help"}, "task-queue submit --help", true},
		{[]string{"help"}, "task-queue submit --help", true},
		{[]string{"submit", "--help"}, "task-queue submit [OPTIONS]", true},
		{[]string{"submit"}, "pass an explicit command", false},
		{[]string{"submit", "--session", "work", "--cwd", ".", "--", "echo"}, "choose --session or --cwd", false},
		{[]string{"reconcile", "extra"}, "reconcile accepts no arguments", false},
		{[]string{"invalid"}, "unknown action", false},
	} {
		t.Run(strings.Join(tt.args, " "), func(t *testing.T) {
			cmd := exec.Command(testBinary, append([]string{"--state", dir}, tt.args...)...)
			cmd.Env = append(os.Environ(), "PATH="+t.TempDir())
			out, err := cmd.CombinedOutput()
			if (err == nil) != tt.ok || !strings.Contains(string(out), tt.want) {
				t.Fatalf("command returned %v: %s", err, out)
			}
			if _, err := os.Stat(dir); !os.IsNotExist(err) {
				t.Fatalf("command touched attempt storage: %v", err)
			}
		})
	}
}

func TestMain(m *testing.M) {
	if os.Getenv("TQ_TESTS") == "1" {
		root, e := os.MkdirTemp("", "queue-test-bin-")
		if e != nil {
			panic(e)
		}
		testBinary = filepath.Join(root, "tq")
		c := exec.Command("go", "build", "-o", testBinary, ".")
		c.Stdout = os.Stdout
		c.Stderr = os.Stderr
		if e = c.Run(); e != nil {
			panic(e)
		}
		code := m.Run()
		_ = os.RemoveAll(root)
		os.Exit(code)
	}
	os.Exit(m.Run())
}

type fixture struct {
	t      *testing.T
	root   string
	env    []string
	daemon *exec.Cmd
}

func (f *fixture) command(name string, args ...string) ([]byte, error) {
	c := exec.Command(name, args...)
	c.Env = f.env
	var stderr bytes.Buffer
	c.Stderr = &stderr
	b, e := c.Output()
	if e != nil {
		b = append(b, stderr.Bytes()...)
	}
	return b, e
}

func (f *fixture) must(name string, args ...string) []byte {
	f.t.Helper()
	b, e := f.command(name, args...)
	if e != nil {
		f.t.Fatalf("%s %v: %v\n%s", name, args, e, b)
	}
	return b
}

func (f *fixture) queue(args ...string) []byte {
	f.t.Helper()
	return f.must(testBinary, append([]string{"--state", filepath.Join(f.root, "attempt records")}, args...)...)
}

func (f *fixture) queueError(args ...string) {
	f.t.Helper()
	b, e := f.command(testBinary, append([]string{"--state", filepath.Join(f.root, "attempt records")}, args...)...)
	if e == nil {
		f.t.Fatalf("expected rejection: %s", b)
	}
}

func (f *fixture) submit(args ...string) attempt {
	f.t.Helper()
	var a attempt
	if e := json.Unmarshal(f.queue(append([]string{"submit"}, args...)...), &a); e != nil {
		f.t.Fatal(e)
	}
	return a
}

func waitFor(t *testing.T, fn func() bool) {
	t.Helper()
	for i := 0; i < 250; i++ {
		if fn() {
			return
		}
		time.Sleep(40 * time.Millisecond)
	}
	t.Fatal("timed out waiting for queue")
}

func (f *fixture) finished(a attempt) attempt {
	f.t.Helper()
	var result attempt
	waitFor(f.t, func() bool {
		var rows []attempt
		if e := json.Unmarshal(f.queue("status"), &rows); e != nil {
			f.t.Fatal(e)
		}
		for _, r := range rows {
			if r.ID == a.ID {
				result = r
				return state(r.Result) == "Done"
			}
		}
		return false
	})
	return result
}

func fixtureFor(t *testing.T) *fixture {
	t.Helper()
	if testBinary == "" {
		t.Skip("TQ_TESTS=1 enables isolated daemon integration tests")
	}
	root, e := os.MkdirTemp("", "pq-")
	if e != nil {
		t.Fatal(e)
	}
	f := &fixture{t: t, root: root}
	config := filepath.Join(root, "pueue.json")
	settings := map[string]any{
		"shared": map[string]any{
			"pueue_directory":   filepath.Join(root, "data"),
			"runtime_directory": root,
			"unix_socket_path":  filepath.Join(root, "socket"),
		},
	}
	if e = save(config, settings); e != nil {
		t.Fatal(e)
	}
	rc := filepath.Join(root, "taskrc")
	if e = os.WriteFile(rc, []byte("confirmation=off\nnews.version=3.5.0\nuda.repo.type=string\n"), 0600); e != nil {
		t.Fatal(e)
	}
	shell, e := exec.LookPath("bash")
	if e != nil {
		t.Fatal(e)
	}
	socket := filepath.Join(root, "mux.sock")
	muxConfig := filepath.Join(root, "mux.lua")
	if e = os.WriteFile(muxConfig, []byte(fmt.Sprintf("return { unix_domains = { { name = %q, socket_path = %q } }, mux_server_spawn_initial_tab = false }\n", muxDomain, socket)), 0600); e != nil {
		t.Fatal(e)
	}
	f.env = append(
		envWithout("WEZTERM_PANE", "WEZTERM_UNIX_SOCKET", "PUEUE_CONFIG_PATH", "TASKRC", "TASKDATA", "SESHY_CONFIG", "SYSINIT_TERMINAL_PROVIDER"),
		"HOME="+root,
		"XDG_CONFIG_HOME="+filepath.Join(root, "config"),
		"XDG_STATE_HOME="+filepath.Join(root, "state"),
		"PUEUE_CONFIG_PATH="+config,
		"TASKRC="+rc,
		"TASKDATA="+filepath.Join(root, "tasks"),
		"TQ_WEZTERM_SOCKET="+socket,
		"WEZTERM_UNIX_SOCKET="+socket,
		"SHELL="+shell,
		"SYSINIT_TERMINAL_PROVIDER="+weztermManifest(t, root),
	)
	log, e := os.Create(filepath.Join(root, "daemon.log"))
	if e != nil {
		t.Fatal(e)
	}
	mux := exec.Command("wezterm-mux-server", "--config-file", muxConfig)
	mux.Env = f.env
	mux.Stdout = log
	mux.Stderr = log
	if e = mux.Start(); e != nil {
		t.Fatal(e)
	}
	f.daemon = exec.Command("pueued")
	f.daemon.Env = f.env
	f.daemon.Stdout = log
	f.daemon.Stderr = log
	if e = f.daemon.Start(); e != nil {
		t.Fatal(e)
	}
	t.Cleanup(func() {
		if t.Failed() {
			b, _ := f.command("pueue", "log", "--all")
			t.Log(string(b))
		}
		_ = mux.Process.Signal(syscall.SIGTERM)
		_ = mux.Wait()
		_ = f.daemon.Process.Signal(syscall.SIGTERM)
		_ = f.daemon.Wait()
		_ = log.Close()
		_ = os.RemoveAll(root)
	})
	waitFor(t, func() bool {
		_, e := os.Stat(filepath.Join(root, "socket"))
		_, muxErr := os.Stat(socket)
		return e == nil && muxErr == nil
	})
	return f
}

func (f *fixture) task() string {
	description := "synthetic-queue-" + uuid()
	f.must("taskwarrior", "rc.context:none", "add", description, "repo:"+f.root)
	var rows []task
	if e := json.Unmarshal(f.must("taskwarrior", "rc.context:none", "description.is:"+description, "export"), &rows); e != nil || len(rows) != 1 {
		f.t.Fatalf("cannot resolve synthetic task: %v", e)
	}
	return rows[0].UUID
}

func (f *fixture) wezterm(args ...string) []byte {
	return f.must("wezterm", append([]string{"cli", "--prefer-mux", "--no-auto-start"}, args...)...)
}

func (f *fixture) terminalPane(a attempt) (string, bool) {
	var ref terminalRef
	if a.usesSharedTerminal() {
		dir := filepath.Join(f.root, "attempt records")
		path := filepath.Join(dir, a.ID+".terminal")
		if a.TerminalProvider != "" {
			path = providerRefPath(a, dir)
		}
		err := read(path, &ref)
		if errors.Is(err, os.ErrNotExist) {
			return "", false
		}
		if err != nil {
			f.t.Fatal(err)
		}
	}
	var panes []muxPane
	if e := json.Unmarshal(f.wezterm("list", "--format", "json"), &panes); e != nil {
		f.t.Fatal(e)
	}
	for _, p := range panes {
		if p.Workspace == a.Terminal && (!a.usesSharedTerminal() || p.PaneID == ref.PaneID) {
			return strconv.Itoa(p.PaneID), true
		}
	}
	return "", false
}

func weztermManifest(t *testing.T, root string) string {
	t.Helper()
	manifest := filepath.Join(root, "wezterm-provider.json")
	actions := map[string]map[string]string{}
	for _, action := range []string{"terminal.spawn", "terminal.status", "terminal.focus", "terminal.close"} {
		actions[action] = map[string]string{"description": action}
	}
	if err := save(manifest, map[string]any{
		"version": "provider/v1", "name": "wezterm", "description": "Isolated fixture WezTerm",
		"command": []string{testBinary, "wezterm-provider"}, "actions": actions,
	}); err != nil {
		t.Fatal(err)
	}
	return manifest
}

func TestTerminalSubmissionRequiresProvider(t *testing.T) {
	f := fixtureFor(t)
	f.env = append(f.env, "SYSINIT_TERMINAL_PROVIDER=")
	f.queueError("submit", "--terminal", "--", "true")
	if attempts := string(f.queue("status")); strings.TrimSpace(attempts) != "[]" {
		t.Fatalf("submission without a provider created attempts: %s", attempts)
	}
}

func TestTerminalAttemptsShareWorkspaceWithoutSharingLifecycle(t *testing.T) {
	f := fixtureFor(t)
	const workspace = "fixture-queue"
	f.env = append(f.env, "TQ_TERMINAL_WORKSPACE="+workspace)
	f.must("pueue", "group", "add", "agents")
	f.must("pueue", "pause", "--group", "agents")
	f.must("pueue", "parallel", "--group", "agents", "2")
	first := f.submit("--terminal", "--", executable(t, "sleep"), "60")
	second := f.submit("--terminal", "--", executable(t, "sleep"), "60")
	f.must("pueue", "start", "--group", "agents")
	waitFor(t, func() bool { return f.terminalExists(first) && f.terminalExists(second) })
	var panes []struct {
		muxPane
		TabID    int    `json:"tab_id"`
		TabTitle string `json:"tab_title"`
	}
	if err := json.Unmarshal(f.wezterm("list", "--format", "json"), &panes); err != nil {
		t.Fatal(err)
	}
	if len(panes) != 2 || panes[0].Workspace != workspace || panes[1].Workspace != workspace ||
		panes[0].WindowID != panes[1].WindowID || panes[0].TabID == panes[1].TabID {
		t.Fatalf("expected distinct tabs in one queue workspace window: %+v", panes)
	}
	for _, a := range []attempt{first, second} {
		if !strings.Contains(panes[0].TabTitle+" "+panes[1].TabTitle, a.ID[:8]) {
			t.Fatalf("attempt tab title missing for %s: %+v", a.ID, panes)
		}
		if got := string(f.queue("attach", a.ID, "--focus-only")); strings.TrimSpace(got) != strconv.Quote(workspace) {
			t.Fatalf("attach target: %q", got)
		}
	}
	f.queue("cancel", first.ID)
	f.finished(first)
	f.queueError("attach", first.ID, "--focus-only")
	if !f.terminalExists(second) {
		t.Fatal("cancelling the first attempt closed the second tab")
	}
	f.queue("cancel", second.ID)
	f.finished(second)
}

func (f *fixture) terminalExists(a attempt) bool {
	_, ok := f.terminalPane(a)
	return ok
}

func executable(t *testing.T, name string) string {
	t.Helper()
	s, e := exec.LookPath(name)
	if e != nil {
		t.Fatal(e)
	}
	return s
}

func TestCapturedThreadLink(t *testing.T) {
	f := fixtureFor(t)
	bin := filepath.Join(f.root, "bin")
	if err := os.Mkdir(bin, 0700); err != nil {
		t.Fatal(err)
	}
	atuin := "#!/bin/sh\nif [ \"$*\" = 'threads list --style json' ]; then\n  printf '%s' '[{\"atuin_id\":\"captured-thread-a\"}]'\nelse\n  printf '%s\\n' \"$@\"\nfi\n"
	if err := os.WriteFile(filepath.Join(bin, "atuin"), []byte(atuin), 0700); err != nil {
		t.Fatal(err)
	}
	f.env = append(f.env, "PATH="+bin+string(os.PathListSeparator)+os.Getenv("PATH"))
	f.queueError("submit", "--thread", "captured", "--", "true")
	a := f.submit("--thread", "captured-thread-a", "--cwd", f.root, "--", "true")
	if a.Thread != "captured-thread-a" {
		t.Fatalf("lost captured-thread identity: %+v", a)
	}
	if got := strings.TrimSpace(string(f.queue("thread", a.ID))); got != "threads\nshow\ncaptured-thread-a" {
		t.Fatalf("wrong captured conversation: %q", got)
	}
	if got := string(f.queue("browse", "--thread", "unrelated-thread")); got != "" {
		t.Fatalf("empty thread browse emitted structured data: %q", got)
	}
	f.queueError("thread", "../invalid")
}

func TestStatesAndIdentity(t *testing.T) {
	for i := 0; i < 50; i++ {
		if !validID(uuid()) {
			t.Fatal("invalid generated UUID")
		}
	}
	if validID("../../file") {
		t.Fatal("path accepted")
	}
	if success(json.RawMessage(`{"Done":{"result":{"Failed":1}}}`)) {
		t.Fatal("failure reported success")
	}
	if !success(json.RawMessage(`{"Done":{"result":"Success"}}`)) {
		t.Fatal("success lost")
	}
}

func TestJobIdentityDistinguishesReusedNumericID(t *testing.T) {
	original := job{ID: 7, Label: "tq:original", CreatedAt: time.Unix(10, 0)}
	relabelled := original
	relabelled.Label = "tq:replacement"
	recreated := original
	recreated.CreatedAt = original.CreatedAt.Add(time.Second)
	if !original.sameIdentity(original) || original.sameIdentity(relabelled) || original.sameIdentity(recreated) {
		t.Fatal("job identity lost the attempt label or creation time")
	}
}

func TestRetiredAttemptIgnoresReusedPueueID(t *testing.T) {
	first := fixtureFor(t)
	old := first.finished(first.submit("--", executable(t, "sh"), "-c", "printf ORIGINAL"))
	first.queue("reconcile")
	if output := first.queue("logs", old.ID); !bytes.Contains(output, []byte("ORIGINAL")) {
		t.Fatalf("live log output is missing: %q", output)
	}

	second := fixtureFor(t)
	replacement := second.finished(second.submit("--", executable(t, "sh"), "-c", "printf REPLACEMENT; exit 1"))
	if old.ID == replacement.ID || *old.PueueID != *replacement.PueueID {
		t.Fatalf("fixture did not reuse the numeric job ID: %v, %v", old.PueueID, replacement.PueueID)
	}
	oldPath := filepath.Join(second.root, "attempt records", old.ID+".json")
	if err := save(oldPath, old); err != nil {
		t.Fatal(err)
	}
	if view := second.finished(old); !view.Review || !success(view.Result) {
		t.Fatalf("replacement job changed the retired attempt: %+v", view)
	}
	second.queueError("cancel", old.ID)
	second.queueError("resume", old.ID)
	second.queueError("logs", old.ID)
	if output := second.queue("logs", replacement.ID); !bytes.Contains(output, []byte("REPLACEMENT")) {
		t.Fatalf("replacement log output is missing: %q", output)
	}
	if view := second.finished(replacement); view.Cancelled || view.Review {
		t.Fatalf("old attempt controlled the replacement job: %+v", view)
	}
}

func TestSuccessAndExplicitRetry(t *testing.T) {
	f := fixtureFor(t)
	id := f.task()
	a := f.submit("--task", id, "--", executable(t, "true"))
	if !f.finished(a).Review {
		t.Fatal("missing review result")
	}
	f.queueError("submit", "--task", id, "--", executable(t, "true"))
	var rows []task
	_ = json.Unmarshal(f.must("taskwarrior", "rc.context:none", id, "export"), &rows)
	if len(rows) != 1 || rows[0].Status != "pending" {
		t.Fatal("task completion changed")
	}
	b := f.submit("--retry", "--task", id, "--", executable(t, "false"))
	if b.ID == a.ID || f.finished(b).Review {
		t.Fatal("retry did not preserve distinct failure")
	}
	if a.Sequence == 0 || b.Sequence <= a.Sequence || f.finished(b).Sequence != b.Sequence {
		t.Fatal("retry did not preserve durable attempt order")
	}
}

func TestLegacyAttemptUsesMatchingJobCreationTime(t *testing.T) {
	f := fixtureFor(t)
	a := f.finished(f.submit("--", executable(t, "true")))
	a.Sequence = 0
	path := filepath.Join(f.root, "attempt records", a.ID+".json")
	if err := save(path, a); err != nil {
		t.Fatal(err)
	}
	dated := f.finished(a)
	if dated.CreatedAt.IsZero() {
		t.Fatal("snapshot did not recover the legacy attempt's creation time")
	}
	var stored attempt
	if err := read(path, &stored); err != nil || !stored.CreatedAt.IsZero() {
		t.Fatalf("snapshot changed the record: %v, creation time %v", err, stored.CreatedAt)
	}
	f.queue("reconcile")
	f.must("pueue", "remove", strconv.Itoa(*a.PueueID))
	if reconciled := f.finished(a); !reconciled.CreatedAt.Equal(dated.CreatedAt) {
		t.Fatalf("reconciled creation time changed: %v", reconciled.CreatedAt)
	}
}

func TestBlockedAndDependencies(t *testing.T) {
	f := fixtureFor(t)
	dep := f.task()
	id := f.task()
	f.must("taskwarrior", "rc.context:none", id, "modify", "depends:"+dep)
	f.queueError("submit", "--task", id, "--", "true")
	f.must("taskwarrior", "rc.context:none", dep, "done")
	f.must("taskwarrior", "rc.context:none", id, "modify", "+blocked")
	f.queueError("submit", "--task", id, "--", "true")
	f.must("taskwarrior", "rc.context:none", id, "modify", "-blocked")
	a := f.submit("--task", id, "--", executable(t, "true"))
	if !f.finished(a).Review {
		t.Fatal("unblocked task failed")
	}
}

func TestLiteralArgumentsAndMissingDirectory(t *testing.T) {
	f := fixtureFor(t)
	cwd := filepath.Join(f.root, "with spaces")
	_ = os.Mkdir(cwd, 0700)
	value := "$(touch WRONG) 'quoted' ; --detached"
	out := filepath.Join(cwd, "literal")
	a := f.submit("--cwd", cwd, "--", executable(t, "bash"), "-c", `printf '%s' "$1" > literal`, "bash", value)
	if !f.finished(a).Review {
		t.Fatal("literal command failed")
	}
	b, e := os.ReadFile(out)
	if e != nil || string(b) != value {
		t.Fatalf("argv changed: %q %v", b, e)
	}
	f.queueError("submit", "--cwd", filepath.Join(cwd, "missing"), "--", "true")
}

func TestTerminalInputAndFailure(t *testing.T) {
	f := fixtureFor(t)
	ready := filepath.Join(f.root, "input-ready")
	f.env = append(f.env, "TQ_TEST_QUEUE_CANARY=queue-only", "TASKRC="+filepath.Join(f.root, "custom-taskrc"))
	a := f.submit("--terminal", "--", executable(t, "bash"), "-c", `
		if test -n "${TQ_TEST_QUEUE_CANARY+x}"; then
			printf 'queue-only variable reached the terminal' > "$1"
		elif test "$TASKRC" != "$2"; then
			printf 'terminal did not receive the attempt override' > "$1"
		else
			printf ready > "$1"
		fi
		read -r value </dev/tty; test "$value" = hello || exit 8; exit 7
	`, "bash", ready, filepath.Join(f.root, "custom-taskrc"))
	waitFor(t, func() bool {
		_, err := os.Stat(ready)
		return err == nil && f.terminalExists(a)
	})
	if value, err := os.ReadFile(ready); err != nil || string(value) != "ready" {
		t.Fatalf("terminal environment: %s (%v)", value, err)
	}
	pane, _ := f.terminalPane(a)
	f.wezterm("send-text", "--pane-id", pane, "--no-paste", "hello\r")
	r := f.finished(a)
	if !strings.Contains(string(r.Result), `"Failed":7`) && !strings.Contains(string(r.Result), `"Failed": 7`) {
		t.Fatalf("wrong exit: %s", r.Result)
	}
	if !f.terminalExists(a) {
		t.Fatal("finished session disappeared")
	}
}

func TestFailedTerminalSpawnDoesNotWriteEnvironment(t *testing.T) {
	f := fixtureFor(t)
	dir := filepath.Join(f.root, "attempt records")
	if err := os.Mkdir(dir, 0700); err != nil {
		t.Fatal(err)
	}
	a := attempt{ID: uuid(), Cwd: f.root, Argv: []string{"true"}, Terminal: "failure"}
	if err := save(filepath.Join(dir, a.ID+".json"), a); err != nil {
		t.Fatal(err)
	}
	f.env = append(f.env, "TQ_WEZTERM_SOCKET="+filepath.Join(f.root, "no-server.sock"), "TQ_TEST_QUEUE_CANARY=fixture-only")
	out, err := f.command(testBinary, "--state", dir, "run", a.ID)
	if err == nil || !bytes.Contains(out, []byte("terminal spawn failed")) {
		t.Fatalf("expected spawn failure: %v\n%s", err, out)
	}
	if paths, err := filepath.Glob(filepath.Join(dir, "*.environment*")); err != nil || len(paths) != 0 {
		t.Fatalf("terminal spawn left an environment file: %v, %v", paths, err)
	}
}

func TestLostTerminalCannotSucceed(t *testing.T) {
	f := fixtureFor(t)
	a := f.submit("--terminal", "--", executable(t, "sleep"), "60")
	waitFor(t, func() bool { return f.terminalExists(a) })
	pane, _ := f.terminalPane(a)
	f.wezterm("kill-pane", "--pane-id", pane)
	if f.finished(a).Review {
		t.Fatal("lost terminal succeeded")
	}
}

func TestQueueCancel(t *testing.T) {
	f := fixtureFor(t)
	a := f.submit("--terminal", "--", executable(t, "sleep"), "60")
	waitFor(t, func() bool { return f.terminalExists(a) })
	f.queue("cancel", a.ID)
	if f.finished(a).Review || f.terminalExists(a) {
		t.Fatal("cancel failed")
	}
}

func TestNativeKillAndPause(t *testing.T) {
	f := fixtureFor(t)
	ticks := filepath.Join(f.root, "ticks")
	pidfile := filepath.Join(f.root, "pid")
	a := f.submit("--terminal", "--", executable(t, "bash"), "-c", `echo $$ > "$1"; n=0; while true; do echo "$n" > "$2"; n=$((n+1)); sleep .05; done`, "bash", pidfile, ticks)
	waitFor(t, func() bool {
		_, e := os.Stat(ticks)
		return e == nil
	})
	f.must("pueue", "pause", strconv.Itoa(*a.PueueID))
	time.Sleep(600 * time.Millisecond)
	before, _ := os.ReadFile(ticks)
	time.Sleep(300 * time.Millisecond)
	after, _ := os.ReadFile(ticks)
	if string(before) != string(after) {
		t.Fatal("terminal ignored pause")
	}
	f.must("pueue", "start", strconv.Itoa(*a.PueueID))
	waitFor(t, func() bool {
		b, _ := os.ReadFile(ticks)
		return string(b) != string(before)
	})
	p, _ := os.ReadFile(pidfile)
	pid, _ := strconv.Atoi(strings.TrimSpace(string(p)))
	f.must("pueue", "kill", strconv.Itoa(*a.PueueID))
	waitFor(t, func() bool { return syscall.Kill(pid, 0) == syscall.ESRCH })
	if f.finished(a).Review {
		t.Fatal("killed task succeeded")
	}
}

func TestStatusProjectsWithoutPersisting(t *testing.T) {
	f := fixtureFor(t)
	f.must("pueue", "group", "add", "agents")
	f.must("pueue", "pause", "--group", "agents")
	a := f.submit("--", "true")
	path, err := recordPath(filepath.Join(f.root, "attempt records"), a.ID)
	if err != nil {
		t.Fatal(err)
	}
	before, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	f.must("pueue", "stash", strconv.Itoa(*a.PueueID))
	status := f.queue("status")
	if !bytes.Equal(status, f.queue("snapshot")) {
		t.Fatal("status and snapshot disagree")
	}
	var records []attempt
	if err := json.Unmarshal(status, &records); err != nil {
		t.Fatal(err)
	}
	if len(records) != 1 || state(records[0].Result) != "Stashed" {
		t.Fatalf("status did not project the live job: %s", status)
	}
	after, err := os.ReadFile(path)
	if err != nil || !bytes.Equal(before, after) {
		t.Fatalf("inspecting the queue rewrote the attempt: %v", err)
	}
	f.queueError("submit", "--cwd", filepath.Join(f.root, "missing directory"), "--", "true")
	after, err = os.ReadFile(path)
	if err != nil || !bytes.Equal(before, after) {
		t.Fatalf("rejected submission rewrote an unrelated attempt: %v", err)
	}

	f.submit("--", "true")
	after, err = os.ReadFile(path)
	if err != nil || !bytes.Equal(before, after) {
		t.Fatalf("new submission rewrote an unrelated attempt: %v", err)
	}

	f.queue("reconcile")
	var persisted attempt
	if err := read(path, &persisted); err != nil || state(persisted.Result) != "Stashed" {
		t.Fatalf("reconcile did not persist the live job: %v", err)
	}
}

func TestRecoverStashedAndRejectReplay(t *testing.T) {
	f := fixtureFor(t)
	f.must("pueue", "group", "add", "agents")
	f.must("pueue", "pause", "--group", "agents")
	a := f.submit("--", "true")
	f.must("pueue", "stash", strconv.Itoa(*a.PueueID))
	f.queue("resume", a.ID)
	f.must("pueue", "start", "--group", "agents")
	if !f.finished(a).Review {
		t.Fatal("resume failed")
	}
	f.must("pueue", "restart", "--in-place", strconv.Itoa(*a.PueueID))
	if f.finished(a).Review {
		t.Fatal("replayed attempt accepted")
	}
}

func TestAbandonMissingAttemptAllowsRetry(t *testing.T) {
	f := fixtureFor(t)
	id := f.task()
	f.must("pueue", "group", "add", "agents")
	f.must("pueue", "pause", "--group", "agents")
	a := f.submit("--task", id, "--", "true")
	f.queueError("abandon", a.ID)
	f.must("pueue", "remove", strconv.Itoa(*a.PueueID))

	f.queueError("resume", a.ID)
	f.queueError("cancel", a.ID)
	f.queueError("submit", "--retry", "--task", id, "--", "true")
	f.queue("abandon", a.ID)
	retry := f.submit("--retry", "--task", id, "--", "true")
	if retry.ID == a.ID {
		t.Fatal("retry reused the abandoned attempt")
	}
	path, err := recordPath(filepath.Join(f.root, "attempt records"), a.ID)
	if err != nil {
		t.Fatal(err)
	}
	var retired attempt
	if err := read(path, &retired); err != nil || !retired.Cancelled || state(retired.Result) != "Missing" {
		t.Fatalf("missing attempt record was not preserved: %+v, %v", retired, err)
	}
}

func TestSeshyPlan(t *testing.T) {
	f := fixtureFor(t)
	config := filepath.Join(f.root, "seshy.json")
	_ = save(config, map[string]any{"sessionsDir": filepath.Join(f.root, "sessions"), "hooks": map[string]any{"postCreate": []string{}}})
	f.env = append(f.env, "SESHY_CONFIG="+config)
	f.must("sy", "new", "queue-fixture", "--empty")
	var plan struct {
		Cwd string `json:"cwd"`
	}
	_ = json.Unmarshal(f.must("sy", "open", "queue-fixture", "--format", "json"), &plan)
	a := f.submit("--session", "queue-fixture", "--", executable(t, "bash"), "-c", `printf '%s' "$SESHY_SESSION" > session-env`)
	if !f.finished(a).Review {
		t.Fatal("session failed")
	}
	b, e := os.ReadFile(filepath.Join(plan.Cwd, "session-env"))
	if e != nil || string(b) != "queue-fixture" {
		t.Fatalf("wrong session env: %q %v", b, e)
	}
}

func TestTaskRevalidatedAtStart(t *testing.T) {
	f := fixtureFor(t)
	id := f.task()
	f.must("pueue", "group", "add", "agents")
	f.must("pueue", "pause", "--group", "agents")
	a := f.submit("--task", id, "--", "true")
	f.must("taskwarrior", "rc.context:none", id, "modify", "+blocked")
	f.must("pueue", "start", "--group", "agents")
	if f.finished(a).Review {
		t.Fatal("task validation was stale")
	}
}

func TestWorkingDirectoryExclusion(t *testing.T) {
	f := fixtureFor(t)
	one := f.task()
	two := f.task()
	marker := filepath.Join(f.root, "running")
	a := f.submit("--task", one, "--", executable(t, "bash"), "-c", fmt.Sprintf("touch %s; sleep 60", shellQuote(marker)))
	waitFor(t, func() bool {
		_, e := os.Stat(marker)
		return e == nil
	})
	f.must("pueue", "parallel", "2", "--group", "agents")
	b := f.submit("--task", two, "--", "true")
	if f.finished(b).Review {
		t.Fatal("concurrent task edited busy directory")
	}
	f.queue("cancel", a.ID)
}

func TestDaemonLossStopsTerminalCommand(t *testing.T) {
	f := fixtureFor(t)
	marker := filepath.Join(f.root, "pid")
	f.submit("--terminal", "--", executable(t, "bash"), "-c", `echo $$ > "$1"; sleep 60`, "bash", marker)
	waitFor(t, func() bool {
		_, e := os.Stat(marker)
		return e == nil
	})
	b, _ := os.ReadFile(marker)
	pid, _ := strconv.Atoi(strings.TrimSpace(string(b)))
	if e := f.daemon.Process.Kill(); e != nil {
		t.Fatal(e)
	}
	waitFor(t, func() bool { return syscall.Kill(pid, 0) == syscall.ESRCH })
}

func TestQueuedAttemptSurvivesDaemonRestart(t *testing.T) {
	f := fixtureFor(t)
	f.must("pueue", "group", "add", "agents")
	f.must("pueue", "pause", "--group", "agents")
	a := f.submit("--", "true")
	if e := f.daemon.Process.Signal(syscall.SIGTERM); e != nil {
		t.Fatal(e)
	}
	_ = f.daemon.Wait()
	replacement := exec.Command("pueued")
	replacement.Env = f.env
	replacement.Stdout = f.daemon.Stdout
	replacement.Stderr = f.daemon.Stderr
	f.daemon = replacement
	if e := f.daemon.Start(); e != nil {
		t.Fatal(e)
	}
	waitFor(t, func() bool {
		_, e := f.command("pueue", "status", "--json")
		return e == nil
	})
	f.queue("reconcile")
	f.must("pueue", "start", "--group", "agents")
	if !f.finished(a).Review {
		t.Fatal("queued work did not survive daemon restart")
	}
}
