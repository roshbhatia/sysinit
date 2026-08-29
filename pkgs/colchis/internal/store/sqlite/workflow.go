package sqlite

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
)

const (
	workflowDefinitionRecordKind = "workflow-definition"
	workflowRunRecordKind        = "workflow-run"
	nodeRunRecordKind            = "node-run"
)

type AdapterCapacity map[string]uint32

func (store *Store) WorkflowRuns(ctx context.Context) ([]domain.WorkflowRun, error) {
	var runs []domain.WorkflowRun
	err := store.Transaction(ctx, func(transaction *Tx) error {
		var err error
		runs, err = typedRecords[domain.WorkflowRun](transaction, ctx, workflowRunRecordKind)
		return err
	})
	sort.Slice(runs, func(first int, second int) bool {
		return runs[first].Metadata.UpdatedAt.After(runs[second].Metadata.UpdatedAt)
	})
	return runs, err
}

func (store *Store) CreateWorkflowDefinition(
	ctx context.Context,
	id domain.WorkflowDefinitionID,
	predecessorID *domain.WorkflowDefinitionID,
	document json.RawMessage,
	resolved workflowmodel.ResolvedDefinition,
) (domain.WorkflowDefinition, error) {
	if err := id.Validate(); err != nil {
		return domain.WorkflowDefinition{}, err
	}
	if !json.Valid(document) || !json.Valid(resolved.Document) {
		return domain.WorkflowDefinition{}, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "create", Resource: string(id),
			Message: "workflow document is not valid JSON",
		}
	}
	if err := resolved.Validate(); err != nil {
		return domain.WorkflowDefinition{}, err
	}
	if resolved.Definition.SchemaVersion != workflowmodel.DefinitionSchemaVersion ||
		resolved.Definition.EvaluatorVersion != workflowmodel.EvaluatorVersion {
		return domain.WorkflowDefinition{}, &domain.Error{
			Code: domain.ErrorCodeUnsupportedVersion, Op: "create", Resource: string(id),
			Message: "resolved workflow version is unsupported",
		}
	}

	var created domain.WorkflowDefinition
	err := store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := transaction.workflowDefinition(ctx, id); err != nil {
			return err
		} else if found {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "create", Resource: string(id),
				Message: "workflow definition already exists",
			}
		}
		version := uint64(1)
		if predecessorID != nil {
			if err := predecessorID.Validate(); err != nil {
				return err
			}
			predecessor, found, err := transaction.workflowDefinition(ctx, *predecessorID)
			if err != nil {
				return err
			}
			if !found {
				return &domain.Error{
					Code: domain.ErrorCodeNotFound, Op: "create", Resource: string(*predecessorID),
					Message: "predecessor workflow definition does not exist",
				}
			}
			if predecessor.DefinitionVersion == ^uint64(0) {
				return &domain.Error{
					Code: domain.ErrorCodeConflict, Op: "create", Resource: string(*predecessorID),
					Message: "workflow definition version is exhausted",
				}
			}
			version = predecessor.DefinitionVersion + 1
		}
		now := time.Now().UTC()
		created = domain.WorkflowDefinition{
			Metadata: domain.RecordMetadata{
				SchemaVersion: domain.CurrentRecordSchemaVersion, ResourceVersion: 1,
				CreatedAt: now, UpdatedAt: now,
			},
			ID: id, PredecessorID: predecessorID, DefinitionVersion: version,
			DefinitionSchemaVersion: resolved.Definition.SchemaVersion,
			DefinitionDigest:        resolved.DefinitionDigest, SchemaDigest: resolved.SchemaDigest,
			EvaluatorVersion: resolved.Definition.EvaluatorVersion,
			Document:         append(json.RawMessage(nil), document...),
			ResolvedDocument: append(json.RawMessage(nil), resolved.Document...),
		}
		encoded, err := json.Marshal(created)
		if err != nil {
			return wrap("encode workflow definition", string(id), err)
		}
		if err := transaction.reserveRecordCapacity(ctx, encoded); err != nil {
			return err
		}
		if err := transaction.putRecord(ctx, workflowDefinitionRecordKind, string(id), created.Metadata, encoded); err != nil {
			return err
		}
		payload, err := json.Marshal(struct {
			DefinitionVersion uint64 `json:"definitionVersion"`
			DefinitionDigest  string `json:"definitionDigest"`
		}{DefinitionVersion: version, DefinitionDigest: resolved.DefinitionDigest})
		if err != nil {
			return wrap("encode workflow definition event", string(id), err)
		}
		_, err = transaction.AppendEvent(ctx, domain.EventEnvelope{
			SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
			Aggregate: domain.ResourceReference{Kind: workflowDefinitionRecordKind, ID: string(id)},
			Type:      "workflow.definition.created", Payload: payload,
		})
		return err
	})
	return created, err
}

