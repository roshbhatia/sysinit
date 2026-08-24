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
	"sync"
	"time"

	"golang.org/x/term"

	"github.com/roshbhatia/sysinit/pkgs/changes/internal/source"
	"github.com/roshbhatia/sysinit/pkgs/internal/diffview"
	"github.com/roshbhatia/sysinit/pkgs/internal/workspace"
)

const usage = `changes [flags] [<from> [<to>]] [-- <path>...]

  Refs follow git diff: none is HEAD against the working tree, one is that ref
  against the working tree, two compare the trees. A from of the form a..b is
  split into two refs.

  -r reads every repository under the workspace, which is $SYSINIT_WORKSPACE
  when the working directory sits inside it, then the git top level, then the
  working directory. Each repository's files hang under its own name.

Flags:
`

func main() {
	staged := flag.Bool("staged", false, "compare the index rather than the working tree")
	since := flag.String("since", "", "compare against the tree as of a time or a revision, e.g. \"2 hours ago\" or HEAD~3")
	watch := flag.Bool("watch", false, "reprint whenever the diff changes")
	flag.BoolVar(watch, "w", false, "shorthand for -watch")
	every := flag.Duration("interval", 700*time.Millisecond, "how often -watch re-reads the diff")
	width := flag.Int("width", 0, "render at this width (default: the terminal's)")
	noCalls := flag.Bool("no-calls", false, "skip calldiff, which is the slow layer")
	noSyms := flag.Bool("no-symbols", false, "skip the ast-grep outline layer")
	budget := flag.Duration("budget", 20*time.Second, "how long the outline and call layers may take")
	recurse := flag.Bool("recursive", false, "read every repository under the workspace")
	flag.BoolVar(recurse, "r", false, "shorthand for -recursive")
	scan := flag.String("root", "", "scan from here with -r, instead of the workspace")
	stat := flag.Bool("stat", false, "draw the tree and the churn, without the hunks")
	flag.BoolVar(stat, "s", false, "shorthand for -stat")
	flag.Usage = func() {
		fmt.Fprint(flag.CommandLine.Output(), usage)
		flag.PrintDefaults()
	}
	flag.Parse()

	dir, err := os.Getwd()
	if err != nil {
		fail(err)
	}
	if *scan != "" {
		dir = *scan
	}

	roots := []string{}
	if *recurse {
		roots, err = workspace.Roots(dir)
		if err != nil {
			fail(err)
		}
		if len(roots) == 0 {
			fail(fmt.Errorf("no git repository under %s", workspace.Root(dir)))
		}
	} else {
		one, err := source.Root(dir)
		if err != nil {
			fail(err)
		}
		roots = []string{one}
	}
	// Every positional is read against the first repository, because a ref has
	// to mean one thing across the whole render.
	root := roots[0]
	from, to, paths := split(root, flag.Args())
	if *since != "" {
		if from != "" {
			fail(fmt.Errorf("-since and a revision argument both name the left side"))
		}
		from = source.Revision(root, *since)
		if from == "" {
			fail(fmt.Errorf("-since %q resolves to no commit before HEAD: it is not a revision, and git read it as now", *since))
		}
	}
	// git resolves a pathspec against the process cwd, and every command here
	// runs at the repository root, so a relative path from a subdirectory would
	// silently match nothing.
	for i, p := range paths {
		if abs, err := filepath.Abs(filepath.Join(dir, p)); err == nil {
			paths[i] = abs
		}
	}

	specs := make([]source.Spec, 0, len(roots))
	for _, one := range roots {
		specs = append(specs, source.Spec{
			Dir:    one,
			From:   from,
			To:     to,
			Staged: *staged,
			Paths:  paths,
		})
	}
	view := renderer{
		specs:  specs,
		under:  workspace.Root(dir),
		named:  *recurse,
		stat:   *stat,
		width:  *width,
		syms:   !*noSyms && !*stat,
		calls:  !*noCalls && !*stat,
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
	specs  []source.Spec
	under  string
	named  bool
	stat   bool
	width  int
	syms   bool
	calls  bool
	budget time.Duration
}

func (r renderer) render() (string, error) {
	patches, err := r.patches()
	if err != nil {
		return "", err
	}
	return r.draw(patches), nil
}

// patches reads one repository per spec, concurrently, because git is the cheap
// layer and a workspace holds a handful of repositories.
//
// A revision one repository does not carry is normal across a workspace, so
// that repository is named on stderr and left out rather than failing the whole
// render. A single repository still fails, because there is nothing left to
// draw.
func (r renderer) patches() ([]string, error) {
	out, errs := make([]string, len(r.specs)), make([]error, len(r.specs))
	var wg sync.WaitGroup
	for i, spec := range r.specs {
		wg.Add(1)
		go func() {
			defer wg.Done()
			out[i], errs[i] = spec.Diff()
		}()
	}
	wg.Wait()
	for i, err := range errs {
		if err == nil {
			continue
		}
		if len(r.specs) == 1 {
			return nil, err
		}
		fmt.Fprintf(os.Stderr, "changes: skipped %s: %v\n", r.specs[i].Dir, err)
	}
	return out, nil
}

// draw folds every repository into one tree. Each file keeps the path its own
// repository reported, prefixed with the repository's place under the
// workspace, so two repositories holding the same file name stay apart and the
// symbol and call layers keep their keys.
func (r renderer) draw(patches []string) string {
	opts := diffview.Options{
		Width:   r.columns(),
		Symbols: map[string][]diffview.Symbol{},
		Edges:   map[string][]diffview.Edge{},
		Pins:    map[string]bool{},
		Stat:    r.stat,
	}
	for i, patch := range patches {
		files := diffview.Parse(patch)
		if len(files) == 0 {
			continue
		}
		spec := r.specs[i]
		under := r.prefix(spec.Dir)
		if under != "" {
			opts.Pins[strings.TrimSuffix(under, "/")] = true
		}
		syms, edges := r.layers(spec, files)
		for j := range files {
			at := under + files[j].Path
			opts.Symbols[at] = syms[files[j].Path]
			opts.Edges[at] = edges[files[j].Path]
			files[j].Path = at
			opts.Files = append(opts.Files, files[j])
		}
	}
	return diffview.Render(opts)
}

// One repository renders under its own paths, so a single repository reads
// exactly as it did before -r existed.
func (r renderer) prefix(dir string) string {
	if !r.named {
		return ""
	}
	rel, err := filepath.Rel(r.under, dir)
	if err != nil || rel == "." {
		return filepath.Base(dir) + "/"
	}
	return rel + "/"
}

func (r renderer) layers(spec source.Spec, files []diffview.File) (map[string][]diffview.Symbol, map[string][]diffview.Edge) {
	touched := make([]string, 0, len(files))
	for _, f := range files {
		touched = append(touched, f.Path)
	}
	sort.Strings(touched)

	syms := map[string][]diffview.Symbol{}
	if r.syms {
		dir, kept, done := spec.Tree(touched)
		defer done()
		syms = source.Outline(dir, kept, r.budget)
	}
	edges := map[string][]diffview.Edge{}
	if r.calls {
		edges = source.Calls(spec.Dir, spec.From, spec.To, touched, r.budget)
	}
	return syms, edges
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

// follow reprints on change rather than on a timer, because a diff that has not
// moved redraws to the same bytes and the flicker says nothing. The raw patches
// are the change detector: they are what every layer is derived from.
func (r renderer) follow(every time.Duration) error {
	last := ""
	for {
		patches, err := r.patches()
		if err != nil {
			return err
		}
		now := strings.Join(patches, "\x00")
		if now != last {
			last = now
			out := r.draw(patches)
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
