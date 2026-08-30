package domain

import "fmt"

const maxIdentifierLength = 128

type WorkflowDefinitionID string
type WorkflowRunID string
type NodeRunID string
type GraphPatchID string
type RestartPointID string
type RunForkID string
type CommandID string
type WorkspaceID string
type SnapshotID string
type SessionID string
type InterventionID string
type CheckpointID string
type ActivityID string
type PromptArtifactID string
type CommitObservationID string
type ProvenanceRelationID string
type AnnotationID string
type AnnotationReplyID string
type TaskResultID string
type TaskRecordID string
type AdmissionID string
type AdmissionReuseID string
type ArtifactID string
type ValidationID string
type PluginID string
type AdapterHandleID string
type OperationID string
type EffectAuthorityID string
type EffectReconciliationID string
type NodeKey string
type EdgeKey string
type StageTemplateKey string

func (id WorkflowDefinitionID) Validate() error {
	return validateIdentifier("workflow definition", string(id))
}

func (id WorkflowRunID) Validate() error {
	return validateIdentifier("workflow run", string(id))
}

func (id NodeRunID) Validate() error {
	return validateIdentifier("node run", string(id))
}

func (id GraphPatchID) Validate() error {
	return validateIdentifier("graph patch", string(id))
}

func (id RestartPointID) Validate() error {
	return validateIdentifier("restart point", string(id))
}

func (id RunForkID) Validate() error {
	return validateIdentifier("run fork", string(id))
}

func (id CommandID) Validate() error {
	return validateIdentifier("command", string(id))
}

func (id WorkspaceID) Validate() error {
	return validateIdentifier("workspace", string(id))
}

func (id SnapshotID) Validate() error {
	return validateIdentifier("snapshot", string(id))
}

func (id SessionID) Validate() error {
	return validateIdentifier("session", string(id))
}

func (id InterventionID) Validate() error {
	return validateIdentifier("intervention", string(id))
}

func (id CheckpointID) Validate() error {
	return validateIdentifier("checkpoint", string(id))
}

func (id ActivityID) Validate() error {
	return validateIdentifier("activity", string(id))
}

func (id PromptArtifactID) Validate() error {
	return validateIdentifier("prompt artifact", string(id))
}

func (id CommitObservationID) Validate() error {
	return validateIdentifier("commit observation", string(id))
}

func (id ProvenanceRelationID) Validate() error {
	return validateIdentifier("provenance relation", string(id))
}

func (id AnnotationID) Validate() error {
	return validateIdentifier("annotation", string(id))
}

func (id AnnotationReplyID) Validate() error {
	return validateIdentifier("annotation reply", string(id))
}

func (id TaskResultID) Validate() error {
	return validateIdentifier("task result", string(id))
}

func (id TaskRecordID) Validate() error {
	return validateIdentifier("task record", string(id))
}

func (id AdmissionID) Validate() error {
	return validateIdentifier("admission", string(id))
}

func (id AdmissionReuseID) Validate() error {
	return validateIdentifier("admission reuse", string(id))
}

func (id ArtifactID) Validate() error {
	return validateIdentifier("artifact", string(id))
}

func (id ValidationID) Validate() error {
	return validateIdentifier("validation", string(id))
}

func (id PluginID) Validate() error {
	return validateIdentifier("plugin", string(id))
}

func (id AdapterHandleID) Validate() error {
	return validateIdentifier("adapter handle", string(id))
}

func (id OperationID) Validate() error {
	return validateIdentifier("operation", string(id))
}

func (id EffectAuthorityID) Validate() error {
	return validateIdentifier("effect authority", string(id))
}

func (id EffectReconciliationID) Validate() error {
	return validateIdentifier("effect reconciliation", string(id))
}

func (key NodeKey) Validate() error {
	return validateIdentifier("node key", string(key))
}

func (key EdgeKey) Validate() error {
	return validateIdentifier("edge key", string(key))
}

func (key StageTemplateKey) Validate() error {
	return validateIdentifier("stage template key", string(key))
}

func validateIdentifier(kind string, value string) error {
	if value == "" {
		return &Error{Code: ErrorCodeInvalidArgument, Resource: kind, Message: "identifier is empty"}
	}
	if len(value) > maxIdentifierLength {
		return &Error{
			Code:     ErrorCodeInvalidArgument,
			Resource: kind,
			Message:  fmt.Sprintf("identifier exceeds %d bytes", maxIdentifierLength),
		}
	}
	hasAlphanumeric := false
	for index, character := range value {
		if isASCIILetter(character) || character >= '0' && character <= '9' {
			hasAlphanumeric = true
		}
		if isIdentifierCharacter(character) {
			continue
		}
		return &Error{
			Code:     ErrorCodeInvalidArgument,
			Resource: kind,
			Message:  fmt.Sprintf("identifier contains invalid character at byte %d", index),
		}
	}
	if !hasAlphanumeric {
		return &Error{Code: ErrorCodeInvalidArgument, Resource: kind, Message: "identifier has no alphanumeric character"}
	}
	return nil
}

func isIdentifierCharacter(character rune) bool {
	return isASCIILetter(character) ||
		character >= '0' && character <= '9' ||
		character == '-' || character == '_' || character == '.' || character == ':'
}

func isASCIILetter(character rune) bool {
	return character >= 'a' && character <= 'z' || character >= 'A' && character <= 'Z'
}
