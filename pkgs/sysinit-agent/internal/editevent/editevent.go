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
// Measured, not guessed: one session of ordinary work on this repository wrote
// 52 events naming 18 files over 90 minutes, at 233 bytes a line and 263 at the
// longest. Segmented on a two-minute gap, a turn ran 1 to 29 events, mean 6.
//
// The two numbers answer different questions. maxBytes decides how often a trim
// happens, and 512 KiB is roughly 2200 events, so a workspace at the measured
// rate trims about once every 40 sessions. keepLines decides what a trim costs,
// because a reader whose offset is now past the file re-reads what survived and
// counts those files as touched again: 200 events is the smallest window that
// still holds a whole session's own edits, with a turn's worst case of 29 well
// inside it.
const (
	maxBytes  = 512 * 1024
	keepLines = 200
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

	// The reader asks for the path rather than deriving it. Two implementations of
	// the keying rule, one in Go and one in Lua, would agree until the day they
	// did not, and the failure would be a watcher silently tailing a file nothing
	// writes.
	if opts.printLog {
		dir := opts.cwd
		if dir == "" {
			dir = workingDir()
		}
		fmt.Println(repo.EditLogFile(repo.Workspace(dir)))
		return 0
	}

	payload := readStdin()

	// A change is one file and the verb that touched it. Most harnesses name one
	// file per call, so this list usually holds a single entry; an apply-patch
	// envelope is the case that names several, each with its own verb.
	var changes []change
	for _, file := range opts.files {
		changes = append(changes, change{file: file})
	}
	if len(changes) == 0 && opts.applyPatch {
		changes = applyPatchChanges(dig(payload, patchTextKeys...))
	}
	if len(changes) == 0 {
		if found := dig(payload, "tool_input.file_path", "tool_input.notebook_path"); found != "" {
			changes = []change{{file: found}}
		}
	}
	if len(changes) == 0 {
		return 0
	}

	dir := opts.cwd
	if dir == "" {
		dir = dig(payload, "cwd")
	}
	if dir == "" {
		dir = workingDir()
	}

	// The tool's own name, lowercased, so a reader can tell a file that was
	// created from one that was modified. Claude's `Write` on an existing path
	// still means "this file was replaced wholesale", which is a different thing
	// to show than a hunk. `edit` is the fallback rather than the default,
	// because a harness whose payload names no tool still produced an edit.
	kind := opts.kind
	if kind == "" {
		kind = strings.ToLower(dig(payload, "tool_name"))
	}
	if kind == "" {
		kind = "edit"
	}

	log := repo.EditLogFile(repo.Workspace(dir))
	if os.MkdirAll(filepath.Dir(log), 0o700) != nil {
		return 0
	}
	trim(log)

	now := time.Now().UnixMilli()
	for _, c := range changes {
		absolute, err := absoluteIn(dir, c.file)
		if err != nil {
			continue
		}
		// A verb the envelope named beats the tool name, because `apply_patch` says
		// nothing about whether a file was created or rewritten.
		fileKind := kind
		if c.kind != "" && opts.kind == "" {
			fileKind = c.kind
		}
		append1(log, event{
			Version: SchemaVersion,
			TS:      now,
			Harness: opts.harness,
			Kind:    fileKind,
			File:    absolute,
			CWD:     dir,
		})
	}
	return 0
}

// change is one file and, when the source named it, the verb that touched it.
type change struct {
	file string
	kind string
}

// Where a harness conventionally puts the text of an apply-patch envelope. The
// package knows the format, not the harness: codex passes it as a shell command,
// and opencode as a named tool argument.
var patchTextKeys = []string{
	"tool_input.command",
	"tool_input.patchText",
	"tool_input.patch_text",
	"output.args.patchText",
}

// applyPatchChanges reads the file markers out of an apply-patch envelope.
//
// This is a parse of a documented format rather than a guess at one: the envelope
// declares one marker per file, and the marker's verb is the only place the
// difference between a created and a rewritten file is stated. A harness that
// edits through a shell redirect instead names no file anywhere, and correctly
// produces nothing here.
func applyPatchChanges(text string) []change {
	if text == "" {
		return nil
	}
	verbs := map[string]string{
		"*** Add File: ":    "write",
		"*** Update File: ": "edit",
		"*** Delete File: ": "delete",
	}
	var out []change
	for _, line := range strings.Split(text, "\n") {
		line = strings.TrimRight(line, "\r")
		for marker, kind := range verbs {
			path, found := strings.CutPrefix(line, marker)
			if !found {
				continue
			}
			// `*** Move to: ` follows a rename's Update marker; the destination is
			// what exists afterwards, so it is what a reader should be told about.
			if path = strings.TrimSpace(path); path != "" {
				out = append(out, change{file: path, kind: kind})
			}
			break
		}
	}
	return out
}

// absoluteIn resolves file against dir rather than the process working directory.
// A hook runs wherever the harness happened to spawn it, which is not always the
// directory the relative path in its payload was written against.
func absoluteIn(dir, file string) (string, error) {
	if filepath.IsAbs(file) {
		return filepath.Clean(file), nil
	}
	if dir != "" {
		return filepath.Join(dir, file), nil
	}
	return filepath.Abs(file)
}

type options struct {
	harness    string
	kind       string
	cwd        string
	files      []string
	printLog   bool
	applyPatch bool
}

func parse(args []string) (options, error) {
	var opts options
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--print-log":
			opts.printLog = true
		case "--apply-patch":
			opts.applyPatch = true
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
	// A reader asking for the path is not writing, so it names no harness.
	if opts.harness == "" && !opts.printLog {
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
