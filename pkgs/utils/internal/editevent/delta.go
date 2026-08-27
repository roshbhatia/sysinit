package editevent

// The delta store is a shadow git repository. Its history lives under the state
// home and its work tree is the real checkout, so the repository's own git data
// is never touched and the checkout carries no extra marker. One agent write is
// one commit, whose subject is the prompt that asked for it, which makes
// `git blame` over the shadow repo answer "which prompt wrote this line".

import (
	"bytes"
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/repo"
)

const (
	promptBytes  = 8 * 1024
	deltaBytes   = 4 * 1024 * 1024
	subjectRunes = 72
	lockWait     = 2 * time.Second
	lockStale    = time.Minute
)

type prompt struct {
	TS      int64  `json:"ts"`
	Harness string `json:"harness"`
	Session string `json:"session"`
	Text    string `json:"text"`
}

type deltaMeta struct {
	harness string
	session string
	kind    string
	file    string
	prompt  prompt
}

func savePrompt(tree, harness, session, text string) {
	text = strings.TrimSpace(text)
	if text == "" || tree == "" {
		return
	}
	if len(text) > promptBytes {
		text = text[:promptBytes]
	}
	body, err := json.Marshal(prompt{
		TS:      time.Now().UnixMilli(),
		Harness: harness,
		Session: session,
		Text:    text,
	})
	if err != nil {
		return
	}

	path := repo.PromptFile(tree)
	if os.MkdirAll(filepath.Dir(path), 0o700) != nil {
		return
	}
	temporary := path + ".new"
	if os.WriteFile(temporary, append(body, '\n'), 0o600) != nil {
		return
	}
	if os.Rename(temporary, path) != nil {
		_ = os.Remove(temporary)
	}
}

func loadPrompt(tree string) prompt {
	var record prompt
	body, err := os.ReadFile(repo.PromptFile(tree))
	if err != nil {
		return record
	}
	if json.Unmarshal(body, &record) != nil {
		return prompt{}
	}
	return record
}

// recordDelta commits one written file into the shadow repository and returns the
// commit. An empty return means the write left no delta to record.
func recordDelta(tree string, meta deltaMeta) string {
	if tree == "" || !inTree(tree, meta.file) || tooBig(meta.file) {
		return ""
	}
	store := repo.DeltaDir(tree)
	if !ensureStore(store, tree) {
		return ""
	}

	release, ok := lockStore(store)
	if !ok {
		return ""
	}
	defer release()

	relative, err := filepath.Rel(tree, meta.file)
	if err != nil {
		return ""
	}
	seed(store, tree, relative)
	if _, err := git(store, tree, nil, "add", "--all", "--force", "--", relative); err != nil {
		return ""
	}
	message := commitMessage(relative, meta)
	if _, err := git(store, tree, strings.NewReader(message),
		"commit", "--quiet", "--cleanup=whitespace", "--file=-"); err != nil {
		return ""
	}
	head, err := git(store, tree, nil, "rev-parse", "HEAD")
	if err != nil {
		return ""
	}
	return head
}

// seed writes the checkout's HEAD content through the object database, never the work
// tree, so a first write diffs against the old file instead of against nothing.
func seed(store, tree, relative string) {
	if _, err := git(store, tree, nil, "ls-files", "--error-unmatch", "--", relative); err == nil {
		return
	}
	committed := exec.Command("git", "-C", tree, "cat-file", "blob", "HEAD:"+relative)
	committed.Env = repo.CleanEnv()
	body, err := committed.Output()
	if err != nil {
		return
	}

	hash := exec.Command("git", "hash-object", "-w", "--stdin")
	hash.Dir = tree
	hash.Env = repo.GitEnv(store, tree)
	hash.Stdin = bytes.NewReader(body)
	object, err := hash.Output()
	if err != nil {
		return
	}

	mode := "100644"
	if info, err := os.Stat(filepath.Join(tree, relative)); err == nil && info.Mode()&0o111 != 0 {
		mode = "100755"
	}
	entry := strings.Join([]string{mode, strings.TrimSpace(string(object)), relative}, ",")
	if _, err := git(store, tree, nil, "update-index", "--add", "--cacheinfo", entry); err != nil {
		return
	}
	_, _ = git(store, tree, strings.NewReader("seed "+relative+"\n"),
		"commit", "--quiet", "--cleanup=whitespace", "--file=-")
}

