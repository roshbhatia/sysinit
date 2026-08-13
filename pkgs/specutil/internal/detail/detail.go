// Package detail projects the loaded IR into detail.json: a per-change feed of
// lifecycle, progress, and task content that powers the visualizers' ticket drill-down.
package detail

import (
	"encoding/json"
	"fmt"
	"sort"
	"strconv"
	"strings"

	"github.com/roshbhatia/specutil/internal/ident"
	"github.com/roshbhatia/specutil/internal/ir"
	"github.com/roshbhatia/specutil/internal/lifecycle"
	"github.com/roshbhatia/specutil/internal/vcs"
)

// Feed is the whole detail projection: one entry per change, sorted by name for
// deterministic output.
type Feed struct {
	Changes []Change `json:"changes"`
}

// Change is the per-workstream ticket content.
type Change struct {
	Name        string          `json:"name"`
	Lifecycle   string          `json:"lifecycle"`
	Done        int             `json:"done"`
	Total       int             `json:"total"`
	Why         string          `json:"why,omitempty"`
	WhatChanges string          `json:"whatChanges,omitempty"`
	Design      *DesignSections `json:"design,omitempty"`
	Phases      []Phase         `json:"phases"`
	// Review is the standing of the recorded human verdict, when one exists.
	// Absent when the change has never been reviewed.
	Review *ReviewState `json:"review,omitempty"`
	// Diff is the working-tree diff a reviewer annotates alongside the plan.
	// Absent unless the caller asked for it: collecting it runs git, which the
	// default read-only projection has no reason to do.
	Diff *vcs.Diff `json:"diff,omitempty"`
	// Notes are the reviewer's standing remarks for this change, keyed by the
	// identity they were written against. It covers tasks and diff hunks alike,
	// so a renderer seeds its annotation state from one place.
	Notes map[string]Note `json:"notes,omitempty"`
}

// ReviewState is the recorded verdict on a change, flattened for renderers.
// Stale means the artifacts moved after the verdict was recorded, so the
// verdict no longer describes the text on screen.
type ReviewState struct {
	Decision string `json:"decision,omitempty"`
	Stale    bool   `json:"stale"`
	Note     string `json:"note,omitempty"`
}

// DesignSections surfaces design.md content for visualizers.
type DesignSections struct {
	Context       string `json:"context,omitempty"`
	Goals         string `json:"goals,omitempty"`
	NonGoals      string `json:"nonGoals,omitempty"`
	Decisions     string `json:"decisions,omitempty"`
	Risks         string `json:"risks,omitempty"`
	Rollout       string `json:"rollout,omitempty"`
	Migration     string `json:"migration,omitempty"`
	OpenQuestions string `json:"openQuestions,omitempty"`
}

// Phase mirrors a tasks.md phase with its checkbox items.
type Phase struct {
	Number string `json:"number"`
	Name   string `json:"name"`
	Items  []Item `json:"items"`
	// Markers carries the schema-declared facts about this phase lifted by the
	// extract pass (e.g. "shape": "loop", "stop": "…"). Absent when the
	// repository declares no extraction.
	Markers map[string]string `json:"markers,omitempty"`
}

// Item is one checkbox task.
type Item struct {
	// ID is the source task identifier (e.g. "1.2"). It is the join key for
	// DependsOn and is internal to these tools; it never reaches a tracker.
	ID   string `json:"id,omitempty"`
	Text string `json:"text"`
	Done bool   `json:"done"`
	// Kind is the verify/apply/confirm discipline classification carried from the
	// IR ("task" for plain items), so visualizers can mark impactful and
	// confirmation steps without re-parsing the source markdown.
	Kind  string `json:"kind"`
	Level int    `json:"level"`
	Key   string `json:"key"`
	// DependsOn lists the source IDs of sibling tasks this task waits on, as
	// declared through a taskRefs field. Empty when none are declared.
	DependsOn  []string `json:"dependsOn,omitempty"`
	Tags       []string `json:"tags,omitempty"`
	InlineRefs []string `json:"inlineRefs,omitempty"`
	// Identity is the content-addressed task handle. It is what an annotation
	// written in a browser names, so a comment survives the renumbering that
	// follows almost every edit to the source.
	Identity string `json:"identity,omitempty"`
	// Drift classifies this task against the last recorded review: "new",
	// "changed", or "unchanged". Empty when the change was never reviewed.
	Drift string `json:"drift,omitempty"`
	// Comment and Action carry the reviewer's standing remark on this task, so a
	// reader sees prior feedback without re-opening the record.
	Comment string `json:"comment,omitempty"`
	Action  string `json:"action,omitempty"`
}

// Note is a reviewer's standing remark on one task or diff hunk.
type Note struct {
	Comment string `json:"comment,omitempty"`
	Action  string `json:"action,omitempty"`
}

// Options carries the per-change facts that live outside the IR: review drift
// and recorded verdicts. The caller assembles them from the review records so
// this package stays free of a review dependency. Every field is optional.
type Options struct {
	Drift  DriftByKey
	Notes  NotesByKey
	Review ReviewByChange
	Diff   DiffByChange
}

// DiffByChange maps a change name to the working-tree diff shown against it.
type DiffByChange map[string]*vcs.Diff

// DriftByKey maps changeName + "\x00" + identity to a drift class.
type DriftByKey map[string]string

// NotesByKey maps changeName + "\x00" + identity to the reviewer's remark.
type NotesByKey map[string]Note

// ReviewByChange maps a change name to its recorded verdict.
type ReviewByChange map[string]ReviewState

