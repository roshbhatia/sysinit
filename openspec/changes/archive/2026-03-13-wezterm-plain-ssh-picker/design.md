## Context

Wezterm's SSH domains provide built-in multiplexing but are extremely sensitive to version mismatches. In a heterogeneous environment (macOS, multiple NixOS versions), this leads to frequent "version mismatch" errors. The `smart_ssh.wezterm` plugin currently abstracts these domains, making it difficult to force a "plain" SSH connection without losing the fuzzy-finding UI.

## Goals / Non-Goals

**Goals:**
- Eliminate SSH connection failures caused by Wezterm version mismatches.
- Preserve the fuzzy-finding user experience for choosing SSH hosts.
- Automate workspace creation/switching for each remote host.
- Use the standard system `ssh` binary for all remote connections.

**Non-Goals:**
- Supporting Wezterm's native SSH multiplexing (multiplexing will be handled by the system SSH `ControlMaster` if configured, or not at all).
- Changing the existing `~/.ssh/config` parsing logic.

## Decisions

### 1. Shift from `smart_ssh` to Native `InputSelector`
**Decision**: Implement a custom Lua function using `wezterm.action.InputSelector`.
**Rationale**: This provides a built-in fuzzy UI that doesn't depend on external plugins and allows total control over the `SpawnCommand` executed upon selection.

### 2. Host Discovery via `enumerate_ssh_hosts()`
**Decision**: Use the native `wezterm.enumerate_ssh_hosts()` function to populate the picker.
**Rationale**: This ensures we pick up all hosts from the user's `~/.ssh/config` automatically, just as the previous plugin did.

### 3. Spawning "Plain" SSH Tabs
**Decision**: When a host is selected, the action will be `act.SpawnCommandInNewTab({ args = { 'ssh', host } })`.
**Rationale**: By spawning a standard shell command, we use the system's `ssh` binary, which is version-agnostic and fully supports all SSH config options.

### 4. Hook-based Workspace Management
**Decision**: Add a callback to the selection that runs `window:perform_action(act.SwitchToWorkspace({ name = host }))`.
**Rationale**: This replicates the most valuable "smart" feature of the previous setup—keeping each host's tabs isolated in their own named workspace.

## Risks / Trade-offs

- **[Risk]**: Loss of Wezterm-native multiplexing features (like attaching to a detached domain).
- **[Mitigation]**: Standard SSH is more robust for general use; users requiring persistent remote sessions should use `tmux` or `screen` on the remote host.
- **[Risk]**: `enumerate_ssh_hosts()` might include unwanted entries (like wildcards).
- **[Mitigation]**: Filter the list in Lua to only include valid host identifiers.
