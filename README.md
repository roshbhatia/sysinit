# SysInit - Refined macOS Configuration System

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

A streamlined Nix flake-based system configuration for macOS, using nix-darwin and home-manager with simplified structure.

## Features

- **Simplified Configuration**: Clean and maintainable flake structure
- **Robust Validation**: Configuration validation with clear error messages
- **Custom File Installation**: Easy installation of dotfiles and configurations
- **Integrated Homebrew**: Seamless integration with Homebrew packages
- **Modular Design**: Easily add or remove components

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

## Configuration System

SysInit uses a `config.nix` file for customization. This allows you to easily customize various aspects of your setup without modifying the core files.

### Configuration Structure

The `config.nix` file contains the following sections:

```nix
{
  # User information
  user = {
    username = "yourusername";
    hostname = "yourhostname";
  };

  # Git configuration
  git = {
    userName = "Your Name";
    userEmail = "your.email@example.com";
    githubUser = "yourgithubuser";
    credentialUsername = "yourgithubuser";
  };

  # Homebrew packages (optional)
  homebrew = {
    additionalPackages = {
      taps = [];
      brews = [];
      casks = ["app1" "app2"];
    };
  };

  # Wallpaper (optional)
  wallpaper = {
    path = "wall/image.jpeg";  # Path relative to flake root
  };

  # Files to install (optional)
  install = [
    # Test file for validation
    {
      source = "modules/test/nix-install-test.yaml";
      destination = "/Users/yourusername/.config/nix-test/nix-test.yaml";
    }
    
    # Custom file installation
    {
      source = "examples/work-configs/ssh-config";
      destination = "/Users/yourusername/.ssh/config";
    }
  ];
}
```

### File Installation

SysInit allows you to automatically install files during system activation:

1. Add entries to the `install` list in your `config.nix` file
2. Each entry must have `source` (relative to flake or absolute) and `destination` paths
3. Files are copied during system activation

The test file `modules/test/nix-install-test.yaml` is included in the default config.nix and installed to `~/.config/nix-test/nix-test.yaml` to validate the installation process.

## Structure Overview

- **flake.nix**: The main entry point, simplified and streamlined
- **config.nix**: User configuration with validation
- **modules/darwin/**: System-level macOS configuration modules
- **modules/home/**: Home-manager user environment configuration
- **modules/test/**: Test files for validation

## Development

### Adding New Modules

1. Create a new module file in `modules/darwin/` or `modules/home/`
2. Import it in the appropriate `default.nix` file
3. Add any necessary configuration options to `config.nix`

### Using with Work Configurations

1. Copy the examples directory to your work repo
2. Customize the `config.nix` file with your work-specific settings
3. Add your work-specific files to be installed via the `install` list
4. Build and apply the configuration

## Troubleshooting

If you encounter issues:

1. Check error messages for validation failures
2. Verify that all paths in the configuration exist
3. Check that required fields are properly set in `config.nix`
4. Use `darwin-rebuild switch --rollback` to revert to previous configuration