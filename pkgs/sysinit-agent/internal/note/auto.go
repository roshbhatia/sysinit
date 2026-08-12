// Auto-derived notes: `note auto <harness>` reads a PostToolUse payload and
// writes one note from what the harness had already said about the edit.
//
// The alternative was to ask the model to run `note add` itself. That was tried
// and it does not hold: the instruction competes with the task for attention, a
// note appears for the edits the model happens to narrate, and a review then
// shows notes on three files out of nine and reads as though the other six were
// unexamined. Reading the words the model already wrote needs nothing from the
// model at all.
//
// Nothing here invents a note. When the transcript holds no narration for the
// turn, this writes nothing, because a box that says less than the diff is worse
// than no box.
package note

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"unicode"

	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/repo"
	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/store"
)

// How much of the transcript's tail to read.
//
// A transcript grows without bound: this session's own file is 21k lines. The
// narration for the edit that just fired the hook is the last assistant text in
// the file, so only the tail can matter, and 1 MiB holds the last several turns
// even when one of them wrote a whole file through a single tool call.
const transcriptTail = 1 << 20

// What a note carries. The summary is one line under a diff hunk, so it holds a
// sentence; the rationale is the paragraph under it and is bounded to keep a
// virtual-line box from covering the code it annotates.
const (
	maxSummary   = 160
	maxRationale = 600
)

// autoRun writes one note and ALWAYS returns 0.
//
// Every failure is silent, for the reason editevent's is: this runs on a
// harness's edit path, so a non-zero exit or a word on stdout surfaces inside the
// agent's loop as though the tool call had failed. `--explain` is the debugging
// route, and it is the only mode that prints or reports a reason.
func autoRun(args []string, stdin io.Reader) int {
	harness := ""
	explain := false
	for _, arg := range args {
		switch {
		case arg == "--explain":
			explain = true
		case strings.HasPrefix(arg, "-"), harness != "":
			if explain {
				fmt.Fprintf(os.Stderr, "note auto: unexpected argument %s\n", arg)
			}
			return 0
		default:
			harness = arg
		}
	}
	if harness == "" || strings.ContainsAny(harness, "/ ") {
		if explain {
			fmt.Fprint(os.Stderr, "note auto: the first argument names the harness\n")
		}
		return 0
	}

	reason, err := autoWrite(harness, stdin, explain)
	if explain {
		if err != nil {
			fmt.Fprintf(os.Stderr, "note auto: %s\n", err)
			return 1
		}
		fmt.Println(reason)
	}
	return 0
}

// autoPayload is the subset of a PostToolUse payload this reads.
//
// `tool_response` is held raw because its type is the tool's, not the hook's: an
// edit answers with an object and other tools answer with a string, and a typed
// field would fail the whole decode on the string and lose the file path with it.
type autoPayload struct {
	ToolName       string `json:"tool_name"`
	Cwd            string `json:"cwd"`
	TranscriptPath string `json:"transcript_path"`
	ToolInput      struct {
		FilePath     string `json:"file_path"`
		NotebookPath string `json:"notebook_path"`
		NewString    string `json:"new_string"`
		Content      string `json:"content"`
	} `json:"tool_input"`
	ToolResponse json.RawMessage `json:"tool_response"`
}

// hunk is one changed region on the modified side, which is the side a note
// anchors to. The lines carry a diff's leading space, plus, or minus.
type hunk struct {
	NewStart int64    `json:"newStart"`
	NewLines int64    `json:"newLines"`
	Lines    []string `json:"lines"`
}

// firstChangedLine returns the line the edit actually changed.
//
// Not `newStart`: a hunk opens with three lines of context, so anchoring on it put
// the note three lines above the change. Measured on a live edit that appended to
// a README, where the note landed on line 38 and the new text was on line 41.
//
// A deletion does not advance the modified side, so a hunk that only removes lines
// anchors on the line that now sits where they were.
func (h hunk) firstChangedLine() int64 {
	line := h.NewStart
	for _, text := range h.Lines {
		if text == "" {
			continue
		}
		switch text[0] {
		case '+':
			return line
		case '-':
			return line
		default:
			line++
		}
	}
	return h.NewStart
}

