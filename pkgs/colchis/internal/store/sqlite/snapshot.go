package sqlite

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"
	"unicode/utf8"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
	"golang.org/x/sys/unix"
)

const (
	snapshotRecordKind          = "snapshot"
	artifactRecordKind          = "artifact"
	snapshotReferenceRecordKind = "snapshot-reference"
	workspaceObjectStoreName    = "workspace-objects.git"
)

var workspaceSnapshotMu sync.Mutex

type ArtifactRequest struct {
	ID             domain.ArtifactID  `json:"id"`
	NodeRunID      domain.NodeRunID   `json:"nodeRunId"`
	SnapshotID     domain.SnapshotID  `json:"snapshotId"`
	BaseSnapshotID *domain.SnapshotID `json:"baseSnapshotId,omitempty"`
	Path           string             `json:"path"`
}

type MaterializedSnapshot struct {
	Path  string
	once  sync.Once
	close func() error
}

func (snapshot *MaterializedSnapshot) Close() error {
	var err error
	snapshot.once.Do(func() { err = snapshot.close() })
	return err
}

func (store *Store) CreateWorkspaceSnapshot(
	ctx context.Context,
	id domain.SnapshotID,
	workspaceID domain.WorkspaceID,
	workspacePath string,
) (domain.Snapshot, error) {
	if err := id.Validate(); err != nil {
		return domain.Snapshot{}, err
	}
	if err := workspaceID.Validate(); err != nil {
		return domain.Snapshot{}, err
	}
	if err := store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := transaction.recordPayload(ctx, snapshotRecordKind, string(id)); err != nil {
			return err
		} else if found {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "snapshot", Resource: string(id),
				Message: "snapshot already exists",
			}
		}
		return nil
	}); err != nil {
		return domain.Snapshot{}, err
	}
	absoluteWorkspace, err := secureWorkspaceRoot(workspacePath)
	if err != nil {
		return domain.Snapshot{}, err
	}
	if err := preflightWorkspace(absoluteWorkspace, store.budgets.MaxSnapshotBytes); err != nil {
		return domain.Snapshot{}, err
	}
	workspaceSnapshotMu.Lock()
	defer workspaceSnapshotMu.Unlock()
	objectStore, err := store.ensureWorkspaceObjectStore(ctx)
	if err != nil {
		return domain.Snapshot{}, err
	}
	indexPath, cleanup, err := temporaryGitIndex(filepath.Dir(store.path))
	if err != nil {
		return domain.Snapshot{}, err
	}
	defer cleanup()
	environment := gitEnvironment(objectStore, absoluteWorkspace, indexPath)
	if _, err := runGit(ctx, environment, store.budgets.MaxEventBytes, "read-tree", "--empty"); err != nil {
		return domain.Snapshot{}, err
	}
	if _, err := runGit(ctx, environment, store.budgets.MaxEventBytes, "add", "-A", "-f", "--", "."); err != nil {
		return domain.Snapshot{}, err
	}
	treeOutput, err := runGit(ctx, environment, 256, "write-tree")
	if err != nil {
		return domain.Snapshot{}, err
	}
	tree := strings.TrimSpace(string(treeOutput))
	if len(tree) != 40 && len(tree) != 64 {
		return domain.Snapshot{}, &domain.Error{
			Code: domain.ErrorCodeInternal, Op: "snapshot", Resource: absoluteWorkspace,
			Message: "Git returned an unsupported tree identifier",
		}
	}
	listing, err := runGit(
		ctx, gitEnvironment(objectStore, "", ""), store.budgets.MaxEventBytes,
		"ls-tree", "-r", "-l", "-z", tree,
	)
	if err != nil {
		return domain.Snapshot{}, err
	}
	byteSize, err := snapshotListingSize(listing, store.budgets.MaxSnapshotBytes)
	if err != nil {
		return domain.Snapshot{}, err
	}
	algorithm := "sha1"
	if len(tree) == 64 {
		algorithm = "sha256"
	}
	now := time.Now().UTC()
	snapshot := domain.Snapshot{
		Metadata: newRecordMetadata(now), ID: id, WorkspaceID: workspaceID,
		TreeDigest: "git:" + algorithm + ":" + tree, ByteSize: byteSize,
	}
	encoded, err := json.Marshal(snapshot)
	if err != nil {
		return domain.Snapshot{}, wrap("encode workspace snapshot", string(id), err)
	}
	reference := snapshotGitReference(id)
	if _, err := runGit(
		ctx, gitEnvironment(objectStore, "", ""), store.budgets.MaxEventBytes,
		"update-ref", reference, tree,
	); err != nil {
		return domain.Snapshot{}, err
	}
	err = store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := transaction.recordPayload(ctx, snapshotRecordKind, string(id)); err != nil {
			return err
		} else if found {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "snapshot", Resource: string(id),
				Message: "snapshot already exists",
			}
		}
		if err := transaction.reserveRecordCapacity(ctx, encoded); err != nil {
			return err
		}
		if err := transaction.putRecord(ctx, snapshotRecordKind, string(id), snapshot.Metadata, encoded); err != nil {
			return err
		}
		payload, err := json.Marshal(struct {
			SnapshotID domain.SnapshotID `json:"snapshotId"`
			TreeDigest string            `json:"treeDigest"`
		}{SnapshotID: id, TreeDigest: snapshot.TreeDigest})
		if err != nil {
			return wrap("encode workspace snapshot event", string(id), err)
		}
		_, err = transaction.AppendEvent(ctx, domain.EventEnvelope{
			SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
			Aggregate: domain.ResourceReference{Kind: snapshotRecordKind, ID: string(id)},
			Type:      "workspace.snapshot.created", Payload: payload,
		})
		return err
	})
	if err != nil {
		cleanupContext, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_, cleanupErr := runGit(
			cleanupContext, gitEnvironment(objectStore, "", ""), store.budgets.MaxEventBytes,
			"update-ref", "-d", reference, tree,
		)
		_, pruneErr := runGit(
			cleanupContext, gitEnvironment(objectStore, "", ""), store.budgets.MaxEventBytes,
			"gc", "--prune=now", "--quiet",
		)
		return domain.Snapshot{}, errors.Join(err, cleanupErr, pruneErr)
	}
	return snapshot, err
}

