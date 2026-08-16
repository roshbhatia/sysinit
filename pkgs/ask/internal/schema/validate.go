package schema

import (
	"encoding/json"
	"fmt"
	"strings"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	cueerrors "cuelang.org/go/cue/errors"
	"cuelang.org/go/encoding/jsonschema"
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

// most is the number of reasons reported. Past a handful the answer is wrong in
// a way one more line will not explain.
const most = 6

// Check answers with nil when the reply satisfies the schema, and with every
// reason it does not otherwise. Without this the only test a reply faced was
// whether it held a `{` at all, so an agent could answer `{"tags": "[\"a\"]"}`
// for a `tags:[]string` field and be reported as a success.
//
// CUE does the checking. The schema goes out as JSON Schema, because that is
// what both agents take, and comes back here as CUE constraints, which unify
// with the answer and name the field that broke.
func Check(shape map[string]any, reply map[string]any) error {
	if Free(shape) {
		return nil
	}

	ctx := cuecontext.New()

	constraint, err := compile(ctx, shape)
	if err != nil {
		return err
	}
	given, err := value(ctx, reply)
	if err != nil {
		return fmt.Errorf("the answer will not encode: %w", err)
	}

	// Concrete insists every field holds a value rather than only a type, which
	// is what catches a missing required field.
	if err := constraint.Unify(given).Validate(cue.Concrete(true)); err != nil {
		return fmt.Errorf("the answer is outside the shape: %s", reasons(err))
	}
	return nil
}

// compile turns a JSON Schema into the CUE constraints it stands for.
func compile(ctx *cue.Context, shape map[string]any) (cue.Value, error) {
	written, err := value(ctx, shape)
	if err != nil {
		return cue.Value{}, fmt.Errorf("the schema will not encode: %w", err)
	}

	// The shapes this builds carry no $schema, so the version has to be named
	// here or Extract reads them as the oldest draft.
	file, err := jsonschema.Extract(written, &jsonschema.Config{
		DefaultVersion: jsonschema.VersionDraft2020_12,
	})
	if err != nil {
		return cue.Value{}, fmt.Errorf("the schema will not compile: %s", reasons(err))
	}

	built := ctx.BuildFile(file)
	if err := built.Err(); err != nil {
		return cue.Value{}, fmt.Errorf("the schema will not compile: %s", reasons(err))
	}
	return built, nil
}

// value reads Go data into CUE through JSON, which is the only encoding both
// sides agree on. Build hands out Go types such as []string that CUE would
// otherwise read as something else.
func value(ctx *cue.Context, from any) (cue.Value, error) {
	encoded, err := json.Marshal(from)
	if err != nil {
		return cue.Value{}, err
	}
	read := ctx.CompileBytes(encoded)
	return read, read.Err()
}

// reasons flattens the failure into one line per broken rule. CUE renders a
// multi-line tree by default, and this string is read back to the agent as the
// reason to answer again, so it has to stay on one line.
func reasons(err error) string {
	broken := cueerrors.Errors(err)
	if len(broken) == 0 {
		return err.Error()
	}

	found := make([]string, 0, len(broken))
	seen := map[string]bool{}
	for _, one := range broken {
		format, args := one.Msg()
		said := fmt.Sprintf(format, args...)

		// An enum is a CUE disjunction, so a wrong value reports one conflict per
		// branch under a header counting them. The header says nothing the
		// branches do not.
		if strings.Contains(said, "in empty disjunction") {
			continue
		}

		where := strings.Join(one.Path(), ".")
		if where == "" {
			where = "the answer"
		}
		line := where + ": " + said
		if seen[line] {
			continue
		}
		seen[line] = true
		found = append(found, line)
	}
	if len(found) == 0 {
		return err.Error()
	}

	if len(found) > most {
		found = append(found[:most], fmt.Sprintf("and %d more", len(found)-most))
	}
	return strings.Join(found, "; ")
}
