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
    # Hard-code the username since environment variables are not reliable during Nix evaluation
    username = "rshnbhatia"; # Change this if needed for your system
    homeDirectory = "/Users/${username}";
    
    # Common darwin configuration function
    mkDarwinConfig = {}: darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs username homeDirectory; };
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
    bootstrapConfig = darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit username; };
      modules = [{
        # Minimal configuration
        system.stateVersion = 4;
        
        # Use dynamic user home directory
        users.users.${username}.home = homeDirectory;
        
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
    # Default configuration
    darwinConfigurations.default = mkDarwinConfig {};
    
    # We can create different configurations if needed in the future
    # darwinConfigurations.work = mkDarwinConfig {};
    
    # Bootstrap configuration for initial setup
    darwinConfigurations.bootstrap = bootstrapConfig;
  };
}