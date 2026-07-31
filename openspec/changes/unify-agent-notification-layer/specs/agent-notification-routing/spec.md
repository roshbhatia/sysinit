## ADDED Requirements

### Requirement: One producer owns the desktop toast

Exactly one component SHALL raise a desktop notification for an agent
lifecycle event. That component is `agent-notify`, reached directly or through
`agent-prompt`. Every other notification producer that this repository
configures MUST be turned off in the layer that configures it.

The producers that MUST be turned off are the agent-deck WezTerm plugin's
`notifications` block, OpenCode's `attention.notifications`, and the vendored
pi `notify.ts` extension.

Turning a producer off MUST NOT disable the signal it fed. Agent-deck's status
scraping stays on, because the statusline uses it as the fallback for a harness
that emits no lifecycle state.

A producer for one harness MUST NOT be turned off before that harness is in the
bridged set. Turning off pi's extension or OpenCode's `attention` before its
bridge lands would leave that harness with no producer at all, which is a
regression, not a step toward one producer. The two edits MUST ship together.

#### Scenario: A single toast per wait

- **POLARITY** positive
- **WHEN** a configured harness reaches a state that warrants a notification
- **THEN** exactly one desktop notification is raised
- **AND** it is raised by `agent-notify` or `agent-prompt`

#### Scenario: A second producer is reintroduced

- **POLARITY** negative
- **WHEN** a contributor re-enables agent-deck notifications, OpenCode
  `attention.notifications`, or pi `notify.ts`
- **THEN** the build fails and names the reintroduced producer
- **AND** the failure message names `agent-notify` as the owning producer

#### Scenario: A producer is turned off with no bridge in place

- **POLARITY** negative
- **WHEN** a harness's own producer is turned off while that harness is not in
  the bridged set
- **THEN** the build fails and names the harness
- **AND** the harness is not left with zero producers on the live machine

#### Scenario: Scraping survives the notification cut

- **POLARITY** negative
- **WHEN** agent-deck notifications are turned off
- **THEN** agent-deck still reports a scraped status for a hookless pane
- **AND** the statusline still shows that pane's status

### Requirement: Every configured harness reaches the notifier

Each harness this repository configures SHALL be recorded in one coverage set
in `notify.nix`, in exactly one of three states.

Bridged: the harness reaches `agent-notify` through the mechanism it exposes. A
harness with a lifecycle hook system uses a hook. A harness with an extension or
plugin system uses a repository-authored extension or plugin.

Deferred: the harness exposes a hook, extension, or plugin surface, but the
wiring is not done. The record MUST name the surface it exposes and the change
that will wire it. Gemini and devin are deferred, not surfaceless: both already
render a `PreToolUse` hook file today.

No surface: the harness exposes no hook, extension, or plugin mechanism at all.
The record MUST state the reason.

A configured harness in none of the three sets MUST fail the build. An icon
fetched for a harness in none of the three sets is also a defect, because it
implies a coverage that does not exist.

The bridged state MUST be derived from the bridge artifact, not from a
hand-written label. A guard that reads the label alone is defeated by editing
the label, which is the same file a contributor edits to turn a producer off.

Pi SHALL reach the notifier through a repository-authored extension installed
at `~/.pi/agent/extensions/`. OpenCode SHALL reach it through a
repository-authored plugin.

The bridge MUST call the same executables the hooked harnesses call. It MUST
NOT reimplement classification, dedup, or identity resolution.

#### Scenario: Pi raises the shared toast

- **POLARITY** positive
- **WHEN** a pi session settles, meaning no retry, compaction, or queued
  follow-up remains
- **THEN** the pi extension invokes `agent-notify pi done`
- **AND** the toast carries the pi icon and the session context

#### Scenario: A pi run that is not settled raises nothing

- **POLARITY** negative
- **WHEN** a pi agent run ends but pi will auto-retry, auto-compact, or run a
  queued follow-up
- **THEN** no done notification is raised
- **AND** no done state is written for that pane

#### Scenario: OpenCode raises the shared toast

- **POLARITY** positive
- **WHEN** an OpenCode session goes idle and a plugin event for that
  transition is reachable
- **THEN** the OpenCode plugin invokes `agent-notify opencode idle`

#### Scenario: An unreachable plugin event leaves OpenCode deferred

- **POLARITY** negative
- **WHEN** the spike finds no plugin event a repository-authored plugin can
  subscribe to
- **THEN** OpenCode stays in the deferred set with its own producer left on
- **AND** no requirement asserts a bridge that does not exist

#### Scenario: A bridge failure never breaks the session

- **POLARITY** negative
- **WHEN** `agent-notify` is absent from PATH or exits non-zero
- **THEN** the pi extension and the OpenCode plugin swallow the failure
- **AND** the agent turn completes unaffected

