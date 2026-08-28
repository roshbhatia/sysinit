package workflow

import (
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"reflect"
	"sort"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	workflowv1 "github.com/roshbhatia/sysinit/pkgs/colchis/schemas/workflow/v1"
)

const (
	LegacyDefinitionSchemaVersion = "colchis.workflow/v1"
	LegacyEvaluatorVersion        = "cue-0.17"
	DefinitionSchemaVersion       = "colchis.workflow/v2"
	EvaluatorVersion              = "cue-0.17.1+colchis-policy-v2"
)

func SafeJobPolicy() domain.JobPolicy {
	return domain.JobPolicy{
		Approvals: domain.ApprovalPolicyOnRequest, Filesystem: domain.FilesystemPolicyWorkspaceWrite,
		Network: domain.NetworkPolicyDeny,
	}
}

type Definition struct {
	SchemaVersion    string                               `json:"schemaVersion"`
	EvaluatorVersion string                               `json:"evaluatorVersion"`
	Name             string                               `json:"name"`
	Budgets          DefinitionBudgets                    `json:"budgets"`
	Effects          EffectPolicy                         `json:"effects"`
	JobDefaults      domain.JobPolicy                     `json:"jobDefaults"`
	Templates        map[domain.StageTemplateKey]Template `json:"templates"`
	Nodes            map[domain.NodeKey]Node              `json:"nodes"`
	Edges            []Edge                               `json:"edges"`
	Loops            []Loop                               `json:"loops"`
}

type DefinitionBudgets struct {
	MaxConcurrentNodes       uint32 `json:"maxConcurrentNodes"`
	MaxConcurrentProcesses   uint32 `json:"maxConcurrentProcesses"`
	MaxMaterializedSnapshots uint32 `json:"maxMaterializedSnapshots"`
	MaxSnapshotBytes         uint64 `json:"maxSnapshotBytes"`
	MaxVerificationSeconds   uint32 `json:"maxVerificationSeconds"`
}

type EffectPolicy struct {
	Mode                   string            `json:"mode"`
	RequiresOwnerAuthority bool              `json:"requiresOwnerAuthority,omitempty"`
	Operations             []EffectOperation `json:"operations,omitempty"`
}

type EffectOperation struct {
	Kind               string `json:"kind"`
	TargetSchemaDigest string `json:"targetSchemaDigest"`
	Reconciliation     string `json:"reconciliation"`
	Idempotent         bool   `json:"idempotent"`
}

type Template struct {
	Kind               string          `json:"kind"`
	InputSchema        json.RawMessage `json:"inputSchema"`
	InputSchemaDigest  string          `json:"inputSchemaDigest"`
	OutputSchema       json.RawMessage `json:"outputSchema"`
	OutputSchemaDigest string          `json:"outputSchemaDigest"`
	Capabilities       Capabilities    `json:"capabilities"`
	WriteScopes        []string        `json:"writeScopes,omitempty"`
	Verification       []Verification  `json:"verification"`
	Effects            EffectPolicy    `json:"effects"`
	MaxAttempts        uint32          `json:"maxAttempts"`
	MaxRepairAttempts  uint32          `json:"maxRepairAttempts"`
}

type Capabilities struct {
	Required []string `json:"required"`
	Optional []string `json:"optional"`
}

type Verification struct {
	Key            string   `json:"key"`
	Required       bool     `json:"required"`
	Environment    string   `json:"environment"`
	Command        []string `json:"command"`
	TimeoutSeconds uint32   `json:"timeoutSeconds"`
}

type Node struct {
	Template domain.StageTemplateKey `json:"template"`
	Adapter  string                  `json:"adapter"`
	Policy   domain.JobPolicy        `json:"policy"`
	Budget   NodeBudget              `json:"budget"`
}

type NodeBudget struct {
	MaxAttempts uint32 `json:"maxAttempts"`
}

type Edge struct {
	ID                domain.EdgeKey `json:"id"`
	From              domain.NodeKey `json:"from"`
	FromPort          string         `json:"fromPort"`
	To                domain.NodeKey `json:"to"`
	ToPort            string         `json:"toPort"`
	ValueSchemaDigest string         `json:"valueSchemaDigest"`
	Required          bool           `json:"required"`
}