func autoWrite(harness string, stdin io.Reader, explain bool) (string, error) {
	data, err := io.ReadAll(stdin)
	if err != nil || len(data) == 0 {
		return "", die("no payload on stdin")
	}
	var event autoPayload
	if err := json.Unmarshal(data, &event); err != nil {
		return "", die("payload is not valid JSON")
	}

	file := event.ToolInput.FilePath
	if file == "" {
		file = event.ToolInput.NotebookPath
	}
	if file == "" {
		return "", die("payload names no file")
	}
	if !filepath.IsAbs(file) {
		if event.Cwd == "" {
			return "", die("payload names a relative file and no cwd")
		}
		file = filepath.Join(event.Cwd, file)
	}
	file = filepath.Clean(file)
	if store.HasControlBytes(file) {
		return "", die("file contains a control byte")
	}

	// The repository holding the file, not the one holding the hook's working
	// directory. An agent started at a workspace root edits several repositories
	// under it, and a note filed against the wrong root renders nowhere.
	root, err := repo.RootAt(filepath.Dir(file))
	if err != nil {
		return "", die("%s is not inside a git repository", file)
	}
	relative, err := repo.RelativeToRoot(root, file)
	if err != nil {
		return "", die("%s does not name a file inside %s", file, root)
	}

	text := narration(event.TranscriptPath, event.ToolName, file)
	if text == "" {
		return "", die("the transcript holds no narration for this edit")
	}
	summary, rationale := split(text)
	if summary == "" {
		return "", die("narration is empty once control bytes are removed")
	}

	start, end := anchor(event, file)
	author := harness + " (auto)"
	note := Note{File: relative, Line: start, Summary: summary, Author: store.OneLine(author)}
	if rationale != "" {
		note.Rationale = &rationale
	}

	if explain {
		preview, err := json.MarshalIndent(struct {
			Root string `json:"root"`
			Note Note   `json:"note"`
			End  int64  `json:"replaces_through_line"`
		}{root, note, end}, "", "  ")
		if err != nil {
			return "", err
		}
		return string(preview), nil
	}

	s := newStore(repo.NoteFile(root), root)
	release, err := s.Lock()
	if err != nil {
		return "", err
	}
	defer release()

	doc, err := readDoc(s)
	if err != nil {
		return "", err
	}
	kept, err := dropOverlapping(doc.Notes, note.File, note.Author, start, end)
	if err != nil {
		return "", err
	}
	encoded, err := json.Marshal(note)
	if err != nil {
		return "", err
	}
	doc.Notes = append(kept, encoded)
	if err := publishDoc(s, doc); err != nil {
		return "", err
	}
	if err := publishExport(root, doc.Notes); err != nil {
		return "", err
	}
	beforeRelease()
	release()
	return fmt.Sprintf("note: %s:%d", note.File, note.Line), nil
}

