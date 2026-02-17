inputs:

let
  inherit (inputs.nixpkgs) lib;
  self = inputs.self;

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
      nix-homebrew
      onepassword-shell-plugins
      ;
    inherit (builders) mkPkgs;
    inherit (builders) mkUtils;
    inherit (builders) mkOverlays;
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

  templates = {
    vm-dev = {
      path = self + /templates/vm-dev;
      description = "Full development project with automatic Lima VM integration";
      welcomeText = ''
        # Development project created!

        ## Setup
        1. Review shell.nix and customize VM settings
        2. Run: direnv allow
        3. The VM will auto-create and you'll be dropped into it

        ## Manual controls
        - Stop VM: task lima:stop
        - Destroy VM: task lima:destroy
        - Status: task lima:status

        ## Disable auto-entry
        Set SYSINIT_NO_AUTO_VM=1 in .envrc to disable automatic VM entry.
      '';
    };

    vm-minimal = {
      path = self + /templates/vm-minimal;
      description = "Minimal project with basic Lima VM";
      welcomeText = ''
        # Minimal project created!

        Run 'direnv allow' to enable automatic VM management.
      '';
    };
  };
}
