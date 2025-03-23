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

# For personal machines (using default configuration)
darwin-rebuild switch --flake .

# For a specific configuration profile (default, minimal, work)
darwin-rebuild switch --flake .#default

# For machines with a different username
darwin-rebuild switch --flake ".#$(nix eval --impure --expr '(import ./flake.nix).lib.mkConfig "your-username"')"

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
darwin-rebuild switch --flake ".#$(nix eval --impure --expr '(import ./flake.nix).lib.mkConfig "your-username"')"

# For custom username without Homebrew
darwin-rebuild switch --flake ".#$(nix eval --impure --expr '(import ./flake.nix).lib.mkMinimalConfig "your-username"')"
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

## Using in Another Flake

You can use this configuration in another flake (e.g., for your work machine) by importing it as a dependency.

### Sample Work Flake

Here's an example of how to create a work-specific flake that uses this configuration:

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
    
    # Import the base configuration from sysinit
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
    system = "aarch64-darwin"; # For Apple Silicon
    username = "your-work-username";
    homeDirectory = "/Users/${username}";
  in {
    # Create a simpler named configuration so you can just run:
    # darwin-rebuild switch --flake .
    darwinConfigurations.${username} = darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs username homeDirectory; };
      modules = [
        # Import the base configuration module from sysinit
        sysinit.darwinModules.default {
          inherit username homeDirectory;
          # You can override parameters here
          enableHomebrew = true;
        }
        
        # Add your work-specific configuration
        ({ pkgs, ... }: {
          # Add work-specific packages
          environment.systemPackages = with pkgs; [
            # Add work-specific packages here
          ];
          
          # Work-specific Homebrew packages
          homebrew.brews = [
            "work-specific-package"
          ];
          
          homebrew.casks = [
            "work-specific-app"
          ];
        })
        
        # Import the Home Manager configuration 
        home-manager.darwinModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs username homeDirectory; };
            backupFileExtension = "backup";
            users.${username} = { pkgs, ... }: {
              imports = [ 
                # Import the base home configuration
                sysinit.darwinModules.home
                
                # Add your work-specific home configuration
                ({ ... }: {
                  # Work-specific home configuration here
                })
              ];
              
              # Override username and home directory
              home.username = username;
              home.homeDirectory = homeDirectory;
            };
          };
        }
      ];
    };
    
    # This allows you to run: darwin-rebuild switch --flake .
    darwinConfigurations.default = self.darwinConfigurations.${username};
  };
}
```

With this setup, you can simply run:

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
