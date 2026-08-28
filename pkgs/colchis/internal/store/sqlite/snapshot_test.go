package sqlite

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"testing"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
)

func TestWorkspaceSnapshotsDeduplicateAndResolveArtifacts(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	nodeID := createArtifactPolicyNode(t, ctx, store, evaluator, []string{"artifact.txt"})
	workspace := t.TempDir()
	writeSnapshotTestFile(t, filepath.Join(workspace, "artifact.txt"), "first")
	writeSnapshotTestFile(t, filepath.Join(workspace, "unchanged.txt"), "same")
	first, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-first", "workspace-1", workspace)
	if err != nil {
		t.Fatalf("CreateWorkspaceSnapshot() returned %v", err)
	}
	writeSnapshotTestFile(t, filepath.Join(workspace, "artifact.txt"), "second")
	second, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-second", "workspace-1", workspace)
	if err != nil {
		t.Fatalf("second CreateWorkspaceSnapshot() returned %v", err)
	}
	if first.TreeDigest == second.TreeDigest || first.ByteSize != 9 || second.ByteSize != 10 {
		t.Fatalf("snapshots = %#v, %#v", first, second)
	}
	artifact, err := store.ResolveArtifact(ctx, ArtifactRequest{
		ID: "artifact-1", NodeRunID: nodeID, SnapshotID: second.ID,
		BaseSnapshotID: &first.ID, Path: "artifact.txt",
	})
	if err != nil {
		t.Fatalf("ResolveArtifact() returned %v", err)
	}
	expected := sha256.Sum256([]byte("second"))
	if artifact.Digest != fmt.Sprintf("sha256:%x", expected) || artifact.ByteSize != 6 ||
		len(artifact.ChangedPaths) != 1 || artifact.ChangedPaths[0] != "artifact.txt" {
		t.Fatalf("artifact = %#v", artifact)
	}
	objectStore := filepath.Join(filepath.Dir(store.path), workspaceObjectStoreName)
	output, err := runGit(ctx, gitEnvironment(objectStore, "", ""), 4096, "count-objects", "-v")
	if err != nil {
		t.Fatalf("count-objects returned %v", err)
	}
	if len(output) == 0 {
		t.Fatal("content-addressed object store is empty")
	}
}

func TestArtifactResolutionRejectsSymlinksAndScopeEscapes(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	nodeID := createArtifactPolicyNode(t, ctx, store, evaluator, []string{"link.txt"})
	workspace := t.TempDir()
	writeSnapshotTestFile(t, filepath.Join(workspace, "inside.txt"), "inside")
	base, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-links-base", "workspace-links", workspace)
	if err != nil {
		t.Fatalf("base CreateWorkspaceSnapshot() returned %v", err)
	}
	if err := os.Symlink("inside.txt", filepath.Join(workspace, "link.txt")); err != nil {
		t.Fatalf("Symlink() returned %v", err)
	}
	snapshot, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-links", "workspace-links", workspace)
	if err != nil {
		t.Fatalf("CreateWorkspaceSnapshot() returned %v", err)
	}
	if _, err := store.ResolveArtifact(ctx, ArtifactRequest{
		ID: "artifact-link", NodeRunID: nodeID, SnapshotID: snapshot.ID,
		BaseSnapshotID: &base.ID, Path: "link.txt",
	}); !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("symlink ResolveArtifact() error = %v", err)
	}
	if _, err := store.ResolveArtifact(ctx, ArtifactRequest{
		ID: "artifact-scope", NodeRunID: nodeID, SnapshotID: snapshot.ID, Path: "inside.txt",
	}); !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("scope ResolveArtifact() error = %v", err)
	}
}

