{ lib, inputs }:

{
  buildNixosSystem =
    {
      home-manager,
      stylix,
      mangowc ? null,
      nix-gaming ? null,
    }:
    {
      hostConfig,
      hostname,
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
          _module.args = {
            inherit hostname;
          };
          # Pass pre-configured pkgs to avoid re-evaluation
          # Note: nixpkgs.config and nixpkgs.overlays are ignored when pkgs is set
          nixpkgs.pkgs = lib.mkDefault pkgs;
        }
        {
          config.sysinit.user.username = hostConfig.username;
        }
        (lib.optionalAttrs (values ? theme) {
          config.sysinit.theme = values.theme;
        })
        (lib.optionalAttrs (values ? git) {
          config.sysinit.git = values.git;
        })
        home-manager.nixosModules.home-manager
        stylix.nixosModules.stylix
        ../../modules/nixos
        (import ../../modules/nixos/home-manager.nix {
          inherit lib;
          inherit
            values
            inputs
            utils
            stylix
            ;
          inherit pkgs;
        })
        {
          documentation.enable = false;
        }
      ]
      ++ lib.optionals (hostConfig ? hardware) [ hostConfig.hardware ]
      ++ lib.optionals (hostConfig.lima or false) [
        inputs.nixos-lima.nixosModules.lima
      ]
      ++ lib.optionals (hostConfig.desktop or false && mangowc != null) [
        mangowc.nixosModules.mango
      ]
      ++ lib.optionals (hostConfig.desktop or false && nix-gaming != null) [
        nix-gaming.nixosModules.pipewireLowLatency
        nix-gaming.nixosModules.platformOptimizations
      ];
    };
}
