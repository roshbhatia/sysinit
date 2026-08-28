package workflow

import (
	"encoding/json"
	"os"
	"testing"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

func TestApplyOperationsInsertsStageBetweenTypedEdges(t *testing.T) {
	t.Parallel()

	evaluator, base := resolvedFixtureDefinition(t)
	operation := insertCriticOperation(t)
	patched, err := evaluator.ApplyOperations(base, []domain.GraphPatchOperation{operation}, CapabilityMap{
		"pi": {"structured-result", "live-input"},
	})
	if err != nil {
		t.Fatalf("ApplyOperations() returned %v", err)
	}
	if _, found := base.Nodes["critic"]; found {
		t.Fatal("ApplyOperations() mutated the base definition")
	}
	if node, found := patched.Resolved.Definition.Nodes["critic"]; !found || node.Template != "critic-template" {
		t.Fatalf("inserted node = %#v, %v", node, found)
	}
	if len(patched.Resolved.Definition.Edges) != 3 ||
		edgeExists(patched.Resolved.Definition.Edges, "implement-to-judge") {
		t.Fatalf("patched edges = %#v", patched.Resolved.Definition.Edges)
	}
	if len(patched.AffectedNodes) != 2 ||
		patched.AffectedNodes[0] != "critic" || patched.AffectedNodes[1] != "judge" {
		t.Fatalf("affected nodes = %#v", patched.AffectedNodes)
	}
}

func TestApplyOperationsIsAtomic(t *testing.T) {
	t.Parallel()

	evaluator, base := resolvedFixtureDefinition(t)
	valid := insertCriticOperation(t)
	missing := domain.NodeKey("missing")
	invalid := domain.GraphPatchOperation{
		Kind: domain.GraphPatchOperationRemove, TargetNodeKey: &missing,
	}
	if _, err := evaluator.ApplyOperations(base, []domain.GraphPatchOperation{valid, invalid}, CapabilityMap{
		"pi": {"structured-result", "live-input"},
	}); !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("ApplyOperations() error = %v", err)
	}
	if len(base.Nodes) != 2 || len(base.Edges) != 2 {
		t.Fatalf("base definition changed = %#v", base)
	}
}

func resolvedFixtureDefinition(t *testing.T) (*Evaluator, Definition) {
	t.Helper()
	evaluator, err := NewEvaluator(EvaluatorVersion)
	if err != nil {
		t.Fatalf("NewEvaluator() returned %v", err)
	}
	document, err := os.ReadFile("../../schemas/workflow/v1/testdata/valid.json")
	if err != nil {
		t.Fatalf("ReadFile() returned %v", err)
	}
	resolved, err := evaluator.Resolve(document, CapabilityMap{
		"pi": {"structured-result", "live-input"},
	})
	if err != nil {
		t.Fatalf("Resolve() returned %v", err)
	}
	return evaluator, resolved.Definition
}

func insertCriticOperation(t *testing.T) domain.GraphPatchOperation {
	t.Helper()
	target := domain.EdgeKey("implement-to-judge")
	instance := domain.NodeKey("critic")
	templateKey := domain.StageTemplateKey("critic-template")
	digest := "sha256:ccb5a9d66e068ea8f4e205788589675a48e9e3754a840d8ac10120d14238e914"
	value, err := json.Marshal(StageOperationValue{
		Adapter: "pi", InputPort: "candidate", OutputPort: "verdict",
		Template: Template{
			Kind:               "judge",
			InputSchema:        json.RawMessage(`{"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object"}`),
			InputSchemaDigest:  digest,
			OutputSchema:       json.RawMessage(`{"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object"}`),
			OutputSchemaDigest: digest,
			Capabilities: Capabilities{
				Required: []string{"structured-result"}, Optional: []string{},
			},
			Verification: []Verification{}, Effects: EffectPolicy{Mode: "deny"}, MaxAttempts: 2,
		},
	})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	return domain.GraphPatchOperation{
		Kind:          domain.GraphPatchOperationInsertBetween,
		TargetEdgeKey: &target, InstanceNodeKey: &instance, StageTemplateKey: &templateKey,
		Value: value,
	}
}

func edgeExists(edges []Edge, key domain.EdgeKey) bool {
	for _, edge := range edges {
		if edge.ID == key {
			return true
		}
	}
	return false
}
