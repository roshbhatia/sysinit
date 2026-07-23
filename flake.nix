{
  description = "Personal system configuration";

  inputs = {
    # Main Nix package repository
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Nix modules for macOS
    darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Determinate Systems' Nix installer and tools
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    # User-specific package and dotfile management
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Browser extensions packaged for Nix
    firefox-addons = {
      url = "github:nix-community/nur-combined?dir=repos/rycee/pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # System-wide consistent styling (fonts, colors, etc)
    stylix = {
      url = "github:danth/stylix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Integration for 1Password CLI
    onepassword-shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Community package repository
    nur.url = "github:nix-community/NUR";

    # NixOS on macOS via Lima
    nixos-lima = {
      url = "github:nixos-lima/nixos-lima";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS gaming configuration
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # SwayFX compositor (sway fork with blur, shadows, dim)
    swayfx = {
      url = "github:WillPower3309/swayfx";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Mozilla Firefox overlay
    nixpkgs-mozilla = {
      url = "github:mozilla/nixpkgs-mozilla";
    };

    # Policy enforcement for AI coding agents
    cupcake = {
      url = "github:eqtylab/cupcake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Latest Claude Code CLI binaries
    nix-claude-code = {
      url = "github:ryoppippi/nix-claude-code";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # OpenSpec change projection CLI (graph, render, plan, sync)
    specutil = {
      url = "github:roshbhatia/specutil";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Terminal-first git diff pager. Do not make nixpkgs follow ours: hunk's
    # bun2nix/flake-parts build enumerates perSystem.x86_64-darwin, which
    # nixpkgs-unstable (26.11) dropped. Pin the same rev hunk's own lock uses,
    # which still supports x86_64-darwin, so the build matches upstream.
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.url = "github:NixOS/nixpkgs/549bd84d6279f9852cae6225e372cc67fb91a4c1";
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

      # Systems the cache bundle and checks are built for.
      cacheSystems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      # nixpkgs with this repo's overlays applied, per system. Shared by the
      # packages and checks outputs.
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
          # Custom / version-overridden packages that cache.nixos.org never
          # serves. A generous list is safe: the CI cachix post-build-hook only
          # uploads paths it actually builds, so already-cached entries cost
          # nothing. Keep heavy from-source overrides (cuda sunshine, the
          # desktop/media stack) OUT — those are intentionally uncached.
          cacheAttrs = [
            "openspec"
            "localias"
            "mermaid-ascii"
            "pi-coding-agent"
            "crush"
            "contextive"
            "codex-acp"
            "claude-code"
            "go-enum"
            "gomvp"
            "kubernetes-zeitgeist"
            "crossplane"
            "open-policy-agent"
            "direnv"
            "hererocks"
            "sheets"
            "alerter"
            "kvazaar"
            "ioskeleyMono"
            "wumpusMono"
            "bookerly"
            "hunk"
          ];
          # Only overlay-defined packages go in the bundle. Flake-input CLIs
          # (specutil, cupcake, …) have their own flakes/caches and their own
          # build fragility (e.g. specutil's stale go-modules vendorHash), so
          # caching them here just couples this job to upstream breakage.
          cacheBundleFor =
            system:
            let
              pkgs = pkgsFor system;
            in
            pkgs.symlinkJoin {
              name = "sysinit-cache-bundle-${system}";
              paths = builtins.filter (p: p != null) (map (n: pkgs.${n} or null) cacheAttrs);
            };
          agentsMd =
            let
              pkgs = pkgsFor "aarch64-darwin";
              skillsLib = import ./modules/home/programs/llm/skills.nix { inherit pkgs; };
              llmLib = import ./modules/home/programs/llm/lib/instructions.nix;
              rendered = llmLib.makeInstructions {
                inherit (skillsLib) localSkillDescriptions;
                openspecVersion = pkgs.openspec.version;
                skillsRoot = "~/.claude/skills";
              };
              agentsMdBody = ''
                # AGENTS.md

                Nix-managed dotfiles for macOS (Apple Silicon) and NixOS, single-user repo.

                This file mirrors the content generated by `modules/home/programs/llm/lib/instructions.nix` and is the canonical context shared by all agents (Claude Code, Codex, Gemini, Cursor, Aider). Per-agent context files at `~/.claude/CLAUDE.md`, `~/.codex/instructions.md`, etc., contain the same shared sections plus per-agent extensions.

                ${rendered}
              '';
            in
            pkgs.writeText "AGENTS.md" agentsMdBody;
        in
        lib.recursiveUpdate
          (lib.genAttrs cacheSystems (system: {
            cacheBundle = cacheBundleFor system;
          }))
          {
            aarch64-darwin.agentsMd = agentsMd;
          };

      checks = lib.genAttrs cacheSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          # Behavioral guard for the machine-wide default (Lever 2). Assert a
          # bare `openspec new change` writes `schema: rosh-spec-driven`. This
          # catches a newly added or moved default-schema site that the
          # overlay's `--replace-fail` patch is blind to. Hermetic: HOME and
          # XDG_DATA_HOME in the build tmp, the schema copied into the tmp XDG
          # dir, no network (telemetry is disabled and swallowed).
          openspec-default-schema =
            pkgs.runCommand "openspec-default-schema-check"
              {
                nativeBuildInputs = [ pkgs.openspec ];
              }
              ''
                export HOME="$TMPDIR/home"
                export XDG_DATA_HOME="$TMPDIR/xdg"
                export OPENSPEC_TELEMETRY=0
                export CI=true
                mkdir -p "$XDG_DATA_HOME/openspec/schemas"
                cp -r ${./openspec/schemas/rosh-spec-driven} "$XDG_DATA_HOME/openspec/schemas/rosh-spec-driven"
                chmod -R u+w "$XDG_DATA_HOME/openspec/schemas/rosh-spec-driven"
                mkdir -p "$TMPDIR/proj"
                cd "$TMPDIR/proj"
                openspec new change probe > /dev/null 2>&1 || true
                cfg="$(find . -name config.yaml -path '*openspec*' | head -n1)"
                if [ -z "$cfg" ]; then
                  echo "FAIL: bare 'openspec new change' wrote no openspec config.yaml" >&2
                  exit 1
                fi
                if grep -q "schema: rosh-spec-driven" "$cfg"; then
                  echo "OK: bare 'openspec new change' defaults to rosh-spec-driven" | tee "$out"
                else
                  echo "FAIL: default schema is not rosh-spec-driven. Wrote:" >&2
                  cat "$cfg" >&2
                  exit 1
                fi
              '';

          # Offline citation gate: run citelock's offline stages over every
          # openspec change that ships a citations.lock. Pure function of the
          # tree (no network, no MCP); the same gate the pre-commit hook runs.
          # A change with no citations.lock is a no-op.
          citelock =
            pkgs.runCommand "citelock-check"
              {
                nativeBuildInputs = [
                  pkgs.jq
                  pkgs.bash
                ];
              }
              ''
                changes=${./openspec/changes}
                found=0
                fail=0
                while IFS= read -r lock; do
                  [ -z "$lock" ] && continue
                  found=1
                  dir="$(dirname "$lock")"
                  if ! bash ${./hack/citelock.sh} verify "$dir"; then
                    fail=1
                  fi
                done < <(find "$changes" -name citations.lock 2> /dev/null)
                if [ "$fail" -ne 0 ]; then
                  echo "FAIL: citelock offline gate failed" >&2
                  exit 1
                fi
                echo "OK: citelock offline gate ($([ "$found" -eq 1 ] && echo 'all locks pass' || echo 'no locks present'))" | tee "$out"
              '';
        }
      );

      lib = {
        inherit
          builders
          hostConfigs
          ;
      };

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
      formatter =
        lib.genAttrs
          [
            "aarch64-darwin"
            "x86_64-darwin"
            "x86_64-linux"
            "aarch64-linux"
          ]
          (
            system:
            let
              pkgs = nixpkgs.legacyPackages.${system};
            in
            pkgs.writeShellApplication {
              name = "sysinit-nixfmt";
              runtimeInputs = [
                pkgs.fd
                pkgs.nixfmt
              ];
              text = ''
                if [ "$#" -gt 0 ]; then
                  exec nixfmt "$@"
                fi

                exec fd --extension nix --type file --exec-batch nixfmt
              '';
            }
          );
    };
}
