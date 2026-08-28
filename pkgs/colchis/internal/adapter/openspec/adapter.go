package openspec

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"sort"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

type Adapter struct {
	runner Runner
}

func New(runner Runner) (*Adapter, error) {
	if runner == nil {
		return nil, adapterError(
			domain.ErrorCodeInvalidArgument, "create OpenSpec adapter", FrameworkID, "runner is nil", nil,
		)
	}
	return &Adapter{runner: runner}, nil
}

func (adapter *Adapter) Invoke(
	ctx context.Context,
	operation string,
	input json.RawMessage,
) (json.RawMessage, error) {
	switch operation {
	case OperationDiscover:
		if _, err := decodeRequest[DiscoverRequest](input); err != nil {
			return nil, err
		}
		result, err := adapter.Discover(ctx)
		if err != nil {
			return nil, err
		}
		encoded, err := json.Marshal(result)
		if err != nil {
			return nil, adapterError(domain.ErrorCodeInternal, "encode discovery", FrameworkID, err.Error(), err)
		}
		return encoded, nil
	case OperationSnapshot:
		request, err := decodeRequest[SnapshotRequest](input)
		if err != nil {
			return nil, err
		}
		result, err := adapter.Snapshot(ctx, request)
		if err != nil {
			return nil, err
		}
		encoded, err := json.Marshal(result)
		if err != nil {
			return nil, adapterError(domain.ErrorCodeInternal, "encode snapshot", request.Change, err.Error(), err)
		}
		return encoded, nil
	case OperationAction:
		request, err := decodeRequest[ActionRequest](input)
		if err != nil {
			return nil, err
		}
		result, err := adapter.Action(ctx, request)
		if err != nil {
			return nil, err
		}
		encoded, err := json.Marshal(result)
		if err != nil {
			return nil, adapterError(domain.ErrorCodeInternal, "encode action", request.Action, err.Error(), err)
		}
		return encoded, nil
	default:
		return nil, adapterError(
			domain.ErrorCodeNotFound, "invoke OpenSpec adapter", operation, "planning operation is unknown", nil,
		)
	}
}

func (adapter *Adapter) Discover(ctx context.Context) (DiscoverResult, error) {
	schemasPayload, err := adapter.runner.RunJSON(ctx, "schemas", "--json")
	if err != nil {
		return DiscoverResult{}, err
	}
	var rawEntries []json.RawMessage
	if err := json.Unmarshal(schemasPayload, &rawEntries); err != nil {
		return DiscoverResult{}, invalidPayload("schemas", err)
	}
	type discoveredSchema struct {
		Name        string   `json:"name"`
		Description string   `json:"description"`
		Artifacts   []string `json:"artifacts"`
		Source      string   `json:"source"`
	}
	result := DiscoverResult{Framework: FrameworkID, Schemas: make([]Schema, 0, len(rawEntries))}
	detailPayloads := make([]json.RawMessage, 0, len(rawEntries)*2)
	for _, rawEntry := range rawEntries {
		var entry discoveredSchema
		if err := json.Unmarshal(rawEntry, &entry); err != nil {
			return DiscoverResult{}, invalidPayload("schema entry", err)
		}
		if err := validatePlanningIdentifier("schema", entry.Name); err != nil {
			return DiscoverResult{}, err
		}
		templatesPayload, err := adapter.runner.RunJSON(ctx, "templates", "--schema", entry.Name, "--json")
		if err != nil {
			return DiscoverResult{}, err
		}
		resolutionPayload, err := adapter.runner.RunJSON(ctx, "schema", "which", entry.Name, "--json")
		if err != nil {
			return DiscoverResult{}, err
		}
		var templates map[string]json.RawMessage
		if err := json.Unmarshal(templatesPayload, &templates); err != nil {
			return DiscoverResult{}, invalidPayload(entry.Name+" templates", err)
		}
		var resolution struct {
			Source string `json:"source"`
			Path   string `json:"path"`
		}
		if err := json.Unmarshal(resolutionPayload, &resolution); err != nil {
			return DiscoverResult{}, invalidPayload(entry.Name+" resolution", err)
		}
		templateArtifacts := sortedMapKeys(templates)
		declaredArtifacts := sortedUniqueStrings(entry.Artifacts)
		opaque, err := json.Marshal(struct {
			Listing    json.RawMessage `json:"listing"`
			Templates  json.RawMessage `json:"templates"`
			Resolution json.RawMessage `json:"resolution"`
		}{Listing: rawEntry, Templates: templatesPayload, Resolution: resolutionPayload})
		if err != nil {
			return DiscoverResult{}, adapterError(domain.ErrorCodeInternal, "encode schema source", entry.Name, err.Error(), err)
		}
		source := entry.Source
		if resolution.Source != "" {
			source = resolution.Source
		}
		result.Schemas = append(result.Schemas, Schema{
			ID: entry.Name, Description: entry.Description, Source: source,
			DeclaredArtifacts: declaredArtifacts, TemplateArtifacts: templateArtifacts,
			Location: resolution.Path, SourceDigest: digestPayloads(rawEntry, templatesPayload, resolutionPayload),
			OpaqueSourceData: opaque,
		})
		detailPayloads = append(detailPayloads, templatesPayload, resolutionPayload)
	}
	sort.Slice(result.Schemas, func(first int, second int) bool {
		return result.Schemas[first].ID < result.Schemas[second].ID
	})
	opaque, err := json.Marshal(struct {
		Schemas json.RawMessage   `json:"schemas"`
		Details []json.RawMessage `json:"details"`
	}{Schemas: schemasPayload, Details: detailPayloads})
	if err != nil {
		return DiscoverResult{}, adapterError(domain.ErrorCodeInternal, "encode discovery source", FrameworkID, err.Error(), err)
	}
	allPayloads := append([]json.RawMessage{schemasPayload}, detailPayloads...)
	result.SourceDigest = digestPayloads(allPayloads...)
	result.OpaqueSourceData = opaque
	return result, nil
}

