## 1. Foundation

- [x] 1.1 Add `github.com/golang-jwt/jwt/v5` to go.mod
- [x] 1.2 Implement `internal/auth`: token issuance (HS256, configurable secret + TTL) and verification
- [x] 1.3 verify: `go test ./internal/auth/...` green with unit tests covering valid, expired, and tampered tokens
- [ ] 1.4 Implement `internal/middleware/auth.go`: extract Bearer token, verify, pass claims in context; return 401 on failure

## 2. API Integration

- [ ] 2.1 Add `/auth/token` POST endpoint to `cmd/api/main.go` (accepts credentials, returns signed JWT)
- [ ] 2.2 Wire auth middleware into the route chain for all non-public routes
- [ ] 2.3 verify: integration tests cover authenticated request (200), missing token (401), expired token (401), tampered token (401)

## 3. Rollout

- [ ] 3.1 verify: deploy to staging; run the full integration suite against a live staging instance
- [ ] 3.2 apply: deploy to production (impactful — blocks all unauthenticated callers immediately)
- [ ] 3.3 confirm: tail production logs for 5 minutes; verify 401 rate matches expected pre-auth traffic; no authenticated requests rejected
