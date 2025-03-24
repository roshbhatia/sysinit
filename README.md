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

## Custom Work Setup Example

Create a work-specific flake that inherits from sysinit:

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
    username = "roshanatwork";  # Change this
    homeDirectory = "/Users/${username}";
  in {
    darwinConfigurations.work = darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs username homeDirectory; };
      modules = [
        # Import sysinit base config
        sysinit.darwinModules.default {
          inherit username homeDirectory;
        }
        
        # Work-specific Homebrew packages
        ({ pkgs, ... }: {
          homebrew.taps = []

          homebrew.brews = [
            "work-specific-tool"
          ];
          
          homebrew.casks = [
            "company-chat-app"
            "company-vpn"
          ];
        })
        
        # Home Manager config
        home-manager.darwinModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs username homeDirectory; };
            users.${username} = { pkgs, ... }: {
              imports = [ 
                sysinit.darwinModules.home
                # Work Git Config
                ({ ... }: {
                  programs.git = {
                    userEmail = "roshan@work.com";
                  };
                })
              ];
              
              home.username = username;
              home.homeDirectory = homeDirectory;
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
