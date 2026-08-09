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
      profile,
      theme,
      values,
    }:
    darwin.lib.darwinSystem {
      inherit (hostConfig) system;
      specialArgs = {
        inherit
          inputs
          profile
          theme
          values
          pkgs
          ;
        inherit (hostConfig) system;
      };
      modules = [
        {
          _module.args = {
            inherit hostname profile;
          };
          nixpkgs.pkgs = lib.mkDefault pkgs;
        }
        inputs.determinate.darwinModules.default
        {
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
            pkgs
            inputs
            profile
            theme
            ;
        })
        home-manager.darwinModules.home-manager
        stylix.darwinModules.stylix
        {
          home-manager.sharedModules = [
            onepassword-shell-plugins.hmModules.default
          ];
          documentation.enable = false;
        }
      ];
    };
}
