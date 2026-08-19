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
	"github.com/roshbhatia/sysinit/pkgs/specutil/internal/export"
	"github.com/roshbhatia/sysinit/pkgs/specutil/internal/ir"
)

//go:embed templates/*.tmpl
var embeddedTemplates embed.FS

const placeholder = "_None provided._"

type Options struct {
	OverrideDir string

	Title string
}

type templateData struct {
	Title   string
	Change  *ir.Change
	Export  export.Change
	Section map[string]string
	Ticket  export.Ticket
}

func Render(change *ir.Change, target string, opts Options) ([]byte, []ir.Warning, error) {
	mapping, ok := mappings[target]
	if !ok {
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

func templateFuncs() template.FuncMap {
	funcs := sprig.FuncMap()
	funcs["section"] = func(m map[string]string, key string) string { return m[key] }
	return funcs
}

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
