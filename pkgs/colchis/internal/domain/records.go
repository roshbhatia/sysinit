package domain

import (
	"encoding/json"
	"time"
)

type SchemaVersion uint32
type ResourceVersion uint64

const CurrentRecordSchemaVersion SchemaVersion = 1

type RecordMetadata struct {
	SchemaVersion   SchemaVersion   `json:"schemaVersion"`
	ResourceVersion ResourceVersion `json:"resourceVersion"`
	CreatedAt       time.Time       `json:"createdAt"`
	UpdatedAt       time.Time       `json:"updatedAt"`
}

func (metadata RecordMetadata) Validate() error {
	if metadata.SchemaVersion != CurrentRecordSchemaVersion {
		return &Error{Code: ErrorCodeUnsupportedVersion, Resource: "record", Message: "schema version is unsupported"}
	}
	if metadata.ResourceVersion == 0 {
		return &Error{Code: ErrorCodeInvalidArgument, Resource: "record", Message: "resource version is zero"}
	}
	if metadata.CreatedAt.IsZero() || metadata.UpdatedAt.IsZero() {
		return &Error{Code: ErrorCodeInvalidArgument, Resource: "record", Message: "timestamps must be set"}
	}
	if metadata.UpdatedAt.Before(metadata.CreatedAt) {
		return &Error{Code: ErrorCodeInvalidArgument, Resource: "record", Message: "updatedAt precedes createdAt"}
	}
	return nil
}

type ResourceReference struct {
	Kind string `json:"kind"`
	ID   string `json:"id"`
}

type JobPolicy struct {
	Approvals  ApprovalPolicy   `json:"approvals"`
	Filesystem FilesystemPolicy `json:"filesystem"`
	Network    NetworkPolicy    `json:"network"`
}

func (policy JobPolicy) Validate() error {
	if !policy.Approvals.Valid() || !policy.Filesystem.Valid() || !policy.Network.Valid() {
		return &Error{
			Code: ErrorCodeInvalidArgument, Resource: "job-policy",
			Message: "approval, filesystem, and network policies must be valid",
		}
	}
	return nil
}

type CommandRequest struct {
	ID              CommandID        `json:"id"`
	IdempotencyKey  string           `json:"idempotencyKey"`
	Kind            string           `json:"kind"`
	ExpectedVersion *ResourceVersion `json:"expectedVersion,omitempty"`
	Payload         json.RawMessage  `json:"payload"`
}

func (request CommandRequest) Validate() error {
	if err := request.ID.Validate(); err != nil {
		return err
	}
	if err := (ResourceReference{Kind: "idempotency-key", ID: request.IdempotencyKey}).Validate(); err != nil {
		return err
	}
	if err := (ResourceReference{Kind: "command-kind", ID: request.Kind}).Validate(); err != nil {
		return err
	}
	if request.ExpectedVersion != nil && *request.ExpectedVersion == 0 {
		return &Error{Code: ErrorCodeInvalidArgument, Resource: "command", Message: "expectedVersion is zero"}
	}
	if !json.Valid(request.Payload) {
		return &Error{Code: ErrorCodeInvalidArgument, Resource: "command", Message: "payload is not valid JSON"}
	}
	return nil
}

func (reference ResourceReference) Validate() error {
	if err := validateIdentifier("resource kind", reference.Kind); err != nil {
		return err
	}
	return validateIdentifier(reference.Kind, reference.ID)
}

type WorkflowDefinition struct {
	Metadata                RecordMetadata        `json:"metadata"`
	ID                      WorkflowDefinitionID  `json:"id"`
	PredecessorID           *WorkflowDefinitionID `json:"predecessorId,omitempty"`
	DefinitionVersion       uint64                `json:"definitionVersion"`
	DefinitionSchemaVersion string                `json:"definitionSchemaVersion"`
	DefinitionDigest        string                `json:"definitionDigest"`
	SchemaDigest            string                `json:"schemaDigest"`
	EvaluatorVersion        string                `json:"evaluatorVersion"`
	Document                json.RawMessage       `json:"document"`
	ResolvedDocument        json.RawMessage       `json:"resolvedDocument"`
}

type WorkflowRun struct {
	Metadata             RecordMetadata       `json:"metadata"`
	ID                   WorkflowRunID        `json:"id"`
	WorkflowDefinition   WorkflowDefinitionID `json:"workflowDefinitionId"`
	DefinitionVersion    uint64               `json:"definitionVersion"`
	State                WorkflowRunState     `json:"state"`
	OrchestrationSession *SessionID           `json:"orchestrationSessionId,omitempty"`
	Budgets              Budgets              `json:"budgets"`
}

