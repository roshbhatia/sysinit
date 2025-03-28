# SysInit Work Configuration Example

This directory contains examples of how to use the SysInit flake for your work environment.

## Configuration Files

A work system can be configured with its own Nix configuration using the following:

- `flake.nix`: A minimal flake that references the main SysInit flake.
- `config.nix`: Contains work-specific settings that override the default configuration.

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

3. Update the `flake.nix` to point to your SysInit repository:

```nix
{
  inputs.sysinit = {
    url = "github:roshbhatia/sysinit";
    # Or for local development:
    # url = "/path/to/sysinit";
  };

  outputs = { self, sysinit }: {
    darwinConfigurations.default = sysinit.lib.mkConfigWithFile ./config.nix;
  };
}
```

4. Place any work-specific configuration files in a directory inside your work repository.

5. Add those files to the `install` list in your `config.nix`:

```nix
{
  # ...other config...
  
  install = [
    {
      source = "./work-configs/ssh-config";
      destination = "/Users/yourusername/.ssh/config";
    }
    {
      source = "./work-configs/vpn-config";
      destination = "/Users/yourusername/.config/vpn/config";
    }
  ];
}
```

6. Build and activate your configuration:

```bash
cd /path/to/work-config
darwin-rebuild switch --flake .#default
```

## Validation

The configuration includes robust validation:

1. **Configuration validation**: Checks all required fields and file paths
2. **File installation validation**: The test file `modules/test/nix-install-test.yaml` is automatically installed to `~/.config/nix-test.yaml` to validate the installation process works

## Troubleshooting

If you encounter issues:

### Rollback to Previous Configuration

```bash
# Roll back to the previous system generation
darwin-rebuild switch --rollback

# Or for home-manager configuration
home-manager switch --rollback
```

### File-Level Rollback

Home Manager creates backups of replaced files:

```bash
# Find backups with the backup extension
find ~ -name "*.backup" | grep ssh

# Restore a specific file
cp ~/.ssh/config.backup ~/.ssh/config
```

## Work-Specific Tips

- Keep sensitive configuration in a separate, gitignored directory
- Use the `install` list for work-specific dotfiles
- Consider adding these useful settings to your work configuration:

```nix
{
  security.pam.enableSudoTouchIdAuth = true;  # Enable TouchID for sudo
  system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;  # Better for coding
  system.defaults.dock.autohide = true;  # Auto-hide the dock for more screen space
}
```