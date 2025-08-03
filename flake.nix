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
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs =
    inputs@{
      darwin,
      home-manager,
      nix-homebrew,
      ...
    }:
    let
      system = "aarch64-darwin";
      
      # Import and validate values
      rawValues = import ./values.nix;
      lib = inputs.nixpkgs.lib;
      valuesValidator = import ./modules/lib/values-validator.nix { 
        inherit lib; 
        values = rawValues; 
      };
      defaultValues = valuesValidator.validatedValues;

      overlayFiles = ./overlays;
      overlays = import overlayFiles {
        inherit inputs system;
      };

      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = overlays;
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
        };
      };

      mkDarwinConfiguration =
        customValues:
        let
          # Validate custom values as well
          customValidator = import ./modules/lib/values-validator.nix { 
            inherit lib; 
            values = customValues; 
          };
          values = customValidator.validatedValues;
          username = values.user.username;
          hostname = values.user.hostname;
        in
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              system
              values
              username
              hostname
              pkgs
              ;
          };
          modules = [
            ./modules/darwin
            (import ./modules/darwin/home-manager.nix {
              username = defaultValues.user.username;
              values = defaultValues;
              utils = import ./modules/lib {
                lib = pkgs.lib;
                inherit pkgs system;
              };
            })
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            {
              _module.args.utils = import ./modules/lib {
                lib = pkgs.lib;
                inherit pkgs system;
              };
            }
          ];
        };
    in
    {
      darwinConfigurations = {
        ${defaultValues.user.hostname} = mkDarwinConfiguration defaultValues;
      };

      homeConfigurations = {
        ${defaultValues.user.username} = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            utils = import ./modules/lib {
              inherit (pkgs) lib;
              inherit pkgs system;
            };
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
              utils = import ./modules/lib {
                inherit (pkgs) lib;
                inherit pkgs system;
              };
            })
          ];
        };
      };

      overlays = {
        default =
          final: prev:
          let
            customOverlays = import overlayFiles { inherit inputs system; };
          in
          builtins.foldl' (acc: overlay: acc // overlay final prev) { } customOverlays;

        packages = import (overlayFiles + "/packages.nix") { inherit inputs system; };
      };

      lib = {
        inherit mkDarwinConfiguration;
        defaultValues = defaultValues;
        valuesTypes = import ./modules/lib/values-types.nix { inherit lib; };
        valuesValidator = valuesValidator;
      };
    };
}
