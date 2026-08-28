package workflow

import (
	"encoding/json"
	"os"
	"strings"
	"testing"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

func TestEvaluatorResolvesPinnedDefinition(t *testing.T) {
	t.Parallel()

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
	if resolved.Definition.SchemaVersion != DefinitionSchemaVersion ||
		resolved.Definition.EvaluatorVersion != EvaluatorVersion {
		t.Fatalf("resolved versions = %q, %q", resolved.Definition.SchemaVersion, resolved.Definition.EvaluatorVersion)
	}
	for _, digest := range []string{resolved.DefinitionDigest, resolved.SchemaDigest} {
		if !strings.HasPrefix(digest, "sha256:") || len(digest) != 71 {
			t.Fatalf("digest = %q", digest)
		}
	}
}

func TestEvaluatorRejectsMissingCapability(t *testing.T) {
	t.Parallel()

	evaluator, err := NewEvaluator(EvaluatorVersion)
	if err != nil {
		t.Fatalf("NewEvaluator() returned %v", err)
	}
	document, err := os.ReadFile("../../schemas/workflow/v1/testdata/valid.json")
	if err != nil {
		t.Fatalf("ReadFile() returned %v", err)
	}
	if _, err := evaluator.Resolve(document, CapabilityMap{"pi": {"live-input"}}); !domain.IsErrorCode(
		err, domain.ErrorCodeInvalidArgument,
	) {
		t.Fatalf("Resolve() error = %v", err)
	}
}

func TestEvaluatorRejectsBackEdgeWithoutForwardPath(t *testing.T) {
	t.Parallel()

	evaluator, err := NewEvaluator(EvaluatorVersion)
	if err != nil {
		t.Fatalf("NewEvaluator() returned %v", err)
	}
	document, err := os.ReadFile("../../schemas/workflow/v1/testdata/valid.json")
	if err != nil {
		t.Fatalf("ReadFile() returned %v", err)
	}
	var definition Definition
	if err := json.Unmarshal(document, &definition); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	definition.Edges = definition.Edges[1:]
	document, err = json.Marshal(definition)
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	if _, err := evaluator.Resolve(document, CapabilityMap{
		"pi": {"structured-result", "live-input"},
	}); !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("Resolve() error = %v", err)
	}
}

func TestEvaluatorResolvesDefaults(t *testing.T) {
	t.Parallel()

	evaluator, err := NewEvaluator(EvaluatorVersion)
	if err != nil {
		t.Fatalf("NewEvaluator() returned %v", err)
	}
	document := json.RawMessage(`{
  "schemaVersion":"colchis.workflow/v2",
	"evaluatorVersion":"cue-0.17.1+colchis-policy-v2",
  "name":"defaults",
  "budgets":{
    "maxConcurrentNodes":1,
    "maxConcurrentProcesses":1,
    "maxMaterializedSnapshots":1,
    "maxSnapshotBytes":1024,
    "maxVerificationSeconds":10
  },
  "templates":{
    "task":{
      "kind":"task",
      "inputSchema":{"$schema":"https://json-schema.org/draft/2020-12/schema"},
      "inputSchemaDigest":"sha256:042593f8c06f3af13910448e80b07865b66db137c16a125291699564732eac88",
      "outputSchema":{"$schema":"https://json-schema.org/draft/2020-12/schema"},
      "outputSchemaDigest":"sha256:042593f8c06f3af13910448e80b07865b66db137c16a125291699564732eac88",
      "capabilities":{}
    }
  },
  "nodes":{"task":{"template":"task","adapter":"fixture"}},
  "edges":[]
}`)
	resolved, err := evaluator.Resolve(document, CapabilityMap{"fixture": {}})
	if err != nil {
		t.Fatalf("Resolve() returned %v", err)
	}
	template := resolved.Definition.Templates["task"]
	if resolved.Definition.Effects.Mode != "deny" || len(resolved.Definition.Loops) != 0 ||
		template.MaxAttempts != 1 || template.MaxRepairAttempts != 2 ||
		len(template.WriteScopes) != 1 || template.WriteScopes[0] != "." ||
		resolved.Definition.Nodes["task"].Budget.MaxAttempts != 1 ||
		resolved.Definition.JobDefaults.Approvals != domain.ApprovalPolicyOnRequest ||
		resolved.Definition.Nodes["task"].Policy != resolved.Definition.JobDefaults {
		t.Fatalf("resolved defaults = %#v", resolved.Definition)
	}
}

func TestEvaluatorResolvesCompleteNodePolicyOverride(t *testing.T) {
	t.Parallel()

	evaluator, err := NewEvaluator(EvaluatorVersion)
	if err != nil {
		t.Fatalf("NewEvaluator() returned %v", err)
	}
	document, err := os.ReadFile("../../schemas/workflow/v1/testdata/valid.json")
	if err != nil {
		t.Fatalf("ReadFile() returned %v", err)
	}
	var value map[string]json.RawMessage
	if err := json.Unmarshal(document, &value); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	var nodes map[string]json.RawMessage
	if err := json.Unmarshal(value["nodes"], &nodes); err != nil {
		t.Fatalf("Unmarshal(nodes) returned %v", err)
	}
	var implement map[string]json.RawMessage
	if err := json.Unmarshal(nodes["implement"], &implement); err != nil {
		t.Fatalf("Unmarshal(implement) returned %v", err)
	}
	implement["policy"] = json.RawMessage(
		`{"approvals":"never","filesystem":"danger-full-access","network":"allow"}`,
	)
	nodes["implement"], err = json.Marshal(implement)
	if err != nil {
		t.Fatalf("Marshal(implement) returned %v", err)
	}
	value["nodes"], err = json.Marshal(nodes)
	if err != nil {
		t.Fatalf("Marshal(nodes) returned %v", err)
	}
	document, err = json.Marshal(value)
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	resolved, err := evaluator.Resolve(document, CapabilityMap{"pi": {"structured-result", "live-input"}})
	if err != nil {
		t.Fatalf("Resolve() returned %v", err)
	}
	if resolved.Definition.Nodes["implement"].Policy.Filesystem != domain.FilesystemPolicyDangerFullAccess ||
		resolved.Definition.Nodes["judge"].Policy.Network != domain.NetworkPolicyDeny {
		t.Fatalf("resolved policies = %#v", resolved.Definition.Nodes)
	}
}

func TestNewEvaluatorRejectsUnknownVersion(t *testing.T) {
	t.Parallel()

	if _, err := NewEvaluator("cue-next"); !domain.IsErrorCode(err, domain.ErrorCodeUnsupportedVersion) {
		t.Fatalf("NewEvaluator() error = %v", err)
	}
}

func TestResolvedDefinitionRejectsChangedDocument(t *testing.T) {
	t.Parallel()

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
	resolved.Document = append(resolved.Document, ' ')
	if err := resolved.Validate(); !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("Validate() error = %v", err)
	}
}
