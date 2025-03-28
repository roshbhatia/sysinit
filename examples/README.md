# Sysinit Work Configuration Example

This directory contains examples of how to use the sysinit flake for your work environment.

## Configuration Files

A work system can be configured with its own Nix configuration using the following:

- `flake.nix`: This should be minimal, pointing to the main flake in the sysinit repo.
- `config.nix`: Mirrors the config in the main repo, but has overrides for work-specific settings.

## Setup Instructions

1. Copy this directory to your work repository:

```bash
cp -r /path/to/sysinit/examples /path/to/work-config
```

2. Edit the `config.nix` file with your work-specific settings:
   - Update username and hostname
   - Configure git settings
   - Add work-specific homebrew packages
   - Configure files to install

3. Place your work-specific configuration files in the `work-configs/` directory:
   - SSH configuration
   - VPN configuration
   - Any other work-specific dotfiles

4. Build and activate your configuration:

```bash
cd /path/to/work-config
darwin-rebuild switch --flake .#default
```

## Troubleshooting & Rollback

If you encounter any issues with your configuration:

### Immediate Rollback to Previous Generation

```bash
# List available generations
home-manager generations

# Roll back to a previous generation
home-manager switch --generation 123

# System level rollback
darwin-rebuild switch --flake .#default --rollback
```

### File-Level Rollback

After using sysinit, all replaced files will have backups with timestamped extensions:

```bash
# Find backups
find ~ -name "*.backup-*" | grep ssh

# Restore a specific file
cp ~/.ssh/config.backup-20230101-120000 ~/.ssh/config
```

### Complete Reset

If you need to completely reset:

```bash
# Uninstall Nix and all configurations
/path/to/sysinit/uninstall-nix.sh
```

## Validation

The configuration includes multiple validation steps:

1. **Pre-build validation**: Checks all configuration values and file paths
2. **Build-time validation**: Ensures all files exist before trying to install them
3. **Post-install validation**: Verifies that files were installed correctly

## Work-Specific Tips

- Use relative paths for work files: `./work-configs/ssh-config` rather than absolute paths
- Keep sensitive files in a separate, gitignored directory
- For work laptops, consider adding these settings to your config:
  ```nix
  {
    security.pam.enableSudoTouchIdAuth = true;  # Enable TouchID for sudo
    system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;  # Better for coding
  }
  ```
