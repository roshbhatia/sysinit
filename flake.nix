{
  description = "Roshan's OSX DevEnv System Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }@inputs:
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
        ./modules/darwin/darwin.nix
        home-manager.darwinModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs username homeDirectory; };
          # Set backup file extension to backup existing files automatically
          home-manager.backupFileExtension = "backup";
          home-manager.users.${username} = { pkgs, ... }: {
            imports = [ ./modules/home ];
            # These settings override any null values from imported modules
            home.username = pkgs.lib.mkForce username;
            home.homeDirectory = pkgs.lib.mkForce homeDirectory;
            
            # Remove warning about overlays with useGlobalPkgs
            nixpkgs = {};
          };
        }
      ];
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
        
        # Use dynamic user home directory
        users.users.${bootstrapUsername}.home = bootstrapHomeDirectory;
        
        # Disable nix management for Determinate Nix compatibility
        nix.enable = false;
        
        # Nix configuration
        nix.settings.experimental-features = [ "nix-command" "flakes" ];
        
        # Basic packages
        environment.systemPackages = with nixpkgs.legacyPackages.${system}; [
          git
          curl
        ];
        
        # MacOS configuration
        system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
        system.defaults.finder.AppleShowAllExtensions = true;
        
        # Touch ID for sudo
        security.pam.services.sudo_local.touchIdAuth = true;
      }];
    };
  in {
    # Default configuration (personal, with Homebrew)
    darwinConfigurations.default = mkDarwinConfig {};
    
    # Default configuration without Homebrew
    darwinConfigurations.minimal = mkDarwinConfig { enableHomebrew = false; };
    
    # Example of custom username configuration
    darwinConfigurations.work = mkDarwinConfig { username = "your-work-username"; };
    
    # Functions to create configurations with custom parameters
    mkConfig = username: mkDarwinConfig { inherit username; };
    mkMinimalConfig = username: mkDarwinConfig { inherit username; enableHomebrew = false; };
    
    # Bootstrap configuration for initial setup
    darwinConfigurations.bootstrap = bootstrapConfig;
  };
}