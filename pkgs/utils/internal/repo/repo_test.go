package repo

import "testing"

func TestWorkerKeyed(t *testing.T) {
	for _, name := range []string{"repo-0123456789abcdef", "nested-name-abcdef0123456789"} {
		if !WorkerKeyed(name) {
			t.Fatalf("WorkerKeyed rejected %q", name)
		}
	}
	for _, name := range []string{"repo", "repo-0123", "repo-0123456789abcdeg", "-0123456789abcdef"} {
		if WorkerKeyed(name) {
			t.Fatalf("WorkerKeyed accepted %q", name)
		}
	}
}
