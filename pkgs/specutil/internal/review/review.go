// Package review carries a human verdict on a change back to the agent that
// wrote it.
//
// The browser page emits Feedback: a decision, a note, and per-task comments.
// `specutil review ingest` folds that into a Record stored next to the change,
// which fingerprints what was reviewed. Comparing the record's fingerprints to
// the current artifacts answers the two questions a reviewer always asks next:
// is this verdict still about the text I read, and which tasks did the agent
// touch since?
//
// Nothing here is time-based. Staleness is decided by content hash, so a repeat
// run over unchanged inputs produces byte-identical output, and a record stays
// meaningful after a checkout, a rebase, or a clone.
package review

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/roshbhatia/specutil/internal/ident"
	"github.com/roshbhatia/specutil/internal/ir"
	"gopkg.in/yaml.v3"
)

// Schema is the value the browser writes into a feedback document's schema
// field. Ingest rejects anything else rather than guessing at an unknown shape.
const Schema = "specutil.review/v1"

// RecordVersion is the on-disk schema version of the review record.
const RecordVersion = 1

// RecordFile is the review record's filename inside a change directory.
const RecordFile = "specutil.review.yaml"

// Decision is the reviewer's verdict on a change.
type Decision string

const (
	// DecisionApproved means the reviewer accepts the change as written.
	DecisionApproved Decision = "approved"
	// DecisionChangesRequested means the reviewer wants edits before it proceeds.
	DecisionChangesRequested Decision = "changes-requested"
	// DecisionCommented means the reviewer left notes without gating anything.
	DecisionCommented Decision = "commented"
)

// Decisions returns every accepted decision value, sorted.
func Decisions() []Decision {
	return []Decision{DecisionApproved, DecisionChangesRequested, DecisionCommented}
}

// Valid reports whether d is a decision this package accepts.
func (d Decision) Valid() bool {
	for _, v := range Decisions() {
		if d == v {
			return true
		}
	}
	return false
}

// Action is what the reviewer asked for on an annotated target.
type Action string

const (
	// ActionComment is a remark the author should read.
	ActionComment Action = "comment"
	// ActionDrop asks for the annotated task to be removed.
	ActionDrop Action = "drop"
)

// Annotation is one comment attached to a change, a task, or a diff hunk.
// Identity is the content-addressed handle of whatever it is attached to, which
// is what lets a comment survive the renumbering that follows almost every edit.
type Annotation struct {
	Scope    string `json:"scope"              yaml:"scope"`
	Phase    string `json:"phase,omitempty"    yaml:"phase,omitempty"`
	File     string `json:"file,omitempty"     yaml:"file,omitempty"`
	Identity string `json:"identity,omitempty" yaml:"identity,omitempty"`
	Text     string `json:"text,omitempty"     yaml:"text,omitempty"`
	Action   Action `json:"action,omitempty"   yaml:"action,omitempty"`
	Comment  string `json:"comment"            yaml:"comment"`
}

// The annotation scopes. A change annotation is the overall remark, a task
// annotation names a checkbox in tasks.md, and a hunk annotation names a run of
// changed lines in the working tree.
const (
	ScopeChange = "change"
	ScopeTask   = "task"
	ScopeHunk   = "hunk"
)

// Feedback is the document the browser page exports and `review ingest` reads.
type Feedback struct {
	Schema      string       `json:"schema"`
	Change      string       `json:"change"`
	Decision    Decision     `json:"decision"`
	Note        string       `json:"note,omitempty"`
	Annotations []Annotation `json:"annotations"`
}

// ItemState fingerprints one task as it read at review time.
type ItemState struct {
	Hash string `yaml:"hash"`
	Text string `yaml:"text,omitempty"`
}

// Record is the persisted verdict. Items is keyed by task identity so a task
// that was renumbered still matches, while Hash still flips when its wording
// changes.
type Record struct {
	Version    int      `yaml:"version"`
	Change     string   `yaml:"change"`
	Decision   Decision `yaml:"decision"`
	Note       string   `yaml:"note,omitempty"`
	ChangeHash string   `yaml:"change_hash"`
	// BaseCommit is the commit the working tree sat on when the decision was
	// recorded. It is what `review diff` compares against to show everything
	// that moved since, code included. Empty outside a git working tree.
	BaseCommit  string               `yaml:"base_commit,omitempty"`
	Items       map[string]ItemState `yaml:"items,omitempty"`
	Annotations []Annotation         `yaml:"annotations,omitempty"`
}

// RecordPath returns the review record path for a change.
func RecordPath(repoRoot, change string) string {
	return filepath.Join(repoRoot, "openspec", "changes", change, RecordFile)
}

