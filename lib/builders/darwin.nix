{ lib, inputs }:

{
  buildDarwinSystem =
    {
      darwin,
      home-manager,
      stylix,
      onepassword-shell-plugins,
    }:
    {
      hostConfig,
      hostname,
      pkgs,
      utils,
      values,
    }:
    darwin.lib.darwinSystem {
      inherit (hostConfig) system;
      specialArgs = {
        inherit
          inputs
          values
          utils
          pkgs
          ;
        inherit (hostConfig) system;
        # Path to sysinit flake for cross-flake imports (e.g., hosts/base/*.nix)
        sysinit = ../..;
      };
      modules = [
        {
          _module.args = {
            inherit utils hostname;
          };
          # Use pre-configured pkgs with overlays instead of letting nix-darwin instantiate its own
          # Note: nixpkgs.config and nixpkgs.overlays are ignored when pkgs is set
          nixpkgs.pkgs = lib.mkDefault pkgs;
        }
        inputs.determinate.darwinModules.default
        {
          # Let Determinate Nix handle Nix configuration rather than nix-darwin
          nix.enable = false;
        }
        {
          config.sysinit.user.username = hostConfig.username;
        }
        (lib.optionalAttrs (values ? theme) {
          config.sysinit.theme = values.theme;
        })
        (lib.optionalAttrs (values ? darwin) {
          config.sysinit.darwin = values.darwin;
        })
        ../../modules/darwin
        (import ../../modules/darwin/home-manager.nix {
          inherit (values.user) username;
          inherit
            lib
            values
            utils
            pkgs
            inputs
            ;
        })
        home-manager.darwinModules.home-manager
        stylix.darwinModules.stylix
        {
          _module.args.utils = utils;
          home-manager.sharedModules = [
            onepassword-shell-plugins.hmModules.default
            pkgs.nur.repos.charmbracelet.modules.homeManager.crush
          ];
          documentation.enable = false;
        }
      ];
    };
}
