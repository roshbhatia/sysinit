package extract

import (
	"fmt"
	"regexp"
	"sort"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/specutil/internal/ir"
)

type Scope string

const (
	ScopePhase       Scope = "phase"
	ScopeTask        Scope = "task"
	ScopeScenario    Scope = "scenario"
	ScopeRequirement Scope = "requirement"
)

func Scopes() []string {
	return []string{string(ScopePhase), string(ScopeRequirement), string(ScopeScenario), string(ScopeTask)}
}

type FieldType string

const (
	FieldString FieldType = "string"

	FieldList FieldType = "list"

	FieldTaskRefs FieldType = "taskRefs"
)

func FieldTypes() []string {
	return []string{string(FieldList), string(FieldString), string(FieldTaskRefs)}
}

type Marker struct {
	Key string `yaml:"key"`

	Scope Scope `yaml:"scope"`

	Bullet string `yaml:"bullet"`
}

type Field struct {
	Key string `yaml:"key"`

	Scope Scope `yaml:"scope"`

	Label string `yaml:"label"`

	Type FieldType `yaml:"type"`
}

type Config struct {
	Preset  string   `yaml:"preset"`
	Markers []Marker `yaml:"markers"`
	Fields  []Field  `yaml:"fields"`
}

func (c Config) IsZero() bool {
	return c.Preset == "" && len(c.Markers) == 0 && len(c.Fields) == 0
}

var presets = map[string]Config{
	"spec-driven": {
		Markers: []Marker{
			{Key: "polarity", Scope: ScopeScenario, Bullet: "POLARITY"},
			{Key: "shape", Scope: ScopePhase, Bullet: "SHAPE"},
			{Key: "stop", Scope: ScopePhase, Bullet: "STOP"},
			{Key: "maxIters", Scope: ScopePhase, Bullet: "MAX-ITERS"},
		},
		Fields: []Field{
			{Key: "deps", Scope: ScopeTask, Label: "deps", Type: FieldTaskRefs},
		},
	},
}

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

func Resolve(cfg Config) (Config, error) {
	out := Config{Preset: cfg.Preset}
	if cfg.Preset != "" {
		base, ok := presets[resolvePresetName(cfg.Preset)]
		if !ok {
			return Config{}, fmt.Errorf("unknown extract preset %q; available: %s",
				cfg.Preset, strings.Join(Presets(), ", "))
		}
		out.Markers = append(out.Markers, base.Markers...)
		out.Fields = append(out.Fields, base.Fields...)
	}
	out.Markers = append(out.Markers, cfg.Markers...)
	out.Fields = append(out.Fields, cfg.Fields...)

	markers := make([]Marker, 0, len(out.Markers))
	seenMarker := map[string]int{}
	for _, m := range out.Markers {
		if m.Key == "" || m.Bullet == "" {
			return Config{}, fmt.Errorf("extract marker needs both key and bullet, got %+v", m)
		}
		if !validScope(m.Scope) {
			return Config{}, fmt.Errorf("extract marker %q has unknown scope %q; available: %s",
				m.Key, m.Scope, strings.Join(Scopes(), ", "))
		}
		id := string(m.Scope) + "\x00" + m.Key
		if i, dup := seenMarker[id]; dup {
			markers[i] = m
			continue
		}
		seenMarker[id] = len(markers)
		markers = append(markers, m)
	}
	out.Markers = markers

	fields := make([]Field, 0, len(out.Fields))
	seenField := map[string]int{}
	for _, f := range out.Fields {
		if f.Key == "" || f.Label == "" {
			return Config{}, fmt.Errorf("extract field needs both key and label, got %+v", f)
		}
		if f.Scope == "" {
			f.Scope = ScopeTask
		}
		if f.Scope != ScopeTask {
			return Config{}, fmt.Errorf("extract field %q has scope %q; only %q is supported",
				f.Key, f.Scope, ScopeTask)
		}
		if f.Type == "" {
			f.Type = FieldString
		}
		if !validFieldType(f.Type) {
			return Config{}, fmt.Errorf("extract field %q has unknown type %q; available: %s",
				f.Key, f.Type, strings.Join(FieldTypes(), ", "))
		}
		id := string(f.Scope) + "\x00" + f.Key
		if i, dup := seenField[id]; dup {
			fields[i] = f
			continue
		}
		seenField[id] = len(fields)
		fields = append(fields, f)
	}
	out.Fields = fields
	return out, nil
}

func validScope(s Scope) bool {
	switch s {
	case ScopePhase, ScopeTask, ScopeScenario, ScopeRequirement:
		return true
	}
	return false
}

func validFieldType(t FieldType) bool {
	switch t {
	case FieldString, FieldList, FieldTaskRefs:
		return true
	}
	return false
}

var markerRe = regexp.MustCompile(`^-?\s*\*\*([A-Za-z][A-Za-z0-9_-]*)\*\*\s*:?\s*(.*)$`)

var valueSplitRe = regexp.MustCompile("[,`\\s]+")

func Apply(cfg Config, c *ir.Change) []ir.Warning {
	if c == nil || cfg.IsZero() {
		return nil
	}
	var warns []ir.Warning
	applyPhases(cfg, c, &warns)
	applySpecs(cfg, c)
	return warns
}

