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
    firefox-addons = {
      url = "github:nix-community/nur-combined?dir=repos/rycee/pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs =
    inputs@{
      nixpkgs,
      darwin,
      home-manager,
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
          allowUnfreePredicate =
            pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "onepassword-password-manager"
            ];
        };
      };

      lib = pkgs.lib;

      utils = import ./modules/lib {
        inherit lib pkgs system;
      };

      userValues = import ./values.nix;

      # Process values through the module system to apply defaults
      processedValues =
        (lib.evalModules {
          modules = [
            {
              options.values = lib.mkOption {
                type = utils.values.valuesType;
              };
              config.values = userValues;
            }
          ];
        }).config.values;

      mkDarwinConfiguration =
        {
          customValues ? processedValues,
        }:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              system
              pkgs
              utils
              ;
            values = customValues;
          };
          modules = [
            ./modules/darwin
            (import ./modules/darwin/home-manager.nix {
              username = customValues.user.username;
              values = customValues;
              inherit utils;
            })
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            {
              _module.args.utils = utils;
            }
          ];
        };
    in
    {
      darwinConfigurations = {
        ${processedValues.user.hostname} = mkDarwinConfiguration { };
        default = mkDarwinConfiguration { };
      };

      homeConfigurations = {
        ${processedValues.user.username} = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit utils;
            values = processedValues;
          };
          modules = [
            {
              home.username = processedValues.user.username;
              home.homeDirectory = "/Users/${processedValues.user.username}";
              home.stateVersion = "23.11";
            }
            (import ./modules/home {
              username = processedValues.user.username;
              values = processedValues;
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
        inherit mkDarwinConfiguration;
      };
    };
}