type NodeRun struct {
	Metadata             RecordMetadata `json:"metadata"`
	ID                   NodeRunID      `json:"id"`
	WorkflowRunID        WorkflowRunID  `json:"workflowRunId"`
	DefinitionVersion    uint64         `json:"definitionVersion"`
	NodeKey              NodeKey        `json:"nodeKey"`
	NodeDefinitionDigest string         `json:"nodeDefinitionDigest"`
	Adapter              string         `json:"adapter"`
	Attempt              uint32         `json:"attempt"`
	RepairAttempt        uint32         `json:"repairAttempt"`
	State                NodeRunState   `json:"state"`
	SessionID            *SessionID     `json:"sessionId,omitempty"`
	TaskResultID         *TaskResultID  `json:"taskResultId,omitempty"`
	AdmissionID          *AdmissionID   `json:"admissionId,omitempty"`
	InputSnapshotIDs     []SnapshotID   `json:"inputSnapshotIds"`
}

type GraphPatchOperation struct {
	Kind             GraphPatchOperationKind `json:"kind"`
	TargetNodeKey    *NodeKey                `json:"targetNodeKey,omitempty"`
	TargetEdgeKey    *EdgeKey                `json:"targetEdgeKey,omitempty"`
	InstanceNodeKey  *NodeKey                `json:"instanceNodeKey,omitempty"`
	StageTemplateKey *StageTemplateKey       `json:"stageTemplateKey,omitempty"`
	Value            json.RawMessage         `json:"value,omitempty"`
}

type GraphPatch struct {
	Metadata                   RecordMetadata        `json:"metadata"`
	ID                         GraphPatchID          `json:"id"`
	WorkflowRunID              *WorkflowRunID        `json:"workflowRunId,omitempty"`
	BaseWorkflowDefinitionID   WorkflowDefinitionID  `json:"baseWorkflowDefinitionId"`
	ResultWorkflowDefinitionID WorkflowDefinitionID  `json:"resultWorkflowDefinitionId"`
	ExpectedDefinitionVersion  uint64                `json:"expectedDefinitionVersion"`
	CommandID                  CommandID             `json:"commandId"`
	Operations                 []GraphPatchOperation `json:"operations"`
}

type RestartPoint struct {
	Metadata             RecordMetadata       `json:"metadata"`
	ID                   RestartPointID       `json:"id"`
	Kind                 RestartPointKind     `json:"kind"`
	WorkflowRunID        WorkflowRunID        `json:"workflowRunId"`
	WorkflowDefinitionID WorkflowDefinitionID `json:"workflowDefinitionId"`
	DefinitionVersion    uint64               `json:"definitionVersion"`
	EventCursor          EventCursor          `json:"eventCursor"`
	SnapshotID           SnapshotID           `json:"snapshotId"`
	NodeRunID            *NodeRunID           `json:"nodeRunId,omitempty"`
	AdmissionIDs         []AdmissionID        `json:"admissionIds"`
	CheckpointIDs        []CheckpointID       `json:"checkpointIds"`
}

type RunFork struct {
	Metadata                   RecordMetadata       `json:"metadata"`
	ID                         RunForkID            `json:"id"`
	ParentWorkflowRunID        WorkflowRunID        `json:"parentWorkflowRunId"`
	ChildWorkflowRunID         WorkflowRunID        `json:"childWorkflowRunId"`
	RestartPointID             RestartPointID       `json:"restartPointId"`
	TargetWorkflowDefinitionID WorkflowDefinitionID `json:"targetWorkflowDefinitionId"`
	TargetDefinitionVersion    uint64               `json:"targetDefinitionVersion"`
	ExpectedParentVersion      ResourceVersion      `json:"expectedParentVersion"`
	StartingSnapshotID         SnapshotID           `json:"startingSnapshotId"`
	CommandID                  CommandID            `json:"commandId"`
	Principal                  string               `json:"principal"`
}

type CommandRecord struct {
	Metadata        RecordMetadata   `json:"metadata"`
	ID              CommandID        `json:"id"`
	IdempotencyKey  string           `json:"idempotencyKey"`
	Principal       string           `json:"principal"`
	Kind            string           `json:"kind"`
	ExpectedVersion *ResourceVersion `json:"expectedVersion,omitempty"`
	State           CommandState     `json:"state"`
	Payload         json.RawMessage  `json:"payload"`
	Result          json.RawMessage  `json:"result,omitempty"`
}

