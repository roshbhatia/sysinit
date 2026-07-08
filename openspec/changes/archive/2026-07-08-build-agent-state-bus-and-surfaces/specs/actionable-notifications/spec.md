## ADDED Requirements

### Requirement: Present Accept/Deny actions on permission notifications

On the permission/waiting notification path, the notifier SHALL use `alerter`
(vjeantet/alerter) instead of `terminal-notifier` so the notification presents
actionable **Accept** and **Deny** buttons and blocks until the user chooses,
reporting the choice on stdout. The alert SHALL carry the per-harness custom
icon (`-appIcon`/`-contentImage`), a per-session `-group` so repeated alerts
for one session collapse, a `-subtitle` naming the repo·session, and a `-sound`.
The blocking alert MUST run detached from the harness hook so the hook returns
immediately and the agent turn is never stalled by the notification.

#### Scenario: Permission event shows Accept/Deny

- **WHEN** an agent emits a permission/waiting notification
- **THEN** an `alerter` alert appears with Accept and Deny actions, the harness
  icon, and a repo·session subtitle
- **AND** the harness hook that fired it has already returned (the alert runs
  detached)

#### Scenario: Non-actionable events keep plain notifications

- **WHEN** a `done`/informational event fires (no decision to make)
- **THEN** a plain notification is shown without Accept/Deny actions

#### Scenario: alerter unavailable degrades to a plain notification

- **WHEN** the `alerter` binary is missing or fails to launch
- **THEN** the notifier falls back to a plain notification (or no-op) and exits 0
- **AND** the agent turn is unaffected

### Requirement: Relay the decision back into the agent pane

When the user chooses an action, a detached waiter SHALL relay the decision into
the exact agent pane via `wezterm cli send-text` using per-agent approve/reject
keystrokes: Accept sends the harness's approve input, Deny sends its reject
input. The relay SHALL target the pane recorded for that notification and SHALL
be best-effort — a missing pane, unknown agent mapping, dismissed alert, or
alert timeout MUST leave the agent in its current waiting state without error.

#### Scenario: Accept approves in the pane

- **WHEN** the user clicks Accept on a Claude permission alert
- **THEN** the waiter sends Claude's approve keystroke to that pane via
  `wezterm cli send-text`

#### Scenario: Deny rejects in the pane

- **WHEN** the user clicks Deny
- **THEN** the waiter sends the agent's reject keystroke to that pane

#### Scenario: Dismissal or timeout relays nothing

- **WHEN** the alert is dismissed, times out, or the user takes no action
- **THEN** no keystroke is sent and the agent remains waiting
- **AND** the waiter exits 0

#### Scenario: Closed target pane is a safe no-op

- **WHEN** the recorded pane has closed before the user chooses
- **THEN** the relay attempt fails gracefully and surfaces no error

### Requirement: Gate the relay behind a toggle

Keystroke relay into a live agent TUI SHALL be controlled by a single config
toggle acting as the kill switch. When the toggle is off, notifications MAY
still show but SHALL NOT inject keystrokes; disabling the toggle SHALL restore
click-to-focus-only behavior with no relay.

#### Scenario: Toggle off disables keystroke injection

- **WHEN** the relay toggle is disabled
- **THEN** notifications do not inject any keystrokes into any pane
- **AND** the prior click-to-focus behavior is preserved

#### Scenario: Toggle is per-agent-safe

- **WHEN** an agent has no defined approve/reject keystroke mapping
- **THEN** the relay is skipped for that agent even when the toggle is on
- **AND** no keystroke is sent
