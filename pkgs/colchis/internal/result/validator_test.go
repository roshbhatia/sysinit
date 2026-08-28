package result

import (
	"encoding/json"
	"strings"
	"testing"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
)

func TestValidatorAcceptsTypedResult(t *testing.T) {
	t.Parallel()

	validator := newTestValidator(t, 2, 1024)
	decision := validator.Validate(json.RawMessage(`{"status":"passed"}`), 0)
	if !decision.Accepted || decision.RepairAllowed || decision.Exhausted || decision.RepairsLeft != 2 {
		t.Fatalf("decision = %#v", decision)
	}
}

func TestValidatorBoundsRepairFeedback(t *testing.T) {
	t.Parallel()

	validator := newTestValidator(t, 2, 1024)
	value := json.RawMessage(`{"status":"unknown"}`)
	first := validator.Validate(value, 0)
	second := validator.Validate(value, first.RepairsUsed)
	third := validator.Validate(value, second.RepairsUsed)
	if !first.RepairAllowed || first.RepairsUsed != 1 || first.RepairsLeft != 1 || first.Feedback == "" {
		t.Fatalf("first decision = %#v", first)
	}
	if !second.RepairAllowed || second.RepairsUsed != 2 || second.RepairsLeft != 0 {
		t.Fatalf("second decision = %#v", second)
	}
	if !third.Exhausted || third.RepairAllowed || third.RepairsUsed != 2 {
		t.Fatalf("third decision = %#v", third)
	}
}

func TestValidatorRejectsMalformedAndOversizedResults(t *testing.T) {
	t.Parallel()

	validator := newTestValidator(t, 1, 16)
	for _, value := range []json.RawMessage{
		json.RawMessage(`{"status":`),
		json.RawMessage(`{"status":"passed","padding":"large"}`),
	} {
		decision := validator.Validate(value, 0)
		if !decision.RepairAllowed || decision.Feedback == "" {
			t.Fatalf("decision = %#v", decision)
		}
	}
}

func TestNewValidatorRejectsDigestMismatchAndExternalReference(t *testing.T) {
	t.Parallel()

	schema := testResultSchema()
	if _, err := NewValidator(schema, "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", 1, 1024); !domain.IsErrorCode(
		err, domain.ErrorCodeInvalidArgument,
	) {
		t.Fatalf("digest mismatch error = %v", err)
	}
	external := json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "$ref":"https://example.invalid/result.json"
}`)
	digest, err := workflowmodel.JSONSchemaDigest(external)
	if err != nil {
		t.Fatalf("JSONSchemaDigest() returned %v", err)
	}
	if _, err := NewValidator(external, digest, 1, 1024); err == nil || !strings.Contains(err.Error(), "cannot be compiled") {
		t.Fatalf("external reference error = %v", err)
	}
}

func newTestValidator(t *testing.T, repairs uint32, bytes uint64) *Validator {
	t.Helper()
	schema := testResultSchema()
	digest, err := workflowmodel.JSONSchemaDigest(schema)
	if err != nil {
		t.Fatalf("JSONSchemaDigest() returned %v", err)
	}
	validator, err := NewValidator(schema, digest, repairs, bytes)
	if err != nil {
		t.Fatalf("NewValidator() returned %v", err)
	}
	return validator
}

func testResultSchema() json.RawMessage {
	return json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object",
  "properties":{"status":{"enum":["passed","failed"]}},
  "required":["status"],
  "additionalProperties":false
}`)
}
