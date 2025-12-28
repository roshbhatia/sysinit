inputs:

let
  inherit (inputs.nixpkgs) lib;

  common = import ./common.nix;
  hostConfigs = (import ./hosts.nix) common;
  builders = import ./builders.nix {
    inherit lib;
    inherit (inputs) nixpkgs;
    inherit inputs;
  };

  darwinConfigs = lib.filterAttrs (_: cfg: cfg.platform == "darwin") hostConfigs;
  nixosConfigs = lib.filterAttrs (_: cfg: cfg.platform == "linux") hostConfigs;

  buildConfig = builders.buildConfiguration {
    inherit (inputs)
      darwin
      home-manager
      stylix
      nix-homebrew
      onepassword-shell-plugins
      darwin-custom-icons
      ;
    inherit (builders) mkPkgs;
    inherit (builders) mkUtils;
    inherit (builders) mkOverlays;
    inherit (builders) processValues;
  };
in
{
  darwinConfigurations =
    lib.mapAttrs (
      name: cfg:
      buildConfig {
        hostConfig = cfg;
        hostname = name;
      }
    ) darwinConfigs
    // {
      bootstrap = inputs.darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [ (import ./bootstrap.nix) ];
      };
    };

  nixosConfigurations = lib.mapAttrs (
    name: cfg:
    buildConfig {
      hostConfig = cfg;
      hostname = name;
    }
  ) nixosConfigs;

  lib = {
    inherit
      builders
      hostConfigs
      common
      ;
  };
}