func (adapter *Adapter) Snapshot(ctx context.Context, request SnapshotRequest) (Snapshot, error) {
	if err := validatePlanningIdentifier("change", request.Change); err != nil {
		return Snapshot{}, err
	}
	statusPayload, err := adapter.runner.RunJSON(
		ctx, "status", "--change", request.Change, "--json",
	)
	if err != nil {
		return Snapshot{}, err
	}
	status, err := decodeStatus(statusPayload)
	if err != nil {
		return Snapshot{}, err
	}
	if status.ChangeName != request.Change || status.SchemaName == "" {
		return Snapshot{}, invalidPayload(request.Change+" status", nil)
	}
	instructions := make(map[string]json.RawMessage)
	decodedInstructions := make(map[string]instructionDocument)
	for _, action := range []string{"apply", "archive"} {
		payload, actionErr := adapter.runner.RunJSON(
			ctx, "instructions", action, "--change", request.Change, "--json",
		)
		if actionErr != nil {
			if domain.IsErrorCode(actionErr, domain.ErrorCodeNotFound) {
				continue
			}
			return Snapshot{}, actionErr
		}
		instruction, actionErr := decodeInstruction(payload)
		if actionErr != nil {
			return Snapshot{}, actionErr
		}
		if instruction.ChangeName != "" && instruction.ChangeName != request.Change ||
			instruction.SchemaName != "" && instruction.SchemaName != status.SchemaName {
			return Snapshot{}, invalidPayload(action+" instruction identity", nil)
		}
		instructions[action] = payload
		decodedInstructions[action] = instruction
	}
	apply, hasApply := decodedInstructions["apply"]
	archive, hasArchive := decodedInstructions["archive"]
	artifacts := normalizeArtifacts(status)
	actions := normalizeActions(status, apply, hasApply, archive, hasArchive, artifacts)
	contextReferences := normalizeContext(status, apply)
	workItems, err := normalizeWorkItems(apply.Tasks)
	if err != nil {
		return Snapshot{}, err
	}
	gates := normalizeGates(status, apply, artifacts)
	opaque, err := json.Marshal(struct {
		Status       json.RawMessage            `json:"status"`
		Instructions map[string]json.RawMessage `json:"instructions"`
	}{Status: statusPayload, Instructions: instructions})
	if err != nil {
		return Snapshot{}, adapterError(domain.ErrorCodeInternal, "encode planning source", request.Change, err.Error(), err)
	}
	return Snapshot{
		Framework: FrameworkID, Change: request.Change, SchemaID: status.SchemaName,
		SourceDigest: digestPayloadMap(statusPayload, instructions), Artifacts: artifacts,
		Actions: actions, Context: contextReferences, WorkItems: workItems, Gates: gates,
		OpaqueSourceData: opaque,
	}, nil
}

