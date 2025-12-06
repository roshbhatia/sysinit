# Platform-Specific Configuration Analysis

## Executive Summary

This document catalogs all macOS-specific (Darwin) vs cross-platform configurations in sysinit, enabling informed decisions about:
- Which configurations to move to Linux (NixOS)
- Which to keep Darwin-only
- How to refactor the theme system for better maintainability

**Key Finding**: Only **2 home-manager modules** are truly Darwin-only (Hammerspoon, Sketchybar). The remaining 30+ cross-platform tools can work on both macOS and NixOS with proper system-level wiring.

---

## System-Level Darwin Configurations

All located in `/modules/darwin/configurations/`:

### Window Management & UI Tools (100% Darwin-Specific)

| Config | File | Tool | Why Darwin-Only | Can Share? |
|--------|------|------|-----------------|-----------|
| **Aerospace** | `aerospace/aerospace.nix` | Tiling WM | Apple Silicon/macOS exclusive | ❌ No |
| **Sketchybar** | `sketchybar/sketchybar.nix` | Status bar | macOS-specific API | ❌ No |
| **Borders** | `borders/borders.nix` | Window decorator | JankyBorders macOS lib | ❌ No |
| **Dock** | `dock/default.nix` | macOS Dock | Uses `system.defaults.dock` | ❌ No |
| **Finder** | `finder/default.nix` | File manager | Uses `system.defaults.finder` | ❌ No |
| **Keyboard** | `keyboard/default.nix` | Keyboard mappings | Uses `system.defaults` NSGlobalDomain | ⚠️ Partial |

### Package Management (Darwin-Specific)

| Config | File | Tool | Why Darwin-Only | Notes |
|--------|------|------|-----------------|-------|
| **Homebrew** | `packages/homebrew.nix` | Package mgr | macOS/Linux tool, but nix-homebrew integrates with nix-darwin | ✅ *Could be shared* |
| **Tap: Aerospace** | `homebrew.nix:58` | mediosz/tap/swipeaerospace | Aerospace tap | ⚠️ Conditional |

### System-Level Integrations (Darwin-Specific)

| Config | File | Tool | Why Darwin-Only | Notes |
|--------|------|------|-----------------|-------|
| **launchd** | `docker/colima.nix` | Service mgr | macOS process manager | ❌ No Linux equivalent in module |
| **launchd** | `ollama/ollama.nix` | Service mgr | macOS background agents | ⚠️ Could use systemd on Linux |

### Other Configurations (Conditional Darwin)

| Config | File | Tool | Darwin-Only? | Cross-Platform With? |
|--------|------|------|---------------|--------------------|
| **Docker** | `docker/docker.nix` | Container runtime | ❌ No | Both platforms |
| **Tailscale** | `tailscale/tailscale.nix` | VPN | ❌ No | Both platforms |
| **User Config** | `user/default.nix` | System user | ⚠️ Darwin-specific structure | Could share |

---

## Home-Manager Level Configurations

Located in `/modules/home/configurations/` and `/modules/home/packages/`

### CROSS-PLATFORM (Shared Between macOS & Linux)

**35 modules** that work on both platforms:

#### Code Editors & Development
- ✅ **Neovim** (`neovim/`) - Uses XDG config, fully cross-platform
- ✅ **Helix** (`helix/`) - Uses XDG, cross-platform
- ✅ **Ast-grep** (`ast-grep/`) - Code search, fully portable

#### Shell & Terminal
- ✅ **Zsh** (`zsh/`) - Shell configuration, no platform logic
- ✅ **Nushell** (`nushell/`) - Alternative shell, portable
- ✅ **Wezterm** (`wezterm/`) - Terminal emulator, XDG-based config
- ✅ **Omp** (`omp/`) - Oh My Posh prompt, cross-platform
- ✅ **Carapace** (`carapace/`) - Shell completions, portable

#### Git & Version Control
- ✅ **Git** (`git/`) - Version control, standard config format
- ✅ **LazyGit** (`git/config/lazygit.nix`) - TUI git client
- ✅ **Gh-Dash** (`git/config/gh-dash.nix`) - GitHub dashboard
- ✅ **Atuin** (`atuin/`) - Shell history, cross-platform

