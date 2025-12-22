{
  description = "Personal system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "github:nix-community/nur-combined?dir=repos/rycee/pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    onepassword-shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming = {
      url = "github:fufexan/nix-gaming";
    };

    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      darwin,
      home-manager,
      nix-homebrew,
      stylix,
      mac-app-util,
      onepassword-shell-plugins,
      ...
    }:
    let
      inherit (nixpkgs) lib;

      sharedValues = import ./flake/shared-values.nix;
      hostConfigs = (import ./flake/hosts.nix) sharedValues;
      builders = import ./flake/builders.nix {
        inherit lib nixpkgs inputs;
      };

      darwinConfigs = lib.filterAttrs (_: cfg: cfg.platform == "darwin") hostConfigs;
      nixosConfigs = lib.filterAttrs (_: cfg: cfg.platform == "linux") hostConfigs;

      buildConfig = builders.buildConfiguration {
        inherit
          darwin
          home-manager
          stylix
          nix-homebrew
          mac-app-util
          onepassword-shell-plugins
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
          bootstrap = darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            modules = [ (import ./flake/bootstrap.nix) ];
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
          sharedValues
          ;
      };
    };
}
