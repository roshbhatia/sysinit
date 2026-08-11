## Why

The API currently has no authentication. All endpoints are open, which means any caller can read or write data. We need a token-based auth layer before the beta launch.

## What Changes

- Add JWT verification middleware to all API routes
- Add a `/auth/token` endpoint that exchanges credentials for a signed JWT
- Reject unauthenticated requests with a 401 before they reach handler logic
- Add integration tests covering the auth flow end-to-end

## Capabilities

### New Capabilities
- `auth-service`: Issues and validates JWTs for API callers. Exposes `/auth/token` (POST) and a verification middleware.

### Modified Capabilities
- `api-gateway`: Adds the auth middleware as the first handler in the chain for all non-public routes.

## Impact

- **New code:** `internal/auth/` (JWT issuance + verification), `internal/middleware/auth.go`
- **Modified code:** `cmd/api/main.go` (wire middleware), route handler tests
- **Dependencies:** `github.com/golang-jwt/jwt/v5` (JWT)
- **Impactful/irreversible actions:** deploying the middleware blocks all unauthenticated callers immediately — roll back is a revert-and-redeploy (minutes, not instant). Gate this behind the staging verification task.
