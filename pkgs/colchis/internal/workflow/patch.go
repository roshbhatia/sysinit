package workflow

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"sort"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

type StageOperationValue struct {
	Template   Template          `json:"template"`
	Adapter    string            `json:"adapter"`
	Policy     *domain.JobPolicy `json:"policy,omitempty"`
	SourcePort string            `json:"sourcePort,omitempty"`
	InputPort  string            `json:"inputPort"`
	OutputPort string            `json:"outputPort"`
}

type PatchedDefinition struct {
	Resolved      ResolvedDefinition
	AffectedNodes []domain.NodeKey
}

func (evaluator *Evaluator) ApplyOperations(
	base Definition,
	operations []domain.GraphPatchOperation,
	resolver CapabilityResolver,
) (PatchedDefinition, error) {
	candidate, err := cloneDefinition(base)
	if err != nil {
		return PatchedDefinition{}, err
	}
	affected := make(map[domain.NodeKey]struct{})
	for index, operation := range operations {
		if !operation.Kind.Valid() {
			return PatchedDefinition{}, invalidPatch(index, "operation kind is unsupported", nil)
		}
		if err := applyOperation(&candidate, operation, affected); err != nil {
			return PatchedDefinition{}, invalidPatch(index, "operation is invalid", err)
		}
	}
	encoded, err := json.Marshal(candidate)
	if err != nil {
		return PatchedDefinition{}, invalidPatch(-1, "candidate definition cannot be encoded", err)
	}
	resolved, err := evaluator.Resolve(encoded, resolver)
	if err != nil {
		return PatchedDefinition{}, err
	}
	keys := make([]domain.NodeKey, 0, len(affected))
	for key := range affected {
		keys = append(keys, key)
	}
	sort.Slice(keys, func(first int, second int) bool { return keys[first] < keys[second] })
	return PatchedDefinition{Resolved: resolved, AffectedNodes: keys}, nil
}

func applyOperation(
	definition *Definition,
	operation domain.GraphPatchOperation,
	affected map[domain.NodeKey]struct{},
) error {
	switch operation.Kind {
	case domain.GraphPatchOperationInsertBetween:
		return insertBetween(definition, operation, affected)
	case domain.GraphPatchOperationInsertAfter:
		return insertAfter(definition, operation, affected)
	case domain.GraphPatchOperationReplace:
		return replaceStage(definition, operation, affected)
	case domain.GraphPatchOperationRemove:
		return removeStageOrEdge(definition, operation, affected)
	case domain.GraphPatchOperationAddBranch:
		return addBranch(definition, operation, affected)
	default:
		return fmt.Errorf("operation kind %q is unsupported", operation.Kind)
	}
}

func insertBetween(
	definition *Definition,
	operation domain.GraphPatchOperation,
	affected map[domain.NodeKey]struct{},
) error {
	if operation.TargetEdgeKey == nil || operation.InstanceNodeKey == nil || operation.StageTemplateKey == nil {
		return fmt.Errorf("target edge, instance node, and stage template are required")
	}
	edgeIndex, edge, found := findEdge(definition.Edges, *operation.TargetEdgeKey)
	if !found {
		return fmt.Errorf("target edge %q does not exist", *operation.TargetEdgeKey)
	}
	value, err := decodeStageOperationValue(operation.Value)
	if err != nil {
		return err
	}
	if err := addStage(definition, *operation.InstanceNodeKey, *operation.StageTemplateKey, &value); err != nil {
		return err
	}
	firstID := derivedEdgeKey(operation, "incoming")
	secondID := derivedEdgeKey(operation, "outgoing")
	replacement := []Edge{
		{
			ID: firstID, From: edge.From, FromPort: edge.FromPort,
			To: *operation.InstanceNodeKey, ToPort: value.InputPort,
			ValueSchemaDigest: value.Template.InputSchemaDigest, Required: edge.Required,
		},
		{
			ID: secondID, From: *operation.InstanceNodeKey, FromPort: value.OutputPort,
			To: edge.To, ToPort: edge.ToPort,
			ValueSchemaDigest: value.Template.OutputSchemaDigest, Required: edge.Required,
		},
	}
	definition.Edges = replaceEdgeAt(definition.Edges, edgeIndex, replacement)
	for index := range definition.Loops {
		if definition.Loops[index].BackEdge == edge.ID {
			definition.Loops[index].BackEdge = secondID
		}
	}
	markDownstream(*definition, edge.To, affected)
	affected[*operation.InstanceNodeKey] = struct{}{}
	return nil
}

