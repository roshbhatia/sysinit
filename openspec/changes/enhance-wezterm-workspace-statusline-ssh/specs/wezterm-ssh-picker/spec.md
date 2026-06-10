## ADDED Requirements

### Requirement: SSH picker uses the native fuzzy launcher

The `SUPER+SHIFT+s` SSH picker SHALL present hosts through WezTerm's built-in
fuzzy launcher (`ShowLauncherArgs` with the `FUZZY|DOMAINS` flags) over the
configured SSH domains, rather than a hand-rolled `InputSelector`.

#### Scenario: Fuzzy launcher lists SSH domains

- **WHEN** the user presses `SUPER+SHIFT+s`
- **THEN** the fuzzy launcher opens listing the configured SSH domains and
  filters as the user types

#### Scenario: Launcher opens with no SSH config (negative)

- **WHEN** no SSH hosts can be discovered from any source
- **THEN** the launcher opens without erroring (it shows whatever domains exist)
  rather than the keybinding throwing

### Requirement: SSH domains are generated from config

The configuration SHALL seed `ssh_domains` from `wezterm.default_ssh_domains()`,
producing both an `SSH:` (exec) and an `SSHMUX:` (multiplexer) domain per host
discovered by `enumerate_ssh_hosts()`.

#### Scenario: Each enumerated host yields domains

- **WHEN** `~/.ssh/config` declares a literal `Host build01`
- **THEN** the picker offers `build01` reachable as both an `SSH:` and an
  `SSHMUX:` domain

#### Scenario: Remote without wezterm is still usable (negative)

- **WHEN** a selected host has no `wezterm` binary installed remotely
- **THEN** connecting via the `SSH:` exec domain still works (only the
  reattachable `SSHMUX:` variant is unavailable on that host)

### Requirement: Coverage merge surfaces hosts enumerate_ssh_hosts misses

The SSH-domain set SHALL be augmented beyond `enumerate_ssh_hosts()` with hosts
resolved from the real ssh client — parsing `~/.ssh/known_hosts` and/or resolving
specific hosts via `ssh -G` — so wildcard-derived and previously-connected hosts
appear in the picker as `SSH:` exec domains.

#### Scenario: Known-hosts-only host appears

- **WHEN** a host exists in `~/.ssh/known_hosts` but is matched only by a
  wildcard `Host` block in `~/.ssh/config` (so `enumerate_ssh_hosts` omits it)
- **THEN** the picker still lists that host as a selectable `SSH:` domain

#### Scenario: Unparseable known_hosts entries are skipped (negative)

- **WHEN** `~/.ssh/known_hosts` contains hashed (`|1|…`) or malformed lines
- **THEN** those lines are skipped and the merge still contributes the
  parseable hosts rather than aborting
