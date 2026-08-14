{
  description = "Host-specific configuration consuming roshbhatia/sysinit";

  inputs = {
    sysinit.url = "github:roshbhatia/sysinit";

    darwin.follows = "sysinit/darwin";
    determinate.follows = "sysinit/determinate";
    firefox-addons.follows = "sysinit/firefox-addons";
    home-manager.follows = "sysinit/home-manager";
    nixpkgs.follows = "sysinit/nixpkgs";
    nur.follows = "sysinit/nur";
    onepassword-shell-plugins.follows = "sysinit/onepassword-shell-plugins";
    stylix.follows = "sysinit/stylix";
  };

  outputs =
    inputs@{
      sysinit,
      darwin,
      home-manager,
      stylix,
      onepassword-shell-plugins,
      ...
    }:
    let
      inherit (sysinit.inputs) nixpkgs;
      inherit (nixpkgs) lib;

      sysinitLib = import (sysinit + /lib) {
        inherit lib nixpkgs inputs;
      };

      hostConfigs = import ./hosts { };
      inherit (sysinitLib) builders;
      inherit (sysinitLib) outputBuilders;

      mkHostOverlays =
        system: (builders.mkOverlays system) ++ (import ./overlays { inherit inputs system; });

      buildConfig = builders.buildConfiguration {
        inherit
          darwin
          home-manager
          stylix
          onepassword-shell-plugins
          ;
        inherit (builders) mkPkgs;
        mkOverlays = mkHostOverlays;
      };

      darwinConfigs = lib.filterAttrs (_: cfg: cfg.platform == "darwin") hostConfigs;
      nixosConfigs = lib.filterAttrs (_: cfg: cfg.platform == "linux") hostConfigs;

    in
    {
      darwinConfigurations = outputBuilders.mkConfigurations {
        configs = darwinConfigs;
        inherit buildConfig;
        extraModules = [ ./modules/darwin ];
      };

      nixosConfigurations = outputBuilders.mkConfigurations {
        configs = nixosConfigs;
        inherit buildConfig;
        extraModules = [ ./modules/nixos ];
      };

      lib = {
        inherit
          builders
          hostConfigs
          ;
      };
    };
}
