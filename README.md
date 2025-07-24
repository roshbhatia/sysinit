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

## Project Structure

```text
.
├── flake.lock
├── flake.nix
├── hack
│   ├── configs
│   │   ├── bootstrap-flake.nix
│   │   ├── darwin-configuration.nix
│   │   └── darwin-rebuild-script
│   ├── install-deps.sh
│   ├── lib
│   │   └── logger.sh
│   └── uninstall-deps.sh
├── modules
│   ├── darwin
│   │   ├── configurations
│   │   │   ├── default.nix
│   │   │   └── osx
│   │   │       ├── default.nix
│   │   │       ├── dock
│   │   │       │   └── default.nix
│   │   │       ├── finder
│   │   │       │   └── default.nix
│   │   │       ├── hostname
│   │   │       │   └── default.nix
│   │   │       ├── security
│   │   │       │   └── default.nix
│   │   │       ├── system
│   │   │       │   └── default.nix
│   │   │       └── user
│   │   │           └── default.nix
│   │   ├── default.nix
│   │   └── packages
│   │       ├── default.nix
│   │       └── homebrew.nix
│   ├── home
│   │   ├── configurations
│   │   │   ├── aerospace
│   │   │   │   ├── aerospace.nix
│   │   │   │   ├── aerospace.toml
│   │   │   │   └── default.nix
│   │   │   ├── aider
│   │   │   │   ├── aider.conf.yml
│   │   │   │   ├── aider.nix
│   │   │   │   └── default.nix
│   │   │   ├── atuin
│   │   │   │   ├── atuin.nix
│   │   │   │   ├── catppuccin-macchiato.toml
│   │   │   │   ├── default.nix
│   │   │   │   ├── gruvbox-dark.toml
│   │   │   │   ├── rose-pine-moon.toml
│   │   │   │   └── solarized-dark.toml
│   │   │   ├── bat
│   │   │   │   ├── bat.nix
│   │   │   │   ├── Catppuccin-Macchiato.tmTheme
│   │   │   │   ├── default.nix
│   │   │   │   └── Rose-Pine-Moon.tmTheme
│   │   │   ├── borders
│   │   │   │   ├── borders.nix
│   │   │   │   ├── bordersrc.sh
│   │   │   │   └── default.nix
│   │   │   ├── colima
│   │   │   │   ├── colima.nix
│   │   │   │   ├── colimactl.sh
│   │   │   │   ├── default.nix
│   │   │   │   └── dockercerts.sh
│   │   │   ├── default.nix
│   │   │   ├── direnv
│   │   │   │   ├── default.nix
│   │   │   │   └── direnv.nix
│   │   │   ├── git
│   │   │   │   ├── catppuccin.gitconfig
│   │   │   │   ├── default.nix
│   │   │   │   ├── git.nix
│   │   │   │   ├── gitignore.global
│   │   │   │   ├── gruvbox.gitconfig
│   │   │   │   ├── lazygit.yaml
│   │   │   │   ├── rose-pine.gitconfig
│   │   │   │   └── solarized.gitconfig
│   │   │   ├── k9s
│   │   │   │   ├── default.nix
│   │   │   │   ├── k9s.nix
│   │   │   │   └── skins
│   │   │   │       ├── catppuccin.yaml
│   │   │   │       ├── gruvbox.yaml
│   │   │   │       ├── rose-pine.yaml
│   │   │   │       └── solarized.yaml
│   │   │   ├── macchina
│   │   │   │   ├── default.nix
│   │   │   │   ├── macchina.nix
│   │   │   │   └── themes
│   │   │   │       ├── mgs.ascii
│   │   │   │       ├── nix.ascii
│   │   │   │       ├── rosh-color.ascii
│   │   │   │       └── rosh.ascii
│   │   │   ├── mcp
│   │   │   │   ├── default.nix
│   │   │   │   ├── goose.yaml
│   │   │   │   ├── goosehints.md
│   │   │   │   ├── mcp.nix
│   │   │   │   ├── mcphub.json
│   │   │   │   └── opencode.json
│   │   │   ├── neovim
│   │   │   │   ├── _template
│   │   │   │   │   └── sysinit.nvim.conf.json
│   │   │   │   ├── default.nix
│   │   │   │   ├── init.lua
│   │   │   │   ├── lua
│   │   │   │   │   └── sysinit
│   │   │   │   │       ├── config
│   │   │   │   │       │   └── nvim_config.lua
│   │   │   │   │       ├── pkg
│   │   │   │   │       │   ├── autocmds
│   │   │   │   │       │   │   ├── buf.lua
│   │   │   │   │       │   │   ├── force_transparency.lua
│   │   │   │   │       │   │   ├── help.lua
│   │   │   │   │       │   │   └── wezterm.lua
│   │   │   │   │       │   ├── entrypoint
│   │   │   │   │       │   │   └── no-session.lua
│   │   │   │   │       │   ├── keybindings
│   │   │   │   │       │   │   ├── buffer.lua
│   │   │   │   │       │   │   ├── editor.lua
│   │   │   │   │       │   │   ├── leader.lua
│   │   │   │   │       │   │   ├── marks.lua
│   │   │   │   │       │   │   ├── super.lua
│   │   │   │   │       │   │   ├── undo.lua
│   │   │   │   │       │   │   └── vim.lua
│   │   │   │   │       │   ├── opts
│   │   │   │   │       │   │   ├── autoread.lua
│   │   │   │   │       │   │   ├── completion.lua
│   │   │   │   │       │   │   ├── echo.lua
│   │   │   │   │       │   │   ├── editor.lua
│   │   │   │   │       │   │   ├── environment.lua
│   │   │   │   │       │   │   ├── folding.lua
│   │   │   │   │       │   │   ├── indentation.lua
│   │   │   │   │       │   │   ├── leader.lua
│   │   │   │   │       │   │   ├── performance.lua
│   │   │   │   │       │   │   ├── scroll.lua
│   │   │   │   │       │   │   ├── search.lua
│   │   │   │   │       │   │   ├── split_behavior.lua
│   │   │   │   │       │   │   ├── ui.lua
│   │   │   │   │       │   │   ├── undo.lua
│   │   │   │   │       │   │   └── wrapping.lua
│   │   │   │   │       │   ├── pre
│   │   │   │   │       │   │   └── profiler.lua
│   │   │   │   │       │   └── utils
│   │   │   │   │       │       └── plugin_manager.lua
│   │   │   │   │       └── plugins
│   │   │   │   │           ├── _template
│   │   │   │   │           │   └── _template.lua
│   │   │   │   │           ├── core
│   │   │   │   │           │   ├── luarocks.lua
│   │   │   │   │           │   └── plenary.lua
│   │   │   │   │           ├── debugger
│   │   │   │   │           │   ├── dap-ui.lua
│   │   │   │   │           │   ├── dap-virtual-text.lua
│   │   │   │   │           │   ├── dap.lua
│   │   │   │   │           │   ├── nvim-dap-docker.lua
│   │   │   │   │           │   └── nvim-dap-go.lua
│   │   │   │   │           ├── editor
│   │   │   │   │           │   ├── bqf.lua
│   │   │   │   │           │   ├── colorizer.lua
│   │   │   │   │           │   ├── comment.lua
│   │   │   │   │           │   ├── foldsign.lua
│   │   │   │   │           │   ├── hlchunk.lua
│   │   │   │   │           │   ├── hop.lua
│   │   │   │   │           │   ├── intellitab.lua
│   │   │   │   │           │   ├── markdown-preview.lua
│   │   │   │   │           │   ├── marks.lua
│   │   │   │   │           │   ├── move.lua
│   │   │   │   │           │   ├── multicursor.lua
│   │   │   │   │           │   └── render-markdown.lua
│   │   │   │   │           ├── file
│   │   │   │   │           │   ├── neo-tree.lua
│   │   │   │   │           │   ├── oil.lua
│   │   │   │   │           │   ├── persisted.lua
│   │   │   │   │           │   └── telescope.lua
│   │   │   │   │           ├── git
│   │   │   │   │           │   ├── blamer.lua
│   │   │   │   │           │   ├── fugitive.lua
│   │   │   │   │           │   └── signs.lua
│   │   │   │   │           ├── intellicode
│   │   │   │   │           │   ├── avante.lua
│   │   │   │   │           │   ├── blink-cmp.lua
│   │   │   │   │           │   ├── cmp-copilot.lua
│   │   │   │   │           │   ├── conform.lua
│   │   │   │   │           │   ├── copilot-chat.lua
│   │   │   │   │           │   ├── copilot.lua
│   │   │   │   │           │   ├── dropbar.lua
│   │   │   │   │           │   ├── fastaction.lua
│   │   │   │   │           │   ├── friendly-snippets.lua
│   │   │   │   │           │   ├── glance.lua
│   │   │   │   │           │   ├── goose.lua
│   │   │   │   │           │   ├── lazydev.lua
│   │   │   │   │           │   ├── lsp-lines.lua
│   │   │   │   │           │   ├── lspkind.lua
│   │   │   │   │           │   ├── luasnip.lua
│   │   │   │   │           │   ├── minty.lua
│   │   │   │   │           │   ├── none-ls.lua
│   │   │   │   │           │   ├── nvim-autopairs.lua
│   │   │   │   │           │   ├── nvim-lspconfig.lua
│   │   │   │   │           │   ├── opencode.lua
│   │   │   │   │           │   ├── outline.lua
│   │   │   │   │           │   ├── pretty-hover.lua
│   │   │   │   │           │   ├── refactoring.lua
│   │   │   │   │           │   ├── schemastore.lua
│   │   │   │   │           │   ├── sort.lua
│   │   │   │   │           │   ├── trailspace.lua
│   │   │   │   │           │   ├── treesitter-context.lua
│   │   │   │   │           │   ├── treesitter.lua
│   │   │   │   │           │   ├── trouble.lua
│   │   │   │   │           │   └── typescript-tools.lua
│   │   │   │   │           ├── keymaps
│   │   │   │   │           │   └── which-key.lua
│   │   │   │   │           ├── library
│   │   │   │   │           │   ├── nio.lua
│   │   │   │   │           │   ├── nui.lua
│   │   │   │   │           │   ├── snacks.lua
│   │   │   │   │           │   └── volt.lua
│   │   │   │   │           └── ui
│   │   │   │   │               ├── alpha.lua
│   │   │   │   │               ├── auto-cmdheight.lua
│   │   │   │   │               ├── devicons.lua
│   │   │   │   │               ├── dressing.lua
│   │   │   │   │               ├── edgy.lua
│   │   │   │   │               ├── live-command.lua
│   │   │   │   │               ├── minimap.lua
│   │   │   │   │               ├── neoscroll.lua
│   │   │   │   │               ├── scrollview.lua
│   │   │   │   │               ├── smart-splits.lua
│   │   │   │   │               ├── staline.lua
│   │   │   │   │               ├── themes.lua
│   │   │   │   │               ├── tiny-devicons-auto-colors.lua
│   │   │   │   │               ├── tiny-glimmer.lua
│   │   │   │   │               └── wilder.lua
│   │   │   │   └── neovim.nix
│   │   │   ├── omp
│   │   │   │   ├── default.nix
│   │   │   │   └── omp.nix
│   │   │   ├── treesitter
│   │   │   │   ├── default.nix
│   │   │   │   └── treesitter.nix
│   │   │   ├── wezterm
│   │   │   │   ├── default.nix
│   │   │   │   ├── lua
│   │   │   │   │   └── sysinit
│   │   │   │   │       ├── pkg
│   │   │   │   │       │   ├── core
│   │   │   │   │       │   │   └── init.lua
│   │   │   │   │       │   ├── keybindings
│   │   │   │   │       │   │   └── init.lua
│   │   │   │   │       │   ├── theme
│   │   │   │   │       │   │   └── init.lua
│   │   │   │   │       │   └── ui
│   │   │   │   │       │       └── init.lua
│   │   │   │   │       └── plugins
│   │   │   │   │           ├── terminal
│   │   │   │   │           │   └── toggle
│   │   │   │   │           │       └── init.lua
│   │   │   │   │           └── ui
│   │   │   │   │               └── tabline
│   │   │   │   │                   └── init.lua
│   │   │   │   ├── wezterm.lua
│   │   │   │   └── wezterm.nix
│   │   │   └── zsh
│   │   │       ├── bin
│   │   │       │   ├── dns-flush
│   │   │       │   ├── fzf-preview
│   │   │       │   ├── gh-whoami
│   │   │       │   └── git-ai-commit
│   │   │       ├── core
│   │   │       │   ├── completions.sh
│   │   │       │   ├── env.sh
│   │   │       │   ├── extras.sh
│   │   │       │   ├── kubectl.sh
│   │   │       │   ├── loglib.sh
│   │   │       │   ├── paths.sh
│   │   │       │   ├── prompt.sh
│   │   │       │   └── wezterm.sh
│   │   │       ├── default.nix
│   │   │       └── zsh.nix
│   │   ├── default.nix
│   │   └── packages
│   │       ├── cargo
│   │       │   ├── cargo.nix
│   │       │   └── default.nix
│   │       ├── default.nix
│   │       ├── gh
│   │       │   ├── default.nix
│   │       │   └── gh.nix
│   │       ├── go
│   │       │   ├── default.nix
│   │       │   └── go.nix
│   │       ├── kubectl
│   │       │   ├── default.nix
│   │       │   └── krew.nix
│   │       ├── nixpkgs
│   │       │   ├── default.nix
│   │       │   └── nixpkgs.nix
│   │       ├── node
│   │       │   ├── default.nix
│   │       │   ├── npm.nix
│   │       │   └── yarn.nix
│   │       └── python
│   │           ├── default.nix
│   │           ├── pipx.nix
│   │           └── uvx.nix
│   ├── lib
│   │   ├── activation
│   │   │   ├── default.nix
│   │   │   └── library.sh
│   │   ├── shell
│   │   │   └── default.nix
│   │   ├── theme-module.nix
│   │   └── themes
│   │       └── default.nix
│   └── nix
│       └── default.nix
├── README.md
├── Taskfile.yml
└── values.nix
```