func applyPhases(cfg Config, c *ir.Change, warns *[]ir.Warning) {
	if c.Tasks == nil {
		return
	}
	phaseMarkers := markersFor(cfg, ScopePhase)
	taskFields := cfg.Fields

	known := map[string]bool{}
	for _, p := range c.Tasks.Phases {
		for _, it := range p.Items {
			if it.ID != "" {
				known[it.ID] = true
			}
		}
	}

	for pi := range c.Tasks.Phases {
		p := &c.Tasks.Phases[pi]
		if len(phaseMarkers) > 0 {
			if found, kept := liftMarkers(phaseMarkers, p.Notes); found != nil {
				p.Markers, p.Notes = found, kept
			}
		}
		for ii := range p.Items {
			it := &p.Items[ii]
			if len(taskFields) == 0 {
				continue
			}
			found, cleaned, deps := liftFields(taskFields, it.Text)
			if found == nil {
				continue
			}
			it.Fields, it.Text = found, cleaned
			for _, ref := range deps {
				if !known[ref] {
					*warns = append(*warns, ir.Warning{
						File: "tasks.md",
						Msg: fmt.Sprintf("task %s declares a dependency on %q, which names no task in this change",
							it.ID, ref),
					})
					continue
				}
				if ref == it.ID {
					*warns = append(*warns, ir.Warning{
						File: "tasks.md",
						Msg:  fmt.Sprintf("task %s declares a dependency on itself", it.ID),
					})
					continue
				}
				it.DependsOn = append(it.DependsOn, ref)
			}
		}
	}
}

func applySpecs(cfg Config, c *ir.Change) {
	reqMarkers := markersFor(cfg, ScopeRequirement)
	scMarkers := markersFor(cfg, ScopeScenario)
	if len(reqMarkers) == 0 && len(scMarkers) == 0 {
		return
	}
	for _, s := range c.Specs {
		if s == nil {
			continue
		}
		for ri := range s.Requirements {
			r := &s.Requirements[ri]
			if len(reqMarkers) > 0 {
				if found, kept := liftMarkers(reqMarkers, strings.Split(r.Text, "\n")); found != nil {
					r.Markers = found
					r.Text = strings.TrimSpace(strings.Join(kept, "\n"))
				}
			}
			for si := range r.Scenarios {
				sc := &r.Scenarios[si]
				if len(scMarkers) == 0 {
					continue
				}
				if found, kept := liftMarkers(scMarkers, sc.Steps); found != nil {
					sc.Markers, sc.Steps = found, kept
				}
			}
		}
	}
}

func markersFor(cfg Config, scope Scope) []Marker {
	var out []Marker
	for _, m := range cfg.Markers {
		if m.Scope == scope {
			out = append(out, m)
		}
	}
	return out
}

func liftMarkers(markers []Marker, lines []string) (map[string]string, []string) {
	byBullet := make(map[string]string, len(markers))
	for _, m := range markers {
		byBullet[strings.ToUpper(m.Bullet)] = m.Key
	}

	var found map[string]string
	kept := make([]string, 0, len(lines))
	for _, line := range lines {
		m := markerRe.FindStringSubmatch(strings.TrimSpace(line))
		if m == nil {
			kept = append(kept, line)
			continue
		}
		key, ok := byBullet[strings.ToUpper(m[1])]
		if !ok {
			kept = append(kept, line)
			continue
		}
		if found == nil {
			found = map[string]string{}
		}
		found[key] = strings.TrimSpace(m[2])
	}
	if found == nil {
		return nil, lines
	}
	return found, kept
}

func liftFields(fields []Field, text string) (map[string][]string, string, []string) {
	var found map[string][]string
	var refs []string
	cleaned := text

	for _, f := range fields {
		re := regexp.MustCompile("`?\\b" + regexp.QuoteMeta(f.Label) + ":`?\\s*")
		loc := re.FindStringIndex(cleaned)
		if loc == nil {
			continue
		}
		rest := cleaned[loc[1]:]
		value, consumed := fieldValue(f, rest)
		cleaned = strings.TrimSpace(cleaned[:loc[0]] + rest[consumed:])

		if found == nil {
			found = map[string][]string{}
		}
		found[f.Key] = value
		if f.Type == FieldTaskRefs {
			refs = append(refs, value...)
		}
	}
	return found, strings.TrimSpace(cleaned), refs
}

var taskRefRe = regexp.MustCompile(`^(?:\d+(?:\.\d+)+|none)$`)

func fieldValue(f Field, rest string) ([]string, int) {
	if f.Type == FieldString {
		return []string{strings.TrimSpace(rest)}, len(rest)
	}

	var out []string
	consumed := 0
	for consumed < len(rest) {
		next := valueSplitRe.FindStringIndex(rest[consumed:])
		end := len(rest)
		sepEnd := end
		if next != nil && next[0] > 0 {
			end = consumed + next[0]
			sepEnd = consumed + next[1]
		} else if next != nil && next[0] == 0 {
			consumed = consumed + next[1]
			continue
		}
		tok := strings.Trim(rest[consumed:end], "`,")
		if tok == "" {
			consumed = sepEnd
			continue
		}
		if f.Type == FieldTaskRefs && !taskRefRe.MatchString(tok) {
			break
		}
		if !(f.Type == FieldTaskRefs && tok == "none") {
			out = append(out, tok)
		}
		consumed = sepEnd
		if next == nil {
			break
		}
	}
	return out, consumed
}

var aliases = map[string]string{
	"rosh-spec-driven": "spec-driven",
}

func resolvePresetName(name string) string {
	if _, ok := presets[name]; ok {
		return name
	}
	if target, ok := aliases[name]; ok {
		return target
	}
	return name
}