func (store *Store) ReconcileOrphanSnapshotReferences(ctx context.Context) (uint32, error) {
	rows, err := store.db.QueryContext(ctx, "SELECT id FROM records WHERE kind = ? ORDER BY id", snapshotRecordKind)
	if err != nil {
		return 0, wrap("read snapshot records", store.path, err)
	}
	known := make(map[string]struct{})
	for rows.Next() {
		var id domain.SnapshotID
		if err := rows.Scan(&id); err != nil {
			rows.Close()
			return 0, wrap("scan snapshot record", store.path, err)
		}
		known[snapshotGitReference(id)] = struct{}{}
	}
	if err := rows.Err(); err != nil {
		rows.Close()
		return 0, wrap("iterate snapshot records", store.path, err)
	}
	if err := rows.Close(); err != nil {
		return 0, wrap("close snapshot records", store.path, err)
	}

	workspaceSnapshotMu.Lock()
	defer workspaceSnapshotMu.Unlock()
	objectStore, err := store.ensureWorkspaceObjectStore(ctx)
	if err != nil {
		return 0, err
	}
	output, err := runGit(
		ctx, gitEnvironment(objectStore, "", ""), store.budgets.MaxEventBytes,
		"for-each-ref", "--format=%(refname)", "refs/colchis/snapshots/",
	)
	if err != nil {
		return 0, err
	}
	var removed uint32
	for _, reference := range strings.Fields(string(output)) {
		if _, found := known[reference]; found {
			continue
		}
		if _, err := runGit(
			ctx, gitEnvironment(objectStore, "", ""), store.budgets.MaxEventBytes,
			"update-ref", "-d", reference,
		); err != nil {
			return removed, err
		}
		removed++
	}
	if removed == 0 {
		return 0, nil
	}
	_, err = runGit(
		ctx, gitEnvironment(objectStore, "", ""), store.budgets.MaxEventBytes,
		"gc", "--prune=now", "--quiet",
	)
	return removed, err
}

