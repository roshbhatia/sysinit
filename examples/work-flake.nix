{
  description = "Work System Configuration Example";

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
    
    # Import a separate config file or define it inline
    config = import ./work-config.nix;
    
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