func TestArtifactResolutionRejectsChangesOutsideNodeScope(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	nodeID := createArtifactPolicyNode(t, ctx, store, evaluator, []string{"artifact.txt"})
	workspace := t.TempDir()
	writeSnapshotTestFile(t, filepath.Join(workspace, "artifact.txt"), "base")
	base, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-scope-base", "workspace-scope", workspace)
	if err != nil {
		t.Fatalf("base CreateWorkspaceSnapshot() returned %v", err)
	}
	writeSnapshotTestFile(t, filepath.Join(workspace, "artifact.txt"), "target")
	writeSnapshotTestFile(t, filepath.Join(workspace, "workflow.yml"), "unauthorized")
	target, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-scope-target", "workspace-scope", workspace)
	if err != nil {
		t.Fatalf("target CreateWorkspaceSnapshot() returned %v", err)
	}
	if _, err := store.ResolveArtifact(ctx, ArtifactRequest{
		ID: "artifact-extra-change", NodeRunID: nodeID, SnapshotID: target.ID,
		BaseSnapshotID: &base.ID, Path: "artifact.txt",
	}); !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("ResolveArtifact() error = %v", err)
	}
}

func TestArtifactResolutionRejectsDifferentBaseWorkspace(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	nodeID := createArtifactPolicyNode(t, ctx, store, evaluator, []string{"artifact.txt"})
	baseWorkspace := t.TempDir()
	targetWorkspace := t.TempDir()
	writeSnapshotTestFile(t, filepath.Join(baseWorkspace, "artifact.txt"), "base")
	writeSnapshotTestFile(t, filepath.Join(targetWorkspace, "artifact.txt"), "target")
	base, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-base-other", "workspace-base", baseWorkspace)
	if err != nil {
		t.Fatalf("base CreateWorkspaceSnapshot() returned %v", err)
	}
	target, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-target-other", "workspace-target", targetWorkspace)
	if err != nil {
		t.Fatalf("target CreateWorkspaceSnapshot() returned %v", err)
	}
	_, err = store.ResolveArtifact(ctx, ArtifactRequest{
		ID: "artifact-other", NodeRunID: nodeID, SnapshotID: target.ID,
		BaseSnapshotID: &base.ID, Path: "artifact.txt",
	})
	if !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("ResolveArtifact() error = %v", err)
	}
}

func createArtifactPolicyNode(
	t *testing.T,
	ctx context.Context,
	store *Store,
	evaluator *workflowmodel.Evaluator,
	writeScopes []string,
) domain.NodeRunID {
	t.Helper()
	document, err := os.ReadFile("../../../schemas/workflow/v1/testdata/valid.json")
	if err != nil {
		t.Fatalf("ReadFile() returned %v", err)
	}
	var definition workflowmodel.Definition
	if err := json.Unmarshal(document, &definition); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	template := definition.Templates["implement"]
	template.WriteScopes = append([]string(nil), writeScopes...)
	definition.Templates["implement"] = template
	document, err = json.Marshal(definition)
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	resolved, err := evaluator.Resolve(document, graphTestCapabilities())
	if err != nil {
		t.Fatalf("Resolve() returned %v", err)
	}
	if _, err := store.CreateWorkflowDefinition(
		ctx, "definition-artifact", nil, document, resolved,
	); err != nil {
		t.Fatalf("CreateWorkflowDefinition() returned %v", err)
	}
	if _, _, err := store.CreateWorkflowRun(
		ctx, "run-artifact", "definition-artifact", nil,
	); err != nil {
		t.Fatalf("CreateWorkflowRun() returned %v", err)
	}
	return nodeRunID("run-artifact", "implement")
}

