package note

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/repo"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/store"
)

const Summary = "agent review notes on a working-tree diff"

const usageText = `Agent review notes on a working-tree diff. Read them with ` + "`review`" + `.

Usage:
  note add --file <path> --line <n> --summary <text> [--rationale <text>] [--author <name>] [--origin agent|user] [--replace]
  note answer --id <id> --summary <text> [--rationale <text>] [--author <name>]
  note apply --stdin
  note list [--file <path>] [--open] [--json]
  note clear [--id <id>] [--file <path>] [--line <n>] [--yes]
  note path [--export]
  note rebuild

` + "`--origin`" + ` says who wrote the note rather than what they are called: an agent
writes ` + "`agent`" + `, which is the default, and a person writes ` + "`user`" + `. A reader
draws the two differently, so it is not inferred from the author's name.

A note the owner writes is ` + "`open`" + ` until it is answered. ` + "`answer`" + ` files the
reply beside it and marks it answered in one write, and ` + "`list --open`" + ` is what
is still waiting.

Every note carries an id and the text of the line it was written against. A
reader re-anchors on that text, so a note follows its line through later edits;
the record itself is never renumbered. Name the id to remove or answer exactly
one note.

` + "`clear --line`" + ` removes the notes on one line and needs ` + "`--file`" + `. Without
` + "`--line`" + ` it removes every note in that file, and without ` + "`--file`" + ` it removes
every note in the repository, which needs ` + "`--yes`" + `.

A write never opens a viewer. It publishes the record and the viewer-shaped
export derived from it, so the next ` + "`review`" + ` shows the note. A ` + "`review`" + ` that
is already running does not: it was measured and it picks up nothing on its own,
` + "`--watch`" + ` included. Re-run it. Run ` + "`note rebuild`" + ` after hand-editing the
record, which is the one route that changes it without going through a write.
`

type Note struct {
	ID        string  `json:"id"`
	File      string  `json:"file"`
	Line      int64   `json:"line"`
	Summary   string  `json:"summary"`
	Rationale *string `json:"rationale"`
	Author    string  `json:"author"`

	Origin string `json:"origin"`

	Anchor string `json:"anchor,omitempty"`

	State string `json:"state,omitempty"`

	ReplyTo string `json:"reply_to,omitempty"`
}

const (
	originAgent = "agent"
	originUser  = "user"

	stateOpen     = "open"
	stateAnswered = "answered"
)

func cleanOrigin(value string) (string, error) {
	switch strings.TrimSpace(value) {
	case "", originAgent:
		return originAgent, nil
	case originUser:
		return originUser, nil
	default:
		return "", die("--origin takes agent or user, got '%s'", value)
	}
}

type document struct {
	Version int               `json:"version"`
	Repo    string            `json:"repo"`
	Notes   []json.RawMessage `json:"notes"`
}

type existing struct {
	ID      *string      `json:"id"`
	File    *string      `json:"file"`
	Line    *json.Number `json:"line"`
	Summary *string      `json:"summary"`
	Author  *string      `json:"author"`
	Origin  *string      `json:"origin"`
	Anchor  *string      `json:"anchor"`
	State   *string      `json:"state"`
}

type fail struct{ msg string }

func (e *fail) Error() string { return e.msg }

func die(format string, args ...any) error {
	return &fail{msg: fmt.Sprintf(format, args...)}
}

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
	case "answer":
		err = cmdAnswer(args[1:])
	case "apply":
		err = cmdApply(args[1:], os.Stdin)
	case "list":
		err = cmdList(args[1:])
	case "clear":
		err = cmdClear(args[1:])
	case "path":
		err = cmdPath(args[1:])
	case "rebuild":
		err = cmdRebuild(args[1:])
	default:
		err = die("unknown subcommand '%s'", args[0])
	}
	if err != nil {
		fmt.Fprintf(os.Stderr, "note: %s\n", err)
		return 1
	}
	return 0
}

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

func cmdPath(args []string) error {
	export := false
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--export":
			export = true
		default:
			return die("unknown argument for path: %s", args[i])
		}
	}
	root, err := repo.Root()
	if err != nil {
		return err
	}
	if export {
		fmt.Println(repo.ExportFile(root))
		return nil
	}
	fmt.Println(repo.NoteFile(root))
	return nil
}