// anchor returns the first changed region on the modified side, as a line and the
// last line of that region.
//
// The patch the tool reports is the authority, because it counts the lines the
// edit actually moved. Searching the file for the replacement text is the
// fallback for a harness that reports no patch, and it can only find the first
// occurrence: an edit that inserts a line already present elsewhere anchors to
// the earlier copy. That is wrong by a hunk rather than wrong by a file, and the
// note still lands in the diff.
func anchor(event autoPayload, file string) (int64, int64) {
	var response struct {
		StructuredPatch []hunk `json:"structuredPatch"`
	}
	if json.Unmarshal(event.ToolResponse, &response) == nil && len(response.StructuredPatch) > 0 {
		first := response.StructuredPatch[0]
		if first.NewStart >= 1 {
			// The region is the whole hunk, context included, because it is what a
			// later pass over the same code should replace. The anchor is narrower.
			end := first.NewStart + first.NewLines - 1
			if end < first.NewStart {
				end = first.NewStart
			}
			return first.firstChangedLine(), end
		}
	}

	needle := event.ToolInput.NewString
	if needle == "" {
		needle = event.ToolInput.Content
	}
	if needle == "" {
		return 1, 1
	}
	body, err := os.ReadFile(file)
	if err != nil {
		return 1, 1
	}
	added := strings.Split(strings.ReplaceAll(needle, "\r\n", "\n"), "\n")
	var probe string
	for _, line := range added {
		if strings.TrimSpace(line) != "" {
			probe = line
			break
		}
	}
	if probe == "" {
		return 1, 1
	}
	for i, line := range strings.Split(string(body), "\n") {
		if strings.TrimRight(line, "\r") == strings.TrimRight(probe, "\r") {
			start := int64(i + 1)
			return start, start + int64(len(added)) - 1
		}
	}
	return 1, 1
}

// narration returns the harness's own words about the tool call it just made.
//
// The text and the tool call usually arrive in one assistant message, with the
// text first, so the search starts at the message that made this call and walks
// back to the nearest text. Walking back matters: a harness that narrates a plan
// and then makes three calls writes the text once, and all three edits belong to
// it.
//
// The shape read here is one JSON object per line with `type` and
// `message.content`, which is claude's. A harness that writes a different shape
// decodes to nothing and files no note, so wiring this hook into one is a
// no-op rather than a wrong note.
func narration(path, toolName, file string) string {
	if path == "" {
		return ""
	}
	lines, err := tailLines(path)
	if err != nil {
		return ""
	}

	type block struct {
		Type  string `json:"type"`
		Text  string `json:"text"`
		Name  string `json:"name"`
		Input struct {
			FilePath     string `json:"file_path"`
			NotebookPath string `json:"notebook_path"`
		} `json:"input"`
	}
	type row struct {
		Type    string `json:"type"`
		Message struct {
			// Raw, because a user turn carries a string here and an assistant turn
			// carries an array. Typing it as either loses the other.
			Content json.RawMessage `json:"content"`
		} `json:"message"`
	}

	blocksAt := func(i int) []block {
		var parsed row
		if json.Unmarshal([]byte(lines[i]), &parsed) != nil || parsed.Type != "assistant" {
			return nil
		}
		var blocks []block
		if json.Unmarshal(parsed.Message.Content, &blocks) != nil {
			return nil
		}
		return blocks
	}

	// Where to start walking back from: the message that made this very call.
	// Without it the last assistant text is still the current turn's narration,
	// because the hook fires within the turn that wrote it.
	from := len(lines) - 1
	for i := len(lines) - 1; i >= 0; i-- {
		found := false
		for _, b := range blocksAt(i) {
			if b.Type != "tool_use" {
				continue
			}
			if toolName != "" && b.Name != toolName {
				continue
			}
			target := b.Input.FilePath
			if target == "" {
				target = b.Input.NotebookPath
			}
			if target != "" && filepath.Clean(target) != file {
				continue
			}
			found = true
			break
		}
		if found {
			from = i
			break
		}
	}

	for i := from; i >= 0; i-- {
		for j := len(blocksAt(i)) - 1; j >= 0; j-- {
			b := blocksAt(i)[j]
			if b.Type == "text" && strings.TrimSpace(b.Text) != "" {
				return b.Text
			}
		}
	}
	return ""
}

// tailLines returns the transcript's last whole lines, newest last.
//
// The first line of the window is dropped whenever the file is longer than the
// window, because a read that starts mid-file starts mid-line and a half-decoded
// record is not a record.
func tailLines(path string) ([]string, error) {
	handle, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer handle.Close()
	info, err := handle.Stat()
	if err != nil {
		return nil, err
	}
	offset := int64(0)
	truncated := false
	if info.Size() > transcriptTail {
		offset = info.Size() - transcriptTail
		truncated = true
	}
	if _, err := handle.Seek(offset, io.SeekStart); err != nil {
		return nil, err
	}
	body, err := io.ReadAll(handle)
	if err != nil {
		return nil, err
	}
	lines := strings.Split(strings.TrimRight(string(body), "\n"), "\n")
	if truncated && len(lines) > 0 {
		lines = lines[1:]
	}
	return lines, nil
}

