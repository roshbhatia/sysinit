{
  description = "Roshan's macOS DevEnv System Config";

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
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      darwin,
      home-manager,
      nix-homebrew,
      ...
    }:
    let
      system = "aarch64-darwin";
      overlay = import ./overlay.nix;
      username = overlay.user.username;
      hostname = overlay.user.hostname;
      homeDirectory = "/Users/${username}";
    in
    {
      darwinConfigurations.${hostname} = darwin.lib.darwinSystem {
        inherit system;
        specialArgs = {
          inherit
            inputs
            system
            overlay
            username
            homeDirectory
            ;
        };
        modules = [
          ./modules/nix
          ./modules/darwin
          ./modules/home
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew
        ];
      };
    };
}
