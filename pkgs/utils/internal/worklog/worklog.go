// Package worklog appends one SessionEnd record describing what a session
// touched: the repositories under it, the work each one is ahead by, and the
// intent read off the transcript.
package worklog

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/paths"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/transcript"
)

const Summary = "append one SessionEnd record to the worklog"

const usage = `worklog: append one SessionEnd record to the worklog

Usage:
  worklog < event.json

Reads a Claude Code SessionEnd payload on stdin and appends one JSON line. A
session with no repository and no prompt is not recorded, and neither is a
` + "`resume`" + `, which starts work rather than finishing it.

CLAUDE_WORKLOG_FILE overrides where the line is written.

Exits 0 whether or not a record was written, because a SessionEnd hook must not
fail a session that has already ended.
`

// schemaVersion is the record shape readers match on. Bump it when a field
// changes meaning, never when one is added.
const schemaVersion = 2

const (
	maxCommits  = 30
	maxFiles    = 50
	promptChars = 200
	// gitTimeout bounds one git call, so a repository with a stuck index cannot
	// hold the session's last hook open.
	gitTimeout = 15 * time.Second
)

// Commit is one commit the branch is ahead by.
type Commit struct {
	SHA     string `json:"sha"`
	Subject string `json:"subject"`
}

// File is one path the branch changed, with git's own status letters.
type File struct {
	Status string `json:"status"`
	Path   string `json:"path"`
}

// Repo describes one worktree at the moment the session ended.
type Repo struct {
	Name         string   `json:"name"`
	Branch       string   `json:"branch"`
	Head         string   `json:"head"`
	Base         string   `json:"base"`
	URL          string   `json:"url"`
	CommitsAhead int      `json:"commits_ahead"`
	Commits      []Commit `json:"commits"`
	Files        []File   `json:"files"`
	Insertions   int      `json:"insertions"`
	Deletions    int      `json:"deletions"`
	Diffstat     string   `json:"diffstat"`
	Dirty        string   `json:"dirty"`
}

// Record is one worklog line. The pointer fields are the ones a reader must be
// able to tell "absent" from "empty" for.
type Record struct {
	V              int     `json:"v"`
	TS             string  `json:"ts"`
	TSStart        *string `json:"ts_start"`
	DurationMin    *int    `json:"duration_min"`
	SessionID      string  `json:"session_id"`
	Kind           string  `json:"kind"`
	SessionName    string  `json:"session_name"`
	Model          *string `json:"model"`
	UserTurns      int     `json:"user_turns"`
	Repos          []Repo  `json:"repos"`
	CWD            string  `json:"cwd"`
	FirstPrompt    string  `json:"first_prompt"`
	LastPrompt     string  `json:"last_prompt"`
	TranscriptPath string  `json:"transcript_path"`
	EndReason      string  `json:"end_reason"`
	Summary        *string `json:"summary"`
}

// event is the part of the SessionEnd payload this reads.
type event struct {
	SessionID      string `json:"session_id"`
	CWD            string `json:"cwd"`
	Reason         string `json:"reason"`
	TranscriptPath string `json:"transcript_path"`
}

// git runs one git command in repo and returns its trimmed stdout. Every failure
// is the same answer, because this record is best-effort by contract.
func git(repo string, args ...string) (string, bool) {
	ctx, cancel := context.WithTimeout(context.Background(), gitTimeout)
	defer cancel()

	cmd := exec.CommandContext(ctx, "git", append([]string{"-C", repo}, args...)...)
	cmd.Env = append(os.Environ(), "GIT_OPTIONAL_LOCKS=0")
	// The deadline kills git, and this bounds the wait for the pipes a child it
	// left behind still holds open.
	cmd.WaitDelay = gitTimeout
	out, err := cmd.Output()
	if err != nil {
		return "", false
	}
	return strings.TrimSpace(string(out)), true
}

