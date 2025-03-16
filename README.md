# SysInit

A command line tool to deploy personal dotfiles and development environment configuration.

## Installation

```bash
go install github.com/roshbhatia/sysinit@latest
```

## Usage

```bash
# Install all components
sysinit install

# Install specific components
sysinit install --components starship,k9s,zsh

# Legacy script installation (bash)
./install.sh
```

## Available Components

- starship - Cross-shell prompt
- k9s - Kubernetes CLI
- atuin - Shell history
- macchina - System info
- zsh - ZSH configs
- git - Git configs
- rio - Terminal emulator
- grugnvim - Neovim setup
