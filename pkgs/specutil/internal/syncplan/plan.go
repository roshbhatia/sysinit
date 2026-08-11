package syncplan

import (
	"fmt"
	"sort"

	"github.com/roshbhatia/specutil/internal/export"
	"github.com/roshbhatia/specutil/internal/ir"
	"github.com/roshbhatia/specutil/internal/render"
)

// Item is a plannable unit derived from a change. For ticketing targets the
// units are tasks; the abstraction leaves room for document-level items later.
type Item struct {
	Identity    string
	ContentHash string
	// Title is the reader-facing ticket title: no task number, no discipline
	// keyword.
	Title string
	// Milestone is the reader-facing delivery stage name, with no leading
	// number.
	Milestone string
	// Position is the 1-based order across the whole change. Trackers sort on
	// it; readers never see it as text.
	Position int
	// Labels are the tracker labels derived from the stage, the task kind, and
	// the author's bracket tags.
	Labels []string
}

// TaskItems projects a change's tasks into plannable items. Identity is built
// from the phase name and the raw task text (renumber-stable); ContentHash
// fingerprints the exact raw text for drift detection. Everything else is the
// export projection, so no source numbering reaches a tracker.
func TaskItems(change *ir.Change) []Item {
	if change == nil || change.Tasks == nil {
		return nil
	}
	var items []Item
	for _, t := range export.BuildChange(change).Tickets() {
		items = append(items, Item{
			Identity:    Identity(t.SourceGroup, t.SourceText),
			ContentHash: ContentHash(t.SourceText),
			Title:       t.Title,
			Milestone:   t.Milestone,
			Position:    t.Position,
			Labels:      t.Labels,
		})
	}
	return items
}

// OpKind is a planned operation against the target system.
type OpKind string

const (
	OpCreate OpKind = "create"
	OpUpdate OpKind = "update"
	OpOrphan OpKind = "orphan"
)

// Operation is a single create/update/orphan instruction. ExternalID is set for
// update and orphan (the existing remote object). Every other field is the
// ready-to-write projection of the local source: no task numbers, no phase
// numbers, no spec keywords.
type Operation struct {
	Kind        OpKind   `json:"kind"`
	Identity    string   `json:"identity"`
	ExternalID  string   `json:"externalId,omitempty"`
	ContentHash string   `json:"contentHash,omitempty"`
	Title       string   `json:"title,omitempty"`
	Milestone   string   `json:"milestone,omitempty"`
	Position    int      `json:"position,omitempty"`
	Labels      []string `json:"labels,omitempty"`
	Body        string   `json:"body,omitempty"`
}

// BuildPlanOptions carries optional configuration for BuildPlan.
type BuildPlanOptions struct {
	// TemplateOverrideDir is passed to the render engine for ticket body
	// rendering. Empty means use the embedded default.
	TemplateOverrideDir string
}

// Plan is the deterministic, network-free projection of items against a lock.
// Change is the repository-local slug and stays a correlation key; Title and
// Summary are what an external reader should see on the containing project,
// milestone, or page.
type Plan struct {
	Change  string `json:"change"`
	Title   string `json:"title"`
	Summary string `json:"summary,omitempty"`
	// Overview is the ready-to-write Markdown body for the container the target
	// groups tickets under: a Linear project, a GitHub milestone, or a Notion
	// page. It carries the acceptance criteria once.
	Overview   string      `json:"overview,omitempty"`
	Target     string      `json:"target"`
	Milestones []string    `json:"milestones,omitempty"`
	Operations []Operation `json:"operations"`
	Warnings   []string    `json:"warnings,omitempty"`
}

// BuildPlan diffs current items against the lock namespace for target and emits
// create/update/orphan operations. It performs no network I/O.
//
//   - identity absent from lock                -> create
//   - identity present, content hash differs   -> update (carries external ID)
//   - identity present, content hash unchanged  -> no operation (in sync)
//   - lock identity with no current item       -> orphan
func BuildPlan(change *ir.Change, lock *Lock, target string) Plan {
	plan, _ := BuildPlanWithOptions(change, lock, target, BuildPlanOptions{})
	return plan
}

// BuildPlanWithOptions is the full form of BuildPlan with optional configuration.
// It returns an error only when the github-issues body template fails to render;
// partial success is not possible — either all bodies render or none do.
func BuildPlanWithOptions(change *ir.Change, lock *Lock, target string, opts BuildPlanOptions) (Plan, error) {
	exported := export.BuildChange(change)
	ticketByIdentity := make(map[string]export.Ticket)
	for _, t := range exported.Tickets() {
		ticketByIdentity[Identity(t.SourceGroup, t.SourceText)] = t
	}

	items := TaskItems(change)
	current := make(map[string]bool, len(items))

	ops := make([]Operation, 0)
	var planWarnings []string
	for _, it := range items {
		current[it.Identity] = true
		ref, ok := lock.Get(target, it.Identity)
		var op Operation
		switch {
		case !ok:
			op = Operation{Kind: OpCreate, Identity: it.Identity, ContentHash: it.ContentHash}
		case ref.ContentHash != it.ContentHash:
			op = Operation{
				Kind: OpUpdate, Identity: it.Identity,
				ExternalID: ref.ExternalID, ContentHash: it.ContentHash,
			}
		default:
			continue
		}
		op.Title = it.Title
		op.Milestone = it.Milestone
		op.Position = it.Position
		op.Labels = it.Labels

		body, warn, err := render.RenderTicketBody(change, exported, ticketByIdentity[it.Identity], opts.TemplateOverrideDir)
		if err != nil {
			return Plan{}, fmt.Errorf("ticket body for %q: %w", it.Title, err)
		}
		if warn != nil {
			planWarnings = append(planWarnings, warn.Msg)
		}
		op.Body = body

		ops = append(ops, op)
	}

	for _, id := range lock.Identities(target) {
		if !current[id] {
			ref, _ := lock.Get(target, id)
			ops = append(ops, Operation{
				Kind: OpOrphan, Identity: id, ExternalID: ref.ExternalID, Title: ref.Title,
			})
		}
	}

	sortOps(ops)
	milestones := make([]string, 0, len(exported.Milestones))
	for _, m := range exported.Milestones {
		milestones = append(milestones, m.Name)
	}

	overview, warn, err := render.RenderOverview(change, exported, opts.TemplateOverrideDir)
	if err != nil {
		return Plan{}, fmt.Errorf("overview body for %q: %w", change.Name, err)
	}
	if warn != nil {
		planWarnings = append(planWarnings, warn.Msg)
	}

	return Plan{
		Change:     change.Name,
		Title:      exported.Title,
		Summary:    exported.Summary,
		Overview:   overview,
		Target:     target,
		Milestones: milestones,
		Operations: ops,
		Warnings:   planWarnings,
	}, nil
}

// sortOps orders operations deterministically: by kind (create, update,
// orphan), then identity.
func sortOps(ops []Operation) {
	rank := map[OpKind]int{OpCreate: 0, OpUpdate: 1, OpOrphan: 2}
	sort.Slice(ops, func(i, j int) bool {
		if rank[ops[i].Kind] != rank[ops[j].Kind] {
			return rank[ops[i].Kind] < rank[ops[j].Kind]
		}
		return ops[i].Identity < ops[j].Identity
	})
}
