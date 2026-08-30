package domain

import "strings"

type WorkflowRunState string

const (
	WorkflowRunStatePending   WorkflowRunState = "pending"
	WorkflowRunStateRunning   WorkflowRunState = "running"
	WorkflowRunStateWaiting   WorkflowRunState = "waiting"
	WorkflowRunStateSucceeded WorkflowRunState = "succeeded"
	WorkflowRunStateFailed    WorkflowRunState = "failed"
	WorkflowRunStateCancelled WorkflowRunState = "cancelled"
	WorkflowRunStateCapped    WorkflowRunState = "capped"
)

func (state WorkflowRunState) Valid() bool {
	switch state {
	case WorkflowRunStatePending,
		WorkflowRunStateRunning,
		WorkflowRunStateWaiting,
		WorkflowRunStateSucceeded,
		WorkflowRunStateFailed,
		WorkflowRunStateCancelled,
		WorkflowRunStateCapped:
		return true
	default:
		return false
	}
}

type NodeRunState string

const (
	NodeRunStatePending   NodeRunState = "pending"
	NodeRunStateReady     NodeRunState = "ready"
	NodeRunStateRunning   NodeRunState = "running"
	NodeRunStateWaiting   NodeRunState = "waiting"
	NodeRunStateSucceeded NodeRunState = "succeeded"
	NodeRunStateFailed    NodeRunState = "failed"
	NodeRunStateCancelled NodeRunState = "cancelled"
	NodeRunStateCapped    NodeRunState = "capped"
)

func (state NodeRunState) Valid() bool {
	switch state {
	case NodeRunStatePending,
		NodeRunStateReady,
		NodeRunStateRunning,
		NodeRunStateWaiting,
		NodeRunStateSucceeded,
		NodeRunStateFailed,
		NodeRunStateCancelled,
		NodeRunStateCapped:
		return true
	default:
		return false
	}
}

type CommandState string

const (
	CommandStateAccepted      CommandState = "accepted"
	CommandStateRunning       CommandState = "running"
	CommandStateIndeterminate CommandState = "indeterminate"
	CommandStateSucceeded     CommandState = "succeeded"
	CommandStateFailed        CommandState = "failed"
	CommandStateRejected      CommandState = "rejected"
	CommandStateConflict      CommandState = "conflict"
)

func (state CommandState) Valid() bool {
	switch state {
	case CommandStateAccepted,
		CommandStateRunning,
		CommandStateIndeterminate,
		CommandStateSucceeded,
		CommandStateFailed,
		CommandStateRejected,
		CommandStateConflict:
		return true
	default:
		return false
	}
}

type SessionState string

const (
	SessionStateStarting  SessionState = "starting"
	SessionStateRunning   SessionState = "running"
	SessionStateWaiting   SessionState = "waiting"
	SessionStateCompleted SessionState = "completed"
	SessionStateFailed    SessionState = "failed"
	SessionStateCancelled SessionState = "cancelled"
	SessionStateOrphaned  SessionState = "orphaned"
)

func (state SessionState) Valid() bool {
	switch state {
	case SessionStateStarting,
		SessionStateRunning,
		SessionStateWaiting,
		SessionStateCompleted,
		SessionStateFailed,
		SessionStateCancelled,
		SessionStateOrphaned:
		return true
	default:
		return false
	}
}

type SessionReconciliationState string

const (
	SessionReconciliationAdopted    SessionReconciliationState = "adopted"
	SessionReconciliationCompleted  SessionReconciliationState = "completed"
	SessionReconciliationOrphaned   SessionReconciliationState = "orphaned"
	SessionReconciliationRehydrated SessionReconciliationState = "rehydrated"
)

func (state SessionReconciliationState) Valid() bool {
	switch state {
	case SessionReconciliationAdopted,
		SessionReconciliationCompleted,
		SessionReconciliationOrphaned,
		SessionReconciliationRehydrated:
		return true
	default:
		return false
	}
}

