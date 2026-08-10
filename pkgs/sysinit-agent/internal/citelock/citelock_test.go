package citelock

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"
)

// capturedRecord writes a lock, a snapshot, and a provenance sidecar that all
func capturedRecord(t *testing.T, dir string, rec Record, body string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Join(dir, snapDirName), 0o755); err != nil {
		t.Fatal(err)
	}
	snap := filepath.Join(dir, rec.Snapshot)
	if err := os.WriteFile(snap, []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}
	sum := sha256.Sum256([]byte(body))
	digest := hex.EncodeToString(sum[:])
	if rec.SHA256 == "" {
		rec.SHA256 = digest
	}
	sidecar := `{"url":"` + rec.Source + `","http_status":200,"engine":"curl","sha256":"` + digest + `"}`
	if err := os.WriteFile(snap+".prov.json", []byte(sidecar), 0o644); err != nil {
		t.Fatal(err)
	}
	writeLock(t, dir, rec)
}

func writeLock(t *testing.T, dir string, records ...Record) {
	t.Helper()
	raw := make([]json.RawMessage, 0, len(records))
	for _, rec := range records {
		encoded, err := json.Marshal(rec)
		if err != nil {
			t.Fatal(err)
		}
		raw = append(raw, encoded)
	}
	data, err := json.Marshal(lockfile{Records: raw})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(lockPath(dir), data, 0o644); err != nil {
		t.Fatal(err)
	}
}

func goodRecord() Record {
	return Record{
		ID:         "example",
		Source:     "https://example.com/doc",
		Accessed:   time.Now().Format("2006-01-02"),
		ClaimClass: "api",
		Quote:      "the verbatim quote",
		Snapshot:   filepath.Join(snapDirName, "example.snapshot"),
	}
}

// stderr captures the diagnostics, which are the gate's whole output.
func stderr(t *testing.T, fn func() error) (error, string) {
	t.Helper()
	old := os.Stderr
	r, w, err := os.Pipe()
	if err != nil {
		t.Fatal(err)
	}
	os.Stderr = w
	var out strings.Builder
	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		buf := make([]byte, 4096)
		for {
			n, err := r.Read(buf)
			out.Write(buf[:n])
			if err != nil {
				return
			}
		}
	}()
	callErr := fn()
	w.Close()
	wg.Wait()
	os.Stderr = old
	return callErr, out.String()
}

func TestVerifyIsANoOpWithNoLockfile(t *testing.T) {
	dir := t.TempDir()
	err, out := stderr(t, func() error { return verify(dir) })
	if err != nil {
		t.Fatalf("verify on a lockless directory failed: %v", err)
	}
	if !strings.Contains(out, "nothing to verify") {
		t.Fatalf("verify exited 0 without taking the no-op path: %s", out)
	}
}

func TestVerifyAcceptsAWellFormedRecord(t *testing.T) {
	dir := t.TempDir()
	capturedRecord(t, dir, goodRecord(), "prelude the verbatim quote postlude")
	err, out := stderr(t, func() error { return verify(dir) })
	if err != nil {
		t.Fatalf("verify rejected a good record: %v: %s", err, out)
	}
	if !strings.Contains(out, "offline gate passed") {
		t.Fatalf("verify passed without saying so: %s", out)
	}
}

func TestVerifyRejectsARecordMissingEveryField(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(lockPath(dir), []byte(`{"records":[{"id":"unanchored"}]}`), 0o644); err != nil {
		t.Fatal(err)
	}
	err, out := stderr(t, func() error { return verify(dir) })
	if err == nil {
		t.Fatal("verify accepted a record with no source, quote, snapshot, or sha256")
	}
	if !strings.Contains(out, "[unanchored] format:") {
		t.Fatalf("verify rejected the bad lock for the wrong reason: %s", out)
	}
}

func TestVerifyRejectsAMissingSnapshot(t *testing.T) {
	dir := t.TempDir()
	rec := goodRecord()
	rec.SHA256 = strings.Repeat("a", 64)
	writeLock(t, dir, rec)
	err, out := stderr(t, func() error { return verify(dir) })
	if err == nil {
		t.Fatal("verify accepted a record whose snapshot is absent")
	}
	if !strings.Contains(out, "snapshot missing") {
		t.Fatalf("wrong diagnostic: %s", out)
	}
}

func TestVerifyRejectsAHandAuthoredSnapshot(t *testing.T) {
	dir := t.TempDir()
	body := "prelude the verbatim quote postlude"
	capturedRecord(t, dir, goodRecord(), body)
	if err := os.Remove(filepath.Join(dir, goodRecord().Snapshot+".prov.json")); err != nil {
		t.Fatal(err)
	}
	err, out := stderr(t, func() error { return verify(dir) })
	if err == nil {
		t.Fatal("verify accepted a snapshot with no capture provenance")
	}
	if !strings.Contains(out, "hand-authored snapshots are rejected") {
		t.Fatalf("wrong diagnostic: %s", out)
	}
}

