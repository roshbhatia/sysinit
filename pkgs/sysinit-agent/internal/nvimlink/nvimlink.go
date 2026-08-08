// Package nvimlink finds a running neovim whose working directory is a given
// repository and asks it to show that repository's agent notes.
//
// Every call here is best effort. diffnote runs from agents, hooks, and CI,
// where there is no editor at all, so a failure to reach one is not a failure
// of the write that preceded it. Nothing in this package returns an error the
// caller is expected to surface.
package nvimlink

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/neovim/go-client/nvim"
)

// dialTimeout bounds the whole sweep. A wedged editor must not hold up the CLI
// that just wrote a note; the note is already on disk either way.
const dialTimeout = 750 * time.Millisecond

// openViewLua opens the diff view when it is not already showing, then reloads
// the store. Written as one expression so the round trip is a single call: the
// editor may be mid-redraw, and two calls can interleave with the user typing.
//
// vim.g.codediff_saved_showtabline is set by the CodeDiffOpen handler and
// cleared by CodeDiffClose, so it doubles as the "is the view up" flag without
// reaching into the plugin's own state.
const openViewLua = `
local ok, d = pcall(require, "harness.diffnote")
if not ok then return "no-module" end
if vim.g.codediff_saved_showtabline == nil then
  local opened = pcall(vim.cmd, "CodeDiff")
  if not opened then return "no-codediff" end
  return "opened"
end
pcall(function() d.refresh() end)
return "refreshed"
`

// Sockets lists the RPC sockets neovim may be listening on.
//
// neovim puts them at <run dir>/<random>/0, where the run dir is
// $XDG_RUNTIME_DIR/nvim.$USER on Linux and $TMPDIR/nvim.$USER on macOS. Both
// are probed rather than branched on: a Linux host with no XDG_RUNTIME_DIR
// falls back to the temp directory too.
func Sockets() []string {
	user := os.Getenv("USER")
	if user == "" {
		user = os.Getenv("LOGNAME")
	}
	bases := []string{}
	for _, dir := range []string{os.Getenv("XDG_RUNTIME_DIR"), os.Getenv("TMPDIR"), "/tmp"} {
		if dir == "" {
			continue
		}
		bases = append(bases, filepath.Join(dir, "nvim."+user))
	}

	seen := map[string]bool{}
	found := []string{}
	add := func(path string) {
		resolved, err := filepath.EvalSymlinks(path)
		if err != nil {
			resolved = path
		}
		if !seen[resolved] {
			seen[resolved] = true
			found = append(found, path)
		}
	}
	for _, base := range bases {
		matches, err := filepath.Glob(filepath.Join(base, "*", "0"))
		if err != nil {
			continue
		}
		for _, match := range matches {
			add(match)
		}
	}
	return found
}

// debugf reports what the sweep did, under DIFFNOTE_OPEN_DEBUG=1.
//
// The whole path is silent by design, which leaves "nothing happened" and "no
// editor was running" looking identical. This is the only way to tell them
// apart without a debugger.
func debugf(format string, args ...any) {
	if os.Getenv("DIFFNOTE_OPEN_DEBUG") != "1" {
		return
	}
	fmt.Fprintf(os.Stderr, "diffnote: open: "+format+"\n", args...)
}

// ShowNotes asks every neovim serving root to open its diff view.
//
// Servers are swept in parallel: one that is busy in a modal prompt will not
// answer within the timeout, and it must not starve the others.
func ShowNotes(root string) {
	sockets := Sockets()
	debugf("found %d socket(s): %v", len(sockets), sockets)
	if len(sockets) == 0 {
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), dialTimeout)
	defer cancel()

	var wg sync.WaitGroup
	for _, socket := range sockets {
		wg.Add(1)
		go func(path string) {
			defer wg.Done()
			showOne(ctx, path, root)
		}(socket)
	}
	wg.Wait()
}

func showOne(ctx context.Context, socket, root string) {
	client, err := nvim.Dial(socket, nvim.DialContext(ctx))
	if err != nil {
		debugf("%s: dial: %v", socket, err)
		return
	}
	defer client.Close()

	var cwd string
	if err := client.Eval("getcwd()", &cwd); err != nil {
		debugf("%s: getcwd: %v", socket, err)
		return
	}
	if !servesRoot(cwd, root) {
		debugf("%s: cwd %s does not serve %s", socket, cwd, root)
		return
	}
	var result string
	// The result is read but not acted on: there is nothing useful to do about
	// an editor without the plugin, and saying so would be noise on a path the
	// caller did not ask for.
	if err := client.ExecLua(openViewLua, &result); err != nil {
		debugf("%s: exec: %v", socket, err)
		return
	}
	debugf("%s: %s", socket, result)
}

// servesRoot reports whether an editor sitting in cwd is looking at root.
//
// Compared after resolving symlinks, because git answers physically while the
// editor's getcwd() reports whatever route the user took to get there. A
// subdirectory counts: the diff view is repository-wide.
func servesRoot(cwd, root string) bool {
	resolve := func(path string) string {
		resolved, err := filepath.EvalSymlinks(path)
		if err != nil {
			return filepath.Clean(path)
		}
		return resolved
	}
	cwd, root = resolve(cwd), resolve(root)
	if cwd == root {
		return true
	}
	rel, err := filepath.Rel(root, cwd)
	if err != nil {
		return false
	}
	return rel != ".." && !filepath.IsAbs(rel) &&
		!(len(rel) >= 3 && rel[:3] == "../")
}
