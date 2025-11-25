# sysinit

- [sysinit](#sysinit)
  - [Overview](#overview)
  - [Supported Systems](#supported-systems)
  - [Install Dependencies](#install-dependencies)
  - [Usage](#usage)
  - [Multi-Host Setup](#multi-host-setup)
  - [Project Structure](#project-structure)

```ascii
          ▗▄▄▄       ▗▄▄▄▄    ▄▄▄▖
          ▜███▙       ▜███▙  ▟███▛
           ▜███▙       ▜███▙▟███▛
            ▜███▙       ▜██████▛
     ▟█████████████████▙ ▜████▛     ▟▙
    ▟███████████████████▙ ▜███▙    ▟██▙
           ▄▄▄▄▖           ▜███▙  ▟███▛
          ▟███▛             ▜██▛ ▟███▛
         ▟███▛               ▜▛ ▟███▛
▟███████████▛                  ▟██████████▙
▜██████████▛                  ▟███████████▛
      ▟███▛ ▟▙               ▟███▛
     ▟███▛ ▟██▙             ▟███▛
    ▟███▛  ▜███▙           ▝▀▀▀▀
    ▜██▛    ▜███▙ ▜██████████████████▛
     ▜▛     ▟████▙ ▜████████████████▛
           ▟██████▙       ▜███▙
          ▟███▛▜███▙       ▜███▙
         ▟███▛  ▜███▙       ▜███▙
         ▝▀▀▀    ▀▀▀▀▘       ▀▀▀▘
```

## Overview

This comprises most of my dotfiles, managed by `nix`. It supports both **macOS** (via nix-darwin) and **NixOS** (Linux) with a unified configuration system.

## Supported Systems

- **macOS (nix-darwin)**: aarch64-darwin, x86_64-darwin
- **NixOS (Linux)**: aarch64-linux, x86_64-linux

All systems share the same home-manager configuration for consistent dotfiles across platforms.

## Install Dependencies

```bash
xcode-select --install && \
/bin/bash -c "$(curl -fsSL \
https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
eval "$(/opt/homebrew/bin/brew shellenv)" && \
brew install go-task/tap/go-task
```

## Installing Neovim only (with fallback theming)

```bash
git clone --depth 1 https://github.com/roshbhatia/sysinit.git /tmp/sysinit && \
mkdir -p ~/.config/nvim && \
cp -r /tmp/sysinit/modules/home/configurations/neovim/ ~/.config/nvim/
```

## Usage

```text
task: Available tasks for this project:
* default:                 Show help information
* nix:fmt:                 Format the Nix configuration
* nix:build:               Build the configuration without applying
* nix:clean:               Run garbage collection
* nix:refresh:             Apply the system configuration
* nix:refresh:work:        Update and rebuild work sysinit configuration
```

## Multi-Host Setup

This repository supports multiple hosts with a unified configuration system. Host configurations are defined in `hosts/values.nix`.

### Configured Hosts

- **lv426** - Personal MacBook Pro (aarch64-darwin)
- **arrakis** - Gaming Desktop (x86_64-linux) with Steam/gaming support
- **urth** - Home Server (x86_64-linux) with k3s Kubernetes

### Building for macOS (nix-darwin)

```bash
# Build for lv426 (personal MacBook)
darwin-rebuild switch --flake .#lv426

# Or use values.nix (backward compatible)
darwin-rebuild switch --flake .
```

### Building for NixOS

```bash
# First time setup on a new NixOS machine:
# 1. Generate hardware configuration
sudo nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware-configuration.nix

# 2. Build and switch
sudo nixos-rebuild switch --flake .#arrakis  # For gaming desktop
sudo nixos-rebuild switch --flake .#urth     # For home server
```

### Adding a New Host

1. Create a directory in `hosts/` with your hostname:
   ```bash
   mkdir -p hosts/newhostname
   ```

2. Add configuration to `hosts/values.nix`:
   ```nix
   hosts = {
     newhostname = {
       system = "x86_64-linux";  # or "aarch64-darwin" for Mac
       hostname = "newhostname";
       # Add host-specific config here
     };
   };
   ```

3. Create host-specific module in `hosts/newhostname/default.nix`:
   ```nix
   { config, pkgs, ... }:
   {
     # Host-specific configuration
   }
   ```

4. For NixOS hosts, generate hardware config:
   ```bash
   nixos-generate-config --show-hardware-config > hosts/newhostname/hardware-configuration.nix
   ```

## Environment Variables Schema

| Variable | Default | Description |
|----------|---------|-------------|
| `SYSINIT_DEBUG` | `false` | Enable debugging for zsh/nu/nvim |
| `SYSINIT_MACCHINA_THEME` | `rosh` | Macchina theme name |

<!-- VALUES_SCHEMA_START -->

## Values Configuration Schema

| Field | Type | Default | Required | Description |
|-------|------|---------|----------|-------------|
| `cargo.additionalPackages` | list(string) | [] |  | Additional Rust/Cargo packages |
| `darwin.borders.enable` | boolean | true |  | Enable window borders |
| `darwin.docker.enable` | boolean | true |  | Enable container runtime |
| `darwin.homebrew.additionalPackages.brews` | list(string) | [] |  | Additional Homebrew formulae |
| `darwin.homebrew.additionalPackages.casks` | list(string) | [] |  | Additional Homebrew casks |
| `darwin.homebrew.additionalPackages.taps` | list(string) | [] |  | Additional Homebrew taps |
| `darwin.tailscale.enable` | boolean | true |  | Enable Tailscale |
| `definedAliases` | list(string) | [] |  | Search aliases |
| `firefox.name` | string | - | ✓ | Parameter name |
| `firefox.template` | string | - | ✓ | URL template for the search engine |
| `firefox.value` | string | - | ✓ | Parameter value |
| `gh.additionalPackages` | list(string) | [] |  | Additional GitHub CLI extensions |
| `git.email` | string | - | ✓ | Git user email |
| `git.name` | string | - | ✓ | Git user name |
| `git.personalEmail` | string? | null |  | Personal email override |
| `git.personalUsername` | string? | null |  | Personal username override |
| `git.username` | string | - | ✓ | Git/GitHub username |
| `git.workEmail` | string? | null |  | Work email override |
| `git.workUsername` | string? | null |  | Work username override |
| `go.additionalPackages` | list(string) | [] |  | Additional Go packages |
| `icon` | string? | null |  | Icon URL for the search engine |
| `krew.additionalPackages` | list(string) | [] |  | Additional kubectl krew plugins |
| `llm.agentsMd.autoUpdate` | boolean | true |  | Automatically update AGENTS.md when configuration changes |
| `llm.agentsMd.enabled` | boolean | true |  | Enable AGENTS.md integration across all LLM configurations |
| `llm.amp.enabled` | boolean | false |  | Enable Amp CLI configuration and MCP setup |
| `llm.amp.mcp.additionalServers` | attrsOf (attrsOf anything) | `{ }` |  | Additional MCP servers for Amp |
| `llm.amp.mcp.aws.enabled` | boolean | true |  | Enable AWS MCP servers for Amp |
| `llm.amp.mcp.aws.region` | string | "us-east-1" |  | Default AWS region for Amp MCP servers |
| `llm.amp.permissions.bash` | boolean | true |  | Ask before running arbitrary bash commands |
| `llm.amp.permissions.git` | boolean | true |  | Ask before running git commit commands |
| `llm.amp.permissions.mcp` | boolean | true |  | Ask before running MCP tools |
| `llm.claude.enabled` | boolean | true |  | Enable Claude Desktop configuration |
| `llm.claude.mcp.additionalServers` | attrsOf (attrsOf anything) | `{ }` |  | Additional MCP servers for Claude |
| `llm.claude.mcp.aws.enabled` | boolean | true |  | Enable AWS MCP servers |
| `llm.claude.mcp.aws.region` | string | "us-east-1" |  | Default AWS region for MCP servers |
| `llm.cursor.enabled` | boolean | true |  | Enable Cursor CLI configuration |
| `llm.cursor.permissions.kubectl.allowed` | list(string) | `constants.llmDefaults.cursor.permissions.kubectl.allowed` |  | Allowed kubectl commands for Cursor |
| `llm.cursor.permissions.shell.allowed` | list(string) | `constants.llmDefaults.cursor.permissions.shell.allowed` |  | Allowed shell commands for Cursor |
| `llm.cursor.vimMode` | boolean | `constants.llmDefaults.cursor.vimMode` |  | Enable Vim mode in Cursor |
| `llm.execution.isolation.enabled` | boolean | true |  | Enable execution isolation for security |
| `llm.execution.isolation.monitoring` | boolean | true |  | Monitor resource usage during execution |
| `llm.execution.isolation.timeout` | integer | `300` |  | Default execution timeout in seconds |
| `llm.execution.nixShell.autoDeps` | boolean | true |  | Automatically download dependencies via nix-shell when needed |
| `llm.execution.nixShell.enabled` | boolean | true |  | Enable nix-shell integration for dynamic dependency management |
| `llm.execution.nixShell.sandbox` | boolean | true |  | Use nix-shell sandboxing for isolation |
| `llm.execution.terminal.wezterm.enabled` | boolean | true |  | Enable wezterm session spawning for visibility |
| `llm.execution.terminal.wezterm.monitor` | boolean | true |  | Monitor command execution in terminal |
| `llm.execution.terminal.wezterm.newWindow` | boolean | true |  | Spawn commands in new wezterm windows |
| `llm.goose.alphaFeatures` | boolean | `constants.llmDefaults.goose.alphaFeatures` |  | Enable Goose alpha features |
| `llm.goose.enabled` | boolean | true |  | Enable Goose AI assistant configuration |
| `llm.goose.leadModel` | string? | `constants.llmDefaults.goose.leadModel` |  | Goose lead model configuration |
| `llm.goose.mode` | string | `constants.llmDefaults.goose.mode` |  | Goose interaction mode |
| `llm.goose.model` | string | `constants.llmDefaults.goose.model` |  | Goose model configuration |
| `llm.goose.provider` | string | `constants.llmDefaults.goose.provider` |  | Goose provider configuration |
| `llm.mcp.additionalServers` | listOf (attrsOf anything) | [] |  | Additional MCP servers in list format |
| `llm.mcp.servers` | attrsOf (attrsOf anything) | `{ }` |  | Additional MCP servers configuration |
| `llm.opencode.autoupdate` | boolean | `constants.llmDefaults.opencode.autoupdate` |  | Enable Opencode auto-update |
| `llm.opencode.enabled` | boolean | true |  | Enable Opencode IDE configuration |
| `llm.opencode.share` | string | `constants.llmDefaults.opencode.share` |  | Opencode sharing configuration |
| `llm.opencode.theme` | string | `constants.llmDefaults.opencode.theme` |  | Opencode theme configuration |
| `nix.additionalPackages` | list(string) | [] |  | Additional Nix packages |
| `npm.additionalPackages` | list(string) | [] |  | Additional global npm packages |
| `pipx.additionalPackages` | list(string) | [] |  | Additional global pipx packages |
| `theme.appearance` |  | "dark" |  | Appearance mode (light or dark) |
| `theme.colorscheme` | string | "catppuccin" |  | Theme colorscheme |
| `theme.font.monospace` | string | "TX-02" |  | Monospace font for terminal and editor |
| `theme.font.nerdfontFallback` | string | "Symbols Nerd Font" |  | Fallback font for nerd font glyphs |
| `theme.transparency.blur` | integer | `80` |  | Background blur amount |
| `theme.transparency.enable` | boolean | true |  | Enable transparency effects |
| `theme.transparency.opacity` | float | `0.8` |  | Transparency opacity level |
| `theme.variant` | string | "macchiato" |  | Theme variant |
| `updateInterval` | nullOr int | null |  | Update interval in milliseconds |
| `user.hostname` | string | "nixos" |  | System hostname |
| `user.username` | string | "user" |  | Username for the system user |
| `uvx.additionalPackages` | list(string) | [] |  | Additional global uvx packages |
| `vet.additionalPackages` | list(string) | [] |  | Additional Vet packages |
| `wezterm.shell` | string | "zsh" |  | Default shell for wezterm |
| `yarn.additionalPackages` | list(string) | [] |  | Additional global yarn packages |
<!-- VALUES_SCHEMA_END -->
