package domain

import (
	"encoding/json"
	"errors"
	"reflect"
	"strings"
	"testing"
	"time"
)

func TestIdentifiers(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name    string
		id      SessionID
		wantErr bool
	}{
		{name: "valid", id: "session-83"},
		{name: "namespaced", id: "runtime:pi.17"},
		{name: "empty", id: "", wantErr: true},
		{name: "punctuation only", id: "::", wantErr: true},
		{name: "space", id: "session 83", wantErr: true},
		{name: "too long", id: SessionID(strings.Repeat("a", maxIdentifierLength+1)), wantErr: true},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			err := test.id.Validate()
			if test.wantErr && err == nil {
				t.Fatal("Validate() returned nil")
			}
			if !test.wantErr && err != nil {
				t.Fatalf("Validate() returned %v", err)
			}
		})
	}
}

func TestStatesRejectUnknownValues(t *testing.T) {
	t.Parallel()

	if !NodeRunStateReady.Valid() {
		t.Fatal("ready node state is invalid")
	}
	if NodeRunState("unknown").Valid() {
		t.Fatal("unknown node state is valid")
	}
	if !ValidationStateStale.Valid() {
		t.Fatal("stale validation state is invalid")
	}
	if !CommandStateIndeterminate.Valid() {
		t.Fatal("indeterminate command state is invalid")
	}
	if !SessionReconciliationRehydrated.Valid() || SessionReconciliationState("unknown").Valid() {
		t.Fatal("session reconciliation state validity is incorrect")
	}
	if !InterventionKindInterrupt.Valid() || InterventionKind("unknown").Valid() ||
		!InterventionStateQueued.Valid() || InterventionState("unknown").Valid() {
		t.Fatal("intervention validity is incorrect")
	}
	if Authority("unknown").Valid() {
		t.Fatal("unknown authority is valid")
	}
	if !AdapterPortPlanning.Valid() || !AdapterPortActivity.Valid() || !AdapterPortAnnotation.Valid() ||
		!AdapterPortEffect.Valid() {
		t.Fatal("provenance adapter port is invalid")
	}
	pluginID, adapterID := ParseAdapterSelector("safe::pi")
	if pluginID != "safe" || adapterID != "pi" {
		t.Fatalf("ParseAdapterSelector() = %q, %q", pluginID, adapterID)
	}
	pluginID, adapterID = ParseAdapterSelector("::pi")
	if pluginID != "" || adapterID != "::pi" {
		t.Fatalf("malformed ParseAdapterSelector() = %q, %q", pluginID, adapterID)
	}
	if !GraphPatchOperationInsertBetween.Valid() || GraphPatchOperationKind("unknown").Valid() {
		t.Fatal("graph patch operation validity is incorrect")
	}
	if !RestartPointNodeAdmission.Valid() || RestartPointKind("unknown").Valid() {
		t.Fatal("restart point validity is incorrect")
	}
	if !ActivityKindModelCall.Valid() || ActivityKind("unknown").Valid() {
		t.Fatal("activity kind validity is incorrect")
	}
	if !ProvenanceBasisAdapterReported.Valid() || ProvenanceBasis("unknown").Valid() {
		t.Fatal("provenance basis validity is incorrect")
	}
	if !ProvenanceRelationProduced.Valid() || ProvenanceRelationKind("unknown").Valid() {
		t.Fatal("provenance relation validity is incorrect")
	}
	if !AnnotationOriginUser.Valid() || AnnotationOrigin("unknown").Valid() {
		t.Fatal("annotation origin validity is incorrect")
	}
	if !AnnotationStateAnswered.Valid() || AnnotationState("unknown").Valid() {
		t.Fatal("annotation state validity is incorrect")
	}
}

func TestJobPolicyRejectsUnknownValues(t *testing.T) {
	t.Parallel()

	policy := JobPolicy{
		Approvals: ApprovalPolicyNever, Filesystem: FilesystemPolicyWorkspaceWrite, Network: "ambient",
	}
	if err := policy.Validate(); !IsErrorCode(err, ErrorCodeInvalidArgument) {
		t.Fatalf("Validate() error = %v", err)
	}
}

