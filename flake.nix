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
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
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
    system = "aarch64-darwin";
    configValidator = import ./modules/lib/config-validator.nix { inherit nixpkgs self; };
    config = configValidator ./config.nix;
    username = config.user.username;
    hostname = config.user.hostname;
    homeDirectory = "/Users/${username}";
  in {
    darwinConfigurations.${hostname} = darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { 
        inherit inputs username homeDirectory;
        userConfig = config;
        enableHomebrew = if config.homebrew ? enable then config.homebrew.enable else true;
      };
      modules = [
        ./modules/darwin/system.nix
        ./modules/darwin/homebrew.nix
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
        {
          networking.hostName = hostname;
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { 
              inherit inputs username homeDirectory; 
              userConfig = config;
            };
            users.${username} = { pkgs, ... }: {
              imports = [ ./modules/darwin/home ];
              home = {
                inherit username homeDirectory;
                stateVersion = "23.11";
              };
            };
            backupFileExtension = "backup";
          };
        }
      ];
    };

    # Keep compatibility with previous configuration
    darwinConfigurations.default = self.darwinConfigurations.${hostname};

    # Preserve the helper functions
    lib = {
      mkConfigWithFile = configPath: 
        let
          customConfig = configValidator configPath;
          customUsername = customConfig.user.username;
          customHostname = customConfig.user.hostname;
          customHomeDirectory = "/Users/${customUsername}";
        in
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { 
            inherit inputs;
            username = customUsername;
            homeDirectory = customHomeDirectory;
            userConfig = customConfig;
            enableHomebrew = if customConfig.homebrew ? enable then customConfig.homebrew.enable else true;
          };
          modules = [
            ./modules/darwin/system.nix
            ./modules/darwin/homebrew.nix
            nix-homebrew.darwinModules.nix-homebrew
            home-manager.darwinModules.home-manager
            {
              networking.hostName = customHostname;
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { 
                  inherit inputs; 
                  username = customUsername;
                  homeDirectory = customHomeDirectory;
                  userConfig = customConfig;
                };
                users.${customUsername} = { pkgs, ... }: {
                  imports = [ ./modules/darwin/home ];
                  home = {
                    username = customUsername;
                    homeDirectory = customHomeDirectory;
                    stateVersion = "23.11";
                  };
                };
                backupFileExtension = "backup";
              };
            }
          ];
        };
      defaultConfigPath = ./config.nix;
    };

    packages.${system}.default = self.darwinConfigurations.${hostname}.system;
  };
}