#### Language/Package Managers
- ✅ **Cargo** (`packages/cargo/`) - Rust, cross-platform
- ✅ **Go** (`packages/go/`) - Go binaries, cross-platform
- ✅ **NPM** (`packages/node/npm.nix`) - Node packages, portable
- ✅ **Yarn** (`packages/node/yarn.nix`) - Node packages, portable
- ✅ **Pipx** (`packages/python/pipx.nix`) - Python apps, portable
- ✅ **Uvx** (`packages/python/uvx.nix`) - UV Python, portable

#### System & Monitoring Tools
- ✅ **Bat** (`bat/`) - Code highlighting, cross-platform
- ✅ **Btop** (`btop/`) - System monitor, portable
- ✅ **Eza** (`eza/`) - `ls` replacement, cross-platform
- ✅ **Fd** (`fd/`) - Find replacement, portable
- ✅ **Fzf** (`fzf/`) - Fuzzy finder, cross-platform
- ✅ **Zoxide** (`zoxide/`) - Smart cd, portable
- ✅ **Direnv** (`direnv/`) - Env loader, cross-platform
- ✅ **Dircolors** (`dircolors/`) - LS colors, portable
- ✅ **Vivid** (`vivid/`) - Syntax coloring, portable
- ✅ **Yazi** (`yazi/`) - File manager, portable
- ✅ **Macchina** (`macchina/`) - System info, cross-platform
- ✅ **Editorconfig** (`editorconfig/`) - Editor standard, portable

#### Kubernetes & DevOps
- ✅ **Kubectl** (`kubectl/`) - K8s CLI, cross-platform
- ✅ **K9s** (`k9s/`) - K8s TUI, portable
- ✅ **Krew** (`packages/kubectl/krew.nix`) - Kubectl plugins, portable

#### Package Management
- ✅ **GitHub CLI** (`packages/gh/`) - GH commands, portable
- ✅ **Vet** (`packages/vet/`) - Vet tool, portable

#### AI/LLM Tools
- ✅ **LLM Config** (`llm/`) - Model configuration, portable
- ✅ **Claude Config** (`llm/config/claude.nix`) - Claude setup, portable
- ✅ **Cursor Config** (`llm/config/cursor.nix`) - Cursor IDE, cross-platform
- ✅ **Copilot Config** (`llm/config/copilot.nix`) - GitHub Copilot, portable

#### Browser
- ✅ **Firefox** (`firefox/`) - Browser config, portable

---

### DARWIN-ONLY (macOS Exclusive)

**2 modules** that require macOS:

#### Automation & UI
| Module | File | Framework | macOS Requirement | Alternative |
|--------|------|-----------|-------------------|-------------|
| **Hammerspoon** | `hammerspoon/` | Lua automation | Hammerspoon only on macOS | *None (no Linux equivalent)* |
| **Sketchybar** | `sketchybar/` | Status bar UI | macOS menu bar | *polybar/Waybar for Linux* |

**Hammerspoon Details**:
- macOS-only Lua scripting framework
- No viable Linux equivalent (closest: custom scripts + wmctrl)
- Used for: app-specific automation, keyboard bindings, notifications

**Sketchybar Issues** (for cross-platform use):
- Hardcoded path: `#!/opt/homebrew/bin/lua` (line 26)
- Hardcoded path: `local home_dir = "/Users/" .. username` (line 31)
- Would need `$HOME` substitution and conditional Lua path for Linux

---

## Theme System Architecture

Located in `/modules/lib/theme/`:

### Current Structure (1,500 LOC)

```
theme/
├── default.nix (415 lines) - Orchestrator
├── core/
│   ├── types.nix (196 lines) - Schema definitions
│   ├── constants.nix (54 lines) - Shared constants
│   └── utils.nix (433 lines) - Color operations
├── palettes/ (8 themes)
│   ├── catppuccin.nix
│   ├── gruvbox.nix
│   ├── kanagawa.nix
│   ├── rose-pine.nix
│   ├── solarized.nix
│   ├── nord.nix
│   ├── everforest.nix
│   └── black-metal.nix
├── adapters/ (3 apps)
│   ├── neovim.nix (133 lines)
│   ├── wezterm.nix (100+ lines)
│   └── firefox.nix (100+ lines)
└── presets/
    └── transparency.nix (94 lines)
```

### Architecture Layers

| Layer | Files | Purpose | Status |
|-------|-------|---------|--------|
| **Semantic** | `core/utils.nix` | Color transformations, semantic mapping | ✅ Well-implemented |
| **Type System** | `core/types.nix` | Schema & validation | ✅ Comprehensive |
| **Palettes** | `palettes/*.nix` | 8 theme definitions | ✅ Complete |
| **Adapters** | `adapters/*.nix` | App-specific configs | ⚠️ High duplication |
| **Orchestration** | `default.nix` | Theme selection & app config | ✅ Clean |
| **Presets** | `presets/transparency.nix` | Transparency settings | ✅ Working |

