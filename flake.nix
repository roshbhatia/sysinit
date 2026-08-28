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

    cupcake = {
      url = "github:eqtylab/cupcake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
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

    ast-grep-skills = {
      url = "github:ast-grep/agent-skill";
      flake = false;
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.url = "github:NixOS/nixpkgs/0954f7ee2f6bb3dc7d4e3d0d8bcb8fd4bde4cfc5";
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
        inherit (builders) mkPkgs mkOverlays;
      };

      cacheSystems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      pkgsFor =
        system:
        builders.mkPkgs {
          inherit system;
          overlays = builders.mkOverlays;
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

      homeModules = {
        default = ./modules/home;
        options = {
          imports = [
            ./modules/shared/options/theme.nix
            ./modules/home/programs/llm/options.nix
            ./modules/home/programs/git/options.nix
          ];
        };
      };

      homeConfigurations =
        let
          buildHome = builders.mkHome {
            inherit (inputs) home-manager;
            inherit (builders) mkPkgs mkOverlays;
          };
        in
        lib.listToAttrs (
          lib.concatMap
            (
              profile:
              map (system: {
                name = "${profile}-${system}";
                value = buildHome {
                  inherit system profile;
                  inherit (hostConfigs.lv426) username;
                  hostname = "standalone";
                  values = {
                    inherit (hostConfigs.lv426.values) git;
                  };
                };
              }) cacheSystems
            )
            [
              "dev"
              "minimal"
            ]
        );

      packages =
        let
          cacheAttrs = [
            "openspec"
            "calldiff"
            "localias"
            "mermaid-ascii"
            "pretty-mermaid"
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
            "sysinit-gotools"
            "seshy"
            "specutil"
            "changes"
            "traces"
            "ask"
            "sysinit-utils"
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
          inherit system;
          pkgs = pkgsFor system;
        }
      );

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
              pkgs.actionlint
              pkgs.clang
              pkgs.go
              pkgs.golangci-lint
              pkgs.shfmt
              pkgs.shellcheck
              pkgs.zsh
              pkgs.nushell
              pkgs.lua5_4
              pkgs.lua-language-server
              pkgs.jq
              pkgs.libxml2
              pkgs.fd
              pkgs.ast-grep
              pkgs.statix
              pkgs.deadnix
              pkgs.stylua
              pkgs.cue
              pkgs.taplo
              pkgs.typescript
              pkgs.eslint
              pkgs.yamllint
              pkgs.vale
            ];
            # prose-gate's tests read the rule set through this, the same way
            # the installed wrapper does. Without it they skip.
            SYSINIT_PROSE_STYLE = "${pkgs.vale-styles}/vale.ini";
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
          "x86_64-linux"
          "aarch64-linux"
        ];
      };
    };
}
