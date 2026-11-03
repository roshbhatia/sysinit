package main

import (
	"bytes"
	"encoding/json"
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

func TestMain(m *testing.M) {
	if os.Getenv("TASK_QUEUE_TESTS") == "1" {
		root, e := os.MkdirTemp("", "queue-test-bin-")
		if e != nil {
			panic(e)
		}
		testBinary = filepath.Join(root, "task-queue")
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
		t.Skip("TASK_QUEUE_TESTS=1 enables isolated daemon integration tests")
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
	f.env = append(
		envWithout("ZMX_SESSION", "ZMX_SESSION_PREFIX", "PUEUE_CONFIG_PATH", "TASKRC", "TASKDATA", "SESHY_CONFIG"),
		"PUEUE_CONFIG_PATH="+config,
		"TASKRC="+rc,
		"TASKDATA="+filepath.Join(root, "tasks"),
		"ZMX_DIR="+filepath.Join(root, "z"),
		"ZMX_SESSION_PREFIX=",
		"SHELL="+shell,
	)
	log, e := os.Create(filepath.Join(root, "daemon.log"))
	if e != nil {
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
		b, _ := f.command("zmx", "list", "--short")
		for _, name := range strings.Fields(string(b)) {
			_, _ = f.command("zmx", "kill", name, "--force")
		}
		_ = f.daemon.Process.Signal(syscall.SIGTERM)
		_ = f.daemon.Wait()
		_ = log.Close()
		_ = os.RemoveAll(root)
	})
	waitFor(t, func() bool {
		_, e := os.Stat(filepath.Join(root, "socket"))
		return e == nil
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

func (f *fixture) terminalExists(a attempt) bool {
	b, _ := f.command("zmx", "list", "--short")
	return strings.Contains(string(b), a.Terminal)
}

func executable(t *testing.T, name string) string {
	t.Helper()
	s, e := exec.LookPath(name)
	if e != nil {
		t.Fatal(e)
	}
	return s
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
	a := f.submit("--terminal", "--", executable(t, "bash"), "-c", `read -r value </dev/tty; test "$value" = hello || exit 8; exit 7`)
	waitFor(t, func() bool { return f.terminalExists(a) })
	time.Sleep(300 * time.Millisecond)
	f.must("zmx", "send", a.Terminal, "hello\r")
	r := f.finished(a)
	if !strings.Contains(string(r.Result), `"Failed":7`) && !strings.Contains(string(r.Result), `"Failed": 7`) {
		t.Fatalf("wrong exit: %s", r.Result)
	}
	if !f.terminalExists(a) {
		t.Fatal("finished session disappeared")
	}
}

func TestLostTerminalCannotSucceed(t *testing.T) {
	f := fixtureFor(t)
	a := f.submit("--terminal", "--", executable(t, "sleep"), "60")
	waitFor(t, func() bool { return f.terminalExists(a) })
	f.must("zmx", "kill", a.Terminal, "--force")
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

func TestRecoverStashedAndRejectReplay(t *testing.T) {
	f := fixtureFor(t)
	f.must("pueue", "group", "add", "agents")
	f.must("pueue", "pause", "--group", "agents")
	a := f.submit("--", "true")
	f.must("pueue", "stash", strconv.Itoa(*a.PueueID))
	f.queue("reconcile")
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
