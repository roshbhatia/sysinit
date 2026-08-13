// Package vcs reads the working tree's diff so a reviewer can annotate the code a
// change produced, not just the plan that described it.
package vcs

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"github.com/roshbhatia/specutil/internal/ident"
)

// Line kinds in a hunk.
const (
	LineContext = "context"
	LineAdd     = "add"
	LineDelete  = "delete"
)

// File statuses.
const (
	StatusAdded    = "added"
	StatusModified = "modified"
	StatusDeleted  = "deleted"
	StatusRenamed  = "renamed"
	StatusBinary   = "binary"
)

// Line is one line of a hunk.
type Line struct {
	Kind    string `json:"kind"`
	Text    string `json:"text"`
	OldLine int    `json:"oldLine,omitempty"`
	NewLine int    `json:"newLine,omitempty"`
}

// Hunk is one contiguous run of changed lines with its surrounding context.
type Hunk struct {
	Identity string `json:"identity"`
	Header   string `json:"header"`
	OldStart int    `json:"oldStart"`
	NewStart int    `json:"newStart"`
	Lines    []Line `json:"lines"`
}

// File is one file's diff.
type File struct {
	Path    string `json:"path"`
	OldPath string `json:"oldPath,omitempty"`
	Status  string `json:"status"`
	Hunks   []Hunk `json:"hunks"`
}

// Diff is a whole working-tree comparison.
type Diff struct {
	Base  string `json:"base"`
	Files []File `json:"files"`
	// Note explains an empty diff that is not simply "nothing changed", so a
	// reader is never left guessing whether the tool worked.
	Note string `json:"note,omitempty"`
}

// Stats counts what a diff touches.
func (d *Diff) Stats() (files, added, deleted int) {
	files = len(d.Files)
	for _, f := range d.Files {
		for _, h := range f.Hunks {
			for _, l := range h.Lines {
				switch l.Kind {
				case LineAdd:
					added++
				case LineDelete:
					deleted++
				}
			}
		}
	}
	return files, added, deleted
}

// IsRepo reports whether repo is inside a git working tree.
func IsRepo(repo string) bool {
	cmd := exec.Command("git", "-C", repo, "rev-parse", "--is-inside-work-tree")
	out, err := cmd.Output()
	return err == nil && strings.TrimSpace(string(out)) == "true"
}

// HeadCommit returns the current commit, or an empty string when there is no
// git working tree or no commit yet. Recording it is a read of local state, not
// a clock: the same repository state always yields the same value.
func HeadCommit(repo string) string {
	out, err := exec.Command("git", "-C", repo, "rev-parse", "HEAD").Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}

// Collect returns the diff between base and the working tree, restricted to
// paths when any are given. An empty base compares against HEAD, which is what
// shows uncommitted work.
func Collect(repo, base string, paths []string) (*Diff, error) {
	if !IsRepo(repo) {
		return &Diff{Base: base, Files: []File{}, Note: "not a git working tree"}, nil
	}
	if base == "" {
		base = "HEAD"
	}
	args := []string{
		"-C", repo, "--no-pager", "diff", "--no-color", "--no-ext-diff",
		"--find-renames", "-U3", base,
	}
	if len(paths) > 0 {
		args = append(args, "--")
		args = append(args, paths...)
	}
	out, err := exec.Command("git", args...).Output()
	if err != nil {
		// A bad ref is the common failure and the message git prints is the useful
		// one, so it is passed through rather than replaced.
		if ee, ok := err.(*exec.ExitError); ok && len(ee.Stderr) > 0 {
			return nil, fmt.Errorf("git diff %s: %s", base, strings.TrimSpace(string(ee.Stderr)))
		}
		return nil, fmt.Errorf("git diff %s: %w", base, err)
	}
	files := Parse(string(out))
	files = append(files, untracked(repo, paths)...)
	files = dropToolState(files)
	sort.SliceStable(files, func(i, j int) bool { return files[i].Path < files[j].Path })
	return &Diff{Base: base, Files: files}, nil
}

// toolState names the files specutil writes to track its own work. A reviewer
// looking at what a change did should not have to read the record of their own
// last review, so these never appear in a diff.
var toolState = map[string]bool{
	"specutil.review.yaml": true,
	"specutil.lock.yaml":   true,
}

func dropToolState(files []File) []File {
	out := files[:0]
	for _, f := range files {
		if toolState[filepath.Base(f.Path)] {
			continue
		}
		out = append(out, f)
	}
	return out
}

// untracked returns the new files git does not yet know about.
func untracked(repo string, paths []string) []File {
	args := []string{"-C", repo, "ls-files", "--others", "--exclude-standard"}
	if len(paths) > 0 {
		args = append(args, "--")
		args = append(args, paths...)
	}
	out, err := exec.Command("git", args...).Output()
	if err != nil {
		return nil
	}
	var files []File
	for _, name := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		if name == "" {
			continue
		}
		// --no-index exits 1 whenever the files differ, which is always here, so
		// the exit code carries no information and only the output is read.
		raw, _ := exec.Command("git", "-C", repo, "--no-pager", "diff", "--no-color",
			"--no-ext-diff", "-U3", "--no-index", os.DevNull, name).Output()
		for _, f := range Parse(string(raw)) {
			f.Path = name
			f.OldPath = ""
			f.Status = StatusAdded
			files = append(files, f)
		}
	}
	return files
}

