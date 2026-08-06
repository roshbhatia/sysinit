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
        sysinit = ../..;
      };
      modules = [
        {
          _module.args = {
            inherit utils hostname;
          };
          # reuse the evaluated package set so overlays stay identical
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
            utils
            pkgs
            inputs
            ;
        })
        home-manager.darwinModules.home-manager
        stylix.darwinModules.stylix
        {
          _module.args.utils = utils;
          # No charmbracelet NUR crush module. home-manager gained its own
          # `programs.crush` (bumped in 5aac343d0) and two modules declaring the
          # same option abort evaluation. Nothing here ever set a `programs.crush`
          # option from either one: the config is written straight to
          # `.config/crush/crush.json` by `sysinit.llm.managedFiles` in
          # `modules/home/programs/llm/harnesses/crush.nix`, and the package comes
          # from `modules/home/packages.nix`. So the import was already inert.
          home-manager.sharedModules = [
            onepassword-shell-plugins.hmModules.default
          ];
          documentation.enable = false;
        }
      ];
    };
}