func (store *Store) MaterializeWorkspaceSnapshot(
	ctx context.Context,
	id domain.SnapshotID,
) (*MaterializedSnapshot, error) {
	snapshot, err := store.workspaceSnapshot(ctx, id)
	if err != nil {
		return nil, err
	}
	if snapshot.ByteSize > store.budgets.MaxSnapshotBytes {
		return nil, &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "materialize", Resource: string(id),
			Message: "snapshot byte limit exceeded",
		}
	}
	workspaceSnapshotMu.Lock()
	defer workspaceSnapshotMu.Unlock()
	objectStore, err := store.ensureWorkspaceObjectStore(ctx)
	if err != nil {
		return nil, err
	}
	parent := filepath.Join(filepath.Dir(store.path), "workspace-materializations")
	if err := os.MkdirAll(parent, 0o700); err != nil {
		return nil, wrap("create workspace materialization parent", parent, err)
	}
	directory, lease, err := createSnapshotDirectory(parent, store.budgets.MaxMaterializedSnapshots)
	if err != nil {
		return nil, err
	}
	failed := true
	defer func() {
		if failed {
			_ = cleanupReadOnlySnapshot(directory, lease)
		}
	}()
	indexPath, cleanupIndex, err := temporaryGitIndex(filepath.Dir(store.path))
	if err != nil {
		return nil, err
	}
	defer cleanupIndex()
	tree, err := snapshotTreeID(snapshot.TreeDigest)
	if err != nil {
		return nil, err
	}
	environment := gitEnvironment(objectStore, directory, indexPath)
	if _, err := runGit(ctx, environment, store.budgets.MaxEventBytes, "read-tree", tree); err != nil {
		return nil, err
	}
	if _, err := runGit(
		ctx, environment, store.budgets.MaxEventBytes,
		"checkout-index", "--all", "--force", "--prefix="+directory+string(os.PathSeparator),
	); err != nil {
		return nil, err
	}
	failed = false
	return &MaterializedSnapshot{
		Path:  directory,
		close: func() error { return cleanupReadOnlySnapshot(directory, lease) },
	}, nil
}

func (store *Store) ResolveArtifact(
	ctx context.Context,
	request ArtifactRequest,
) (domain.Artifact, error) {
	if err := validateArtifactRequest(request); err != nil {
		return domain.Artifact{}, err
	}
	writeScopes, err := store.artifactWriteScopes(ctx, request.NodeRunID)
	if err != nil {
		return domain.Artifact{}, err
	}
	if !pathWithinScopes(request.Path, writeScopes) {
		return domain.Artifact{}, &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "resolve", Resource: request.Path,
			Message: "artifact path is outside the pinned node write scope",
		}
	}
	if request.BaseSnapshotID == nil && !pathWithinScopes(".", writeScopes) {
		return domain.Artifact{}, &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "resolve", Resource: request.Path,
			Message: "a restricted artifact requires a base snapshot",
		}
	}
	changed, err := store.snapshotChangedPaths(ctx, request.BaseSnapshotID, request.SnapshotID)
	if err != nil {
		return domain.Artifact{}, err
	}
	for _, path := range changed {
		if !pathWithinScopes(path, writeScopes) {
			return domain.Artifact{}, &domain.Error{
				Code: domain.ErrorCodeUnauthorized, Op: "resolve", Resource: path,
				Message: "snapshot changed a path outside the pinned node write scope",
			}
		}
	}
	materialized, err := store.MaterializeWorkspaceSnapshot(ctx, request.SnapshotID)
	if err != nil {
		return domain.Artifact{}, err
	}
	defer materialized.Close()
	digest, byteSize, err := digestArtifactDescriptor(materialized.Path, request.Path, store.budgets.MaxSnapshotBytes)
	if err != nil {
		return domain.Artifact{}, err
	}
	now := time.Now().UTC()
	artifact := domain.Artifact{
		Metadata: newRecordMetadata(now), ID: request.ID, SnapshotID: request.SnapshotID,
		Path: request.Path, Digest: digest, ByteSize: byteSize, ChangedPaths: changed,
	}
	encoded, err := json.Marshal(artifact)
	if err != nil {
		return domain.Artifact{}, wrap("encode artifact", string(request.ID), err)
	}
	owner := domain.ResourceReference{Kind: artifactRecordKind, ID: string(request.ID)}
	referenceID := snapshotReferenceID(request.SnapshotID, owner)
	referencePayload, err := json.Marshal(struct {
		SnapshotID domain.SnapshotID        `json:"snapshotId"`
		Owner      domain.ResourceReference `json:"owner"`
	}{SnapshotID: request.SnapshotID, Owner: owner})
	if err != nil {
		return domain.Artifact{}, wrap("encode artifact snapshot reference", referenceID, err)
	}
	err = store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := transaction.recordPayload(ctx, artifactRecordKind, string(request.ID)); err != nil {
			return err
		} else if found {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "resolve", Resource: string(request.ID),
				Message: "artifact already exists",
			}
		}
		if err := transaction.reserveRecordBytes(
			ctx, uint64(len(encoded))+uint64(len(referencePayload)), 2,
		); err != nil {
			return err
		}
		if err := transaction.putRecord(ctx, artifactRecordKind, string(request.ID), artifact.Metadata, encoded); err != nil {
			return err
		}
		return transaction.putRecord(
			ctx, snapshotReferenceRecordKind, referenceID, newRecordMetadata(now), referencePayload,
		)
	})
	return artifact, err
}