func TestVerifyRejectsAnEditedSnapshot(t *testing.T) {
	dir := t.TempDir()
	rec := goodRecord()
	capturedRecord(t, dir, rec, "prelude the verbatim quote postlude")
	if err := os.WriteFile(filepath.Join(dir, rec.Snapshot), []byte("the verbatim quote, edited"), 0o644); err != nil {
		t.Fatal(err)
	}
	err, out := stderr(t, func() error { return verify(dir) })
	if err == nil {
		t.Fatal("verify accepted a snapshot whose hash no longer matches")
	}
	if !strings.Contains(out, "snapshot sha256 mismatch") {
		t.Fatalf("wrong diagnostic: %s", out)
	}
}

func TestVerifyRejectsASidecarThatDisagreesWithTheRecord(t *testing.T) {
	dir := t.TempDir()
	rec := goodRecord()
	body := "prelude the verbatim quote postlude"
	capturedRecord(t, dir, rec, body)
	sidecar := `{"url":"x","http_status":200,"engine":"curl","sha256":"` + strings.Repeat("b", 64) + `"}`
	if err := os.WriteFile(filepath.Join(dir, rec.Snapshot+".prov.json"), []byte(sidecar), 0o644); err != nil {
		t.Fatal(err)
	}
	err, out := stderr(t, func() error { return verify(dir) })
	if err == nil {
		t.Fatal("verify accepted a provenance sidecar that disagrees with the record")
	}
	if !strings.Contains(out, "provenance sha256 does not match record") {
		t.Fatalf("wrong diagnostic: %s", out)
	}
}

func TestVerifyRejectsAQuoteThatDoesNotAnchor(t *testing.T) {
	dir := t.TempDir()
	capturedRecord(t, dir, goodRecord(), "prelude a similar but different quote postlude")
	err, out := stderr(t, func() error { return verify(dir) })
	if err == nil {
		t.Fatal("verify accepted a quote that is not in the snapshot")
	}
	if !strings.Contains(out, "unanchored") {
		t.Fatalf("wrong diagnostic: %s", out)
	}
}

func TestVerifyEnforcesTheFreshnessWindowPerClass(t *testing.T) {
	body := "prelude the verbatim quote postlude"
	cases := []struct {
		class   string
		ageDays int
		stale   bool
	}{
		{"pricing", 31, true},
		{"pricing", 29, false},
		{"availability", 31, true},
		{"api", 91, true},
		{"api", 89, false},
		{"paper", 10000, false},
		{"other", 181, true},
		{"other", 179, false},
	}
	for _, tc := range cases {
		dir := t.TempDir()
		rec := goodRecord()
		rec.ClaimClass = tc.class
		rec.Accessed = time.Now().AddDate(0, 0, -tc.ageDays).Format("2006-01-02")
		capturedRecord(t, dir, rec, body)

		err, out := stderr(t, func() error { return verify(dir) })
		if tc.stale && err == nil {
			t.Errorf("%s at %dd should be stale", tc.class, tc.ageDays)
		}
		if !tc.stale && err != nil {
			t.Errorf("%s at %dd should be fresh: %s", tc.class, tc.ageDays, out)
		}
	}
}

func TestVerifyRejectsAnUnparseableAccessedDate(t *testing.T) {
	dir := t.TempDir()
	rec := goodRecord()
	rec.Accessed = "last tuesday"
	capturedRecord(t, dir, rec, "prelude the verbatim quote postlude")
	err, out := stderr(t, func() error { return verify(dir) })
	if err == nil {
		t.Fatal("verify accepted an unparseable accessed date")
	}
	if !strings.Contains(out, "unparseable accessed date") {
		t.Fatalf("wrong diagnostic: %s", out)
	}
}

func TestVerifyReportsEveryBadRecordNotJustTheFirst(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(lockPath(dir), []byte(
		`{"records":[{"id":"one"},{"source":"https://example.com"},{"id":"three"}]}`), 0o644); err != nil {
		t.Fatal(err)
	}
	err, out := stderr(t, func() error { return verify(dir) })
	if err == nil {
		t.Fatal("verify accepted three malformed records")
	}
	for _, want := range []string{"[one] format:", "[null] format:", "[three] format:"} {
		if !strings.Contains(out, want) {
			t.Errorf("missing diagnostic %q in:\n%s", want, out)
		}
	}
}

