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
| `SYSINIT_NVIM_AVANTE_ENABLED` | `true` | Enable Avante |
| `SYSINIT_NVIM_AVANTE_PROVIDER` | `goose` | Set specific adapter for Avante: `copilot`, `claude_code`, `goose` |
| `SYSINIT_NVIM_CODECOMPANION_ADAPTER` | `copilot` | Set specific adapter for CodeCompanion: `copilot`, `claude_code`  |
| `SYSINIT_NVIM_CODECOMPANION_ENABLED` | `true` | Enable CodeCompanion |
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
| `options.cargo.additionalPackages` | listOf /gstr | [] |  | Additional Rust/Cargo packages |
| `options.darwin.borders.enable` | boolean | false |  | Enable window borders |
| `options.darwin.homebrew.additionalPackages.brews` | listOf /gstr | [] |  | Additional Homebrew formulae |
| `options.darwin.homebrew.additionalPackages.casks` | listOf /gstr | [] |  | Additional Homebrew casks |
| `options.darwin.homebrew.additionalPackages.taps` | listOf /gstr | [] |  | Additional Homebrew taps |
| `options.darwin.tailscale.enable` | boolean | false |  | Enable Tailscale |
| `options.gh.additionalPackages` | listOf /gstr | [] |  | Additional GitHub CLI extensions |
| `options.git.credentialUsername` | string | "username" | ✓ | Git credential username |
| `options.git.githubUser` | string | "username" | ✓ | GitHub username |
| `options.git.personalEmail` | nullOr /gstr | null |  | Personal email override |
| `options.git.personalGithubUser` | nullOr /gstr | null |  | Personal GitHub username override |
| `options.git.userEmail` | string | "user@example.com" | ✓ | Git user email |
| `options.git.userName` | string | "User Name" | ✓ | Git user name |
| `options.git.workEmail` | nullOr /gstr | null |  | Work email override |
| `options.git.workGithubUser` | nullOr /gstr | null |  | Work GitHub username override |
| `options.go.additionalPackages` | listOf /gstr | [] |  | Additional Go packages |
| `options.krew.additionalPackages` | listOf /gstr | [] |  | Additional kubectl krew plugins |
| `options.llm.claude.enabled` | boolean | false |  | Enable Claude Code integration |
| `options.llm.claude.uvPackages` | listOf /gstr | [] |  | Additional uv packages for Claude |
| `options.llm.claude.yarnPackages` | listOf /gstr | [] |  | Additional yarn packages for Claude |
| `options.llm.goose.leadModel` | string | "claude-sonnet-4" | ✓ | Goose lead model configuration |
| `options.llm.goose.model` | string | "gpt-4o-mini" | ✓ | Goose model configuration |
| `options.llm.goose.provider` | string | "github_copilot" | ✓ | Goose provider configuration |
| `options.nix.additionalPackages` | listOf /gstr | [] |  | Additional Nix packages |
| `options.npm.additionalPackages` | listOf /gstr | [] |  | Additional global npm packages |
| `options.pipx.additionalPackages` | listOf /gstr | [] |  | Additional global pipx packages |
| `options.theme.colorscheme` | string | "catppuccin" | ✓ | Theme colorscheme |
| `options.theme.transparency.blur` | integer | `80` |  | Background blur amount |
| `options.theme.transparency.enable` | boolean | true |  | Enable transparency effects |
| `options.theme.transparency.opacity` | float | `0.85` |  | Transparency opacity level |
| `options.theme.variant` | string | "macchiato" | ✓ | Theme variant |
| `options.user.hostname` | string | "nixos" | ✓ | System hostname |
| `options.user.username` | string | "user" | ✓ | Username for the system user |
| `options.uvx.additionalPackages` | listOf /gstr | [] |  | Additional global uvx packages |
| `options.wezterm.shell` | string | "zsh" | ✓ | Default shell for wezterm |
| `options.yarn.additionalPackages` | listOf /gstr | [] |  | Additional global yarn packages |

