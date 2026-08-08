// Package diffnote implements the `diffnote` command: agent review notes on a
// working-tree diff, rendered by neovim's CodeDiff view.
//
// The on-disk format is fixed by lua/harness/diffnote.lua, which reads it. Every
// rejection here has a matching case in checks/diffnote-roundtrip.nix, which
// drives both halves.
package diffnote

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/nvimlink"
	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/repo"
	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/store"
)

const Summary = "agent review notes on a working-tree diff"

const usageText = `Agent review notes on a working-tree diff, rendered by neovim's CodeDiff view.

Usage:
  diffnote add --file <path> --line <n> --summary <text> [--rationale <text>] [--author <name>] [--replace] [--no-open]
  diffnote apply --stdin [--no-open]
  diffnote list [--file <path>] [--json]
  diffnote clear [--file <path>] [--yes]
  diffnote path

After a write, any neovim already sitting in this repository is asked to show
the diff view, so notes appear as they land. Pass --no-open, or set
DIFFNOTE_NO_OPEN=1, to write silently.
`

// Note is one anchored annotation. The field order is the serialized order, and
// the editor reads these names, so neither may be reordered casually.
type Note struct {
	File      string  `json:"file"`
	Line      int64   `json:"line"`
	Summary   string  `json:"summary"`
	Rationale *string `json:"rationale"`
	Author    string  `json:"author"`
}

// document is the store. Notes stay raw so an operation that does not read a
// note's contents cannot fail on one it did not write. `clear --yes` must
// succeed on a hand-authored store holding malformed notes, because clearing is
// the documented way out of exactly that state.
type document struct {
	Version int               `json:"version"`
	Repo    string            `json:"repo"`
	Notes   []json.RawMessage `json:"notes"`
}

// existing is the lenient view of a stored note, for the operations that do
// filter on contents. A scalar where an object belongs fails to decode, which
// is the shell original's behavior: its jq producer exited non-zero and
// published nothing.
type existing struct {
	File    *string      `json:"file"`
	Line    *json.Number `json:"line"`
	Summary *string      `json:"summary"`
	Author  *string      `json:"author"`
}

type fail struct{ msg string }

func (e *fail) Error() string { return e.msg }

func die(format string, args ...any) error {
	return &fail{msg: fmt.Sprintf(format, args...)}
}

// Run dispatches the subcommand and returns the process exit code.
func Run(args []string) int {
	if len(args) == 0 {
		fmt.Print(usageText)
		return 0
	}
	var err error
	switch args[0] {
	case "-h", "--help", "help":
		fmt.Print(usageText)
		return 0
	case "add":
		err = cmdAdd(args[1:])
	case "apply":
		err = cmdApply(args[1:], os.Stdin)
	case "list":
		err = cmdList(args[1:])
	case "clear":
		err = cmdClear(args[1:])
	case "path":
		err = cmdPath()
	default:
		err = die("unknown subcommand '%s'", args[0])
	}
	if err != nil {
		fmt.Fprintf(os.Stderr, "diffnote: %s\n", err)
		return 1
	}
	return 0
}

// takeValue reads the value of a flag that requires one.
//
// A flag with no value must say so. Under the shell original's errexit an
// unguarded shift exited silently, which reads to a caller as success.
func takeValue(args []string, i int, name string) (string, int, error) {
	if i+1 >= len(args) {
		return "", 0, die("%s needs a value", name)
	}
	return args[i+1], i + 2, nil
}

func marshal(doc *document) ([]byte, error) {
	out, err := json.MarshalIndent(doc, "", "  ")
	if err != nil {
		return nil, err
	}
	return append(out, '\n'), nil
}

// newStore builds the guarded store for root. The validator is the shape test
// the editor also applies: an object carrying a notes array.
func newStore(path, root string) *store.Store {
	return &store.Store{
		Path: path,
		Validate: store.JSONValidator(func(doc struct {
			Notes *[]json.RawMessage `json:"notes"`
		}) error {
			if doc.Notes == nil {
				return errors.New("no notes array")
			}
			return nil
		}),
		Initial: func() ([]byte, error) {
			return marshal(&document{Version: 1, Repo: root, Notes: []json.RawMessage{}})
		},
	}
}

func readDoc(s *store.Store) (*document, error) {
	data, err := s.Read()
	if err != nil {
		return nil, err
	}
	var doc document
	if err := json.Unmarshal(data, &doc); err != nil {
		return nil, err
	}
	if doc.Notes == nil {
		doc.Notes = []json.RawMessage{}
	}
	return &doc, nil
}

func publishDoc(s *store.Store, doc *document) error {
	data, err := marshal(doc)
	if err != nil {
		return err
	}
	return s.Publish(data)
}

