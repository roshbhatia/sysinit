## ADDED Requirements

### Requirement: token-issuance

Callers POST credentials to `/auth/token` and receive a signed JWT on success.

#### Scenario: valid credentials

- Given a POST to `/auth/token` with valid `username` and `password`
- When the server verifies the credentials against the user store
- Then it returns HTTP 200 with `{"token": "<signed-jwt>", "expires_in": <seconds>}`

#### Scenario: invalid credentials

- Given a POST to `/auth/token` with an unrecognized username or wrong password
- When the server checks the credentials
- Then it returns HTTP 401 with no token in the body

### Requirement: token-verification

All non-public API routes reject requests that carry no valid token.

#### Scenario: authenticated request

- Given a GET to `/api/items` with `Authorization: Bearer <valid-token>`
- When the middleware verifies the token signature and expiry
- Then the request proceeds to the route handler and returns 200

#### Scenario: missing token

- Given a GET to `/api/items` with no Authorization header
- When the middleware processes the request
- Then it returns HTTP 401 before the handler runs

#### Scenario: expired token

- Given a GET to `/api/items` with `Authorization: Bearer <expired-token>`
- When the middleware verifies the token
- Then it returns HTTP 401 with a body indicating the token has expired
