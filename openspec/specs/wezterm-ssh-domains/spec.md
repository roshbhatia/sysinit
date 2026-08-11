# wezterm-ssh-domains Specification

## Purpose
Define the `ssh_domains` WezTerm builds for this machine, so a bare `ssh <host>`
inside a pane opens a reattachable remote pane instead of a plain session.

Renamed from `wezterm-ssh-picker`. The `SUPER+SHIFT+s` picker and the vendored
`smart_ssh.wezterm` plugin it drove were removed; the domains they selected from
are what remains, and the `ssh()` shell wrapper is now the only caller.
## Requirements
### Requirement: SSH domains are generated with key-based auth

The configuration SHALL seed `config.ssh_domains` from `enumerate_ssh_hosts()`,
shaping each domain as name `ssh:<host>`, `multiplexing = "WezTerm"`,
`assume_shell = "Posix"`, and SHALL attach an `ssh_option` table so WezTerm's
libssh transport authenticates with the agent or key.

`identityagent` SHALL come from `config.json`'s `ssh.agent_socket`, which Nix
writes from `sysinit.git.ssh.agentSocket`, and SHALL fall back to
`$SSH_AUTH_SOCK` only when that path does not exist. The order matters and is
not a preference: under the GUI, `$SSH_AUTH_SOCK` names WezTerm's own forwarded
agent, which holds no identities, so trusting it first denies every key.
`identitiesonly` SHALL be `no`, because WezTerm defaults it to yes and that
skips agent auth outright.

`identityfile` SHALL be the first existing default key among `id_ed25519`,
`id_ecdsa`, `id_rsa`, and is absent on a machine whose keys live only in an
agent.

#### Scenario: Configured host connects without a password

- **WHEN** the user selects a host whose key is loaded in the ssh-agent (or whose
  default identity file exists)
- **THEN** the connection authenticates via the agent / key rather than prompting
  for a password

#### Scenario: Host alias becomes a domain of the same name

- **WHEN** `~/.ssh/config` declares a literal `Host build01`
- **THEN** the domain is named `ssh:build01`, which is the name the `ssh()` shell
  wrapper passes to `wezterm cli spawn --domain-name`

#### Scenario: Spawning into a host opens a reattachable pane

- **WHEN** the shell wrapper runs `wezterm cli spawn --domain-name ssh:<host>`
- **THEN** the pane is opened against the `multiplexing = "WezTerm"` domain, so
  the remote session is a reattachable mux domain (the remote runs
  `wezterm-mux-server`) rather than a single-shot exec

#### Scenario: No identity available (negative)

- **WHEN** no agent socket resolves and no default identity file exists
- **THEN** the domain is still created with an empty `ssh_option` and the wrapper
  still spawns, falling back to whatever auth WezTerm negotiates

### Requirement: Coverage merge surfaces hosts enumerate_ssh_hosts misses

The SSH-domain set SHALL be augmented beyond `enumerate_ssh_hosts()` by parsing
`~/.ssh/known_hosts` (skipping hashed `|1|…` and malformed lines, unwrapping
`[host]:port` tokens) and appending the parseable hosts as additional
`ssh:<host>` domains, deduped against the enumerated set, so wildcard-derived and
previously-connected hosts appear as domains. Deduplication SHALL also skip
any known_hosts entry whose name equals the resolved `HostName` of an enumerated
alias, so a Tailscale FQDN (e.g. `arrakis.stork-eel.ts.net`) does not appear as a
duplicate of its short `Host` alias (e.g. `arrakis`).

#### Scenario: Known-hosts-only host appears

- **WHEN** a host exists in `~/.ssh/known_hosts` but is matched only by a
  wildcard `Host` block in `~/.ssh/config` (so `enumerate_ssh_hosts` omits it)
- **THEN** that host is still built as a spawnable `ssh:<host>` domain

#### Scenario: Unparseable known_hosts entries are skipped (negative)

- **WHEN** `~/.ssh/known_hosts` contains hashed (`|1|…`) or malformed lines
- **THEN** those lines are skipped and the merge still contributes the
  parseable hosts rather than aborting

#### Scenario: Wildcard and duplicate hosts are not added (negative)

- **WHEN** a candidate host is empty, contains a `*`/`?` glob, or was already
  added from `enumerate_ssh_hosts()`
- **THEN** it is not added a second time and no glob pseudo-host
  becomes a domain

#### Scenario: FQDN that resolves to an alias is not duplicated (negative)

- **WHEN** `~/.ssh/known_hosts` contains a FQDN (e.g. `arrakis.stork-eel.ts.net`)
  that equals the resolved `HostName` of an enumerated `Host` alias (e.g.
  `arrakis`)
- **THEN** only the short alias `ssh:arrakis` is built and no separate
  `ssh:arrakis.stork-eel.ts.net` domain is added