### Consolidation Opportunities

| Priority | Opportunity | Impact | Effort | ROI |
|----------|-------------|--------|--------|-----|
| 🔴 **High** | Extract adapter base class | Remove 150 LOC duplication | 2h | Very High |
| 🟠 **Medium** | Standardize palette keys | Simplify semantic mapping | 3h | High |
| 🟠 **Medium** | Consolidate validation | Centralize all checks | 1h | Medium |
| 🟠 **Medium** | Move transparency to core | Cleaner preset handling | 1h | Medium |
| 🟡 **Low** | Optimize color functions | Improve performance | 2h | Low |
| 🟡 **Low** | Semantic layer docs | Better maintainability | 1h | Low |

**Estimated savings**: 250-300 LOC (15-20% reduction)

---

## Recommendations

### For Darwin-Only Configurations

**Current Status**: Safe - properly isolated in `/modules/darwin/`

**Recommendation**: 
- Keep as-is - modules are well-organized by responsibility
- No changes needed for Linux support (they won't be imported on NixOS)

### For Cross-Platform Configurations

**Current Status**: Ready for Linux - no platform-specific code in home configs

**Recommendation**:
- All 35+ cross-platform modules can work on NixOS
- Just need system-level packages to be available
- Consider importing based on platform conditionals when running `arrakis`:

```nix
# In modules/home/configurations/default.nix (future)
imports = [
  # Cross-platform modules (always import)
  ./neovim
  ./git
  ./zsh
  ./wezterm
  # Darwin-only modules (conditional)
] ++ lib.optionals pkgs.stdenv.isDarwin [
  ./hammerspoon
  ./sketchybar
];
```

### For Theme System

**Immediate Action** (Phase 1 - Quick Wins):
1. Extract adapter base class → reduces boilerplate by 150 LOC
2. Standardize palette keys → simplifies semantic mapping by 50 LOC

**Future Enhancement** (Phase 2 - Polish):
3. Consolidate validation utilities → 30 LOC savings
4. Move transparency to core/presets → better separation

---

## Migration Path for arrakis (NixOS Desktop)

### What Can Reuse
✅ All 35+ home-manager cross-platform modules
✅ Theme system (palettes, adapters, semantic layer)
✅ Git, shell, editor configurations
✅ Development tools (language managers, CLI utilities)

### What Needs Linux Alternatives
❌ Aerospace → Sway/i3/Hyprland (in NixOS system config)
❌ Sketchybar → Waybar/polybar (if using Wayland)
❌ Hammerspoon → Custom scripts (if needed)
❌ Borders → Hyprland native decorations (if using Hyprland)

### What Can Be Shared
⚠️ Docker → Works on both, but uses different backends (colima on macOS, systemd on Linux)
⚠️ Tailscale → Works on both, uses same config
⚠️ Homebrew → Works on macOS nix-homebrew, skip on NixOS

---

## Platform-Specific Paths in Codebase

### Hardcoded macOS Paths

| File | Path | Issue | Solution |
|------|------|-------|----------|
| `sketchybar/sketchybar.nix:26` | `#!/opt/homebrew/bin/lua` | Homebrew Lua path | Use `${pkgs.lua}/bin/lua` |
| `sketchybar/sketchybar.nix:31` | `/Users/` | macOS home structure | Use `$HOME` variable |
| `homepage.nix` | `/opt/homebrew/bin/lua` | Homebrew Lua | Use `${pkgs.lua}/bin/lua` |

### No Hardcoded Linux Paths Found
✅ Well-designed: All other configs use XDG vars and relative paths

---

## Summary Table

| Category | Count | Darwin-Only | Cross-Platform | Status |
|----------|-------|------------|-----------------|--------|
| **System Configs** | 16 | 15 | 1 | ✅ Well-separated |
| **Home Modules** | 37 | 2 | 35 | ✅ Mostly portable |
| **Theme Files** | 14 | 0 | 14 | ⚠️ Needs consolidation |
| **Total LOC** | ~5,000 | ~2,000 | ~3,000 | ✅ Clean separation |

**Conclusion**: Architecture is well-designed for multi-platform support. Theme system can be optimized for maintainability. Ready for NixOS/arrakis expansion.
