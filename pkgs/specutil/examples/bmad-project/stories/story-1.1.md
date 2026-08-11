# Story 1.1: Add User Authentication

**Status:** In Progress

## Story

As a developer using the platform API, I want to authenticate with a JWT token so that I can make authorized requests without sharing credentials on every call.

## Acceptance Criteria

- [ ] `POST /auth/token` accepts `{email, password}` and returns a signed JWT
- [x] Invalid credentials return a `401` with a machine-readable error body
- [ ] All non-public endpoints reject requests missing a valid token with `401`
- [ ] Tokens expire after 24 hours; clients must re-authenticate
- [ ] Auth middleware propagates caller identity into request context for downstream handlers

## Tasks

### Phase 1: Token Issuance

- [x] 1.1 Add `github.com/golang-jwt/jwt/v5` to `go.mod`
- [x] 1.2 Implement `internal/auth/issue.go`: HS256 signing with configurable secret and TTL
- [x] 1.3 Write unit tests: valid token, expired token, tampered token
- [ ] 1.4 Implement `POST /auth/token` endpoint in `cmd/api/main.go`

### Phase 2: Middleware

- [ ] 2.1 Implement `internal/middleware/auth.go`: extract Bearer header, verify, inject claims
- [ ] 2.2 Wire middleware into the route chain before all protected handlers
- [ ] 2.3 Integration tests: authenticated (200), missing token (401), expired (401)

### Phase 3: Rollout

- [ ] 3.1 Deploy to staging; run full integration suite
- [ ] 3.2 Verify staging 401 rate matches baseline unauthenticated traffic
- [ ] 3.3 Deploy to production — monitor for 10 minutes post-deploy

## Dev Notes

Use HS256 with a secret loaded from `AUTH_SECRET` env var. Do not hard-code defaults in production paths.