type Workspace struct {
	Metadata RecordMetadata  `json:"metadata"`
	ID       WorkspaceID     `json:"id"`
	Adapter  PluginID        `json:"adapterPluginId"`
	Handle   AdapterHandleID `json:"adapterHandleId"`
}

type Snapshot struct {
	Metadata    RecordMetadata `json:"metadata"`
	ID          SnapshotID     `json:"id"`
	WorkspaceID WorkspaceID    `json:"workspaceId"`
	TreeDigest  string         `json:"treeDigest"`
	ByteSize    uint64         `json:"byteSize"`
}

type Session struct {
	Metadata            RecordMetadata   `json:"metadata"`
	ID                  SessionID        `json:"id"`
	WorkflowRunID       WorkflowRunID    `json:"workflowRunId"`
	NodeRunID           NodeRunID        `json:"nodeRunId"`
	RuntimePluginID     PluginID         `json:"runtimePluginId"`
	RuntimeAdapterID    string           `json:"runtimeAdapterId"`
	RuntimeHandle       *AdapterHandleID `json:"runtimeHandleId,omitempty"`
	HandleFormatVersion uint32           `json:"handleFormatVersion"`
	TraceSessionID      string           `json:"traceSessionId,omitempty"`
	State               SessionState     `json:"state"`
	Capabilities        []string         `json:"capabilities"`
	JobPolicy           JobPolicy        `json:"jobPolicy"`
	CheckpointID        *CheckpointID    `json:"checkpointId,omitempty"`
	ActiveOperationID   *OperationID     `json:"activeOperationId,omitempty"`
	RuntimeEventCursor  uint64           `json:"runtimeEventCursor"`
}

type RuntimeEvent struct {
	Sequence          uint64          `json:"sequence"`
	Kind              string          `json:"kind"`
	ProviderEventType string          `json:"providerEventType"`
	ProviderID        string          `json:"providerId,omitempty"`
	ParentProviderID  string          `json:"parentProviderId,omitempty"`
	OccurredAt        time.Time       `json:"occurredAt"`
	Data              json.RawMessage `json:"data"`
}

type RuntimeEventBatch struct {
	State                string         `json:"state"`
	Cursor               uint64         `json:"cursor"`
	FirstAvailableCursor uint64         `json:"firstAvailableCursor"`
	Events               []RuntimeEvent `json:"events"`
	More                 bool           `json:"more"`
}

type Intervention struct {
	Metadata    RecordMetadata    `json:"metadata"`
	ID          InterventionID    `json:"id"`
	SessionID   SessionID         `json:"sessionId"`
	Kind        InterventionKind  `json:"kind"`
	State       InterventionState `json:"state"`
	Payload     json.RawMessage   `json:"payload"`
	Source      string            `json:"source"`
	Authority   Authority         `json:"authority"`
	Deadline    *time.Time        `json:"deadline,omitempty"`
	RecordedAt  time.Time         `json:"recordedAt"`
	ForwardedAt *time.Time        `json:"forwardedAt,omitempty"`
	CompletedAt *time.Time        `json:"completedAt,omitempty"`
}

type Checkpoint struct {
	Metadata            RecordMetadata    `json:"metadata"`
	ID                  CheckpointID      `json:"id"`
	SessionID           SessionID         `json:"sessionId"`
	WorkflowVersion     uint64            `json:"workflowVersion"`
	EventCursor         EventCursor       `json:"eventCursor"`
	OpenNodeRunIDs      []NodeRunID       `json:"openNodeRunIds"`
	ActiveHandleIDs     []AdapterHandleID `json:"activeHandleIds"`
	InterventionIDs     []InterventionID  `json:"interventionIds"`
	UnresolvedDecisions []string          `json:"unresolvedDecisions"`
	State               json.RawMessage   `json:"state"`
}

type Activity struct {
	Metadata         RecordMetadata    `json:"metadata"`
	ID               ActivityID        `json:"id"`
	Kind             ActivityKind      `json:"kind"`
	ParentID         *ActivityID       `json:"parentId,omitempty"`
	WorkflowRunID    WorkflowRunID     `json:"workflowRunId"`
	NodeRunID        *NodeRunID        `json:"nodeRunId,omitempty"`
	SessionID        *SessionID        `json:"sessionId,omitempty"`
	PromptArtifactID *PromptArtifactID `json:"promptArtifactId,omitempty"`
	Provider         string            `json:"provider,omitempty"`
	ProviderID       string            `json:"providerId,omitempty"`
	Basis            ProvenanceBasis   `json:"basis"`
	Authority        Authority         `json:"authority"`
	Source           string            `json:"source,omitempty"`
	SourceID         string            `json:"sourceId,omitempty"`
	StartedAt        time.Time         `json:"startedAt"`
	EndedAt          *time.Time        `json:"endedAt,omitempty"`
}

