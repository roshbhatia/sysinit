package note

import (
	"encoding/json"
	"os"
	"strconv"
	"strings"
	"sync"
	"testing"
)

func exportPath(t *testing.T) string {
	t.Helper()
	code, out := run(t, "path", "--export")
	if code != 0 {
		t.Fatalf("path --export exited %d", code)
	}
	return strings.TrimSpace(out)
}

func readExport(t *testing.T) *exportDoc {
	t.Helper()
	data, err := os.ReadFile(exportPath(t))
	if err != nil {
		t.Fatalf("export is not readable: %v", err)
	}
	var doc exportDoc
	if err := json.Unmarshal(data, &doc); err != nil {
		t.Fatalf("export is not valid JSON: %v: %s", err, data)
	}
	return &doc
}

func rebuiltFromRecord(t *testing.T) []byte {
	t.Helper()
	data, err := os.ReadFile(storePath(t))
	if err != nil {
		t.Fatalf("record is not readable: %v", err)
	}
	var doc document
	if err := json.Unmarshal(data, &doc); err != nil {
		t.Fatalf("record is not valid JSON: %v", err)
	}
	rendered, err := marshalExport(buildExport(doc.Notes))
	if err != nil {
		t.Fatalf("rebuild failed: %v", err)
	}
	return rendered
}

func assertExportLeadsRelease(t *testing.T) {
	t.Helper()
	fired := false
	beforeRelease = func() {
		fired = true
		on, err := os.ReadFile(exportPath(t))
		if err != nil {
			t.Errorf("the export is not on disk when the lock is released: %v", err)
			return
		}
		if want := rebuiltFromRecord(t); string(on) != string(want) {
			t.Errorf("the export lags the record at release:\n on disk: %s\n rebuilt: %s", on, want)
		}
	}
	t.Cleanup(func() {
		beforeRelease = func() {}
		if !fired {
			t.Error("the release seam never fired; the assertion tested nothing")
		}
	})
}

func TestAddPublishesTheExportBeforeReleasingTheLock(t *testing.T) {
	newRepo(t)
	assertExportLeadsRelease(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "2", "--summary", "one")
}

func TestApplyPublishesTheExportBeforeReleasingTheLock(t *testing.T) {
	newRepo(t)
	assertExportLeadsRelease(t)
	if code := apply(t, `{"notes":[{"file":"src/app.ts","line":1,"summary":"batched"}]}`); code != 0 {
		t.Fatalf("apply exited %d", code)
	}
}

func TestClearPublishesTheExportBeforeReleasingTheLock(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "2", "--summary", "one")
	assertExportLeadsRelease(t)
	if code, _ := run(t, "clear", "--yes"); code != 0 {
		t.Fatal("clear --yes failed")
	}
}

func TestClearEmptiesTheExportBeforeTheRecord(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "2", "--summary", "one")

	seen := false
	beforeRelease = func() {
		seen = true
		if got := len(readExport(t).Files); got != 0 {
			t.Errorf("clear left %d file(s) on display at release", got)
		}
	}
	t.Cleanup(func() { beforeRelease = func() {} })
	if code, _ := run(t, "clear", "--yes"); code != 0 {
		t.Fatal("clear --yes failed")
	}
	if !seen {
		t.Fatal("the release seam never fired")
	}
}

func TestExportCarriesRationaleAndAuthorIntact(t *testing.T) {
	newRepo(t)
	rationale := "first line\nsecond line"
	mustAdd(t, "--file", "src/app.ts", "--line", "3", "--summary", "anchored",
		"--rationale", rationale, "--author", "pi")

	doc := readExport(t)
	if len(doc.Files) != 1 || doc.Files[0].Path != "src/app.ts" {
		t.Fatalf("export does not name the file: %+v", doc.Files)
	}
	if len(doc.Files[0].Annotations) != 1 {
		t.Fatalf("expected one annotation, got %d", len(doc.Files[0].Annotations))
	}
	got := doc.Files[0].Annotations[0]
	if got.Summary != "anchored" {
		t.Errorf("summary crossed as %q", got.Summary)
	}
	if got.Rationale == nil || *got.Rationale != rationale {
		t.Errorf("rationale did not cross intact: %v", got.Rationale)
	}
	if got.Author != "pi" {
		t.Errorf("author crossed as %q", got.Author)
	}
	if got.NewRange != [2]int64{3, 3} {
		t.Errorf("newRange is %v", got.NewRange)
	}
}

