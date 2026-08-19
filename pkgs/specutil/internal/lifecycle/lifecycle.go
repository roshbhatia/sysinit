package lifecycle

import "github.com/roshbhatia/sysinit/pkgs/specutil/internal/ir"

type Lifecycle string

const (
	Proposed Lifecycle = "proposed"

	Active Lifecycle = "active"

	Archived Lifecycle = "archived"
)

var Order = []Lifecycle{Proposed, Active, Archived}

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
