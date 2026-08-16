package schema

import (
	"bytes"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/santhosh-tekuri/jsonschema/v6"
)

// keywords are the ways a schema can constrain something. A shape holding none
// of them is the one --json asks for, which names no fields and so has nothing
// to check; validating it would pass anything and cost a compile.
var keywords = []string{"properties", "oneOf", "anyOf", "allOf", "items", "required", "enum", "$ref"}

func Free(shape map[string]any) bool {
	if shape == nil {
		return true
	}
	for _, keyword := range keywords {
		if _, named := shape[keyword]; named {
			return false
		}
	}
	return true
}

// Check answers with nil when the reply satisfies the schema, and with every
// reason it does not otherwise. Without this the only test a reply faced was
// whether it held a `{` at all, so an agent could answer `{"tags": "[\"a\"]"}`
// for a `tags:[]string` field and be reported as a success.
func Check(shape map[string]any, reply map[string]any) error {
	if Free(shape) {
		return nil
	}

	// Both sides go through JSON first. The validator only reads the types a
	// JSON decoder produces, and Build hands it Go types such as []string, which
	// it rejects as an unwritable schema rather than as a failed answer.
	plain, err := asJSON(shape)
	if err != nil {
		return fmt.Errorf("the schema will not encode: %w", err)
	}
	given, err := asJSON(reply)
	if err != nil {
		return fmt.Errorf("the answer will not encode: %w", err)
	}

	compiler := jsonschema.NewCompiler()
	if err := compiler.AddResource("shape.json", plain); err != nil {
		return fmt.Errorf("the schema will not compile: %w", err)
	}
	compiled, err := compiler.Compile("shape.json")
	if err != nil {
		return fmt.Errorf("the schema will not compile: %w", err)
	}

	if err := compiled.Validate(given); err != nil {
		return fmt.Errorf("the answer is outside the shape: %s", reasons(err))
	}
	return nil
}

func asJSON(value any) (any, error) {
	encoded, err := json.Marshal(value)
	if err != nil {
		return nil, err
	}
	return jsonschema.UnmarshalJSON(bytes.NewReader(encoded))
}

// vague are the units that only say a branch failed. The units under them say
// which field and why, so keeping both repeats the failure without adding to it.
var vague = map[string]bool{
	"validation failed": true,
	"'anyOf' failed":    true,
	"'oneOf' failed":    true,
	"'allOf' failed":    true,
}

// reasons flattens the validation tree into one line per broken rule. The
// default rendering is an indented tree, and this string is read back to the
// agent as the reason to answer again, so it has to stay on one line.
func reasons(err error) string {
	failure, ok := err.(*jsonschema.ValidationError)
	if !ok {
		return err.Error()
	}

	var found []string
	for _, unit := range failure.BasicOutput().Errors {
		if unit.Error == nil || vague[unit.Error.String()] {
			continue
		}
		where := unit.InstanceLocation
		if where == "" {
			where = "the answer"
		}
		found = append(found, where+": "+unit.Error.String())
	}
	if len(found) == 0 {
		return failure.Error()
	}
	if len(found) > 6 {
		found = append(found[:6], fmt.Sprintf("and %d more", len(found)-6))
	}
	return strings.Join(found, "; ")
}
