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
          ];
      };
    };

  mkUtils = { system, pkgs }: import ../modules/lib { inherit lib pkgs system; };

  mkOverlays = system: import ../overlays.nix { inherit inputs system; };

  buildConfiguration =
    {
      darwin,
      home-manager,
      stylix,
      nix-homebrew,
      onepassword-shell-plugins,
      mkPkgs,
      mkUtils,
      mkOverlays,
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
      # Merge username into values for backward compatibility with bridge code
      values = hostConfig.values // {
        user.username = hostConfig.username;
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
          # Path to sysinit flake for cross-flake imports (e.g., hosts/base/*.nix)
          sysinit = ../.;
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
          {
            config.sysinit.user.username = hostConfig.username;
            config.sysinit.git = values.git;
            config.sysinit.theme = {
              appearance = values.theme.appearance or "dark";
              colorscheme = values.theme.colorscheme;
              variant = values.theme.variant;
              font.monospace = values.theme.font.monospace or "TX-02";
              transparency =
                values.theme.transparency or {
                  opacity = 0.8;
                  blur = 70;
                };
            };
            config.sysinit.darwin = {
              tailscale.enable = values.darwin.tailscale.enable or true;
              homebrew.additionalPackages = {
                taps = values.darwin.homebrew.additionalPackages.taps or [ ];
                brews = values.darwin.homebrew.additionalPackages.brews or [ ];
                casks = values.darwin.homebrew.additionalPackages.casks or [ ];
              };
            };
          }
          ../modules/darwin
          (import ../modules/darwin/home-manager.nix {
            inherit (values.user) username;
            inherit
              values
              utils
              pkgs
              inputs
              ;
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
            ;
          customUtils = utils;
          # Path to sysinit flake for cross-flake imports (e.g., hosts/base/*.nix)
          sysinit = ../.;
        };
        modules = [
          {
            # Pass pre-configured pkgs to avoid re-evaluation
            # Note: nixpkgs.config and nixpkgs.overlays are ignored when pkgs is set
            nixpkgs.pkgs = lib.mkDefault pkgs;
          }
          {
            config.sysinit.user.username = hostConfig.username;
            config.sysinit.git = values.git;
            config.sysinit.theme = {
              appearance = values.theme.appearance or "dark";
              colorscheme = values.theme.colorscheme;
              variant = values.theme.variant;
              font.monospace = values.theme.font.monospace or "TX-02";
              transparency =
                values.theme.transparency or {
                  opacity = 0.8;
                  blur = 70;
                };
            };
          }
          ../modules/nixos
          home-manager.nixosModules.home-manager

          stylix.nixosModules.stylix
          (import ../modules/nixos/home-manager.nix {
            inherit values inputs;
            inherit utils;
          })
          {
            documentation.enable = false;
          }
        ]
        ++ lib.optionals (hostConfig.isLima or false) [
          inputs.nixos-lima.nixosModules.lima
          ../modules/nixos/configurations/lima.nix
        ];
      };
}