func openStore() (*store.Store, string, error) {
	root, err := repo.Root()
	if err != nil {
		return nil, "", err
	}
	return newStore(repo.NoteFile(root), root), root, nil
}

func cmdPath() error {
	root, err := repo.Root()
	if err != nil {
		return err
	}
	fmt.Println(repo.NoteFile(root))
	return nil
}

// showNotes nudges a running editor, unless the caller opted out.
//
// Best effort and after the write, never before: the note is on disk whether or
// not an editor exists, and a caller in CI has none.
func showNotes(root string, suppressed bool) {
	if suppressed || os.Getenv("DIFFNOTE_NO_OPEN") == "1" {
		return
	}
	nvimlink.ShowNotes(root)
}

func cmdAdd(args []string) error {
	var file, line, summary, rationale string
	author := "agent"
	replace := false
	noOpen := false

	for i := 0; i < len(args); {
		var err error
		switch args[i] {
		case "--replace":
			replace, i = true, i+1
			continue
		case "--no-open":
			noOpen, i = true, i+1
			continue
		case "--file":
			file, i, err = takeValue(args, i, "--file")
		case "--line":
			line, i, err = takeValue(args, i, "--line")
		case "--summary":
			summary, i, err = takeValue(args, i, "--summary")
		case "--rationale":
			rationale, i, err = takeValue(args, i, "--rationale")
		case "--author":
			author, i, err = takeValue(args, i, "--author")
		default:
			return die("unknown argument for add: %s", args[i])
		}
		if err != nil {
			return err
		}
	}

	if file == "" {
		return die("add requires --file")
	}
	if store.HasControlBytes(file) {
		return die("--file must not contain a control byte")
	}
	if summary == "" {
		return die("add requires --summary")
	}
	// Emptiness is tested after stripping, not before. Validating first let a
	// summary of only control bytes land as a blank note, where `apply` refused
	// the same input.
	cleanSummary := store.OneLine(summary)
	if cleanSummary == "" {
		return die("--summary is empty once control bytes are removed")
	}
	parsed, err := parseLineArg(line)
	if err != nil {
		return err
	}

	s, root, err := openStore()
	if err != nil {
		return err
	}
	relative, err := repo.RelativeToRoot(root, file)
	if err != nil {
		return die("%s does not name a file inside %s", file, root)
	}

	note := Note{File: relative, Line: parsed, Summary: cleanSummary, Author: store.OneLine(author)}
	if rationale != "" {
		cleaned := store.Clean(rationale)
		note.Rationale = &cleaned
	}

	release, err := s.Lock()
	if err != nil {
		return err
	}
	defer release()

	doc, err := readDoc(s)
	if err != nil {
		return err
	}
	if replace {
		kept, err := dropMatching(doc.Notes, note)
		if err != nil {
			return err
		}
		doc.Notes = kept
	}
	encoded, err := json.Marshal(note)
	if err != nil {
		return err
	}
	doc.Notes = append(doc.Notes, encoded)
	if err := publishDoc(s, doc); err != nil {
		return err
	}
	release()
	fmt.Printf("diffnote: %s:%d\n", relative, parsed)
	showNotes(root, noOpen)
	return nil
}

// parseLineArg accepts only a bare positive integer.
//
// A leading zero is refused rather than normalized: `0123` reaches the store as
// 123, so the caller's line and the stored line differ with no diagnostic.
func parseLineArg(line string) (int64, error) {
	if line == "" {
		return 0, die("add requires --line")
	}
	if strings.ContainsFunc(line, func(r rune) bool { return r < '0' || r > '9' }) {
		return 0, die("--line must be a positive integer, got '%s'", line)
	}
	if strings.HasPrefix(line, "0") {
		return 0, die("--line must not carry a leading zero, got '%s'", line)
	}
	parsed, err := strconv.ParseInt(line, 10, 64)
	if err != nil {
		return 0, die("--line must be a positive integer, got '%s'", line)
	}
	return parsed, nil
}

func dropMatching(notes []json.RawMessage, note Note) ([]json.RawMessage, error) {
	kept := make([]json.RawMessage, 0, len(notes))
	for _, raw := range notes {
		var cur existing
		if err := json.Unmarshal(raw, &cur); err != nil {
			return nil, die("the store holds a note that is not an object; move it aside to start over")
		}
		same := cur.File != nil && *cur.File == note.File &&
			cur.Line != nil && cur.Line.String() == strconv.FormatInt(note.Line, 10) &&
			cur.Author != nil && *cur.Author == note.Author
		if !same {
			kept = append(kept, raw)
		}
	}
	return kept, nil
}

