package pane

import (
	"strings"
	"testing"
)

func TestDelta(t *testing.T) {
	for _, one := range []struct {
		name string
		prev []string
		now  []string
		want []string
	}{
		{
			name: "a clean append",
			prev: []string{"❯ ls", "a.go", "❯ cargo build"},
			now:  []string{"❯ ls", "a.go", "❯ cargo build", "error: no", "❯ ask --last"},
			want: []string{"error: no", "❯ ask --last"},
		},
		{
			name: "no earlier snapshot",
			prev: nil,
			now:  []string{"a", "b"},
			want: []string{"a", "b"},
		},
		{
			name: "the scrollback rolled past the prefix",
			prev: []string{"old", "❯ cargo build"},
			now:  []string{"different", "❯ cargo build", "error: no"},
			want: []string{"error: no"},
		},
		{
			name: "nothing was printed",
			prev: []string{"a", "b"},
			now:  []string{"a", "b"},
			want: []string{},
		},
	} {
		t.Run(one.name, func(t *testing.T) {
			got := Delta(one.prev, one.now)
			if strings.Join(got, "\n") != strings.Join(one.want, "\n") {
				t.Fatalf("got %q, want %q", got, one.want)
			}
		})
	}
}

func TestLinesDropsTrailingBlanks(t *testing.T) {
	got := lines([]byte("a\r\nb\n\n   \n"))
	if strings.Join(got, "|") != "a|b" {
		t.Fatalf("got %q", got)
	}
}

func TestTrimKeepsTheTail(t *testing.T) {
	long := strings.Repeat("noise\n", widest/2)
	kept := string(trim([]byte(long + "the last line")))
	if !strings.HasSuffix(kept, "the last line") {
		t.Fatal("the end of the output is what says why a command failed")
	}
	if !strings.HasPrefix(kept, "[earlier output cut]") {
		t.Fatal("a cut should say it happened")
	}
	if len(kept) > widest+64 {
		t.Fatalf("kept %d bytes, over the %d cap", len(kept), widest)
	}
}