func (store *Store) artifactWriteScopes(
	ctx context.Context,
	nodeID domain.NodeRunID,
) ([]string, error) {
	var scopes []string
	err := store.Transaction(ctx, func(transaction *Tx) error {
		node, found, err := transaction.nodeRun(ctx, nodeID)
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "resolve", Resource: string(nodeID),
				Message: "artifact node run does not exist",
			}
		}
		run, found, err := transaction.workflowRun(ctx, node.WorkflowRunID)
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeInternal, Op: "resolve", Resource: string(node.WorkflowRunID),
				Message: "artifact workflow run is unavailable",
			}
		}
		definitionRecord, err := transaction.workflowDefinitionAtVersion(
			ctx, run.WorkflowDefinition, node.DefinitionVersion,
		)
		if err != nil {
			return err
		}
		definition, err := decodeResolvedDefinition(definitionRecord)
		if err != nil {
			return err
		}
		nodeDefinition, found := definition.Nodes[node.NodeKey]
		if !found {
			return invalidArtifactWriteScopes(nodeID)
		}
		template, found := definition.Templates[nodeDefinition.Template]
		if !found || !validArtifactWriteScopes(template) {
			return invalidArtifactWriteScopes(nodeID)
		}
		scopes = append([]string(nil), template.WriteScopes...)
		return nil
	})
	return scopes, err
}

func validArtifactWriteScopes(template workflowmodel.Template) bool {
	if len(template.WriteScopes) == 0 {
		return false
	}
	for _, scope := range template.WriteScopes {
		if scope != "." && !validRelativePath(scope) {
			return false
		}
	}
	return true
}

func invalidArtifactWriteScopes(nodeID domain.NodeRunID) error {
	return &domain.Error{
		Code: domain.ErrorCodeUnauthorized, Op: "resolve", Resource: string(nodeID),
		Message: "pinned node write scope is unavailable or invalid",
	}
}

func (store *Store) RetainSnapshot(
	ctx context.Context,
	snapshotID domain.SnapshotID,
	owner domain.ResourceReference,
) error {
	if err := snapshotID.Validate(); err != nil {
		return err
	}
	if err := owner.Validate(); err != nil {
		return err
	}
	id := snapshotReferenceID(snapshotID, owner)
	return store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := transaction.recordPayload(ctx, snapshotRecordKind, string(snapshotID)); err != nil {
			return err
		} else if !found {
			return &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "retain", Resource: string(snapshotID),
				Message: "snapshot does not exist",
			}
		}
		if _, found, err := transaction.recordPayload(ctx, snapshotReferenceRecordKind, id); err != nil || found {
			return err
		}
		now := time.Now().UTC()
		metadata := newRecordMetadata(now)
		payload, err := json.Marshal(struct {
			SnapshotID domain.SnapshotID        `json:"snapshotId"`
			Owner      domain.ResourceReference `json:"owner"`
		}{SnapshotID: snapshotID, Owner: owner})
		if err != nil {
			return wrap("encode snapshot reference", id, err)
		}
		if err := transaction.reserveRecordCapacity(ctx, payload); err != nil {
			return err
		}
		return transaction.putRecord(ctx, snapshotReferenceRecordKind, id, metadata, payload)
	})
}

func (store *Store) ReleaseSnapshot(
	ctx context.Context,
	snapshotID domain.SnapshotID,
	owner domain.ResourceReference,
) error {
	if err := snapshotID.Validate(); err != nil {
		return err
	}
	if err := owner.Validate(); err != nil {
		return err
	}
	id := snapshotReferenceID(snapshotID, owner)
	return store.Transaction(ctx, func(transaction *Tx) error {
		_, err := transaction.tx.ExecContext(
			ctx, "DELETE FROM records WHERE kind = ? AND id = ?", snapshotReferenceRecordKind, id,
		)
		return err
	})
}

