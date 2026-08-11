// Package editevent implements `edit-event`: one append-only log per workspace
// naming the files an agent wrote, for an editor that wants to know without
// polling.
//
// Nothing in this package knows what reads the log, and nothing that reads it
// knows which harness wrote a line. That is the point: a hook writes whether or
// not an editor is running, and the reader is optional.
package editevent

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/repo"
)

const Summary = "record the files an agent wrote, for an editor watching the log"

// SchemaVersion is the event line's schema version.
const SchemaVersion = 1

// The log's bound. Past maxBytes the writer keeps the newest keepLines and drops
// the rest, which is the same truncation the reader must already survive.
//
// Placeholder values. Task 6.1 of `add-agent-edit-bus` replaces them with
// numbers measured from a real turn; until then they are large enough that a
// long turn is not evicted and small enough that the file stays cheap to read
// from a Lua watcher.
const (
	maxBytes  = 256 * 1024
	keepLines = 500
)

// event is one line of the log. It carries no file contents on purpose: the file
// on disk is the content, and a copy here would go stale the moment it is
// written.
type event struct {
	Version int    `json:"version"`
	TS      int64  `json:"ts"`
	Harness string `json:"harness"`
	Kind    string `json:"kind"`
	File    string `json:"file"`
	CWD     string `json:"cwd"`
}

// Run appends one event per named file and ALWAYS returns 0.
//
// Every failure is silent. This runs on a harness's edit path, so a non-zero
// exit or a word on stdout would surface inside the agent's loop as though the
// tool call itself had failed. There is nothing the agent could do about it
// either way.
func Run(args []string) int {
	opts, err := parse(args)
	if err != nil {
		// The one loud failure, and only for a caller that is malformed rather
		// than unlucky. A hook's arguments come from a Nix expression, so a
		// mistake here is a build-time mistake worth seeing once.
		fmt.Fprintf(os.Stderr, "edit-event: %v\n", err)
		return 0
	}

	payload := readStdin()
	files := opts.files
	if len(files) == 0 {
		if found := dig(payload, "tool_input.file_path", "tool_input.notebook_path"); found != "" {
			files = []string{found}
		}
	}
	if len(files) == 0 {
		return 0
	}

	dir := opts.cwd
	if dir == "" {
		dir = dig(payload, "cwd")
	}
	if dir == "" {
		dir = workingDir()
	}

	kind := opts.kind
	if kind == "" {
		kind = "edit"
	}

	log := repo.EditLogFile(repo.Workspace(dir))
	if os.MkdirAll(filepath.Dir(log), 0o700) != nil {
		return 0
	}
	trim(log)

	now := time.Now().UnixMilli()
	for _, file := range files {
		absolute, err := filepath.Abs(file)
		if err != nil {
			continue
		}
		append1(log, event{
			Version: SchemaVersion,
			TS:      now,
			Harness: opts.harness,
			Kind:    kind,
			File:    absolute,
			CWD:     dir,
		})
	}
	return 0
}

type options struct {
	harness string
	kind    string
	cwd     string
	files   []string
}

func parse(args []string) (options, error) {
	var opts options
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--file", "--kind", "--cwd":
			name := args[i]
			if i+1 >= len(args) {
				return opts, fmt.Errorf("%s needs a value", name)
			}
			i++
			switch name {
			case "--file":
				if args[i] != "" {
					opts.files = append(opts.files, args[i])
				}
			case "--kind":
				opts.kind = args[i]
			case "--cwd":
				opts.cwd = args[i]
			}
		default:
			if strings.HasPrefix(args[i], "-") {
				return opts, fmt.Errorf("unknown flag %s", args[i])
			}
			if opts.harness != "" {
				return opts, fmt.Errorf("harness is already %q, got a second one %q", opts.harness, args[i])
			}
			opts.harness = args[i]
		}
	}
	if opts.harness == "" {
		return opts, fmt.Errorf("the first argument names the harness")
	}
	return opts, nil
}

// append1 writes one line in one Write call, so two harnesses writing at the
// same moment produce two intact lines rather than one interleaved pair. O_APPEND
// is what makes the offset safe; the single call is what keeps the bytes
// contiguous.
func append1(log string, e event) {
	encoded, err := json.Marshal(e)
	if err != nil {
		return
	}
	handle, err := os.OpenFile(log, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600)
	if err != nil {
		return
	}
	defer handle.Close()
	handle.Write(append(encoded, '\n'))
}

// trim enforces the bound before an append rather than after, so the log is never
// observed past it. Rewriting through a temporary file and renaming means a
// reader either sees the old file or the new one, never a half-written log.
func trim(log string) {
	info, err := os.Stat(log)
	if err != nil || info.Size() <= maxBytes {
		return
	}
	body, err := os.ReadFile(log)
	if err != nil {
		return
	}
	lines := strings.Split(strings.TrimRight(string(body), "\n"), "\n")
	if len(lines) <= keepLines {
		return
	}
	kept := strings.Join(lines[len(lines)-keepLines:], "\n") + "\n"

	temporary := log + ".trim"
	if os.WriteFile(temporary, []byte(kept), 0o600) != nil {
		return
	}
	if os.Rename(temporary, log) != nil {
		os.Remove(temporary)
	}
}

func workingDir() string {
	dir, err := os.Getwd()
	if err != nil {
		return os.Getenv("PWD")
	}
	return dir
}

// readStdin returns the hook payload, or nothing when stdin is a terminal.
func readStdin() map[string]any {
	info, err := os.Stdin.Stat()
	if err != nil || info.Mode()&os.ModeCharDevice != 0 {
		return nil
	}
	data, err := io.ReadAll(os.Stdin)
	if err != nil || len(data) == 0 {
		return nil
	}
	var parsed map[string]any
	if json.Unmarshal(data, &parsed) != nil {
		return nil
	}
	return parsed
}

// dig walks a dotted path and returns the first non-empty string it finds.
func dig(doc map[string]any, keys ...string) string {
	for _, key := range keys {
		var cur any = doc
		ok := true
		for _, part := range strings.Split(key, ".") {
			node, isMap := cur.(map[string]any)
			if !isMap {
				ok = false
				break
			}
			cur, ok = node[part]
			if !ok {
				break
			}
		}
		if !ok {
			continue
		}
		if text, isString := cur.(string); isString && text != "" {
			return text
		}
	}
	return ""
}
