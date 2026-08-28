package result

import (
	"bytes"
	"encoding/json"
	"fmt"
	"strings"
	"unicode/utf8"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
	"github.com/santhosh-tekuri/jsonschema/v6"
)

const maxFeedbackBytes = 4096

type Decision struct {
	Accepted      bool   `json:"accepted"`
	RepairAllowed bool   `json:"repairAllowed"`
	Exhausted     bool   `json:"exhausted"`
	RepairsUsed   uint32 `json:"repairsUsed"`
	RepairsLeft   uint32 `json:"repairsLeft"`
	Feedback      string `json:"feedback,omitempty"`
}

type Validator struct {
	schema            *jsonschema.Schema
	schemaDigest      string
	maxRepairAttempts uint32
	maxValueBytes     uint64
}

func NewValidator(
	schemaDocument json.RawMessage,
	schemaDigest string,
	maxRepairAttempts uint32,
	maxValueBytes uint64,
) (*Validator, error) {
	if maxValueBytes == 0 {
		return nil, invalidValidator("result byte limit is zero", nil)
	}
	computedDigest, err := workflowmodel.JSONSchemaDigest(schemaDocument)
	if err != nil {
		return nil, err
	}
	if computedDigest != schemaDigest {
		return nil, invalidValidator("JSON Schema digest does not match", nil)
	}
	var header struct {
		Schema string `json:"$schema"`
	}
	if err := json.Unmarshal(schemaDocument, &header); err != nil {
		return nil, invalidValidator("JSON Schema cannot be decoded", err)
	}
	if header.Schema != "https://json-schema.org/draft/2020-12/schema" {
		return nil, &domain.Error{
			Code: domain.ErrorCodeUnsupportedVersion, Op: "compile", Resource: "task result schema",
			Message: "JSON Schema draft is unsupported",
		}
	}
	parsed, err := jsonschema.UnmarshalJSON(bytes.NewReader(schemaDocument))
	if err != nil {
		return nil, invalidValidator("JSON Schema cannot be parsed", err)
	}
	compiler := jsonschema.NewCompiler()
	compiler.DefaultDraft(jsonschema.Draft2020)
	compiler.AssertFormat()
	compiler.UseLoader(jsonschema.SchemeURLLoader{})
	if err := compiler.AddResource("schema.json", parsed); err != nil {
		return nil, invalidValidator("JSON Schema resource cannot be added", err)
	}
	compiled, err := compiler.Compile("schema.json")
	if err != nil {
		return nil, invalidValidator("JSON Schema cannot be compiled", err)
	}
	return &Validator{
		schema: compiled, schemaDigest: schemaDigest,
		maxRepairAttempts: maxRepairAttempts, maxValueBytes: maxValueBytes,
	}, nil
}

func (validator *Validator) Validate(value json.RawMessage, repairsUsed uint32) Decision {
	if repairsUsed > validator.maxRepairAttempts {
		repairsUsed = validator.maxRepairAttempts
	}
	var validationErr error
	if uint64(len(value)) > validator.maxValueBytes {
		validationErr = fmt.Errorf("task result exceeds %d bytes", validator.maxValueBytes)
	} else {
		parsed, err := jsonschema.UnmarshalJSON(bytes.NewReader(value))
		if err != nil {
			validationErr = fmt.Errorf("task result is not valid JSON: %w", err)
		} else {
			validationErr = validator.schema.Validate(parsed)
		}
	}
	if validationErr == nil {
		return Decision{
			Accepted: true, RepairsUsed: repairsUsed,
			RepairsLeft: validator.maxRepairAttempts - repairsUsed,
		}
	}
	feedback := boundedFeedback(validationErr.Error())
	if repairsUsed < validator.maxRepairAttempts {
		repairsUsed++
		return Decision{
			RepairAllowed: true, RepairsUsed: repairsUsed,
			RepairsLeft: validator.maxRepairAttempts - repairsUsed, Feedback: feedback,
		}
	}
	return Decision{Exhausted: true, RepairsUsed: repairsUsed, Feedback: feedback}
}

func (validator *Validator) SchemaDigest() string {
	return validator.schemaDigest
}

func boundedFeedback(feedback string) string {
	feedback = strings.TrimSpace(feedback)
	if len(feedback) <= maxFeedbackBytes {
		return feedback
	}
	feedback = feedback[:maxFeedbackBytes]
	for !utf8.ValidString(feedback) {
		feedback = feedback[:len(feedback)-1]
	}
	return feedback
}

func invalidValidator(message string, err error) error {
	return &domain.Error{
		Code: domain.ErrorCodeInvalidArgument, Op: "compile", Resource: "task result schema",
		Message: message, Err: err,
	}
}