type PromptArtifact struct {
	Metadata       RecordMetadata   `json:"metadata"`
	ID             PromptArtifactID `json:"id"`
	Digest         string           `json:"digest"`
	TemplateDigest string           `json:"templateDigest,omitempty"`
	MediaType      string           `json:"mediaType"`
	ByteSize       uint64           `json:"byteSize"`
	SecretNames    []string         `json:"secretNames"`
	Content        []byte           `json:"content"`
}

type CommitObservation struct {
	Metadata         RecordMetadata      `json:"metadata"`
	ID               CommitObservationID `json:"id"`
	WorkspaceID      WorkspaceID         `json:"workspaceId"`
	Repository       string              `json:"repository"`
	Commit           string              `json:"commit"`
	Parents          []string            `json:"parents"`
	TreeDigest       string              `json:"treeDigest"`
	BeforeSnapshotID SnapshotID          `json:"beforeSnapshotId"`
	AfterSnapshotID  SnapshotID          `json:"afterSnapshotId"`
	Basis            ProvenanceBasis     `json:"basis"`
	Authority        Authority           `json:"authority"`
	Source           string              `json:"source,omitempty"`
	SourceID         string              `json:"sourceId,omitempty"`
	ObservedAt       time.Time           `json:"observedAt"`
}

type ProvenanceRelation struct {
	Metadata   RecordMetadata         `json:"metadata"`
	ID         ProvenanceRelationID   `json:"id"`
	Kind       ProvenanceRelationKind `json:"kind"`
	From       ResourceReference      `json:"from"`
	To         ResourceReference      `json:"to"`
	Basis      ProvenanceBasis        `json:"basis"`
	Authority  Authority              `json:"authority"`
	Source     string                 `json:"source,omitempty"`
	SourceID   string                 `json:"sourceId,omitempty"`
	ObservedAt time.Time              `json:"observedAt"`
}

type AnnotationAnchor struct {
	File string `json:"file"`
	Line uint64 `json:"line"`
	Text string `json:"text"`
}

type Annotation struct {
	Metadata  RecordMetadata      `json:"metadata"`
	ID        AnnotationID        `json:"id"`
	Summary   string              `json:"summary"`
	Rationale string              `json:"rationale,omitempty"`
	Author    string              `json:"author"`
	Origin    AnnotationOrigin    `json:"origin"`
	State     AnnotationState     `json:"state"`
	Anchor    *AnnotationAnchor   `json:"anchor,omitempty"`
	Targets   []ResourceReference `json:"targets"`
	Authority Authority           `json:"authority"`
	Source    string              `json:"source,omitempty"`
	SourceID  string              `json:"sourceId,omitempty"`
}

type AnnotationReply struct {
	Metadata     RecordMetadata    `json:"metadata"`
	ID           AnnotationReplyID `json:"id"`
	AnnotationID AnnotationID      `json:"annotationId"`
	Summary      string            `json:"summary"`
	Rationale    string            `json:"rationale,omitempty"`
	Author       string            `json:"author"`
	Authority    Authority         `json:"authority"`
	Source       string            `json:"source,omitempty"`
	SourceID     string            `json:"sourceId,omitempty"`
}

type TaskResult struct {
	Metadata     RecordMetadata  `json:"metadata"`
	ID           TaskResultID    `json:"id"`
	NodeRunID    NodeRunID       `json:"nodeRunId"`
	SchemaDigest string          `json:"schemaDigest"`
	Value        json.RawMessage `json:"value"`
	ArtifactIDs  []ArtifactID    `json:"artifactIds"`
}

type TaskRecord struct {
	Metadata     RecordMetadata `json:"metadata"`
	ID           TaskRecordID   `json:"id"`
	TaskResultID TaskResultID   `json:"taskResultId"`
	SnapshotID   SnapshotID     `json:"snapshotId"`
	InputDigest  string         `json:"inputDigest"`
}

