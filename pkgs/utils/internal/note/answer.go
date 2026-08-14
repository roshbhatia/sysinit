// The two operations that name one note by its id: answering it, and removing it.
// Both need the note found and the record rewritten under a single lock, because a
// half-answered question is worse than an unanswered one.
package note

import (
	"encoding/json"
	"fmt"

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/store"
)

// findID returns the position of the note named by id.
func findID(notes []json.RawMessage, id string) (int, *existing, error) {
	for at, raw := range notes {
		var cur existing
		// A note this cannot read is a note that carries no id, so it is passed
		// over rather than made into an error the caller cannot act on.
		if json.Unmarshal(raw, &cur) != nil {
			continue
		}
		if cur.ID != nil && *cur.ID == id {
			return at, &cur, nil
		}
	}
	return 0, nil, die("no note is named %s. `note list --json` prints every id", id)
}

// setState rewrites one note's state, leaving every other field of it byte-identical.
func setState(raw json.RawMessage, state string) (json.RawMessage, error) {
	var fields map[string]json.RawMessage
	if err := json.Unmarshal(raw, &fields); err != nil {
		return nil, die("the store holds a note that is not an object; move it aside to start over")
	}
	encoded, err := json.Marshal(state)
	if err != nil {
		return nil, err
	}
	fields["state"] = encoded
	return json.Marshal(fields)
}

func cmdAnswer(args []string) error {
	var id, summary, rationale string
	author := "agent"

	for i := 0; i < len(args); {
		var err error
		switch args[i] {
		case "--id":
			id, i, err = takeValue(args, i, "--id")
		case "--summary":
			summary, i, err = takeValue(args, i, "--summary")
		case "--rationale":
			rationale, i, err = takeValue(args, i, "--rationale")
		case "--author":
			author, i, err = takeValue(args, i, "--author")
		default:
			return die("unknown argument for answer: %s", args[i])
		}
		if err != nil {
			return err
		}
	}

	if id == "" {
		return die("answer requires --id")
	}
	if summary == "" {
		return die("answer requires --summary")
	}
	cleanSummary := store.OneLine(summary)
	if cleanSummary == "" {
		return die("--summary is empty once control bytes are removed")
	}

	s, root, err := openStore()
	if err != nil {
		return err
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
	at, asked, err := findID(doc.Notes, id)
	if err != nil {
		return err
	}
	if asked.File == nil || asked.Line == nil {
		return die("the note named %s carries no file and line to answer on", id)
	}
	line, err := asked.Line.Int64()
	if err != nil {
		return die("the note named %s carries a line that is not a number", id)
	}

	replyID, err := newID()
	if err != nil {
		return err
	}
	reply := Note{
		ID:      replyID,
		File:    *asked.File,
		Line:    line,
		Summary: cleanSummary,
		Author:  store.OneLine(author),
		Origin:  originAgent,
		// The question's own anchor, not the file's line as it reads now: the answer
		// belongs beside the question wherever the question ends up.
		Anchor:  deref(asked.Anchor),
		ReplyTo: id,
	}
	if rationale != "" {
		cleaned := store.Clean(rationale)
		reply.Rationale = &cleaned
	}

	marked, err := setState(doc.Notes[at], stateAnswered)
	if err != nil {
		return err
	}
	doc.Notes[at] = marked

	encoded, err := json.Marshal(reply)
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
	fmt.Printf("note: answered %s at %s:%d\n", id, reply.File, reply.Line)
	return nil
}

// clearOne removes the note named by id, which is the only removal that cannot hit
// the wrong note when a file has moved under the record.
func clearOne(id string) error {
	s, root, err := openStore()
	if err != nil {
		return err
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
	at, _, err := findID(doc.Notes, id)
	if err != nil {
		return err
	}
	doc.Notes = append(doc.Notes[:at], doc.Notes[at+1:]...)

	if err := publishExport(root, doc.Notes); err != nil {
		return err
	}
	if err := publishDoc(s, doc); err != nil {
		return err
	}
	beforeRelease()
	release()
	fmt.Printf("note: cleared %s\n", id)
	return nil
}
