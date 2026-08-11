// Package lifecycle derives a workstream's status and progress from its task
// completion. OpenSpec tasks are only done/not-done, so lifecycle is computed
// rather than read from a status field. It is the single source of truth shared
// by every renderer so they never disagree about a change.
package lifecycle

import "github.com/roshbhatia/specutil/internal/ir"

// Lifecycle is the workstream-level status.
type Lifecycle string

const (
	// Proposed: no tasks exist yet, or none are complete — planning stage.
	Proposed Lifecycle = "proposed"
	// Active: some but not all tasks are complete — in progress.
	Active Lifecycle = "active"
	// Archived: every task is complete — work is finished.
	Archived Lifecycle = "archived"
)

// Order is the canonical left-to-right ordering of lifecycle states.
var Order = []Lifecycle{Proposed, Active, Archived}

// Progress counts completed and total task items across all phases.
func Progress(c *ir.Change) (done, total int) {
	if c.Tasks == nil {
		return 0, 0
	}
	for _, p := range c.Tasks.Phases {
		for _, it := range p.Items {
			total++
			if it.Done {
				done++
			}
		}
	}
	return done, total
}

// Classify derives a change's lifecycle from its task progress.
func Classify(c *ir.Change) Lifecycle {
	done, total := Progress(c)
	switch {
	case total == 0 || done == 0:
		return Proposed
	case done == total:
		return Archived
	default:
		return Active
	}
}
