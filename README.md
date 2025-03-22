# SysInit

A Nix flake-based system configuration for macOS, using nix-darwin and home-manager.

## Installation

### 1. Install Prerequisites

Run the `install-deps.sh` script to install the required dependencies:

This will install:

- Xcode Command Line Tools
- Nix package manager
- Nix Flakes configuration
- Prepare system files for nix-darwin

### 2. Clone and Build

```bash
# Clone the repository
git clone https://github.com/roshbhatia/sysinit.git
cd sysinit

# For personal machines (username: rshnbhatia)
darwin-rebuild switch --flake .#default

# For machines with a different username
darwin-rebuild switch --flake ".#$(nix eval --impure --expr '(import ./flake.nix).mkConfig "your-username"')"

# For minimal setup without Homebrew
darwin-rebuild switch --flake .#minimal
```

You can customize configurations in the flake.nix file:

```nix
# Examples in flake.nix
darwinConfigurations.work = mkDarwinConfig { username = "your-work-username"; };
darwinConfigurations.work-minimal = mkDarwinConfig { username = "your-work-username"; enableHomebrew = false; };
```

Or use the provided helper functions:
```bash
# For custom username
darwin-rebuild switch --flake ".#$(nix eval --impure --expr '(import ./flake.nix).mkConfig "your-username"')"

# For custom username without Homebrew
darwin-rebuild switch --flake ".#$(nix eval --impure --expr '(import ./flake.nix).mkMinimalConfig "your-username"')"
```

## Updating

After making changes to the configuration:

```bash
# For personal configuration
darwin-rebuild switch --flake .#default

# For personal configuration without Homebrew
darwin-rebuild switch --flake .#minimal

# For work configuration
darwin-rebuild switch --flake .#work
```

## Rebuilding from URL

If you want to build directly from the GitHub repository:

```bash
# For personal configuration
darwin-rebuild switch --flake github:roshbhatia/sysinit#default

# For personal configuration without Homebrew
darwin-rebuild switch --flake github:roshbhatia/sysinit#minimal

# For work configuration
darwin-rebuild switch --flake github:roshbhatia/sysinit#work
```

## Maintenance

### Garbage Collection

To clean up old generations and free disk space:

```bash
nix-collect-garbage -d
```

### Updating Flake Inputs

To update all flake inputs:

```bash
nix flake update
```

To update a specific input:

```bash
nix flake lock --update-input nixpkgs
```

### Cleaning Up Backup Files

To remove any backup files created during nix-darwin installation or updates:

```bash
# Remove system backup files
sudo rm -f /etc/*.before-nix-darwin

# Remove home directory backup files
rm -f $HOME/.*.backup* $HOME/.*.bak

# Remove XDG config backup files
find $HOME/.config -name "*.backup" -o -name "*.bak" -exec rm -f {} \;
```

### Reinstalling After Deleting 'result' Directory

If you've deleted the `result` directory and need to reinstall:

1. Use the `no-homebrew` flag to reinstall without Homebrew dependencies:
   ```bash
   darwin-rebuild switch --flake .#default no-homebrew
   ```

2. This will reinstall all configuration files with the comment:
   ```
   # THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
   ```
