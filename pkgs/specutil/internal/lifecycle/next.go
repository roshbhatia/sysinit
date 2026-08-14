package lifecycle

import (
	"sort"
	"strconv"
	"strings"

	"github.com/roshbhatia/specutil/internal/ir"
)

type Next struct {
	Change string `json:"change"`

	Phase     string `json:"phase,omitempty"`
	PhaseName string `json:"phaseName,omitempty"`
	Shape     string `json:"shape,omitempty"`
	Ready     []Task `json:"ready"`
	Blocked   []Task `json:"blocked,omitempty"`

	Concurrent bool `json:"concurrent"`

	EdgesDeclared bool `json:"edgesDeclared"`

	Stop string `json:"stop,omitempty"`
	Done bool   `json:"done"`
}

type Task struct {
	ID       string   `json:"id"`
	Kind     string   `json:"kind"`
	Text     string   `json:"text"`
	WaitsOn  []string `json:"waitsOn,omitempty"`
	Gate     bool     `json:"gate"`
	Adverse  bool     `json:"adversarialReview,omitempty"`
	PhaseNum string   `json:"-"`
}

func ComputeNext(c *ir.Change) Next {
	out := Next{Change: c.Name, Ready: []Task{}}
	if c.Tasks == nil || len(c.Tasks.Phases) == 0 {
		out.Done = true
		return out
	}

	phases := append([]ir.Phase(nil), c.Tasks.Phases...)
	sort.SliceStable(phases, func(i, j int) bool {
		return phaseOrder(phases[i].Number) < phaseOrder(phases[j].Number)
	})

	var current *ir.Phase
	for i := range phases {
		if anyPending(phases[i]) {
			current = &phases[i]
			break
		}
	}
	if current == nil {
		out.Done = true
		return out
	}

	out.Phase, out.PhaseName = current.Number, current.Name
	out.Shape = current.Markers["shape"]
	if stop, ok := current.Markers["stop"]; ok {
		out.Stop = strings.Join(strings.Fields(stop), " ")
	}

	done := map[string]bool{}
	known := map[string]bool{}
	for _, ph := range phases {
		for _, it := range ph.Items {
			if it.ID == "" {
				continue
			}
			known[it.ID] = true
			if it.Done {
				done[it.ID] = true
			}
		}
	}

	for _, it := range current.Items {
		if it.Done {
			continue
		}
		var waits []string
		for _, dep := range it.DependsOn {
			if known[dep] && !done[dep] {
				waits = append(waits, dep)
			}
		}
		t := Task{
			ID:       it.ID,
			Kind:     string(it.Kind),
			Text:     strings.Join(strings.Fields(it.Text), " "),
			WaitsOn:  waits,
			Gate:     it.Kind == ir.KindApply || it.Kind == ir.KindConfirm,
			Adverse:  strings.Contains(strings.ToLower(it.Text), "adversarial review"),
			PhaseNum: current.Number,
		}
		if len(waits) == 0 {
			out.Ready = append(out.Ready, t)
		} else {
			out.Blocked = append(out.Blocked, t)
		}
	}

	for _, it := range current.Items {
		if len(it.DependsOn) > 0 {
			out.EdgesDeclared = true
			break
		}
	}

	out.Concurrent = out.Shape == "graph" && out.EdgesDeclared && countRunnable(out.Ready) > 1
	return out
}

func countRunnable(ready []Task) int {
	n := 0
	for _, t := range ready {
		if !t.Gate && !t.Adverse {
			n++
		}
	}
	return n
}

func anyPending(p ir.Phase) bool {
	for _, it := range p.Items {
		if !it.Done {
			return true
		}
	}
	return false
}

func phaseOrder(number string) int {
	n, err := strconv.Atoi(strings.TrimSuffix(number, "."))
	if err != nil {
		return 1 << 30
	}
	return n
}