#### Scenario: A surfaceless harness is declared

- **POLARITY** negative
- **WHEN** a configured harness exposes no hook, extension, or plugin surface
- **THEN** `notify.nix` records it as no-surface with a stated reason
- **AND** the build does not silently omit it

#### Scenario: A harness with a hook is deferred, not called surfaceless

- **POLARITY** negative
- **WHEN** a configured harness renders a hook file but has no notifier wiring
- **THEN** it is recorded as deferred, naming its surface and the change that
  will wire it
- **AND** recording it as no-surface fails the build, because the claim is
  false

#### Scenario: A harness in no set fails the build

- **POLARITY** negative
- **WHEN** a configured harness appears in neither the bridged, deferred, nor
  no-surface set
- **THEN** the build fails and names the harness

### Requirement: A notification is dismissible and actionable

A notification group name SHALL identify the pane that raised it, not the
agent-and-context pair. One pane SHALL own one notification slot, so a repeat
from that pane replaces the pending one and a dismiss from any handler matches.

The pane id is not always available. `WEZTERM_PANE` is not forwarded over ssh,
and the notifier runs anyway, because only the state emitter requires a pane.
When the pane id is empty, the group and the suppression key SHALL fall back to
the agent-and-context pair. Keying an empty pane id would collapse every
paneless session onto one slot, which is worse than the behavior this
requirement replaces.

Clicking the body of any notification SHALL raise the pane that produced it.
This applies to the approval notification raised by `agent-prompt` as well as
to the plain notification raised by `agent-notify`.

#### Scenario: Clicking an approval toast raises the pane

- **POLARITY** positive
- **WHEN** the human clicks the body of an approval notification
- **THEN** `agent-focus` runs for the originating pane
- **AND** WezTerm activates that pane

#### Scenario: A handler dismisses the toast it raised

- **POLARITY** positive
- **WHEN** `agent-focus` runs for a pane that has a pending notification
- **THEN** the pending notification for that pane is removed

#### Scenario: A group mismatch cannot silently skip the dismiss

- **POLARITY** negative
- **WHEN** the group name written by a producer does not match the name a
  handler removes
- **THEN** a check fails and names both strings
- **AND** the mismatch is not discoverable only at runtime

### Requirement: Suppression is scoped to the pane

Repeat suppression for a non-actionable notification SHALL be keyed on the
pane that raised it. Suppression MUST NOT be keyed on the harness name alone.

#### Scenario: Two panes of one harness both notify

- **POLARITY** positive
- **WHEN** two panes running the same harness both go idle inside one
  suppression window
- **THEN** both panes raise a notification

#### Scenario: One pane repeating is still suppressed

- **POLARITY** negative
- **WHEN** one pane goes idle twice inside the suppression window
- **THEN** the second notification is suppressed

#### Scenario: Two paneless sessions do not collapse onto one slot

- **POLARITY** negative
- **WHEN** two agents run over ssh, where `WEZTERM_PANE` is not forwarded, and
  both go idle inside the suppression window
- **THEN** both raise a notification, keyed on the agent-and-context pair
- **AND** neither replaces the other's notification slot

### Requirement: Each harness has its own icon

The notifier SHALL install one icon per configured harness. The generic
fallback icon MUST be visually distinct from every harness icon, so an
unrecognized agent is never mistaken for a recognized one.

Icon sources are fetched by pinned hash, following the existing block in
`notify.nix`. A harness with no available brand asset uses the generic icon and
is listed in `notify.nix` as intentionally generic.

#### Scenario: A configured harness renders its own glyph

- **POLARITY** positive
- **WHEN** a notification is raised for opencode, pi, amp, crush, goose, or
  copilot
- **THEN** the notification carries that harness's icon

#### Scenario: The fallback is not a harness glyph

- **POLARITY** negative
- **WHEN** the notifier is invoked with an agent name it does not recognize
- **THEN** the notification carries the generic icon
- **AND** the generic icon is not a copy of any harness icon

### Requirement: The body names why the human must act

The notification body SHALL carry the specific reason the human is needed.
When the per-pane state file exists, the body SHALL also carry the repository,
the branch, and the elapsed time since the transition. A dirty worktree SHALL
be marked.

A missing or unreadable state file MUST degrade to the harness message alone,
never to an error.

#### Scenario: A full body

- **POLARITY** positive
- **WHEN** a notification is raised for a pane whose state file names repo
  `sysinit`, branch `main`, dirty `true`, and a transition 90 seconds ago
- **THEN** the body names the reason, `sysinit`, `main`, the dirty marker, and
  `1m`

#### Scenario: A missing state file degrades

- **POLARITY** negative
- **WHEN** the per-pane state file is absent or is not valid JSON
- **THEN** the body carries the harness message alone
- **AND** the notification is still raised
