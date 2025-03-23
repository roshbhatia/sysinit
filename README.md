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

# Build and activate in one step
darwin-rebuild switch --flake .#default

# You can also use the hostname (if you've added it to the flake)
darwin-rebuild switch --flake .#lv426

# For machines with a different username
darwin-rebuild switch --flake ".#$(nix eval --impure --expr '(import ./flake.nix).lib.mkConfig "your-username"')"
```

You can customize configurations in the flake.nix file:

```nix
# Example in flake.nix for custom username
darwinConfigurations.custom = mkDarwinConfig { username = "your-custom-username"; };
```

Or use the provided helper function:

```bash
# For custom username
darwin-rebuild build --flake ".#$(nix eval --impure --expr '(import ./flake.nix).lib.mkConfig "your-username"')"
sudo ./result/activate
```

## Updating

After making changes to the configuration:

```bash
# Build and activate the updated configuration
darwin-rebuild switch --flake .#default
```

## Rebuilding from URL

If you want to build directly from the GitHub repository:

```bash
# Using the default configuration
darwin-rebuild switch --flake github:roshbhatia/sysinit#default

# Or with the hostname configuration
darwin-rebuild switch --flake github:roshbhatia/sysinit#lv426
```

## Using in Another Flake

You can use this configuration in another flake (e.g., for your work machine) by importing it as a dependency.

### Sample Work Flake

Here's an example of a work-specific flake that uses this configuration:

```nix
{
  description = "Work System Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Import sysinit base configuration
    sysinit = {
      url = "github:roshbhatia/sysinit";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        darwin.follows = "darwin";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, sysinit, ... }@inputs:
  let
    system = "aarch64-darwin";
    username = "your-work-username";
    homeDirectory = "/Users/${username}";
  in {
    # Main configuration
    darwinConfigurations.${username} = darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs username homeDirectory; };
      modules = [
        # Import base system configuration
        sysinit.darwinModules.default {
          inherit username homeDirectory;
        }
        
        # Work-specific system configuration
        ({ pkgs, ... }: {
          environment.systemPackages = with pkgs; [
            # Work packages here
          ];
          
          # Work-specific Homebrew packages
          homebrew.brews = [
            "work-specific-package"
          ];
          
          homebrew.casks = [
            "work-specific-app"
          ];
        })
        
        # Home Manager configuration
        home-manager.darwinModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs username homeDirectory; };
            backupFileExtension = "backup";
            users.${username} = { pkgs, ... }: {
              imports = [ 
                # Import base home configuration
                sysinit.darwinModules.home
                
                # Work-specific home configuration
                ({ ... }: {
                  programs.git = {
                    userEmail = "your-work-email@company.com";
                  };
                  # Other work-specific config here
                })
              ];
              
              home.username = username;
              home.homeDirectory = homeDirectory;
            };
          };
        }
      ];
    };
    
    # Set as default configuration
    darwinConfigurations.default = self.darwinConfigurations.${username};
  };
}
```

With this setup, you can build and activate from your work flake:

```bash
darwin-rebuild switch --flake .
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