// isGit reports whether path is inside a work tree.
func isGit(path string) bool {
	out, ok := git(path, "rev-parse", "--is-inside-work-tree")
	return ok && out == "true"
}

// normalizeRemote turns a git remote into a URL a browser can open.
func normalizeRemote(url string) string {
	u := strings.TrimSuffix(url, ".git")
	if rest, found := strings.CutPrefix(u, "git@"); found {
		host, path, _ := strings.Cut(rest, ":")
		return "https://" + host + "/" + path
	}
	if rest, found := strings.CutPrefix(u, "ssh://"); found {
		if _, after, hasUser := strings.Cut(rest, "@"); hasUser {
			rest = after
		}
		return "https://" + rest
	}
	return u
}

// comparisonRef names the remote ref that exposes this branch's local work. A
// branch off the base compares against the base, so work on a topic branch is
// still counted rather than reported as nothing.
func comparisonRef(repo, branch, base string) (string, bool) {
	if branch == "" || base == "" {
		return "", false
	}
	ref := "origin/" + base
	if branch == base {
		ref = "origin/" + branch
	}
	if _, ok := git(repo, "rev-parse", "--verify", ref); !ok {
		return "", false
	}
	return ref, true
}

// describe reads the worktree at path, or reports false when it is not one.
func describe(path string) (Repo, bool) {
	toplevel, ok := git(path, "rev-parse", "--show-toplevel")
	if !ok || toplevel == "" {
		return Repo{}, false
	}

	repo := Repo{
		Name:    filepath.Base(toplevel),
		Commits: []Commit{},
		Files:   []File{},
	}
	repo.Branch, _ = git(path, "branch", "--show-current")
	repo.Head, _ = git(path, "rev-parse", "--short", "HEAD")
	repo.Dirty, _ = git(path, "diff", "--shortstat")

	remote, ok := git(path, "remote", "get-url", "origin")
	if !ok || remote == "" {
		if names, listed := git(path, "remote"); listed && names != "" {
			first := strings.SplitN(names, "\n", 2)[0]
			remote, _ = git(path, "remote", "get-url", first)
		}
	}
	if remote != "" {
		repo.URL = normalizeRemote(remote)
		if repo.Branch != "" {
			repo.URL += "/tree/" + repo.Branch
		}
	}

	if head, found := git(path, "symbolic-ref", "refs/remotes/origin/HEAD"); found && head != "" {
		repo.Base = head[strings.LastIndex(head, "/")+1:]
	}

	ref, hasRef := comparisonRef(path, repo.Branch, repo.Base)
	if !hasRef {
		return repo, true
	}

	if count, found := git(path, "rev-list", "--count", ref+"..HEAD"); found {
		if parsed, err := strconv.Atoi(count); err == nil {
			repo.CommitsAhead = parsed
		}
	}
	// Three dots for the stats and the file list, so a base that moved on does
	// not read as this session's work. Two for the commits, which are this
	// branch's own.
	repo.Diffstat, _ = git(path, "diff", "--shortstat", ref+"...HEAD")

	if log, found := git(path, "log", "--format=%h%x09%s", ref+"..HEAD"); found {
		for _, line := range lines(log, maxCommits) {
			sha, subject, _ := strings.Cut(line, "\t")
			repo.Commits = append(repo.Commits, Commit{SHA: sha, Subject: subject})
		}
	}

	if names, found := git(path, "diff", "--name-status", ref+"...HEAD"); found {
		for _, line := range lines(names, maxFiles) {
			fields := strings.Split(line, "\t")
			repo.Files = append(repo.Files, File{
				Status: fields[0],
				// A rename carries two paths, joined the way the record has always
				// spelled it.
				Path: strings.Join(fields[1:], " -> "),
			})
		}
	}

	if numstat, found := git(path, "diff", "--numstat", ref+"...HEAD"); found {
		for _, line := range lines(numstat, 0) {
			cols := strings.Split(line, "\t")
			if len(cols) < 2 {
				continue
			}
			// A binary file reports "-", which is not a count.
			if n, err := strconv.Atoi(cols[0]); err == nil {
				repo.Insertions += n
			}
			if n, err := strconv.Atoi(cols[1]); err == nil {
				repo.Deletions += n
			}
		}
	}

	return repo, true
}

