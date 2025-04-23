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

    mkDarwinConfig = { configPath ? ./config.nix }: 
    let
      config = configValidator configPath;
      username = config.user.username;
      hostname = config.user.hostname;
      homeDirectory = "/Users/${username}";
    in
    darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { 
        inherit inputs username homeDirectory;
        userConfig = config;
        enableHomebrew = true;
      };
      modules = [
        ./modules/darwin/default.nix
        # Ensure Home Manager backs up existing files instead of erroring
        { home-manager.backupFileExtension = "backup"; }
        { 
          networking.hostName = hostname;
        }
      ];
    };
  in {
    darwinConfigurations = {
      default = mkDarwinConfig {};
      "${(import ./config.nix).user.hostname}" = mkDarwinConfig {};
    };

    lib = {
      mkConfigWithFile = configPath: mkDarwinConfig { inherit configPath; };
      defaultConfigPath = ./config.nix;
    };

    packages.${system}.default = self.darwinConfigurations.default.system;
  };
}