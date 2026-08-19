package check

import (
	"fmt"
	"sort"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/specutil/internal/ir"
)

type Severity string

const (
	SeverityError Severity = "error"
	SeverityWarn  Severity = "warn"
)

type Finding struct {
	Rule     string   `json:"rule"`
	Severity Severity `json:"severity"`
	Change   string   `json:"change"`
	File     string   `json:"file,omitempty"`
	Line     int      `json:"line,omitempty"`
	Msg      string   `json:"msg"`
}

type Report struct {
	Findings []Finding `json:"findings"`
	Checked  []string  `json:"checked"`
}

func (r *Report) Errors() int {
	n := 0
	for _, f := range r.Findings {
		if f.Severity == SeverityError {
			n++
		}
	}
	return n
}

func (r *Report) Warnings() int { return len(r.Findings) - r.Errors() }

func (r *Report) OK() bool { return r.Errors() == 0 }

type RuleConfig struct {
	ID string `yaml:"id"`

	Name string `yaml:"name"`

	Severity Severity `yaml:"severity"`

	Params map[string]any `yaml:",inline"`
}

type Config struct {
	Preset string `yaml:"preset"`

	Rules []RuleConfig `yaml:"rules"`

	Disable []string `yaml:"disable"`
}

func (c Config) IsZero() bool {
	return c.Preset == "" && len(c.Rules) == 0 && len(c.Disable) == 0
}

type ruleFn func(p params, c *ir.Change) []Finding

type rule struct {
	id   string
	doc  string
	eval ruleFn
}

var registry = map[string]rule{}

func register(r rule) { registry[r.id] = r }

func RuleIDs() []string {
	out := make([]string, 0, len(registry))
	for id := range registry {
		out = append(out, id)
	}
	sort.Strings(out)
	return out
}

func RuleDoc(id string) string { return registry[id].doc }

func Presets() []string {
	out := make([]string, 0, len(presets))
	for name := range presets {
		out = append(out, name)
	}
	sort.Strings(out)
	return out
}

func HasPreset(name string) bool {
	_, ok := presets[resolvePresetName(name)]
	return ok
}

type resolved struct {
	name     string
	severity Severity
	params   params
	eval     ruleFn
}

func (rc RuleConfig) instanceName() string {
	if rc.Name != "" {
		return rc.Name
	}
	return rc.ID
}

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

func hasAnyArtifact(c *ir.Change) bool {
	return c.Proposal != nil || c.Design != nil || c.Tasks != nil || len(c.Specs) > 0
}

type params map[string]any

func (p params) String(key string) string {
	if v, ok := p[key]; ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return ""
}

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