// lines splits text and drops the empty ones, keeping at most limit. A limit of
// zero keeps them all.
func lines(text string, limit int) []string {
	var kept []string
	for _, line := range strings.Split(text, "\n") {
		if line == "" {
			continue
		}
		kept = append(kept, line)
		if limit > 0 && len(kept) == limit {
			break
		}
	}
	return kept
}

// intent is what one pass over the transcript yields.
type intent struct {
	TSStart     string
	Model       string
	FirstPrompt string
	LastPrompt  string
	UserTurns   int
}

// entry is the part of a transcript line this reads.
type entry struct {
	Type      string `json:"type"`
	Timestamp string `json:"timestamp"`
	Message   struct {
		Model   string          `json:"model"`
		Content json.RawMessage `json:"content"`
	} `json:"message"`
}

// block is one content block of an assistant or user message.
type block struct {
	Type string `json:"type"`
	Text string `json:"text"`
}

// text collapses a message's content to its plain text, whether the harness
// wrote a string or an array of blocks.
func text(raw json.RawMessage) string {
	if len(raw) == 0 {
		return ""
	}
	var plain string
	if json.Unmarshal(raw, &plain) == nil {
		return plain
	}
	var blocks []block
	if json.Unmarshal(raw, &blocks) != nil {
		return ""
	}
	var parts []string
	for _, b := range blocks {
		if b.Type == "text" {
			parts = append(parts, b.Text)
		}
	}
	return strings.Join(parts, " ")
}

// truncate cuts to n characters rather than n bytes, so a prompt holding one
// multi-byte character is not cut through the middle of it.
func truncate(s string, n int) string {
	runes := []rune(s)
	if len(runes) <= n {
		return s
	}
	return string(runes[:n])
}

// readContext reads intent and scale in one pass over the transcript.
func readContext(path string) intent {
	file, err := os.Open(path)
	if err != nil {
		return intent{}
	}
	defer file.Close()

	var found intent
	var prompts []string
	scanner := bufio.NewScanner(file)
	// A transcript line holds a whole message, which outgrows the default 64KB.
	scanner.Buffer(make([]byte, 0, 64*1024), 8*1024*1024)

	for scanner.Scan() {
		raw := strings.TrimSpace(scanner.Text())
		if raw == "" {
			continue
		}
		var e entry
		if json.Unmarshal([]byte(raw), &e) != nil {
			continue
		}
		if found.TSStart == "" && e.Timestamp != "" {
			found.TSStart = e.Timestamp
		}
		switch e.Type {
		case "assistant":
			if strings.TrimSpace(e.Message.Model) != "" {
				found.Model = e.Message.Model
			}
		case "user":
			if cleaned := strings.Join(strings.Fields(text(e.Message.Content)), " "); cleaned != "" {
				prompts = append(prompts, cleaned)
			}
		}
	}

	found.UserTurns = len(prompts)
	if len(prompts) > 0 {
		found.FirstPrompt = truncate(prompts[0], promptChars)
		found.LastPrompt = truncate(prompts[len(prompts)-1], promptChars)
	}
	return found
}

// parseISO reads a transcript timestamp, which carries Z rather than an offset.
func parseISO(value string) (time.Time, bool) {
	for _, layout := range []string{time.RFC3339Nano, time.RFC3339} {
		if parsed, err := time.Parse(layout, value); err == nil {
			return parsed, true
		}
	}
	return time.Time{}, false
}

