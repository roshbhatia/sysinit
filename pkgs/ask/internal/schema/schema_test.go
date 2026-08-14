package schema

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

// field is one property of a built schema, or the test fails saying which one is missing.
func field(t *testing.T, built map[string]any, name string) map[string]any {
	t.Helper()
	properties, ok := built["properties"].(map[string]any)
	if !ok {
		t.Fatalf("the schema has no properties: %v", built)
	}
	one, ok := properties[name].(map[string]any)
	if !ok {
		t.Fatalf("the schema has no field %q: %v", properties, name)
	}
	return one
}

func TestASpecBecomesOneRequiredFieldPerName(t *testing.T) {
	built, err := Build("name:string, count:int")
	if err != nil {
		t.Fatal(err)
	}
	if got := field(t, built, "name")["type"]; got != "string" {
		t.Errorf("name is %v, want string", got)
	}
	if got := field(t, built, "count")["type"]; got != "integer" {
		t.Errorf("count is %v, want integer", got)
	}
	required, _ := built["required"].([]string)
	if !reflect.DeepEqual(required, []string{"name", "count"}) {
		t.Errorf("required is %v, want both fields", required)
	}
	if built["additionalProperties"] != false {
		t.Error("the shape lets extra fields through")
	}
}

func TestAQuestionMarkLeavesTheFieldOut(t *testing.T) {
	built, err := Build("name:string, notes:string?")
	if err != nil {
		t.Fatal(err)
	}
	required, _ := built["required"].([]string)
	if !reflect.DeepEqual(required, []string{"name"}) {
		t.Errorf("required is %v, want only name", required)
	}
	if got := field(t, built, "notes")["type"]; got != "string" {
		t.Errorf("notes is %v, want string", got)
	}
}

func TestABarBecomesAClosedSetOfStrings(t *testing.T) {
	built, err := Build("level:error|warn|info")
	if err != nil {
		t.Fatal(err)
	}
	level := field(t, built, "level")
	if level["type"] != "string" {
		t.Errorf("the enum is %v, want string", level["type"])
	}
	if got, _ := level["enum"].([]string); !reflect.DeepEqual(got, []string{"error", "warn", "info"}) {
		t.Errorf("the values are %v, want all three", got)
	}
}

// The comma inside the enum is the whole point: splitting on every comma would cut this
// field in half and lose the type.
func TestAnEnumIsNotCutInHalfByItsOwnComma(t *testing.T) {
	built, err := Build("tags:[]string, level:error|warn")
	if err != nil {
		t.Fatal(err)
	}
	tags := field(t, built, "tags")
	if tags["type"] != "array" {
		t.Fatalf("tags is %v, want array", tags["type"])
	}
	items, _ := tags["items"].(map[string]any)
	if items["type"] != "string" {
		t.Errorf("the array holds %v, want string", items["type"])
	}
	if _, ok := field(t, built, "level")["enum"]; !ok {
		t.Error("the field after the array lost its enum")
	}
}

func TestAnEnumOfOneIsRejected(t *testing.T) {
	if _, err := Build("level:only|"); err == nil {
		t.Error("a one-value enum was accepted")
	}
}

func TestAFieldWithNoTypeIsRejected(t *testing.T) {
	if _, err := Build("name"); err == nil {
		t.Error("a field with no colon was accepted")
	}
}

func TestATypeNoOneKnowsIsRejected(t *testing.T) {
	_, err := Build("name:notatype")
	if err == nil {
		t.Fatal("an unknown type was accepted")
	}
	// The message has to name the field, because a spec holds several.
	if want := `field "name"`; err.Error()[:len(want)] != want {
		t.Errorf("the error is %q, want it to open by naming the field", err)
	}
}

func TestAnEmptySpecIsRejected(t *testing.T) {
	if _, err := Build("  ,  "); err == nil {
		t.Error("a spec naming no fields was accepted")
	}
}

func TestAnAtSignReadsAFileInstead(t *testing.T) {
	path := filepath.Join(t.TempDir(), "shape.json")
	if err := os.WriteFile(path, []byte(`{"type":"object","title":"mine"}`), 0o600); err != nil {
		t.Fatal(err)
	}
	built, err := Resolve("@" + path)
	if err != nil {
		t.Fatal(err)
	}
	if built["title"] != "mine" {
		t.Errorf("the file was not used: %v", built)
	}
}

func TestAFileThatIsNotJSONIsRejected(t *testing.T) {
	path := filepath.Join(t.TempDir(), "shape.json")
	if err := os.WriteFile(path, []byte("not json"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := Resolve("@" + path); err == nil {
		t.Error("a file that is not JSON was accepted")
	}
}

func TestAskingForJSONWithNoShapeAllowsAnyObject(t *testing.T) {
	built := Any()
	if built["type"] != "object" || built["additionalProperties"] != true {
		t.Errorf("the open shape is %v", built)
	}
}