func commitMessage(relative string, meta deltaMeta) string {
	subject := subjectOf(meta.prompt.Text)
	if subject == "" {
		subject = meta.kind + " " + relative
	}

	var out strings.Builder
	out.WriteString(subject)
	out.WriteString("\n\n")
	if body := strings.TrimSpace(meta.prompt.Text); body != "" && body != subject {
		out.WriteString(body)
		out.WriteString("\n\n")
	}
	for _, trailer := range [][2]string{
		{"Sysinit-Harness", meta.harness},
		{"Sysinit-Session", meta.session},
		{"Sysinit-Kind", meta.kind},
		{"Sysinit-File", relative},
	} {
		if trailer[1] == "" {
			continue
		}
		out.WriteString(trailer[0])
		out.WriteString(": ")
		out.WriteString(oneLine(trailer[1]))
		out.WriteString("\n")
	}
	return out.String()
}

func subjectOf(text string) string {
	for line := range strings.SplitSeq(text, "\n") {
		line = oneLine(line)
		if line == "" {
			continue
		}
		runes := []rune(line)
		if len(runes) > subjectRunes {
			return string(runes[:subjectRunes-1]) + "…"
		}
		return line
	}
	return ""
}

func oneLine(text string) string {
	return strings.Join(strings.Fields(text), " ")
}

func inTree(tree, file string) bool {
	return strings.HasPrefix(file, strings.TrimRight(tree, "/")+"/")
}

func tooBig(file string) bool {
	info, err := os.Stat(file)
	if err != nil {
		// A delete has no file to size, and it is still worth a delta.
		return !os.IsNotExist(err)
	}
	return info.Size() > deltaBytes
}

func ensureStore(store, tree string) bool {
	if _, err := os.Stat(filepath.Join(store, "HEAD")); err == nil {
		return true
	}
	if os.MkdirAll(store, 0o700) != nil {
		return false
	}
	if _, err := git(store, tree, nil, "init", "--quiet", "--initial-branch=deltas"); err != nil {
		return false
	}
	for _, setting := range [][2]string{
		{"user.name", "sysinit agent"},
		{"user.email", "agent@sysinit.invalid"},
		// A hook fires this commit with no terminal, so a signing prompt would hang it.
		{"commit.gpgsign", "false"},
		{"core.bare", "false"},
		{"core.hooksPath", filepath.Join(store, "hooks")},
	} {
		if _, err := git(store, tree, nil, "config", setting[0], setting[1]); err != nil {
			return false
		}
	}
	return true
}

func lockStore(store string) (func(), bool) {
	path := filepath.Join(store, "sysinit-delta.lock")
	deadline := time.Now().Add(lockWait)
	for {
		handle, err := os.OpenFile(path, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0o600)
		if err == nil {
			_ = handle.Close()
			return func() { _ = os.Remove(path) }, true
		}
		if info, statErr := os.Stat(path); statErr == nil && time.Since(info.ModTime()) > lockStale {
			_ = os.Remove(path)
			continue
		}
		if time.Now().After(deadline) {
			return nil, false
		}
		time.Sleep(25 * time.Millisecond)
	}
}

func git(store, tree string, stdin *strings.Reader, args ...string) (string, error) {
	cmd := exec.Command("git", args...)
	cmd.Dir = tree
	cmd.Env = repo.GitEnv(store, tree)
	if stdin != nil {
		cmd.Stdin = stdin
	}
	var out bytes.Buffer
	cmd.Stdout = &out
	if err := cmd.Run(); err != nil {
		return "", err
	}
	return strings.TrimSpace(out.String()), nil
}