type Admission struct {
	Metadata      RecordMetadata `json:"metadata"`
	ID            AdmissionID    `json:"id"`
	TaskRecordID  TaskRecordID   `json:"taskRecordId"`
	State         AdmissionState `json:"state"`
	BoundDigest   string         `json:"boundDigest"`
	ValidationIDs []ValidationID `json:"validationIds"`
}

type Artifact struct {
	Metadata     RecordMetadata `json:"metadata"`
	ID           ArtifactID     `json:"id"`
	SnapshotID   SnapshotID     `json:"snapshotId"`
	Path         string         `json:"path"`
	Digest       string         `json:"digest"`
	ByteSize     uint64         `json:"byteSize"`
	ChangedPaths []string       `json:"changedPaths"`
}

type Validation struct {
	Metadata         RecordMetadata  `json:"metadata"`
	ID               ValidationID    `json:"id"`
	TaskRecordID     TaskRecordID    `json:"taskRecordId"`
	Key              string          `json:"key"`
	ArtifactID       *ArtifactID     `json:"artifactId,omitempty"`
	State            ValidationState `json:"state"`
	Authority        Authority       `json:"authority"`
	InputDigest      string          `json:"inputDigest"`
	DefinitionDigest string          `json:"definitionDigest"`
	EnvironmentID    string          `json:"environmentId"`
	ExitCode         *int            `json:"exitCode,omitempty"`
	LogArtifactID    *ArtifactID     `json:"logArtifactId,omitempty"`
}

type Plugin struct {
	Metadata        RecordMetadata    `json:"metadata"`
	ID              PluginID          `json:"id"`
	ProtocolVersion uint32            `json:"protocolVersion"`
	Ports           []AdapterPort     `json:"ports"`
	Capabilities    []string          `json:"capabilities"`
	SchemaDigests   map[string]string `json:"schemaDigests"`
}

type AdapterHandle struct {
	Metadata      RecordMetadata    `json:"metadata"`
	ID            AdapterHandleID   `json:"id"`
	Owner         ResourceReference `json:"owner"`
	PluginID      PluginID          `json:"pluginId"`
	Port          AdapterPort       `json:"port"`
	AdapterID     string            `json:"adapterId"`
	FormatVersion uint32            `json:"formatVersion"`
	OpaqueValue   json.RawMessage   `json:"opaqueValue"`
}

type Operation struct {
	Metadata           RecordMetadata    `json:"metadata"`
	ID                 OperationID       `json:"id"`
	PluginID           PluginID          `json:"pluginId,omitempty"`
	CommandID          CommandID         `json:"commandId"`
	NodeRunID          NodeRunID         `json:"nodeRunId"`
	Kind               string            `json:"kind"`
	TargetSchemaDigest string            `json:"targetSchemaDigest"`
	TargetDigest       string            `json:"targetDigest"`
	InputDigest        string            `json:"inputDigest"`
	AuthorityID        EffectAuthorityID `json:"authorityId"`
	State              OperationState    `json:"state"`
	Retryable          bool              `json:"retryable"`
	Idempotent         bool              `json:"idempotent"`
	Reconciliation     string            `json:"reconciliation"`
	Attempt            uint32            `json:"attempt"`
	Request            json.RawMessage   `json:"request"`
	Result             json.RawMessage   `json:"result,omitempty"`
	DispatchedAt       *time.Time        `json:"dispatchedAt,omitempty"`
	CompletedAt        *time.Time        `json:"completedAt,omitempty"`
}

type EffectAuthority struct {
	Metadata      RecordMetadata    `json:"metadata"`
	ID            EffectAuthorityID `json:"id"`
	CommandID     CommandID         `json:"commandId"`
	NodeRunID     NodeRunID         `json:"nodeRunId"`
	OperationKind string            `json:"operationKind"`
	TargetDigest  string            `json:"targetDigest"`
	InputDigest   string            `json:"inputDigest"`
	Principal     string            `json:"principal"`
	ExpiresAt     time.Time         `json:"expiresAt"`
	ConsumedBy    *OperationID      `json:"consumedBy,omitempty"`
	ConsumedAt    *time.Time        `json:"consumedAt,omitempty"`
}

type EffectReconciliation struct {
	Metadata             RecordMetadata         `json:"metadata"`
	ID                   EffectReconciliationID `json:"id"`
	OperationID          OperationID            `json:"operationId"`
	Resolution           string                 `json:"resolution"`
	ObservedTargetDigest string                 `json:"observedTargetDigest"`
	Principal            string                 `json:"principal"`
	ObservedAt           time.Time              `json:"observedAt"`
}