// seshySession returns the session name holding dir, when dir is under the seshy
// sessions root.
func seshySession(dir string) (string, bool) {
	root := paths.SeshySessions()
	rel, err := filepath.Rel(root, dir)
	if err != nil || rel == "." || strings.HasPrefix(rel, "..") {
		return "", false
	}
	name := strings.Split(rel, string(os.PathSeparator))[0]
	if name == "" {
		return "", false
	}
	return name, true
}

// logFile is where the line is appended.
func logFile() string {
	if override := os.Getenv("CLAUDE_WORKLOG_FILE"); override != "" {
		return override
	}
	return paths.AgentWorklog()
}

// build assembles the record, or reports false when there is nothing to record.
func build(ev event, now time.Time) (Record, bool) {
	if ev.SessionID == "" {
		return Record{}, false
	}
	// A resume starts a session, so it has no finished work to report.
	if ev.Reason == "resume" {
		return Record{}, false
	}

	kind, sessionName := "dir", ""
	repos := []Repo{}

	if name, inSeshy := seshySession(ev.CWD); inSeshy {
		// One seshy session spans several worktrees, so every one of them is
		// reported rather than only the directory the session ended in.
		kind, sessionName = "seshy-session", name
		dir := filepath.Join(paths.SeshySessions(), name)
		children, err := os.ReadDir(dir)
		if err == nil {
			sort.Slice(children, func(i, j int) bool { return children[i].Name() < children[j].Name() })
			for _, child := range children {
				if !child.IsDir() {
					continue
				}
				path := filepath.Join(dir, child.Name())
				if !isGit(path) {
					continue
				}
				if repo, ok := describe(path); ok {
					repos = append(repos, repo)
				}
			}
		}
	} else if ev.CWD != "" && isGit(ev.CWD) {
		kind = "repo"
		if repo, ok := describe(ev.CWD); ok {
			repos = append(repos, repo)
		}
	}

	ts := now.UTC().Format("2006-01-02T15:04:05Z")
	found := intent{}
	path := transcript.Resolve(ev.TranscriptPath, ev.SessionID)
	if path != "" {
		found = readContext(path)
	}

	// Neither a repository nor a prompt means the session left no trace worth a
	// line.
	if len(repos) == 0 && found.FirstPrompt == "" {
		return Record{}, false
	}

	record := Record{
		V:              schemaVersion,
		TS:             ts,
		SessionID:      ev.SessionID,
		Kind:           kind,
		SessionName:    sessionName,
		UserTurns:      found.UserTurns,
		Repos:          repos,
		CWD:            ev.CWD,
		FirstPrompt:    found.FirstPrompt,
		LastPrompt:     found.LastPrompt,
		TranscriptPath: path,
		EndReason:      ev.Reason,
	}
	if found.TSStart != "" {
		record.TSStart = &found.TSStart
	}
	if found.Model != "" {
		record.Model = &found.Model
	}
	if start, ok := parseISO(found.TSStart); ok {
		if end, ok := parseISO(ts); ok && !end.Before(start) {
			minutes := int(end.Sub(start).Minutes())
			record.DurationMin = &minutes
		}
	}
	return record, true
}

// appendLine writes one record, creating the directory the log sits in.
func appendLine(path string, record Record) error {
	encoded, err := json.Marshal(record)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	file, err := os.OpenFile(path, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600)
	if err != nil {
		return err
	}
	defer file.Close()
	_, err = file.Write(append(encoded, '\n'))
	return err
}

// Run reads the payload and appends the record.
func Run(args []string) int {
	if len(args) > 0 {
		switch args[0] {
		case "-h", "--help", "help":
			fmt.Print(usage)
			return 0
		}
	}

	var ev event
	if err := json.NewDecoder(os.Stdin).Decode(&ev); err != nil {
		return 0
	}
	record, ok := build(ev, time.Now())
	if !ok {
		return 0
	}
	if err := appendLine(logFile(), record); err != nil {
		fmt.Fprintf(os.Stderr, "worklog: %v\n", err)
	}
	return 0
}