type InterventionKind string

const (
	InterventionKindMessage   InterventionKind = "message"
	InterventionKindInterrupt InterventionKind = "interrupt"
	InterventionKindAttach    InterventionKind = "attach"
	InterventionKindDetach    InterventionKind = "detach"
	InterventionKindPolicy    InterventionKind = "policy"
	InterventionKindPause     InterventionKind = "pause"
	InterventionKindResume    InterventionKind = "resume"
	InterventionKindRetry     InterventionKind = "retry"
	InterventionKindCancel    InterventionKind = "cancel"
	InterventionKindBranch    InterventionKind = "branch"
)

func (kind InterventionKind) Valid() bool {
	switch kind {
	case InterventionKindMessage, InterventionKindInterrupt, InterventionKindAttach, InterventionKindDetach,
		InterventionKindPolicy, InterventionKindPause, InterventionKindResume, InterventionKindRetry,
		InterventionKindCancel, InterventionKindBranch:
		return true
	default:
		return false
	}
}

type PauseCauseKind string

const (
	PauseCauseOwnerInput            PauseCauseKind = "owner_input"
	PauseCauseCapabilityUnavailable PauseCauseKind = "capability_unavailable"
	PauseCauseContractIncomplete    PauseCauseKind = "contract_incomplete"
	PauseCauseLimitReached          PauseCauseKind = "limit_reached"
)

func (kind PauseCauseKind) Valid() bool {
	switch kind {
	case PauseCauseOwnerInput, PauseCauseCapabilityUnavailable,
		PauseCauseContractIncomplete, PauseCauseLimitReached:
		return true
	default:
		return false
	}
}

type ApprovalPolicy string

const (
	ApprovalPolicyAlways    ApprovalPolicy = "always"
	ApprovalPolicyOnRequest ApprovalPolicy = "on-request"
	ApprovalPolicyNever     ApprovalPolicy = "never"
)

func (policy ApprovalPolicy) Valid() bool {
	switch policy {
	case ApprovalPolicyAlways, ApprovalPolicyOnRequest, ApprovalPolicyNever:
		return true
	default:
		return false
	}
}

type FilesystemPolicy string

const (
	FilesystemPolicyReadOnly         FilesystemPolicy = "read-only"
	FilesystemPolicyWorkspaceWrite   FilesystemPolicy = "workspace-write"
	FilesystemPolicyDangerFullAccess FilesystemPolicy = "danger-full-access"
)

func (policy FilesystemPolicy) Valid() bool {
	switch policy {
	case FilesystemPolicyReadOnly, FilesystemPolicyWorkspaceWrite, FilesystemPolicyDangerFullAccess:
		return true
	default:
		return false
	}
}

type NetworkPolicy string

const (
	NetworkPolicyDeny  NetworkPolicy = "deny"
	NetworkPolicyAllow NetworkPolicy = "allow"
)

func (policy NetworkPolicy) Valid() bool {
	switch policy {
	case NetworkPolicyDeny, NetworkPolicyAllow:
		return true
	default:
		return false
	}
}

type InterventionState string

const (
	InterventionStateRecorded  InterventionState = "recorded"
	InterventionStateQueued    InterventionState = "queued"
	InterventionStateForwarded InterventionState = "forwarded"
	InterventionStateCompleted InterventionState = "completed"
	InterventionStateFailed    InterventionState = "failed"
)

func (state InterventionState) Valid() bool {
	switch state {
	case InterventionStateRecorded,
		InterventionStateQueued,
		InterventionStateForwarded,
		InterventionStateCompleted,
		InterventionStateFailed:
		return true
	default:
		return false
	}
}

type OperationState string

const (
	OperationStatePending       OperationState = "pending"
	OperationStateRunning       OperationState = "running"
	OperationStateSucceeded     OperationState = "succeeded"
	OperationStateFailed        OperationState = "failed"
	OperationStateCancelled     OperationState = "cancelled"
	OperationStateIndeterminate OperationState = "indeterminate"
)

