{
  description = "Roshan's macOS DevEnv System Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs =
    inputs@{
      darwin,
      home-manager,
      nix-homebrew,
      ...
    }:
    let
      system = "aarch64-darwin";
      defaultOverlay = import ./overlay.nix;

      mkDarwinConfiguration =
        customOverlay:
        let
          overlay = customOverlay;
          username = overlay.user.username;
          hostname = overlay.user.hostname;
        in
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              system
              overlay
              username
              hostname
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
    in
    {
      darwinConfigurations = {
        ${defaultOverlay.user.hostname} = mkDarwinConfiguration defaultOverlay;
      };

      lib = {
        inherit mkDarwinConfiguration;
        defaultOverlay = defaultOverlay;
      };
    };
}

