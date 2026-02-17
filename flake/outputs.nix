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
  outputBuilders = import ./output-builders.nix { inherit lib; };

  darwinConfigs = lib.filterAttrs (_: cfg: cfg.platform == "darwin") hostConfigs;
  nixosConfigs = lib.filterAttrs (_: cfg: cfg.platform == "linux") hostConfigs;

  buildConfig = builders.buildConfiguration {
    inherit (inputs)
      darwin
      home-manager
      stylix
      nix-gaming
      nix-homebrew
      onepassword-shell-plugins
      ;
    inherit (builders) mkPkgs;
    inherit (builders) mkUtils;
    inherit (builders) mkOverlays;
    inherit (builders) processValues;
  };

  nixosConfigurationsOutput = outputBuilders.mkConfigurations {
    configs = nixosConfigs;
    inherit buildConfig;
  };
in
{
  darwinConfigurations = outputBuilders.mkConfigurations {
    configs = darwinConfigs;
    inherit buildConfig;
    extras = {
      bootstrap = inputs.darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [ (import ./bootstrap.nix) ];
      };
    };
  };

  nixosConfigurations = nixosConfigurationsOutput;

  # Lima VM images - for PRD-03, exposing configurations
  # Actual QCOW2 images can be built with nixos-generators or
  # by using official NixOS cloud images with declarative config
  packages.aarch64-darwin = {
    # Expose configurations for later image building
    # For now, validate that configs build successfully
  };

  lib = {
    inherit
      builders
      hostConfigs
      common
      ;
  };
}
