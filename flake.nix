{
  description = "Personal system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    systems.url = "github:nix-systems/default";

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

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    orc = {
      url = "github:roshbhatia/orc/f9e485693b03d9d938e5ebe659c1b1bb2f452a88";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    orc-extras = {
      url = "github:roshbhatia/orc/f9e485693b03d9d938e5ebe659c1b1bb2f452a88?dir=extras";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
        orc.follows = "orc";
        changes.follows = "changes";
        traces.follows = "traces";
      };
    };

    ask = {
      url = "github:roshbhatia/ask/v0.7.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gate = {
      url = "github:roshbhatia/gate/v0.5.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ask-extras = {
      url = "github:roshbhatia/ask/v0.7.2?dir=extras";
      inputs = {
        ask.follows = "ask";
        nixpkgs.follows = "nixpkgs";
        runtime.follows = "hermes-agent";
      };
    };

    changes = {
      url = "github:roshbhatia/changes/v0.13.0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    seshy = {
      url = "github:roshbhatia/seshy/7689dd4552dcdac8ee017a32689e7e9165af08eb";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    specutil = {
      url = "github:roshbhatia/specutil/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ere = {
      url = "github:roshbhatia/ere/f22fa13dc0b3e652a03d3f8f3bb60189c64b6fd2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    traces = {
      url = "github:roshbhatia/traces/6fffbfc35cef710ea41d11d6f56258161c0d0996";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    agent-notes = {
      url = "github:roshbhatia/agent-notes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sysinit-wezterm = {
      url = "github:roshbhatia/sysinit.wezterm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sysinit-nvim = {
      url = "github:roshbhatia/sysinit.nvim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        agent-notes.follows = "agent-notes";
        changes.follows = "changes";
      };
    };
    prose-style = {
      url = "github:roshbhatia/prose-style/8d131f507a7a43a99f25cc4e16d97b75cf921a8e";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tether = {
      url = "github:roshbhatia/tether/111caa782ea49916341e7e978c920c70cfc738bb";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    citelock = {
      url = "github:roshbhatia/citelock/v0.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    slk = {
      url = "github:gammons/slk/v0.20.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nuvim = {
      url = "github:roshbhatia/nu_plugin_nvim/main";
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
      inputs.nixpkgs.url = "github:NixOS/nixpkgs/02f5696b0e6097e589076d886b317b83ff0437d7";
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

      cacheSystems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      # An attrset, not a function. As a function it re-instantiated nixpkgs
      # with the full overlay list once per call site per system.
      pkgsFor = lib.genAttrs cacheSystems (
        system:
        builders.mkPkgs {
          inherit system;
          overlays = builders.mkOverlays;
        }
      );
    in
    {
      inherit darwinConfigurations nixosConfigurations;

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
            "git-ai"
            "mermaid-ascii"
            "pretty-mermaid"
            "pi-coding-agent"
            "crush"
            "contextive"
            "codex"
            "claude-code"
            "gomvp"
            "kubernetes-zeitgeist"
            "hererocks"
            "sheets"
            "alerter"
            "sysinit-gotools"
            "seshy"
            "specutil"
            "changes"
            "changes-providers"
            "changes-provider-git-notes"
            "changes-neovim-plugin"
            "traces"
            "ere"
            "traces-providers"
            "ask"
            "ask-providers"
            "gate-cli"
            "gate-providers"
            "tether"
            "citelock"
            "sysinit-utils"
            "orc-cli"
            "orc-providers"
            "nuvim"
            "slk"
            "ioskeleyMono"
            "wumpusMono"
            "bookerly"
            "mise-nix"
            "zoetrope"
            "prime-agent"
            "atomic-coding-agent"
            "hermes-agent"
            "sysinit-fx"
            "meat"
            "amp-cli"
            "acp-amp"
            "git-ai-gate"
            "agent-notes"
            "seshy-picker"
            "tether-picker"
            "zoxide-picker"
            "zmx-picker"
          ];

          # Attrs the overlays define only on Linux. Naming them here rather
          # than tolerating an absent attr keeps a typo an error everywhere.
          linuxCacheAttrs = [
            "cua-computer-server"
            "sunshine"
            "sysinit-swayfx"
          ];
        in
        lib.genAttrs cacheSystems (
          system:
          let
            pkgs = pkgsFor.${system};
          in
          {
            # Resolve strictly. `pkgs.${name} or null` silently shrank the
            # bundle whenever an attr was renamed, so the miss showed up as a
            # source build on the laptop rather than as a CI failure.
            cacheBundle = pkgs.symlinkJoin {
              name = "sysinit-cache-bundle-${system}";
              paths = map (
                name:
                pkgs.${name}
                  or (throw "cacheAttrs names `${name}`, which the overlay set does not define on ${system}")
              ) (cacheAttrs ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux linuxCacheAttrs);
            };
            # Trimmed profile of this user's own CLIs for cloud agent boxes.
            # Every component is in cacheAttrs, so only the join builds; the
            # closure substitutes from roshbhatia.cachix.org with no source build.
            cloudTools = pkgs.symlinkJoin {
              name = "sysinit-cloud-tools-${system}";
              paths = map (name: pkgs.${name}) [
                "ask"
                "gate-cli"
                "gate-providers"
                "changes"
                "changes-providers"
                "traces"
                "traces-providers"
                "orc-cli"
                "orc-providers"
                "seshy"
                "specutil"
                "calldiff"
                "sysinit-utils"
              ];
            };
            # The committed .cursor, .devin, and hack/cloud-setup.sh files,
            # rendered from modules/shared/cloud.nix. hack/generate-cloud.sh
            # copies them in; checks.cloud-files fails on drift.
            cloud-files =
              (import ./flake/cloud-files.nix {
                inherit pkgs;
                inherit (pkgs) lib;
              }).all;
          }
        );

      checks = lib.genAttrs cacheSystems (
        system:
        import ./checks {
          inherit
            system
            darwinConfigurations
            nixosConfigurations
            ;
          homeManagerLib = inputs.home-manager.lib;
          pkgs = pkgsFor.${system};
        }
      );

      devShells = lib.genAttrs cacheSystems (
        system:
        let
          pkgs = pkgsFor.${system};
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
              pkgs.fish
              pkgs.carapace
              pkgs.lua5_4
              pkgs.lua-language-server
              pkgs.jq
              pkgs.libxml2
              pkgs.fd
              pkgs.ripgrep
              pkgs.ast-grep
              pkgs.statix
              pkgs.deadnix
              pkgs.stylua
              pkgs.cue
              pkgs.taplo
              pkgs.typescript
              pkgs.eslint
              pkgs.prettier
              pkgs.yamllint
              pkgs.vale
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
          "x86_64-linux"
          "aarch64-linux"
        ];
      };
    };
}