func (store *Store) WorkflowDefinition(
	ctx context.Context,
	id domain.WorkflowDefinitionID,
) (domain.WorkflowDefinition, error) {
	if err := id.Validate(); err != nil {
		return domain.WorkflowDefinition{}, err
	}
	var definition domain.WorkflowDefinition
	err := store.Transaction(ctx, func(transaction *Tx) error {
		var found bool
		var err error
		definition, found, err = transaction.workflowDefinition(ctx, id)
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "read", Resource: string(id),
				Message: "workflow definition does not exist",
			}
		}
		return nil
	})
	return definition, err
}

func (store *Store) CreateWorkflowRun(
	ctx context.Context,
	id domain.WorkflowRunID,
	definitionID domain.WorkflowDefinitionID,
	orchestrationSession *domain.SessionID,
) (domain.WorkflowRun, []domain.NodeRun, error) {
	if err := id.Validate(); err != nil {
		return domain.WorkflowRun{}, nil, err
	}
	if err := definitionID.Validate(); err != nil {
		return domain.WorkflowRun{}, nil, err
	}
	if orchestrationSession != nil {
		if err := orchestrationSession.Validate(); err != nil {
			return domain.WorkflowRun{}, nil, err
		}
	}

	var created domain.WorkflowRun
	var nodes []domain.NodeRun
	err := store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := transaction.workflowRun(ctx, id); err != nil {
			return err
		} else if found {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "create", Resource: string(id),
				Message: "workflow run already exists",
			}
		}
		definitionRecord, found, err := transaction.workflowDefinition(ctx, definitionID)
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "create", Resource: string(definitionID),
				Message: "workflow definition does not exist",
			}
		}
		definition, err := decodeResolvedDefinition(definitionRecord)
		if err != nil {
			return err
		}
		now := time.Now().UTC()
		created, nodes, err = newWorkflowRunRecords(
			store, id, definitionRecord, definition, orchestrationSession, now,
		)
		if err != nil {
			return err
		}
		createdPayload, err := json.Marshal(created)
		if err != nil {
			return wrap("encode workflow run", string(id), err)
		}
		payloads := make([][]byte, len(nodes))
		totalBytes := uint64(len(createdPayload))
		for index := range nodes {
			payloads[index], err = json.Marshal(nodes[index])
			if err != nil {
				return wrap("encode node run", string(nodes[index].ID), err)
			}
			totalBytes += uint64(len(payloads[index]))
		}
		if err := transaction.reserveRecordBytes(ctx, totalBytes, uint64(len(nodes)+1)); err != nil {
			return err
		}
		if err := transaction.putRecord(ctx, workflowRunRecordKind, string(id), created.Metadata, createdPayload); err != nil {
			return err
		}
		for index := range nodes {
			if err := transaction.putRecord(
				ctx, nodeRunRecordKind, string(nodes[index].ID), nodes[index].Metadata, payloads[index],
			); err != nil {
				return err
			}
		}
		eventPayload, err := json.Marshal(struct {
			DefinitionID domain.WorkflowDefinitionID `json:"workflowDefinitionId"`
			NodeCount    int                         `json:"nodeCount"`
		}{DefinitionID: definitionID, NodeCount: len(nodes)})
		if err != nil {
			return wrap("encode workflow run event", string(id), err)
		}
		_, err = transaction.AppendEvent(ctx, domain.EventEnvelope{
			SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
			Aggregate: domain.ResourceReference{Kind: workflowRunRecordKind, ID: string(id)},
			Type:      "workflow.run.created", Payload: eventPayload,
		})
		return err
	})
	return created, nodes, err
}

