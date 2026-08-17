package guard

import (
	"strings"
	"testing"
)

func TestBoundCommandWrapsAnUnboundedCommand(t *testing.T) {
	for _, command := range []string{
		"cat /etc/hosts",
		"rg TODO .",
		"find . -name '*.go'",
		"git log --oneline",
		"tree /nix/store",
	} {
		bounded, ok := boundCommand(command)
		if !ok {
			t.Fatalf("%q should be bounded", command)
		}
		if !strings.Contains(bounded, command) {
			t.Fatalf("the rewrite of %q must keep the original, got %q", command, bounded)
		}
		if !strings.Contains(bounded, "set -o pipefail") {
			t.Fatalf("the rewrite of %q must keep the exit status, got %q", command, bounded)
		}
		if !strings.Contains(bounded, "head -c 16384") {
			t.Fatalf("the rewrite of %q must carry the budget, got %q", command, bounded)
		}
		if !strings.Contains(bounded, "cat >/dev/null") {
			t.Fatalf("the rewrite of %q must drain the pipe, got %q", command, bounded)
		}
	}
}

func TestBoundCommandLeavesComposedCommandsAlone(t *testing.T) {
	for _, command := range []string{
		"cat /etc/hosts | head -20",
		"rg TODO . > out.txt",
		"cat a && cat b",
		"find . -name x -exec rm {} +",
		"echo hi",
		"git status",
		"cat",
		"",
	} {
		if bounded, ok := boundCommand(command); ok {
			t.Fatalf("%q must not be rewritten, got %q", command, bounded)
		}
	}
}

func TestBoundCommandRespectsALimitTheCallerChose(t *testing.T) {
	for _, command := range []string{
		"rg TODO . -m 5",
		"rg TODO . --max-count=5",
		"git log -5",
		"git log -n 20",
		"rg TODO . -m5",
	} {
		if bounded, ok := boundCommand(command); ok {
			t.Fatalf("%q already has a limit, got %q", command, bounded)
		}
	}
}

// find's -name starts with -n. An earlier prefix match exempted every find that
// used it, which is nearly all of them.
func TestFindNameIsNotALimit(t *testing.T) {
	if alreadyBounded([]string{".", "-name", "*.go"}) {
		t.Fatal("-name is not a limit")
	}
	if alreadyBounded([]string{"-maxdepth", "2"}) {
		t.Fatal("-maxdepth is not a limit")
	}
}
