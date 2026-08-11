package vcs_test

import (
	"strings"
	"testing"

	"github.com/roshbhatia/specutil/internal/vcs"
)

const sample = `diff --git a/internal/auth/token.go b/internal/auth/token.go
index 1111111..2222222 100644
--- a/internal/auth/token.go
+++ b/internal/auth/token.go
@@ -10,7 +10,9 @@ func Issue(sub string) (string, error) {
 	claims := jwt.MapClaims{
 		"sub": sub,
 	}
-	return sign(claims)
+	claims["exp"] = time.Now().Add(ttl).Unix()
+	return sign(claims)
+}
 }
diff --git a/README.md b/README.md
new file mode 100644
--- /dev/null
+++ b/README.md
@@ -0,0 +1,2 @@
+# Title
+Body
diff --git a/old.txt b/new.txt
similarity index 90%
rename from old.txt
rename to new.txt
diff --git a/logo.png b/logo.png
index 3333333..4444444 100644
Binary files a/logo.png and b/logo.png differ
`

func TestParseFilesAndStatuses(t *testing.T) {
	files := vcs.Parse(sample)
	if len(files) != 4 {
		t.Fatalf("got %d files, want 4: %+v", len(files), files)
	}
	want := map[string]string{
		"internal/auth/token.go": vcs.StatusModified,
		"README.md":              vcs.StatusAdded,
		"new.txt":                vcs.StatusRenamed,
		"logo.png":               vcs.StatusBinary,
	}
	for _, f := range files {
		if want[f.Path] == "" {
			t.Errorf("unexpected file %q", f.Path)
			continue
		}
		if f.Status != want[f.Path] {
			t.Errorf("%s: got status %q, want %q", f.Path, f.Status, want[f.Path])
		}
	}
}

func TestParseCountsLinesAndNumbersThem(t *testing.T) {
	files := vcs.Parse(sample)
	var tok vcs.File
	for _, f := range files {
		if f.Path == "internal/auth/token.go" {
			tok = f
		}
	}
	if len(tok.Hunks) != 1 {
		t.Fatalf("got %d hunks, want 1", len(tok.Hunks))
	}
	h := tok.Hunks[0]
	if h.OldStart != 10 || h.NewStart != 10 {
		t.Errorf("hunk starts: got old=%d new=%d, want 10/10", h.OldStart, h.NewStart)
	}

	var adds, dels int
	for _, l := range h.Lines {
		switch l.Kind {
		case vcs.LineAdd:
			adds++
		case vcs.LineDelete:
			dels++
		}
	}
	if adds != 3 || dels != 1 {
		t.Errorf("got +%d -%d, want +3 -1", adds, dels)
	}

	d := &vcs.Diff{Files: files}
	gotFiles, gotAdd, gotDel := d.Stats()
	if gotFiles != 4 || gotAdd != 5 || gotDel != 1 {
		t.Errorf("stats: got %d files +%d -%d, want 4 +5 -1", gotFiles, gotAdd, gotDel)
	}
}

// A hunk's identity must not move when unrelated edits shift its line numbers,
// or every comment written against it would be orphaned by the next save.
func TestHunkIdentityIgnoresLineNumbersAndContext(t *testing.T) {
	base := vcs.Parse(sample)[0].Hunks[0].Identity

	shifted := strings.Replace(sample, "@@ -10,7 +10,9 @@", "@@ -420,7 +436,9 @@", 1)
	if got := vcs.Parse(shifted)[0].Hunks[0].Identity; got != base {
		t.Errorf("shifting line numbers changed the identity: %s vs %s", got, base)
	}

	recontexted := strings.Replace(sample, ` 	claims := jwt.MapClaims{`, ` 	claims := jwt.MapClaims{ // note`, 1)
	if got := vcs.Parse(recontexted)[0].Hunks[0].Identity; got != base {
		t.Errorf("editing surrounding context changed the identity: %s vs %s", got, base)
	}

	edited := strings.Replace(sample, `+	claims["exp"] = time.Now().Add(ttl).Unix()`, `+	claims["exp"] = deadline`, 1)
	if got := vcs.Parse(edited)[0].Hunks[0].Identity; got == base {
		t.Error("editing a changed line must change the identity")
	}
}

func TestParseIsTolerantOfGarbage(t *testing.T) {
	if files := vcs.Parse(""); len(files) != 0 {
		t.Errorf("empty input should yield no files, got %+v", files)
	}
	if files := vcs.Parse("not a diff at all\njust some text\n"); len(files) != 0 {
		t.Errorf("non-diff input should yield no files, got %+v", files)
	}
}

func TestCollectOutsideAGitTreeIsNotAnError(t *testing.T) {
	d, err := vcs.Collect(t.TempDir(), "", nil)
	if err != nil {
		t.Fatalf("a non-git directory must degrade, not fail: %v", err)
	}
	if d.Note == "" {
		t.Error("an empty diff needs a stated reason so a reader is not left guessing")
	}
	if len(d.Files) != 0 {
		t.Errorf("got %d files, want 0", len(d.Files))
	}
}

func TestTextLeadsWithTheSummary(t *testing.T) {
	d := &vcs.Diff{Base: "HEAD", Files: vcs.Parse(sample)}
	out := d.Text()
	if !strings.HasPrefix(out, "4 files changed against HEAD: +5 -1") {
		t.Errorf("the summary must come first, got: %s", strings.SplitN(out, "\n", 2)[0])
	}
	if !strings.Contains(out, "internal/auth/token.go (modified)") {
		t.Errorf("output missing a file heading: %s", out)
	}
}
