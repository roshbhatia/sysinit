package note

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"strconv"

	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/repo"
	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/store"
)

// The export is the record rendered in the viewer's own schema. It is derived,
// never authored: every write republishes it from the record it just published,
// so the record stays the single owner of a note.
//
// The shape is `hunk diff --agent-context`, read by loadAgentContext in
// src/core/agent.ts. `path` and `summary` are the only required fields, and an
// unknown key is dropped rather than refused. Probed at 0.18.0; the change's
// hunk-probe.md records the whole schema.

// derivedMarker tells an owner who opens this file that editing it is pointless.
//
// It rides in `summary`, a field the viewer's parser reads and displays, and not
// in a key of our own. JSON carries no comment, and an unknown key is silently
// dropped by that parser, so a marker in one would be invisible on the only
// surface an owner is likely to be looking at.
const derivedMarker = "Derived from the sysinit note record. Every note write rewrites this file, so edit the record instead: sysinit-agent note path"

// exportDoc is the sidecar root. `files` orders the review, so it follows the
// record's own order rather than a sort.
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
// home for. `rationale` is a plain string there, so a multi-line rationale
// crosses intact and nothing has to be flattened.
type exportAnnotation struct {
	Summary   string   `json:"summary"`
	Rationale *string  `json:"rationale,omitempty"`
	Author    string   `json:"author,omitempty"`
	NewRange  [2]int64 `json:"newRange"`
}

// stored is the lenient view of a record note for the export builder. It is
// separate from `existing` because the export needs the rationale and a number
// the sidecar can hold, and `existing` deliberately reads neither.
type stored struct {
	File      *string      `json:"file"`
	Line      *json.Number `json:"line"`
	Summary   *string      `json:"summary"`
	Rationale *string      `json:"rationale"`
	Author    *string      `json:"author"`
}

// newExportStore gives the export the record's publishing discipline.
//
// Not os.WriteFile: Publish validates before the rename and refuses a symlink,
// and a bare write could leave the zero-byte state store.go:85-100 exists to
// prevent. The validator is the viewer's own precondition, a files array,
// because publishing a document the viewer refuses is the silent failure this
// export exists to avoid.
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
//
// A note it cannot read is skipped, not repaired and not fatal. The record is
// the owner's to hand-edit (store.go:27-29), and `clear --yes` is the documented
// way out of a malformed one, so a single bad note must not make the export
// unbuildable. Skipping only ever omits; it never shows a note the record does
// not hold.
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
		// The sidecar refuses a line below 1 outright rather than clamping it,
		// so a note that never had a usable line is dropped here instead of
		// making the whole export unloadable.
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
// lock still held.
//
// It is bound only by tests, which use it to assert that the export on disk
// already equals a rebuild from the record at that moment. Bound to the explicit
// call the assertion is deterministic: no other writer is in the critical
// section. Bound to the deferred release it would also fire at function return
// with the lock dropped, where another process may have moved the record, so it
// would fail on correct work.
var beforeRelease = func() {}

func cmdRebuild(args []string) error {
	if len(args) > 0 {
		return die("unknown argument for rebuild: %s", args[0])
	}
	s, root, err := openStore()
	if err != nil {
		return err
	}

	// The same lock the writers take. Without it a rebuild can read the record,
	// lose a race to a concurrent `add`, and publish an export derived from the
	// pre-add state. That is the lost update TestConcurrentAddsLoseNoNote catches
	// for the record and nothing else catches for the export.
	release, err := s.Lock()
	if err != nil {
		return err
	}
	defer release()

	// An absent or zero-byte record rebuilds to an empty export rather than
	// failing. `clear --yes` returns early on exactly that state, so a rebuild
	// that refused it could not repair the export clear stranded.
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
