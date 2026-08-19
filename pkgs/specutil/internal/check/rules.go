package check

import (
	"fmt"
	"regexp"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/specutil/internal/ir"
	"github.com/roshbhatia/sysinit/pkgs/specutil/internal/review"
)

func init() {
	register(rule{
		id:  "required-sections",
		doc: "an artifact must contain each named heading (params: artifact, sections)",
		eval: func(p params, c *ir.Change) []Finding {
			artifact := p.String("artifact")
			text, file, ok := artifactText(c, artifact)
			if !ok {
				return nil
			}
			var out []Finding
			for _, want := range p.Strings("sections") {
				if line := findLine(text, func(l string) bool { return strings.TrimSpace(l) == want }); line == 0 {
					out = append(out, Finding{
						File: file,
						Msg:  fmt.Sprintf("%s is missing the required section %q", file, want),
					})
				}
			}
			return out
		},
	})

	register(rule{
		id: "section-min-bullets",
		doc: "a named section must hold at least min bullets, so a required heading " +
			"cannot be satisfied by an empty one (params: artifact, section, min)",
		eval: func(p params, c *ir.Change) []Finding {
			artifact, section, min := p.String("artifact"), p.String("section"), p.Int("min")
			if section == "" || min <= 0 {
				return nil
			}
			text, file, ok := artifactText(c, artifact)
			if !ok {
				return nil
			}

			var found, counting int
			for _, raw := range strings.Split(text, "\n") {
				line := strings.TrimSpace(raw)
				switch {
				case line == section:
					counting = 1
					continue
				case counting == 1 && strings.HasPrefix(line, "## "):
					counting = 2
				}
				if counting == 1 && strings.HasPrefix(line, "- ") {
					found++
				}
			}
			if counting == 0 || found >= min {
				return nil
			}
			return []Finding{{
				File: file,
				Msg: fmt.Sprintf("%s holds %d bullet(s), under the %d this rubric requires; a heading with nothing under it states no criteria",
					section, found, min),
			}}
		},
	})

	register(rule{
		id: "paired-bullet",
		doc: "every bullet matching lead must be followed by one matching follower " +
			"before the next lead (params: artifact, lead, follower)",
		eval: func(p params, c *ir.Change) []Finding {
			text, file, ok := artifactText(c, p.String("artifact"))
			if !ok {
				return nil
			}
			lead, follower := p.String("lead"), p.String("follower")
			if lead == "" || follower == "" {
				return nil
			}
			var out []Finding
			openLine, openText := 0, ""
			paired := true
			flush := func() {
				if openLine != 0 && !paired {
					out = append(out, Finding{
						File: file, Line: openLine,
						Msg: fmt.Sprintf("%q has no following %q", openText, follower),
					})
				}
			}
			for i, raw := range strings.Split(text, "\n") {
				line := strings.TrimSpace(raw)
				switch {
				case strings.HasPrefix(line, lead):
					flush()
					openLine, openText, paired = i+1, line, false
				case strings.HasPrefix(line, follower):
					if openLine != 0 {
						paired = true
					}
				}
			}
			flush()
			return out
		},
	})

	register(rule{
		id: "scenario-marker-coverage",
		doc: "every requirement must have at least one scenario declaring marker=value " +
			"(params: marker, value)",
		eval: func(p params, c *ir.Change) []Finding {
			marker, value := p.String("marker"), p.String("value")
			if marker == "" {
				return nil
			}
			var out []Finding
			for _, s := range c.Specs {
				if s == nil {
					continue
				}
				file := "specs/" + s.Capability + "/spec.md"
				for _, r := range s.Requirements {
					if r.Delta == ir.DeltaRemoved || r.Delta == ir.DeltaRenamed {
						continue
					}
					found := false
					for _, sc := range r.Scenarios {
						if got, ok := sc.Markers[marker]; ok && strings.EqualFold(got, value) {
							found = true
							break
						}
					}
					if !found {
						out = append(out, Finding{
							File: file,
							Msg: fmt.Sprintf("requirement %q has no scenario declaring %s=%s",
								r.Name, marker, value),
						})
					}
				}
			}
			return out
		},
	})

	register(rule{
		id: "phase-marker-required",
		doc: "every phase must declare the named marker, and declare an allowed value " +
			"for it when allowedValues is set (params: marker, allowedValues, skipPhasePattern)",
		eval: func(p params, c *ir.Change) []Finding {
			marker := p.String("marker")
			if marker == "" || c.Tasks == nil {
				return nil
			}

			allowed := p.Strings("allowedValues")
			skip := compile(p.String("skipPhasePattern"))
			var out []Finding
			for _, ph := range c.Tasks.Phases {
				if skipped(skip, ph) {
					continue
				}
				got, ok := ph.Markers[marker]
				if !ok {
					out = append(out, Finding{
						File: "tasks.md",
						Msg:  fmt.Sprintf("phase %q declares no %s marker", phaseLabel(ph), marker),
					})
					continue
				}
				if len(allowed) > 0 && !containsFold(allowed, got) {
					out = append(out, Finding{
						File: "tasks.md",
						Msg: fmt.Sprintf("phase %q declares %s=%s, which is not one of: %s",
							phaseLabel(ph), marker, got, strings.Join(allowed, ", ")),
					})
				}
			}
			return out
		},
	})

	register(rule{
		id: "phase-marker-pattern",
		doc: "a phase marker's value must match the pattern, optionally only when " +
			"another marker holds a value (params: marker, pattern, describe, when {marker, value})",
		eval: func(p params, c *ir.Change) []Finding {
			marker, pattern := p.String("marker"), p.String("pattern")
			re := compile(pattern)
			if marker == "" || re == nil || c.Tasks == nil {
				return nil
			}
			describe := p.String("describe")
			if describe == "" {
				describe = "match " + pattern
			}
			when, _ := p["when"].(map[string]any)
			trigger, value := "", ""
			if when != nil {
				trigger = params(when).String("marker")
				value = params(when).String("value")
			}
			var out []Finding
			for _, ph := range c.Tasks.Phases {
				if trigger != "" {
					got, ok := ph.Markers[trigger]
					if !ok || !strings.EqualFold(got, value) {
						continue
					}
				}
				got, ok := ph.Markers[marker]
				if !ok {
					continue
				}
				if !re.MatchString(got) {
					out = append(out, Finding{
						File: "tasks.md",
						Msg: fmt.Sprintf("phase %q declares a %s that does not %s: %s",
							phaseLabel(ph), marker, describe, firstWords(got, 12)),
					})
				}
			}
			return out
		},
	})

	register(rule{
		id:  "task-id-matches-phase",
		doc: "every task id must carry the number of the phase it sits in",
		eval: func(_ params, c *ir.Change) []Finding {
			if c.Tasks == nil {
				return nil
			}

			var out []Finding
			for _, ph := range c.Tasks.Phases {
				if ph.Number == "" {
					continue
				}
				for _, it := range ph.Items {
					if it.ID == "" {
						continue
					}
					got, _, ok := strings.Cut(it.ID, ".")
					if !ok || got == ph.Number {
						continue
					}
					out = append(out, Finding{
						File: "tasks.md",
						Msg: fmt.Sprintf("task %s sits in phase %q but is numbered for phase %s",
							it.ID, phaseLabel(ph), got),
					})
				}
			}
			return out
		},
	})

	register(rule{
		id: "task-text-max-words",
		doc: "a task's own line must stay under a word budget, so evidence goes " +
			"below it rather than into it (params: max)",
		eval: func(p params, c *ir.Change) []Finding {
			max := p.Int("max")
			if max <= 0 || c.Tasks == nil {
				return nil
			}

			var out []Finding
			for _, ph := range c.Tasks.Phases {
				for _, it := range ph.Items {
					n := len(strings.Fields(it.Text))
					if n <= max {
						continue
					}
					out = append(out, Finding{
						File: "tasks.md",
						Msg: fmt.Sprintf("task %s runs %d words on its own line, over the %d-word budget; "+
							"move the evidence and the history to an indented block under it",
							taskLabel(it, ph), n, max),
					})
				}
			}
			return out
		},
	})

	register(rule{
		id: "phase-edges-declared",
		doc: "a phase declaring when.marker=when.value must declare at least one task " +
			"dependency (params: when {marker, value}, skipPhasePattern)",
		eval: func(p params, c *ir.Change) []Finding {
			when, _ := p["when"].(map[string]any)
			if when == nil || c.Tasks == nil {
				return nil
			}
			trigger := params(when).String("marker")
			value := params(when).String("value")
			if trigger == "" {
				return nil
			}
			skip := compile(p.String("skipPhasePattern"))
			var out []Finding
			for _, ph := range c.Tasks.Phases {
				if skipped(skip, ph) {
					continue
				}
				got, ok := ph.Markers[trigger]
				if !ok || !strings.EqualFold(got, value) {
					continue
				}

				if len(ph.Items) < 2 {
					continue
				}
				edges := false
				for _, it := range ph.Items {
					if len(it.DependsOn) > 0 {
						edges = true
						break
					}
				}
				if !edges {
					out = append(out, Finding{
						File: "tasks.md",
						Msg: fmt.Sprintf("phase %q is %s=%s with %d subtasks and no declared "+
							"dependency, so nothing states the order",
							phaseLabel(ph), trigger, value, len(ph.Items)),
					})
				}
			}
			return out
		},
	})

	register(rule{
		id:  "task-id-required",
		doc: "every task must carry an N.M identifier",
		eval: func(_ params, c *ir.Change) []Finding {
			if c.Tasks == nil {
				return nil
			}

			var out []Finding
			for _, ph := range c.Tasks.Phases {
				for _, it := range ph.Items {
					if it.ID == "" {
						out = append(out, Finding{
							File: "tasks.md",
							Msg: fmt.Sprintf("a task in phase %q carries no N.M identifier: %q",
								phaseLabel(ph), firstWords(it.Text, 10)),
						})
					}
				}
			}
			return out
		},
	})

	register(rule{
		id: "phase-marker-conditional",
		doc: "a phase declaring when.marker=when.value must also declare each required marker " +
			"(params: when {marker, value}, require, skipPhasePattern)",
		eval: func(p params, c *ir.Change) []Finding {
			when, _ := p["when"].(map[string]any)
			if when == nil || c.Tasks == nil {
				return nil
			}
			trigger := params(when).String("marker")
			value := params(when).String("value")
			required := p.Strings("require")
			if trigger == "" || len(required) == 0 {
				return nil
			}
			skip := compile(p.String("skipPhasePattern"))
			var out []Finding
			for _, ph := range c.Tasks.Phases {
				if skipped(skip, ph) {
					continue
				}
				got, ok := ph.Markers[trigger]
				if !ok || !strings.EqualFold(got, value) {
					continue
				}
				for _, need := range required {
					if _, ok := ph.Markers[need]; !ok {
						out = append(out, Finding{
							File: "tasks.md",
							Msg: fmt.Sprintf("phase %q is %s=%s but declares no %s marker",
								phaseLabel(ph), trigger, value, need),
						})
					}
				}
			}
			return out
		},
	})

	register(rule{
		id: "phase-task-pattern",
		doc: "every phase must contain a task matching the pattern " +
			"(params: pattern, skipPhasePattern, describe)",
		eval: func(p params, c *ir.Change) []Finding {
			re := compile(p.String("pattern"))
			if re == nil || c.Tasks == nil {
				return nil
			}
			describe := p.String("describe")
			if describe == "" {
				describe = "a task matching " + p.String("pattern")
			}
			skip := compile(p.String("skipPhasePattern"))
			var out []Finding
			for _, ph := range c.Tasks.Phases {
				if skipped(skip, ph) {
					continue
				}
				found := false
				for _, it := range ph.Items {
					if re.MatchString(it.Text) {
						found = true
						break
					}
				}
				if !found {
					out = append(out, Finding{
						File: "tasks.md",
						Msg:  fmt.Sprintf("phase %q has no %s", phaseLabel(ph), describe),
					})
				}
			}
			return out
		},
	})

	register(rule{
		id:  "task-deps-resolve",
		doc: "every declared task dependency must name a task in the same change",
		eval: func(_ params, c *ir.Change) []Finding {
			if c.Tasks == nil {
				return nil
			}
			known := map[string]bool{}
			for _, ph := range c.Tasks.Phases {
				for _, it := range ph.Items {
					if it.ID != "" {
						known[it.ID] = true
					}
				}
			}
			var out []Finding
			for _, ph := range c.Tasks.Phases {
				for _, it := range ph.Items {
					for _, dep := range it.Fields["deps"] {
						if !known[dep] {
							out = append(out, Finding{
								File: "tasks.md",
								Msg:  fmt.Sprintf("task %s depends on %q, which names no task in this change", it.ID, dep),
							})
						}
					}
				}
			}
			return out
		},
	})

	register(rule{
		id:  "task-deps-acyclic",
		doc: "declared task dependencies must not form a cycle",
		eval: func(_ params, c *ir.Change) []Finding {
			if c.Tasks == nil {
				return nil
			}
			deps := map[string][]string{}
			var order []string
			for _, ph := range c.Tasks.Phases {
				for _, it := range ph.Items {
					if it.ID == "" {
						continue
					}
					if _, seen := deps[it.ID]; !seen {
						order = append(order, it.ID)
					}
					deps[it.ID] = append(deps[it.ID], it.Fields["deps"]...)
				}
			}
			const (
				unvisited = iota
				onStack
				done
			)
			state := map[string]int{}
			var stack []string
			var out []Finding
			var walk func(string)
			walk = func(id string) {
				state[id] = onStack
				stack = append(stack, id)
				for _, dep := range deps[id] {
					if _, known := deps[dep]; !known {
						continue
					}
					switch state[dep] {
					case unvisited:
						walk(dep)
					case onStack:
						out = append(out, Finding{
							File: "tasks.md",
							Msg: fmt.Sprintf("task dependencies form a cycle: %s",
								strings.Join(append(cycleFrom(stack, dep), dep), " -> ")),
						})
					}
				}
				stack = stack[:len(stack)-1]
				state[id] = done
			}
			for _, id := range order {
				if state[id] == unvisited {
					walk(id)
				}
			}
			return out
		},
	})

	register(rule{
		id:  "no-em-dash",
		doc: "no artifact may contain an em-dash in prose",
		eval: func(_ params, c *ir.Change) []Finding {
			var out []Finding
			for _, a := range allArtifacts(c) {
				if line := findProseLine(a.Text, '—'); line != 0 {
					out = append(out, Finding{
						File: a.File, Line: line,
						Msg: fmt.Sprintf("%s contains an em-dash; use a comma, colon, or new sentence", a.File),
					})
				}
			}
			return out
		},
	})

	register(rule{
		id: "bolded-bullet-lead",
		doc: "a bullet may not open with a bolded term unless it is allowed " +
			"(params: allow)",
		eval: func(p params, c *ir.Change) []Finding {
			allowed := map[string]bool{}
			for _, a := range p.Strings("allow") {
				allowed[a] = true
			}
			var out []Finding
			for _, a := range allArtifacts(c) {
				for i, raw := range strings.Split(a.Text, "\n") {
					m := boldLeadRe.FindStringSubmatch(raw)
					if m == nil || allowed[m[1]] {
						continue
					}
					out = append(out, Finding{
						File: a.File, Line: i + 1,
						Msg: fmt.Sprintf("%s opens a bullet with the bolded term **%s**; use plain text or a sub-bullet",
							a.File, m[1]),
					})
				}
			}
			return out
		},
	})

	register(rule{
		id: "review-decision-current",
		doc: "a recorded review decision must exist and still describe the current " +
			"artifacts (params: accept, requireRecord)",
		eval: func(p params, c *ir.Change) []Finding {
			rec, err := review.LoadForChange(c)
			if err != nil {
				return []Finding{{File: review.RecordFile, Msg: err.Error()}}
			}
			accept := p.Strings("accept")
			if len(accept) == 0 {
				accept = []string{string(review.DecisionApproved)}
			}
			if rec == nil {
				if v, ok := p["requireRecord"].(bool); ok && !v {
					return nil
				}
				return []Finding{{
					File: review.RecordFile,
					Msg: fmt.Sprintf("no review decision recorded; run `specutil review set --change %s --decision %s`",
						c.Name, strings.Join(accept, "|")),
				}}
			}
			var out []Finding
			if !containsString(accept, string(rec.Decision)) {
				out = append(out, Finding{
					File: review.RecordFile,
					Msg: fmt.Sprintf("review decision is %q; the rubric accepts %s",
						rec.Decision, strings.Join(accept, ", ")),
				})
			}

			if st := review.Build(c, rec); st.Stale {
				out = append(out, Finding{
					File: review.RecordFile,
					Msg: fmt.Sprintf("review decision is stale: the artifacts changed since it was recorded (reviewed %s, now %s)",
						st.ReviewHash, st.ChangeHash),
				})
			}
			return out
		},
	})
}

