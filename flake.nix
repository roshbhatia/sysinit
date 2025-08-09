{
  description = "Roshan's macOS DevEnv System Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix.url = "github:nix-community/stylix";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs =
    inputs@{
      nixpkgs,
      darwin,
      home-manager,
      stylix,
      nix-homebrew,
      ...
    }:
    let
      system = "aarch64-darwin";

      overlayFiles = ./overlays;
      overlays = import overlayFiles {
        inherit inputs system;
      };

      pkgs = import nixpkgs {
        inherit system overlays;
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
        };
      };

      lib = pkgs.lib;

      utils = import ./modules/lib {
        inherit lib pkgs system;
      };

      defaultValues = import ./values.nix;

      mkDarwinConfiguration =
        {
          values ? defaultValues,
        }:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              system
              pkgs
              values
              utils
              ;
          };
          modules = [
            ./modules/darwin
            (import ./modules/darwin/home-manager.nix {
              username = values.user.username;
              inherit values utils;
            })
            home-manager.darwinModules.home-manager
            stylix.darwinModules.stylix
            {
              disabledModules = [ "${stylix}/modules/anki/hm.nix" ];
            }
            nix-homebrew.darwinModules.nix-homebrew
            {
              _module.args.utils = utils;
            }
          ];
        };
    in
    {
      darwinConfigurations = {
        ${defaultValues.user.hostname} = mkDarwinConfiguration { };
      };

      homeConfigurations = {
        ${defaultValues.user.username} = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit utils;
            values = defaultValues;
          };
          modules = [
            {
              home.username = defaultValues.user.username;
              home.homeDirectory = "/Users/${defaultValues.user.username}";
              home.stateVersion = "23.11";
            }
            (import ./modules/home {
              username = defaultValues.user.username;
              values = defaultValues;
              inherit utils;
            })
          ];
        };
      };

      overlays = {
        default =
          final: prev:
          builtins.foldl' (acc: overlay: acc // overlay final prev) { } (
            import overlayFiles { inherit inputs system; }
          );

        packages = import (overlayFiles + "/packages.nix") {
          inherit inputs system;
        };
      };

      lib = {
        inherit mkDarwinConfiguration defaultValues;
      };
    };
}

