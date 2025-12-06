{
  description = "Multi-system Nix configuration supporting macOS and NixOS";

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
      inherit (nixpkgs) lib;

      # Multi-system support configuration
      systems = {
        laptop = "aarch64-darwin"; # macOS laptop
        nixos-desktop = "aarch64-linux"; # NixOS desktop
      };

      # Centralized user/host configuration - replaces values.nix
      # Centralized user/host configuration - replaces values.nix
      hostConfigs = {
        lv426 = {
          # macOS laptop
          system = systems.laptop;
          platform = "darwin";
          username = "rshnbhatia";
          values = {
            user = {
              username = "rshnbhatia";
              hostname = "lv426";
            };
            git = {
              name = "Roshan Bhatia";
              email = "rshnbhatia@gmail.com";
              username = "roshbhatia";
            };
            darwin = {
              homebrew = {
                additionalPackages = {
                  taps = [ "qmk/qmk" ];
                  brews = [ "qmk" ];
                  casks = [
                    "betterdiscord-installer"
                    "calibre"
                    "discord"
                    "orbstack"
                    "steam"
                  ];
                };
              };
            };
          };
        };
        arrakis = {
          # NixOS desktop
          system = systems.nixos-desktop;
          platform = "linux";
          username = "rshnbhatia";
          values = {
            user = {
              username = "rshnbhatia";
              hostname = "arrakis";
            };
            git = {
              name = "Roshan Bhatia";
              email = "rshnbhatia@gmail.com";
              username = "roshbhatia";
            };
          };
        };
      };

      # Helper to build pkgs for a specific system
      mkPkgs =
        {
          system,
          overlays ? [ ],
        }:
        import nixpkgs {
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

      # Build overlays
      mkOverlays = system: import ./overlays { inherit inputs system; };

      # Build utils for a system/pkgs combo
      mkUtils = { system, pkgs }: import ./modules/lib { inherit lib pkgs system; };

      # Process and validate values against schema
      processValues =
        { utils, userValues }:
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

      # Build a Darwin configuration
      mkDarwinConfiguration =
        {
          values,
          utils,
          pkgs,
          system,
        }:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              system
              pkgs
              utils
              values
              ;
          };
          modules = [
            ./modules/darwin
            (import ./modules/darwin/home-manager.nix {
              inherit (values.user) username;
              inherit values utils;
            })
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            {
              _module.args.utils = utils;
            }
          ];
        };

      # Build a NixOS configuration
      mkNixosConfiguration =
        {
          values,
          utils,
          system,
        }:
        lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              system
              utils
              values
              ;
          };
          modules = [
            ./modules/nixos
            {
              _module.args.utils = utils;
            }
          ];
        };

      # Generate all configurations dynamically
      mkConfigurations =
        f:
        lib.mapAttrs (
          hostname: hostConfig:
          let
            overlays = mkOverlays hostConfig.system;
            pkgs = mkPkgs {
              system = hostConfig.system;
              inherit overlays;
            };
            utils = mkUtils {
              system = hostConfig.system;
              inherit pkgs;
            };
            processedVals = processValues {
              inherit utils;
              userValues = hostConfig.values;
            };
          in
          f {
            inherit hostname pkgs utils;
            system = hostConfig.system;
            values = processedVals;
          }
        ) (lib.filterAttrs (_: cfg: cfg.platform == "darwin") hostConfigs);

      # Default config for local builds
      defaultHostname = "lv426";
      defaultConfig = hostConfigs.${defaultHostname};
      defaultSystem = defaultConfig.system;
      defaultOverlays = mkOverlays defaultSystem;
      defaultPkgs = mkPkgs {
        system = defaultSystem;
        overlays = defaultOverlays;
      };
      defaultUtils = mkUtils {
        system = defaultSystem;
        pkgs = defaultPkgs;
      };
      defaultProcessedValues = processValues {
        utils = defaultUtils;
        userValues = defaultConfig.values;
      };
    in
    {
      # Darwin configurations
      darwinConfigurations = mkConfigurations mkDarwinConfiguration;

      # NixOS configurations (framework in place, requires host hardware-configuration.nix)
      # Uncomment when arrakis hardware configuration is available
      # nixosConfigurations = mkNixosConfigurations;

      # Home manager standalone (for non-NixOS/Darwin systems)
      homeConfigurations = {
        ${defaultConfig.username} = home-manager.lib.homeManagerConfiguration {
          pkgs = defaultPkgs;
          extraSpecialArgs = {
            inherit defaultUtils;
            values = defaultProcessedValues;
          };
          modules = [
            {
              home.username = defaultConfig.username;
              home.homeDirectory = "/Users/${defaultConfig.username}";
              home.stateVersion = "23.11";
            }
            (import ./modules/home {
              inherit (defaultConfig.username) username;
              values = defaultProcessedValues;
              pkgs = defaultPkgs;
              utils = defaultUtils;
            })
          ];
        };
      };

      # Overlays
      overlays = {
        default =
          final: prev:
          builtins.foldl' (acc: overlay: acc // overlay final prev) { } (mkOverlays defaultSystem);

        packages = import (./overlays + "/packages.nix") {
          inherit inputs;
          system = defaultSystem;
        };
      };

      # Library exports for external consumption
      # External flakes can use: personal-sysinit.lib.mkDarwinConfiguration
      lib = {
        inherit
          mkDarwinConfiguration
          mkNixosConfiguration
          processValues
          mkPkgs
          mkUtils
          mkOverlays
          ;
        inherit hostConfigs systems;
      };
      # Checks - only for default system
      checks.${defaultSystem} = {
        nix-format = defaultPkgs.runCommand "check-nix-format" { } ''
          ${defaultPkgs.fd}/bin/fd -e nix -E result . ${./.} \
            -x ${defaultPkgs.nixfmt-rfc-style}/bin/nixfmt --width=100 --check {} \
            || (echo "Nix formatting check failed. Run 'task format:nix' to fix." && exit 1)
          touch $out
        '';

        lua-format = defaultPkgs.runCommand "check-lua-format" { } ''
          ${defaultPkgs.fd}/bin/fd -e lua . ${./.} \
            -x ${defaultPkgs.stylua}/bin/stylua --check {} \
            || (echo "Lua formatting check failed. Run 'task format:lua' to fix." && exit 1)
          touch $out
        '';

        shell-format = defaultPkgs.runCommand "check-shell-format" { } ''
          ${defaultPkgs.fd}/bin/fd -e sh -e bash -e zsh . ${./.} \
            -x ${defaultPkgs.shfmt}/bin/shfmt -i 2 -ci -bn -d {} \
            || (echo "Shell formatting check failed. Run 'task format:sh' to fix." && exit 1)
          touch $out
        '';
      };
    };
}
