package note

import (
	"encoding/json"
	"fmt"

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/store"
)

func findID(notes []json.RawMessage, id string) (int, *existing, error) {
	for at, raw := range notes {
		var cur existing

		if json.Unmarshal(raw, &cur) != nil {
			continue
		}
		if cur.ID != nil && *cur.ID == id {
			return at, &cur, nil
		}
	}
	return 0, nil, die("no note is named %s. `note list --json` prints every id", id)
}

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

	s, err := openStore()
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
	beforeRelease()
	release()
	fmt.Printf("note: answered %s at %s:%d\n", id, reply.File, reply.Line)
	return nil
}

func clearOne(id string) error {
	s, err := openStore()
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

	if err := publishDoc(s, doc); err != nil {
		return err
	}
	beforeRelease()
	release()
	fmt.Printf("note: cleared %s\n", id)
	return nil
}