type StopCondition struct {
	Kind       string          `json:"kind"`
	Validation string          `json:"validation,omitempty"`
	Node       domain.NodeKey  `json:"node,omitempty"`
	Path       []string        `json:"path,omitempty"`
	Equals     json.RawMessage `json:"equals,omitempty"`
}

type Loop struct {
	ID             string         `json:"id"`
	BackEdge       domain.EdgeKey `json:"backEdge"`
	Stop           StopCondition  `json:"stop"`
	IterationLimit uint32         `json:"iterationLimit"`
	StallLimit     uint32         `json:"stallLimit"`
}

type CapabilityResolver interface {
	Capabilities(adapter string) ([]string, bool)
}

type CapabilityMap map[string][]string

func (capabilities CapabilityMap) Capabilities(adapter string) ([]string, bool) {
	values, found := capabilities[adapter]
	return values, found
}

type ResolvedDefinition struct {
	Definition       Definition
	Document         json.RawMessage
	DefinitionDigest string
	SchemaDigest     string
}

func (resolved ResolvedDefinition) Validate() error {
	if !json.Valid(resolved.Document) {
		return invalidDefinition("resolved document is not valid JSON", nil)
	}
	definitionDigest := sha256.Sum256(resolved.Document)
	if resolved.DefinitionDigest != fmt.Sprintf("sha256:%x", definitionDigest) {
		return invalidDefinition("resolved definition digest does not match", nil)
	}
	schemaDigest := sha256.Sum256(workflowv1.Schema)
	if resolved.SchemaDigest != fmt.Sprintf("sha256:%x", schemaDigest) {
		return invalidDefinition("workflow schema digest does not match", nil)
	}
	var decoded Definition
	if err := json.Unmarshal(resolved.Document, &decoded); err != nil {
		return invalidDefinition("resolved document cannot be decoded", err)
	}
	if !reflect.DeepEqual(decoded, resolved.Definition) {
		return invalidDefinition("resolved document and definition differ", nil)
	}
	return nil
}

func UpgradeLegacyDefinition(
	schemaVersion string,
	evaluatorVersion string,
	definition *Definition,
) error {
	if schemaVersion != LegacyDefinitionSchemaVersion || evaluatorVersion != LegacyEvaluatorVersion {
		return &domain.Error{
			Code: domain.ErrorCodeUnsupportedVersion, Resource: schemaVersion + "/" + evaluatorVersion,
			Message: "pinned workflow semantics are unavailable",
		}
	}
	if err := definition.JobDefaults.Validate(); err != nil {
		definition.JobDefaults = SafeJobPolicy()
	}
	for key, node := range definition.Nodes {
		if err := node.Policy.Validate(); err != nil {
			node.Policy = definition.JobDefaults
			definition.Nodes[key] = node
		}
	}
	definition.SchemaVersion = DefinitionSchemaVersion
	definition.EvaluatorVersion = EvaluatorVersion
	return nil
}

type Evaluator struct {
	context      *cue.Context
	schema       cue.Value
	schemaDigest string
}

func NewEvaluator(version string) (*Evaluator, error) {
	if version != EvaluatorVersion {
		return nil, &domain.Error{
			Code: domain.ErrorCodeUnsupportedVersion, Resource: "workflow evaluator",
			Message: "evaluator version is unsupported",
		}
	}
	context := cuecontext.New()
	root := context.CompileBytes(workflowv1.Schema)
	if err := root.Err(); err != nil {
		return nil, &domain.Error{
			Code: domain.ErrorCodeInternal, Resource: "workflow schema", Message: "schema compilation failed", Err: err,
		}
	}
	schema := root.LookupPath(cue.ParsePath("#Workflow"))
	if err := schema.Err(); err != nil {
		return nil, &domain.Error{
			Code: domain.ErrorCodeInternal, Resource: "workflow schema", Message: "workflow definition is missing", Err: err,
		}
	}
	digest := sha256.Sum256(workflowv1.Schema)
	return &Evaluator{context: context, schema: schema, schemaDigest: fmt.Sprintf("sha256:%x", digest)}, nil
}