func cmdApply(args []string, stdin io.Reader) error {
	stdinFlag := false
	noOpen := false
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--stdin":
			stdinFlag = true
		case "--no-open":
			noOpen = true
		default:
			return die("unknown argument for apply: %s", args[i])
		}
	}
	if !stdinFlag {
		return die("apply reads its batch from stdin; pass --stdin")
	}

	s, root, err := openStore()
	if err != nil {
		return err
	}

	payload, err := io.ReadAll(stdin)
	if err != nil {
		return die("stdin is not valid JSON")
	}
	notes, err := normalizeBatch(payload)
	if err != nil {
		return err
	}

	// Resolution comes last and before the lock. Every rejection has to leave
	// the store byte-identical, and a repository with no store must still have
	// none once a bad batch is refused.
	for i := range notes {
		relative, err := repo.RelativeToRoot(root, notes[i].File)
		if err != nil {
			return die("a note names a path that is not a file inside %s", root)
		}
		notes[i].File = relative
	}

	release, err := s.Lock()
	if err != nil {
		return err
	}
	defer release()

	doc, err := readDoc(s)
	if err != nil {
		return err
	}
	for _, note := range notes {
		encoded, err := json.Marshal(note)
		if err != nil {
			return err
		}
		doc.Notes = append(doc.Notes, encoded)
	}
	if err := publishDoc(s, doc); err != nil {
		return err
	}
	release()
	fmt.Printf("diffnote: applied %d note(s)\n", len(notes))
	showNotes(root, noOpen)
	return nil
}

// normalizeBatch accepts both payload shapes and validates every item.
//
// Two shapes because the harness skills already emit hunk's (`filePath`,
// `newLine`) while this tool's own is (`file`, `line`). Neither side is going
// to change, so both are read.
func normalizeBatch(payload []byte) ([]Note, error) {
	decoder := json.NewDecoder(strings.NewReader(string(payload)))
	decoder.UseNumber()
	var envelope map[string]any
	if err := decoder.Decode(&envelope); err != nil {
		return nil, die("stdin is not valid JSON")
	}

	raw, ok := pick(envelope, "comments", "notes")
	if !ok {
		return nil, die("batch carried no notes")
	}
	items, ok := raw.([]any)
	if !ok {
		return nil, die("could not read the batch")
	}
	if len(items) == 0 {
		return nil, die("batch carried no notes")
	}

	notes := make([]Note, 0, len(items))
	for _, item := range items {
		fields, ok := item.(map[string]any)
		if !ok {
			return nil, die("could not read the batch")
		}
		note, err := normalizeItem(fields)
		if err != nil {
			return nil, err
		}
		notes = append(notes, note)
	}
	return notes, nil
}

// pick returns the first key present with a value that is neither null nor
// false, mirroring jq's `//` alternative operator.
func pick(m map[string]any, keys ...string) (any, bool) {
	for _, key := range keys {
		value, ok := m[key]
		if !ok || value == nil || value == false {
			continue
		}
		return value, true
	}
	return nil, false
}

func normalizeItem(fields map[string]any) (Note, error) {
	var note Note

	// An oldLine-only comment names the original side. Notes anchor on the
	// modified side, and silently re-anchoring one would attach it to whatever
	// text now occupies that row.
	lineValue, hasModified := pick(fields, "line", "newLine")
	if !hasModified {
		if _, hasOld := pick(fields, "oldLine"); hasOld {
			return note, die("a note names only oldLine. Notes anchor on the modified side; pass newLine.")
		}
		return note, die(fieldContract)
	}

	fileValue, _ := pick(fields, "file", "filePath")
	file, ok := fileValue.(string)
	if !ok || file == "" {
		return note, die(fieldContract)
	}

	number, ok := lineValue.(json.Number)
	if !ok {
		return note, die(fieldContract)
	}
	line, err := strconv.ParseInt(number.String(), 10, 64)
	if err != nil || line < 1 {
		return note, die(fieldContract)
	}

	summary, ok := fields["summary"].(string)
	if !ok || store.OneLine(summary) == "" {
		return note, die(fieldContract)
	}

	author := "agent"
	if value, ok := pick(fields, "author"); ok {
		author, ok = value.(string)
		if !ok {
			return note, die(fieldContract)
		}
	}

	if value, present := fields["rationale"]; present && value != nil {
		text, ok := value.(string)
		if !ok {
			return note, die(fieldContract)
		}
		cleaned := store.Clean(text)
		note.Rationale = &cleaned
	}

	// The path is rejected rather than cleaned. It must survive verbatim to
	// match a buffer, and a stripped path would key the note on something the
	// caller never named. A newline in it also forges a whole listing row.
	if store.HasControlBytes(file) {
		return note, die("a note's file contains a control byte")
	}

	note.File = file
	note.Line = line
	note.Summary = store.OneLine(summary)
	note.Author = store.OneLine(author)
	return note, nil
}