// LoadRecord reads a change's review record. An absent file yields nil with no
// error: never having been reviewed is a state, not a failure.
func LoadRecord(repoRoot, change string) (*Record, error) {
	path := RecordPath(repoRoot, change)
	b, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, fmt.Errorf("reading %s: %w", path, err)
	}
	var r Record
	if err := yaml.Unmarshal(b, &r); err != nil {
		return nil, fmt.Errorf("parsing %s: %w", path, err)
	}
	if r.Version == 0 {
		r.Version = RecordVersion
	}
	return &r, nil
}

// LoadForChange reads the record sitting in a loaded change's own directory.
// It is the path a consumer holding an ir.Change (a check rule) can reach
// without knowing the repository layout. An absent record yields nil, nil.
func LoadForChange(c *ir.Change) (*Record, error) {
	if c == nil || c.Root == "" {
		return nil, nil
	}
	path := filepath.Join(c.Root, RecordFile)
	b, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, fmt.Errorf("reading %s: %w", path, err)
	}
	var r Record
	if err := yaml.Unmarshal(b, &r); err != nil {
		return nil, fmt.Errorf("parsing %s: %w", path, err)
	}
	if r.Version == 0 {
		r.Version = RecordVersion
	}
	return &r, nil
}

// Save writes the record back deterministically. yaml.v3 emits map keys sorted,
// so identical state produces identical bytes.
func (r *Record) Save(repoRoot, change string) error {
	path := RecordPath(repoRoot, change)
	b, err := yaml.Marshal(r)
	if err != nil {
		return fmt.Errorf("encoding review record: %w", err)
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return fmt.Errorf("creating change dir: %w", err)
	}
	return os.WriteFile(path, b, 0o644)
}

// ChangeHash fingerprints what a reviewer actually approved: the raw markdown of
// the artifacts that carry scope and intent, plus the shape of the task list. It
// deliberately does not fold in the raw bytes of tasks.md; see tasksScope.
func ChangeHash(c *ir.Change) string {
	if c == nil {
		return ""
	}
	var b strings.Builder
	write := func(name, raw string) {
		b.WriteString(name)
		b.WriteString("\x00")
		b.WriteString(raw)
		b.WriteString("\x00")
	}
	if c.Proposal != nil {
		write("proposal", c.Proposal.Raw)
	}
	if c.Design != nil {
		write("design", c.Design.Raw)
	}
	if c.Tasks != nil {
		write("tasks", tasksScope(c.Tasks))
	}
	specs := append([]*ir.Spec{}, c.Specs...)
	sort.SliceStable(specs, func(i, j int) bool { return specs[i].Capability < specs[j].Capability })
	for _, s := range specs {
		if s == nil {
			continue
		}
		write("spec/"+s.Capability, s.Raw)
	}
	return ident.Hash(b.String())
}

// tasksScope projects tasks.md down to the part a verdict is about: the phase
// structure and the identity of each task. It drops the raw bytes, the checkbox
// state, and every line indented under a task.
//
// Those are the record of the work rather than its scope, and they change on
// every step of it. Folding in the raw bytes made a verdict go stale for ticking
// a box or appending a finding, so the author had to re-stamp the decision to
// record progress. That re-stamp carries no judgement, and a gate that fires
// where no judgement is needed teaches people to clear it without reading.
//
// What still goes stale is what a reviewer would want to see again: adding a
// task, dropping one, resequencing phases, or rewording a task past what
// ident.Normalize absorbs.
func tasksScope(t *ir.Tasks) string {
	if t == nil {
		return ""
	}
	var b strings.Builder
	for _, p := range t.Phases {
		b.WriteString(ident.Normalize(p.Name))
		b.WriteString("\x00")
		for _, it := range p.Items {
			b.WriteString(ident.Identity(p.Name, it.Text))
			b.WriteString("\x00")
		}
	}
	return b.String()
}

// Snapshot fingerprints every task in a change, keyed by identity. A duplicate
// identity (the same wording twice in one phase) keeps its first occurrence,
// which is the same item as far as every other consumer is concerned.
func Snapshot(c *ir.Change) map[string]ItemState {
	out := map[string]ItemState{}
	if c == nil || c.Tasks == nil {
		return out
	}
	for _, p := range c.Tasks.Phases {
		for _, it := range p.Items {
			id := ident.Identity(p.Name, it.Text)
			if _, dup := out[id]; dup {
				continue
			}
			out[id] = ItemState{Hash: ident.ContentHash(it.Text), Text: it.Text}
		}
	}
	return out
}

// Drift classifies one task against the reviewed record.
const (
	// DriftNew means the task did not exist when the change was reviewed.
	DriftNew = "new"
	// DriftChanged means the task was reworded since it was reviewed.
	DriftChanged = "changed"
	// DriftUnchanged means the task reads exactly as it did at review time.
	DriftUnchanged = "unchanged"
)

