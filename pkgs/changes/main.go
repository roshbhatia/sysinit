// changes prints a diff the way a reviewer reads one: an eza shaped tree of
// the touched files, each file's hunks grouped under the outline symbol that
// owns them, and each symbol annotated with the call edges the edit added or
// removed. It is the same renderer reel draws in its inspector, over git
// instead of over a trace.
package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"golang.org/x/term"

	"github.com/roshbhatia/sysinit/pkgs/changes/internal/source"
	"github.com/roshbhatia/sysinit/pkgs/internal/diffview"
)

const usage = `changes [flags] [<from> [<to>]] [-- <path>...]

  Refs follow git diff: none is HEAD against the working tree, one is that ref
  against the working tree, two compare the trees. A from of the form a..b is
  split into two refs.

Flags:
`

func main() {
	staged := flag.Bool("staged", false, "compare the index rather than the working tree")
	watch := flag.Bool("watch", false, "reprint whenever the diff changes")
	flag.BoolVar(watch, "w", false, "shorthand for -watch")
	every := flag.Duration("interval", 700*time.Millisecond, "how often -watch re-reads the diff")
	width := flag.Int("width", 0, "render at this width (default: the terminal's)")
	noCalls := flag.Bool("no-calls", false, "skip calldiff, which is the slow layer")
	noSyms := flag.Bool("no-symbols", false, "skip the ast-grep outline layer")
	budget := flag.Duration("budget", 20*time.Second, "how long the outline and call layers may take")
	flag.Usage = func() {
		fmt.Fprint(flag.CommandLine.Output(), usage)
		flag.PrintDefaults()
	}
	flag.Parse()

	dir, err := os.Getwd()
	if err != nil {
		fail(err)
	}
	root, err := source.Root(dir)
	if err != nil {
		fail(err)
	}
	from, to, paths := split(root, flag.Args())
	// git resolves a pathspec against the process cwd, and every command here
	// runs at the repository root, so a relative path from a subdirectory would
	// silently match nothing.
	for i, p := range paths {
		if abs, err := filepath.Abs(filepath.Join(dir, p)); err == nil {
			paths[i] = abs
		}
	}

	view := renderer{
		spec: source.Spec{
			Dir:    root,
			From:   from,
			To:     to,
			Staged: *staged,
			Paths:  paths,
		},
		width:  *width,
		syms:   !*noSyms,
		calls:  !*noCalls,
		budget: *budget,
	}

	if !*watch {
		out, err := view.render()
		if err != nil {
			fail(err)
		}
		if out == "" {
			fmt.Fprintln(os.Stderr, "changes: nothing changed")
			return
		}
		fmt.Println(out)
		return
	}
	fail(view.follow(*every))
}

// split reads the git shaped positional arguments. flag.Parse consumes the --
// separator, so the refs and the paths arrive in one list and the first
// argument git does not know as a tree starts the paths.
func split(root string, args []string) (from, to string, paths []string) {
	refs := args
	for i, a := range args {
		if a == "--" {
			refs, paths = args[:i], args[i+1:]
			break
		}
	}
	if len(refs) > 0 {
		if a, b, ok := strings.Cut(refs[0], ".."); ok {
			return a, b, append(refs[1:], paths...)
		}
	}
	for i, a := range refs {
		if !source.IsRev(root, a) {
			// An argument that is neither a tree nor a path is a typo, and
			// read as a pathspec it matches nothing and prints "nothing
			// changed", which reads as a clean tree.
			if _, err := os.Stat(a); err != nil {
				fail(fmt.Errorf("%s is not a revision or a path", a))
			}
			return from, to, append(refs[i:], paths...)
		}
		switch i {
		case 0:
			from = a
		case 1:
			to = a
		default:
			// git takes two trees and no more, so a third would silently
			// change which comparison ran.
			fail(fmt.Errorf("too many revisions: %s", strings.Join(refs, " ")))
		}
	}
	return from, to, paths
}

type renderer struct {
	spec   source.Spec
	width  int
	syms   bool
	calls  bool
	budget time.Duration
}

func (r renderer) render() (string, error) {
	patch, err := r.spec.Diff()
	if err != nil {
		return "", err
	}
	return r.draw(patch), nil
}

func (r renderer) draw(patch string) string {
	files := diffview.Parse(patch)
	if len(files) == 0 {
		return ""
	}
	touched := make([]string, 0, len(files))
	for _, f := range files {
		touched = append(touched, f.Path)
	}
	sort.Strings(touched)

	opts := diffview.Options{Files: files, Width: r.columns()}
	if r.syms {
		dir, kept, done := r.spec.Tree(touched)
		defer done()
		opts.Symbols = source.Outline(dir, kept, r.budget)
	}
	if r.calls {
		opts.Edges = source.Calls(r.spec.Dir, r.spec.From, r.spec.To, touched, r.budget)
	}
	return diffview.Render(opts)
}

// The renderer pads every row to the width it is given, so a width taken from
// a pipe would print a wall of trailing spaces. 100 is the width the side by
// side view was tuned against.
func (r renderer) columns() int {
	if r.width > 0 {
		return r.width
	}
	if w, _, err := term.GetSize(int(os.Stdout.Fd())); err == nil && w > 0 {
		return w
	}
	return 100
}

// follow reprints on change rather than on a timer, because a diff that has
// not moved redraws to the same bytes and the flicker says nothing. The raw
// patch is the change detector: it is what every layer is derived from.
func (r renderer) follow(every time.Duration) error {
	last := ""
	for {
		patch, err := r.spec.Diff()
		if err != nil {
			return err
		}
		if patch != last {
			last = patch
			out := r.draw(patch)
			if out == "" {
				out = "changes: nothing changed"
			}
			// Home the cursor and clear forward, so the frame lands in the
			// scrollback the reader already has rather than in an alt screen
			// they cannot scroll.
			fmt.Print("\x1b[H\x1b[2J", out, "\n")
		}
		time.Sleep(every)
	}
}

func fail(err error) {
	if err == nil {
		return
	}
	fmt.Fprintf(os.Stderr, "changes: %v\n", err)
	os.Exit(1)
}
