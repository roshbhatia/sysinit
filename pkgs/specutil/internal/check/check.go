// Package check validates a change against a declared rubric.
//
// Rules are generic and parameterized, not tied to any spec framework: a rule
// says "this artifact must contain these sections" or "every requirement needs
// a scenario carrying this marker", and the repository supplies the specifics
// in openspec/specutil.yaml. A framework ships as a preset, which is nothing
// more than a named bundle of rule parameters.
//
// Every rule reads only facts the author stated: a heading that is present, a
// marker that is declared, a bullet that follows another. None infers intent
// from prose, so two runs over the same input always agree.
package check

import (
	"fmt"
	"sort"
	"strings"

	"github.com/roshbhatia/specutil/internal/ir"
)

// Severity ranks a finding. An error fails the run; a warning is reported and
// does not.
type Severity string

const (
	SeverityError Severity = "error"
	SeverityWarn  Severity = "warn"
)

// Finding is one rule violation.
type Finding struct {
	Rule     string   `json:"rule"`
	Severity Severity `json:"severity"`
	Change   string   `json:"change"`
	File     string   `json:"file,omitempty"`
	Line     int      `json:"line,omitempty"`
	Msg      string   `json:"msg"`
}

// Report is the outcome of checking one or more changes.
type Report struct {
	Findings []Finding `json:"findings"`
	Checked  []string  `json:"checked"`
}

// Errors counts the findings that fail the run.
func (r *Report) Errors() int {
	n := 0
	for _, f := range r.Findings {
		if f.Severity == SeverityError {
			n++
		}
	}
	return n
}

// Warnings counts the findings that do not fail the run.
func (r *Report) Warnings() int { return len(r.Findings) - r.Errors() }

// OK reports whether the run passed.
func (r *Report) OK() bool { return r.Errors() == 0 }

// RuleConfig selects a built-in rule and supplies its parameters.
type RuleConfig struct {
	// ID names a built-in rule. An unknown ID is an error, not a silent skip.
	ID string `yaml:"id"`
	// Name identifies this instance. It defaults to ID, and is what Disable and
	// a local override match on. A rubric that applies the same rule twice with
	// different parameters gives each instance its own name.
	Name string `yaml:"name"`
	// Severity overrides the rule's default. Empty means error.
	Severity Severity `yaml:"severity"`
	// Params are the rule's parameters. Their shape is per-rule and documented
	// on each built-in.
	Params map[string]any `yaml:",inline"`
}

// Config is the repository's rubric declaration.
type Config struct {
	// Preset names a built-in rubric to start from.
	Preset string `yaml:"preset"`
	// Rules are appended to the preset's. A rule sharing a name with a preset
	// rule replaces it, which is how a repository retunes one check without
	// restating the rest.
	Rules []RuleConfig `yaml:"rules"`
	// Disable removes rules by name after the preset and Rules are merged.
	Disable []string `yaml:"disable"`
}

// IsZero reports whether the config declares no rubric.
func (c Config) IsZero() bool {
	return c.Preset == "" && len(c.Rules) == 0 && len(c.Disable) == 0
}

// ruleFn evaluates one rule against one change.
type ruleFn func(p params, c *ir.Change) []Finding

// rule is a built-in rule's implementation and documentation.
type rule struct {
	id   string
	doc  string
	eval ruleFn
}

// registry holds every built-in rule, keyed by ID. Adding a check means adding
// an entry here and, if a framework needs it, referencing it from a preset.
var registry = map[string]rule{}

func register(r rule) { registry[r.id] = r }

// RuleIDs returns every built-in rule ID, sorted.
func RuleIDs() []string {
	out := make([]string, 0, len(registry))
	for id := range registry {
		out = append(out, id)
	}
	sort.Strings(out)
	return out
}

// RuleDoc returns a rule's one-line description.
func RuleDoc(id string) string { return registry[id].doc }

// Presets returns the built-in preset names, sorted.
func Presets() []string {
	out := make([]string, 0, len(presets))
	for name := range presets {
		out = append(out, name)
	}
	sort.Strings(out)
	return out
}

// HasPreset reports whether name is a built-in preset.
func HasPreset(name string) bool {
	_, ok := presets[resolvePresetName(name)]
	return ok
}

// resolved is a rule ready to run.
type resolved struct {
	name     string
	severity Severity
	params   params
	eval     ruleFn
}

// instanceName is a rule config's identity: its explicit name, or its rule ID.
func (rc RuleConfig) instanceName() string {
	if rc.Name != "" {
		return rc.Name
	}
	return rc.ID
}

// Resolve expands the preset, merges local rules, applies Disable, and
// validates every ID. An unknown rule or preset is an error rather than a
// silent no-op, because a typo would otherwise read as a check that passes.
func Resolve(cfg Config) ([]resolved, error) {
	var merged []RuleConfig
	if cfg.Preset != "" {
		base, ok := presets[resolvePresetName(cfg.Preset)]
		if !ok {
			return nil, fmt.Errorf("unknown check preset %q; available: %s",
				cfg.Preset, strings.Join(Presets(), ", "))
		}
		merged = append(merged, base...)
	}
	merged = append(merged, cfg.Rules...)

	byName := map[string]int{}
	var ordered []RuleConfig
	for _, rc := range merged {
		if rc.ID == "" {
			return nil, fmt.Errorf("check rule needs an id")
		}
		if _, ok := registry[rc.ID]; !ok {
			return nil, fmt.Errorf("unknown check rule %q; available: %s",
				rc.ID, strings.Join(RuleIDs(), ", "))
		}
		name := rc.instanceName()
		if i, dup := byName[name]; dup {
			ordered[i] = rc
			continue
		}
		byName[name] = len(ordered)
		ordered = append(ordered, rc)
	}

	known := map[string]bool{}
	for _, rc := range ordered {
		known[rc.instanceName()] = true
	}
	disabled := map[string]bool{}
	for _, name := range cfg.Disable {
		if !known[name] {
			return nil, fmt.Errorf("cannot disable %q: no such rule in the resolved rubric", name)
		}
		disabled[name] = true
	}

	out := make([]resolved, 0, len(ordered))
	for _, rc := range ordered {
		if disabled[rc.instanceName()] {
			continue
		}
		sev := rc.Severity
		switch sev {
		case "":
			sev = SeverityError
		case SeverityError, SeverityWarn:
		default:
			return nil, fmt.Errorf("check rule %q has unknown severity %q; use error or warn", rc.ID, sev)
		}
		out = append(out, resolved{
			name: rc.instanceName(), severity: sev,
			params: params(rc.Params), eval: registry[rc.ID].eval,
		})
	}
	return out, nil
}

