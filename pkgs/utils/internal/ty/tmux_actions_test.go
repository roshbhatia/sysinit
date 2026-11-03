package ty

import (
	"os"
	"os/exec"
	"reflect"
	"testing"
)

func TestProcessArgvPreservesArguments(t *testing.T) {
	child := exec.Command("/bin/sh", "-c", "sleep 10", "argument with spaces", "literal ' quote")
	if err := child.Start(); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = child.Process.Kill(); _ = child.Wait() })
	args, err := processArgv(child.Process.Pid)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(args[1:], child.Args[1:]) {
		t.Fatalf("argv=%q want=%q", args, child.Args)
	}
}

func TestRemoteSpawnRetainsConnectionWithoutReplayingCommand(t *testing.T) {
	argv := []string{"/bin/ssh", "-p", "2222", "-i", "/key with spaces", "-L", "8080:localhost:80", "-o", "ProxyJump=relay", "-t", "user@host", "dangerous remote command"}
	got, err := remoteCommand(argv)
	want := []string{"ssh", "-o", "ClearAllForwardings=yes", "-o", "RemoteCommand=none", "-p", "2222", "-i", "/key with spaces", "-o", "ProxyJump=relay", "user@host"}
	if err != nil || !reflect.DeepEqual(got, want) {
		t.Fatalf("command=%q err=%v", got, err)
	}
	wrapped, err := remoteProcess(foregroundProcess{Argv: []string{"zsh"}, Children: []foregroundProcess{{Argv: argv}}})
	if err != nil || !reflect.DeepEqual(wrapped, want) {
		t.Fatalf("wrapped SSH=%q err=%v", wrapped, err)
	}
	if _, err := remoteCommand([]string{"ssh", "-p"}); err == nil {
		t.Fatal("missing SSH option value accepted")
	}
	if _, err := remoteCommand([]string{"mosh-client", "127.0.0.1", "60000"}); err == nil {
		t.Fatal("ambiguous Mosh title accepted")
	}
	got, err = remoteCommand([]string{"mosh-client", "-# user@host |"})
	if err != nil || !reflect.DeepEqual(got, []string{"mosh", "user@host"}) {
		t.Fatalf("mosh=%q err=%v", got, err)
	}
	got, err = remoteCommand([]string{os.Getenv("SHELL")})
	if err != nil || got != nil {
		t.Fatalf("local shell treated as remote: %q %v", got, err)
	}
}
