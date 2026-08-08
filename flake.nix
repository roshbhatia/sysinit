{
  description = "Personal system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "github:nix-community/nur-combined?dir=repos/rycee/pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    onepassword-shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    swayfx = {
      url = "github:WillPower3309/swayfx";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-mozilla = {
      url = "github:mozilla/nixpkgs-mozilla";
    };

    cupcake = {
      url = "github:eqtylab/cupcake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-claude-code = {
      url = "github:ryoppippi/nix-claude-code";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    meat = {
      url = "github:boldsoftware/meat";
      flake = false;
    };

    specutil = {
      url = "github:roshbhatia/specutil";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    seshy = {
      url = "github:roshbhatia/seshy";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ast-grep-skills = {
      url = "github:ast-grep/agent-skill";
      flake = false;
    };

  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;

      sysinitLib = import ./lib {
        inherit lib nixpkgs inputs;
      };

      hostConfigs = import ./hosts { };
      inherit (sysinitLib) builders;
      inherit (sysinitLib) outputBuilders;

      darwinConfigs = lib.filterAttrs (_: cfg: cfg.platform == "darwin") hostConfigs;
      nixosConfigs = lib.filterAttrs (_: cfg: cfg.platform == "linux") hostConfigs;

      buildConfig = builders.buildConfiguration {
        inherit (inputs)
          darwin
          home-manager
          stylix
          onepassword-shell-plugins
          nix-gaming
          ;
        inherit (builders) mkPkgs mkUtils mkOverlays;
      };

      cacheSystems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowUnsupportedSystem = true;
          };
          overlays = [ (lib.composeManyExtensions (import ./overlays/default.nix { inherit inputs; })) ];
        };
    in
    {
      darwinConfigurations = outputBuilders.mkConfigurations {
        configs = darwinConfigs;
        inherit buildConfig;
        extras = {
          bootstrap = inputs.darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            modules = [ (import ./flake/bootstrap.nix) ];
          };
        };
      };

      nixosConfigurations = outputBuilders.mkConfigurations {
        configs = nixosConfigs;
        inherit buildConfig;
      };

      packages =
        let
          cacheAttrs = [
            "openspec"
            "localias"
            "pplx"
            "mermaid-ascii"
            "pi-coding-agent"
            "crush"
            "contextive"
            "codex-acp"
            "claude-code"
            "go-enum"
            "gomvp"
            "kubernetes-zeitgeist"
            "open-policy-agent"
            "direnv"
            "hererocks"
            "sheets"
            "alerter"
            "kvazaar"
            "ioskeleyMono"
            "wumpusMono"
            "bookerly"
          ];
        in
        lib.genAttrs cacheSystems (
          system:
          let
            pkgs = pkgsFor system;
          in
          {
            cacheBundle = pkgs.symlinkJoin {
              name = "sysinit-cache-bundle-${system}";
              paths = builtins.filter (p: p != null) (map (name: pkgs.${name} or null) cacheAttrs);
            };
          }
        );

      checks = lib.genAttrs cacheSystems (
        system:
        import ./checks {
          inherit lib system;
          pkgs = pkgsFor system;
        }
      );
      lib = {
        inherit
          builders
          hostConfigs
          ;
      };

      devShells = lib.genAttrs cacheSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShellNoCC {
            name = "sysinit-dev";
            packages = [
              pkgs.nh
              pkgs.shfmt
              pkgs.shellcheck
              pkgs.lua5_4
              pkgs.jq
              pkgs.fd
            ];
          };
        }
      );

      templates = {
        discrete = {
          path = ./templates/discrete;
          description = "Template for discrete host repository consuming sysinit";
        };
      };

      overlays = {
        default =
          final: _prev:
          (lib.composeManyExtensions (import ./overlays/default.nix { inherit inputs; })) final _prev;
      };
      formatter = import ./flake/formatter.nix {
        inherit nixpkgs;
        systems = [
          "aarch64-darwin"
          "x86_64-darwin"
          "x86_64-linux"
          "aarch64-linux"
        ];
      };
    };
}
