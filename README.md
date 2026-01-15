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
* default:                Show all available tasks
* fmt:                    Format all supported file types
* sh:chmod:               Make all .sh files executable
* docs:values:            Generate and inject values documentation into README

* nix:build:              Build system configuration (defaults to lv426)
* nix:build:lv426:        Build lv426 (macOS) system configuration
* nix:build:arrakis:      Build arrakis (NixOS) system configuration
* nix:build:all:          Build all system configurations
* nix:build:work:         Build work system configuration

* nix:refresh:            Apply system configuration (defaults to lv426)
* nix:refresh:lv426:      Apply lv426 (macOS) system configuration
* nix:refresh:arrakis:    Apply arrakis (NixOS) system configuration
* nix:refresh:work:       Apply work system configuration

* nix:config:             Copy nix configs to /etc/nix/
* nix:config:user:        Setup user-level nix.conf
* nix:secrets:init:       Initialize nix.secrets.conf with GitHub token
* nix:secrets:check:      Check nix secrets configuration
* nix:clean:              Clean Nix store and delete old generations
* nix:update:             Update Nix flake inputs and commit lock file
* nix:validate:           Validate Nix configuration

* fmt:nix:                Format all Nix files
* fmt:nix:check:          Check Nix formatting without modifying
* fmt:lua:                Format all Lua files
* fmt:lua:check:          Check Lua formatting without modifying
* fmt:lua:lint:           Run lua-language-server diagnostics
* fmt:lua:validate:       Validate Lua code (format + lint)
* fmt:sh:                 Format all shell files
* fmt:sh:check:           Check shell formatting without modifying
* fmt:all:                Format all file types
* fmt:all:check:          Check formatting for all file types
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
| `theme.transparency.blur` | integer | `80` |  | Background blur amount |
| `theme.transparency.opacity` | float | `0.7` |  | Transparency opacity level |
| `theme.variant` | string | - | ✓ | Theme variant |
| `user.username` | string | "user" |  | Username for the system user |
| `uvx.additionalPackages` | list(string) | [] |  | Additional global uvx packages |
| `vet.additionalPackages` | list(string) | [] |  | Additional Vet packages |
| `yarn.additionalPackages` | list(string) | [] |  | Additional global yarn packages |
<!-- VALUES_SCHEMA_END -->