const fieldContract = "every item needs a string file, an integral line of 1 or more, " +
	"a non-empty summary, a string author, and a string or null rationale"

func cmdList(args []string) error {
	filter := ""
	asJSON := false
	for i := 0; i < len(args); {
		var err error
		switch args[i] {
		case "--json":
			asJSON, i = true, i+1
			continue
		case "--file":
			filter, i, err = takeValue(args, i, "--file")
		default:
			return die("unknown argument for list: %s", args[i])
		}
		if err != nil {
			return err
		}
	}

	s, root, err := openStore()
	if err != nil {
		return err
	}

	info, statErr := os.Stat(s.Path)
	if statErr != nil || info.Size() == 0 {
		if asJSON {
			// Same keys on the absent-store path as everywhere else, so a
			// consumer never has to branch on whether a store exists yet.
			data, err := marshal(&document{Version: 1, Repo: root, Notes: []json.RawMessage{}})
			if err != nil {
				return err
			}
			os.Stdout.Write(data)
		}
		return nil
	}

	doc, err := readDoc(s)
	if err != nil {
		return die("%s is not a valid note store", s.Path)
	}

	notes := doc.Notes
	if filter != "" {
		relative, err := repo.RelativeToRoot(root, filter)
		if err != nil {
			return die("%s does not name a file inside %s", filter, root)
		}
		notes, err = keepFile(doc.Notes, relative)
		if err != nil {
			return err
		}
	}

	if asJSON {
		data, err := marshal(&document{Version: 1, Repo: root, Notes: notes})
		if err != nil {
			return err
		}
		os.Stdout.Write(data)
		return nil
	}
	for _, raw := range notes {
		var cur existing
		if err := json.Unmarshal(raw, &cur); err != nil {
			continue
		}
		fmt.Printf("%s:%s  %s\n", orNull(cur.File), numberOrNull(cur.Line), store.OneLine(deref(cur.Summary)))
	}
	return nil
}

func orNull(s *string) string {
	if s == nil {
		return "null"
	}
	return *s
}

func deref(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}

func numberOrNull(n *json.Number) string {
	if n == nil {
		return "null"
	}
	return n.String()
}

func keepFile(notes []json.RawMessage, relative string) ([]json.RawMessage, error) {
	kept := make([]json.RawMessage, 0, len(notes))
	for _, raw := range notes {
		var cur existing
		if err := json.Unmarshal(raw, &cur); err != nil {
			return nil, die("the store holds a note that is not an object; move it aside to start over")
		}
		if cur.File != nil && *cur.File == relative {
			kept = append(kept, raw)
		}
	}
	return kept, nil
}

func cmdClear(args []string) error {
	filter := ""
	confirmed := false
	for i := 0; i < len(args); {
		var err error
		switch args[i] {
		case "--yes":
			confirmed, i = true, i+1
			continue
		case "--file":
			filter, i, err = takeValue(args, i, "--file")
		default:
			return die("unknown argument for clear: %s", args[i])
		}
		if err != nil {
			return err
		}
	}

	s, root, err := openStore()
	if err != nil {
		return err
	}
	// No store is success, not failure. This is a documented kill switch, and
	// the shell original returned the status of its own `-s` test here.
	info, statErr := os.Stat(s.Path)
	if statErr != nil || info.Size() == 0 {
		return nil
	}
	if _, err := readDoc(s); err != nil {
		return die("%s is not a valid note store", s.Path)
	}

	if filter == "" && !confirmed {
		return die("clearing every note needs --yes")
	}

	relative := ""
	if filter != "" {
		relative, err = repo.RelativeToRoot(root, filter)
		if err != nil {
			return die("%s does not name a file inside %s", filter, root)
		}
	}

	release, err := s.Lock()
	if err != nil {
		return err
	}
	defer release()

	doc, err := readDoc(s)
	if err != nil {
		return err
	}
	if relative != "" {
		kept := make([]json.RawMessage, 0, len(doc.Notes))
		for _, raw := range doc.Notes {
			var cur existing
			if err := json.Unmarshal(raw, &cur); err != nil {
				return die("the store holds a note that is not an object; move it aside to start over")
			}
			if cur.File == nil || *cur.File != relative {
				kept = append(kept, raw)
			}
		}
		doc.Notes = kept
	} else {
		doc.Notes = []json.RawMessage{}
	}
	if err := publishDoc(s, doc); err != nil {
		return err
	}
	release()

	if relative != "" {
		fmt.Printf("diffnote: cleared notes on %s\n", relative)
	} else {
		fmt.Println("diffnote: cleared every note")
	}
	return nil
}