func cmdAdd(args []string) error {
	var file, line, summary, rationale, origin string
	author := "agent"
	replace := false

	for i := 0; i < len(args); {
		var err error
		switch args[i] {
		case "--replace":
			replace, i = true, i+1
			continue
		case "--origin":
			origin, i, err = takeValue(args, i, "--origin")
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
	cleanSummary := store.OneLine(summary)
	if cleanSummary == "" {
		return die("--summary is empty once control bytes are removed")
	}
	parsed, err := parseLineArg(line)
	if err != nil {
		return err
	}
	written, err := cleanOrigin(origin)
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

	id, err := newID()
	if err != nil {
		return err
	}
	note := Note{
		ID:      id,
		File:    relative,
		Line:    parsed,
		Summary: cleanSummary,
		Author:  store.OneLine(author),
		Origin:  written,
		Anchor:  captureAnchor(root, relative, parsed),
	}

	if written == originUser {
		note.State = stateOpen
	}
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
	if err := publishExport(root, doc.Notes); err != nil {
		return err
	}
	beforeRelease()
	release()
	fmt.Printf("note: %s:%d\n", relative, parsed)
	return nil
}

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
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--stdin":
			stdinFlag = true
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

	for i := range notes {
		relative, err := repo.RelativeToRoot(root, notes[i].File)
		if err != nil {
			return die("a note names a path that is not a file inside %s", root)
		}
		notes[i].File = relative
		notes[i].ID, err = newID()
		if err != nil {
			return err
		}
		notes[i].Anchor = captureAnchor(root, relative, notes[i].Line)
		if notes[i].Origin == originUser {
			notes[i].State = stateOpen
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
	if err := publishExport(root, doc.Notes); err != nil {
		return err
	}
	beforeRelease()
	release()
	fmt.Printf("note: applied %d note(s)\n", len(notes))
	return nil
}

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

	origin := ""
	if value, present := fields["origin"]; present && value != nil {
		origin, ok = value.(string)
		if !ok {
			return note, die(fieldContract)
		}
	}
	written, err := cleanOrigin(origin)
	if err != nil {
		return note, err
	}

	if store.HasControlBytes(file) {
		return note, die("a note's file contains a control byte")
	}

	note.File = file
	note.Line = line
	note.Summary = store.OneLine(summary)
	note.Author = store.OneLine(author)
	note.Origin = written
	return note, nil
}

const fieldContract = "every item needs a string file, an integral line of 1 or more, " +
	"a non-empty summary, a string author, and a string or null rationale"

func cmdList(args []string) error {
	filter := ""
	asJSON := false
	openOnly := false
	forHook := false
	for i := 0; i < len(args); {
		var err error
		switch args[i] {
		case "--json":
			asJSON, i = true, i+1
			continue
		case "--open":
			openOnly, i = true, i+1
			continue
		case "--hook":
			forHook, openOnly, i = true, true, i+1
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
		if forHook {
			return nil
		}
		return err
	}

	info, statErr := os.Stat(s.Path)
	if statErr != nil || info.Size() == 0 {
		if asJSON {
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
		if forHook {
			return nil
		}
		return die("%s is not a valid note store", s.Path)
	}

	notes := reanchor(root, doc.Notes)
	if filter != "" {
		relative, err := repo.RelativeToRoot(root, filter)
		if err != nil {
			return die("%s does not name a file inside %s", filter, root)
		}
		notes, err = keepFile(notes, relative)
		if err != nil {
			return err
		}
	}
	if openOnly {
		notes = keepOpen(notes)
	}

	if forHook {
		reportOpen(notes)
		return nil
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

func keepOpen(notes []json.RawMessage) []json.RawMessage {
	kept := make([]json.RawMessage, 0, len(notes))
	for _, raw := range notes {
		var cur existing
		if err := json.Unmarshal(raw, &cur); err != nil {
			continue
		}
		if cur.State != nil && *cur.State == stateOpen {
			kept = append(kept, raw)
		}
	}
	return kept
}

func reportOpen(notes []json.RawMessage) {
	if len(notes) == 0 {
		return
	}
	fmt.Printf("The owner left %d note(s) on the diff waiting for an answer.\n", len(notes))
	for _, raw := range notes {
		var cur existing
		if err := json.Unmarshal(raw, &cur); err != nil {
			continue
		}
		fmt.Printf("  [%s] %s:%s  %s\n",
			orNull(cur.ID), orNull(cur.File), numberOrNull(cur.Line), store.OneLine(deref(cur.Summary)))
	}
	fmt.Print("Read the code each one names, then answer it with `utils note answer --id <id> --summary <text>`.\n")
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
	line := ""
	id := ""
	confirmed := false
	for i := 0; i < len(args); {
		var err error
		switch args[i] {
		case "--yes":
			confirmed, i = true, i+1
			continue
		case "--file":
			filter, i, err = takeValue(args, i, "--file")
		case "--line":
			line, i, err = takeValue(args, i, "--line")
		case "--id":
			id, i, err = takeValue(args, i, "--id")
		default:
			return die("unknown argument for clear: %s", args[i])
		}
		if err != nil {
			return err
		}
	}

	if id != "" {
		if filter != "" || line != "" {
			return die("--id names one note on its own; drop --file and --line")
		}
		return clearOne(id)
	}

	var only int64
	if line != "" {
		if filter == "" {
			return die("clearing one line needs --file")
		}
		parsed, err := parseLineArg(line)
		if err != nil {
			return err
		}
		only = parsed
	}

	s, root, err := openStore()
	if err != nil {
		return err
	}
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
			match := cur.File != nil && *cur.File == relative
			if match && only != 0 {
				match = cur.Line != nil && cur.Line.String() == strconv.FormatInt(only, 10)
			}
			if !match {
				kept = append(kept, raw)
			}
		}
		doc.Notes = kept
	} else {
		doc.Notes = []json.RawMessage{}
	}
	if err := publishExport(root, doc.Notes); err != nil {
		return err
	}
	if err := publishDoc(s, doc); err != nil {
		return err
	}
	beforeRelease()
	release()

	if relative != "" && only != 0 {
		fmt.Printf("note: cleared notes on %s:%d\n", relative, only)
	} else if relative != "" {
		fmt.Printf("note: cleared notes on %s\n", relative)
	} else {
		fmt.Println("note: cleared every note")
	}
	return nil
}
