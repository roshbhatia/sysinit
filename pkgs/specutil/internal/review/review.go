package review

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/specutil/internal/ident"
	"github.com/roshbhatia/sysinit/pkgs/specutil/internal/ir"
	"gopkg.in/yaml.v3"
)

const Schema = "specutil.review/v1"

const RecordVersion = 2

const hashComparableFrom = 2

const RecordFile = "specutil.review.yaml"

type Decision string

const (
	DecisionApproved Decision = "approved"

	DecisionChangesRequested Decision = "changes-requested"

	DecisionCommented Decision = "commented"
)

func Decisions() []Decision {
	return []Decision{DecisionApproved, DecisionChangesRequested, DecisionCommented}
}

func (d Decision) Valid() bool {
	for _, v := range Decisions() {
		if d == v {
			return true
		}
	}
	return false
}

type Action string

const (
	ActionComment Action = "comment"

	ActionDrop Action = "drop"
)

type Annotation struct {
	Scope    string `json:"scope"              yaml:"scope"`
	Phase    string `json:"phase,omitempty"    yaml:"phase,omitempty"`
	File     string `json:"file,omitempty"     yaml:"file,omitempty"`
	Identity string `json:"identity,omitempty" yaml:"identity,omitempty"`
	Text     string `json:"text,omitempty"     yaml:"text,omitempty"`
	Action   Action `json:"action,omitempty"   yaml:"action,omitempty"`
	Comment  string `json:"comment"            yaml:"comment"`
}

const (
	ScopeChange = "change"
	ScopeTask   = "task"
	ScopeHunk   = "hunk"
)

type Feedback struct {
	Schema      string       `json:"schema"`
	Change      string       `json:"change"`
	Decision    Decision     `json:"decision"`
	Note        string       `json:"note,omitempty"`
	Annotations []Annotation `json:"annotations"`
}

type ItemState struct {
	Hash string `yaml:"hash"`
	Text string `yaml:"text,omitempty"`
}

type Record struct {
	Version    int      `yaml:"version"`
	Change     string   `yaml:"change"`
	Decision   Decision `yaml:"decision"`
	Note       string   `yaml:"note,omitempty"`
	ChangeHash string   `yaml:"change_hash"`

	BaseCommit  string               `yaml:"base_commit,omitempty"`
	Items       map[string]ItemState `yaml:"items,omitempty"`
	Annotations []Annotation         `yaml:"annotations,omitempty"`
}

func RecordPath(repoRoot, change string) string {
	return filepath.Join(repoRoot, "openspec", "changes", change, RecordFile)
}

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
		r.Version = 1
	}
	return &r, nil
}

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
		r.Version = 1
	}
	return &r, nil
}

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

const (
	DriftNew = "new"

	DriftChanged = "changed"

	DriftUnchanged = "unchanged"
)

type Match struct {
	Drift string
	Prior string
}

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

type ItemStatus struct {
	Identity string `json:"identity"`
	Phase    string `json:"phase"`
	Text     string `json:"text"`
	Drift    string `json:"drift,omitempty"`
	Comment  string `json:"comment,omitempty"`
	Action   Action `json:"action,omitempty"`
}

type HunkStatus struct {
	Identity string `json:"identity"`
	File     string `json:"file"`
	Header   string `json:"header,omitempty"`
	Comment  string `json:"comment"`
	Action   Action `json:"action,omitempty"`
}

type Status struct {
	Change   string   `json:"change"`
	Reviewed bool     `json:"reviewed"`
	Decision Decision `json:"decision,omitempty"`
	Note     string   `json:"note,omitempty"`
	Stale    bool     `json:"stale"`

	HashRetired bool         `json:"hashRetired,omitempty"`
	ChangeHash  string       `json:"changeHash"`
	ReviewHash  string       `json:"reviewHash,omitempty"`
	BaseCommit  string       `json:"baseCommit,omitempty"`
	Items       []ItemStatus `json:"items"`
	Hunks       []HunkStatus `json:"hunks,omitempty"`
	Annotations []Annotation `json:"annotations,omitempty"`
	Dropped     []ItemStatus `json:"dropped,omitempty"`
}

func (s *Status) Gated() bool {
	return !s.Reviewed || s.Stale || s.Decision != DecisionApproved
}

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
		st.HashRetired = rec.Version < hashComparableFrom
		st.Stale = !st.HashRetired && rec.ChangeHash != st.ChangeHash
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

	for _, is := range st.Items {
		if is.Action == ActionDrop {
			st.Dropped = append(st.Dropped, is)
		}
	}
	return st
}

func ApplyAt(c *ir.Change, fb *Feedback, baseCommit string) *Record {
	rec := Apply(c, fb)
	rec.BaseCommit = baseCommit
	return rec
}

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