// Run evaluates the rubric over every change and returns a sorted report.
// Findings are ordered by change, then rule, then message, so output is stable
// across runs and diffable in CI.
func Run(cfg Config, changes []*ir.Change) (*Report, error) {
	rules, err := Resolve(cfg)
	if err != nil {
		return nil, err
	}
	rep := &Report{Findings: []Finding{}, Checked: []string{}}
	for _, c := range changes {
		if c == nil {
			continue
		}
		rep.Checked = append(rep.Checked, c.Name)

		// Every rule treats an absent artifact as nothing to check, so a change
		// with no artifacts at all would satisfy the whole rubric vacuously.
		// That is the one failure a gate must never report as a pass.
		if !hasAnyArtifact(c) {
			rep.Findings = append(rep.Findings, Finding{
				Rule: "change-has-artifacts", Severity: SeverityError, Change: c.Name,
				Msg: "change has no proposal, design, tasks, or specs; nothing could be checked",
			})
			continue
		}

		for _, r := range rules {
			for _, f := range r.eval(r.params, c) {
				f.Rule = r.name
				f.Severity = r.severity
				f.Change = c.Name
				rep.Findings = append(rep.Findings, f)
			}
		}
	}
	sort.Strings(rep.Checked)
	sort.SliceStable(rep.Findings, func(i, j int) bool {
		a, b := rep.Findings[i], rep.Findings[j]
		if a.Change != b.Change {
			return a.Change < b.Change
		}
		if a.Rule != b.Rule {
			return a.Rule < b.Rule
		}
		return a.Msg < b.Msg
	})
	return rep, nil
}

// hasAnyArtifact reports whether a change carries anything to check. A change
// with a single artifact is legitimately minimal; one with none is an empty
// directory.
func hasAnyArtifact(c *ir.Change) bool {
	return c.Proposal != nil || c.Design != nil || c.Tasks != nil || len(c.Specs) > 0
}

// params is a rule's parameter bag with typed readers. A missing parameter
// yields the zero value; each rule documents which it requires.
type params map[string]any

func (p params) String(key string) string {
	if v, ok := p[key]; ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return ""
}

// Strings reads a list parameter, tolerating a single scalar so a one-element
// list can be written without list syntax.
func (p params) Strings(key string) []string {
	v, ok := p[key]
	if !ok {
		return nil
	}
	switch t := v.(type) {
	case string:
		return []string{t}
	case []string:
		return t
	case []any:
		out := make([]string, 0, len(t))
		for _, e := range t {
			if s, ok := e.(string); ok {
				out = append(out, s)
			}
		}
		return out
	}
	return nil
}

// Int reads a whole-number parameter. YAML decodes an integer as int, and JSON
// as float64, so both are accepted. A missing or non-numeric value yields 0,
// which each rule reads as "unset" and skips on.
func (p params) Int(key string) int {
	switch t := p[key].(type) {
	case int:
		return t
	case int64:
		return int(t)
	case float64:
		return int(t)
	}
	return 0
}

// artifactText returns an artifact's retained raw markdown and the filename to
// report against it. An absent artifact yields ok=false, which every rule
// treats as "nothing to check" rather than a violation: an optional artifact
// that was not written is the author's choice, and a rule that requires it
// says so through required-sections instead.
func artifactText(c *ir.Change, artifact string) (text, file string, ok bool) {
	switch artifact {
	case "proposal":
		if c.Proposal == nil {
			return "", "", false
		}
		return c.Proposal.Raw, "proposal.md", true
	case "design":
		if c.Design == nil {
			return "", "", false
		}
		return c.Design.Raw, "design.md", true
	case "tasks":
		if c.Tasks == nil {
			return "", "", false
		}
		return c.Tasks.Raw, "tasks.md", true
	}
	return "", "", false
}

// allArtifacts returns every artifact's raw text paired with its filename,
// including one entry per spec, in a deterministic order.
func allArtifacts(c *ir.Change) []struct{ Text, File string } {
	var out []struct{ Text, File string }
	for _, name := range []string{"proposal", "design", "tasks"} {
		if text, file, ok := artifactText(c, name); ok {
			out = append(out, struct{ Text, File string }{text, file})
		}
	}
	specs := append([]*ir.Spec{}, c.Specs...)
	sort.SliceStable(specs, func(i, j int) bool { return specs[i].Capability < specs[j].Capability })
	for _, s := range specs {
		if s == nil {
			continue
		}
		out = append(out, struct{ Text, File string }{s.Raw, "specs/" + s.Capability + "/spec.md"})
	}
	return out
}
