// Package extract pulls schema-specific structure out of already-parsed IR.
//
// Spec frameworks layer conventions on top of plain markdown: a bullet that
// declares a fact about its block, or an inline key that references sibling
// tasks. specutil does not hard-code any one framework's conventions. Instead a
// repository declares them in openspec/specutil.yaml, and this package applies
// that declaration as a pure IR-to-IR pass.
//
// Two primitives cover the conventions seen in practice:
//
//	marker  a bullet of the form "- **NAME** value" that states a fact about
//	        the block it opens (a scenario's polarity, a phase's shape)
//	field   an inline "`key:` value" inside a task line (the tasks it depends
//	        on, an estimate, an owner)
//
// Running as a post-parse pass rather than inside the parser keeps every
// provider free of schema knowledge: openspec, bmad, plan, and script adapters
// all benefit without changes.
package extract

import (
	"fmt"
	"regexp"
	"sort"
	"strings"

	"github.com/roshbhatia/specutil/internal/ir"
)

// Scope names the IR block a marker or field attaches to.
type Scope string

const (
	ScopePhase       Scope = "phase"
	ScopeTask        Scope = "task"
	ScopeScenario    Scope = "scenario"
	ScopeRequirement Scope = "requirement"
)

// Scopes lists every recognized scope, sorted, for error messages.
func Scopes() []string {
	return []string{string(ScopePhase), string(ScopeRequirement), string(ScopeScenario), string(ScopeTask)}
}

// FieldType selects how a field's value is interpreted.
type FieldType string

const (
	// FieldString keeps the raw remainder of the line as a single value.
	FieldString FieldType = "string"
	// FieldList splits the value on commas and whitespace.
	FieldList FieldType = "list"
	// FieldTaskRefs is FieldList plus meaning: each value names another task in
	// the same change, and the pair becomes a dependency edge. The literal
	// "none" declares an explicit absence of dependencies.
	FieldTaskRefs FieldType = "taskRefs"
)

// FieldTypes lists every recognized field type, sorted, for error messages.
func FieldTypes() []string {
	return []string{string(FieldList), string(FieldString), string(FieldTaskRefs)}
}

// Marker declares a "- **NAME** value" bullet to lift out of a block.
type Marker struct {
	// Key is the name the extracted value is stored under.
	Key string `yaml:"key"`
	// Scope is the block the bullet attaches to.
	Scope Scope `yaml:"scope"`
	// Bullet is the bold token to match, without asterisks (e.g. "POLARITY").
	Bullet string `yaml:"bullet"`
}

// Field declares an inline "`key:` value" to lift out of a task line.
type Field struct {
	// Key is the name the extracted value is stored under.
	Key string `yaml:"key"`
	// Scope is the block the field attaches to. Only task is supported today.
	Scope Scope `yaml:"scope"`
	// Label is the inline key to match, without the colon (e.g. "deps").
	Label string `yaml:"label"`
	// Type selects how the value is interpreted. Empty means string.
	Type FieldType `yaml:"type"`
}

// Config is the repository's extraction declaration. An empty Config extracts
// nothing, which is the correct default for a repository using plain markdown.
type Config struct {
	// Preset names a built-in declaration to start from. Markers and Fields
	// declared alongside it are appended, and a later entry with the same key
	// and scope replaces the preset's.
	Preset  string   `yaml:"preset"`
	Markers []Marker `yaml:"markers"`
	Fields  []Field  `yaml:"fields"`
}

// IsZero reports whether the config declares nothing.
func (c Config) IsZero() bool {
	return c.Preset == "" && len(c.Markers) == 0 && len(c.Fields) == 0
}

// presets are the built-in declarations, keyed by the spec-framework schema
// name they describe. They are data, not behavior: nothing else in specutil
// branches on a schema name.
var presets = map[string]Config{
	// spec-driven declares scenario polarity, phase shape with its loop bounds,
	// and intra-phase task dependencies.
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

// Resolve expands cfg's preset and validates the result. A declaration that
// names an unknown preset, scope, or type is an error rather than a silent
// no-op, because a typo in a marker name would otherwise look like a schema
// that simply never uses that marker.
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

// markerRe matches a declared marker bullet, capturing the bold token and the
// remainder. Leading "- " is already stripped by the list parser for task and
// scenario bullets, so it is optional here.
var markerRe = regexp.MustCompile(`^-?\s*\*\*([A-Za-z][A-Za-z0-9_-]*)\*\*\s*:?\s*(.*)$`)

// valueSplitRe splits a list value on commas, backticks, and whitespace.
var valueSplitRe = regexp.MustCompile("[,`\\s]+")

// Apply runs the extraction over a change in place. It removes every consumed
// marker bullet and inline field from the prose it was embedded in, so a
// renderer never shows a reader the raw convention. Warnings report a declared
// dependency that names no sibling task.
//
// Apply is idempotent: running it twice yields the same IR, because the markers
// it consumes are gone after the first pass.
func Apply(cfg Config, c *ir.Change) []ir.Warning {
	if c == nil || cfg.IsZero() {
		return nil
	}
	var warns []ir.Warning
	applyPhases(cfg, c, &warns)
	applySpecs(cfg, c)
	return warns
}

// applyPhases lifts phase markers out of the retained non-checkbox bullets and
// task fields out of each task's text, then resolves dependency references.
func applyPhases(cfg Config, c *ir.Change, warns *[]ir.Warning) {
	if c.Tasks == nil {
		return
	}
	phaseMarkers := markersFor(cfg, ScopePhase)
	taskFields := cfg.Fields

	// Every task id in the change, so a dependency reference can be checked.
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

// applySpecs lifts requirement and scenario markers out of their bullet lists.
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

// markersFor returns the markers declared for one scope.
func markersFor(cfg Config, scope Scope) []Marker {
	var out []Marker
	for _, m := range cfg.Markers {
		if m.Scope == scope {
			out = append(out, m)
		}
	}
	return out
}

// liftMarkers pulls every declared marker out of lines, returning the extracted
// values and the lines that remain. A line that looks like a marker but names an
// undeclared token is left in place: it belongs to the prose, not to us.
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

// liftFields pulls every declared inline field out of a task line, returning the
// values, the cleaned text, and the flattened task references from any
// taskRefs-typed field. The literal "none" declares an explicit absence and
// yields no references.
func liftFields(fields []Field, text string) (map[string][]string, string, []string) {
	var found map[string][]string
	var refs []string
	cleaned := text

	for _, f := range fields {
		// The label is conventionally written as `deps:` in backticks, but a
		// plain deps: must match too so the convention survives reformatting.
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

// taskRefRe matches a dotted task identifier (1.2) or the literal none.
var taskRefRe = regexp.MustCompile(`^(?:\d+(?:\.\d+)+|none)$`)

// fieldValue reads a field's value from the text following its label and
// reports how many bytes it consumed. A string field takes the rest of the
// line; list and taskRefs fields take the leading run of value tokens, so
// trailing prose after the value survives.
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

// aliases map retired schema names onto a live preset key. Archived changes pin
// a schema in their .openspec.yaml and are history: rewriting them to chase a
// rename would falsify the record, so the rename carries its old name forward
// instead. Resolution consults aliases only after a direct hit fails, so an
// alias can never shadow a real preset.
var aliases = map[string]string{
	"rosh-spec-driven": "spec-driven",
}

// resolvePresetName returns the live preset key for name.
func resolvePresetName(name string) string {
	if _, ok := presets[name]; ok {
		return name
	}
	if target, ok := aliases[name]; ok {
		return target
	}
	return name
}
