{
  description = "Roshan's Multi-Platform System Config (macOS + NixOS)";

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
      # Helper function to create pkgs for a given system
      mkPkgs =
        system: overlays:
        import nixpkgs {
          inherit system overlays;
          config = {
            allowUnfree = true;
            allowUnsupportedSystem = true;
            allowUnfreePredicate =
              pkg:
              builtins.elem (nixpkgs.lib.getName pkg) [
                "onepassword-password-manager"
                "steam"
                "steam-original"
                "steam-run"
              ];
          };
        };

      # Helper function to create utils for a given system
      mkUtils =
        system: pkgs:
        import ./modules/lib {
          inherit (pkgs) lib;
          inherit pkgs system;
        };

      # Load host configurations
      hostsConfig = import ./hosts/values.nix;

      # Helper function to merge common values with host-specific values
      mkHostValues =
        hostname: hostConfig:
        hostsConfig.common
        // hostConfig
        // {
          user = hostsConfig.common.user // (hostConfig.user or { }) // {
            hostname = hostConfig.hostname;
          };
        };

      # Helper function to process values through validation
      processValues =
        system: values:
        let
          overlayFiles = ./overlays;
          overlays = import overlayFiles {
            inherit inputs system;
          };
          pkgs = mkPkgs system overlays;
          inherit (pkgs) lib;
          utils = mkUtils system pkgs;
        in
        (lib.evalModules {
          modules = [
            {
              options.values = lib.mkOption {
                type = utils.values.valuesType;
              };
              config.values = values;
            }
          ];
        }).config.values;

      # For backward compatibility - load values.nix if it exists
      # This is used when someone provides their own values.nix (like work MacBook)
      userValues = import ./values.nix;
      defaultSystem = "aarch64-darwin"; # Used for backward compatibility
      defaultOverlays = import ./overlays {
        inherit inputs;
        system = defaultSystem;
      };
      defaultPkgs = mkPkgs defaultSystem defaultOverlays;
      defaultUtils = mkUtils defaultSystem defaultPkgs;
      inherit (defaultPkgs) lib;
      processedValues = processValues defaultSystem userValues;

      # Create darwin configuration for a host
      mkDarwinConfiguration =
        {
          hostname,
          system,
          customValues,
          hostModule ? null,
        }:
        let
          overlays = import ./overlays {
            inherit inputs system;
          };
          pkgs = mkPkgs system overlays;
          utils = mkUtils system pkgs;
        in
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit inputs system pkgs utils;
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
            { _module.args.utils = utils; }
          ] ++ lib.optional (hostModule != null) hostModule;
        };

      # Create NixOS configuration for a host
      mkNixosConfiguration =
        {
          hostname,
          system,
          customValues,
          hostModule ? ./hosts/${hostname},
        }:
        let
          overlays = import ./overlays {
            inherit inputs system;
          };
          pkgs = mkPkgs system overlays;
          utils = mkUtils system pkgs;
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs system pkgs utils;
            values = customValues;
          };
          modules = [
            ./modules/nixos
            (import ./modules/nixos/home-manager.nix {
              inherit (customValues.user) username;
              values = customValues;
              inherit utils;
            })
            home-manager.nixosModules.home-manager
            { _module.args.utils = utils; }
            hostModule
          ];
        };
      # Helper to create all configurations for a host
      mkHostConfiguration =
        hostname: hostConfig:
        let
          system = hostConfig.system;
          values = mkHostValues hostname hostConfig;
          processedHostValues = processValues system values;
          hostModulePath = ./hosts/${hostname};
        in
        if lib.hasSuffix "darwin" system then
          {
            name = hostname;
            value = mkDarwinConfiguration {
              inherit hostname system;
              customValues = processedHostValues;
              hostModule = hostModulePath;
            };
          }
        else
          {
            name = hostname;
            value = mkNixosConfiguration {
              inherit hostname system;
              customValues = processedHostValues;
              hostModule = hostModulePath;
            };
          };

      # Generate configurations for all hosts
      allHostConfigurations = lib.mapAttrs' mkHostConfiguration hostsConfig.hosts;

      # Separate into darwin and nixos configurations
      darwinHosts = lib.filterAttrs (
        name: cfg: lib.hasSuffix "darwin" hostsConfig.hosts.${name}.system
      ) allHostConfigurations;

      nixosHosts = lib.filterAttrs (
        name: cfg: lib.hasSuffix "linux" hostsConfig.hosts.${name}.system
      ) allHostConfigurations;
    in
    {
      # Darwin configurations (macOS)
      darwinConfigurations =
        darwinHosts
        // {
          # Backward compatibility: support for external values.nix (work MacBook)
          ${processedValues.user.hostname} = mkDarwinConfiguration {
            hostname = processedValues.user.hostname;
            system = defaultSystem;
            customValues = processedValues;
          };
          default = mkDarwinConfiguration {
            hostname = processedValues.user.hostname;
            system = defaultSystem;
            customValues = processedValues;
          };
        };

      # NixOS configurations (Linux)
      nixosConfigurations = nixosHosts;

      # Standalone home-manager configurations
      homeConfigurations = {
        ${processedValues.user.username} = home-manager.lib.homeManagerConfiguration {
          pkgs = defaultPkgs;
          extraSpecialArgs = {
            utils = defaultUtils;
            values = processedValues;
          };
          modules = [
            {
              home.username = processedValues.user.username;
              home.homeDirectory = defaultUtils.platform.homeDirectory processedValues.user.username;
              home.stateVersion = "23.11";
            }
            (import ./modules/home {
              inherit (processedValues.user) username;
              values = processedValues;
              utils = defaultUtils;
              pkgs = defaultPkgs;
            })
          ];
        };
      };

      overlays = {
        default =
          final: prev:
          builtins.foldl' (acc: overlay: acc // overlay final prev) { } (
            import ./overlays {
              inherit inputs;
              system = final.system;
            }
          );

        packages = import (./overlays + "/packages.nix") {
          inherit inputs;
          system = defaultSystem;
        };
      };

      lib = {
        inherit
          mkDarwinConfiguration
          mkNixosConfiguration
          mkHostValues
          processValues
          ;
      };

      checks.${defaultSystem} = {
        # Check Nix formatting
        nix-format = defaultPkgs.runCommand "check-nix-format" { } ''
          ${defaultPkgs.fd}/bin/fd -e nix -E result . ${./.} \
            -x ${defaultPkgs.nixfmt-rfc-style}/bin/nixfmt --width=100 --check {} \
            || (echo "Nix formatting check failed. Run 'task format:nix' to fix." && exit 1)
          touch $out
        '';

        # Check Lua formatting
        lua-format = defaultPkgs.runCommand "check-lua-format" { } ''
          ${defaultPkgs.fd}/bin/fd -e lua . ${./.} \
            -x ${defaultPkgs.stylua}/bin/stylua --check {} \
            || (echo "Lua formatting check failed. Run 'task format:lua' to fix." && exit 1)
          touch $out
        '';

        # Check shell formatting
        shell-format = defaultPkgs.runCommand "check-shell-format" { } ''
          ${defaultPkgs.fd}/bin/fd -e sh -e bash -e zsh . ${./.} \
            -x ${defaultPkgs.shfmt}/bin/shfmt -i 2 -ci -bn -d {} \
            || (echo "Shell formatting check failed. Run 'task format:sh' to fix." && exit 1)
          touch $out
        '';
      };
    };
}
