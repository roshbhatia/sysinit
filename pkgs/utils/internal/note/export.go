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

// publishExport writes the export for root from notes.
func publishExport(root string, notes []json.RawMessage) error {
	data, err := marshalExport(buildExport(notes))
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
	}
	if err := publishExport(root, notes); err != nil {
		return err
	}
	release()
	fmt.Printf("note: rebuilt %s\n", repo.ExportFile(root))
	return nil
}
