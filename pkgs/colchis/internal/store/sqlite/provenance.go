package sqlite

import (
	"context"
	"encoding/json"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

const (
	commitObservationRecordKind  = "commit-observation"
	provenanceRelationRecordKind = "provenance-relation"
	annotationRecordKind         = "annotation"
	annotationReplyRecordKind    = "annotation-reply"
)

type AnnotationWithReplies struct {
	Annotation domain.Annotation
	Replies    []domain.AnnotationReply
}

type ProvenanceInspection struct {
	CommitObservations []domain.CommitObservation  `json:"commitObservations"`
	Relations          []domain.ProvenanceRelation `json:"relations"`
	AdmissionReuses    []domain.AdmissionReuse     `json:"admissionReuses"`
	Activities         []domain.Activity           `json:"activities"`
	PromptArtifacts    []domain.PromptArtifact     `json:"promptArtifacts"`
}

func (store *Store) InspectProvenance(ctx context.Context) (ProvenanceInspection, error) {
	var inspection ProvenanceInspection
	err := store.Transaction(ctx, func(transaction *Tx) error {
		var err error
		inspection.CommitObservations, err = typedRecords[domain.CommitObservation](
			transaction, ctx, commitObservationRecordKind,
		)
		if err != nil {
			return err
		}
		inspection.Relations, err = typedRecords[domain.ProvenanceRelation](
			transaction, ctx, provenanceRelationRecordKind,
		)
		if err != nil {
			return err
		}
		inspection.AdmissionReuses, err = typedRecords[domain.AdmissionReuse](
			transaction, ctx, admissionReuseRecordKind,
		)
		if err != nil {
			return err
		}
		inspection.Activities, err = typedRecords[domain.Activity](transaction, ctx, activityRecordKind)
		if err != nil {
			return err
		}
		inspection.PromptArtifacts, err = typedRecords[domain.PromptArtifact](
			transaction, ctx, promptArtifactRecordKind,
		)
		return err
	})
	return inspection, err
}

func (store *Store) RecordCommitObservation(
	ctx context.Context,
	observation domain.CommitObservation,
) (domain.CommitObservation, error) {
	if err := validateCommitObservation(observation); err != nil {
		return domain.CommitObservation{}, err
	}
	var recorded domain.CommitObservation
	err := store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := typedRecord[domain.CommitObservation](
			transaction, ctx, commitObservationRecordKind, string(observation.ID),
		); err != nil {
			return err
		} else if found {
			return conflict("record commit observation", string(observation.ID), "commit observation already exists")
		}
		before, found, err := transaction.snapshot(ctx, observation.BeforeSnapshotID)
		if err != nil {
			return err
		}
		if !found {
			return notFound("record commit observation", string(observation.BeforeSnapshotID), "before snapshot does not exist")
		}
		after, found, err := transaction.snapshot(ctx, observation.AfterSnapshotID)
		if err != nil {
			return err
		}
		if !found {
			return notFound("record commit observation", string(observation.AfterSnapshotID), "after snapshot does not exist")
		}
		if before.WorkspaceID != observation.WorkspaceID || after.WorkspaceID != observation.WorkspaceID ||
			after.TreeDigest != observation.TreeDigest {
			return conflict("record commit observation", string(observation.ID), "snapshot evidence does not match commit observation")
		}
		recorded = observation
		recorded.Metadata = newRecordMetadata(time.Now().UTC())
		encoded, err := json.Marshal(recorded)
		if err != nil {
			return wrap("encode commit observation", string(recorded.ID), err)
		}
		if err := transaction.reserveRecordCapacity(ctx, encoded); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, commitObservationRecordKind, string(recorded.ID), recorded.Metadata, encoded,
		); err != nil {
			return err
		}
		return appendProvenanceEvent(
			transaction, ctx, recorded.Metadata.CreatedAt, commitObservationRecordKind,
			string(recorded.ID), "provenance.commit.observed", recorded.Authority,
		)
	})
	return recorded, err
}