func TestWorkspaceMaterializationAndReferencesAreBounded(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	budgets := domain.DefaultBudgets()
	budgets.MaxMaterializedSnapshots = 1
	store, err := OpenWithBudgets(ctx, filepath.Join(t.TempDir(), "state", "colchis.db"), budgets)
	if err != nil {
		t.Fatalf("OpenWithBudgets() returned %v", err)
	}
	defer store.Close()
	workspace := t.TempDir()
	writeSnapshotTestFile(t, filepath.Join(workspace, "file.txt"), "content")
	snapshot, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-bounded", "workspace-bounded", workspace)
	if err != nil {
		t.Fatalf("CreateWorkspaceSnapshot() returned %v", err)
	}
	first, err := store.MaterializeWorkspaceSnapshot(ctx, snapshot.ID)
	if err != nil {
		t.Fatalf("MaterializeWorkspaceSnapshot() returned %v", err)
	}
	if _, err := os.Stat(filepath.Join(first.Path, "file.txt")); err != nil {
		t.Fatalf("materialized file stat returned %v", err)
	}
	if _, err := store.MaterializeWorkspaceSnapshot(ctx, snapshot.ID); !domain.IsErrorCode(
		err, domain.ErrorCodeBudgetExhausted,
	) {
		t.Fatalf("second MaterializeWorkspaceSnapshot() error = %v", err)
	}
	if err := first.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	owner := domain.ResourceReference{Kind: "admission", ID: "admission-1"}
	if err := store.RetainSnapshot(ctx, snapshot.ID, owner); err != nil {
		t.Fatalf("RetainSnapshot() returned %v", err)
	}
	if reclaimed, err := store.ReclaimSnapshot(ctx, snapshot.ID); err != nil || reclaimed {
		t.Fatalf("retained ReclaimSnapshot() = %v, %v", reclaimed, err)
	}
	if err := store.ReleaseSnapshot(ctx, snapshot.ID, owner); err != nil {
		t.Fatalf("ReleaseSnapshot() returned %v", err)
	}
	if reclaimed, err := store.ReclaimSnapshot(ctx, snapshot.ID); err != nil || !reclaimed {
		t.Fatalf("ReclaimSnapshot() = %v, %v", reclaimed, err)
	}
	if _, err := store.MaterializeWorkspaceSnapshot(ctx, snapshot.ID); !domain.IsErrorCode(
		err, domain.ErrorCodeNotFound,
	) {
		t.Fatalf("reclaimed MaterializeWorkspaceSnapshot() error = %v", err)
	}
}

func TestWorkspaceSnapshotObjectsRespectStateBudget(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "state", "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	if _, err := store.ensureWorkspaceObjectStore(ctx); err != nil {
		t.Fatalf("ensureWorkspaceObjectStore() returned %v", err)
	}
	baseline, err := physicalStateBytes(path)
	if err != nil {
		t.Fatalf("physicalStateBytes() returned %v", err)
	}
	store.budgets.MaxStateBytes = baseline + store.budgets.EmergencyReserveBytes + 64<<10
	workspace := t.TempDir()
	contents := make([]byte, 512<<10)
	if _, err := rand.Read(contents); err != nil {
		t.Fatalf("rand.Read() returned %v", err)
	}
	if err := os.WriteFile(filepath.Join(workspace, "large.bin"), contents, 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	if _, err := store.CreateWorkspaceSnapshot(
		ctx, "snapshot-over-budget", "workspace-budget", workspace,
	); !domain.IsErrorCode(err, domain.ErrorCodeBudgetExhausted) {
		t.Fatalf("CreateWorkspaceSnapshot() error = %v", err)
	}
	if _, err := store.workspaceSnapshot(ctx, "snapshot-over-budget"); !domain.IsErrorCode(
		err, domain.ErrorCodeNotFound,
	) {
		t.Fatalf("workspaceSnapshot() error = %v", err)
	}
	after, err := physicalStateBytes(path)
	if err != nil {
		t.Fatalf("physicalStateBytes() after rejection returned %v", err)
	}
	if after > store.budgets.MaxStateBytes-store.budgets.EmergencyReserveBytes {
		t.Fatalf("physical state bytes after rejection = %d", after)
	}
}

