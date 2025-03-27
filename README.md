# SysInit

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

A Nix flake-based system configuration for macOS, using nix-darwin and home-manager.

Sysinit includes a direnv-like feature for automatically loading development environments:

1. Place a `devenv.shell.nix` file in your project directory
2. When you `cd` into that directory, the environment activates automatically
3. The environment stays active in subdirectories and deactivates when you leave

### Usage

```bash
# Initialize a new devenv.shell.nix file in your project
devenv.init

# Manually activate a devenv.shell.nix in current directory
devenv.nix.shell

# Get help
devenv.nix.shell --help
```

Shell integration works with Nushell first, but falls back to ZSH if `nu` isn't present.

## Quick Install

```bash
# Install dependencies
./install-deps.sh

# Build and activate
darwin-rebuild switch --flake .#default

# Remove everything
./uninstall-nix.sh

# Update all flake inputs
nix flake update

# Cleanup old generations
nix-collect-garbage -d
```

## Configuration System

SysInit supports a customizable configuration system through a `config.nix` file. This allows you to easily customize various aspects of your setup without modifying the core files.

### Example Files

Check out the `examples/` directory for:

- `config.nix`: An example configuration file for a work setup
- `flake.nix`: An example flake file for a separate repository that imports SysInit
