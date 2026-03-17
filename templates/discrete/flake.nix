{
  description = "Host-specific configuration consuming roshbhatia/sysinit";

  inputs = {
    # Point to sysinit (use local path for development, remote for production)
    # sysinit.url = "path:/path/to/sysinit";
    sysinit.url = "github:roshbhatia/sysinit";

    # Follow all inputs from sysinit for consistency
    darwin.follows = "sysinit/darwin";
    determinate.follows = "sysinit/determinate";
    direnv-instant.follows = "sysinit/direnv-instant";
    firefox-addons.follows = "sysinit/firefox-addons";
    home-manager.follows = "sysinit/home-manager";
    neovim-nightly-overlay.follows = "sysinit/neovim-nightly-overlay";
    nixpkgs.follows = "sysinit/nixpkgs";
    nixos-lima.follows = "sysinit/nixos-lima";
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

      # Re-instantiate sysinit lib with host inputs
      sysinitLib = import (sysinit + /lib) {
        inherit lib nixpkgs inputs;
      };

      hostConfigs = import ./hosts { };
      builders = sysinitLib.builders;
      outputBuilders = sysinitLib.outputBuilders;

      # Add host-specific overlays
      mkHostOverlays =
        system: (builders.mkOverlays system) ++ (import ./overlays { inherit inputs system; });

      buildConfig = builders.buildConfiguration {
        inherit
          darwin
          home-manager
          stylix
          onepassword-shell-plugins
          ;
        inherit (builders) mkPkgs mkUtils;
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
