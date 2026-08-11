## 1. Implementation

- [ ] 1.1 Implement `internal/user` store: `Get(id)` and `Update(id, fields)` backed by the existing DB layer
- [ ] 1.2 Implement `GET /users/me`: extract caller ID from JWT claims in context, return profile JSON
- [ ] 1.3 Implement `PUT /users/me`: validate and apply allowed field updates (name, email only)
- [ ] 1.4 verify: unit tests for the user store; integration tests for both endpoints (auth required, update validation)

## 2. Rollout

- [ ] 2.1 verify: `add-auth-layer` is deployed and active in staging before proceeding
- [ ] 2.2 apply: deploy `user-profile-api` to staging; smoke test both endpoints with a valid token
- [ ] 2.3 apply: deploy to production
- [ ] 2.4 confirm: verify `GET /users/me` returns correct profile for a known test account
