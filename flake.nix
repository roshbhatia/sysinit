{
  description = "roshbhatia's system configuration";

  inputs = {
    # Core dependencies
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    # Darwin support
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Homebrew integration
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, nix-homebrew, homebrew-bundle, ... }@inputs:
  let
    system = "aarch64-darwin"; # For Apple Silicon
    
    # Common darwin configuration function with a personal flag
    mkDarwinConfig = { includePersonal ? true }: darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        # System config with personal flag
        {
          sysinit.includePersonal = includePersonal;
        }
        ./modules/darwin
        home-manager.darwinModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.${builtins.getEnv "USER"} = import ./modules/home;
        }
        nix-homebrew.darwinModules.nix-homebrew {
          nix-homebrew = {
            enable = true;
            user = builtins.getEnv "USER";
            autoMigrate = true;
            taps = {
              "homebrew/homebrew-bundle" = homebrew-bundle;
            };
          };
        }
      ];
    };
  in {
    # Default configuration with personal applications
    darwinConfigurations.default = mkDarwinConfig { 
      includePersonal = true; 
    };
    
    # Work configuration without personal applications
    darwinConfigurations.work = mkDarwinConfig { 
      includePersonal = false; 
    };
  };
}