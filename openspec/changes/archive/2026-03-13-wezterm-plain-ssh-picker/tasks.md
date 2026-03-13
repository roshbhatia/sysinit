## 1. Wezterm Plugin Cleanup

- [x] 1.1 Remove `smart_ssh` plugin reference and configuration from `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua`.
- [x] 1.2 Remove the `SUPER+SHIFT+S` binding from `modules/home/programs/wezterm/lua/sysinit/pkg/keybindings.lua`.

## 2. SSH Picker Implementation

- [x] 2.1 Implement `get_ssh_picker_action()` in `modules/home/programs/wezterm/lua/sysinit/pkg/sessions.lua`.
- [x] 2.2 Add host enumeration logic using `wezterm.enumerate_ssh_hosts()`.
- [x] 2.3 Implement the `InputSelector` callback to spawn `ssh <host>` and switch workspaces.

## 3. Keybinding Integration

- [x] 3.1 Restore `SUPER+SHIFT+S` in `keybindings.lua` using the new picker action from `sessions.lua`.
- [x] 3.2 Verify the picker opens and correctly lists hosts from `~/.ssh/config`.

## 4. Validation

- [x] 4.1 Verify that selecting a host opens a new tab with a plain SSH connection.
- [x] 4.2 Confirm the window switches to a workspace named after the host.
- [x] 4.3 Verify that version mismatch errors no longer occur when connecting to remote hosts.
