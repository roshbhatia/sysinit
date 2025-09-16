# sysinit

- [sysinit](#sysinit)
  - [Install Dependencies](#install-dependencies)
  - [Usage](#usage)
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

This comprises most of my dotfiles, managed (mostly) by `nix`.

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

## Environment Variables

### SYSINIT Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `SYSINIT_DEBUG` | `false` | Enable debugging for zsh/nu/nvim |
| `SYSINIT_MACCHINA_THEME` | `rosh` | Macchina theme name |
| `SYSINIT_NVIM_AGENTS_ENABLED` | `true` | Enable/disable all neovim AI agent plugins |
| `SYSINIT_NVIM_COPILOTLUA_ENABLED` | `true` | Enable GitHub Copilot integration (copilot.lua, copilot-cmp) |
| `SYSINIT_NVIM_OPENCODE_ENABLED` | `true` | Enable OpenCode |

### External Dependencies

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_CODE_OAUTH_TOKEN` | - | OAuth token for Claude Pro subscription |

<!-- VALUES_SCHEMA_START -->

## Values Configuration Schema

| Field | Type | Default | Required | Description |
|-------|------|---------|----------|-------------|
| `cargo.additionalPackages` | list(string) | [] |  | Additional Rust/Cargo packages |
| `darwin.borders.enable` | boolean | false |  | Enable window borders |
| `darwin.homebrew.additionalPackages.brews` | list(string) | [] |  | Additional Homebrew formulae |
| `darwin.homebrew.additionalPackages.casks` | list(string) | [] |  | Additional Homebrew casks |
| `darwin.homebrew.additionalPackages.taps` | list(string) | [] |  | Additional Homebrew taps |
| `darwin.tailscale.enable` | boolean | false |  | Enable Tailscale |
| `definedAliases` | list(string) | [] |  | Search aliases |
| `firefox.name` | string | - | ✓ | Parameter name |
| `firefox.template` | string | - | ✓ | URL template for the search engine |
| `firefox.value` | string | - | ✓ | Parameter value |
| `gh.additionalPackages` | list(string) | [] |  | Additional GitHub CLI extensions |
| `git.name` | string | - | ✓ | Git user name |
| `git.personalEmail` | string? | null |  | Personal email override |
| `git.personalUsername` | string? | null |  | Personal username override |
| `git.userEmail` | string | - | ✓ | Git user email |
| `git.username` | string | - | ✓ | Git/GitHub username |
| `git.workEmail` | string? | null |  | Work email override |
| `git.workUsername` | string? | null |  | Work username override |
| `go.additionalPackages` | list(string) | [] |  | Additional Go packages |
| `icon` | string? | null |  | Icon URL for the search engine |
| `krew.additionalPackages` | list(string) | [] |  | Additional kubectl krew plugins |
| `llm.claude.enabled` | boolean | false |  | Enable Claude Code integration |
| `llm.claude.uvPackages` | list(string) | [] |  | Additional uv packages for Claude |
| `llm.claude.yarnPackages` | list(string) | [] |  | Additional yarn packages for Claude |
| `llm.goose.leadModel` | string? | null |  | Goose lead model configuration |
| `llm.goose.model` | string | "gpt-4o-mini" |  | Goose model configuration |
| `llm.goose.provider` | string | "github_copilot" |  | Goose provider configuration |
| `nix.additionalPackages` | list(string) | [] |  | Additional Nix packages |
| `npm.additionalPackages` | list(string) | [] |  | Additional global npm packages |
| `pipx.additionalPackages` | list(string) | [] |  | Additional global pipx packages |
| `theme.colorscheme` | string | "catppuccin" |  | Theme colorscheme |
| `theme.transparency.blur` | integer | `80` |  | Background blur amount |
| `theme.transparency.enable` | boolean | true |  | Enable transparency effects |
| `theme.transparency.opacity` | float | `0.85` |  | Transparency opacity level |
| `theme.variant` | string | "macchiato" |  | Theme variant |
| `updateInterval` | nullOr int | null |  | Update interval in milliseconds |
| `user.hostname` | string | "nixos" |  | System hostname |
| `user.username` | string | "user" |  | Username for the system user |
| `uvx.additionalPackages` | list(string) | [] |  | Additional global uvx packages |
| `wezterm.shell` | string | "zsh" |  | Default shell for wezterm |
| `yarn.additionalPackages` | list(string) | [] |  | Additional global yarn packages |
<!-- VALUES_SCHEMA_END -->