func (store *Store) ReclaimSnapshot(ctx context.Context, id domain.SnapshotID) (bool, error) {
	if err := id.Validate(); err != nil {
		return false, err
	}
	var reclaimed bool
	var referenced bool
	err := store.Transaction(ctx, func(transaction *Tx) error {
		references, err := transaction.snapshotReferenceCount(ctx, id)
		if err != nil {
			return err
		}
		if references != 0 {
			referenced = true
			return nil
		}
		result, err := transaction.tx.ExecContext(
			ctx, "DELETE FROM records WHERE kind = ? AND id = ?", snapshotRecordKind, string(id),
		)
		if err != nil {
			return wrap("reclaim snapshot", string(id), err)
		}
		rows, err := result.RowsAffected()
		if err != nil {
			return wrap("count reclaimed snapshot", string(id), err)
		}
		reclaimed = rows == 1
		return nil
	})
	if err != nil || referenced {
		return reclaimed, err
	}
	workspaceSnapshotMu.Lock()
	defer workspaceSnapshotMu.Unlock()
	objectStore, err := store.ensureWorkspaceObjectStore(ctx)
	if err != nil {
		return true, err
	}
	if _, err := runGit(
		ctx, gitEnvironment(objectStore, "", ""), store.budgets.MaxEventBytes,
		"update-ref", "-d", snapshotGitReference(id),
	); err != nil {
		return true, err
	}
	_, err = runGit(
		ctx, gitEnvironment(objectStore, "", ""), store.budgets.MaxEventBytes,
		"gc", "--prune=now", "--quiet",
	)
	return true, err
}

func (transaction *Tx) snapshotReferenceCount(ctx context.Context, id domain.SnapshotID) (uint32, error) {
	rows, err := transaction.tx.QueryContext(
		ctx, "SELECT payload FROM records WHERE kind = ?", snapshotReferenceRecordKind,
	)
	if err != nil {
		return 0, wrap("read snapshot references", string(id), err)
	}
	defer rows.Close()
	var count uint32
	for rows.Next() {
		var payload []byte
		if err := rows.Scan(&payload); err != nil {
			return 0, wrap("scan snapshot reference", string(id), err)
		}
		var reference struct {
			SnapshotID domain.SnapshotID `json:"snapshotId"`
		}
		if err := json.Unmarshal(payload, &reference); err != nil {
			return 0, wrap("decode snapshot reference", string(id), err)
		}
		if reference.SnapshotID == id {
			count++
		}
	}
	if err := rows.Err(); err != nil {
		return 0, wrap("iterate snapshot references", string(id), err)
	}
	return count, nil
}

func (store *Store) workspaceSnapshot(ctx context.Context, id domain.SnapshotID) (domain.Snapshot, error) {
	if err := id.Validate(); err != nil {
		return domain.Snapshot{}, err
	}
	var snapshot domain.Snapshot
	err := store.Transaction(ctx, func(transaction *Tx) error {
		payload, found, err := transaction.recordPayload(ctx, snapshotRecordKind, string(id))
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "read", Resource: string(id),
				Message: "snapshot does not exist",
			}
		}
		return json.Unmarshal(payload, &snapshot)
	})
	return snapshot, err
}

func (store *Store) ensureWorkspaceObjectStore(ctx context.Context) (string, error) {
	path := filepath.Join(filepath.Dir(store.path), workspaceObjectStoreName)
	if info, err := os.Lstat(path); err == nil {
		if info.Mode()&os.ModeSymlink != 0 || !info.IsDir() {
			return "", &domain.Error{
				Code: domain.ErrorCodeUnauthorized, Op: "use object store", Resource: path,
				Message: "workspace object store is not a directory",
			}
		}
		return path, nil
	} else if !errors.Is(err, os.ErrNotExist) {
		return "", wrap("inspect workspace object store", path, err)
	}
	if _, err := runGit(ctx, nil, store.budgets.MaxEventBytes, "init", "--bare", path); err != nil {
		return "", err
	}
	if err := os.Chmod(path, 0o700); err != nil {
		return "", wrap("restrict workspace object store", path, err)
	}
	return path, nil
}

func (store *Store) snapshotChangedPaths(
	ctx context.Context,
	baseID *domain.SnapshotID,
	targetID domain.SnapshotID,
) ([]string, error) {
	if baseID == nil {
		return []string{}, nil
	}
	base, err := store.workspaceSnapshot(ctx, *baseID)
	if err != nil {
		return nil, err
	}
	target, err := store.workspaceSnapshot(ctx, targetID)
	if err != nil {
		return nil, err
	}
	if base.WorkspaceID != target.WorkspaceID {
		return nil, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "diff", Resource: string(targetID),
			Message: "snapshot workspaces do not match",
		}
	}
	baseTree, err := snapshotTreeID(base.TreeDigest)
	if err != nil {
		return nil, err
	}
	targetTree, err := snapshotTreeID(target.TreeDigest)
	if err != nil {
		return nil, err
	}
	output, err := runGit(
		ctx, gitEnvironment(filepath.Join(filepath.Dir(store.path), workspaceObjectStoreName), "", ""),
		store.budgets.MaxEventBytes, "diff", "--name-only", "-z", baseTree, targetTree,
	)
	if err != nil {
		return nil, err
	}
	return parseChangedPaths(output)
}