func TestCreateWorkspaceSnapshotRejectsSymbolicRoot(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "state", "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	root := t.TempDir()
	target := filepath.Join(root, "target")
	if err := os.Mkdir(target, 0o700); err != nil {
		t.Fatalf("Mkdir() returned %v", err)
	}
	link := filepath.Join(root, "link")
	if err := os.Symlink(target, link); err != nil {
		t.Fatalf("Symlink() returned %v", err)
	}
	_, err = store.CreateWorkspaceSnapshot(ctx, "snapshot-root", "workspace-root", link)
	if !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("CreateWorkspaceSnapshot() error = %v", err)
	}
	if _, statErr := os.Stat(filepath.Join(filepath.Dir(store.path), workspaceObjectStoreName)); !errors.Is(statErr, os.ErrNotExist) {
		t.Fatalf("object store stat error = %v", statErr)
	}
}

func TestCreateWorkspaceSnapshotRejectsNestedRepository(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "state", "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	workspace := t.TempDir()
	nestedGit := filepath.Join(workspace, "nested", ".git")
	if err := os.MkdirAll(nestedGit, 0o700); err != nil {
		t.Fatalf("MkdirAll() returned %v", err)
	}
	_, err = store.CreateWorkspaceSnapshot(ctx, "snapshot-nested", "workspace-nested", workspace)
	if !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("CreateWorkspaceSnapshot() error = %v", err)
	}
}

func TestCreateWorkspaceSnapshotRetriesOrphanReference(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "state", "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	workspace := t.TempDir()
	path := filepath.Join(workspace, "value.txt")
	writeSnapshotTestFile(t, path, "first")
	if _, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-orphan-retry", "workspace-orphan", workspace); err != nil {
		t.Fatalf("CreateWorkspaceSnapshot() returned %v", err)
	}
	if _, err := store.db.ExecContext(
		ctx, "DELETE FROM records WHERE kind = ? AND id = ?", snapshotRecordKind, "snapshot-orphan-retry",
	); err != nil {
		t.Fatalf("delete snapshot record returned %v", err)
	}
	writeSnapshotTestFile(t, path, "second")
	if _, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-orphan-retry", "workspace-orphan", workspace); err != nil {
		t.Fatalf("retry CreateWorkspaceSnapshot() returned %v", err)
	}
	materialized, err := store.MaterializeWorkspaceSnapshot(ctx, "snapshot-orphan-retry")
	if err != nil {
		t.Fatalf("MaterializeWorkspaceSnapshot() returned %v", err)
	}
	defer materialized.Close()
	value, err := os.ReadFile(filepath.Join(materialized.Path, "value.txt"))
	if err != nil || string(value) != "second" {
		t.Fatalf("materialized orphan retry = %q, %v", value, err)
	}
}

func TestReconcileOrphanSnapshotReferencesDeletesUnknownRef(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "state", "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	workspace := t.TempDir()
	writeSnapshotTestFile(t, filepath.Join(workspace, "value.txt"), "orphan")
	if _, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-orphan-clean", "workspace-orphan", workspace); err != nil {
		t.Fatalf("CreateWorkspaceSnapshot() returned %v", err)
	}
	if _, err := store.db.ExecContext(
		ctx, "DELETE FROM records WHERE kind = ? AND id = ?", snapshotRecordKind, "snapshot-orphan-clean",
	); err != nil {
		t.Fatalf("delete snapshot record returned %v", err)
	}
	removed, err := store.ReconcileOrphanSnapshotReferences(ctx)
	if err != nil || removed != 1 {
		t.Fatalf("ReconcileOrphanSnapshotReferences() = %d, %v", removed, err)
	}
	objectStore, err := store.ensureWorkspaceObjectStore(ctx)
	if err != nil {
		t.Fatalf("ensureWorkspaceObjectStore() returned %v", err)
	}
	if _, err := runGit(
		ctx, gitEnvironment(objectStore, "", ""), store.budgets.MaxEventBytes,
		"show-ref", "--verify", snapshotGitReference("snapshot-orphan-clean"),
	); err == nil {
		t.Fatal("orphan snapshot reference remains")
	}
}

func writeSnapshotTestFile(t *testing.T, path string, value string) {
	t.Helper()
	if err := os.WriteFile(path, []byte(value), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
}
