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
    fileInstaller = import ./modules/lib/file-installer.nix;
    mkDarwinConfig = import ./modules/lib/make-darwin-system.nix { 
      inherit inputs configValidator fileInstaller; 
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

    darwinModules = {
      default = { username, homeDirectory ? "/Users/${username}", config ? {}, ... }: {
        imports = [ ./modules/darwin/default.nix ];
        _module.args = {
          inherit username homeDirectory inputs;
          userConfig = config;
          enableHomebrew = true;
        };
      };
    };

    packages.${system}.default = self.darwinConfigurations.default.system;
  };
}