func (store *Store) WorkflowRun(
	ctx context.Context,
	id domain.WorkflowRunID,
) (domain.WorkflowRun, []domain.NodeRun, error) {
	if err := id.Validate(); err != nil {
		return domain.WorkflowRun{}, nil, err
	}
	var run domain.WorkflowRun
	var nodes []domain.NodeRun
	err := store.Transaction(ctx, func(transaction *Tx) error {
		var found bool
		var err error
		run, found, err = transaction.workflowRun(ctx, id)
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "read", Resource: string(id),
				Message: "workflow run does not exist",
			}
		}
		nodes, err = transaction.nodeRuns(ctx, &id)
		return err
	})
	return run, nodes, err
}

func (store *Store) ReserveReadyNodes(
	ctx context.Context,
	runID domain.WorkflowRunID,
	adapterCapacity AdapterCapacity,
) ([]domain.NodeRun, error) {
	if err := runID.Validate(); err != nil {
		return nil, err
	}
	reserved := make([]domain.NodeRun, 0)
	err := store.Transaction(ctx, func(transaction *Tx) error {
		run, found, err := transaction.workflowRun(ctx, runID)
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "schedule", Resource: string(runID),
				Message: "workflow run does not exist",
			}
		}
		if run.State != domain.WorkflowRunStatePending && run.State != domain.WorkflowRunStateRunning {
			return nil
		}
		definitionRecord, found, err := transaction.workflowDefinition(ctx, run.WorkflowDefinition)
		if err != nil {
			return err
		}
		if !found || definitionRecord.DefinitionVersion != run.DefinitionVersion {
			return &domain.Error{
				Code: domain.ErrorCodeInternal, Op: "schedule", Resource: string(runID),
				Message: "pinned workflow definition is unavailable",
			}
		}
		definition, err := decodeResolvedDefinition(definitionRecord)
		if err != nil {
			return err
		}
		allNodes, err := transaction.nodeRuns(ctx, nil)
		if err != nil {
			return err
		}
		globalRunning := uint32(0)
		runRunning := uint32(0)
		adapterRunning := make(map[string]uint32)
		var candidates []domain.NodeRun
		for _, node := range allNodes {
			if node.State == domain.NodeRunStateRunning {
				globalRunning++
				adapterRunning[node.Adapter]++
				if node.WorkflowRunID == runID {
					runRunning++
				}
			}
			if node.WorkflowRunID == runID && node.State == domain.NodeRunStateReady {
				candidates = append(candidates, node)
			}
		}
		sort.Slice(candidates, func(first int, second int) bool {
			return candidates[first].NodeKey < candidates[second].NodeKey
		})
		brokerLimit := minUint32(store.budgets.MaxConcurrentNodes, store.budgets.MaxConcurrentProcesses)
		brokerLimit = minUint32(brokerLimit, store.budgets.MaxEventsPerSecond)
		workflowLimit := minUint32(run.Budgets.MaxConcurrentNodes, run.Budgets.MaxConcurrentProcesses)
		if globalRunning >= brokerLimit || runRunning >= workflowLimit {
			return nil
		}
		availableBroker := brokerLimit - globalRunning
		availableWorkflow := workflowLimit - runRunning
		now := time.Now().UTC()
		for _, candidate := range candidates {
			if uint32(len(reserved)) >= availableBroker || uint32(len(reserved)) >= availableWorkflow {
				break
			}
			limit, configured := adapterCapacity[candidate.Adapter]
			if !configured || limit == 0 || adapterRunning[candidate.Adapter] >= limit {
				continue
			}
			nodeDefinition := definition.Nodes[candidate.NodeKey]
			template := definition.Templates[nodeDefinition.Template]
			attemptLimit := minUint32(nodeDefinition.Budget.MaxAttempts, template.MaxAttempts)
			for _, loop := range definition.Loops {
				if _, found := loopNodeKeys(definition, loop)[candidate.NodeKey]; found &&
					loop.IterationLimit > attemptLimit {
					attemptLimit = loop.IterationLimit
				}
			}
			if candidate.Attempt >= attemptLimit {
				if err := transaction.transitionNodeRun(
					ctx, &candidate, domain.NodeRunStateCapped, now,
				); err != nil {
					return err
				}
				continue
			}
			candidate.Attempt++
			if err := transaction.transitionNodeRun(
				ctx, &candidate, domain.NodeRunStateRunning, now,
			); err != nil {
				return err
			}
			adapterRunning[candidate.Adapter]++
			reserved = append(reserved, candidate)
			payload, err := json.Marshal(struct {
				NodeRunID domain.NodeRunID `json:"nodeRunId"`
				NodeKey   domain.NodeKey   `json:"nodeKey"`
				Attempt   uint32           `json:"attempt"`
			}{NodeRunID: candidate.ID, NodeKey: candidate.NodeKey, Attempt: candidate.Attempt})
			if err != nil {
				return wrap("encode node start event", string(candidate.ID), err)
			}
			if _, err := transaction.AppendEvent(ctx, domain.EventEnvelope{
				SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
				Aggregate: domain.ResourceReference{Kind: nodeRunRecordKind, ID: string(candidate.ID)},
				Type:      "workflow.node.started", Payload: payload,
			}); err != nil {
				return err
			}
		}
		if len(reserved) > 0 && run.State == domain.WorkflowRunStatePending {
			run.State = domain.WorkflowRunStateRunning
			run.Metadata.ResourceVersion++
			run.Metadata.UpdatedAt = now
			encoded, err := json.Marshal(run)
			if err != nil {
				return wrap("encode workflow run transition", string(run.ID), err)
			}
			if err := transaction.updateRecord(
				ctx, workflowRunRecordKind, string(run.ID), run.Metadata.ResourceVersion-1, run.Metadata, encoded,
			); err != nil {
				return err
			}
		}
		return nil
	})
	return reserved, err
}