// Match is how one current task lines up with the reviewed baseline. Prior is
// the baseline identity it was re-matched to after a reword, which is what lets
// a comment follow its task instead of vanishing when the author edits it.
type Match struct {
	Drift string
	Prior string
}

// MatchTasks aligns every current task against rec.
//
// An exact identity hit is the common case. When it misses, the task was either
// added or reworded past what the identity normalization absorbs, and those two
// are not the same event to a reviewer: a reworded task still carries the
// comment that was written about it. So an unmatched task is re-matched against
// the unclaimed baseline entries by token similarity, the same way the sync
// diff re-matches an edited item against an orphaned lock entry.
//
// A nil record yields an empty map. With no baseline, every task would classify
// as new, which says nothing.
func MatchTasks(c *ir.Change, rec *Record) map[string]Match {
	out := map[string]Match{}
	if rec == nil {
		return out
	}
	cur := Snapshot(c)

	claimed := map[string]bool{}
	var unmatched []string
	for id := range cur {
		prev, ok := rec.Items[id]
		if !ok {
			unmatched = append(unmatched, id)
			continue
		}
		claimed[id] = true
		if prev.Hash != cur[id].Hash {
			out[id] = Match{Drift: DriftChanged, Prior: id}
		} else {
			out[id] = Match{Drift: DriftUnchanged, Prior: id}
		}
	}

	orphans := make([]string, 0, len(rec.Items))
	for id := range rec.Items {
		if !claimed[id] {
			orphans = append(orphans, id)
		}
	}
	// Sorting both sides makes the greedy pairing a function of the inputs alone,
	// so two runs over the same repository agree.
	sort.Strings(unmatched)
	sort.Strings(orphans)

	used := map[string]bool{}
	for _, id := range unmatched {
		best, bestScore := "", ident.FuzzyThreshold
		for _, oid := range orphans {
			if used[oid] || rec.Items[oid].Text == "" {
				continue
			}
			if s := ident.Similarity(cur[id].Text, rec.Items[oid].Text); s > bestScore {
				best, bestScore = oid, s
			}
		}
		if best != "" {
			used[best] = true
			out[id] = Match{Drift: DriftChanged, Prior: best}
			continue
		}
		out[id] = Match{Drift: DriftNew}
	}
	return out
}

// DriftByIdentity classifies every current task against rec, discarding the
// re-match provenance. See MatchTasks.
func DriftByIdentity(c *ir.Change, rec *Record) map[string]string {
	out := map[string]string{}
	for id, m := range MatchTasks(c, rec) {
		out[id] = m.Drift
	}
	return out
}

// ItemStatus is one task's standing against the review record.
type ItemStatus struct {
	Identity string `json:"identity"`
	Phase    string `json:"phase"`
	Text     string `json:"text"`
	Drift    string `json:"drift,omitempty"`
	Comment  string `json:"comment,omitempty"`
	Action   Action `json:"action,omitempty"`
}

// HunkStatus is one standing comment on a run of changed lines.
type HunkStatus struct {
	Identity string `json:"identity"`
	File     string `json:"file"`
	Header   string `json:"header,omitempty"`
	Comment  string `json:"comment"`
	Action   Action `json:"action,omitempty"`
}

// Status is the full standing of a change against its review record: the
// verdict, whether that verdict still describes the current text, what drifted,
// and which comments are still attached.
type Status struct {
	Change      string       `json:"change"`
	Reviewed    bool         `json:"reviewed"`
	Decision    Decision     `json:"decision,omitempty"`
	Note        string       `json:"note,omitempty"`
	Stale       bool         `json:"stale"`
	ChangeHash  string       `json:"changeHash"`
	ReviewHash  string       `json:"reviewHash,omitempty"`
	BaseCommit  string       `json:"baseCommit,omitempty"`
	Items       []ItemStatus `json:"items"`
	Hunks       []HunkStatus `json:"hunks,omitempty"`
	Annotations []Annotation `json:"annotations,omitempty"`
	Dropped     []ItemStatus `json:"dropped,omitempty"`
}

// Gated reports whether the record blocks the change from proceeding: it was
// never reviewed, the verdict asked for edits, or the artifacts moved after the
// verdict was recorded.
func (s *Status) Gated() bool {
	return !s.Reviewed || s.Stale || s.Decision != DecisionApproved
}

