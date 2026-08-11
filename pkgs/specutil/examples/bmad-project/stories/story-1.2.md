# Story 1.2: User Profile API

**Status:** Draft

## Story

As an authenticated user, I want to fetch and update my profile information so that I can keep my account details current without going through support.

## Acceptance Criteria

- [ ] `GET /users/me` returns the current user's profile (name, email, created_at)
- [ ] `PATCH /users/me` accepts partial updates to name; email changes require re-verification
- [ ] Profile endpoints require a valid JWT (enforced by auth middleware from Story 1.1)
- [ ] Responses follow the standard `{data, error}` envelope used by the rest of the API

## Tasks

### Phase 1: Read

- [ ] 1.1 Add `GET /users/me` handler; return profile from DB
- [ ] 1.2 Unit test: authenticated request returns profile; unauthenticated returns 401 (via middleware)

### Phase 2: Write

- [ ] 2.1 Add `PATCH /users/me` handler; validate and persist name updates
- [ ] 2.2 Block email changes at the handler level with a clear error (email change flow is out of scope)
- [ ] 2.3 Unit tests: valid update, invalid payload (400), unauthorized (401)

## Dev Notes

Profile data lives in the `users` table; no new tables needed. Caller identity comes from the JWT claims injected by the auth middleware — do not re-read the token in the handler.
