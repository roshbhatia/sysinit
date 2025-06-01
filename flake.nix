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

  outputs =
    {
      self,
      darwin,
      home-manager,
      nix-homebrew,
      ...
    }@inputs:
    let
      system = "aarch64-darwin";
      defaultConfigPath = ./config.nix;

      defaultConfig = import defaultConfigPath;

      mkDarwinConfig =
        configPath:
        let
          config = import configPath;
          username = config.user.username;
          hostname = config.user.hostname;
          homeDirectory = "/Users/${username}";
        in
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit inputs username homeDirectory;
            userConfig = config;
          };
          modules = [
            ./modules/darwin
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
                users.${username} =
                  { ... }:
                  {
                    imports = [ ./modules/home ];
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

      defaultHostname = defaultConfig.user.hostname;
    in
    {
      darwinConfigurations.${defaultHostname} = mkDarwinConfig defaultConfigPath;

      lib = {
        mkConfigWithFile = mkDarwinConfig;
        inherit defaultConfigPath;
      };

      packages.${system}.default = self.darwinConfigurations.${defaultHostname}.system;
    };
}