func (state OperationState) Valid() bool {
	switch state {
	case OperationStatePending,
		OperationStateRunning,
		OperationStateSucceeded,
		OperationStateFailed,
		OperationStateCancelled,
		OperationStateIndeterminate:
		return true
	default:
		return false
	}
}

type AdmissionState string

const (
	AdmissionStatePending  AdmissionState = "pending"
	AdmissionStateAdmitted AdmissionState = "admitted"
	AdmissionStateRejected AdmissionState = "rejected"
	AdmissionStateStale    AdmissionState = "stale"
)

func (state AdmissionState) Valid() bool {
	switch state {
	case AdmissionStatePending,
		AdmissionStateAdmitted,
		AdmissionStateRejected,
		AdmissionStateStale:
		return true
	default:
		return false
	}
}

type ValidationState string

const (
	ValidationStatePassed  ValidationState = "passed"
	ValidationStateFailed  ValidationState = "failed"
	ValidationStateError   ValidationState = "error"
	ValidationStateSkipped ValidationState = "skipped"
	ValidationStateStale   ValidationState = "stale"
)

func (state ValidationState) Valid() bool {
	switch state {
	case ValidationStatePassed,
		ValidationStateFailed,
		ValidationStateError,
		ValidationStateSkipped,
		ValidationStateStale:
		return true
	default:
		return false
	}
}

type Authority string

const (
	AuthorityRepository Authority = "repository"
	AuthorityHarness    Authority = "harness"
	AuthorityOwner      Authority = "owner"
	AuthorityAdvisory   Authority = "advisory"
)

func (authority Authority) Valid() bool {
	switch authority {
	case AuthorityRepository, AuthorityHarness, AuthorityOwner, AuthorityAdvisory:
		return true
	default:
		return false
	}
}

type AdapterPort string

const (
	AdapterPortPlanning     AdapterPort = "planning"
	AdapterPortWorkspace    AdapterPort = "workspace"
	AdapterPortEnvironment  AdapterPort = "environment"
	AdapterPortAgentRuntime AdapterPort = "agent-runtime"
	AdapterPortAttachment   AdapterPort = "attachment"
	AdapterPortActivity     AdapterPort = "activity"
	AdapterPortAnnotation   AdapterPort = "annotation"
	AdapterPortEffect       AdapterPort = "effect"
)

func (port AdapterPort) Valid() bool {
	switch port {
	case AdapterPortPlanning,
		AdapterPortWorkspace,
		AdapterPortEnvironment,
		AdapterPortAgentRuntime,
		AdapterPortAttachment,
		AdapterPortActivity,
		AdapterPortAnnotation,
		AdapterPortEffect:
		return true
	default:
		return false
	}
}

func ParseAdapterSelector(selector string) (PluginID, string) {
	pluginID, adapterID, qualified := strings.Cut(selector, "::")
	if !qualified || pluginID == "" || adapterID == "" || strings.Contains(adapterID, "::") {
		return "", selector
	}
	return PluginID(pluginID), adapterID
}

type GraphPatchOperationKind string

const (
	GraphPatchOperationInsertBetween GraphPatchOperationKind = "insert_between"
	GraphPatchOperationInsertAfter   GraphPatchOperationKind = "insert_after"
	GraphPatchOperationReplace       GraphPatchOperationKind = "replace"
	GraphPatchOperationRemove        GraphPatchOperationKind = "remove"
	GraphPatchOperationAddBranch     GraphPatchOperationKind = "add_branch"
)

func (kind GraphPatchOperationKind) Valid() bool {
	switch kind {
	case GraphPatchOperationInsertBetween,
		GraphPatchOperationInsertAfter,
		GraphPatchOperationReplace,
		GraphPatchOperationRemove,
		GraphPatchOperationAddBranch:
		return true
	default:
		return false
	}
}