// split turns narration into a one-line summary and the rest.
//
// The first sentence is the summary because that is where a harness states what
// it did; the paragraphs after it are why. Markdown decoration is stripped rather
// than rendered: the note is drawn as virtual lines in a buffer, and a literal
// `**` there is noise.
func split(text string) (string, string) {
	cleaned := undecorate(text)
	head, tail := firstSentence(cleaned)
	summary := store.OneLine(head)
	if summary == "" {
		return "", ""
	}
	summary = clip(summary, maxSummary)
	rationale := store.Clean(strings.TrimSpace(tail))
	if rationale != "" {
		rationale = clip(rationale, maxRationale)
	}
	return summary, rationale
}

// undecorate removes the markdown a harness writes for a chat pane.
func undecorate(text string) string {
	var out []string
	fenced := false
	for _, line := range strings.Split(text, "\n") {
		trimmed := strings.TrimSpace(line)
		// A fenced block is dropped whole, markers and body alike: it is code the
		// diff is already showing, and dropping only the markers left the code in
		// the note with nothing to mark it as a quotation.
		if strings.HasPrefix(trimmed, "```") {
			fenced = !fenced
			continue
		}
		if fenced {
			continue
		}
		trimmed = strings.TrimPrefix(trimmed, "- ")
		trimmed = strings.TrimPrefix(trimmed, "* ")
		trimmed = strings.ReplaceAll(trimmed, "**", "")
		trimmed = strings.ReplaceAll(trimmed, "`", "")
		out = append(out, trimmed)
	}
	return strings.TrimSpace(strings.Join(out, "\n"))
}

// firstSentence splits on the first terminator followed by a space, a newline, or
// the end of the text. A terminator inside a version number or a file name is
// followed by neither, so it does not split.
func firstSentence(text string) (string, string) {
	runes := []rune(text)
	for i, r := range runes {
		if r != '.' && r != '!' && r != '?' {
			continue
		}
		if i+1 >= len(runes) {
			return text, ""
		}
		next := runes[i+1]
		if next == ' ' || next == '\n' || next == '\t' {
			return string(runes[:i+1]), string(runes[i+1:])
		}
	}
	return text, ""
}

// clip shortens to limit runes on a word boundary, marking that it did.
func clip(text string, limit int) string {
	runes := []rune(text)
	if len(runes) <= limit {
		return text
	}
	cut := limit
	for cut > 0 && !unicode.IsSpace(runes[cut]) {
		cut--
	}
	if cut == 0 {
		cut = limit
	}
	return strings.TrimRight(string(runes[:cut]), " \t") + "…"
}

// dropOverlapping removes this author's earlier notes on the same file inside the
// region the new note covers.
//
// Anchored on the region rather than on the file, so two edits far apart in one
// file keep two notes and two passes over the same lines keep one. A file edited
// in ten places during a change is reviewed better with ten notes than with the
// last one.
func dropOverlapping(notes []json.RawMessage, file, author string, start, end int64) ([]json.RawMessage, error) {
	kept := make([]json.RawMessage, 0, len(notes))
	for _, raw := range notes {
		var cur existing
		if err := json.Unmarshal(raw, &cur); err != nil {
			return nil, die("the store holds a note that is not an object; move it aside to start over")
		}
		overlaps := false
		if cur.File != nil && *cur.File == file && cur.Author != nil && *cur.Author == author && cur.Line != nil {
			if line, err := strconv.ParseInt(cur.Line.String(), 10, 64); err == nil {
				overlaps = line >= start && line <= end
			}
		}
		if !overlaps {
			kept = append(kept, raw)
		}
	}
	return kept, nil
}
