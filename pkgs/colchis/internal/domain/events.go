package domain

import (
	"encoding/json"
	"time"
)

const CurrentEventSchemaVersion SchemaVersion = 1

type EventCursor uint64

type EventEnvelope struct {
	SchemaVersion SchemaVersion     `json:"schemaVersion"`
	Cursor        EventCursor       `json:"cursor"`
	OccurredAt    time.Time         `json:"occurredAt"`
	Aggregate     ResourceReference `json:"aggregate"`
	Type          string            `json:"type"`
	Payload       json.RawMessage   `json:"payload"`
	Metadata      map[string]string `json:"metadata,omitempty"`
}

func (event EventEnvelope) Validate() error {
	if event.Cursor == 0 {
		return &Error{Code: ErrorCodeInvalidArgument, Resource: "event", Message: "cursor is zero"}
	}
	return event.ValidateForAppend()
}

func (event EventEnvelope) ValidateForAppend() error {
	if event.SchemaVersion != CurrentEventSchemaVersion {
		return &Error{Code: ErrorCodeUnsupportedVersion, Resource: "event", Message: "schema version is unsupported"}
	}
	if event.OccurredAt.IsZero() {
		return &Error{Code: ErrorCodeInvalidArgument, Resource: "event", Message: "occurredAt is zero"}
	}
	if err := event.Aggregate.Validate(); err != nil {
		return err
	}
	if err := validateIdentifier("event type", event.Type); err != nil {
		return err
	}
	if !json.Valid(event.Payload) {
		return &Error{Code: ErrorCodeInvalidArgument, Resource: "event", Message: "payload is not valid JSON"}
	}
	return nil
}
