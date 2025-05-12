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
    defaultConfigPath = ./config.nix;
    
    mkDarwinConfig = configPath:
      let
        config = configPath;
        username = config.user.username;
        hostname = config.user.hostname;
        homeDirectory = "/Users/${username}";
      in darwin.lib.darwinSystem {
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
      
    defaultConfig = configValidator defaultConfigPath;
    defaultHostname = defaultConfig.user.hostname;
  in {
    # Create the default config using the default config path
    darwinConfigurations.${defaultHostname} = mkDarwinConfig defaultConfigPath;

    lib = {
      mkConfigWithFile = mkDarwinConfig;
      inherit defaultConfigPath;
    };

    packages.${system}.default = self.darwinConfigurations.${defaultHostname}.system;
  };
}