func containsString(list []string, want string) bool {
	for _, s := range list {
		if s == want {
			return true
		}
	}
	return false
}

var boldLeadRe = regexp.MustCompile(`^\s*[-*]\s+\*\*([A-Za-z][A-Za-z0-9 _-]*)\*\*`)

func compile(pattern string) *regexp.Regexp {
	if pattern == "" {
		return nil
	}
	re, err := regexp.Compile(pattern)
	if err != nil {
		return nil
	}
	return re
}

func skipped(skip *regexp.Regexp, ph ir.Phase) bool {
	return skip != nil && skip.MatchString(ph.Name)
}

func phaseLabel(ph ir.Phase) string {
	if ph.Number != "" {
		return ph.Number + ". " + ph.Name
	}
	return ph.Name
}

func taskLabel(it ir.TaskItem, ph ir.Phase) string {
	if it.ID != "" {
		return it.ID
	}
	opening := it.Text
	if len(opening) > 40 {
		opening = opening[:40] + "..."
	}
	return fmt.Sprintf("%q in phase %s", opening, phaseLabel(ph))
}

func cycleFrom(stack []string, id string) []string {
	for i, s := range stack {
		if s == id {
			return append([]string(nil), stack[i:]...)
		}
	}
	return append([]string(nil), stack...)
}

func findLine(text string, match func(string) bool) int {
	for i, line := range strings.Split(text, "\n") {
		if match(line) {
			return i + 1
		}
	}
	return 0
}

func containsFold(list []string, want string) bool {
	for _, got := range list {
		if strings.EqualFold(got, want) {
			return true
		}
	}
	return false
}

func firstWords(text string, n int) string {
	words := strings.Fields(text)
	if len(words) <= n {
		return strings.Join(words, " ")
	}
	return strings.Join(words[:n], " ") + " ..."
}

func findProseLine(text string, r rune) int {
	fenced := false
	for i, line := range strings.Split(text, "\n") {
		if strings.HasPrefix(strings.TrimSpace(line), "```") {
			fenced = !fenced
			continue
		}
		if fenced {
			continue
		}
		if strings.ContainsRune(stripCodeSpans(line), r) {
			return i + 1
		}
	}
	return 0
}

func stripCodeSpans(line string) string {
	var prose strings.Builder
	code := false
	for _, c := range line {
		if c == '`' {
			code = !code
			continue
		}
		if !code {
			prose.WriteRune(c)
		}
	}
	return prose.String()
}