func insertAfter(
	definition *Definition,
	operation domain.GraphPatchOperation,
	affected map[domain.NodeKey]struct{},
) error {
	if operation.TargetNodeKey == nil || operation.InstanceNodeKey == nil || operation.StageTemplateKey == nil {
		return fmt.Errorf("target node, instance node, and stage template are required")
	}
	target, found := definition.Nodes[*operation.TargetNodeKey]
	if !found {
		return fmt.Errorf("target node %q does not exist", *operation.TargetNodeKey)
	}
	value, err := decodeStageOperationValue(operation.Value)
	if err != nil {
		return err
	}
	if err := addStage(definition, *operation.InstanceNodeKey, *operation.StageTemplateKey, &value); err != nil {
		return err
	}
	targetTemplate := definition.Templates[target.Template]
	if value.SourcePort == "" {
		return fmt.Errorf("source port is required")
	}
	incoming := Edge{
		ID: derivedEdgeKey(operation, "incoming"), From: *operation.TargetNodeKey,
		FromPort: value.SourcePort, To: *operation.InstanceNodeKey, ToPort: value.InputPort,
		ValueSchemaDigest: targetTemplate.OutputSchemaDigest, Required: true,
	}
	result := make([]Edge, 0, len(definition.Edges)+1)
	result = append(result, incoming)
	for _, edge := range definition.Edges {
		if edge.From == *operation.TargetNodeKey {
			markDownstream(*definition, edge.To, affected)
			edge.From = *operation.InstanceNodeKey
			edge.FromPort = value.OutputPort
			edge.ValueSchemaDigest = value.Template.OutputSchemaDigest
		}
		result = append(result, edge)
	}
	definition.Edges = result
	affected[*operation.InstanceNodeKey] = struct{}{}
	return nil
}

func replaceStage(
	definition *Definition,
	operation domain.GraphPatchOperation,
	affected map[domain.NodeKey]struct{},
) error {
	if operation.TargetNodeKey == nil || operation.StageTemplateKey == nil {
		return fmt.Errorf("target node and stage template are required")
	}
	node, found := definition.Nodes[*operation.TargetNodeKey]
	if !found {
		return fmt.Errorf("target node %q does not exist", *operation.TargetNodeKey)
	}
	value, err := decodeStageOperationValue(operation.Value)
	if err != nil {
		return err
	}
	if existing, found := definition.Templates[*operation.StageTemplateKey]; found {
		if value.Template.Kind != "" {
			return fmt.Errorf("replacement template %q already exists", *operation.StageTemplateKey)
		}
		value.Template = existing
	} else if value.Template.Kind == "" {
		return fmt.Errorf("replacement template %q does not exist", *operation.StageTemplateKey)
	} else {
		definition.Templates[*operation.StageTemplateKey] = value.Template
	}
	node.Template = *operation.StageTemplateKey
	node.Adapter = value.Adapter
	if value.Policy != nil {
		node.Policy = *value.Policy
	}
	if value.Template.MaxAttempts > 0 {
		node.Budget.MaxAttempts = value.Template.MaxAttempts
	}
	definition.Nodes[*operation.TargetNodeKey] = node
	markDownstream(*definition, *operation.TargetNodeKey, affected)
	return nil
}