type RestartPointKind string

const (
	RestartPointRunAdmission            RestartPointKind = "run_admission"
	RestartPointNodeAdmission           RestartPointKind = "node_admission"
	RestartPointOrchestrationCheckpoint RestartPointKind = "orchestration_checkpoint"
)

func (kind RestartPointKind) Valid() bool {
	switch kind {
	case RestartPointRunAdmission,
		RestartPointNodeAdmission,
		RestartPointOrchestrationCheckpoint:
		return true
	default:
		return false
	}
}

type ActivityKind string

const (
	ActivityKindWorkflowRun ActivityKind = "workflow_run"
	ActivityKindNodeAttempt ActivityKind = "node_attempt"
	ActivityKindSession     ActivityKind = "session"
	ActivityKindTurn        ActivityKind = "turn"
	ActivityKindModelCall   ActivityKind = "model_call"
	ActivityKindToolCall    ActivityKind = "tool_call"
)

func (kind ActivityKind) Valid() bool {
	switch kind {
	case ActivityKindWorkflowRun,
		ActivityKindNodeAttempt,
		ActivityKindSession,
		ActivityKindTurn,
		ActivityKindModelCall,
		ActivityKindToolCall:
		return true
	default:
		return false
	}
}

type ProvenanceBasis string

const (
	ProvenanceBasisBrokerObserved  ProvenanceBasis = "broker_observed"
	ProvenanceBasisAdapterReported ProvenanceBasis = "adapter_reported"
	ProvenanceBasisDerived         ProvenanceBasis = "derived"
)

func (basis ProvenanceBasis) Valid() bool {
	switch basis {
	case ProvenanceBasisBrokerObserved,
		ProvenanceBasisAdapterReported,
		ProvenanceBasisDerived:
		return true
	default:
		return false
	}
}

type ProvenanceRelationKind string

const (
	ProvenanceRelationContains       ProvenanceRelationKind = "contains"
	ProvenanceRelationPrompted       ProvenanceRelationKind = "prompted"
	ProvenanceRelationInvoked        ProvenanceRelationKind = "invoked"
	ProvenanceRelationProduced       ProvenanceRelationKind = "produced"
	ProvenanceRelationModified       ProvenanceRelationKind = "modified"
	ProvenanceRelationObservedDuring ProvenanceRelationKind = "observed_during"
	ProvenanceRelationDerivedFrom    ProvenanceRelationKind = "derived_from"
	ProvenanceRelationAnnotates      ProvenanceRelationKind = "annotates"
	ProvenanceRelationRepliesTo      ProvenanceRelationKind = "replies_to"
	ProvenanceRelationReused         ProvenanceRelationKind = "reused"
)

func (kind ProvenanceRelationKind) Valid() bool {
	switch kind {
	case ProvenanceRelationContains,
		ProvenanceRelationPrompted,
		ProvenanceRelationInvoked,
		ProvenanceRelationProduced,
		ProvenanceRelationModified,
		ProvenanceRelationObservedDuring,
		ProvenanceRelationDerivedFrom,
		ProvenanceRelationAnnotates,
		ProvenanceRelationRepliesTo,
		ProvenanceRelationReused:
		return true
	default:
		return false
	}
}

type AnnotationOrigin string

const (
	AnnotationOriginAgent AnnotationOrigin = "agent"
	AnnotationOriginUser  AnnotationOrigin = "user"
)

func (origin AnnotationOrigin) Valid() bool {
	return origin == AnnotationOriginAgent || origin == AnnotationOriginUser
}

type AnnotationState string

const (
	AnnotationStateOpen     AnnotationState = "open"
	AnnotationStateAnswered AnnotationState = "answered"
)

func (state AnnotationState) Valid() bool {
	return state == AnnotationStateOpen || state == AnnotationStateAnswered
}
