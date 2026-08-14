package guard

import (
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"testing"
)

var networkPackages = map[string]bool{
	"net":           true,
	"net/http":      true,
	"net/http/cgi":  true,
	"net/http/fcgi": true,
	"net/rpc":       true,
	"net/smtp":      true,
	"net/mail":      true,
	"net/textproto": true,
}

func TestNoNetworkImportsInBinary(t *testing.T) {
	root := moduleRoot(t)
	fset := token.NewFileSet()

	err := filepath.WalkDir(root, func(path string, d os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			base := d.Name()
			if base == ".git" || base == "vendor" {
				return filepath.SkipDir
			}
			return nil
		}
		if !strings.HasSuffix(path, ".go") {
			return nil
		}

		if strings.HasSuffix(path, "_test.go") {
			return nil
		}

		f, perr := parser.ParseFile(fset, path, nil, parser.ImportsOnly)
		if perr != nil {
			t.Errorf("parsing %s: %v", path, perr)
			return nil
		}
		for _, imp := range f.Imports {
			p, uerr := strconv.Unquote(imp.Path.Value)
			if uerr != nil {
				continue
			}
			if networkPackages[p] {
				rel, _ := filepath.Rel(root, path)
				t.Errorf("network import %q in binary code path %s (line %d): the binary must perform no network I/O — delegate remote writes to the sync skills",
					p, rel, fset.Position(imp.Pos()).Line)
			}
		}
		return nil
	})
	if err != nil {
		t.Fatalf("walking module: %v", err)
	}
}

var cdnTag = regexp.MustCompile(`(?s)<(?:script|link)\b[^>]*?(?:src|href)="(https://[^"]+)"[^>]*>`)

var versionPin = regexp.MustCompile(`@\d+\.\d+\.\d+`)

func TestWebRuntimeIsPinnedCDN(t *testing.T) {
	root := moduleRoot(t)
	assets := filepath.Join(root, "internal", "web", "assets")

	for _, gone := range []string{"cytoscape.min.js", "dagre.min.js", "cytoscape-dagre.min.js", "system.css", "SYSTEM_CSS_VERSION"} {
		if _, err := os.Stat(filepath.Join(assets, gone)); err == nil {
			t.Errorf("vendored asset %s still on disk: the web viewer now loads its runtime from a pinned CDN, not vendored bundles", gone)
		}
	}

	tmpl, err := os.ReadFile(filepath.Join(assets, "page.html.tmpl"))
	if err != nil {
		t.Fatalf("reading page template: %v", err)
	}
	src := string(tmpl)

	for _, gone := range []string{"{{.CytoscapeJS}}", "{{.DagreJS}}", "{{.CytoscapeDagreJS}}", "{{.SystemCSS}}"} {
		if strings.Contains(src, gone) {
			t.Errorf("page template still inlines %s; the runtime now loads from a CDN", gone)
		}
	}

	for _, want := range []string{"{{.GraphJSON}}", "{{.DetailJSON}}"} {
		if !strings.Contains(src, want) {
			t.Errorf("page template must inline %s; the data feeds are never fetched at view time", want)
		}
	}

	tags := cdnTag.FindAllStringSubmatch(src, -1)
	if len(tags) == 0 {
		t.Fatal("no CDN <script>/<link> tags found; expected pinned Pico CSS and Chart.js references")
	}
	for _, m := range tags {
		tag, url := m[0], m[1]
		if !versionPin.MatchString(url) || strings.Contains(url, "@latest") {
			t.Errorf("CDN reference %q is not pinned to an exact version (want @x.y.z, no @latest)", url)
		}
		if !strings.Contains(tag, `integrity="sha`) {
			t.Errorf("CDN reference %q lacks an SRI integrity hash", url)
		}
		if !strings.Contains(tag, "crossorigin") {
			t.Errorf("CDN reference %q lacks crossorigin (required for SRI to be enforced)", url)
		}
		if !strings.Contains(tag, "onerror=") {
			t.Errorf("CDN reference %q lacks an onerror handler; an offline open must degrade loudly, not silently", url)
		}
	}
}

func TestWebFeedbackIsExportedNotPosted(t *testing.T) {
	root := moduleRoot(t)
	tmpl, err := os.ReadFile(filepath.Join(root, "internal", "web", "assets", "page.html.tmpl"))
	if err != nil {
		t.Fatalf("reading page template: %v", err)
	}
	src := string(tmpl)

	for _, banned := range []string{
		"fetch(", "XMLHttpRequest", "WebSocket", "sendBeacon",
		"EventSource", "<form", "document.cookie",
	} {
		if strings.Contains(src, banned) {
			t.Errorf("page template uses %q: reviewer feedback leaves this page as an exported document, never over a connection", banned)
		}
	}

	for _, want := range []string{"createObjectURL", "specutil.review/v1", "specutil review ingest"} {
		if !strings.Contains(src, want) {
			t.Errorf("page template is missing %q; the annotation export is the review loop's return path", want)
		}
	}
}

func moduleRoot(t *testing.T) string {
	t.Helper()
	dir, err := os.Getwd()
	if err != nil {
		t.Fatalf("getwd: %v", err)
	}
	for {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			t.Fatalf("could not locate go.mod above %s", dir)
		}
		dir = parent
	}
}