func (store *Store) RecoverUnboundNodeReservations(ctx context.Context) ([]domain.NodeRun, error) {
	var recovered []domain.NodeRun
	err := store.Transaction(ctx, func(transaction *Tx) error {
		nodes, err := transaction.nodeRuns(ctx, nil)
		if err != nil {
			return err
		}
		now := time.Now().UTC()
		for _, node := range nodes {
			if node.State != domain.NodeRunStateRunning || node.SessionID != nil {
				continue
			}
			if node.Attempt == 0 {
				return &domain.Error{
					Code: domain.ErrorCodeInternal, Op: "recover node reservation", Resource: string(node.ID),
					Message: "running node has no reserved attempt",
				}
			}
			node.Attempt--
			if err := transaction.transitionNodeRun(ctx, &node, domain.NodeRunStateReady, now); err != nil {
				return err
			}
			payload, err := json.Marshal(struct {
				NodeRunID domain.NodeRunID `json:"nodeRunId"`
			}{NodeRunID: node.ID})
			if err != nil {
				return wrap("encode recovered node reservation", string(node.ID), err)
			}
			if _, err := transaction.AppendEvent(ctx, domain.EventEnvelope{
				SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
				Aggregate: domain.ResourceReference{Kind: nodeRunRecordKind, ID: string(node.ID)},
				Type:      "workflow.node.reservation-recovered", Payload: payload,
			}); err != nil {
				return err
			}
			recovered = append(recovered, node)
		}
		return nil
	})
	return recovered, err
}

func (transaction *Tx) workflowDefinition(
	ctx context.Context,
	id domain.WorkflowDefinitionID,
) (domain.WorkflowDefinition, bool, error) {
	var definition domain.WorkflowDefinition
	payload, found, err := transaction.recordPayload(ctx, workflowDefinitionRecordKind, string(id))
	if err == nil && found {
		err = json.Unmarshal(payload, &definition)
		if err != nil {
			err = wrap("decode workflow definition", string(id), err)
		}
	}
	return definition, found, err
}