func removeStageOrEdge(
	definition *Definition,
	operation domain.GraphPatchOperation,
	affected map[domain.NodeKey]struct{},
) error {
	if operation.TargetEdgeKey != nil {
		index, edge, found := findEdge(definition.Edges, *operation.TargetEdgeKey)
		if !found {
			return fmt.Errorf("target edge %q does not exist", *operation.TargetEdgeKey)
		}
		definition.Edges = append(definition.Edges[:index], definition.Edges[index+1:]...)
		markDownstream(*definition, edge.To, affected)
		return nil
	}
	if operation.TargetNodeKey == nil {
		return fmt.Errorf("target node or edge is required")
	}
	if _, found := definition.Nodes[*operation.TargetNodeKey]; !found {
		return fmt.Errorf("target node %q does not exist", *operation.TargetNodeKey)
	}
	incoming := edgesTo(definition.Edges, *operation.TargetNodeKey)
	outgoing := edgesFrom(definition.Edges, *operation.TargetNodeKey)
	if len(incoming) > 1 || len(outgoing) > 1 {
		return fmt.Errorf("node removal requires at most one incoming and one outgoing edge")
	}
	result := make([]Edge, 0, len(definition.Edges))
	for _, edge := range definition.Edges {
		if edge.From != *operation.TargetNodeKey && edge.To != *operation.TargetNodeKey {
			result = append(result, edge)
		}
	}
	if len(incoming) == 1 && len(outgoing) == 1 {
		bridge := outgoing[0]
		bridge.ID = derivedEdgeKey(operation, "bridge")
		bridge.From = incoming[0].From
		bridge.FromPort = incoming[0].FromPort
		bridge.Required = incoming[0].Required && outgoing[0].Required
		result = append(result, bridge)
		markDownstream(*definition, outgoing[0].To, affected)
	}
	delete(definition.Nodes, *operation.TargetNodeKey)
	affected[*operation.TargetNodeKey] = struct{}{}
	definition.Edges = result
	return nil
}

func addBranch(
	definition *Definition,
	operation domain.GraphPatchOperation,
	affected map[domain.NodeKey]struct{},
) error {
	if operation.TargetNodeKey == nil || operation.InstanceNodeKey == nil || operation.StageTemplateKey == nil {
		return fmt.Errorf("target node, instance node, and stage template are required")
	}
	target, found := definition.Nodes[*operation.TargetNodeKey]
	if !found {
		return fmt.Errorf("target node %q does not exist", *operation.TargetNodeKey)
	}
	value, err := decodeStageOperationValue(operation.Value)
	if err != nil {
		return err
	}
	if err := addStage(definition, *operation.InstanceNodeKey, *operation.StageTemplateKey, &value); err != nil {
		return err
	}
	template := definition.Templates[target.Template]
	if value.SourcePort == "" {
		return fmt.Errorf("source port is required")
	}
	definition.Edges = append(definition.Edges, Edge{
		ID: derivedEdgeKey(operation, "branch"), From: *operation.TargetNodeKey,
		FromPort: value.SourcePort, To: *operation.InstanceNodeKey, ToPort: value.InputPort,
		ValueSchemaDigest: template.OutputSchemaDigest, Required: true,
	})
	affected[*operation.InstanceNodeKey] = struct{}{}
	return nil
}

func addStage(
	definition *Definition,
	nodeKey domain.NodeKey,
	templateKey domain.StageTemplateKey,
	value *StageOperationValue,
) error {
	if _, found := definition.Nodes[nodeKey]; found {
		return fmt.Errorf("instance node %q already exists", nodeKey)
	}
	template, found := definition.Templates[templateKey]
	if found {
		if value.Template.Kind != "" {
			return fmt.Errorf("stage template %q already exists", templateKey)
		}
	} else {
		if value.Template.Kind == "" {
			return fmt.Errorf("stage template %q does not exist", templateKey)
		}
		template = value.Template
		definition.Templates[templateKey] = template
	}
	value.Template = template
	attempts := template.MaxAttempts
	if attempts == 0 {
		attempts = 1
	}
	policy := definition.JobDefaults
	if value.Policy != nil {
		policy = *value.Policy
	}
	definition.Nodes[nodeKey] = Node{
		Template: templateKey, Adapter: value.Adapter,
		Policy: policy, Budget: NodeBudget{MaxAttempts: attempts},
	}
	return nil
}