func (store *Store) RecordProvenanceRelation(
	ctx context.Context,
	relation domain.ProvenanceRelation,
) (domain.ProvenanceRelation, error) {
	if err := validateProvenanceRelation(relation); err != nil {
		return domain.ProvenanceRelation{}, err
	}
	var recorded domain.ProvenanceRelation
	err := store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := typedRecord[domain.ProvenanceRelation](
			transaction, ctx, provenanceRelationRecordKind, string(relation.ID),
		); err != nil {
			return err
		} else if found {
			return conflict("record provenance", string(relation.ID), "provenance relation already exists")
		}
		for _, reference := range []domain.ResourceReference{relation.From, relation.To} {
			found, err := transaction.resourceExists(ctx, reference)
			if err != nil {
				return err
			}
			if !found {
				return notFound("record provenance", reference.Kind+":"+reference.ID, "provenance target does not exist")
			}
		}
		recorded = relation
		recorded.Metadata = newRecordMetadata(time.Now().UTC())
		encoded, err := json.Marshal(recorded)
		if err != nil {
			return wrap("encode provenance relation", string(recorded.ID), err)
		}
		if err := transaction.reserveRecordCapacity(ctx, encoded); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, provenanceRelationRecordKind, string(recorded.ID), recorded.Metadata, encoded,
		); err != nil {
			return err
		}
		return appendProvenanceEvent(
			transaction, ctx, recorded.Metadata.CreatedAt, provenanceRelationRecordKind,
			string(recorded.ID), "provenance.relation.recorded", recorded.Authority,
		)
	})
	return recorded, err
}

func (store *Store) CreateAnnotation(
	ctx context.Context,
	annotation domain.Annotation,
) (domain.Annotation, error) {
	if err := validateAnnotation(annotation); err != nil {
		return domain.Annotation{}, err
	}
	var recorded domain.Annotation
	err := store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := typedRecord[domain.Annotation](
			transaction, ctx, annotationRecordKind, string(annotation.ID),
		); err != nil {
			return err
		} else if found {
			return conflict("create annotation", string(annotation.ID), "annotation already exists")
		}
		if err := transaction.validateAnnotationTargets(ctx, annotation.Targets); err != nil {
			return err
		}
		recorded = annotation
		recorded.Metadata = newRecordMetadata(time.Now().UTC())
		recorded.State = domain.AnnotationStateOpen
		encoded, err := json.Marshal(recorded)
		if err != nil {
			return wrap("encode annotation", string(recorded.ID), err)
		}
		if err := transaction.reserveRecordCapacity(ctx, encoded); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, annotationRecordKind, string(recorded.ID), recorded.Metadata, encoded,
		); err != nil {
			return err
		}
		return appendProvenanceEvent(
			transaction, ctx, recorded.Metadata.CreatedAt, annotationRecordKind,
			string(recorded.ID), "annotation.created", recorded.Authority,
		)
	})
	return recorded, err
}

func (store *Store) AnswerAnnotation(
	ctx context.Context,
	expectedVersion domain.ResourceVersion,
	reply domain.AnnotationReply,
) (AnnotationWithReplies, error) {
	if err := validateAnnotationReply(expectedVersion, reply); err != nil {
		return AnnotationWithReplies{}, err
	}
	var result AnnotationWithReplies
	err := store.Transaction(ctx, func(transaction *Tx) error {
		annotation, found, err := typedRecord[domain.Annotation](
			transaction, ctx, annotationRecordKind, string(reply.AnnotationID),
		)
		if err != nil {
			return err
		}
		if !found {
			return notFound("answer annotation", string(reply.AnnotationID), "annotation does not exist")
		}
		if annotation.Metadata.ResourceVersion != expectedVersion || annotation.State != domain.AnnotationStateOpen {
			return conflict("answer annotation", string(annotation.ID), "annotation version or state changed")
		}
		if _, found, err := typedRecord[domain.AnnotationReply](
			transaction, ctx, annotationReplyRecordKind, string(reply.ID),
		); err != nil {
			return err
		} else if found {
			return conflict("answer annotation", string(reply.ID), "annotation reply already exists")
		}
		now := time.Now().UTC()
		recordedReply := reply
		recordedReply.Metadata = newRecordMetadata(now)
		annotation.State = domain.AnnotationStateAnswered
		annotation.Metadata.ResourceVersion++
		annotation.Metadata.UpdatedAt = now
		replyPayload, err := json.Marshal(recordedReply)
		if err != nil {
			return wrap("encode annotation reply", string(reply.ID), err)
		}
		annotationPayload, err := json.Marshal(annotation)
		if err != nil {
			return wrap("encode answered annotation", string(annotation.ID), err)
		}
		if err := transaction.reserveRecordBytes(ctx, uint64(len(replyPayload)+len(annotationPayload)), 2); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, annotationReplyRecordKind, string(reply.ID), recordedReply.Metadata, replyPayload,
		); err != nil {
			return err
		}
		if err := transaction.updateRecord(
			ctx, annotationRecordKind, string(annotation.ID), expectedVersion, annotation.Metadata, annotationPayload,
		); err != nil {
			return err
		}
		result.Annotation = annotation
		result.Replies = []domain.AnnotationReply{recordedReply}
		return appendProvenanceEvent(
			transaction, ctx, now, annotationRecordKind, string(annotation.ID),
			"annotation.answered", recordedReply.Authority,
		)
	})
	return result, err
}

