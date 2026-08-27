package workspace

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"sync"

	wsroot "github.com/roshbhatia/sysinit/pkgs/internal/workspace"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/repo"
)

const Summary = "list the repositories under a workspace, and the changes in them"

const scanDepth = wsroot.ScanDepth

const logCount = 10

const emptyTree = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

func takeCount(args []string, count *int) ([]string, int) {
	rest := make([]string, 0, len(args))
	for i := 0; i < len(args); i++ {
		if args[i] != "-n" {
			rest = append(rest, args[i])
			continue
		}
		if i+1 >= len(args) {
			fmt.Fprintln(os.Stderr, "workspace: -n needs a value")
			return nil, 2
		}
		parsed, err := strconv.Atoi(args[i+1])
		if err != nil || parsed < 1 {
			fmt.Fprintf(os.Stderr, "workspace: -n takes a positive integer, got %q\n", args[i+1])
			return nil, 2
		}
		*count = parsed
		i++
	}
	return rest, 0
}

func takeJSON(args []string, asJSON *bool) []string {
	rest := make([]string, 0, len(args))
	for _, arg := range args {
		if arg == "--json" {
			*asJSON = true
			continue
		}
		rest = append(rest, arg)
	}
	return rest
}

func readRoots(r io.Reader) []string {
	var roots []string
	scanner := bufio.NewScanner(r)
	for scanner.Scan() {
		if line := strings.TrimSpace(scanner.Text()); line != "" {
			roots = append(roots, line)
		}
	}
	return roots
}

func Run(args []string) (code int) {
	if len(args) == 0 {
		usage(os.Stderr)
		return 2
	}

	action, rest := args[0], args[1:]
	switch action {
	case "-h", "--help", "help":
		usage(os.Stdout)
		return 0
	case "roots", "changes", "health", "log":
	default:
		fmt.Fprintf(os.Stderr, "workspace: unknown action %q\n", action)
		usage(os.Stderr)
		return 2
	}

	count := logCount
	rest, usageCode := takeCount(rest, &count)
	if usageCode != 0 {
		return usageCode
	}

	asJSON := false
	rest = takeJSON(rest, &asJSON)
	if asJSON && action != "changes" {
		fmt.Fprintf(os.Stderr, "workspace: --json is only for changes, not %s\n", action)
		return 2
	}

	fromStdin := len(rest) == 1 && rest[0] == "-"
	if fromStdin && action == "health" {
		fmt.Fprintln(os.Stderr, "workspace: health reports on a directory, not on roots from stdin")
		return 2
	}

	var (
		dir   string
		roots []string
	)
	if fromStdin {
		roots = readRoots(os.Stdin)
	} else {
		var dirCode int
		dir, dirCode = resolveDir(rest)
		if dirCode != 0 {
			return dirCode
		}
		var err error
		roots, err = Roots(dir)
		if err != nil {
			fmt.Fprintf(os.Stderr, "workspace: %v\n", err)
			return 1
		}
	}

	out := bufio.NewWriter(os.Stdout)
	defer func() {
		if out.Flush() != nil {
			code = 1
		}
	}()

	if action == "roots" {
		writeLines(out, roots)
		return 0
	}

	if action == "log" {
		for _, commit := range Log(roots, count) {
			_, _ = fmt.Fprintf(out, "%s\t%s\t%s\t%s\t%s\n",
				commit.Root, commit.SHA, commit.Short, commit.Parent, commit.Subject)
		}
		return 0
	}

	groups := Changes(roots)

	if action == "health" {
		writeHealth(out, dir, roots, groups)
		return 0
	}

	if asJSON {
		return writeReport(out, dir, roots, groups)
	}

	for _, group := range groups {
		for _, file := range group.Files {
			_, _ = fmt.Fprintln(out, file.Path)
		}
	}
	return 0
}

// Everything a reader needs to draw one list over several repositories: the
// workspace it read, every root under it, and the changed files grouped by root.
type Report struct {
	Workspace string   `json:"workspace"`
	Roots     []string `json:"roots"`
	Groups    []Group  `json:"groups"`
}

func writeReport(w io.Writer, dir string, roots []string, groups []Group) int {
	report := Report{Roots: roots, Groups: groups}
	if dir != "" {
		report.Workspace = repo.Workspace(dir)
	}
	if report.Roots == nil {
		report.Roots = []string{}
	}
	if report.Groups == nil {
		report.Groups = []Group{}
	}

	body, err := json.Marshal(report)
	if err != nil {
		fmt.Fprintf(os.Stderr, "workspace: %v\n", err)
		return 1
	}
	if _, err := fmt.Fprintf(w, "%s\n", body); err != nil {
		return 1
	}
	return 0
}

func writeHealth(w io.Writer, dir string, roots []string, groups []Group) {
	changed := 0
	for _, group := range groups {
		changed += len(group.Files)
	}
	_, _ = fmt.Fprintf(w, "dir=%s\n", dir)
	_, _ = fmt.Fprintf(w, "workspace=%s\n", repo.Workspace(dir))
	_, _ = fmt.Fprintf(w, "roots=%d\n", len(roots))
	_, _ = fmt.Fprintf(w, "dirty_roots=%d\n", len(groups))
	_, _ = fmt.Fprintf(w, "changed_files=%d\n", changed)
	_, _ = fmt.Fprintf(w, "scan_depth=%d\n", scanDepth)
	for _, group := range groups {
		_, _ = fmt.Fprintf(w, "dirty=%s %d\n", group.Root, len(group.Files))
	}
}

