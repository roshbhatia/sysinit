## ADDED Requirements

### Requirement: SSH picker uses smart_ssh's fuzzy host selector

The `SUPER+SHIFT+s` SSH picker SHALL present hosts through the vendored
`smart_ssh.wezterm` plugin's "Choose Host" `InputSelector` (`smart_ssh.tab()`),
which lists the mux domains whose name begins with `ssh`. If the plugin fails to
load, the picker SHALL fall back to WezTerm's native fuzzy launcher
(`ShowLauncherArgs` with the `FUZZY|DOMAINS` flags) rather than erroring.

#### Scenario: smart_ssh selector lists SSH domains

- **WHEN** the user presses `SUPER+SHIFT+s`
- **THEN** smart_ssh's "Choose Host" selector opens listing the configured
  `ssh:<host>` domains by bare host name and filters as the user types

#### Scenario: Plugin load failure falls back (negative)

- **WHEN** `smart_ssh.wezterm` fails to load
- **THEN** `SUPER+SHIFT+s` opens the native fuzzy launcher over the configured
  domains instead of the keybinding throwing

### Requirement: SSH domains are generated with key-based auth

The configuration SHALL seed `config.ssh_domains` from `enumerate_ssh_hosts()`,
shaping each domain to match smart_ssh's formatter — name `ssh:<host>`,
`multiplexing = "None"`, `assume_shell = "Posix"` — and SHALL attach an
`ssh_option` table (`identityagent = $SSH_AUTH_SOCK` when set, and
`identityfile` = the first existing default key among `id_ed25519`, `id_ecdsa`,
`id_rsa`) so WezTerm's libssh transport authenticates with the agent / key.

#### Scenario: Configured host connects without a password

- **WHEN** the user selects a host whose key is loaded in the ssh-agent (or whose
  default identity file exists)
- **THEN** the connection authenticates via the agent / key rather than prompting
  for a password

#### Scenario: Host name renders cleanly in the picker

- **WHEN** `~/.ssh/config` declares a literal `Host build01`
- **THEN** the domain is named `ssh:build01` and smart_ssh's formatter renders it
  as the bare host `build01` in the selector

#### Scenario: No identity available (negative)

- **WHEN** neither `$SSH_AUTH_SOCK` is set nor any default identity file exists
- **THEN** the domain is still created with an empty `ssh_option` and the picker
  works (the connection simply falls back to whatever auth WezTerm negotiates)

### Requirement: Coverage merge surfaces hosts enumerate_ssh_hosts misses

The SSH-domain set SHALL be augmented beyond `enumerate_ssh_hosts()` by parsing
`~/.ssh/known_hosts` (skipping hashed `|1|…` and malformed lines, unwrapping
`[host]:port` tokens) and appending the parseable hosts as additional
`ssh:<host>` domains, deduped against the enumerated set, so wildcard-derived and
previously-connected hosts appear in the picker.

#### Scenario: Known-hosts-only host appears

- **WHEN** a host exists in `~/.ssh/known_hosts` but is matched only by a
  wildcard `Host` block in `~/.ssh/config` (so `enumerate_ssh_hosts` omits it)
- **THEN** the picker still lists that host as a selectable `ssh:<host>` domain

#### Scenario: Unparseable known_hosts entries are skipped (negative)

- **WHEN** `~/.ssh/known_hosts` contains hashed (`|1|…`) or malformed lines
- **THEN** those lines are skipped and the merge still contributes the
  parseable hosts rather than aborting

#### Scenario: Wildcard and duplicate hosts are not added (negative)

- **WHEN** a candidate host is empty, contains a `*`/`?` glob, or was already
  added from `enumerate_ssh_hosts()`
- **THEN** it is not added a second time and no glob pseudo-host appears in the
  picker
