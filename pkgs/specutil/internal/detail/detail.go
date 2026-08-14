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

type Feed struct {
	Changes []Change `json:"changes"`
}

type Change struct {
	Name        string          `json:"name"`
	Lifecycle   string          `json:"lifecycle"`
	Done        int             `json:"done"`
	Total       int             `json:"total"`
	Why         string          `json:"why,omitempty"`
	WhatChanges string          `json:"whatChanges,omitempty"`
	Design      *DesignSections `json:"design,omitempty"`
	Phases      []Phase         `json:"phases"`

	Review *ReviewState `json:"review,omitempty"`

	Diff *vcs.Diff `json:"diff,omitempty"`

	Notes map[string]Note `json:"notes,omitempty"`
}

type ReviewState struct {
	Decision string `json:"decision,omitempty"`
	Stale    bool   `json:"stale"`
	Note     string `json:"note,omitempty"`
}

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

type Phase struct {
	Number string `json:"number"`
	Name   string `json:"name"`
	Items  []Item `json:"items"`

	Markers map[string]string `json:"markers,omitempty"`
}

type Item struct {
	ID   string `json:"id,omitempty"`
	Text string `json:"text"`
	Done bool   `json:"done"`

	Kind  string `json:"kind"`
	Level int    `json:"level"`
	Key   string `json:"key"`

	DependsOn  []string `json:"dependsOn,omitempty"`
	Tags       []string `json:"tags,omitempty"`
	InlineRefs []string `json:"inlineRefs,omitempty"`

	Identity string `json:"identity,omitempty"`

	Drift string `json:"drift,omitempty"`

	Comment string `json:"comment,omitempty"`
	Action  string `json:"action,omitempty"`
}

type Note struct {
	Comment string `json:"comment,omitempty"`
	Action  string `json:"action,omitempty"`
}

type Options struct {
	Drift  DriftByKey
	Notes  NotesByKey
	Review ReviewByChange
	Diff   DiffByChange
}

type DiffByChange map[string]*vcs.Diff

type DriftByKey map[string]string

type NotesByKey map[string]Note

type ReviewByChange map[string]ReviewState

func levelKey(level, idx int) string {
	if idx < 26 {
		return fmt.Sprintf("%d%c", level, 'a'+idx)
	}
	return strconv.Itoa(level) + "x" + strconv.Itoa(idx)
}

func taskKey(phaseIndex, itemIndex int) [2]int { return [2]int{phaseIndex, itemIndex} }

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

		if n.pi > 0 {
			prev := phases[n.pi-1]
			for pii := range prev.Items {
				if d := depth(node{n.pi - 1, pii}) + 1; d > best {
					best = d
				}
			}

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

func Build(changes []*ir.Change) *Feed { return BuildWith(changes, Options{}) }

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

func (f *Feed) JSON() ([]byte, error) {
	b, err := json.MarshalIndent(f, "", "  ")
	if err != nil {
		return nil, err
	}
	return append(b, '\n'), nil
}