// hunkHeaderRe matches "@@ -12,7 +12,9 @@ optional context".
// The counts are optional because git omits them for single-line ranges.
var hunkHeaderRe = regexp.MustCompile(`^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@`)

// Parse turns git's unified diff output into files and hunks. It is tolerant:
// an unrecognized line inside a file block is skipped rather than aborting the
// parse, because a diff a reviewer cannot see is worse than one with a gap.
func Parse(src string) []File {
	var files []File
	var cur *File
	var hunk *Hunk
	oldLine, newLine := 0, 0

	flushHunk := func() {
		if cur != nil && hunk != nil {
			hunk.Identity = hunkIdentity(cur.Path, *hunk)
			cur.Hunks = append(cur.Hunks, *hunk)
		}
		hunk = nil
	}
	flushFile := func() {
		flushHunk()
		if cur != nil {
			files = append(files, *cur)
		}
		cur = nil
	}

	sc := bufio.NewScanner(strings.NewReader(src))
	sc.Buffer(make([]byte, 0, 64*1024), 8*1024*1024)
	for sc.Scan() {
		line := sc.Text()

		switch {
		case strings.HasPrefix(line, "diff --git "):
			flushFile()
			a, b := splitDiffHeader(strings.TrimPrefix(line, "diff --git "))
			cur = &File{Path: b, OldPath: a, Status: StatusModified, Hunks: []Hunk{}}
			continue
		case cur == nil:
			continue
		case strings.HasPrefix(line, "new file mode"):
			cur.Status = StatusAdded
			cur.OldPath = ""
			continue
		case strings.HasPrefix(line, "deleted file mode"):
			cur.Status = StatusDeleted
			continue
		case strings.HasPrefix(line, "rename from "):
			cur.Status = StatusRenamed
			cur.OldPath = strings.TrimPrefix(line, "rename from ")
			continue
		case strings.HasPrefix(line, "rename to "):
			cur.Status = StatusRenamed
			cur.Path = strings.TrimPrefix(line, "rename to ")
			continue
		case strings.HasPrefix(line, "Binary files ") || strings.HasPrefix(line, "GIT binary patch"):
			flushHunk()
			cur.Status = StatusBinary
			continue
		case strings.HasPrefix(line, "--- ") || strings.HasPrefix(line, "+++ "):
			continue
		case strings.HasPrefix(line, "@@"):
			flushHunk()
			m := hunkHeaderRe.FindStringSubmatch(line)
			if m == nil {
				continue
			}
			oldLine, newLine = atoi(m[1]), atoi(m[3])
			hunk = &Hunk{Header: line, OldStart: oldLine, NewStart: newLine, Lines: []Line{}}
			continue
		case hunk == nil:
			continue
		case strings.HasPrefix(line, "\\"):
			// "\ No newline at end of file" annotates the previous line.
			continue
		}

		switch {
		case strings.HasPrefix(line, "+"):
			hunk.Lines = append(hunk.Lines, Line{Kind: LineAdd, Text: line[1:], NewLine: newLine})
			newLine++
		case strings.HasPrefix(line, "-"):
			hunk.Lines = append(hunk.Lines, Line{Kind: LineDelete, Text: line[1:], OldLine: oldLine})
			oldLine++
		case strings.HasPrefix(line, " "):
			hunk.Lines = append(hunk.Lines, Line{Kind: LineContext, Text: line[1:], OldLine: oldLine, NewLine: newLine})
			oldLine++
			newLine++
		}
	}
	flushFile()

	if files == nil {
		files = []File{}
	}
	return files
}

// hunkIdentity hashes the path and the changed lines, leaving out line numbers
// and context so an edit elsewhere in the file does not orphan a comment.
func hunkIdentity(path string, h Hunk) string {
	var b strings.Builder
	b.WriteString(path)
	b.WriteString("\n")
	for _, l := range h.Lines {
		if l.Kind == LineContext {
			continue
		}
		b.WriteString(l.Kind)
		b.WriteString(":")
		b.WriteString(l.Text)
		b.WriteString("\n")
	}
	return ident.Hash(b.String())
}

// splitDiffHeader pulls the two paths out of a "diff --git a/x b/y" line. Git
// quotes paths containing spaces, and the a/ b/ prefixes are conventional, so
// both are stripped.
func splitDiffHeader(rest string) (old, current string) {
	fields := strings.Fields(rest)
	if len(fields) < 2 {
		return "", strings.Trim(rest, `"`)
	}
	return stripPrefix(fields[0]), stripPrefix(fields[len(fields)-1])
}

func stripPrefix(p string) string {
	p = strings.Trim(p, `"`)
	for _, pre := range []string{"a/", "b/"} {
		if strings.HasPrefix(p, pre) {
			return p[len(pre):]
		}
	}
	return p
}

func atoi(s string) int {
	n, _ := strconv.Atoi(s)
	return n
}
