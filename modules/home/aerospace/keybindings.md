# AeroSpace and Spectacle Keybinding Compatibility Guide

## Overview
This guide documents how AeroSpace and Spectacle can work together with compatible keybindings.

## Spectacle Keybindings
Spectacle traditionally uses **Command + Option + Arrow Keys** for window resizing and positioning:
- `Cmd + Opt + Left` - Move window to left half of screen
- `Cmd + Opt + Right` - Move window to right half of screen
- `Cmd + Opt + Up` - Move window to top half of screen
- `Cmd + Opt + Down` - Move window to bottom half of screen

## AeroSpace Keybindings
To avoid conflicts, AeroSpace is configured to use the following keybindings:

### Window Management
- `Cmd + H/J/K/L` - Focus window left/down/up/right
- `Cmd + Shift + H/J/K/L` - Move window left/down/up/right
- `Cmd + Minus/Equal` - Resize active window smaller/larger

### Layout Management
- `Cmd + /` - Switch to tiles layout
- `Cmd + ,` - Switch to accordion layout

### Workspace Management
- `Cmd + [1-9]` - Switch to workspace 1-9
- `Cmd + Shift + [1-9]` - Move current window to workspace 1-9
- `Cmd + Tab` - Switch to previous workspace (back and forth)
- `Cmd + Shift + Tab` - Move workspace to next monitor

### Service Mode (Special Operations)
- `Cmd + Shift + ;` - Enter service mode
  - While in service mode:
    - `Esc` - Reload config and exit service mode
    - `R` - Reset layout (flatten workspace tree)
    - `F` - Toggle between floating and tiling layout
    - `Backspace` - Close all windows except current
    - `Cmd + Shift + H/J/K/L` - Join with window left/down/up/right
    - `Down/Up` - Decrease/increase volume
    - `Shift + Down` - Mute volume

## Benefits of This Configuration

1. **Complementary Tools**: 
   - Spectacle handles simple window snapping and positioning
   - AeroSpace handles advanced tiling, workspaces, and layouts

2. **Familiar Keybindings**:
   - Maintains the familiar Spectacle keybindings for basic operations
   - Adds powerful AeroSpace features with intuitive keybindings

3. **No Conflicts**:
   - All keybindings are designed to avoid conflicts between the two tools
   - Use Spectacle for quick window positioning
   - Use AeroSpace for more advanced window management and workspaces

4. **Gradual Learning Curve**:
   - Start with familiar Spectacle commands
   - Gradually adopt more powerful AeroSpace features as needed