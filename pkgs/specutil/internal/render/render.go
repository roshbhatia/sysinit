package render

import (
	"bytes"
	"embed"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	sprig "github.com/Masterminds/sprig/v3"
	"github.com/roshbhatia/specutil/internal/export"
	"github.com/roshbhatia/specutil/internal/ir"
)

//go:embed templates/*.tmpl
var embeddedTemplates embed.FS

// placeholder marks a mapped target section whose IR source was absent. The
// section is still emitted (so the canonical skeleton stays intact) but flagged.
const placeholder = "_None provided._"

// Options controls a render invocation.
type Options struct {
	// OverrideDir, if non-empty, is searched for `<target>.md.tmpl` before the
	// embedded default. A missing file there falls back to embedded with a warning.
	OverrideDir string
	// Title overrides the document title; defaults to the change name.
	Title string
}

// templateData is the value passed to the Go template. Change is the raw IR for
// templates that need source fidelity; Export is the same change projected into
// tracker vocabulary, with no phase numbers or task identifiers.
type templateData struct {
	Title   string
	Change  *ir.Change
	Export  export.Change
	Section map[string]string
	Ticket  export.Ticket
}

// Render projects change into the named target, returning the rendered bytes and
// any warnings (e.g. absent source sections, override fallback). An unknown
// target is an error naming the supported set.
func Render(change *ir.Change, target string, opts Options) ([]byte, []ir.Warning, error) {
	mapping, ok := mappings[target]
	if !ok || internalTargets[target] {
		return nil, nil, fmt.Errorf("unknown render target %q; supported targets: %s",
			target, strings.Join(SupportedTargets(), ", "))
	}

	var warns []ir.Warning
	sections := make(map[string]string, len(mapping.Fields))
	for _, f := range mapping.Fields {
		content := strings.TrimSpace(f.Source(change))
		if content == "" {
			warns = append(warns, ir.Warning{
				File: change.Name,
				Msg:  fmt.Sprintf("render %s: source for section %q is absent; emitting placeholder", target, f.Key),
			})
			content = placeholder
		}
		sections[f.Key] = content
	}

	tmplText, tmplWarn, err := loadTemplate(target, opts.OverrideDir)
	if err != nil {
		return nil, warns, err
	}
	if tmplWarn != nil {
		warns = append(warns, *tmplWarn)
	}

	tmpl, err := template.New(target).Funcs(templateFuncs()).Parse(tmplText)
	if err != nil {
		return nil, warns, fmt.Errorf("parsing %s template: %w", target, err)
	}

	exported := export.BuildChange(change)
	title := opts.Title
	if title == "" {
		title = exported.Title
	}

	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, templateData{
		Title:   title,
		Change:  change,
		Export:  exported,
		Section: sections,
	}); err != nil {
		return nil, warns, fmt.Errorf("executing %s template: %w", target, err)
	}
	return buf.Bytes(), warns, nil
}

// templateFuncs merges Sprig with the helpers the shipped templates use. A
// local helper takes precedence on any name conflict.
func templateFuncs() template.FuncMap {
	funcs := sprig.FuncMap()
	funcs["section"] = func(m map[string]string, key string) string { return m[key] }
	return funcs
}

// TicketTarget and OverviewTarget are the template names for a single tracker
// ticket body and for the change-level container body. Both are deliberately
// target-neutral: Linear, Notion, and GitHub Issues all accept the same
// Markdown, so one template serves all three.
const (
	TicketTarget   = "ticket"
	OverviewTarget = "overview"
)

// RenderOverview renders the change-level body a tracker shows on the container
// it groups tickets under: a Linear project, a GitHub milestone, or a Notion
// page. The returned warning is non-nil when an override was requested but not
// found.
func RenderOverview(change *ir.Change, exported export.Change, overrideDir string) (string, *ir.Warning, error) {
	tmplText, tmplWarn, err := loadTemplate(OverviewTarget, overrideDir)
	if err != nil {
		return "", nil, err
	}
	summary := exported.Summary
	if summary == "" {
		summary = placeholder
	}
	tmpl, err := template.New(OverviewTarget).Funcs(templateFuncs()).Parse(tmplText)
	if err != nil {
		return "", nil, fmt.Errorf("parsing overview template: %w", err)
	}
	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, templateData{
		Title:   exported.Title,
		Change:  change,
		Export:  exported,
		Section: map[string]string{"summary": summary},
	}); err != nil {
		return "", nil, fmt.Errorf("executing overview template: %w", err)
	}
	return buf.String(), tmplWarn, nil
}

// RenderTicketBody renders the body an external tracker shows for one ticket.
// exported must be the projection of change. overrideDir follows the same
// semantics as Options.OverrideDir; the returned warning is non-nil when an
// override was requested but not found.
func RenderTicketBody(change *ir.Change, exported export.Change, ticket export.Ticket, overrideDir string) (string, *ir.Warning, error) {
	tmplText, tmplWarn, err := loadTemplate(TicketTarget, overrideDir)
	if err != nil {
		return "", nil, err
	}

	summary := exported.Summary
	if summary == "" {
		summary = placeholder
	}
	tmpl, err := template.New(TicketTarget).Funcs(templateFuncs()).Parse(tmplText)
	if err != nil {
		return "", nil, fmt.Errorf("parsing ticket template: %w", err)
	}

	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, templateData{
		Title:   ticket.Title,
		Change:  change,
		Export:  exported,
		Ticket:  ticket,
		Section: map[string]string{"summary": summary},
	}); err != nil {
		return "", nil, fmt.Errorf("executing ticket template: %w", err)
	}
	return buf.String(), tmplWarn, nil
}

// loadTemplate returns the template text for target, preferring an override file
// and falling back to the embedded default with a warning if the override dir is
// set but lacks the file.
func loadTemplate(target, overrideDir string) (string, *ir.Warning, error) {
	name := target + ".md.tmpl"
	if overrideDir != "" {
		path := filepath.Join(overrideDir, name)
		if b, err := os.ReadFile(path); err == nil {
			return string(b), nil, nil
		}
		w := ir.Warning{Msg: fmt.Sprintf("override template %s not found; using embedded default", path)}
		b, err := embeddedTemplates.ReadFile("templates/" + name)
		if err != nil {
			return "", &w, fmt.Errorf("embedded template %s missing: %w", name, err)
		}
		return string(b), &w, nil
	}
	b, err := embeddedTemplates.ReadFile("templates/" + name)
	if err != nil {
		return "", nil, fmt.Errorf("embedded template %s missing: %w", name, err)
	}
	return string(b), nil, nil
}
