package ui

import "testing"

// Eight rows of one run read "R=/Users/roshan/github/persona…" and the eight
// commands under that prefix were invisible. These are the shapes that caused it.
func TestTrimLead(t *testing.T) {
	for _, one := range []struct{ in, want string }{
		{"R=/repo; cd $R && go build ./...", "go build ./..."},
		// An assignment and a cd in front of one command: both are prefix.
		{"R=/repo cd /x && ls", "ls"},
		{"cd /repo && git status", "git status"},
		{"cd /repo; git status", "git status"},
		{"A=1 B=2 make test", "make test"},
		// Nothing to strip: the command has to survive whole.
		{"go build ./...", "go build ./..."},
		{"git diff --stat", "git diff --stat"},
		// A cd with nothing after it is the whole point of the row.
		{"cd /repo", "cd /repo"},
		// Not an assignment: an equals inside an argument must not be eaten.
		{"grep -n a=b file", "grep -n a=b file"},
		{"ast-grep --pattern 'x = $Y' .", "ast-grep --pattern 'x = $Y' ."},
		{"", ""},
	} {
		if got := trimLead(one.in); got != one.want {
			t.Errorf("trimLead(%q) = %q, want %q", one.in, got, one.want)
		}
	}
}
