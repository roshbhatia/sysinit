# sysinit

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

This comprises most of my dotfiles, managed (mostly) by `nix`.

## Structure

- `flake.nix` - Flake entry point
- `hosts/` - Per-host configurations (lv426, lima-dev, lima-minimal)
- `lib/` - Nix builder functions and utilities
- `modules/` - Reusable NixOS/Darwin/home-manager modules
- `profiles/` - Reusable configuration bundles
- `pkgs/` - Custom package definitions
- `templates/` - Project templates (VM dev environments)
- `hack/` - Build and maintenance scripts

## Install Dependencies

```bash
xcode-select --install && \
/bin/bash -c "$(curl -fsSL \
https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
eval "$(/opt/homebrew/bin/brew shellenv)" && \
brew install go-task/tap/go-task
```

## Installing Neovim only 

```bash
curl -fsSL https://raw.githubusercontent.com/roshbhatia/sysinit/main/setup/neovim.sh | bash
```

## Quick Start

### System Configuration
```bash
# Build configuration (test without applying)
task nix:build

# Apply configuration changes
task nix:refresh

# Update dependencies
task nix:update
```

### Development VMs
Create disposable NixOS VMs for project isolation:

```bash
# Start a minimal VM
limactl start --name=dev lima/templates/minimal.yaml
limactl shell dev

# Stop and delete
limactl stop dev
limactl delete dev
```

**Available VM Templates:**
- `minimal.yaml` - Basic NixOS (2 CPU, 4GB RAM, dev-minimal profile)
- `dev.yaml` - Full environment (4 CPU, 8GB RAM, dev-full profile)

## Environment Variables Schema

| Variable | Default | Description |
|----------|---------|-------------|
| `SYSINIT_DEBUG` | `false` | Enable debugging for zsh/nu/nvim |

<!-- VALUES_SCHEMA_START -->

## Values Configuration Schema

| Field | Type | Default | Required | Description |
|-------|------|---------|----------|-------------|
| `cargo.additionalPackages` | list(string) | [] |  | Additional Rust/Cargo packages |
| `config.root` | path | - | ✓ | Root path to the configuration flake directory |
| `darwin.borders.enable` | boolean | true |  | Enable window borders |
| `darwin.homebrew.additionalPackages.brews` | list(string) | [] |  | Additional Homebrew formulae |
| `darwin.homebrew.additionalPackages.casks` | list(string) | [] |  | Additional Homebrew casks |
| `darwin.homebrew.additionalPackages.taps` | list(string) | [] |  | Additional Homebrew taps |
| `gh.additionalPackages` | list(string) | [] |  | Additional GitHub CLI extensions |
| `git.email` | string | - | ✓ | Git user email |
| `git.name` | string | - | ✓ | Git user name |
| `git.personalEmail` | string? | null |  | Personal email override |
| `git.personalUsername` | string? | null |  | Personal username override |
| `git.username` | string | - | ✓ | Git/GitHub username |
| `git.workEmail` | string? | null |  | Work email override |
| `git.workUsername` | string? | null |  | Work username override |
| `go.additionalPackages` | list(string) | [] |  | Additional Go packages |
| `krew.additionalPackages` | list(string) | [] |  | Additional kubectl krew plugins |
| `llm.mcp.args` | list(string) | [] |  | MCP server arguments |
| `llm.mcp.command` | string | - | ✓ | MCP server command |
| `llm.mcp.description` | string | "" |  | Server description |
| `llm.mcp.enabled` | boolean | true |  | Enable this server |
| `llm.mcp.env` | attrsOf str | `{ }` |  | Environment variables for MCP server |
| `llm.mcp.type` |  | "local" |  | MCP server type |
| `llm.mcp.url` | string? | null |  | HTTP server URL (if type = http) |
| `nix.additionalPackages` | list(string) | [] |  | Additional Nix packages |
| `nix.gaming.enable` | boolean | false |  | Enable gaming configuration (Proton, Lutris, gamescope) |
| `npm.additionalPackages` | list(string) | [] |  | Additional global npm packages |
| `pipx.additionalPackages` | list(string) | [] |  | Additional global pipx packages |
| `tailscale.enable` | boolean | true |  | Enable Tailscale |
| `theme.appearance` |  | "dark" |  | Appearance mode (light or dark) |
| `theme.colorscheme` | string | - | ✓ | Theme colorscheme |
| `theme.font.monospace` | string | "TX-02" |  | Monospace font for terminal and editor |
| `theme.font.symbols` | string | "Symbols Nerd Font" |  | Fallback font for nerd font glyphs |
| `theme.transparency.blur` | integer | `70` |  | Background blur amount |
| `theme.transparency.opacity` | float | `0.8` |  | Transparency opacity level |
| `theme.variant` | string | - | ✓ | Theme variant |
| `user.username` | string | "user" |  | Username for the system user |
| `uvx.additionalPackages` | list(string) | [] |  | Additional global uvx packages |
| `vet.additionalPackages` | list(string) | [] |  | Additional Vet packages |
| `yarn.additionalPackages` | list(string) | [] |  | Additional global yarn packages |

<!-- VALUES_SCHEMA_END -->
