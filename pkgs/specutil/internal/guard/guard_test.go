// Package guard hosts the determinism guard: a test asserting that no
// non-test code path in the binary imports a network package. This is the
// enforcement arm of the core invariant — the binary is pure and offline; all
// remote I/O is delegated to the agent via the shipped sync skills.
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

// networkPackages are stdlib import paths that perform outbound network I/O.
// net/url is intentionally excluded: it is pure parsing with no I/O.
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
			// Skip vendored, hidden, and the guard package's own dir is fine to scan
			// (this file is a _test.go and is excluded below).
			base := d.Name()
			if base == ".git" || base == "vendor" {
				return filepath.SkipDir
			}
			return nil
		}
		if !strings.HasSuffix(path, ".go") {
			return nil
		}
		// The determinism boundary governs binary code paths, not tests.
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

// cdnTag matches any <script src="https://…"> or <link href="https://…"> tag in
// the page template, capturing the whole tag (group 0) and its URL (group 1).
var cdnTag = regexp.MustCompile(`(?s)<(?:script|link)\b[^>]*?(?:src|href)="(https://[^"]+)"[^>]*>`)

// versionPin matches a jsdelivr/npm-style exact semver pin (@1.2.3) and rejects
// a floating @latest or bare major.
var versionPin = regexp.MustCompile(`@\d+\.\d+\.\d+`)

// TestWebRuntimeIsPinnedCDN guards the *presentation* half of the web viewer's
// trust boundary. The runtime is no longer vendored — Pico CSS and Chart.js load
// from a CDN at view time — so the guard inverts: the old bundles must be gone,
// the old inline template fields must be gone, and every CDN reference must be
// version-pinned with an SRI integrity hash, crossorigin, and an onerror handler
// so a supply-chain swap can't execute and an offline open degrades loudly
// rather than silently. The binary's own no-network guarantee is covered
// separately by TestNoNetworkImportsInBinary.
func TestWebRuntimeIsPinnedCDN(t *testing.T) {
	root := moduleRoot(t)
	assets := filepath.Join(root, "internal", "web", "assets")

	// The previously-vendored client runtime must no longer ship on disk.
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

	// The old inline-runtime fields must be gone from the template.
	for _, gone := range []string{"{{.CytoscapeJS}}", "{{.DagreJS}}", "{{.CytoscapeDagreJS}}", "{{.SystemCSS}}"} {
		if strings.Contains(src, gone) {
			t.Errorf("page template still inlines %s; the runtime now loads from a CDN", gone)
		}
	}

	// The data feeds must still be inlined as JS literals (no data files fetched).
	for _, want := range []string{"{{.GraphJSON}}", "{{.DetailJSON}}"} {
		if !strings.Contains(src, want) {
			t.Errorf("page template must inline %s; the data feeds are never fetched at view time", want)
		}
	}

	// Every CDN tag must be pinned + integrity-checked + cross-origin + guarded.
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

// TestWebFeedbackIsExportedNotPosted guards the annotation return path. The page
// collects a reviewer's comments, but it has nowhere to send them: there is no
// server behind it and the binary opens no socket. The loop closes when the
// reviewer hands the exported document to `specutil review ingest`.
//
// A future edit that "just posts it back" would need a listener, and a listener
// would put network I/O in the binary. This test is what makes that a failing
// build rather than a design drift nobody notices.
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

	// The export path itself must still be there, or the review loop has no
	// return leg at all.
	for _, want := range []string{"createObjectURL", "specutil.review/v1", "specutil review ingest"} {
		if !strings.Contains(src, want) {
			t.Errorf("page template is missing %q; the annotation export is the review loop's return path", want)
		}
	}
}

// moduleRoot walks up from the test's working directory until it finds go.mod.
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
