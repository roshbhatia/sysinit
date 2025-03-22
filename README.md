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

# For personal machines (with all apps)
darwin-rebuild switch --flake .#default

# OR for work machines (without personal apps)
darwin-rebuild switch --flake .#work

# For minimal setup without Homebrew
darwin-rebuild switch --flake .#default no-homebrew
```

## Updating

After making changes to the configuration:

```bash
# For personal configuration
darwin-rebuild switch --flake .#default

# For work configuration
darwin-rebuild switch --flake .#work

# For minimal setup without Homebrew
darwin-rebuild switch --flake .#default no-homebrew
```

## Rebuilding from URL

If you want to build directly from the GitHub repository:

```bash
# For personal configuration
darwin-rebuild switch --flake github:roshbhatia/sysinit#default

# For work configuration
darwin-rebuild switch --flake github:roshbhatia/sysinit#work

# For minimal setup without Homebrew
darwin-rebuild switch --flake github:roshbhatia/sysinit#default no-homebrew
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