func TestContractIdentifiers(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name     string
		validate func() error
	}{
		{name: "graph patch", validate: func() error { return GraphPatchID("patch-1").Validate() }},
		{name: "restart point", validate: func() error { return RestartPointID("restart-1").Validate() }},
		{name: "run fork", validate: func() error { return RunForkID("fork-1").Validate() }},
		{name: "intervention", validate: func() error { return InterventionID("intervention-1").Validate() }},
		{name: "activity", validate: func() error { return ActivityID("activity-1").Validate() }},
		{name: "prompt", validate: func() error { return PromptArtifactID("prompt-1").Validate() }},
		{name: "commit", validate: func() error { return CommitObservationID("commit-1").Validate() }},
		{name: "relation", validate: func() error { return ProvenanceRelationID("relation-1").Validate() }},
		{name: "annotation", validate: func() error { return AnnotationID("annotation-1").Validate() }},
		{name: "reply", validate: func() error { return AnnotationReplyID("reply-1").Validate() }},
		{name: "node key", validate: func() error { return NodeKey("judge-1").Validate() }},
		{name: "edge key", validate: func() error { return EdgeKey("build-to-test").Validate() }},
		{name: "stage template", validate: func() error { return StageTemplateKey("judge").Validate() }},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			if err := test.validate(); err != nil {
				t.Fatalf("Validate() returned %v", err)
			}
		})
	}
}

func TestGraphPatchContractRoundTrips(t *testing.T) {
	t.Parallel()

	edge := EdgeKey("build-to-test")
	node := NodeKey("judge-1")
	template := StageTemplateKey("judge")
	run := WorkflowRunID("run-1")
	want := GraphPatch{
		Metadata:                   validMetadata(),
		ID:                         "patch-1",
		WorkflowRunID:              &run,
		BaseWorkflowDefinitionID:   "definition-1",
		ResultWorkflowDefinitionID: "definition-2",
		ExpectedDefinitionVersion:  1,
		CommandID:                  "command-1",
		Operations: []GraphPatchOperation{{
			Kind:             GraphPatchOperationInsertBetween,
			TargetEdgeKey:    &edge,
			InstanceNodeKey:  &node,
			StageTemplateKey: &template,
			Value:            json.RawMessage(`{"verdict":"approved"}`),
		}},
	}

	encoded, err := json.Marshal(want)
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	var got GraphPatch
	if err := json.Unmarshal(encoded, &got); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("round trip = %#v, want %#v", got, want)
	}
}

func TestReplayContractsRoundTrip(t *testing.T) {
	t.Parallel()

	nodeRun := NodeRunID("node-run-1")
	restart := RestartPoint{
		Metadata:             validMetadata(),
		ID:                   "restart-1",
		Kind:                 RestartPointNodeAdmission,
		WorkflowRunID:        "run-1",
		WorkflowDefinitionID: "definition-1",
		DefinitionVersion:    2,
		EventCursor:          41,
		SnapshotID:           "snapshot-1",
		NodeRunID:            &nodeRun,
		AdmissionIDs:         []AdmissionID{"admission-1"},
		CheckpointIDs:        []CheckpointID{"checkpoint-1"},
	}
	fork := RunFork{
		Metadata:                   validMetadata(),
		ID:                         "fork-1",
		ParentWorkflowRunID:        "run-1",
		ChildWorkflowRunID:         "run-2",
		RestartPointID:             restart.ID,
		TargetWorkflowDefinitionID: "definition-2",
		TargetDefinitionVersion:    3,
		ExpectedParentVersion:      4,
		StartingSnapshotID:         restart.SnapshotID,
		ReusedAdmissionIDs:         restart.AdmissionIDs,
		CommandID:                  "command-1",
		Principal:                  "owner",
	}

	encoded, err := json.Marshal(struct {
		Restart RestartPoint `json:"restart"`
		Fork    RunFork      `json:"fork"`
	}{Restart: restart, Fork: fork})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	var got struct {
		Restart RestartPoint `json:"restart"`
		Fork    RunFork      `json:"fork"`
	}
	if err := json.Unmarshal(encoded, &got); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if !reflect.DeepEqual(got.Restart, restart) || !reflect.DeepEqual(got.Fork, fork) {
		t.Fatalf("round trip = %#v, want restart %#v and fork %#v", got, restart, fork)
	}
}