func (adapter *Adapter) Action(ctx context.Context, request ActionRequest) (ActionResult, error) {
	if err := validatePlanningIdentifier("change", request.Change); err != nil {
		return ActionResult{}, err
	}
	if err := validatePlanningIdentifier("action", request.Action); err != nil {
		return ActionResult{}, err
	}
	statusPayload, err := adapter.runner.RunJSON(
		ctx, "status", "--change", request.Change, "--json",
	)
	if err != nil {
		return ActionResult{}, err
	}
	instructionPayload, err := adapter.runner.RunJSON(
		ctx, "instructions", request.Action, "--change", request.Change, "--json",
	)
	if err != nil {
		return ActionResult{}, err
	}
	status, err := decodeStatus(statusPayload)
	if err != nil {
		return ActionResult{}, err
	}
	instruction, err := decodeInstruction(instructionPayload)
	if err != nil {
		return ActionResult{}, err
	}
	if status.ChangeName != request.Change || status.SchemaName == "" {
		return ActionResult{}, invalidPayload(request.Change+" status", nil)
	}
	if instruction.ChangeName != "" && instruction.ChangeName != request.Change {
		return ActionResult{}, invalidPayload(request.Action+" change", nil)
	}
	if instruction.SchemaName != "" && instruction.SchemaName != status.SchemaName {
		return ActionResult{}, invalidPayload(request.Action+" schema", nil)
	}
	if instruction.ArtifactID != "" && instruction.ArtifactID != request.Action {
		return ActionResult{}, invalidPayload(request.Action+" artifact", nil)
	}
	workItems, err := normalizeWorkItems(instruction.Tasks)
	if err != nil {
		return ActionResult{}, err
	}
	opaque, err := json.Marshal(struct {
		Status      json.RawMessage `json:"status"`
		Instruction json.RawMessage `json:"instruction"`
	}{Status: statusPayload, Instruction: instructionPayload})
	if err != nil {
		return ActionResult{}, adapterError(domain.ErrorCodeInternal, "encode action source", request.Action, err.Error(), err)
	}
	return ActionResult{
		Framework: FrameworkID, Change: request.Change, SchemaID: status.SchemaName, Action: request.Action,
		Description: instruction.Description, Instruction: instruction.Instruction,
		OutputPath: instruction.OutputPath, ResolvedOutputPath: instruction.ResolvedOutputPath,
		Dependencies: sortedUniqueStrings(instruction.Dependencies),
		Unlocks:      sortedUniqueStrings(instruction.Unlocks), Context: normalizeInstructionContext(instruction),
		WorkItems: workItems, SourceDigest: digestPayloads(statusPayload, instructionPayload),
		OpaqueSourceData: opaque,
	}, nil
}

type statusDocument struct {
	ChangeName         string                   `json:"changeName"`
	SchemaName         string                   `json:"schemaName"`
	ArtifactPaths      map[string]artifactPaths `json:"artifactPaths"`
	IsPlanningComplete bool                     `json:"isPlanningComplete"`
	IsComplete         bool                     `json:"isComplete"`
	ApplyRequires      []string                 `json:"applyRequires"`
	ActionContext      actionContextDocument    `json:"actionContext"`
	Artifacts          []statusArtifactDocument `json:"artifacts"`
}

type artifactPaths struct {
	OutputPath          string   `json:"outputPath"`
	ResolvedOutputPath  string   `json:"resolvedOutputPath"`
	ExistingOutputPaths []string `json:"existingOutputPaths"`
}

type statusArtifactDocument struct {
	ID         string   `json:"id"`
	OutputPath string   `json:"outputPath"`
	Status     string   `json:"status"`
	Requires   []string `json:"requires"`
}

type actionContextDocument struct {
	RequiresAffectedAreaSelection bool     `json:"requiresAffectedAreaSelection"`
	Constraints                   []string `json:"constraints"`
}

