package sqlite

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

func TestCommitProvenanceAndAnnotationHistory(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	workspace := t.TempDir()
	tracked := filepath.Join(workspace, "tracked.txt")
	if err := os.WriteFile(tracked, []byte("before\n"), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	before, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-before-commit", "workspace-provenance", workspace)
	if err != nil {
		t.Fatalf("CreateWorkspaceSnapshot(before) returned %v", err)
	}
	if err := os.WriteFile(tracked, []byte("after\n"), 0o600); err != nil {
		t.Fatalf("second WriteFile() returned %v", err)
	}
	after, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-after-commit", "workspace-provenance", workspace)
	if err != nil {
		t.Fatalf("CreateWorkspaceSnapshot(after) returned %v", err)
	}
	observation, err := store.RecordCommitObservation(ctx, domain.CommitObservation{
		ID: "commit-observation-1", WorkspaceID: "workspace-provenance", Repository: "colchis",
		Commit: "0123456789abcdef", TreeDigest: after.TreeDigest,
		BeforeSnapshotID: before.ID, AfterSnapshotID: after.ID,
		Basis: domain.ProvenanceBasisBrokerObserved, Authority: domain.AuthorityHarness,
		ObservedAt: time.Now().UTC(),
	})
	if err != nil {
		t.Fatalf("RecordCommitObservation() returned %v", err)
	}
	relation, err := store.RecordProvenanceRelation(ctx, domain.ProvenanceRelation{
		ID: "provenance-relation-1", Kind: domain.ProvenanceRelationProduced,
		From:  domain.ResourceReference{Kind: commitObservationRecordKind, ID: string(observation.ID)},
		To:    domain.ResourceReference{Kind: snapshotRecordKind, ID: string(after.ID)},
		Basis: domain.ProvenanceBasisDerived, Authority: domain.AuthorityHarness,
		ObservedAt: time.Now().UTC(),
	})
	if err != nil || relation.Authority != domain.AuthorityHarness {
		t.Fatalf("RecordProvenanceRelation() = %#v, %v", relation, err)
	}
	inspection, err := store.InspectProvenance(ctx)
	if err != nil || len(inspection.CommitObservations) != 1 || len(inspection.Relations) != 1 {
		t.Fatalf("InspectProvenance() = %#v, %v", inspection, err)
	}
	annotation, err := store.CreateAnnotation(ctx, domain.Annotation{
		ID: "annotation-1", Summary: "Explain the tracked change", Author: "owner",
		Origin: domain.AnnotationOriginUser, Authority: domain.AuthorityOwner,
		Anchor:  &domain.AnnotationAnchor{File: tracked, Line: 1, Text: "after"},
		Targets: []domain.ResourceReference{{Kind: commitObservationRecordKind, ID: string(observation.ID)}},
	})
	if err != nil {
		t.Fatalf("CreateAnnotation() returned %v", err)
	}
	annotation, err = store.ReanchorAnnotation(ctx, annotation.ID, annotation.Metadata.ResourceVersion, domain.AnnotationAnchor{
		File: tracked, Line: 2, Text: "after",
	})
	if err != nil {
		t.Fatalf("ReanchorAnnotation() returned %v", err)
	}
	answered, err := store.AnswerAnnotation(ctx, annotation.Metadata.ResourceVersion, domain.AnnotationReply{
		ID: "annotation-reply-1", AnnotationID: annotation.ID,
		Summary: "The stage produced this content.", Author: "agent",
		Authority: domain.AuthorityAdvisory, Source: "runtime", SourceID: "reply-private",
	})
	if err != nil {
		t.Fatalf("AnswerAnnotation() returned %v", err)
	}
	if answered.Annotation.State != domain.AnnotationStateAnswered || len(answered.Replies) != 1 {
		t.Fatalf("answered annotation = %#v", answered)
	}
	restored, err := store.Annotation(ctx, annotation.ID)
	if err != nil || len(restored.Replies) != 1 || restored.Annotation.Anchor.Line != 2 {
		t.Fatalf("Annotation() = %#v, %v", restored, err)
	}
}

func TestAdapterReportedProvenanceRemainsAdvisory(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	_, err = store.RecordProvenanceRelation(ctx, domain.ProvenanceRelation{
		ID: "provenance-elevated", Kind: domain.ProvenanceRelationProduced,
		From:  domain.ResourceReference{Kind: "activity", ID: "missing-from"},
		To:    domain.ResourceReference{Kind: "activity", ID: "missing-to"},
		Basis: domain.ProvenanceBasisAdapterReported, Authority: domain.AuthorityHarness,
		ObservedAt: time.Now().UTC(),
	})
	if !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("RecordProvenanceRelation() error = %v", err)
	}
}