func (evaluator *Evaluator) Resolve(
	document json.RawMessage,
	resolver CapabilityResolver,
) (ResolvedDefinition, error) {
	if !json.Valid(document) {
		return ResolvedDefinition{}, invalidDefinition("document is not valid JSON", nil)
	}
	instance := evaluator.context.CompileBytes(document)
	if err := instance.Err(); err != nil {
		return ResolvedDefinition{}, invalidDefinition("document compilation failed", err)
	}
	resolved := evaluator.schema.Unify(instance)
	if err := resolved.Validate(cue.Concrete(true), cue.Final()); err != nil {
		return ResolvedDefinition{}, invalidDefinition("document violates the workflow schema", err)
	}
	encoded, err := resolved.MarshalJSON()
	if err != nil {
		return ResolvedDefinition{}, invalidDefinition("resolved document cannot be encoded", err)
	}
	var definition Definition
	if err := json.Unmarshal(encoded, &definition); err != nil {
		return ResolvedDefinition{}, invalidDefinition("resolved document cannot be decoded", err)
	}
	if err := validateSchemaDigests(definition); err != nil {
		return ResolvedDefinition{}, err
	}
	if err := validateCapabilities(definition, resolver); err != nil {
		return ResolvedDefinition{}, err
	}
	if err := validateGraph(definition); err != nil {
		return ResolvedDefinition{}, err
	}
	digest := sha256.Sum256(encoded)
	return ResolvedDefinition{
		Definition: definition, Document: encoded,
		DefinitionDigest: fmt.Sprintf("sha256:%x", digest), SchemaDigest: evaluator.schemaDigest,
	}, nil
}

func JSONSchemaDigest(schema json.RawMessage) (string, error) {
	if !json.Valid(schema) {
		return "", invalidDefinition("JSON Schema is not valid JSON", nil)
	}
	var compact bytes.Buffer
	if err := json.Compact(&compact, schema); err != nil {
		return "", invalidDefinition("JSON Schema cannot be compacted", err)
	}
	digest := sha256.Sum256(compact.Bytes())
	return fmt.Sprintf("sha256:%x", digest), nil
}

func validateSchemaDigests(definition Definition) error {
	keys := make([]domain.StageTemplateKey, 0, len(definition.Templates))
	for key := range definition.Templates {
		keys = append(keys, key)
	}
	sort.Slice(keys, func(first int, second int) bool { return keys[first] < keys[second] })
	for _, key := range keys {
		template := definition.Templates[key]
		inputDigest, err := JSONSchemaDigest(template.InputSchema)
		if err != nil {
			return err
		}
		outputDigest, err := JSONSchemaDigest(template.OutputSchema)
		if err != nil {
			return err
		}
		if inputDigest != template.InputSchemaDigest || outputDigest != template.OutputSchemaDigest {
			return invalidDefinition(
				"stage template JSON Schema digest does not match",
				fmt.Errorf("template %s", key),
			)
		}
	}
	return nil
}

func validateCapabilities(definition Definition, resolver CapabilityResolver) error {
	if resolver == nil {
		return invalidDefinition("capability resolver is nil", nil)
	}
	keys := sortedNodeKeys(definition.Nodes)
	for _, key := range keys {
		node := definition.Nodes[key]
		available, found := resolver.Capabilities(node.Adapter)
		if !found {
			return invalidDefinition("selected adapter is unavailable", fmt.Errorf("node %s uses %s", key, node.Adapter))
		}
		capabilitySet := make(map[string]struct{}, len(available))
		for _, capability := range available {
			capabilitySet[capability] = struct{}{}
		}
		for _, required := range definition.Templates[node.Template].Capabilities.Required {
			if _, found := capabilitySet[required]; !found {
				return invalidDefinition(
					"selected adapter lacks a required capability",
					fmt.Errorf("node %s requires %s", key, required),
				)
			}
		}
	}
	return nil
}