type instructionDocument struct {
	ChangeName         string              `json:"changeName"`
	SchemaName         string              `json:"schemaName"`
	ArtifactID         string              `json:"artifactId"`
	Description        string              `json:"description"`
	Instruction        string              `json:"instruction"`
	OutputPath         string              `json:"outputPath"`
	ResolvedOutputPath string              `json:"resolvedOutputPath"`
	Dependencies       []string            `json:"dependencies"`
	Unlocks            []string            `json:"unlocks"`
	ContextFiles       map[string][]string `json:"contextFiles"`
	Tasks              []json.RawMessage   `json:"tasks"`
	Progress           *progressDocument   `json:"progress"`
}

type progressDocument struct {
	Total     uint64 `json:"total"`
	Complete  uint64 `json:"complete"`
	Remaining uint64 `json:"remaining"`
}

func decodeStatus(payload json.RawMessage) (statusDocument, error) {
	var document statusDocument
	if err := json.Unmarshal(payload, &document); err != nil {
		return statusDocument{}, invalidPayload("status", err)
	}
	return document, nil
}

func decodeInstruction(payload json.RawMessage) (instructionDocument, error) {
	var document instructionDocument
	if err := json.Unmarshal(payload, &document); err != nil {
		return instructionDocument{}, invalidPayload("instructions", err)
	}
	return document, nil
}

func normalizeArtifacts(status statusDocument) []Artifact {
	artifacts := make([]Artifact, 0, len(status.Artifacts))
	for _, source := range status.Artifacts {
		paths := status.ArtifactPaths[source.ID]
		outputPath := source.OutputPath
		if paths.OutputPath != "" {
			outputPath = paths.OutputPath
		}
		artifacts = append(artifacts, Artifact{
			ID: source.ID, Status: source.Status, OutputPath: outputPath,
			ResolvedOutputPath:  paths.ResolvedOutputPath,
			ExistingOutputPaths: sortedUniqueStrings(paths.ExistingOutputPaths),
			Requires:            sortedUniqueStrings(source.Requires),
		})
	}
	sort.Slice(artifacts, func(first int, second int) bool { return artifacts[first].ID < artifacts[second].ID })
	return artifacts
}

func normalizeActions(
	status statusDocument,
	apply instructionDocument,
	hasApply bool,
	archive instructionDocument,
	hasArchive bool,
	artifacts []Artifact,
) []Action {
	actions := make([]Action, 0, len(artifacts)+2)
	for _, artifact := range artifacts {
		actions = append(actions, Action{
			ID: artifact.ID, Kind: "artifact", Available: artifact.Status != "blocked",
			Requires: append([]string{}, artifact.Requires...),
		})
	}
	if hasApply {
		actions = append(actions, Action{
			ID: "apply", Kind: "implementation", Available: status.IsPlanningComplete,
			Requires: sortedUniqueStrings(status.ApplyRequires), Description: apply.Description,
		})
	}
	if hasArchive {
		archiveAvailable := status.IsComplete
		if apply.Progress != nil {
			archiveAvailable = archiveAvailable && apply.Progress.Remaining == 0
		}
		actions = append(actions, Action{
			ID: "archive", Kind: "lifecycle", Available: archiveAvailable, Requires: []string{},
			Description: archive.Description,
		})
	}
	return actions
}

func digestPayloadMap(status json.RawMessage, values map[string]json.RawMessage) string {
	keys := sortedMapKeys(values)
	payloads := []json.RawMessage{status}
	for _, key := range keys {
		payloads = append(payloads, values[key])
	}
	return digestPayloads(payloads...)
}

func normalizeContext(status statusDocument, instruction instructionDocument) []ContextReference {
	paths := make(map[string][]string, len(status.ArtifactPaths)+len(instruction.ContextFiles))
	for artifactID, artifactPaths := range status.ArtifactPaths {
		paths[artifactID] = append(paths[artifactID], artifactPaths.ExistingOutputPaths...)
	}
	for artifactID, contextPaths := range instruction.ContextFiles {
		paths[artifactID] = append(paths[artifactID], contextPaths...)
	}
	return contextReferences(paths)
}

func normalizeInstructionContext(instruction instructionDocument) []ContextReference {
	return contextReferences(instruction.ContextFiles)
}