func (transaction *Tx) workflowRun(
	ctx context.Context,
	id domain.WorkflowRunID,
) (domain.WorkflowRun, bool, error) {
	var run domain.WorkflowRun
	payload, found, err := transaction.recordPayload(ctx, workflowRunRecordKind, string(id))
	if err == nil && found {
		err = json.Unmarshal(payload, &run)
		if err != nil {
			err = wrap("decode workflow run", string(id), err)
		}
	}
	return run, found, err
}

func (transaction *Tx) recordPayload(
	ctx context.Context,
	kind string,
	id string,
) ([]byte, bool, error) {
	var payload []byte
	err := transaction.tx.QueryRowContext(
		ctx, "SELECT payload FROM records WHERE kind = ? AND id = ?", kind, id,
	).Scan(&payload)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, false, nil
	}
	if err != nil {
		return nil, false, wrap("read record", kind+":"+id, err)
	}
	return payload, true, nil
}

func (transaction *Tx) nodeRuns(
	ctx context.Context,
	runID *domain.WorkflowRunID,
) ([]domain.NodeRun, error) {
	rows, err := transaction.tx.QueryContext(
		ctx, "SELECT payload FROM records WHERE kind = ? ORDER BY id", nodeRunRecordKind,
	)
	if err != nil {
		return nil, wrap("read node runs", transaction.path, err)
	}
	defer rows.Close()
	result := make([]domain.NodeRun, 0)
	for rows.Next() {
		var payload []byte
		if err := rows.Scan(&payload); err != nil {
			return nil, wrap("scan node run", transaction.path, err)
		}
		var node domain.NodeRun
		if err := json.Unmarshal(payload, &node); err != nil {
			return nil, wrap("decode node run", transaction.path, err)
		}
		if runID == nil || node.WorkflowRunID == *runID {
			result = append(result, node)
		}
	}
	if err := rows.Err(); err != nil {
		return nil, wrap("iterate node runs", transaction.path, err)
	}
	sort.Slice(result, func(first int, second int) bool {
		if result[first].NodeKey == result[second].NodeKey {
			return result[first].ID < result[second].ID
		}
		return result[first].NodeKey < result[second].NodeKey
	})
	return result, nil
}

func (transaction *Tx) transitionNodeRun(
	ctx context.Context,
	node *domain.NodeRun,
	state domain.NodeRunState,
	now time.Time,
) error {
	previousVersion := node.Metadata.ResourceVersion
	node.State = state
	node.Metadata.ResourceVersion++
	node.Metadata.UpdatedAt = now
	encoded, err := json.Marshal(node)
	if err != nil {
		return wrap("encode node run transition", string(node.ID), err)
	}
	return transaction.updateRecord(
		ctx, nodeRunRecordKind, string(node.ID), previousVersion, node.Metadata, encoded,
	)
}

func (transaction *Tx) reserveRecordCapacity(ctx context.Context, payload []byte) error {
	return transaction.reserveRecordBytes(ctx, uint64(len(payload)), 1)
}

func (transaction *Tx) reserveRecordBytes(ctx context.Context, payloadBytes uint64, records uint64) error {
	var pageSize uint64
	if err := transaction.tx.QueryRowContext(ctx, "PRAGMA page_size").Scan(&pageSize); err != nil {
		return wrap("read database page size", transaction.path, err)
	}
	overhead := pageSize * (records + 2)
	if payloadBytes > ^uint64(0)-overhead {
		return &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "write records", Resource: transaction.path,
			Message: "record storage estimate exceeds supported size",
		}
	}
	return transaction.reserveStateCapacity(ctx, payloadBytes+overhead, false)
}