func usage(w io.Writer) {
	_, _ = fmt.Fprint(w, `ws: what a workspace holds

Usage:
  ws roots   [dir]        repository roots, one absolute path per line
  ws changes [dir|-]      changed paths in those repositories
  ws changes --json [dir] the same changes as one object, grouped by root
  ws log     [dir|-] [-n] recent commits, as root, sha, short sha, parent, subject
  ws health  [dir]        what this layer sees, as key=value lines

dir defaults to the working directory. The workspace is the seshy session holding
dir when there is one, and otherwise dir's own repository root or dir itself, which
is the same rule the edit-event log is keyed on.

`+"`-`"+` reads the roots from stdin instead, one per line, keeping their order:
  ws roots | ws log -n 5 -

log writes tab-separated fields, and -n bounds the commits per repository (10).

`+"`--json`"+` writes {workspace, roots, groups}, where a group is a root and its
changed files, each carrying git's two-character porcelain status. It is one call
for a reader that draws every repository's changes in a single list.

Exits 0 with no output when there is nothing to report, 1 when git fails, and 2 on
a usage error.
`)
}

func resolveDir(args []string) (string, int) {
	if len(args) > 1 {
		fmt.Fprintf(os.Stderr, "workspace: expected at most one directory, got %d\n", len(args))
		return "", 2
	}

	dir := ""
	if len(args) == 1 {
		dir = args[0]
	}
	if dir == "" {
		here, err := os.Getwd()
		if err != nil {
			fmt.Fprintf(os.Stderr, "workspace: %v\n", err)
			return "", 2
		}
		dir = here
	}

	info, err := os.Stat(dir)
	if err != nil {
		fmt.Fprintf(os.Stderr, "workspace: %v\n", err)
		return "", 2
	}
	if !info.IsDir() {
		fmt.Fprintf(os.Stderr, "workspace: %s is not a directory\n", dir)
		return "", 2
	}

	abs, err := filepath.Abs(dir)
	if err != nil {
		fmt.Fprintf(os.Stderr, "workspace: %v\n", err)
		return "", 2
	}
	return abs, 0
}

// The walk itself lives in pkgs/internal/workspace, which changes reads too.
func Roots(dir string) ([]string, error) { return wsroot.Roots(dir) }

type Commit struct {
	Root    string
	SHA     string
	Short   string
	Parent  string
	Subject string
}

func Log(roots []string, count int) []Commit {
	perRoot := make([][]Commit, len(roots))
	var wg sync.WaitGroup

	for i, root := range roots {
		wg.Add(1)
		go func(i int, root string) {
			defer wg.Done()
			perRoot[i] = logIn(root, count)
		}(i, root)
	}

	wg.Wait()

	var all []Commit
	for _, commits := range perRoot {
		all = append(all, commits...)
	}
	return all
}

func logIn(root string, count int) []Commit {
	cmd := exec.Command("git", "-C", root, "log",
		"--max-count="+strconv.Itoa(count), "--format=%H%x1f%h%x1f%P%x1f%s")
	cmd.Env = append(os.Environ(), "GIT_OPTIONAL_LOCKS=0")
	out, err := cmd.Output()
	if err != nil {
		return nil
	}

	var commits []Commit
	for _, line := range strings.Split(strings.TrimRight(string(out), "\n"), "\n") {
		fields := strings.Split(line, "\x1f")
		if len(fields) != 4 || fields[0] == "" {
			continue
		}

		parent := emptyTree
		if parents := strings.Fields(fields[2]); len(parents) > 0 {
			parent = parents[0]
		}
		commits = append(commits, Commit{
			Root:    root,
			SHA:     fields[0],
			Short:   fields[1],
			Parent:  parent,
			Subject: fields[3],
		})
	}
	return commits
}

// A changed path, carrying git's own two-character porcelain code rather than a
// word of our own, so a reader maps it once and never has to guess what we meant.
type File struct {
	Path   string `json:"path"`
	Status string `json:"status"`
}

type Group struct {
	Root  string `json:"root"`
	Files []File `json:"files"`
}

func Changes(roots []string) []Group {
	groups := make([]Group, len(roots))
	var wg sync.WaitGroup

	for i, root := range roots {
		wg.Add(1)
		go func(i int, root string) {
			defer wg.Done()
			groups[i] = Group{Root: root, Files: changedIn(root, nested(root, roots))}
		}(i, root)
	}

	wg.Wait()

	kept := groups[:0]
	for _, group := range groups {
		if len(group.Files) > 0 {
			kept = append(kept, group)
		}
	}
	return kept
}

func nested(root string, roots []string) []string {
	var inside []string
	for _, other := range roots {
		if other == root {
			continue
		}
		if rest := strings.TrimPrefix(other, root+string(os.PathSeparator)); rest != other {
			inside = append(inside, rest)
		}
	}
	return inside
}

func changedIn(root string, exclude []string) []File {
	args := []string{"-C", root, "status", "--porcelain", "--untracked-files=all", "-z", "--"}
	args = append(args, ".")
	for _, path := range exclude {
		args = append(args, ":(exclude)"+path)
	}

	cmd := exec.Command("git", args...)
	cmd.Env = append(os.Environ(), "GIT_OPTIONAL_LOCKS=0")
	out, err := cmd.Output()
	if err != nil {
		return nil
	}

	var files []File
	records := strings.Split(string(out), "\x00")
	for i := 0; i < len(records); i++ {
		record := records[i]
		if len(record) < 4 || record[2] != ' ' {
			continue
		}
		files = append(files, File{Path: filepath.Join(root, record[3:]), Status: record[:2]})
		if record[0] == 'R' || record[0] == 'C' {
			i++
		}
	}

	sort.Slice(files, func(a, b int) bool { return files[a].Path < files[b].Path })
	return files
}

func writeLines(w io.Writer, lines []string) {
	for _, line := range lines {
		_, _ = fmt.Fprintln(w, line)
	}
}