func TestProvenanceContractsRoundTrip(t *testing.T) {
	t.Parallel()

	startedAt := time.Unix(20, 0).UTC()
	endedAt := startedAt.Add(time.Second)
	promptID := PromptArtifactID("prompt-1")
	activity := Activity{
		Metadata:         validMetadata(),
		ID:               "activity-1",
		Kind:             ActivityKindModelCall,
		WorkflowRunID:    "run-1",
		PromptArtifactID: &promptID,
		Provider:         "claude",
		ProviderID:       "request-1",
		Basis:            ProvenanceBasisAdapterReported,
		Authority:        AuthorityAdvisory,
		Source:           "traces",
		SourceID:         "span-1",
		StartedAt:        startedAt,
		EndedAt:          &endedAt,
	}
	prompt := PromptArtifact{
		Metadata:       validMetadata(),
		ID:             promptID,
		Digest:         "sha256:prompt",
		TemplateDigest: "sha256:template",
		MediaType:      "text/plain",
		ByteSize:       12,
		SecretNames:    []string{"model-token"},
		Content:        []byte("prompt value"),
	}
	commit := CommitObservation{
		Metadata:         validMetadata(),
		ID:               "commit-1",
		WorkspaceID:      "workspace-1",
		Repository:       "colchis",
		Commit:           "abc123",
		Parents:          []string{"def456"},
		TreeDigest:       "sha256:tree",
		BeforeSnapshotID: "snapshot-1",
		AfterSnapshotID:  "snapshot-2",
		Basis:            ProvenanceBasisBrokerObserved,
		Authority:        AuthorityHarness,
		ObservedAt:       endedAt,
	}
	relation := ProvenanceRelation{
		Metadata:   validMetadata(),
		ID:         "relation-1",
		Kind:       ProvenanceRelationProduced,
		From:       ResourceReference{Kind: "activity", ID: string(activity.ID)},
		To:         ResourceReference{Kind: "commit-observation", ID: string(commit.ID)},
		Basis:      ProvenanceBasisDerived,
		Authority:  AuthorityHarness,
		Source:     "snapshot-diff",
		SourceID:   "comparison-1",
		ObservedAt: endedAt,
	}

	encoded, err := json.Marshal(struct {
		Activity Activity           `json:"activity"`
		Prompt   PromptArtifact     `json:"prompt"`
		Commit   CommitObservation  `json:"commit"`
		Relation ProvenanceRelation `json:"relation"`
	}{Activity: activity, Prompt: prompt, Commit: commit, Relation: relation})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	var got struct {
		Activity Activity           `json:"activity"`
		Prompt   PromptArtifact     `json:"prompt"`
		Commit   CommitObservation  `json:"commit"`
		Relation ProvenanceRelation `json:"relation"`
	}
	if err := json.Unmarshal(encoded, &got); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if !reflect.DeepEqual(got.Activity, activity) || !reflect.DeepEqual(got.Prompt, prompt) {
		t.Fatalf("activity round trip = %#v, prompt = %#v", got.Activity, got.Prompt)
	}
	if !reflect.DeepEqual(got.Commit, commit) || !reflect.DeepEqual(got.Relation, relation) {
		t.Fatalf("commit round trip = %#v, relation = %#v", got.Commit, got.Relation)
	}
}

func TestAnnotationContractKeepsReplyHistory(t *testing.T) {
	t.Parallel()

	annotation := Annotation{
		Metadata:  validMetadata(),
		ID:        "annotation-1",
		Summary:   "Explain the pinned version",
		Rationale: "The diff does not show the upstream constraint.",
		Author:    "owner@example.com",
		Origin:    AnnotationOriginUser,
		State:     AnnotationStateAnswered,
		Anchor:    &AnnotationAnchor{File: "/workspace/flake.nix", Line: 12, Text: "version = 1;"},
		Targets:   []ResourceReference{{Kind: "commit-observation", ID: "commit-1"}},
		Authority: AuthorityOwner,
		Source:    "utils-note",
		SourceID:  "note-1",
	}
	reply := AnnotationReply{
		Metadata:     validMetadata(),
		ID:           "reply-1",
		AnnotationID: annotation.ID,
		Summary:      "The version avoids an upstream linker failure.",
		Author:       "codex",
		Authority:    AuthorityAdvisory,
		Source:       "utils-note",
		SourceID:     "reply-1",
	}

	encoded, err := json.Marshal(struct {
		Annotation Annotation        `json:"annotation"`
		Replies    []AnnotationReply `json:"replies"`
	}{Annotation: annotation, Replies: []AnnotationReply{reply}})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	if !strings.Contains(string(encoded), `"annotationId":"annotation-1"`) {
		t.Fatalf("encoded reply does not reference its annotation: %s", encoded)
	}
}

