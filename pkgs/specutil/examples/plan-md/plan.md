## Why

The billing service currently has no retry logic for failed Stripe charges. When a charge fails transiently (e.g., network timeout, Stripe 5xx), the user sees an immediate failure email and must re-enter payment details. We need automatic retry with exponential backoff before surfacing the error to the user.

## What Changes

- Add a retry queue (Redis-backed) for failed charge attempts
- Implement exponential backoff: 1h, 6h, 24h windows before final failure
- Send retry status emails ("we're trying again") instead of immediate failure
- Add an admin endpoint to manually trigger a retry or mark as failed

## Capabilities

### New Capabilities
- `billing.retry-queue`: Enqueues failed charges for background retry. Tracks attempt count, next-attempt timestamp, and last error.
- `billing.retry-worker`: Background worker that polls the queue and re-attempts charges within their backoff windows.

### Modified Capabilities
- `billing.charge`: On transient failure, enqueue for retry instead of returning an error to the caller.
- `notifications.billing`: Add "retry scheduled" and "retry succeeded" email templates.

## Impact

- **New code:** `internal/billing/retry/`, `internal/billing/worker/`
- **Modified code:** `internal/billing/charge.go`, `internal/notifications/billing.go`
- **New infrastructure:** Redis instance (or use existing; check with platform team)
- **Impactful/irreversible actions:** Worker deployment starts consuming the retry queue immediately. Stage behind a feature flag; enable flag after staging verification.

## Phases

### 1. Retry Queue

- [x] 1.1 Decide storage backend — Redis sorted set keyed by next-attempt timestamp
- [x] 1.2 Implement `internal/billing/retry/queue.go`: Enqueue, Dequeue (due items only), Cancel
- [x] 1.3 Unit tests: enqueue, dequeue ordering, cancel removes item
- [ ] 1.4 Integrate: call `retry.Enqueue` from `billing.Charge` on transient error

### 2. Worker

- [ ] 2.1 Implement `internal/billing/worker/worker.go`: poll loop, re-attempt charge, update attempt count
- [ ] 2.2 Backoff schedule: retry after 1h, 6h, 24h; mark failed after 3 attempts
- [ ] 2.3 Integration test: inject mock Stripe that fails twice then succeeds; verify final success
- [ ] 2.4 Wire worker startup into `cmd/billing/main.go`

### 3. Notifications

- [ ] 3.1 Add "retry scheduled" email template to `internal/notifications/billing.go`
- [ ] 3.2 Add "retry succeeded" and "charge finally failed" email templates
- [ ] 3.3 Call notification from worker on each retry attempt and final outcome

### 4. Admin

- [ ] 4.1 Add `POST /admin/billing/retry/:charge_id` endpoint
- [ ] 4.2 Add `POST /admin/billing/fail/:charge_id` endpoint (marks as permanently failed, triggers failure notification)
- [ ] 4.3 Auth: require admin role (enforced by existing admin middleware)

### 5. Rollout

- [ ] 5.1 Deploy to staging behind feature flag `billing.retry`
- [ ] 5.2 Run integration suite; manually trigger a test retry via admin endpoint
- [ ] 5.3 Enable flag in production; monitor retry queue depth and charge success rate for 1 hour
