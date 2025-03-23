{
  description = "Roshan's OSX DevEnv System Config";

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
    
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, nix-homebrew, homebrew-core, homebrew-cask, ... }@inputs:
  let
    system = "aarch64-darwin"; # For Apple Silicon
    defaultUsername = "rshnbhatia";
    
    # Common darwin configuration function
    mkDarwinConfig = { 
      username ? defaultUsername,
      enableHomebrew ? true
    }: 
    let
      homeDirectory = "/Users/${username}";
    in
    darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs username homeDirectory enableHomebrew; };
      modules = [
        # Main system configuration
        ./modules/darwin/darwin.nix
        
        # Home Manager configuration
        home-manager.darwinModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs username homeDirectory; };
            backupFileExtension = "backup";
            users.${username} = { pkgs, ... }: {
              imports = [ ./modules/home ];
              home.username = pkgs.lib.mkForce username;
              home.homeDirectory = pkgs.lib.mkForce homeDirectory;
              nixpkgs = {};
            };
          };
        }
      ];
    };
    
    # Helper module for including in other flakes
    darwinModules = {
      default = { username, homeDirectory ? "/Users/${username}", enableHomebrew ? true, ... }: {
        imports = [
          ./modules/darwin/darwin.nix
        ];
        
        # Pass the required parameters
        _module.args = {
          inherit username homeDirectory enableHomebrew inputs;
        };
      };
      
      home = { username, homeDirectory ? "/Users/${username}", ... }: {
        imports = [ ./modules/home ];
        home.username = username;
        home.homeDirectory = homeDirectory;
      };
    };
    
    # Simple bootstrap configuration for initial nix-darwin installation
    bootstrapConfig = 
    let
      bootstrapUsername = defaultUsername;
      bootstrapHomeDirectory = "/Users/${bootstrapUsername}";
    in
    darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { 
        username = bootstrapUsername;
        homeDirectory = bootstrapHomeDirectory;
      };
      modules = [{
        # Minimal configuration
        system.stateVersion = 4;
        users.users.${bootstrapUsername}.home = bootstrapHomeDirectory;
        nix.enable = false;
        nix.settings.experimental-features = [ "nix-command" "flakes" ];
        environment.systemPackages = with nixpkgs.legacyPackages.${system}; [
          git
          curl
        ];
        system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
        system.defaults.finder.AppleShowAllExtensions = true;
        security.pam.services.sudo_local.touchIdAuth = true;
      }];
    };
  in {
    # Named configurations
    darwinConfigurations = {
      # Main configuration for personal setup
      default = mkDarwinConfig {};
      
      # Also set as hostname-based configuration for simplified commands
      "${builtins.readFile "/etc/hostname" or "MacBook-Pro"}" = mkDarwinConfig {};
      
      # Minimal configuration without Homebrew
      minimal = mkDarwinConfig { enableHomebrew = false; };
      
      # Example work configuration
      work = mkDarwinConfig { username = "your-work-username"; };
      
      # Bootstrap configuration for initial setup
      bootstrap = bootstrapConfig;
    };
    
    # Helper functions for creating configurations dynamically
    lib = {
      mkConfig = username: mkDarwinConfig { inherit username; };
      mkMinimalConfig = username: mkDarwinConfig { inherit username; enableHomebrew = false; };
    };
    
    # Modules for use in other flakes
    inherit darwinModules;
  };
}