func TestBudgetsValidateCapacity(t *testing.T) {
	t.Parallel()

	budgets := validBudgets()
	if err := budgets.Validate(); err != nil {
		t.Fatalf("Validate() returned %v", err)
	}

	budgets.EmergencyReserveBytes = budgets.MaxStateBytes
	err := budgets.Validate()
	if !IsErrorCode(err, ErrorCodeInvalidArgument) {
		t.Fatalf("Validate() error = %v", err)
	}

	budgets = validBudgets()
	budgets.MaxSnapshotBytes = uint64(1<<63 - 1)
	err = budgets.Validate()
	if !IsErrorCode(err, ErrorCodeInvalidArgument) {
		t.Fatalf("Validate() snapshot size error = %v", err)
	}
}

func TestEventEnvelopeValidate(t *testing.T) {
	t.Parallel()

	event := EventEnvelope{
		SchemaVersion: CurrentEventSchemaVersion,
		Cursor:        1,
		OccurredAt:    time.Unix(10, 0).UTC(),
		Aggregate:     ResourceReference{Kind: "session", ID: "session-83"},
		Type:          "owner.message",
		Payload:       json.RawMessage(`{"text":"continue"}`),
	}
	if err := event.Validate(); err != nil {
		t.Fatalf("Validate() returned %v", err)
	}

	event.Payload = json.RawMessage(`{"text":`)
	if err := event.Validate(); !IsErrorCode(err, ErrorCodeInvalidArgument) {
		t.Fatalf("Validate() error = %v", err)
	}
}

func TestRecordMetadataValidate(t *testing.T) {
	t.Parallel()

	createdAt := time.Unix(10, 0).UTC()
	metadata := RecordMetadata{
		SchemaVersion:   CurrentRecordSchemaVersion,
		ResourceVersion: 1,
		CreatedAt:       createdAt,
		UpdatedAt:       createdAt.Add(time.Second),
	}
	if err := metadata.Validate(); err != nil {
		t.Fatalf("Validate() returned %v", err)
	}

	metadata.UpdatedAt = createdAt.Add(-time.Second)
	if err := metadata.Validate(); !IsErrorCode(err, ErrorCodeInvalidArgument) {
		t.Fatalf("Validate() error = %v", err)
	}
}

func TestErrorWrapsCause(t *testing.T) {
	t.Parallel()

	cause := errors.New("storage unavailable")
	err := &Error{
		Code:     ErrorCodeInternal,
		Op:       "append",
		Resource: "event",
		Message:  "transaction failed",
		Err:      cause,
	}

	if !errors.Is(err, cause) {
		t.Fatal("Error does not wrap its cause")
	}
	if !IsErrorCode(err, ErrorCodeInternal) {
		t.Fatal("IsErrorCode() rejected the code")
	}
	if got := err.Error(); got != "append event: internal: transaction failed" {
		t.Fatalf("Error() = %q", got)
	}
}

func validBudgets() Budgets {
	return Budgets{
		MaxConcurrentNodes:       8,
		MaxConcurrentProcesses:   16,
		MaxEventBytes:            1 << 20,
		MaxEventsPerSecond:       100,
		MaxStateBytes:            1 << 30,
		EmergencyReserveBytes:    1 << 20,
		MaxSnapshotBytes:         10 << 30,
		MaxMaterializedSnapshots: 4,
		MaxVerificationSeconds:   900,
	}
}

func validMetadata() RecordMetadata {
	createdAt := time.Unix(10, 0).UTC()
	return RecordMetadata{
		SchemaVersion:   CurrentRecordSchemaVersion,
		ResourceVersion: 1,
		CreatedAt:       createdAt,
		UpdatedAt:       createdAt,
	}
}
