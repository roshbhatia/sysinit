inputs:

let
  inherit (inputs.nixpkgs) lib;

  common = import ./common.nix;
  hostConfigs = (import ./hosts.nix) common;
  builders = import ./builders.nix {
    inherit lib;
    inherit (inputs) nixpkgs;
    inherit inputs;
    inherit (inputs) determinate;
  };
  outputBuilders = import ./output-builders.nix { inherit lib; };

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
      determinate
      ;
    inherit (builders) mkPkgs;
    inherit (builders) mkUtils;
    inherit (builders) mkOverlays;
    inherit (builders) processValues;
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

  nixosConfigurations = outputBuilders.mkConfigurations {
    configs = nixosConfigs;
    inherit buildConfig;
  };

  lib = {
    inherit
      builders
      hostConfigs
      common
      ;
  };
}