func contextReferences(paths map[string][]string) []ContextReference {
	result := make([]ContextReference, 0, len(paths))
	for artifactID, artifactPaths := range paths {
		result = append(result, ContextReference{
			ArtifactID: artifactID, Paths: sortedUniqueStrings(artifactPaths),
		})
	}
	sort.Slice(result, func(first int, second int) bool { return result[first].ArtifactID < result[second].ArtifactID })
	return result
}

func normalizeWorkItems(rawItems []json.RawMessage) ([]WorkItem, error) {
	type taskDocument struct {
		ID          string `json:"id"`
		Description string `json:"description"`
		Done        bool   `json:"done"`
	}
	items := make([]WorkItem, 0, len(rawItems))
	for _, rawItem := range rawItems {
		var task taskDocument
		if err := json.Unmarshal(rawItem, &task); err != nil {
			return nil, invalidPayload("work item", err)
		}
		if task.ID == "" || task.Description == "" {
			return nil, invalidPayload("work item", nil)
		}
		items = append(items, WorkItem{
			ID: task.ID, Description: task.Description, Done: task.Done,
			OpaqueData: append(json.RawMessage(nil), rawItem...),
		})
	}
	return items, nil
}

func normalizeGates(
	status statusDocument,
	apply instructionDocument,
	artifacts []Artifact,
) []Gate {
	gates := make([]Gate, 0, len(artifacts)+2)
	for _, artifact := range artifacts {
		gates = append(gates, Gate{
			ID: "artifact:" + artifact.ID, Kind: "artifact", Satisfied: artifact.Status == "done",
			Detail: artifact.Status,
		})
	}
	if apply.Progress != nil && apply.Progress.Total > 0 {
		gates = append(gates, Gate{
			ID: "implementation", Kind: "work-items", Satisfied: apply.Progress.Remaining == 0,
			Detail: fmt.Sprintf("%d/%d complete", apply.Progress.Complete, apply.Progress.Total),
		})
	}
	if status.ActionContext.RequiresAffectedAreaSelection {
		gates = append(gates, Gate{
			ID: "affected-area-selection", Kind: "owner", Satisfied: false,
			Detail: strings.Join(status.ActionContext.Constraints, "; "),
		})
	}
	return gates
}

type requestDocument interface {
	DiscoverRequest | SnapshotRequest | ActionRequest
}

func decodeRequest[Request requestDocument](payload json.RawMessage) (Request, error) {
	var request Request
	decoder := json.NewDecoder(bytes.NewReader(payload))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&request); err != nil {
		return request, invalidPayload("planning request", err)
	}
	var trailing json.RawMessage
	if err := decoder.Decode(&trailing); err != io.EOF {
		return request, invalidPayload("planning request", err)
	}
	return request, nil
}

func validatePlanningIdentifier(kind string, value string) error {
	if strings.HasPrefix(value, "-") {
		return adapterError(
			domain.ErrorCodeInvalidArgument, "validate OpenSpec "+kind, value,
			kind+" cannot begin with a hyphen", nil,
		)
	}
	return (domain.ResourceReference{Kind: kind, ID: value}).Validate()
}

func sortedMapKeys(values map[string]json.RawMessage) []string {
	keys := make([]string, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}

func sortedUniqueStrings(values []string) []string {
	seen := make(map[string]struct{}, len(values))
	result := make([]string, 0, len(values))
	for _, value := range values {
		if value == "" {
			continue
		}
		if _, found := seen[value]; found {
			continue
		}
		seen[value] = struct{}{}
		result = append(result, value)
	}
	sort.Strings(result)
	return result
}

func digestPayloads(payloads ...json.RawMessage) string {
	hash := sha256.New()
	for _, payload := range payloads {
		_, _ = fmt.Fprintf(hash, "%d:", len(payload))
		_, _ = hash.Write(payload)
	}
	return fmt.Sprintf("sha256:%x", hash.Sum(nil))
}

func invalidPayload(resource string, err error) error {
	message := "OpenSpec JSON payload is incomplete"
	if err != nil {
		message = err.Error()
	}
	return adapterError(domain.ErrorCodeInvalidArgument, "decode OpenSpec payload", resource, message, err)
}
