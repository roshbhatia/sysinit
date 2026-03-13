## Why

Wezterm's native SSH multiplexing (domains) requires identical versions of Wezterm on both client and server. This causes connection failures across systems with different OS-enforced Wezterm versions. By switching to a "Plain SSH" picker, we can maintain the fuzzy-finding workflow while using the version-resilient system `ssh` binary.

## What Changes

- **Replace `smart_ssh` Plugin**: Remove the dependency on the domain-based `smart_ssh.wezterm` plugin for SSH connections.
- **Implement Custom SSH Picker**: Create a new fuzzy picker using Wezterm's `InputSelector` that enumerates hosts from `~/.ssh/config`.
- **Version-Agnostic Connections**: Configure the picker to spawn tabs running the standard `ssh <host>` command instead of connecting to a Wezterm domain.
- **Maintain Workspace Intelligence**: Automatically switch to a workspace named after the remote host upon connection, preserving the "smart" feel of the previous setup.

## Capabilities

### New Capabilities
- `wezterm-plain-ssh-picker`: A version-resilient fuzzy picker for establishing SSH connections using the system `ssh` client.

### Modified Capabilities
- `wezterm-session-management`: Update session/workspace logic to support "plain" SSH contexts.

## Impact

- `modules/home/programs/wezterm/lua/sysinit/pkg/keybindings.lua`: Update the `SUPER+SHIFT+S` binding to use the new picker.
- `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua`: Removal of the `smart_ssh` plugin configuration.
- `modules/home/programs/wezterm/lua/sysinit/pkg/sessions.lua`: Addition of logic to handle SSH-to-workspace transitions.
