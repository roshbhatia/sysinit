## Why

Authenticated users need to view and update their own profile data. This requires the auth layer (`add-auth-layer`) to land first so that the profile endpoints can identify the caller from the verified JWT claims.

## What Changes

- Add `GET /users/me` and `PUT /users/me` endpoints that read the caller identity from the verified JWT
- Add a `User` store backed by the existing database layer

## Capabilities

### New Capabilities
- `user-profile`: Exposes `GET /users/me` (read profile) and `PUT /users/me` (update name/email). Requires a valid JWT; extracts the caller ID from claims.

## Impact

- **New code:** `internal/user/` (store + handler), routes wired in `cmd/api/main.go`
- **Dependencies on other changes:** `add-auth-layer` must be deployed first (auth middleware must be active so claims are available in context)
- **Impactful/irreversible actions:** none — additive endpoints with no destructive side effects
