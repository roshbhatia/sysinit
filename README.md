# SysInit - Robust macOS Configuration System

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

A comprehensive Nix flake-based system configuration for macOS, using nix-darwin and home-manager, with robust validation and rollback capabilities.

## Features

- **Comprehensive Validation**: At every step of the configuration and installation process
- **Automated Rollback**: Multiple levels of rollback capability, from file-level to complete system reset
- **Flexible Configuration**: Support for both personal and work environments
- **Auto-activating Development Environments**: Like direnv, but integrated with your shell

## Quick Install

```bash
# Install dependencies
./install-deps.sh

# Build and activate
darwin-rebuild switch --flake .#default

# Update all flake inputs
nix flake update

# Cleanup old generations
nix-collect-garbage -d
```

## Validation System

Sysinit includes a robust validation system at multiple levels:

1. **Configuration Validation**:
   - Checks for required configuration properties
   - Validates file paths before attempting to use them
   - Ensures configuration syntax is correct

2. **Build-time Validation**:
   - Verifies all source files exist
   - Checks for proper file permissions
   - Validates environment variables

3. **Post-installation Validation**:
   - Verifies files were installed correctly
   - Validates symlinks point to correct targets
   - Reports success/failure of each action

## Rollback Capabilities

If anything goes wrong, Sysinit provides multiple ways to roll back changes:

1. **Generation-based Rollback**:
   ```bash
   # System level
   darwin-rebuild switch --rollback
   
   # Home-manager level
   home-manager switch --generation 123
   ```

2. **File-level Rollback**:
   All replaced files are automatically backed up with timestamped extensions:
   ```bash
   # Find backups
   find ~ -name "*.backup-*" | grep config
   
   # Restore a specific file
   cp ~/.config/app/config.backup-20230101-120000 ~/.config/app/config
   ```

3. **Complete Reset**:
   If you need to start fresh, use the included uninstall script:
   ```bash
   ./uninstall-nix.sh
   ```

## Development Environment Feature

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

## Configuration System

SysInit supports a customizable configuration system through a `config.nix` file. This allows you to easily customize various aspects of your setup without modifying the core files.

### Using with Work Configurations

Sysinit can be used as a source for work-specific configurations:

1. Copy the examples directory to your work repo:
   ```bash
   cp -r ./examples /path/to/work-config
   ```

2. Customize the `config.nix` file with your work-specific settings
3. Add your work-specific files to the `work-configs` directory
4. Build and apply the configuration:
   ```bash
   cd /path/to/work-config
   darwin-rebuild switch --flake .#default
   ```

See the [examples/README.md](examples/README.md) for detailed instructions on setting up a work configuration.

## Troubleshooting

If you encounter issues:

1. Check the validation error messages for specific problems
2. Review the installation logs for details on what failed
3. Follow the rollback instructions to return to a working state
4. Check the [install-deps.sh](install-deps.sh) script for detailed troubleshooting guidance
