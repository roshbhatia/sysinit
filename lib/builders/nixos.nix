{ lib, inputs }:

{
  buildNixosSystem =
    {
      home-manager,
      stylix,
    }:
    {
      hostConfig,
      pkgs,
      utils,
      values,
    }:
    lib.nixosSystem {
      inherit (hostConfig) system;
      specialArgs = {
        inherit
          inputs
          values
          ;
        customUtils = utils;
        # Path to sysinit flake for cross-flake imports (e.g., hosts/base/*.nix)
        sysinit = ../..;
      };
      modules = [
        {
          # Pass pre-configured pkgs to avoid re-evaluation
          # Note: nixpkgs.config and nixpkgs.overlays are ignored when pkgs is set
          nixpkgs.pkgs = lib.mkDefault pkgs;
        }
        {
          config.sysinit.user.username = hostConfig.username;
          config.sysinit.theme = values.theme;
        }
        ../../modules/nixos
        home-manager.nixosModules.home-manager

        stylix.nixosModules.stylix
        (import ../../modules/nixos/home-manager.nix {
          inherit values inputs;
          inherit utils;
        })
        {
          documentation.enable = false;
        }
      ]
      ++ lib.optionals (hostConfig.isLima or false) [
        inputs.nixos-lima.nixosModules.lima
        ../../modules/nixos/configurations/lima.nix
      ];
    };
}
