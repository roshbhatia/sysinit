package schema

import (
	"strings"
	"testing"
)

func TestFreeOnlyForAnUnconstrainedShape(t *testing.T) {
	if !Free(nil) {
		t.Fatal("a missing shape constrains nothing")
	}
	if !Free(Any()) {
		t.Fatal("--json names no fields, so it constrains nothing")
	}
	built, err := Build("name:string")
	if err != nil {
		t.Fatal(err)
	}
	if Free(built) {
		t.Fatal("a shape with properties has something to check")
	}
	loose, _ := Relaxed(built)
	if Free(loose) {
		t.Fatal("a relaxed shape still has something to check")
	}
}

// The stringified array is the answer that started this: a run asked for
// []string and was handed a JSON string holding a JSON array, which read as a
// success because nothing looked past the opening brace.
func TestCheckRejectsAStringifiedArray(t *testing.T) {
	built, err := Build("files:[]string")
	if err != nil {
		t.Fatal(err)
	}
	err = Check(built, map[string]any{"files": `["a.go","b.go"]`})
	if err == nil {
		t.Fatal("a string where an array was asked for is outside the shape")
	}
	if !strings.Contains(err.Error(), "files") {
		t.Fatalf("the reason should name the field, got %q", err)
	}
}

func TestCheckCases(t *testing.T) {
	built, err := Build("level:error|warn|info, count:int, note:string?")
	if err != nil {
		t.Fatal(err)
	}

	for _, one := range []struct {
		name  string
		reply map[string]any
		ok    bool
	}{
		{"whole", map[string]any{"level": "warn", "count": float64(2), "note": "x"}, true},
		{"without the optional field", map[string]any{"level": "warn", "count": float64(2)}, true},
		{"missing a required field", map[string]any{"level": "warn"}, false},
		{"outside the enum", map[string]any{"level": "loud", "count": float64(2)}, false},
		{"wrong type", map[string]any{"level": "warn", "count": "two"}, false},
		{"an extra field", map[string]any{"level": "warn", "count": float64(2), "extra": true}, false},
	} {
		t.Run(one.name, func(t *testing.T) {
			err := Check(built, one.reply)
			if one.ok && err != nil {
				t.Fatalf("wanted this to pass, got %v", err)
			}
			if !one.ok && err == nil {
				t.Fatal("wanted this to fail")
			}
		})
	}
}

func TestCheckPassesAnythingWhenTheShapeIsFree(t *testing.T) {
	if err := Check(Any(), map[string]any{"whatever": 1}); err != nil {
		t.Fatalf("--json asks for no fields, got %v", err)
	}
}