func validateGraph(definition Definition) error {
	backEdges := make(map[domain.EdgeKey]struct{}, len(definition.Loops))
	for _, loop := range definition.Loops {
		if _, found := backEdges[loop.BackEdge]; found {
			return invalidDefinition("loops must not share a back-edge", nil)
		}
		backEdges[loop.BackEdge] = struct{}{}
	}
	indegree := make(map[domain.NodeKey]uint32, len(definition.Nodes))
	dependents := make(map[domain.NodeKey][]domain.NodeKey, len(definition.Nodes))
	predecessors := make(map[domain.NodeKey][]domain.NodeKey, len(definition.Nodes))
	edgesByID := make(map[domain.EdgeKey]Edge, len(definition.Edges))
	for key := range definition.Nodes {
		indegree[key] = 0
	}
	for _, edge := range definition.Edges {
		edgesByID[edge.ID] = edge
		if _, backEdge := backEdges[edge.ID]; backEdge {
			continue
		}
		indegree[edge.To]++
		dependents[edge.From] = append(dependents[edge.From], edge.To)
		predecessors[edge.To] = append(predecessors[edge.To], edge.From)
	}
	for _, loop := range definition.Loops {
		backEdge, found := edgesByID[loop.BackEdge]
		if !found || !backEdge.Required {
			return invalidDefinition("loop back-edge is absent or optional", nil)
		}
		fromTarget := reachableWorkflowNodes(backEdge.To, dependents)
		if _, found := fromTarget[backEdge.From]; !found {
			return invalidDefinition("loop back-edge does not close a graph path", nil)
		}
		toSource := reachableWorkflowNodes(backEdge.From, predecessors)
		members := make(map[domain.NodeKey]struct{})
		for key := range fromTarget {
			if _, found := toSource[key]; found {
				members[key] = struct{}{}
			}
		}
		switch loop.Stop.Kind {
		case "result_match":
			if _, found := members[loop.Stop.Node]; !found {
				return invalidDefinition("loop result stop references a node outside the loop", nil)
			}
		case "validation":
			found := false
			for key := range members {
				node, inDefinition := definition.Nodes[key]
				if !inDefinition {
					continue
				}
				for _, verification := range definition.Templates[node.Template].Verification {
					if verification.Key == loop.Stop.Validation {
						found = true
					}
				}
			}
			if !found {
				return invalidDefinition("loop validation stop is absent from the loop", nil)
			}
		}
	}
	ready := make([]domain.NodeKey, 0, len(definition.Nodes))
	for key, degree := range indegree {
		if degree == 0 {
			ready = append(ready, key)
		}
	}
	sort.Slice(ready, func(first int, second int) bool { return ready[first] < ready[second] })
	visited := 0
	for len(ready) > 0 {
		key := ready[0]
		ready = ready[1:]
		visited++
		for _, dependent := range dependents[key] {
			indegree[dependent]--
			if indegree[dependent] == 0 {
				ready = append(ready, dependent)
				sort.Slice(ready, func(first int, second int) bool { return ready[first] < ready[second] })
			}
		}
	}
	if visited != len(definition.Nodes) {
		return invalidDefinition("graph contains an undeclared cycle", nil)
	}
	return nil
}

func reachableWorkflowNodes(
	start domain.NodeKey,
	dependents map[domain.NodeKey][]domain.NodeKey,
) map[domain.NodeKey]struct{} {
	seen := map[domain.NodeKey]struct{}{start: {}}
	queue := []domain.NodeKey{start}
	for len(queue) > 0 {
		key := queue[0]
		queue = queue[1:]
		for _, dependent := range dependents[key] {
			if _, found := seen[dependent]; found {
				continue
			}
			seen[dependent] = struct{}{}
			queue = append(queue, dependent)
		}
	}
	return seen
}

func sortedNodeKeys(nodes map[domain.NodeKey]Node) []domain.NodeKey {
	keys := make([]domain.NodeKey, 0, len(nodes))
	for key := range nodes {
		keys = append(keys, key)
	}
	sort.Slice(keys, func(first int, second int) bool { return keys[first] < keys[second] })
	return keys
}

func invalidDefinition(message string, err error) error {
	return &domain.Error{
		Code: domain.ErrorCodeInvalidArgument, Op: "validate", Resource: "workflow definition",
		Message: message, Err: err,
	}
}
