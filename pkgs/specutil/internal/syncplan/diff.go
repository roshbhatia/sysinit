package syncplan

import (
	"sort"

	"github.com/roshbhatia/specutil/internal/ident"
	"github.com/roshbhatia/specutil/internal/ir"
)

// fuzzyThreshold is the minimum token-set similarity for diff to re-match a
// would-be-new item against an orphaned lock entry, treating it as an edit
// rather than a delete+add.
const fuzzyThreshold = ident.FuzzyThreshold

// DriftItem is one entry in a diff report.
type DriftItem struct {
	Identity   string `json:"identity"`
	ExternalID string `json:"externalId,omitempty"`
	Title      string `json:"title,omitempty"`
	Milestone  string `json:"milestone,omitempty"`
	Note       string `json:"note,omitempty"`
}

// Diff is the drift report: items present locally but not in the lock (new),
// items whose content changed (changed), and lock entries with no current item
// (orphaned). It performs no network I/O.
type Diff struct {
	Change   string      `json:"change"`
	Target   string      `json:"target"`
	New      []DriftItem `json:"new"`
	Changed  []DriftItem `json:"changed"`
	Orphaned []DriftItem `json:"orphaned"`
}

// DiffChange compares the change's current items against the lock namespace for
// target. Minor edits are absorbed by the normalized identity (so they surface
// as "changed"); larger edits that move the identity are recovered via fuzzy
// re-match against orphaned entries' retained titles.
func DiffChange(change *ir.Change, lock *Lock, target string) Diff {
	items := TaskItems(change)
	currentIDs := make(map[string]bool, len(items))
	for _, it := range items {
		currentIDs[it.Identity] = true
	}

	d := Diff{Change: change.Name, Target: target}
	var candidateNew []Item
	for _, it := range items {
		ref, ok := lock.Get(target, it.Identity)
		switch {
		case !ok:
			candidateNew = append(candidateNew, it)
		case ref.ContentHash != it.ContentHash:
			d.Changed = append(d.Changed, DriftItem{
				Identity: it.Identity, ExternalID: ref.ExternalID, Title: it.Title, Milestone: it.Milestone,
				Note: "content changed",
			})
		}
	}

	// Collect orphan candidates: lock identities absent from current items.
	type orphan struct {
		id  string
		ref Ref
	}
	var orphans []orphan
	for _, id := range lock.Identities(target) {
		if !currentIDs[id] {
			ref, _ := lock.Get(target, id)
			orphans = append(orphans, orphan{id, ref})
		}
	}

	// Fuzzy re-match each candidate-new against the best-scoring orphan title.
	usedOrphan := make(map[int]bool)
	for _, it := range candidateNew {
		best, bestScore := -1, fuzzyThreshold
		for i, o := range orphans {
			if usedOrphan[i] || o.ref.Title == "" {
				continue
			}
			if s := similarity(it.Title, o.ref.Title); s > bestScore {
				best, bestScore = i, s
			}
		}
		if best >= 0 {
			usedOrphan[best] = true
			d.Changed = append(d.Changed, DriftItem{
				Identity: it.Identity, ExternalID: orphans[best].ref.ExternalID, Title: it.Title, Milestone: it.Milestone,
				Note: "re-matched from edited item",
			})
			continue
		}
		d.New = append(d.New, DriftItem{Identity: it.Identity, Title: it.Title, Milestone: it.Milestone})
	}

	for i, o := range orphans {
		if usedOrphan[i] {
			continue
		}
		d.Orphaned = append(d.Orphaned, DriftItem{Identity: o.id, ExternalID: o.ref.ExternalID, Title: o.ref.Title})
	}

	sortDrift(d.New)
	sortDrift(d.Changed)
	sortDrift(d.Orphaned)
	return d
}

func sortDrift(items []DriftItem) {
	sort.Slice(items, func(i, j int) bool { return items[i].Identity < items[j].Identity })
}

// similarity is the Jaccard index over normalized token sets of two titles,
// in [0,1]. It is symmetric and order-independent.
func similarity(a, b string) float64 { return ident.Similarity(a, b) }