func (store *Store) ReanchorAnnotation(
	ctx context.Context,
	id domain.AnnotationID,
	expectedVersion domain.ResourceVersion,
	anchor domain.AnnotationAnchor,
) (domain.Annotation, error) {
	if err := id.Validate(); err != nil {
		return domain.Annotation{}, err
	}
	if expectedVersion == 0 || !validAnnotationAnchor(anchor) {
		return domain.Annotation{}, invalidSessionArgument("reanchor annotation", string(id), "version and anchor are required")
	}
	var updated domain.Annotation
	err := store.Transaction(ctx, func(transaction *Tx) error {
		current, found, err := typedRecord[domain.Annotation](transaction, ctx, annotationRecordKind, string(id))
		if err != nil {
			return err
		}
		if !found {
			return notFound("reanchor annotation", string(id), "annotation does not exist")
		}
		if current.Metadata.ResourceVersion != expectedVersion {
			return conflict("reanchor annotation", string(id), "annotation version changed")
		}
		updated = current
		updated.Anchor = &anchor
		updated.Metadata.ResourceVersion++
		updated.Metadata.UpdatedAt = time.Now().UTC()
		encoded, err := json.Marshal(updated)
		if err != nil {
			return wrap("encode reanchored annotation", string(id), err)
		}
		if err := transaction.updateRecord(
			ctx, annotationRecordKind, string(id), expectedVersion, updated.Metadata, encoded,
		); err != nil {
			return err
		}
		return appendProvenanceEvent(
			transaction, ctx, updated.Metadata.UpdatedAt, annotationRecordKind,
			string(id), "annotation.reanchored", updated.Authority,
		)
	})
	return updated, err
}

func (store *Store) Annotation(
	ctx context.Context,
	id domain.AnnotationID,
) (AnnotationWithReplies, error) {
	if err := id.Validate(); err != nil {
		return AnnotationWithReplies{}, err
	}
	var result AnnotationWithReplies
	err := store.Transaction(ctx, func(transaction *Tx) error {
		var found bool
		var err error
		result.Annotation, found, err = typedRecord[domain.Annotation](
			transaction, ctx, annotationRecordKind, string(id),
		)
		if err != nil {
			return err
		}
		if !found {
			return notFound("read annotation", string(id), "annotation does not exist")
		}
		replies, err := typedRecords[domain.AnnotationReply](transaction, ctx, annotationReplyRecordKind)
		if err != nil {
			return err
		}
		for _, reply := range replies {
			if reply.AnnotationID == id {
				result.Replies = append(result.Replies, reply)
			}
		}
		return nil
	})
	return result, err
}

func appendProvenanceEvent(
	transaction *Tx,
	ctx context.Context,
	now time.Time,
	kind string,
	id string,
	eventType string,
	authority domain.Authority,
) error {
	payload, err := json.Marshal(struct {
		Authority domain.Authority `json:"authority"`
	}{Authority: authority})
	if err != nil {
		return wrap("encode provenance event", eventType, err)
	}
	_, err = transaction.AppendEvent(ctx, domain.EventEnvelope{
		SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
		Aggregate: domain.ResourceReference{Kind: kind, ID: id}, Type: eventType, Payload: payload,
	})
	return err
}

func (transaction *Tx) resourceExists(ctx context.Context, reference domain.ResourceReference) (bool, error) {
	var exists bool
	err := transaction.tx.QueryRowContext(
		ctx, "SELECT EXISTS(SELECT 1 FROM records WHERE kind = ? AND id = ?)", reference.Kind, reference.ID,
	).Scan(&exists)
	if err != nil {
		return false, wrap("read provenance target", reference.Kind+":"+reference.ID, err)
	}
	return exists, nil
}

func (transaction *Tx) validateAnnotationTargets(
	ctx context.Context,
	targets []domain.ResourceReference,
) error {
	seen := make(map[string]struct{}, len(targets))
	for _, target := range targets {
		if err := target.Validate(); err != nil {
			return err
		}
		key := target.Kind + "\x00" + target.ID
		if _, found := seen[key]; found {
			return invalidSessionArgument("create annotation", target.Kind+":"+target.ID, "annotation targets must be unique")
		}
		seen[key] = struct{}{}
		found, err := transaction.resourceExists(ctx, target)
		if err != nil {
			return err
		}
		if !found {
			return notFound("create annotation", target.Kind+":"+target.ID, "annotation target does not exist")
		}
	}
	return nil
}