// Build computes a change's standing against rec. rec may be nil.
func Build(c *ir.Change, rec *Record) *Status {
	st := &Status{
		Change:     c.Name,
		ChangeHash: ChangeHash(c),
		Items:      []ItemStatus{},
	}
	if rec != nil {
		st.Reviewed = true
		st.Decision = rec.Decision
		st.Note = rec.Note
		st.ReviewHash = rec.ChangeHash
		st.BaseCommit = rec.BaseCommit
		st.Stale = rec.ChangeHash != st.ChangeHash
		st.Annotations = rec.Annotations
	}

	comments := map[string]Annotation{}
	if rec != nil {
		for _, a := range rec.Annotations {
			switch {
			case a.Scope == ScopeTask && a.Identity != "":
				comments[a.Identity] = a
			case a.Scope == ScopeHunk && a.Identity != "":
				st.Hunks = append(st.Hunks, HunkStatus{
					Identity: a.Identity, File: a.File, Header: a.Text,
					Comment: a.Comment, Action: a.Action,
				})
			}
		}
	}

	matches := MatchTasks(c, rec)
	seen := map[string]bool{}
	if c.Tasks != nil {
		for _, p := range c.Tasks.Phases {
			for _, it := range p.Items {
				id := ident.Identity(p.Name, it.Text)
				if seen[id] {
					continue
				}
				seen[id] = true
				m := matches[id]
				is := ItemStatus{Identity: id, Phase: p.Name, Text: it.Text, Drift: m.Drift}
				// A comment written against the pre-edit wording still applies to the
				// task it was written about, so it follows the re-match.
				a, ok := comments[id]
				if !ok && m.Prior != "" {
					a, ok = comments[m.Prior]
				}
				if ok {
					is.Comment, is.Action = a.Comment, a.Action
				}
				st.Items = append(st.Items, is)
			}
		}
	}

	// A task the reviewer asked to drop, that is still present, is the one
	// unresolved item a summary must not bury.
	for _, is := range st.Items {
		if is.Action == ActionDrop {
			st.Dropped = append(st.Dropped, is)
		}
	}
	return st
}

// Apply folds feedback into a record describing the change as it reads now.
// The fingerprints come from the current artifacts, not from the feedback, so
// an author who edits between exporting and ingesting gets a record that is
// immediately reported as stale rather than one that silently blesses text
// nobody read. baseCommit may be empty outside a git working tree.
func ApplyAt(c *ir.Change, fb *Feedback, baseCommit string) *Record {
	rec := Apply(c, fb)
	rec.BaseCommit = baseCommit
	return rec
}

// Apply folds feedback into a record describing the change as it reads now.
// The fingerprints come from the current artifacts, not from the feedback, so
// an author who edits between exporting and ingesting gets a record that is
// immediately reported as stale rather than one that silently blesses text
// nobody read.
func Apply(c *ir.Change, fb *Feedback) *Record {
	anns := make([]Annotation, 0, len(fb.Annotations))
	for _, a := range fb.Annotations {
		if strings.TrimSpace(a.Comment) == "" && a.Action != ActionDrop {
			continue
		}
		if a.Scope == "" {
			a.Scope = ScopeTask
		}
		if a.Action == "" {
			a.Action = ActionComment
		}
		anns = append(anns, a)
	}
	sort.SliceStable(anns, func(i, j int) bool {
		if anns[i].Scope != anns[j].Scope {
			return anns[i].Scope < anns[j].Scope
		}
		return anns[i].Identity < anns[j].Identity
	})
	return &Record{
		Version:     RecordVersion,
		Change:      c.Name,
		Decision:    fb.Decision,
		Note:        strings.TrimSpace(fb.Note),
		ChangeHash:  ChangeHash(c),
		Items:       Snapshot(c),
		Annotations: anns,
	}
}

// Validate reports what is wrong with a feedback document before it is applied.
func (f *Feedback) Validate() error {
	if f.Schema != Schema {
		return fmt.Errorf("unsupported feedback schema %q; want %q", f.Schema, Schema)
	}
	if !f.Decision.Valid() {
		return fmt.Errorf("unknown decision %q; use one of: %s", f.Decision, joinDecisions())
	}
	for i, a := range f.Annotations {
		switch a.Scope {
		case ScopeChange, ScopeTask, ScopeHunk, "":
		default:
			return fmt.Errorf("annotation %d: unknown scope %q; use %s, %s, or %s",
				i, a.Scope, ScopeChange, ScopeTask, ScopeHunk)
		}
		if (a.Scope == ScopeTask || a.Scope == ScopeHunk) && a.Identity == "" {
			return fmt.Errorf("annotation %d: a %s annotation needs an identity", i, a.Scope)
		}
	}
	return nil
}

func joinDecisions() string {
	out := make([]string, 0, len(Decisions()))
	for _, d := range Decisions() {
		out = append(out, string(d))
	}
	return strings.Join(out, ", ")
}
