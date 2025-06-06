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
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
eval "$(/opt/homebrew/bin/brew shellenv)" && \
brew install go-task/tap/go-task
```

## Usage

```task
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
├── hack
│   ├── configs
│   └── lib
└── modules
    ├── darwin
    │   ├── configurations
    │   │   └── osx
    │   │       ├── dock
    │   │       ├── finder
    │   │       ├── hostname
    │   │       ├── security
    │   │       ├── system
    │   │       └── user
    │   └── packages
    ├── home
    │   ├── configurations
    │   │   ├── aider
    │   │   ├── atuin
    │   │   ├── bat
    │   │   ├── borders
    │   │   ├── colima
    │   │   ├── direnv
    │   │   ├── git
    │   │   ├── hammerspoon
    │   │   ├── k9s
    │   │   │   └── skins
    │   │   ├── macchina
    │   │   │   └── themes
    │   │   ├── mcp
    │   │   ├── neovim
    │   │   │   └── lua
    │   │   │       └── sysinit
    │   │   │           ├── pkg
    │   │   │           │   ├── autocmds
    │   │   │           │   ├── entrypoint
    │   │   │           │   ├── keybindings
    │   │   │           │   ├── opts
    │   │   │           │   └── utils
    │   │   │           └── plugins
    │   │   │               ├── _template
    │   │   │               ├── collections
    │   │   │               ├── debugger
    │   │   │               ├── editor
    │   │   │               ├── file
    │   │   │               ├── git
    │   │   │               ├── intellicode
    │   │   │               ├── keymaps
    │   │   │               ├── library
    │   │   │               └── ui
    │   │   ├── omp
    │   │   ├── wezterm
    │   │   │   └── lua
    │   │   │       └── sysinit
    │   │   │           ├── pkg
    │   │   │           │   ├── core
    │   │   │           │   ├── keybindings
    │   │   │           │   └── ui
    │   │   │           └── plugins
    │   │   │               ├── file
    │   │   │               │   └── session
    │   │   │               └── ui
    │   │   │                   └── bar
    │   │   └── zsh
    │   │       ├── bin
    │   │       └── core
    │   └── packages
    │       ├── cargo
    │       ├── gh
    │       ├── go
    │       ├── kubectl
    │       ├── nixpkgs
    │       ├── node
    │       └── python
    ├── lib
    │   ├── activation
    │   └── shell
    └── nix
```
