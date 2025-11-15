{
  description = "Roshan's macOS DevEnv System Config";

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

      inherit (pkgs) lib;

      utils = import ./modules/lib {
        inherit lib pkgs system;
      };

      userValues = import ./values.nix;

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
              inherit (customValues.user) username;
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
              inherit (processedValues.user) username;
              values = processedValues;
              inherit utils pkgs;
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

      checks.${system} = {
        # Check Nix formatting
        nix-format = pkgs.runCommand "check-nix-format" { } ''
          ${pkgs.fd}/bin/fd -e nix -E result . ${./.} \
            -x ${pkgs.nixfmt-rfc-style}/bin/nixfmt --width=100 --check {} \
            || (echo "Nix formatting check failed. Run 'task format:nix' to fix." && exit 1)
          touch $out
        '';

        # Check Lua formatting
        lua-format = pkgs.runCommand "check-lua-format" { } ''
          ${pkgs.fd}/bin/fd -e lua . ${./.} \
            -x ${pkgs.stylua}/bin/stylua --check {} \
            || (echo "Lua formatting check failed. Run 'task format:lua' to fix." && exit 1)
          touch $out
        '';

        # Check shell formatting
        shell-format = pkgs.runCommand "check-shell-format" { } ''
          ${pkgs.fd}/bin/fd -e sh -e bash -e zsh . ${./.} \
            -x ${pkgs.shfmt}/bin/shfmt -i 2 -ci -bn -d {} \
            || (echo "Shell formatting check failed. Run 'task format:sh' to fix." && exit 1)
          touch $out
        '';
      };
    };
}
