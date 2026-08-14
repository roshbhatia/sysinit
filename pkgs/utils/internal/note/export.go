package note

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"strconv"

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/repo"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/store"
)

// The export is the record rendered in the viewer's own schema.

// derivedMarker tells an owner who opens this file that editing it is pointless.
const derivedMarker = "Derived from the sysinit note record. Every note write rewrites this file, so edit the record instead: utils note path"

// exportDoc is the sidecar root.
type exportDoc struct {
	Version int          `json:"version"`
	Summary string       `json:"summary"`
	Files   []exportFile `json:"files"`
}

type exportFile struct {
	Path        string             `json:"path"`
	Annotations []exportAnnotation `json:"annotations"`
}

// exportAnnotation carries every field the record holds that the sidecar has a
type exportAnnotation struct {
	Summary   string   `json:"summary"`
	Rationale *string  `json:"rationale,omitempty"`
	Author    string   `json:"author,omitempty"`
	NewRange  [2]int64 `json:"newRange"`
}

// stored is the lenient view of a record note for the export builder.
type stored struct {
	File      *string      `json:"file"`
	Line      *json.Number `json:"line"`
	Summary   *string      `json:"summary"`
	Rationale *string      `json:"rationale"`
	Author    *string      `json:"author"`
}

// newExportStore gives the export the record's publishing discipline.
func newExportStore(path string) *store.Store {
	return &store.Store{
		Path: path,
		Validate: store.JSONValidator(func(doc struct {
			Files *[]json.RawMessage `json:"files"`
		}) error {
			if doc.Files == nil {
				return errors.New("no files array")
			}
			return nil
		}),
		Initial: func() ([]byte, error) {
			return marshalExport(&exportDoc{Version: 1, Summary: derivedMarker, Files: []exportFile{}})
		},
	}
}

func marshalExport(doc *exportDoc) ([]byte, error) {
	out, err := json.MarshalIndent(doc, "", "  ")
	if err != nil {
		return nil, err
	}
	return append(out, '\n'), nil
}

// buildExport renders notes into the sidecar shape.
func buildExport(notes []json.RawMessage) *exportDoc {
	doc := &exportDoc{Version: 1, Summary: derivedMarker, Files: []exportFile{}}
	index := map[string]int{}
	for _, raw := range notes {
		var cur stored
		if err := json.Unmarshal(raw, &cur); err != nil {
			continue
		}
		if cur.File == nil || *cur.File == "" || cur.Summary == nil {
			continue
		}
		summary := store.OneLine(*cur.Summary)
		if summary == "" {
			continue
		}
		line := int64(0)
		if cur.Line != nil {
			parsed, err := strconv.ParseInt(cur.Line.String(), 10, 64)
			if err != nil {
				continue
			}
			line = parsed
		}
		if line < 1 {
			continue
		}
		annotation := exportAnnotation{Summary: summary, NewRange: [2]int64{line, line}}
		if cur.Rationale != nil {
			annotation.Rationale = cur.Rationale
		}
		if cur.Author != nil {
			annotation.Author = store.OneLine(*cur.Author)
		}
		at, seen := index[*cur.File]
		if !seen {
			doc.Files = append(doc.Files, exportFile{Path: *cur.File, Annotations: []exportAnnotation{}})
			at = len(doc.Files) - 1
			index[*cur.File] = at
		}
		doc.Files[at].Annotations = append(doc.Files[at].Annotations, annotation)
	}
	return doc
}

// publishExport writes the export for root from notes. Re-anchored first, so the
// viewer opens on the line each note is on now rather than the line it was written
// against.
func publishExport(root string, notes []json.RawMessage) error {
	data, err := marshalExport(buildExport(reanchor(root, notes)))
	if err != nil {
		return err
	}
	return newExportStore(repo.ExportFile(root)).Publish(data)
}

// beforeRelease runs immediately before each explicit release, with the store
var beforeRelease = func() {}

func cmdRebuild(args []string) error {
	if len(args) > 0 {
		return die("unknown argument for rebuild: %s", args[0])
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

	notes := []json.RawMessage{}
	if info, statErr := os.Stat(s.Path); statErr == nil && info.Size() > 0 {
		doc, err := readDoc(s)
		if err != nil {
			return die("%s is not a valid note store", s.Path)
		}
		notes = doc.Notes
		// A note written by hand, or written before the record carried ids and
		// anchors, has neither. Filling them in is repair, which is what this
		// command is for, and it is the only route that writes them after the fact.
		filled, changed, err := backfill(root, notes)
		if err != nil {
			return err
		}
		if changed > 0 {
			doc.Notes = filled
			notes = filled
			if err := publishDoc(s, doc); err != nil {
				return err
			}
			fmt.Printf("note: named %d note(s) that carried no id\n", changed)
		}
	}
	if err := publishExport(root, notes); err != nil {
		return err
	}
	release()
	fmt.Printf("note: rebuilt %s\n", repo.ExportFile(root))
	return nil
}

// backfill gives every note an id, and an anchor read from the line it currently
// names. Returns the notes and how many it had to touch.
func backfill(root string, notes []json.RawMessage) ([]json.RawMessage, int, error) {
	filled := make([]json.RawMessage, 0, len(notes))
	changed := 0
	for _, raw := range notes {
		var cur existing
		var fields map[string]json.RawMessage
		// A note this cannot read crosses untouched. Repair is not the place to
		// refuse a record: `rebuild` is what the owner runs when the record is
		// already in a state nothing else accepts.
		if json.Unmarshal(raw, &cur) != nil || json.Unmarshal(raw, &fields) != nil {
			filled = append(filled, raw)
			continue
		}
		if cur.ID != nil && *cur.ID != "" && cur.Anchor != nil {
			filled = append(filled, raw)
			continue
		}
		if cur.ID == nil || *cur.ID == "" {
			id, err := newID()
			if err != nil {
				return nil, 0, err
			}
			encoded, err := json.Marshal(id)
			if err != nil {
				return nil, 0, err
			}
			fields["id"] = encoded
		}
		if cur.Anchor == nil && cur.File != nil && cur.Line != nil {
			line, err := cur.Line.Int64()
			if err == nil {
				anchor := captureAnchor(root, *cur.File, line)
				if anchor != "" {
					encoded, err := json.Marshal(anchor)
					if err != nil {
						return nil, 0, err
					}
					fields["anchor"] = encoded
				}
			}
		}
		rewritten, err := json.Marshal(fields)
		if err != nil {
			return nil, 0, err
		}
		filled = append(filled, rewritten)
		changed++
	}
	return filled, changed, nil
}