func secureWorkspaceRoot(path string) (string, error) {
	absolute, err := filepath.Abs(path)
	if err != nil {
		return "", wrap("resolve workspace", path, err)
	}
	info, err := os.Lstat(absolute)
	if err != nil {
		return "", wrap("inspect workspace", absolute, err)
	}
	if info.Mode()&os.ModeSymlink != 0 || !info.IsDir() {
		return "", &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "snapshot", Resource: absolute,
			Message: "workspace root is not a direct directory",
		}
	}
	return absolute, nil
}

func preflightWorkspace(root string, limit uint64) error {
	var total uint64
	return filepath.WalkDir(root, func(path string, entry os.DirEntry, walkErr error) error {
		if walkErr != nil {
			return wrap("inspect workspace entry", path, walkErr)
		}
		if path != root && entry.Name() == ".git" {
			if filepath.Dir(path) != root {
				return &domain.Error{
					Code: domain.ErrorCodeInvalidArgument, Op: "snapshot", Resource: path,
					Message: "nested Git repositories are unsupported",
				}
			}
			if entry.IsDir() {
				return filepath.SkipDir
			}
			return nil
		}
		info, err := entry.Info()
		if err != nil {
			return wrap("inspect workspace entry", path, err)
		}
		var size uint64
		switch {
		case info.IsDir():
			return nil
		case info.Mode().IsRegular():
			if info.Size() < 0 {
				return &domain.Error{
					Code: domain.ErrorCodeInvalidArgument, Op: "snapshot", Resource: path,
					Message: "workspace file has a negative size",
				}
			}
			size = uint64(info.Size())
		case info.Mode()&os.ModeSymlink != 0:
			target, err := os.Readlink(path)
			if err != nil {
				return wrap("read workspace symbolic link", path, err)
			}
			size = uint64(len(target))
		default:
			return &domain.Error{
				Code: domain.ErrorCodeInvalidArgument, Op: "snapshot", Resource: path,
				Message: "workspace contains an unsupported special file",
			}
		}
		if size > limit-total {
			return &domain.Error{
				Code: domain.ErrorCodeBudgetExhausted, Op: "snapshot", Resource: path,
				Message: "snapshot byte limit exceeded",
			}
		}
		total += size
		return nil
	})
}

func temporaryGitIndex(parent string) (string, func(), error) {
	file, err := os.CreateTemp(parent, ".workspace-index-")
	if err != nil {
		return "", func() {}, wrap("create private Git index", parent, err)
	}
	path := file.Name()
	if err := file.Close(); err != nil {
		return "", func() {}, wrap("close private Git index", path, err)
	}
	if err := os.Remove(path); err != nil {
		return "", func() {}, wrap("prepare private Git index", path, err)
	}
	return path, func() { _ = os.Remove(path) }, nil
}

func gitEnvironment(gitDirectory string, workTree string, indexPath string) []string {
	environment := make([]string, 0, len(os.Environ())+6)
	for _, entry := range os.Environ() {
		if !strings.HasPrefix(entry, "GIT_") {
			environment = append(environment, entry)
		}
	}
	environment = append(
		environment,
		"GIT_CONFIG_NOSYSTEM=1",
		"GIT_CONFIG_GLOBAL="+os.DevNull,
		"GIT_TERMINAL_PROMPT=0",
	)
	if gitDirectory != "" {
		environment = append(environment, "GIT_DIR="+gitDirectory)
	}
	if workTree != "" {
		environment = append(environment, "GIT_WORK_TREE="+workTree)
	}
	if indexPath != "" {
		environment = append(environment, "GIT_INDEX_FILE="+indexPath)
	}
	return environment
}

