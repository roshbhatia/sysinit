{ lib, inputs }:

{
  buildNixosSystem =
    {
      home-manager,
      stylix,
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
        sysinit = ../..;
      };
      modules = [
        {
          _module.args = {
            inherit hostname;
          };
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
      ++ lib.optionals ((hostConfig.desktop or false) && nix-gaming != null) [
        nix-gaming.nixosModules.pipewireLowLatency
        nix-gaming.nixosModules.platformOptimizations
      ];
    };
}
