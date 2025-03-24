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

SysInit now supports a customizable configuration system through a `config.nix` file. This allows you to easily customize various aspects of your setup without modifying the core files.

### Default Config Structure

The default `config.nix` file looks like this:

```nix
{
  # User and system configuration
  user = {
    username = "rshnbhatia";  # Default username
    hostname = "lv426";       # Default hostname
  };

  # Additional Homebrew packages to install
  homebrew = {
    additionalPackages = {
      taps = [
        # Add additional taps here
        # Example: "user/repo"
      ];

      brews = [
        # Add additional brew packages here
        # Example: "package-name"
      ];

      casks = [
        # Add additional cask applications here
        # Example: "app-name"
      ];
    };
  };

  # Wallpaper configuration
  wallpaper = {
    path = "./wall/mvp2.jpg";  # Default wallpaper path
  };

  # Files to install in home directory
  install = [
    # Example file installation
    # {
    #   source = "./path/to/source/file";
    #   destination = ".config/destination/file";
    # }
  ];
}
```

## Custom Work Setup Example

There are two ways to use SysInit for a custom work setup:

### Option 1: Create a Custom Config File

This is the simplest approach - just create a custom config file and reference it when building:

1. Create a work-specific config file:

```nix
# work-config.nix
{
  user = {
    username = "roshanatwork";
    hostname = "work-macbook"; 
  };

  homebrew = {
    additionalPackages = {
      taps = [
        "company/internal"
      ];

      brews = [
        "work-specific-tool"
      ];

      casks = [
        "company-chat-app"
        "company-vpn"
      ];
    };
  };

  wallpaper = {
    path = "./wall/company-logo.jpg";
  };

  install = [
    {
      source = "./work-configs/vpn-config";
      destination = ".config/vpn/config";
    }
  ];
}
```

2. Build using the custom config:

```bash
darwin-rebuild switch --flake .#lib.mkConfigWithFile ./work-config.nix
```

### Option 2: Create a separate flake that imports SysInit

For more advanced customization, create a separate flake that imports SysInit:

```nix
{
  description = "Work System Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sysinit.url = "github:roshbhatia/sysinit";
    sysinit.inputs = {
      nixpkgs.follows = "nixpkgs";
      darwin.follows = "darwin";
      home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, sysinit, ... }@inputs:
  let
    system = "aarch64-darwin";
    config = {
      user = {
        username = "roshanatwork";
        hostname = "work-macbook";
      };
      
      homebrew = {
        additionalPackages = {
          brews = [ "work-specific-tool" ];
          casks = [ "company-chat-app" "company-vpn" ];
        };
      };
      
      wallpaper = {
        path = "./wall/company-logo.jpg";
      };
    };
    username = config.user.username;
    homeDirectory = "/Users/${username}";
  in {
    darwinConfigurations.work = darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs username homeDirectory config; };
      modules = [
        # Import sysinit base config
        sysinit.darwinModules.default {
          inherit username homeDirectory config;
        }
        
        # Home Manager config
        home-manager.darwinModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs username homeDirectory config; };
            users.${username} = { pkgs, ... }: {
              imports = [ 
                sysinit.darwinModules.home {
                  inherit username homeDirectory config;
                }
                
                # Additional work-specific configurations
                ({ ... }: {
                  programs.git = {
                    userEmail = "roshan@work.com";
                  };
                })
              ];
            };
          };
        }
      ];
    };
    
    # Set as default
    darwinConfigurations.default = self.darwinConfigurations.work;
  };
}
```

### Example Files

Check out the `examples/` directory for:
- `work-config.nix`: An example configuration file for a work setup
- `work-flake.nix`: An example flake file for a separate repository that imports SysInit