func TestExportIsMarkedAsDerived(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "one")
	if got := readExport(t).Summary; got != derivedMarker {
		t.Fatalf("export is not marked as derived: %q", got)
	}
}

func TestExportGroupsNotesByFileInRecordOrder(t *testing.T) {
	newRepo(t)
	if err := os.WriteFile("src/other.ts", []byte("a\nb\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	mustAdd(t, "--file", "src/other.ts", "--line", "1", "--summary", "first")
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "second")
	mustAdd(t, "--file", "src/other.ts", "--line", "2", "--summary", "third")

	doc := readExport(t)
	if len(doc.Files) != 2 || doc.Files[0].Path != "src/other.ts" || doc.Files[1].Path != "src/app.ts" {
		t.Fatalf("file order is not the record's: %+v", doc.Files)
	}
	if len(doc.Files[0].Annotations) != 2 {
		t.Fatalf("expected two annotations on src/other.ts, got %d", len(doc.Files[0].Annotations))
	}
}

func TestRebuildRepairsAHandEditedRecord(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "one")

	root, _ := os.Getwd()
	hand := `{"version":1,"repo":"` + root + `","notes":[
	  {"file":"src/app.ts","line":9,"summary":"hand written","author":"owner"}
	]}`
	if err := os.WriteFile(storePath(t), []byte(hand), 0o644); err != nil {
		t.Fatal(err)
	}
	if got := readExport(t).Files[0].Annotations[0].Summary; got != "one" {
		t.Fatalf("the export changed without a rebuild: %q", got)
	}
	if code, _ := run(t, "rebuild"); code != 0 {
		t.Fatal("rebuild failed")
	}
	if got := readExport(t).Files[0].Annotations[0].Summary; got != "hand written" {
		t.Fatalf("rebuild did not pick the hand edit up: %q", got)
	}
}

func TestRebuildAfterClearLeavesAnEmptyExport(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "one")
	if err := os.Remove(storePath(t)); err != nil {
		t.Fatal(err)
	}
	if code, _ := run(t, "rebuild"); code != 0 {
		t.Fatal("rebuild failed on an absent record")
	}
	if got := len(readExport(t).Files); got != 0 {
		t.Fatalf("rebuild left %d file(s) after the record went away", got)
	}
}

func TestRebuildRefusesAMalformedRecord(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "one")
	if err := os.WriteFile(storePath(t), []byte("{ not json"), 0o644); err != nil {
		t.Fatal(err)
	}
	if code, _ := run(t, "rebuild"); code == 0 {
		t.Fatal("rebuild accepted a malformed record")
	}
}

func TestExportSurvivesAMalformedNote(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "seed")
	root, _ := os.Getwd()
	hand := `{"version":1,"repo":"` + root + `","notes":[
	  {"file":"src/app.ts","line":2,"summary":"valid","author":"pi"},
	  {"file":"src/app.ts","line":2,"author":"pi"},
	  "not an object"
	]}`
	if err := os.WriteFile(storePath(t), []byte(hand), 0o644); err != nil {
		t.Fatal(err)
	}
	if code, _ := run(t, "rebuild"); code != 0 {
		t.Fatal("rebuild failed on a record holding a malformed note")
	}
	doc := readExport(t)
	if len(doc.Files) != 1 || len(doc.Files[0].Annotations) != 1 {
		t.Fatalf("expected exactly the readable note to cross: %+v", doc.Files)
	}
}

func TestConcurrentAddsLeaveTheExportCurrent(t *testing.T) {
	newRepo(t)
	mustAdd(t, "--file", "src/app.ts", "--line", "1", "--summary", "seed")

	const writers = 8
	var wg sync.WaitGroup
	for i := 0; i < writers; i++ {
		wg.Add(1)
		go func(n int) {
			defer wg.Done()
			cmdAdd([]string{
				"--file", "src/app.ts",
				"--line", "2",
				"--summary", "concurrent " + strconv.Itoa(n),
			})
		}(i)
	}
	wg.Wait()

	on, err := os.ReadFile(exportPath(t))
	if err != nil {
		t.Fatalf("export is not readable: %v", err)
	}
	if want := rebuiltFromRecord(t); string(on) != string(want) {
		t.Fatalf("the export does not match a rebuild after %d concurrent writers", writers)
	}
}
