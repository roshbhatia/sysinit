{
  lib,
  nixpkgs,
  inputs,
}:

{
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
            "_1password-gui"
            "crush"
          ];
      };
    };

  mkUtils = { system, pkgs }: import ../modules/shared/lib { inherit lib pkgs system; };

  mkOverlays = system: import ../overlays { inherit inputs system; };

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
    {
      darwin,
      home-manager,
      stylix,
      nix-gaming ? null,
      nix-homebrew,
      onepassword-shell-plugins,
      mkPkgs,
      mkUtils,
      mkOverlays,
      processValues,
    }:
    {
      hostConfig,
      hostname,
    }:
    let
      overlays = mkOverlays hostConfig.system;
      pkgs = mkPkgs {
        inherit (hostConfig) system;
        inherit overlays;
      };
      utils = mkUtils {
        inherit (hostConfig) system;
        inherit pkgs;
      };
      userValuesWithUsername = hostConfig.values // {
        user.username = hostConfig.username;
      };
      values = processValues {
        inherit utils;
        userValues = userValuesWithUsername;
      };
    in
    if hostConfig.platform == "darwin" then
      darwin.lib.darwinSystem {
        inherit (hostConfig) system;
        specialArgs = {
          inherit
            inputs
            values
            utils
            pkgs
            ;
          inherit (hostConfig) system;
        };
        modules = [
          {
            _module.args = {
              inherit utils hostname;
            };
          }
          inputs.determinate.darwinModules.default
          {
            # Let Determinate Nix handle Nix configuration rather than nix-darwin
            nix.enable = false;
          }
          ../modules/darwin
          (import ../modules/darwin/home-manager.nix {
            inherit (values.user) username;
            inherit values utils pkgs;
          })
          home-manager.darwinModules.home-manager
          stylix.darwinModules.stylix
          nix-homebrew.darwinModules.nix-homebrew
          {
            _module.args.utils = utils;
            home-manager.sharedModules = [
              onepassword-shell-plugins.hmModules.default
              pkgs.nur.repos.charmbracelet.modules.homeManager.crush
            ];
            documentation.enable = false;
          }
        ];
      }
    else
      lib.nixosSystem {
        inherit (hostConfig) system;
        specialArgs = {
          inherit
            inputs
            values
            pkgs
            ;
          customUtils = utils;
        };
        modules = [
          {
            _module.args = {
              inherit hostname;
            };
          }
          ../modules/nixos
          home-manager.nixosModules.home-manager

          stylix.nixosModules.stylix
          inputs.mangowc.nixosModules.mango
          (import ../modules/nixos/home-manager.nix {
            inherit values inputs;
            inherit utils;
          })
          {
            documentation.enable = false;
            home-manager.sharedModules = [
              inputs.mangowc.hmModules.mango
            ];
          }
        ]
        ++ lib.optionals (values.nix.gaming.enable && nix-gaming != null) [
          nix-gaming.nixosModules.pipewireLowLatency
          nix-gaming.nixosModules.platformOptimizations
        ];
      };
}