func initialNodeRuns(
	runID domain.WorkflowRunID,
	definitionVersion uint64,
	definition workflowmodel.Definition,
	now time.Time,
) ([]domain.NodeRun, error) {
	backEdges := make(map[domain.EdgeKey]struct{}, len(definition.Loops))
	for _, loop := range definition.Loops {
		backEdges[loop.BackEdge] = struct{}{}
	}
	requiredIncoming := make(map[domain.NodeKey]uint32, len(definition.Nodes))
	for key := range definition.Nodes {
		requiredIncoming[key] = 0
	}
	for _, edge := range definition.Edges {
		if _, backEdge := backEdges[edge.ID]; edge.Required && !backEdge {
			requiredIncoming[edge.To]++
		}
	}
	keys := make([]domain.NodeKey, 0, len(definition.Nodes))
	for key := range definition.Nodes {
		keys = append(keys, key)
	}
	sort.Slice(keys, func(first int, second int) bool { return keys[first] < keys[second] })
	result := make([]domain.NodeRun, 0, len(keys))
	for _, key := range keys {
		node := definition.Nodes[key]
		digest, err := nodeDefinitionDigest(node, definition.Templates[node.Template])
		if err != nil {
			return nil, err
		}
		state := domain.NodeRunStatePending
		if requiredIncoming[key] == 0 {
			state = domain.NodeRunStateReady
		}
		result = append(result, domain.NodeRun{
			Metadata: domain.RecordMetadata{
				SchemaVersion: domain.CurrentRecordSchemaVersion, ResourceVersion: 1,
				CreatedAt: now, UpdatedAt: now,
			},
			ID: nodeRunID(runID, key), WorkflowRunID: runID, DefinitionVersion: definitionVersion, NodeKey: key,
			NodeDefinitionDigest: digest, Adapter: node.Adapter, State: state,
		})
	}
	return result, nil
}

func nodeDefinitionDigest(node workflowmodel.Node, template workflowmodel.Template) (string, error) {
	encoded, err := json.Marshal(struct {
		Node     workflowmodel.Node     `json:"node"`
		Template workflowmodel.Template `json:"template"`
	}{Node: node, Template: template})
	if err != nil {
		return "", wrap("encode node definition", string(node.Template), err)
	}
	digest := sha256.Sum256(encoded)
	return fmt.Sprintf("sha256:%x", digest), nil
}

func nodeRunID(runID domain.WorkflowRunID, key domain.NodeKey) domain.NodeRunID {
	digest := sha256.Sum256([]byte(string(runID) + "\x00" + string(key)))
	return domain.NodeRunID(fmt.Sprintf("node-%x", digest))
}

func decodeResolvedDefinition(record domain.WorkflowDefinition) (workflowmodel.Definition, error) {
	current := record.DefinitionSchemaVersion == workflowmodel.DefinitionSchemaVersion &&
		record.EvaluatorVersion == workflowmodel.EvaluatorVersion
	legacy := record.DefinitionSchemaVersion == workflowmodel.LegacyDefinitionSchemaVersion &&
		record.EvaluatorVersion == workflowmodel.LegacyEvaluatorVersion
	if !current && !legacy {
		return workflowmodel.Definition{}, &domain.Error{
			Code: domain.ErrorCodeUnsupportedVersion, Op: "decode", Resource: string(record.ID),
			Message: "pinned workflow semantics are unavailable",
		}
	}
	digest := sha256.Sum256(record.ResolvedDocument)
	if record.DefinitionDigest != fmt.Sprintf("sha256:%x", digest) {
		return workflowmodel.Definition{}, &domain.Error{
			Code: domain.ErrorCodeInternal, Op: "decode", Resource: string(record.ID),
			Message: "resolved workflow definition digest does not match",
		}
	}
	var definition workflowmodel.Definition
	if err := json.Unmarshal(record.ResolvedDocument, &definition); err != nil {
		return workflowmodel.Definition{}, wrap("decode resolved workflow definition", string(record.ID), err)
	}
	if legacy {
		if err := workflowmodel.UpgradeLegacyDefinition(
			record.DefinitionSchemaVersion, record.EvaluatorVersion, &definition,
		); err != nil {
			return workflowmodel.Definition{}, err
		}
	}
	for _, node := range definition.Nodes {
		if err := node.Policy.Validate(); err != nil {
			return workflowmodel.Definition{}, err
		}
	}
	return definition, nil
}

func minUint32(first uint32, second uint32) uint32 {
	if first < second {
		return first
	}
	return second
}

func minUint64(first uint64, second uint64) uint64 {
	if first < second {
		return first
	}
	return second
}