func TestAssertSafeURLRefusesEveryUnsafeHost(t *testing.T) {
	unsafe := []string{
		"http://example.com/x",
		"ftp://example.com/x",
		"https://localhost/x",
		"https://api.localhost/x",
		"https://[::1]/x",
		"https://metadata.google.internal/computeMetadata/v1/",
		"https://foo.internal/x",
		"https://127.0.0.1/x",
		"https://0.0.0.0/x",
		"https://169.254.169.254/latest/meta-data/",
		"https://10.1.2.3/x",
		"https://192.168.1.1/x",
		"https://172.16.0.1/x",
		"https://172.31.255.255/x",
		"https://0x7f000001/x",
		"https://2130706433/x",
		"https://example.com@127.0.0.1/x",
	}
	for _, url := range unsafe {
		if err := assertSafeURL(url); err == nil {
			t.Errorf("assertSafeURL accepted %s", url)
		}
	}

	safe := []string{
		"https://example.com/x",
		"https://api.example.com:443/v1",
		"https://docs.rs/serde/latest/serde/",
		"https://sub.internal-docs.example.com/x",
	}
	for _, url := range safe {
		if err := assertSafeURL(url); err != nil {
			t.Errorf("assertSafeURL refused %s: %v", url, err)
		}
	}
}

func TestUpsertReplacesTheRecordWithTheSameID(t *testing.T) {
	dir := t.TempDir()
	first := goodRecord()
	first.Quote = "first"
	other := goodRecord()
	other.ID = "other"
	writeLock(t, dir, first, other)

	replacement := goodRecord()
	replacement.Quote = "second"
	if err := upsert(dir, replacement); err != nil {
		t.Fatal(err)
	}

	parsed, err := readLock(lockPath(dir))
	if err != nil {
		t.Fatal(err)
	}
	if len(parsed.Records) != 2 {
		t.Fatalf("expected 2 records after upsert, got %d", len(parsed.Records))
	}
	var quotes []string
	for _, raw := range parsed.Records {
		var rec Record
		if err := json.Unmarshal(raw, &rec); err != nil {
			t.Fatal(err)
		}
		quotes = append(quotes, rec.Quote)
	}
	for _, quote := range quotes {
		if quote == "first" {
			t.Fatal("upsert left the record it was meant to replace")
		}
	}
}

func TestUpsertCreatesTheLockWhenAbsent(t *testing.T) {
	dir := t.TempDir()
	if err := upsert(dir, goodRecord()); err != nil {
		t.Fatal(err)
	}
	parsed, err := readLock(lockPath(dir))
	if err != nil {
		t.Fatal(err)
	}
	if len(parsed.Records) != 1 {
		t.Fatalf("expected 1 record in a fresh lock, got %d", len(parsed.Records))
	}
}

func TestUpsertRefusesToPublishThroughASymlink(t *testing.T) {
	dir := t.TempDir()
	target := filepath.Join(dir, "real.json")
	if err := os.WriteFile(target, []byte(`{"records":[]}`), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(target, lockPath(dir)); err != nil {
		t.Skipf("cannot create the symlink: %v", err)
	}
	if err := upsert(dir, goodRecord()); err == nil {
		t.Fatal("upsert wrote through a symlinked lock")
	}
	info, err := os.Lstat(lockPath(dir))
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode()&os.ModeSymlink == 0 {
		t.Fatal("the symlink was replaced by a regular file")
	}
}

func TestVerifyRefusesALockThatDoesNotParse(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(lockPath(dir), []byte("not json"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err, _ := stderr(t, func() error { return verify(dir) }); err == nil {
		t.Fatal("verify accepted a lock that does not parse")
	}
}

func TestRecheckIsANoOpWithNoLockfile(t *testing.T) {
	dir := t.TempDir()
	err, out := stderr(t, func() error { return recheck(dir) })
	if err != nil {
		t.Fatalf("recheck on a lockless directory failed: %v", err)
	}
	if !strings.Contains(out, "nothing to recheck") {
		t.Fatalf("recheck did not take the no-op path: %s", out)
	}
}

func TestRecheckRefusesAnUnsafeSourceBeforeFetching(t *testing.T) {
	dir := t.TempDir()
	rec := goodRecord()
	rec.Source = "https://169.254.169.254/latest/meta-data/"
	writeLock(t, dir, rec)
	if err, _ := stderr(t, func() error { return recheck(dir) }); err == nil {
		t.Fatal("recheck fetched a link-local source")
	}
}

func TestFreshnessDaysMatchesTheDocumentedWindows(t *testing.T) {
	for class, want := range map[string]int{
		"pricing":      30,
		"availability": 30,
		"api":          90,
		"paper":        0,
		"":             180,
		"anything":     180,
	} {
		if got := freshnessDays(class); got != want {
			t.Errorf("freshnessDays(%q) = %d, want %d", class, got, want)
		}
	}
}

func TestUnknownCommandFails(t *testing.T) {
	if code := Run([]string{"nope"}); code == 0 {
		t.Fatal("an unknown command exited zero")
	}
	if code := Run([]string{"capture"}); code == 0 {
		t.Fatal("capture with no URL exited zero")
	}
}