func runGit(ctx context.Context, environment []string, limit uint64, arguments ...string) ([]byte, error) {
	command := exec.CommandContext(ctx, "git", arguments...)
	if environment == nil {
		environment = gitEnvironment("", "", "")
	}
	command.Env = environment
	buffer := &limitedBuffer{remaining: limit}
	command.Stdout = buffer
	command.Stderr = buffer
	if err := command.Run(); err != nil {
		if buffer.exhausted {
			return nil, &domain.Error{
				Code: domain.ErrorCodeBudgetExhausted, Op: "run Git", Resource: arguments[0],
				Message: "Git output limit exceeded", Err: err,
			}
		}
		return nil, wrap("run Git", strings.Join(arguments, " "), fmt.Errorf("%w: %s", err, buffer.Bytes()))
	}
	if buffer.exhausted {
		return nil, &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "run Git", Resource: arguments[0],
			Message: "Git output limit exceeded",
		}
	}
	return buffer.Bytes(), nil
}

type limitedBuffer struct {
	bytes.Buffer
	remaining uint64
	exhausted bool
}

func (buffer *limitedBuffer) Write(value []byte) (int, error) {
	requested := len(value)
	if uint64(requested) > buffer.remaining {
		value = value[:buffer.remaining]
		buffer.exhausted = true
	}
	written, err := buffer.Buffer.Write(value)
	buffer.remaining -= uint64(written)
	return requested, err
}

func snapshotListingSize(listing []byte, limit uint64) (uint64, error) {
	var total uint64
	for _, entry := range bytes.Split(listing, []byte{0}) {
		if len(entry) == 0 {
			continue
		}
		tab := bytes.IndexByte(entry, '\t')
		if tab < 0 {
			return 0, &domain.Error{Code: domain.ErrorCodeInternal, Resource: "Git tree", Message: "tree entry is malformed"}
		}
		fields := strings.Fields(string(entry[:tab]))
		if len(fields) != 4 || fields[1] != "blob" {
			return 0, &domain.Error{
				Code: domain.ErrorCodeInvalidArgument, Op: "snapshot", Resource: string(entry[tab+1:]),
				Message: "nested repositories are unsupported",
			}
		}
		size, err := strconv.ParseUint(fields[3], 10, 64)
		if err != nil || size > limit-total {
			return 0, &domain.Error{
				Code: domain.ErrorCodeBudgetExhausted, Op: "snapshot", Resource: string(entry[tab+1:]),
				Message: "snapshot byte limit exceeded", Err: err,
			}
		}
		total += size
	}
	return total, nil
}

func snapshotTreeID(digest string) (string, error) {
	parts := strings.Split(digest, ":")
	if len(parts) != 3 || parts[0] != "git" || (parts[1] != "sha1" && parts[1] != "sha256") {
		return "", &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "materialize", Resource: digest,
			Message: "snapshot tree digest is unsupported",
		}
	}
	return parts[2], nil
}

func validateArtifactRequest(request ArtifactRequest) error {
	if err := request.ID.Validate(); err != nil {
		return err
	}
	if err := request.NodeRunID.Validate(); err != nil {
		return err
	}
	if err := request.SnapshotID.Validate(); err != nil {
		return err
	}
	if request.BaseSnapshotID != nil {
		if err := request.BaseSnapshotID.Validate(); err != nil {
			return err
		}
	}
	if !validRelativePath(request.Path) {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "resolve", Resource: request.Path,
			Message: "artifact path must be relative",
		}
	}
	return nil
}

func validRelativePath(path string) bool {
	return path != "" && utf8.ValidString(path) && !filepath.IsAbs(path) &&
		filepath.Clean(path) == path && path != "." && path != ".." &&
		!strings.HasPrefix(path, ".."+string(os.PathSeparator))
}

func pathWithinScopes(path string, scopes []string) bool {
	for _, scope := range scopes {
		if scope == "." || path == scope || strings.HasPrefix(path, scope+string(os.PathSeparator)) {
			return true
		}
	}
	return false
}

