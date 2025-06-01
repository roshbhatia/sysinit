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

  outputs = { self, darwin, home-manager, nix-homebrew, ... }@inputs:
    let
      system = "aarch64-darwin";
      mkSystem = configPath:
        let
          config = import configPath;
          username = config.user.username;
          sharedConfig = {
            inherit inputs system username;
            homeDirectory = "/Users/${username}";
            userConfig = config;
          };
        in
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = sharedConfig;
          modules = [
            ./modules/darwin
            nix-homebrew.darwinModules.nix-homebrew
            home-manager.darwinModules.home-manager
            {
              networking.hostName = config.user.hostname;
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = sharedConfig;
                users.${username} = { ... }: {
                  imports = [ ./modules/home ];
                  home = {
                    inherit username;
                    homeDirectory = sharedConfig.homeDirectory;
                    stateVersion = "23.11";
                  };
                };
                backupFileExtension = "backup";
              };
            }
          ];
        };
    in
    {
      darwinConfigurations.${(import ./config.nix).user.hostname} = mkSystem ./config.nix;
      lib = {
        mkConfigWithFile = mkSystem;
        defaultConfigPath = ./config.nix;
      };
    };
}