func validateCommitObservation(observation domain.CommitObservation) error {
	for _, err := range []error{
		observation.ID.Validate(), observation.WorkspaceID.Validate(),
		observation.BeforeSnapshotID.Validate(), observation.AfterSnapshotID.Validate(),
	} {
		if err != nil {
			return err
		}
	}
	if observation.Repository == "" || observation.Commit == "" || observation.TreeDigest == "" ||
		observation.ObservedAt.IsZero() || !observation.Basis.Valid() || !observation.Authority.Valid() ||
		!uniqueNonemptyStrings(observation.Parents) {
		return invalidSessionArgument("record commit observation", string(observation.ID), "commit evidence is incomplete")
	}
	if !validExternalSource(observation.Source, observation.SourceID) ||
		observation.Basis == domain.ProvenanceBasisAdapterReported && observation.Source == "" {
		return invalidSessionArgument("record commit observation", string(observation.ID), "commit source and source identifier are incomplete")
	}
	return validateImportedAuthority(
		"record commit observation", string(observation.ID), observation.Basis, observation.Authority,
	)
}

func validateProvenanceRelation(relation domain.ProvenanceRelation) error {
	if err := relation.ID.Validate(); err != nil {
		return err
	}
	if err := relation.From.Validate(); err != nil {
		return err
	}
	if err := relation.To.Validate(); err != nil {
		return err
	}
	if !relation.Kind.Valid() || !relation.Basis.Valid() || !relation.Authority.Valid() || relation.ObservedAt.IsZero() {
		return invalidSessionArgument("record provenance", string(relation.ID), "provenance relation is incomplete")
	}
	if !validExternalSource(relation.Source, relation.SourceID) ||
		relation.Basis == domain.ProvenanceBasisAdapterReported && relation.Source == "" {
		return invalidSessionArgument("record provenance", string(relation.ID), "provenance source and source identifier are incomplete")
	}
	return validateImportedAuthority("record provenance", string(relation.ID), relation.Basis, relation.Authority)
}

func validateAnnotation(annotation domain.Annotation) error {
	if err := annotation.ID.Validate(); err != nil {
		return err
	}
	if annotation.Summary == "" || annotation.Author == "" || !annotation.Origin.Valid() || !annotation.Authority.Valid() {
		return invalidSessionArgument("create annotation", string(annotation.ID), "annotation identity and authority are required")
	}
	if annotation.Anchor != nil && !validAnnotationAnchor(*annotation.Anchor) {
		return invalidSessionArgument("create annotation", string(annotation.ID), "annotation anchor is invalid")
	}
	if !validExternalSource(annotation.Source, annotation.SourceID) {
		return invalidSessionArgument("create annotation", string(annotation.ID), "annotation source and source identifier are incomplete")
	}
	if annotation.Source != "" && annotation.Authority != domain.AuthorityAdvisory && annotation.Authority != domain.AuthorityOwner {
		return invalidSessionArgument("create annotation", string(annotation.ID), "imported annotation authority is invalid")
	}
	if annotation.Origin == domain.AnnotationOriginUser && annotation.Authority != domain.AuthorityOwner {
		return invalidSessionArgument("create annotation", string(annotation.ID), "user annotation requires owner authority")
	}
	return nil
}

func validateAnnotationReply(expectedVersion domain.ResourceVersion, reply domain.AnnotationReply) error {
	for _, err := range []error{reply.ID.Validate(), reply.AnnotationID.Validate()} {
		if err != nil {
			return err
		}
	}
	if expectedVersion == 0 || reply.Summary == "" || reply.Author == "" || !reply.Authority.Valid() {
		return invalidSessionArgument("answer annotation", string(reply.ID), "reply identity, version, and authority are required")
	}
	if !validExternalSource(reply.Source, reply.SourceID) {
		return invalidSessionArgument("answer annotation", string(reply.ID), "reply source and source identifier are incomplete")
	}
	if reply.Source != "" && reply.Authority != domain.AuthorityAdvisory && reply.Authority != domain.AuthorityOwner {
		return invalidSessionArgument("answer annotation", string(reply.ID), "imported reply authority is invalid")
	}
	return nil
}

func validateImportedAuthority(
	operation string,
	resource string,
	basis domain.ProvenanceBasis,
	authority domain.Authority,
) error {
	if basis == domain.ProvenanceBasisAdapterReported && authority != domain.AuthorityAdvisory {
		return invalidSessionArgument(operation, resource, "adapter-reported evidence must remain advisory")
	}
	return nil
}

func validAnnotationAnchor(anchor domain.AnnotationAnchor) bool {
	return anchor.File != "" && anchor.Line > 0 && anchor.Text != ""
}