func digestArtifactDescriptor(root string, relative string, limit uint64) (string, uint64, error) {
	rootDescriptor, err := unix.Open(root, unix.O_RDONLY|unix.O_CLOEXEC|unix.O_NOFOLLOW|unix.O_DIRECTORY, 0)
	if err != nil {
		return "", 0, wrap("open snapshot root", root, err)
	}
	parts := strings.Split(relative, string(os.PathSeparator))
	parentDescriptor := rootDescriptor
	for _, part := range parts[:len(parts)-1] {
		next, openErr := unix.Openat(
			parentDescriptor, part,
			unix.O_RDONLY|unix.O_CLOEXEC|unix.O_NOFOLLOW|unix.O_NONBLOCK|unix.O_DIRECTORY, 0,
		)
		if openErr != nil {
			if parentDescriptor != rootDescriptor {
				_ = unix.Close(parentDescriptor)
			}
			_ = unix.Close(rootDescriptor)
			return "", 0, &domain.Error{
				Code: domain.ErrorCodeUnauthorized, Op: "resolve", Resource: relative,
				Message: "artifact path contains an unavailable or symbolic component", Err: openErr,
			}
		}
		if parentDescriptor != rootDescriptor {
			_ = unix.Close(parentDescriptor)
		}
		parentDescriptor = next
	}
	name := parts[len(parts)-1]
	descriptor, err := unix.Openat(
		parentDescriptor, name, unix.O_RDONLY|unix.O_CLOEXEC|unix.O_NOFOLLOW|unix.O_NONBLOCK, 0,
	)
	if err != nil {
		if parentDescriptor != rootDescriptor {
			_ = unix.Close(parentDescriptor)
		}
		_ = unix.Close(rootDescriptor)
		return "", 0, &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "resolve", Resource: relative,
			Message: "artifact path contains an unavailable or symbolic component", Err: err,
		}
	}
	var before unix.Stat_t
	if err := unix.Fstat(descriptor, &before); err != nil {
		_ = unix.Close(descriptor)
		if parentDescriptor != rootDescriptor {
			_ = unix.Close(parentDescriptor)
		}
		_ = unix.Close(rootDescriptor)
		return "", 0, wrap("inspect artifact descriptor", relative, err)
	}
	if before.Mode&unix.S_IFMT != unix.S_IFREG || before.Size < 0 || uint64(before.Size) > limit {
		_ = unix.Close(descriptor)
		if parentDescriptor != rootDescriptor {
			_ = unix.Close(parentDescriptor)
		}
		_ = unix.Close(rootDescriptor)
		return "", 0, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "resolve", Resource: relative,
			Message: "artifact is not a bounded regular file",
		}
	}
	file := os.NewFile(uintptr(descriptor), relative)
	hash := sha256.New()
	if _, err := io.Copy(hash, io.LimitReader(file, int64(limit)+1)); err != nil {
		file.Close()
		if parentDescriptor != rootDescriptor {
			_ = unix.Close(parentDescriptor)
		}
		_ = unix.Close(rootDescriptor)
		return "", 0, wrap("digest artifact descriptor", relative, err)
	}
	var after unix.Stat_t
	var pathState unix.Stat_t
	stateErr := unix.Fstat(descriptor, &after)
	pathErr := unix.Fstatat(parentDescriptor, name, &pathState, unix.AT_SYMLINK_NOFOLLOW)
	closeErr := file.Close()
	if parentDescriptor != rootDescriptor {
		closeErr = errors.Join(closeErr, unix.Close(parentDescriptor))
	}
	closeErr = errors.Join(closeErr, unix.Close(rootDescriptor))
	if err := errors.Join(stateErr, pathErr, closeErr); err != nil {
		return "", 0, wrap("close artifact descriptor", relative, err)
	}
	if before.Dev != after.Dev || before.Ino != after.Ino || before.Size != after.Size ||
		before.Dev != pathState.Dev || before.Ino != pathState.Ino || pathState.Mode&unix.S_IFMT != unix.S_IFREG {
		return "", 0, &domain.Error{
			Code: domain.ErrorCodeConflict, Op: "resolve", Resource: relative,
			Message: "artifact path changed during descriptor resolution",
		}
	}
	return fmt.Sprintf("sha256:%x", hash.Sum(nil)), uint64(before.Size), nil
}

func parseChangedPaths(output []byte) ([]string, error) {
	paths := make([]string, 0)
	for _, value := range bytes.Split(output, []byte{0}) {
		if len(value) == 0 {
			continue
		}
		path := string(value)
		if !validRelativePath(path) {
			return nil, &domain.Error{
				Code: domain.ErrorCodeInternal, Op: "diff", Resource: path,
				Message: "Git returned an invalid changed path",
			}
		}
		paths = append(paths, path)
	}
	return paths, nil
}

func snapshotReferenceID(snapshotID domain.SnapshotID, owner domain.ResourceReference) string {
	digest := sha256.Sum256([]byte(string(snapshotID) + "\x00" + owner.Kind + "\x00" + owner.ID))
	return string(snapshotID) + ":" + fmt.Sprintf("%x", digest[:16])
}

func snapshotGitReference(snapshotID domain.SnapshotID) string {
	digest := sha256.Sum256([]byte(snapshotID))
	return fmt.Sprintf("refs/colchis/snapshots/%x", digest[:])
}
