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
| `llm.goose.leadModel` | string? | null |  | Goose lead model configuration |
| `llm.goose.model` | string | "gpt-4o-mini" |  | Goose model configuration |
| `llm.goose.provider` | string | "github_copilot" |  | Goose provider configuration |
| `nix.additionalPackages` | list(string) | [] |  | Additional Nix packages |
| `npm.additionalPackages` | list(string) | [] |  | Additional global npm packages |
| `pipx.additionalPackages` | list(string) | [] |  | Additional global pipx packages |
| `theme.appearance` |  | "dark" |  | Appearance mode (light or dark) |
| `theme.colorscheme` | string | "catppuccin" |  | Theme colorscheme |
| `theme.font.monospace` | string | "JetBrainsMono Nerd Font" |  | Monospace font for terminal and editor |
| `theme.font.nerdfontFallback` | string | "Symbols Nerd Font" |  | Fallback font for nerd font glyphs |
| `theme.transparency.blur` | integer | `80` |  | Background blur amount |
| `theme.transparency.enable` | boolean | true |  | Enable transparency effects |
| `theme.transparency.opacity` | float | `0.85` |  | Transparency opacity level |
| `theme.variant` | string | "macchiato" |  | Theme variant |
| `updateInterval` | nullOr int | null |  | Update interval in milliseconds |
| `user.hostname` | string | "nixos" |  | System hostname |
| `user.username` | string | "user" |  | Username for the system user |
| `uvx.additionalPackages` | list(string) | [] |  | Additional global uvx packages |
| `vet.additionalPackages` | list(string) | [] |  | Additional Vet packages |
| `wezterm.shell` | string | "zsh" |  | Default shell for wezterm |
| `yarn.additionalPackages` | list(string) | [] |  | Additional global yarn packages |
<!-- VALUES_SCHEMA_END -->
