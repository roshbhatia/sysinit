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

const most = 6

// Check answers with every reason the reply is outside the shape, or nil.
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

	// Concrete is what catches a missing required field, as a schema alone
	// unifies with a type.
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

	// Build emits no $schema, so Extract would otherwise read the oldest draft.
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

// value reads Go data into CUE through JSON, as CUE misreads a Go []string.
func value(ctx *cue.Context, from any) (cue.Value, error) {
	encoded, err := json.Marshal(from)
	if err != nil {
		return cue.Value{}, err
	}
	read := ctx.CompileBytes(encoded)
	return read, read.Err()
}

// reasons flattens the failure onto one line, as it is read back to the agent.
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

		// An enum is a disjunction, so this header only counts the branch
		// conflicts reported beside it.
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
