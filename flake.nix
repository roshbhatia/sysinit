{
  description = "Personal macOS and NixOS system configurations";

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
    niri.url = "github:sodiboo/niri-flake";
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.cl-nix-lite.url = "github:r4v3n6101/cl-nix-lite/url-fix";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      darwin,
      home-manager,
      nix-homebrew,
      niri,
      mac-app-util,
      ...
    }:
    let
      inherit (nixpkgs) lib;

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

      mkUtils = { system, pkgs }: import ./modules/shared/lib { inherit lib pkgs system; };

      mkOverlays = system: import ./overlays { inherit inputs system; };

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

      buildConfiguration =
        { hostConfig }:
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
          values = processValues {
            inherit utils;
            userValues = hostConfig.values;
          };
        in
        if hostConfig.platform == "darwin" then
          darwin.lib.darwinSystem {
            system = hostConfig.system;
            specialArgs = {
              inherit
                inputs
                values
                utils
                pkgs
                ;
              system = hostConfig.system;
            };
            modules = [
              ./modules/darwin
              (import ./modules/darwin/home-manager.nix {
                inherit (values.user) username;
                inherit values utils pkgs;
              })
              home-manager.darwinModules.home-manager
              nix-homebrew.darwinModules.nix-homebrew
              mac-app-util.darwinModules.default
              {
                _module.args.utils = utils;
                home-manager.sharedModules = [
                  mac-app-util.homeManagerModules.default
                ];
              }
            ];
          }
        else
          lib.nixosSystem {
            system = hostConfig.system;
            specialArgs = {
              inherit
                inputs
                values
                utils
                pkgs
                ;
              customUtils = utils;
            };
            modules = [
              ./modules/nixos
              home-manager.nixosModules.home-manager
              niri.nixosModules.niri
              (import ./modules/nixos/home-manager.nix {
                inherit values utils pkgs;
              })
            ];
          };

      hostConfigs = {
        lv426 = {
          system = "aarch64-darwin";
          platform = "darwin";
          username = "rshnbhatia";
          values = {
            config.root = ./.;
            user.username = "rshnbhatia";
            git = {
              name = "Roshan Bhatia";
              email = "rshnbhatia@gmail.com";
              username = "roshbhatia";
            };
            darwin.homebrew.additionalPackages = {
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
        arrakis = {
          system = "x86_64-linux";
          platform = "linux";
          username = "rshnbhatia";
          values = {
            config.root = ./.;
            user.username = "rshnbhatia";
            git = {
              name = "Roshan Bhatia";
              email = "rshnbhatia@gmail.com";
              username = "roshbhatia";
            };
          };
        };
      };

      darwinConfigs = lib.filterAttrs (_: cfg: cfg.platform == "darwin") hostConfigs;
      nixosConfigs = lib.filterAttrs (_: cfg: cfg.platform == "linux") hostConfigs;

    in
    {
      darwinConfigurations =
        lib.mapAttrs (_: cfg: buildConfiguration { hostConfig = cfg; }) darwinConfigs
        // {
          bootstrap = darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            modules = [
              {
                system.defaults.finder.AppleShowAllExtensions = true;
                system.stateVersion = 4;
                programs.zsh.enable = true;
              }
            ];
          };
        };

      nixosConfigurations = lib.mapAttrs (_: cfg: buildConfiguration { hostConfig = cfg; }) nixosConfigs;

      lib = {
        inherit
          mkPkgs
          mkUtils
          mkOverlays
          processValues
          buildConfiguration
          hostConfigs
          ;
      };
    };
}
