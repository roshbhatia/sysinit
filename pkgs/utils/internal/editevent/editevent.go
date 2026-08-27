package editevent

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/repo"
)

const Summary = "record every agent write as an ordered delta, with the prompt that asked for it"

const SchemaVersion = 1

const (
	maxBytes  = 512 * 1024
	keepLines = 200
)

type event struct {
	Version int    `json:"version"`
	TS      int64  `json:"ts"`
	Harness string `json:"harness"`
	Kind    string `json:"kind"`
	File    string `json:"file"`
	CWD     string `json:"cwd"`
	Session string `json:"session,omitempty"`
	Delta   string `json:"delta,omitempty"`
}

func Run(args []string) int {
	opts, err := parse(args)
	if err != nil {
		fmt.Fprintf(os.Stderr, "edit-event: %v\n", err)
		return 0
	}

	if opts.printLog || opts.printDelta || opts.printTree {
		dir := opts.cwd
		if dir == "" {
			dir = workingDir()
		}
		root := repo.Workspace(dir)
		switch {
		case opts.printDelta:
			fmt.Println(repo.DeltaDir(root))
		case opts.printTree:
			fmt.Println(root)
		default:
			fmt.Println(repo.EditLogFile(root))
		}
		return 0
	}

	payload := readStdin()

	if opts.savePrompt {
		dir := opts.cwd
		if dir == "" {
			dir = dig(payload, "cwd")
		}
		if dir == "" {
			dir = workingDir()
		}
		savePrompt(
			repo.Workspace(dir),
			opts.harness,
			dig(payload, "session_id", "sessionId", "session"),
			dig(payload, "prompt", "user_prompt", "message", "text"),
		)
		return 0
	}

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

	kind := opts.kind
	if kind == "" {
		kind = strings.ToLower(dig(payload, "tool_name"))
	}
	if kind == "" {
		kind = "edit"
	}

	tree := repo.Workspace(dir)
	log := repo.EditLogFile(tree)
	if os.MkdirAll(filepath.Dir(log), 0o700) != nil {
		return 0
	}
	trim(log)

	session := dig(payload, "session_id", "sessionId", "session")
	asked := loadPrompt(tree)
	if asked.Harness != opts.harness {
		// Another harness asked for that one. Attributing this write to it would lie.
		asked = prompt{}
	}
	now := time.Now().UnixMilli()
	for _, c := range changes {
		absolute, err := absoluteIn(dir, c.file)
		if err != nil {
			continue
		}

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
			Session: session,
			Delta: recordDelta(tree, deltaMeta{
				harness: opts.harness,
				session: session,
				kind:    fileKind,
				file:    absolute,
				prompt:  asked,
			}),
		})
	}
	return 0
}

type change struct {
	file string
	kind string
}

var patchTextKeys = []string{
	"tool_input.command",
	"tool_input.patchText",
	"tool_input.patch_text",
	"output.args.patchText",
}

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

			if path = strings.TrimSpace(path); path != "" {
				out = append(out, change{file: path, kind: kind})
			}
			break
		}
	}
	return out
}

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
	printDelta bool
	printTree  bool
	applyPatch bool
	savePrompt bool
}

func parse(args []string) (options, error) {
	var opts options
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--print-log":
			opts.printLog = true
		case "--print-delta":
			opts.printDelta = true
		case "--print-workspace":
			opts.printTree = true
		case "--apply-patch":
			opts.applyPatch = true
		case "--prompt":
			opts.savePrompt = true
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

	if opts.harness == "" && !opts.printLog && !opts.printDelta && !opts.printTree {
		return opts, fmt.Errorf("the first argument names the harness")
	}
	return opts, nil
}

func append1(log string, e event) {
	encoded, err := json.Marshal(e)
	if err != nil {
		return
	}
	handle, err := os.OpenFile(log, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600)
	if err != nil {
		return
	}
	defer func() { _ = handle.Close() }()
	_, _ = handle.Write(append(encoded, '\n'))
}

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
		_ = os.Remove(temporary)
	}
}

func workingDir() string {
	dir, err := os.Getwd()
	if err != nil {
		return os.Getenv("PWD")
	}
	return dir
}

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