func decodeStageOperationValue(value json.RawMessage) (StageOperationValue, error) {
	if !json.Valid(value) {
		return StageOperationValue{}, fmt.Errorf("operation value is not valid JSON")
	}
	var decoded StageOperationValue
	if err := json.Unmarshal(value, &decoded); err != nil {
		return StageOperationValue{}, fmt.Errorf("decode stage operation value: %w", err)
	}
	if decoded.Adapter == "" || decoded.InputPort == "" || decoded.OutputPort == "" {
		return StageOperationValue{}, fmt.Errorf("adapter, input port, and output port are required")
	}
	return decoded, nil
}

func cloneDefinition(definition Definition) (Definition, error) {
	encoded, err := json.Marshal(definition)
	if err != nil {
		return Definition{}, invalidDefinition("workflow definition cannot be cloned", err)
	}
	var clone Definition
	if err := json.Unmarshal(encoded, &clone); err != nil {
		return Definition{}, invalidDefinition("workflow definition clone cannot be decoded", err)
	}
	return clone, nil
}

func findEdge(edges []Edge, key domain.EdgeKey) (int, Edge, bool) {
	for index, edge := range edges {
		if edge.ID == key {
			return index, edge, true
		}
	}
	return 0, Edge{}, false
}

func replaceEdgeAt(edges []Edge, index int, replacement []Edge) []Edge {
	result := make([]Edge, 0, len(edges)-1+len(replacement))
	result = append(result, edges[:index]...)
	result = append(result, replacement...)
	return append(result, edges[index+1:]...)
}

func edgesTo(edges []Edge, key domain.NodeKey) []Edge {
	result := make([]Edge, 0)
	for _, edge := range edges {
		if edge.To == key {
			result = append(result, edge)
		}
	}
	return result
}

func edgesFrom(edges []Edge, key domain.NodeKey) []Edge {
	result := make([]Edge, 0)
	for _, edge := range edges {
		if edge.From == key {
			result = append(result, edge)
		}
	}
	return result
}

func markDownstream(definition Definition, start domain.NodeKey, affected map[domain.NodeKey]struct{}) {
	backEdges := make(map[domain.EdgeKey]struct{}, len(definition.Loops))
	for _, loop := range definition.Loops {
		backEdges[loop.BackEdge] = struct{}{}
	}
	queue := []domain.NodeKey{start}
	for len(queue) > 0 {
		key := queue[0]
		queue = queue[1:]
		if _, found := affected[key]; found {
			continue
		}
		affected[key] = struct{}{}
		for _, edge := range definition.Edges {
			if _, backEdge := backEdges[edge.ID]; edge.From == key && !backEdge {
				queue = append(queue, edge.To)
			}
		}
	}
}

func derivedEdgeKey(operation domain.GraphPatchOperation, role string) domain.EdgeKey {
	seed := string(operation.Kind) + "\x00" + role
	for _, value := range []*string{
		stringPointer(operation.TargetNodeKey), stringPointer(operation.TargetEdgeKey),
		stringPointer(operation.InstanceNodeKey), stringPointer(operation.StageTemplateKey),
	} {
		if value != nil {
			seed += "\x00" + *value
		}
	}
	digest := sha256.Sum256([]byte(seed))
	return domain.EdgeKey(fmt.Sprintf("edge-%x", digest[:16]))
}

func stringPointer[T ~string](value *T) *string {
	if value == nil {
		return nil
	}
	converted := string(*value)
	return &converted
}

func invalidPatch(index int, message string, err error) error {
	resource := "graph patch"
	if index >= 0 {
		resource = fmt.Sprintf("graph patch operation %d", index)
	}
	return &domain.Error{
		Code: domain.ErrorCodeInvalidArgument, Op: "apply", Resource: resource,
		Message: message, Err: err,
	}
}