// levelKey renders the (level, sibling-index) pair as a compact handle: the
// 0-based level followed by a letter (a..z), falling back to the raw index past
// 26 siblings so it never collides or runs out of letters.
func levelKey(level, idx int) string {
	if idx < 26 {
		return fmt.Sprintf("%d%c", level, 'a'+idx)
	}
	return strconv.Itoa(level) + "x" + strconv.Itoa(idx)
}

// taskKey identifies a task by its position, so levels can be looked up without
// depending on the source ID being present or unique.
func taskKey(phaseIndex, itemIndex int) [2]int { return [2]int{phaseIndex, itemIndex} }

// taskLevels computes each task's 0-based dependency rank: the length of the longest
// chain that must finish before it can start.
func taskLevels(phases []ir.Phase) map[[2]int]int {
	type node struct{ pi, ii int }
	byID := map[string]node{}
	for pi, p := range phases {
		for ii, it := range p.Items {
			if it.ID != "" {
				byID[it.ID] = node{pi, ii}
			}
		}
	}

	levels := make(map[[2]int]int)
	visiting := map[[2]int]bool{}

	var depth func(n node) int
	depth = func(n node) int {
		key := taskKey(n.pi, n.ii)
		if d, ok := levels[key]; ok {
			return d
		}
		if visiting[key] {
			return 0
		}
		visiting[key] = true

		best := 0
		// Every task in the previous phase must finish first.
		if n.pi > 0 {
			prev := phases[n.pi-1]
			for pii := range prev.Items {
				if d := depth(node{n.pi - 1, pii}) + 1; d > best {
					best = d
				}
			}
			// A phase with no items still advances the sequence.
			if len(prev.Items) == 0 {
				if d := depth(node{n.pi - 1, 0}); d >= best {
					best = d
				}
			}
		}
		for _, ref := range phases[n.pi].Items[n.ii].DependsOn {
			dep, ok := byID[ref]
			if !ok {
				continue
			}
			if d := depth(dep) + 1; d > best {
				best = d
			}
		}

		delete(visiting, key)
		levels[key] = best
		return best
	}

	for pi, p := range phases {
		for ii := range p.Items {
			depth(node{pi, ii})
		}
	}
	return levels
}

// Build assembles the detail feed with no annotations. Its callers are the
// tests, which read it a dozen times; inlining it would repeat the zero Options
// at every one.
func Build(changes []*ir.Change) *Feed { return BuildWith(changes, Options{}) }

// BuildWith assembles the detail feed and annotates it with every optional fact
// in opts.
func BuildWith(changes []*ir.Change, opts Options) *Feed {
	out := make([]Change, 0, len(changes))
	for _, c := range changes {
		done, total := lifecycle.Progress(c)
		dc := Change{
			Name:      c.Name,
			Lifecycle: string(lifecycle.Classify(c)),
			Done:      done,
			Total:     total,
			Phases:    []Phase{},
		}
		if c.Proposal != nil {
			dc.Why = c.Proposal.Why
			dc.WhatChanges = c.Proposal.WhatChanges
		}
		if c.Design != nil {
			ds := &DesignSections{
				Context:       c.Design.Context,
				Goals:         c.Design.Goals,
				NonGoals:      c.Design.NonGoals,
				Decisions:     c.Design.Decisions,
				Risks:         c.Design.Risks,
				Rollout:       c.Design.Rollout,
				Migration:     c.Design.Migration,
				OpenQuestions: c.Design.OpenQuestions,
			}
			// Only attach when at least one section is non-empty.
			if ds.Context != "" || ds.Goals != "" || ds.NonGoals != "" || ds.Decisions != "" ||
				ds.Risks != "" || ds.Rollout != "" || ds.Migration != "" || ds.OpenQuestions != "" {
				dc.Design = ds
			}
		}
		if c.Tasks != nil {
			levels := taskLevels(c.Tasks.Phases)
			seen := map[int]int{}
			for pi, p := range c.Tasks.Phases {
				ph := Phase{Number: p.Number, Name: p.Name, Items: []Item{}, Markers: p.Markers}
				for ii, it := range p.Items {
					level, ok := levels[taskKey(pi, ii)]
					if !ok {
						level = pi
					}
					identity := ident.Identity(p.Name, it.Text)
					it2 := Item{
						ID:         it.ID,
						Text:       it.Text,
						Done:       it.Done,
						Kind:       string(it.Kind),
						Level:      level,
						Key:        levelKey(level, seen[level]),
						DependsOn:  it.DependsOn,
						Tags:       it.Tags,
						InlineRefs: it.InlineRefs,
						Identity:   identity,
					}
					seen[level]++
					idKey := c.Name + "\x00" + identity
					it2.Drift = opts.Drift[idKey]
					if n, ok := opts.Notes[idKey]; ok {
						it2.Comment, it2.Action = n.Comment, n.Action
					}
					ph.Items = append(ph.Items, it2)
				}
				dc.Phases = append(dc.Phases, ph)
			}
		}
		if rs, ok := opts.Review[c.Name]; ok {
			dc.Review = &rs
		}
		if d, ok := opts.Diff[c.Name]; ok {
			dc.Diff = d
		}
		prefix := c.Name + "\x00"
		for key, n := range opts.Notes {
			id, ok := strings.CutPrefix(key, prefix)
			if !ok {
				continue
			}
			if dc.Notes == nil {
				dc.Notes = map[string]Note{}
			}
			dc.Notes[id] = n
		}
		out = append(out, dc)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Name < out[j].Name })
	return &Feed{Changes: out}
}

// JSON renders the feed as indented, deterministic JSON.
func (f *Feed) JSON() ([]byte, error) {
	b, err := json.MarshalIndent(f, "", "  ")
	if err != nil {
		return nil, err
	}
	return append(b, '\n'), nil
}
