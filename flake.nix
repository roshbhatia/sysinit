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

    # Abridges a unified diff into a reading diff. No upstream flake, so it is
    # built from source by overlays/meat.nix. No LICENSE upstream either
    # (boldsoftware/meat#2), so it is marked unfree there and must stay out of any
    # public binary cache.
    meat = {
      url = "github:boldsoftware/meat";
      flake = false;
    };

    # OpenSpec change projection CLI (graph, render, plan, sync)
    specutil = {
      url = "github:roshbhatia/specutil";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Multi-repo, git-worktree session manager. Provides `sy`, which the shell
    # integration and the `sy delete` readiness gate both wrap.
    seshy = {
      url = "github:roshbhatia/seshy";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Upstream ast-grep agent skills (the `ast-grep` rule-authoring guide and
    # the `ast-grep-outline` structural-map guide). Vendored as a pinned source
    # rather than copied into skills/, so `nix flake update` is the only way
    # the content moves and drift is visible in flake.lock.
    ast-grep-skills = {
      url = "github:ast-grep/agent-skill";
      flake = false;
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
            "hunk"
          ];
          # Only overlay-defined packages go in the bundle. Flake-input CLIs
          # (specutil, cupcake, …) have their own flakes/caches and their own
          # build fragility (e.g. specutil's stale go-modules vendorHash), so
          # caching them here just couples this job to upstream breakage.
          #
          # `meat` is overlay-defined and still MUST NOT be listed: upstream ships
          # no LICENSE, so pushing a built binary to a public cache would be
          # redistribution without a grant. Building it locally is fine.
          cacheBundleFor =
            system:
            let
              pkgs = pkgsFor system;
            in
            pkgs.symlinkJoin {
              name = "sysinit-cache-bundle-${system}";
              paths = builtins.filter (p: p != null) (map (n: pkgs.${n} or null) cacheAttrs);
            };
        in
        lib.genAttrs cacheSystems (system: {
          cacheBundle = cacheBundleFor system;
        });

      checks = lib.genAttrs cacheSystems (
        system:
        let
          pkgs = pkgsFor system;
          # The rendered notification icons, so a check can assert the generic
          # fallback is not a copy of a harness glyph.
          notifyIcons = (import ./modules/home/programs/llm/config/notify.nix { inherit pkgs lib; }).icons;
          # The same jq program the activation reconciler runs. Imported rather
          # than restated, so the check cannot pass against a copy that has
          # drifted from what actually reconciles the live files.
          managedFile = import ./modules/home/programs/llm/lib/managed-file.nix { inherit lib; };
        in
        {
          # The skill sources moved from Nix strings to SKILL.md files. This
          # asserts the move changed no rendered byte, which is the only claim
          # that matters: 2,113 lines of prose only git holds a copy of.
          #
          # It is a real check rather than a one-time diff because the frontmatter
          # reader and the include expander are now load-bearing: a regression in
          # either silently reshapes every skill the fleet loads.
          skill-render-shape =
            let
              s = import ./modules/home/programs/llm/skills.nix { inherit pkgs; };
              reg = import ./modules/home/programs/llm/skills { inherit pkgs lib; };
            in
            pkgs.runCommand "skill-render-shape-check" { } (
              let
                claudeOne = builtins.head (lib.attrValues s.allSkills);
              in
              ''
                fail=0
                # Every skill renders for both harnesses.
                n_claude=${toString (lib.length (lib.attrNames s.allSkills))}
                n_amp=${toString (lib.length (lib.attrNames s.ampSkills))}
                n_reg=${toString (lib.length (lib.attrNames reg))}
                [ "$n_claude" = "$n_reg" ] || { echo "FAIL: claude renders $n_claude of $n_reg skills" >&2; fail=1; }
                [ "$n_amp" = "$n_reg" ]    || { echo "FAIL: amp renders $n_amp of $n_reg skills" >&2; fail=1; }

                # The include expander must leave no placeholder behind. A
                # surviving {{...}} means a skill ships a literal template to the
                # model, which reads as an instruction it cannot satisfy.
                ${lib.concatStringsSep "\n" (
                  lib.mapAttrsToList (n: f: ''
                    if grep -qE '\{\{[a-zA-Z_]+\}\}' ${f}; then
                      echo "FAIL: rendered claude/${n} still contains a {{placeholder}}" >&2
                      fail=1
                    fi
                  '') s.allSkills
                )}

                # Frontmatter must survive as frontmatter, not become body text.
                head -1 ${claudeOne} | grep -qx -- --- || { echo "FAIL: render lost its frontmatter fence" >&2; fail=1; }

                [ "$fail" -eq 0 ] || exit 1
                echo "OK: $n_reg skills render for both harnesses with no stray placeholder" > "$out"
              ''
            );

          # End-to-end coverage of the reconcile() shell function, not just the
          # jq program. Five adversarial review rounds each found a defect in
          # this region and four of them regressed the previous round's fix,
          # because nothing exercised it. Every scenario below is a defect that
          # actually shipped and was caught by hand.
          managed-file-reconcile =
            let
              mf = managedFile;
              recFor =
                files:
                mf.mkReconciler {
                  inherit pkgs;
                  files = lib.mapAttrs (_: mf.mkTestFile) files;
                };
              schemaStrict = pkgs.writeText "strict.json" (
                builtins.toJSON {
                  type = "object";
                  additionalProperties = false;
                  properties.ok = { };
                }
              );
              main = recFor {
                j = {
                  path = "d/j.json";
                  format = "json";
                  content = {
                    a = 1;
                    keep.deep = true;
                  };
                };
                y = {
                  path = "d/y.yaml";
                  format = "yaml";
                  content = {
                    mode = "smart";
                    n = 0.2;
                  };
                  enforce = [ "mode" ];
                };
                t = {
                  path = "d/t.toml";
                  format = "toml";
                  content = {
                    policy = "never";
                    p.spec.effort = "high";
                  };
                };
                skip = {
                  path = "d/skip.json";
                  createIfMissing = false;
                  content.x = 1;
                };
                strict = {
                  path = "d/strict.json";
                  content.ok = 1;
                  schema = "${schemaStrict}";
                };
              };
              # Same paths, one key undeclared and one changed, to drive
              # deletion-via-base and the conflict path.
              # The adopt path has no base, so the three-way merge has nothing to
              # compare against and cannot remove an undeclared key. `retire` is the
              # only thing that does, and it now applies on EVERY activation, not
              # only on adoption: a key that was never declared is absent from the
              # base too, and the merge preserves base-absent by design. Two
              # reconcilers, identical but for that list.
              adoptWith = recFor {
                a = {
                  path = "d/adopt.json";
                  format = "json";
                  content.ok = 1;
                  retire = [ "stale" ];
                };
              };
              adoptWithout = recFor {
                a = {
                  path = "d/adopt.json";
                  format = "json";
                  content.ok = 1;
                };
              };

              drop = recFor {
                j = {
                  path = "d/j.json";
                  format = "json";
                  content.a = 1;
                };
              };
              allOff = recFor {
                j = {
                  path = "d/j.json";
                  enable = false;
                };
              };
            in
            pkgs.runCommand "managed-file-reconcile-check"
              {
                nativeBuildInputs = [
                  pkgs.jq
                  pkgs.yq-go
                ];
              }
              ''
                export HOME="$TMPDIR/home"
                mkdir -p "$HOME/d"
                fail=0
                say() { echo "  $1"; }
                want() { # label actual expected
                  if [ "$2" = "$3" ]; then say "ok   $1"; else echo "FAIL $1: got [$2] want [$3]" >&2; fail=1; fi
                }

                # The all-disabled kill switch must build. It is what you reach
                # for when the first switch misbehaves, and shellcheck fails the
                # derivation on unreachable helpers unless they are suppressed.
                want "all-disabled kill switch builds" "$([ -x ${allOff}/bin/sysinit-llm-reconcile ] && echo y)" "y"

                # forget_base is the only code a disabled file runs, and it is
                # the live path today: claude-json is disabled whenever
                # disabledBuiltinServers is empty. It derives the sidecar name a
                # second time, so a drift from reconcile() would be silent.
                mkdir -p "$HOME/d"; echo '{"a":1}' > "$HOME/d/j.json"; echo '{"a":1}' > "$HOME/d/.j.json.nix-base"
                ${allOff}/bin/sysinit-llm-reconcile > /dev/null
                want "disabled file drops its base" "$([ -e "$HOME/d/.j.json.nix-base" ] && echo kept || echo dropped)" "dropped"

                # --- `retire` removes a key the merge would otherwise keep --------
                # Two paths, both covered. On adoption there is no base to compare
                # against. On every later activation the key is base-ABSENT, which the
                # merge preserves on purpose, so a harness rewrite would make it
                # immortal. Dropping this list from a harness config is a silent
                # regression, and that regression was made and reverted once.
                mkdir -p "$HOME/d"
                echo '{"ok":1,"stale":true}' > "$HOME/d/adopt.json"
                ${adoptWithout}/bin/sysinit-llm-reconcile > /dev/null
                want "adopt without retire keeps the undeclared key" \
                  "$(jq -r 'has("stale")' "$HOME/d/adopt.json")" "true"

                rm -f "$HOME/d/adopt.json" "$HOME/d/.adopt.json.nix-base"
                echo '{"ok":1,"stale":true}' > "$HOME/d/adopt.json"
                ${adoptWith}/bin/sysinit-llm-reconcile > /dev/null
                want "adopt with retire removes it" \
                  "$(jq -r 'has("stale")' "$HOME/d/adopt.json")" "false"
                want "adopt with retire keeps the declared key" \
                  "$(jq -r '.ok' "$HOME/d/adopt.json")" "1"
                # And the immortal case: the host has adopted, so a base exists, and
                # the harness writes the key again. It is base-absent, so the merge
                # keeps it; only `retire` removes it. This is the `powerline` defect.
                echo '{"ok":1}' > "$HOME/d/adopt.json"
                ${adoptWith}/bin/sysinit-llm-reconcile > /dev/null
                echo '{"ok":1,"stale":"compact"}' > "$HOME/d/adopt.json"
                ${adoptWith}/bin/sysinit-llm-reconcile > /dev/null
                want "retire removes a base-absent key the harness rewrote" \
                  "$(jq -r 'has("stale")' "$HOME/d/adopt.json")" "false"
                rm -f "$HOME/d/adopt.json" "$HOME/d/.adopt.json.nix-base"
                want "disabled file itself untouched" "$(jq -r .a "$HOME/d/j.json")" "1"
                rm -f "$HOME/d/j.json"

                R=${main}/bin/sysinit-llm-reconcile

                # 1. seed, all three formats
                "$R" > /dev/null
                want "json seeded"  "$(jq -r .a "$HOME/d/j.json")" "1"
                want "yaml seeded"  "$(yq -r .mode "$HOME/d/y.yaml")" "smart"
                want "toml block style" "$(yq -p toml -r '.p.spec.effort' "$HOME/d/t.toml")" "high"
                want "yaml float kept" "$(yq -r .n "$HOME/d/y.yaml")" "0.2"
                # Block style, not a single-line flow blob. This asserts a property
                # of the OUTPUT, and is deliberately not mutation-sensitive to the
                # `... style=""` guard in managed-file.nix: verified with yq v4.53.3
                # that the guard only changes a YAML-to-YAML transform, where yq
                # preserves the source node style. The write path reads JSON, which
                # carries no style, so the guard is a no-op there. The assertion still
                # earns its place: it fails if the write path ever takes YAML input.
                want "yaml is block style" "$(wc -l < "$HOME/d/y.yaml" | tr -d ' ')" "2"
                want "createIfMissing=false skipped" "$([ -e "$HOME/d/skip.json" ] && echo present || echo absent)" "absent"

                # createIfMissing=false must also refuse to seed over a leftover
                # store symlink. Seeding writes Nix-only content, which is what
                # the flag refuses; an earlier revision printed "leaves it alone"
                # and then seeded anyway.
                # A RESOLVING store path, not a dangling one: a dangling link
                # fails the `-e` test and would return for the wrong reason,
                # which is how an earlier version of this check passed against
                # the defect it was written to catch.
                ln -s ${schemaStrict} "$HOME/d/skip.json"
                "$R" > /dev/null 2>&1 || true
                want "skip target not seeded over a store link" "$([ -L "$HOME/d/skip.json" ] && echo link || echo seeded)" "link"

                # ...nor delete a zero-byte target it has just refused to create.
                # A crashed harness is exactly what produces one.
                rm -f "$HOME/d/skip.json"; : > "$HOME/d/skip.json"
                "$R" > /dev/null 2>&1 || true
                want "skip target zero-byte not deleted" "$([ -e "$HOME/d/skip.json" ] && echo present || echo gone)" "present"
                rm -f "$HOME/d/skip.json"

                # 2. idempotence
                cp "$HOME/d/j.json" "$TMPDIR/j1"; "$R" > /dev/null; "$R" > /dev/null
                want "idempotent over 3 runs" "$(cmp -s "$TMPDIR/j1" "$HOME/d/j.json" && echo same)" "same"

                # 3. a key the harness adds survives
                jq '.harnessAdded = "keep"' "$HOME/d/j.json" > "$TMPDIR/x" && mv "$TMPDIR/x" "$HOME/d/j.json"
                "$R" > /dev/null
                want "harness-added key kept" "$(jq -r .harnessAdded "$HOME/d/j.json")" "keep"

                # 4. a value the owner changes survives, unless enforced
                yq -i '.mode = "owner"' "$HOME/d/y.yaml"
                "$R" > /dev/null
                want "enforced key reasserted" "$(yq -r .mode "$HOME/d/y.yaml")" "smart"

                # 5. deletion via the base, with no tombstone list
                ${drop}/bin/sysinit-llm-reconcile > /dev/null
                want "undeclared key deleted" "$(jq -r 'has("keep")' "$HOME/d/j.json")" "false"
                want "harness key still kept" "$(jq -r .harnessAdded "$HOME/d/j.json")" "keep"

                # --- a declared key must win on EVERY activation -------------------
                # The three-way merge returns the DISK value whenever the Nix value
                # has not changed since the base, so a mergeable key wins exactly
                # once and never again. Measured before this assertion existed: base
                # stylix, disk dark, new stylix merged to dark, which is the
                # "generated theme is never selected" defect reappearing on the first
                # harness-side write. `enforce` is the only mechanism that fixes it.
                jq '.a = 999' "$HOME/d/j.json" > "$HOME/d/j.tmp" && mv "$HOME/d/j.tmp" "$HOME/d/j.json"
                ${main}/bin/sysinit-llm-reconcile > /dev/null
                want "a mergeable key loses to the harness on a later switch" \
                  "$(jq -r .a "$HOME/d/j.json")" "999"
                jq '.a = 1' "$HOME/d/j.json" > "$HOME/d/j.tmp" && mv "$HOME/d/j.tmp" "$HOME/d/j.json"


                # 6. conflict refuses and leaves the target byte-identical
                jq '.a = 99' "$HOME/d/j.json" > "$TMPDIR/x" && mv "$TMPDIR/x" "$HOME/d/j.json"
                jq '.a = 55' "$HOME/d/.j.json.nix-base" > "$TMPDIR/x" && mv "$TMPDIR/x" "$HOME/d/.j.json.nix-base"
                cp "$HOME/d/j.json" "$TMPDIR/pre"
                msg="$("$R" 2>&1 || true)"
                want "conflict leaves target untouched" "$(cmp -s "$TMPDIR/pre" "$HOME/d/j.json" && echo same)" "same"
                want "conflict names the key" "$(echo "$msg" | grep -c 'conflict at .a')" "1"
                want "conflict shows three values" "$(echo "$msg" | grep -cE '^  (base|live|nix)')" "3"

                # 7. an unreadable base refuses rather than guessing
                rm -rf "$HOME/d2"; mkdir -p "$HOME/d2"
                echo 'not json {{{' > "$HOME/d/.j.json.nix-base"
                echo '{"a":1,"mine":true}' > "$HOME/d/j.json"
                msg="$("$R" 2>&1 || true)"
                want "unreadable base reported" "$(echo "$msg" | grep -c 'unreadable base')" "1"
                want "unreadable base leaves file" "$(jq -r .mine "$HOME/d/j.json")" "true"

                # 8. a schema failure leaves the target untouched
                rm -f "$HOME/d/.strict.json.nix-base"
                echo '{"ok":1,"bogus":2}' > "$HOME/d/strict.json"
                msg="$("$R" 2>&1 || true)"
                want "schema failure reported" "$(echo "$msg" | grep -c 'failed schema validation')" "1"
                want "schema failure keeps file" "$(jq -r .bogus "$HOME/d/strict.json")" "2"
                want "schema failure writes no base" "$([ -e "$HOME/d/.strict.json.nix-base" ] && echo wrote || echo none)" "none"

                # 9. a symlink the module does not own is refused, not replaced
                rm -rf "$HOME/d3"; mkdir -p "$HOME/d3"
                echo '{"precious":true}' > "$HOME/d3/real.json"
                rm -f "$HOME/d/j.json"; ln -s "$HOME/d3/real.json" "$HOME/d/j.json"
                msg="$("$R" 2>&1 || true)"
                want "user symlink refused" "$(echo "$msg" | grep -c 'does not own')" "1"
                want "user symlink intact" "$([ -L "$HOME/d/j.json" ] && echo y)" "y"
                want "pointed-at file intact" "$(jq -r .precious "$HOME/d3/real.json")" "true"

                # 10. a leftover store symlink IS replaced
                rm -f "$HOME/d/j.json" "$HOME/d/.j.json.nix-base"
                # Resolving, for the reason given on the skip fixture above: a
                # dangling link passes this assertion even with store-link
                # detection entirely disabled.
                ln -s ${schemaStrict} "$HOME/d/j.json"
                "$R" > /dev/null 2>&1 || true
                want "store symlink replaced" "$([ -f "$HOME/d/j.json" ] && [ ! -L "$HOME/d/j.json" ] && echo y)" "y"

                if [ "$fail" -ne 0 ]; then echo "reconcile() regressed" >&2; exit 1; fi
                echo "OK: reconcile() behaviour holds" > "$out"
              '';

          # Ownership semantics of the three-way merge. Each case is a claim the
          # harness configs depend on: undeclaring a key deletes it without a
          # tombstone list, a key the harness wrote survives, a value the owner
          # changed from inside the harness is not clobbered, and a genuine
          # three-way divergence refuses rather than silently picking a side.
          managed-file-merge3 =
            pkgs.runCommand "managed-file-merge3-check" { nativeBuildInputs = [ pkgs.jq ]; }
              ''
                prog=${pkgs.writeText "merge3.jq" managedFile.mergeProgram}
                fail=0

                ok() { # name base disk new expected
                  got="$(jq -cs -f "$prog" <(echo "$2") <(echo "$3") <(echo "$4") 2>&1)"
                  if [ "$got" = "$5" ]; then
                    echo "ok   $1"
                  else
                    echo "FAIL $1: expected $5, got $got" >&2
                    fail=1
                  fi
                }

                refuses() { # name base disk new expected-substring
                  if got="$(jq -cs -f "$prog" <(echo "$2") <(echo "$3") <(echo "$4") 2>&1)"; then
                    echo "FAIL $1: expected a refusal, got $got" >&2
                    fail=1
                  elif ! printf '%s' "$got" | grep -q "$5"; then
                    echo "FAIL $1: refusal did not mention '$5': $got" >&2
                    fail=1
                  else
                    echo "ok   $1"
                  fi
                }

                ok "undeclared key is deleted" \
                  '{"a":1,"b":2}' '{"a":1,"b":2}' '{"a":1}' '{"a":1}'
                ok "undeclared key the owner edited is kept" \
                  '{"a":1,"b":2}' '{"a":1,"b":9}' '{"a":1}' '{"a":1,"b":9}'
                ok "key the harness added is kept" \
                  '{"a":1}' '{"a":1,"z":9}' '{"a":1}' '{"a":1,"z":9}'
                ok "nix-only change wins" \
                  '{"a":1}' '{"a":1}' '{"a":2}' '{"a":2}'
                ok "owner-only change wins" \
                  '{"a":1}' '{"a":5}' '{"a":1}' '{"a":5}'
                ok "both sides converged on one value" \
                  '{"a":1}' '{"a":7}' '{"a":7}' '{"a":7}'
                ok "owner deletion sticks when nix is unchanged" \
                  '{"a":1,"b":2}' '{"a":1}' '{"a":1,"b":2}' '{"a":1}'
                ok "nested: inner undeclare deletes, sibling add survives" \
                  '{"s":{"a":1,"b":2}}' '{"s":{"a":1,"b":2,"z":9}}' '{"s":{"a":1}}' '{"s":{"a":1,"z":9}}'

                # `opencode-render.nix` keeps an `authoritative` list that replaces
                # whole blocks, on the stated grounds that a top-level `del` "only
                # reaches depth one" and so cannot remove a stale nested entry such
                # as a `provider.ollama` that Nix stopped declaring. These cases test
                # that claim against the three-way program directly: if deletion
                # recurses to any depth, that list is redundant.
                ok "nested 2 deep: undeclared subtree is deleted" \
                  '{"p":{"o":{"k":1},"x":1}}' '{"p":{"o":{"k":1},"x":1}}' '{"p":{"x":1}}' '{"p":{"x":1}}'
                ok "nested 3 deep: undeclared leaf is deleted" \
                  '{"p":{"o":{"k":1,"j":2}}}' '{"p":{"o":{"k":1,"j":2}}}' '{"p":{"o":{"k":1}}}' '{"p":{"o":{"k":1}}}'
                ok "nested 3 deep: harness addition beside it survives" \
                  '{"p":{"o":{"k":1,"j":2}}}' '{"p":{"o":{"k":1,"j":2,"z":9}}}' '{"p":{"o":{"k":1}}}' '{"p":{"o":{"k":1,"z":9}}}'
                # Expected value is key-sorted: the program builds objects from a
                # `unique` key set, and `jq -S` matches that so the first run does not
                # rewrite a file for ordering alone.
                ok "nested: owner edit to an undeclared leaf is kept" \
                  '{"p":{"o":{"k":1,"j":2}}}' '{"p":{"o":{"k":1,"j":99}}}' '{"p":{"o":{"k":1}}}' '{"p":{"o":{"j":99,"k":1}}}'

                refuses "three-way divergence on a scalar" \
                  '{"a":1}' '{"a":5}' '{"a":9}' "conflict at .a"
                refuses "owner deleted a key nix then changed" \
                  '{"a":1,"b":2}' '{"a":1}' '{"a":1,"b":3}' "conflict at .b"
                refuses "both sides added the same key differently" \
                  '{"a":1}' '{"a":1,"z":1}' '{"a":1,"z":2}' "conflict at .z"

                if [ "$fail" -ne 0 ]; then
                  echo "managed-file merge semantics regressed" >&2
                  exit 1
                fi
                echo "OK: three-way merge semantics hold" > "$out"
              '';

          # Behavioral guard for the machine-wide default (Lever 2). Assert a
          # bare `openspec new change` writes `schema: rosh-spec-driven`. This
          # catches a newly added or moved default-schema site that the
          # overlay's `--replace-fail` patch is blind to. Hermetic: HOME and
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

          # The schema's templates must be a conforming starting point. A change
          # scaffolded verbatim from them has to pass the schema's own rubric,
          # otherwise an author who fills in the template still trips the gate
          # and has to reverse-engineer the rule from a failure. This caught the
          schema-templates-conform =
            pkgs.runCommand "schema-templates-conform-check"
              {
                nativeBuildInputs = [
                  pkgs.specutil
                  pkgs.jq
                ];
              }
              ''
                tmpl=${./openspec/schemas/rosh-spec-driven/templates}
                root="$TMPDIR/proj"
                change="$root/openspec/changes/probe"
                mkdir -p "$change"
                echo "schema: rosh-spec-driven" > "$root/openspec/config.yaml"
                cp "$tmpl/proposal.md" "$change/proposal.md"
                cp "$tmpl/design.md"   "$change/design.md"
                cp "$tmpl/tasks.md"    "$change/tasks.md"

                # review-decision-current: wants a recorded human verdict in
                # specutil.review.yaml. A fresh scaffold has no reviewer yet.
                exempt='["review-decision-current"]'

                # `specutil check` exits 1 on any error finding, so read the
                # findings rather than the exit code. A non-JSON body means the
                # tool itself broke, which must still fail loudly.
                specutil check "$change" --as json > "$TMPDIR/findings.json" || true
                if ! jq -e . "$TMPDIR/findings.json" > /dev/null 2>&1; then
                  echo "FAIL: specutil check produced no parseable JSON:" >&2
                  cat "$TMPDIR/findings.json" >&2
                  exit 1
                fi

                blocking=$(jq --argjson exempt "$exempt" \
                  '[.findings[] | select(.severity == "error") | select(.rule as $r | $exempt | index($r) | not)]' \
                  "$TMPDIR/findings.json")

                if [ "$(jq 'length' <<< "$blocking")" -eq 0 ]; then
                  echo "OK: a change scaffolded from the templates passes the rubric" | tee "$out"
                else
                  echo "FAIL: the schema templates do not satisfy the schema's own rubric." >&2
                  jq -r '.[] | "  \(.rule)  \(.file): \(.msg)"' <<< "$blocking" >&2
                  echo "Fix the templates so a scaffolded change starts out conforming." >&2
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
                  if ! bash ${./modules/home/programs/llm/citation-tools/citelock.sh} verify "$dir"; then
                    fail=1
                  fi
                done < <(find "$changes" -name citations.lock 2> /dev/null)
                if [ "$fail" -ne 0 ]; then
                  echo "FAIL: citelock offline gate failed" >&2
                  exit 1
                fi
                echo "OK: citelock offline gate ($([ "$found" -eq 1 ] && echo 'all locks pass' || echo 'no locks present'))" | tee "$out"
              '';

          # Cross-layer chord collision gate for WezTerm.
          #
          # `modules/darwin/keybindings.nix` already asserts across symbolic
          # hotkeys, aerospace, and the reserved chords. WezTerm was the layer it
          wezterm-chord-collisions =
            let
              chordsLib = import ./modules/darwin/lib/chords.nix { inherit lib; };

              reserved = builtins.attrNames chordsLib.reservedChords;

              enabledHotkeyChords = lib.mapAttrsToList (_: hk: chordsLib.chordOfHotkey hk.keys) (
                lib.filterAttrs (_: hk: hk.enable && (hk ? keys)) chordsLib.baseSymbolicHotkeys
              );

              # ui.lua binds these on top of keybindings.lua. They are declared
              # rather than extracted because ui.lua cannot load under the stub:
              # it pulls in tabline, lantern, and workspace-manager and fails at
              # line 1562. Keep in step by hand if ui.lua's bindings change.
              uiChords = [
                "cmd+shift+l"
                "cmd+s"
              ]
              ++ (map (n: "ctrl+shift+${toString n}") (lib.range 1 9));

              # Overlaps that are known and deliberately tolerated. Each needs a
              # reason; an empty reason is not an entry.
              #
              # cmd+m: symbolic hotkey ID 233 (enabled, cmd+m) versus WezTerm's
              acceptedOverlaps = [ "cmd+m" ];
            in
            pkgs.runCommand "wezterm-chord-collision-check"
              {
                nativeBuildInputs = [ pkgs.lua5_4 ];
                otherChords = lib.concatStringsSep "\n" (lib.unique (reserved ++ enabledHotkeyChords));
                uiChords = lib.concatStringsSep "\n" uiChords;
                accepted = lib.concatStringsSep "\n" acceptedOverlaps;
              }
              ''
                chordcheck=${./modules/home/programs/wezterm/chordcheck}
                lua_root=${./modules/home/programs/wezterm/lua}

                # utils.load_json_file errors on a missing file rather than
                # returning nil, and the loader reads $HOME/.config/wezterm at
                # module scope. The stub's json_parse ignores the contents, so an
                # empty object is enough to get past the read.
                export HOME="$TMPDIR/home"
                mkdir -p "$HOME/.config/wezterm"
                echo '{}' > "$HOME/.config/wezterm/config.json"
                echo '{}' > "$HOME/.config/wezterm/env.json"

                lua "$chordcheck/extract.lua" "$chordcheck/stub.lua" "$lua_root" \
                  > "$TMPDIR/from-lua" || {
                  echo "FAIL: could not extract chords from keybindings.lua." >&2
                  echo "The stub in chordcheck/ has drifted from what the module needs." >&2
                  exit 1
                }

                printf '%s\n' "$uiChords" >> "$TMPDIR/from-lua"
                sort "$TMPDIR/from-lua" | sed '/^$/d' > "$TMPDIR/wezterm"
                printf '%s\n' "$otherChords" | sed '/^$/d' | sort -u > "$TMPDIR/other"
                printf '%s\n' "$accepted" | sed '/^$/d' | sort -u > "$TMPDIR/accepted"

                total=$(wc -l < "$TMPDIR/wezterm")
                if [ "$total" -lt 50 ]; then
                  echo "FAIL: only $total wezterm chords extracted; expected the full set." >&2
                  echo "Extraction silently under-reported rather than failing." >&2
                  exit 1
                fi

                fail=0

                # 1. Duplicates inside WezTerm. `merge_keys` concatenates seven
                #    groups and WezTerm resolves a repeat silently, so one binding
                #    never fires and nothing says so.
                if dupes=$(uniq -d < "$TMPDIR/wezterm") && [ -n "$dupes" ]; then
                  echo "FAIL: WezTerm binds the same chord twice:" >&2
                  printf '  %s\n' $dupes >&2
                  fail=1
                fi

                # 2. Overlap with a layer that owns the chord globally.
                overlap=$(comm -12 <(sort -u "$TMPDIR/wezterm") "$TMPDIR/other")
                unexpected=$(comm -23 <(printf '%s\n' $overlap | sed '/^$/d' | sort -u) "$TMPDIR/accepted")
                if [ -n "$unexpected" ]; then
                  echo "FAIL: WezTerm claims a chord another layer owns:" >&2
                  printf '  %s\n' $unexpected >&2
                  echo "Rebind it, or add it to acceptedOverlaps with a reason." >&2
                  fail=1
                fi

                # 3. Aerospace invariant. See the header.
                if alt=$(grep '^alt+\|+alt+' "$TMPDIR/wezterm") && [ -n "$alt" ]; then
                  echo "FAIL: WezTerm now binds ALT chords:" >&2
                  printf '  %s\n' $alt >&2
                  echo "Aerospace owns ALT. Compare against modules/darwin/aerospace.nix" >&2
                  echo "or drop the ALT binding." >&2
                  fail=1
                fi

                [ "$fail" -eq 0 ] || exit 1
                echo "OK: $total wezterm chords, no unaccepted collision" | tee "$out"
              '';

          # Behavioral gate for the destructive-command guard.
          #
          # The guard is the only mechanical floor under the agent's Bash tool
          # while `dangerouslySkipPermissions` is on, and until this check existed
          destructive-guard-fixtures =
            pkgs.runCommand "destructive-guard-fixtures-check"
              {
                nativeBuildInputs = [
                  pkgs.jq
                  pkgs.bash
                ];
              }
              ''
                guard=${
                  lib.getExe (
                    (import ./modules/home/programs/llm/lib/guards.nix { inherit lib; }).mkBashGuard {
                      inherit pkgs;
                      name = "bash-guard-under-test";
                    }
                  )
                }

                # An allowed command makes the guard print nothing at all, and jq
                # given empty input also prints nothing, so `// "none"` never
                # fires. Default in the shell instead.
                decision() {
                  local out
                  out="$(
                    jq -cn --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}' \
                      | "$guard" \
                      | jq -r '.hookSpecificOutput.permissionDecision // empty' 2> /dev/null
                  )"
                  [ -n "$out" ] || out=none
                  printf '%s' "$out"
                }

                denied=(
                  "git push --force"
                  "git push --force-with-lease origin main"
                  "git push -f"
                  "git push origin main -f"
                  "git commit --no-verify -m wip"
                  "git commit --no-gpg-sign -m wip"
                  "git reset --hard HEAD~1"
                  "git clean -fd"
                  "git branch -D feature"
                  "git branch --delete --force feature"
                )

                allowed=(
                  "git push"
                  "git push origin main"
                  "git push origin feature-f"
                  "git status"
                  "git reset HEAD~1"
                  "git clean -n"
                  "git branch -d feature"
                  "nix flake check"
                  # A flag belonging to a LATER command in the same compound must not
                  # satisfy an earlier subcommand's rule. Each of these was denied
                  # before the gap stopped being `.*`.
                  "git push && rm -f /tmp/x"
                  "git push origin main; rm -rf /tmp/x"
                  "git reset HEAD~1 && printf -- --hard"
                  "git branch -d old && grep -D pattern file"
                )

                # A deny must still fire when the flag really does belong to the
                # subcommand, even with another command after it.
                denied+=(
                  "git push -f && echo done"
                  "git reset --hard HEAD~1; echo done"
                )

                fail=0
                for cmd in "''${denied[@]}"; do
                  got="$(decision "$cmd")"
                  if [ "$got" != "deny" ]; then
                    echo "FAIL: expected deny, got '$got' for: $cmd" >&2
                    fail=1
                  fi
                done
                for cmd in "''${allowed[@]}"; do
                  got="$(decision "$cmd")"
                  if [ "$got" != "none" ]; then
                    echo "FAIL: expected no decision, got '$got' for: $cmd" >&2
                    fail=1
                  fi
                done

                # Fail-open contract: a malformed event must not block the tool.
                # Not named `out`: that is the derivation's output path, and
                # clobbering it makes the final `tee` fail with an empty filename.
                for bad in 'not json at all' '{}' '{"tool_input":{}}'; do
                  got=""
                  got="$(printf '%s' "$bad" | "$guard" 2> /dev/null)"
                  rc=$?
                  if [ "$rc" -ne 0 ] || [ -n "$got" ]; then
                    echo "FAIL: malformed event must exit 0 with no decision: $bad" >&2
                    echo "  rc=$rc output=$got" >&2
                    fail=1
                  fi
                done

                if [ "$fail" -ne 0 ]; then
                  echo "The guard is the only mechanical floor under the Bash tool." >&2
                  exit 1
                fi
                echo "OK: ''${#denied[@]} denied, ''${#allowed[@]} allowed, 3 malformed" | tee "$out"
              '';

          # Parse gate for the zsh fragments `modules/home/programs/zsh/default.nix`
          # interpolates into `programs.zsh.initContent`. Nothing else reads them
          # before they reach a live shell, so a syntax error ships green and then
          # breaks every new shell at once.
          # Pi prepends `shellCommandPrefix` to every bash command it runs, so an
          # alias from the owner's zsh config resolves inside the harness. The
          # property that matters is that BASH PARSES it into commands that load an
          # alias, which no assertion over the string can establish: a line-count
          # gate passes a backslash-continuation version, which bash reads as one
          # command with `eval` as an argument, and rejects a correct
          # semicolon-separated one-liner. So run it.
          pi-shell-prefix-loads-aliases =
            pkgs.runCommand "pi-shell-prefix-loads-aliases-check" { nativeBuildInputs = [ pkgs.bash ]; } ''
              export HOME="$TMPDIR/home"
              mkdir -p "$HOME/.config/zsh"
              printf "alias fromzshrc='echo zshrc'\n" > "$HOME/.zshrc"
              printf "alias fromzshdir='echo zshdir'\n" > "$HOME/.config/zsh/aliases.zsh"

              # Exactly what pi does: the prefix, then the command, in one bash -c.
              got="$(bash -c "$(cat ${./modules/home/programs/llm/config/pi-shell-prefix.sh})
                alias fromzshrc > /dev/null 2>&1 && echo zshrc-ok
                alias fromzshdir > /dev/null 2>&1 && echo zshdir-ok" 2>&1)" || true

              fail=0
              case "$got" in
                *zshrc-ok*) ;;
                *) echo "FAIL: the prefix did not load an alias from ~/.zshrc; bash saw: $got" >&2; fail=1 ;;
              esac
              case "$got" in
                *zshdir-ok*) ;;
                *) echo "FAIL: the prefix did not load an alias from ~/.config/zsh; bash saw: $got" >&2; fail=1 ;;
              esac

              [ "$fail" -eq 0 ] || exit 1
              echo "OK: pi's shell prefix loads aliases from both sources" | tee "$out"
            '';

          pi-settings-keys-exist =
            pkgs.runCommand "pi-settings-keys-exist-check"
              {
                nativeBuildInputs = [ pkgs.ripgrep ];
              }
              ''
                bin=${pkgs.pi-coding-agent}/pi/pi
                docs=${pkgs.pi-coding-agent}/pi/docs/settings.md
                fail=0

                # The doc is the ground truth, not the binary's byte stream. A bare
                # substring search over 76 MB matches for reasons unrelated to whether
                # a name is a settings property: `rg -a editor` matches
                # `editorPaddingX` and a dozen doc strings, so a typo like
                # `editor` for `externalEditor` passed while pi never read it. The
                # shipped doc enumerates every real setting in a table as `` `name` ``.
                [ -f "$docs" ] || {
                  echo "FAIL: pi no longer ships docs/settings.md; this check needs a new ground truth" >&2
                  exit 1
                }

                # Declared keys must be documented settings of the installed build.
                for k in ${lib.concatStringsSep " " (import ./modules/home/programs/llm/config/pi-settings-keys.nix).declared}; do
                  if ! rg -qF "\`$k\`" "$docs"; then
                    echo "FAIL: pi.nix declares '$k' but the installed pi build does not document it as a setting" >&2
                    fail=1
                  fi
                done

                # An ownerPreference key must still BE a setting. It is deliberately
                # undeclared so the owner's runtime choice survives, and
                # `assertPreferencesUndeclared` blocks declaring it. If pi renames or
                # drops one, that assertion goes on blocking a declaration on behalf
                # of a key that no longer exists, and nothing would say so.
                for k in ${lib.concatStringsSep " " (import ./modules/home/programs/llm/config/pi-settings-keys.nix).ownerPreference}; do
                  if ! rg -qF "\`$k\`" "$docs"; then
                    echo "FAIL: '$k' is held back as owner preference but the installed pi build no longer documents it; re-evaluate the handback" >&2
                    fail=1
                  fi
                done

                # Retired keys must stay absent from BOTH, so a future edit cannot
                # quietly reintroduce one. The binary grep is kept here on purpose:
                # for absence, a substring search is the conservative direction, since
                # an incidental match only makes this stricter.
                for k in ${lib.concatStringsSep " " (import ./modules/home/programs/llm/config/pi-settings-keys.nix).retired}; do
                  if rg -qF "\`$k\`" "$docs"; then
                    echo "FAIL: '$k' is retired but the installed build now documents it; re-evaluate it" >&2
                    fail=1
                  fi
                  if rg -qa "$k" "$bin"; then
                    echo "FAIL: '$k' is retired but now exists in the pi build; re-evaluate it" >&2
                    fail=1
                  fi
                done

                [ "$fail" -eq 0 ] || exit 1
                echo "OK: every declared and held-back pi key is documented, every retired key is absent" | tee "$out"
              '';

          # The rendered OpenCode config must satisfy the schema the installed
          # build ships. Two layers are needed and neither is sufficient alone:
          # this one validates the Nix base plus a fixture pushed through the
          # same retired-key delete and merge, and the activation script
          opencode-config-schema =
            let
              render = import ./modules/home/programs/llm/config/opencode-render.nix {
                inherit pkgs lib;
              };
              # The check must validate what activation writes, so it renders the
              # same attrset the module writes. `mcp` is the only host-dependent
              # block; an empty object stands in for it.
              mainJson = pkgs.writeText "opencode-base.json" (builtins.toJSON (render.main // { mcp = { }; }));
              tuiJson = pkgs.writeText "opencode-tui.json" (builtins.toJSON render.tui);
            in
            pkgs.runCommand "opencode-config-schema-check"
              {
                nativeBuildInputs = [
                  pkgs.check-jsonschema
                  pkgs.jq
                ];
              }
              ''
                schemas=${render.schemas}

                check-jsonschema --schemafile "$schemas/config.json" ${mainJson}
                check-jsonschema --schemafile "$schemas/tui.json" ${tuiJson}

                # A live file carrying retired keys and a stale nested entry must
                # come out clean once the adoption pass runs. Base-only
                # validation cannot see either case.
                #
                # This exercises `render.mergeProgram`, which models the adopt
                # step's `retire` plus `enforce` shape. The reconciler's own
                # three-way program is covered by the `managed-file-merge3`
                # check; neither check alone covers the whole activation path.
                jq -n '{
                  theme:"dark",
                  keybinds:{leader:"ctrl+b"},
                  tui:{scroll_acceleration:{enabled:false}},
                  autoupdate:true,
                  provider:{ghost:{name:"removed upstream"}}
                }' > live-main.json
                jq -s ${lib.escapeShellArg (render.mergeProgram render.retiredMain)} live-main.json ${mainJson} > merged-main.json
                check-jsonschema --schemafile "$schemas/config.json" merged-main.json

                jq -e 'has("theme") or has("keybinds") or has("tui") | not' merged-main.json > /dev/null \
                  || { echo "FAIL: a retired key survived the merge" >&2; exit 1; }
                jq -e '.provider | has("ghost") | not' merged-main.json > /dev/null \
                  || { echo "FAIL: a stale nested provider entry survived the merge" >&2; exit 1; }

                jq -n '{theme:"dark"}' > live-tui.json
                jq -s ${lib.escapeShellArg (render.mergeProgram render.retiredTui)} live-tui.json ${tuiJson} > merged-tui.json
                check-jsonschema --schemafile "$schemas/tui.json" merged-tui.json

                echo "OK: opencode base, tui, and both merged fixtures validate" | tee "$out"
              '';

          # Covers all four defects the phase fixes, not the group alone. Each
          # assertion below fails if its fix is reverted; a grep for the fix's
          # presence would not, because a caller can keep the call and still
          # pass the wrong argument.
          # `agent-review` is the gate `sy delete` consults, so its exit code is
          # load-bearing: a wrong 0 discards unfinished work. Exercised against
          # fixture repositories rather than by grepping the script, because every
          # case here is a behaviour and none of them is visible in a pattern.
          agent-review-readiness =
            let
              notifyFor = import ./modules/home/programs/llm/config/notify.nix {
                inherit pkgs lib;
              };
            in
            pkgs.runCommand "agent-review-readiness-check"
              {
                nativeBuildInputs = [
                  notifyFor.reviewScript
                  pkgs.git
                  pkgs.jq
                ];
              }
              ''
                cfg=${./modules/home/programs/llm/config}
                export HOME="$TMPDIR/home"
                export XDG_STATE_HOME="$TMPDIR/state"
                mkdir -p "$HOME" "$XDG_STATE_HOME"
                git config --global user.email fixture@example.invalid
                git config --global user.name Fixture
                git config --global init.defaultBranch main

                fail=0
                note() {
                  echo "FAIL: $1" >&2
                  printf '%s\n' "$body" | sed 's/^/    /' >&2
                  fail=1
                }

                # `body` and `rc`, never `out`: $out is the derivation's output path.
                run() {
                  set +e
                  body="$(agent-review "$1" 2>&1)"
                  rc=$?
                  set -e
                }
                expect_rc() {
                  [ "$rc" -eq "$2" ] || note "$1: exit $rc, expected $2"
                }
                expect_out() {
                  printf '%s\n' "$body" | grep -q -- "$2" ||
                    note "$1: output does not contain '$2'"
                }
                reject_out() {
                  printf '%s\n' "$body" | grep -q -- "$2" &&
                    note "$1: output must not contain '$2'"
                  true
                }

                # A repo level with its upstream, with nothing uncommitted.
                mkrepo() {
                  mkdir -p "$1"
                  git init -q "$1"
                  echo one > "$1/f"
                  git -C "$1" add f
                  git -C "$1" commit -qm one
                  git init -q --bare "$1.origin.git"
                  git -C "$1" remote add origin "$1.origin.git"
                  git -C "$1" push -q -u origin main
                }

                # --- ready: clean and level with upstream ----------------------
                s="$TMPDIR/ready"; mkdir -p "$s"; mkrepo "$s/repo-a"
                run "$s"
                expect_rc  "ready" 0
                expect_out "ready" "clean"
                expect_out "ready" "is ready"

                # --- dirty: an uncommitted file blocks -------------------------
                s="$TMPDIR/dirty"; mkdir -p "$s"; mkrepo "$s/repo-a"
                echo two > "$s/repo-a/f"
                run "$s"
                expect_rc  "dirty" 1
                expect_out "dirty" "1 uncommitted"
                expect_out "dirty" "is not finished"

                # --- unpushed: a commit ahead of upstream blocks ---------------
                s="$TMPDIR/unpushed"; mkdir -p "$s"; mkrepo "$s/repo-a"
                echo two > "$s/repo-a/f"
                git -C "$s/repo-a" commit -qam two
                run "$s"
                expect_rc  "unpushed" 1
                expect_out "unpushed" "1 unpushed"

                # --- no upstream: said so, never reported as zero unpushed -----
                # A branch with no upstream has no answer for "how many unpushed",
                # and printing 0 would read as "nothing left to push".
                # The seshy shape: a session branch created with `worktree add -b`,
                # which sets no upstream, on a repo whose base branch IS pushed. A
                # standalone `git init` with no remote at all is not what seshy
                # creates, and asserting rc 0 on that shape hid the real defect.
                s="$TMPDIR/noupstream"; mkdir -p "$s"; mkrepo "$s/repo-a"
                git -C "$s/repo-a" checkout -q -b dev/session/repo-a
                run "$s"
                expect_out "no upstream" "(no upstream)"
                reject_out "no upstream" "0 unpushed"
                reject_out "no upstream" "commits nowhere else"
                expect_rc  "no upstream" 0

                # Same shape, but the agent committed. Those commits exist on no
                # other ref, and `sy delete` runs `branch -D`, which never refuses an
                # unmerged branch.
                s="$TMPDIR/noupstream-work"; mkdir -p "$s"; mkrepo "$s/repo-a"
                git -C "$s/repo-a" checkout -q -b dev/session/repo-a
                echo work > "$s/repo-a/f"; git -C "$s/repo-a" commit -qam work
                run "$s"
                expect_out "session branch with commits" "1 commits nowhere else"
                expect_rc  "session branch with commits" 1

                # --- liveness, driven directly, both branches --------------------
                # wezterm cannot be stubbed: agent-review is a writeShellApplication
                # whose runtimeInputs are prepended to PATH. The intersection is a
                # sourced helper for exactly that reason, so drive it with a fixed
                # live set instead of faking a mux.
                . "$cfg/agent-busy-panes.sh"
                mkdir -p "$XDG_STATE_HOME/agents/panes"
                busy_says() {
                  local label="$1" want_rc="$2" session="$3" live="$4"
                  set +e
                  body="$(agent_busy_panes "$session" "$live")"; rc=$?
                  set -e
                  [ "$rc" -eq "$want_rc" ] ||
                    note "$label: agent_busy_panes returned $rc, expected $want_rc"
                }

                printf '{"status":"working","agent":"claude","session":"s1"}\n' \
                  > "$XDG_STATE_HOME/agents/panes/42.json"

                # A live pane holding `working` blocks, and is named.
                busy_says "live pane blocks" 1 s1 "42"
                expect_out "live pane blocks" "claude is working"

                # A state file whose pane is NOT live is ignored. This is task 1.4's
                # intersection, which had no coverage at all before.
                busy_says "dead pane ignored" 0 s1 "7"

                # A state file belonging to another session is ignored.
                busy_says "other session ignored" 0 s2 "42"

                # An idle state is not busy.
                printf '{"status":"idle","agent":"claude","session":"s1"}\n' \
                  > "$XDG_STATE_HOME/agents/panes/42.json"
                busy_says "idle is not busy" 0 s1 "42"
                rm -f "$XDG_STATE_HOME/agents/panes"/*.json

                # And end to end: with no live set readable, the report skips rather
                # than blocking, because assuming liveness turns one crashed session
                # into a permanent blocker.
                s="$TMPDIR/stale"; mkdir -p "$s"; mkrepo "$s/repo-a"
                run "$s"
                expect_out "liveness unknown" "agents: skipped"
                expect_rc  "liveness unknown" 0

                # --- a clean repo after a dirty one must not clear the verdict ---
                # `unfinished` is set inside the per-repo loop and never re-checked,
                # so a reset in the clean branch would regress the whole session.
                s="$TMPDIR/mixed"; mkdir -p "$s"
                mkrepo "$s/repo-a"; mkrepo "$s/repo-b"
                echo two > "$s/repo-a/f"
                run "$s"
                expect_rc  "dirty then clean" 1
                expect_out "dirty then clean" "1 uncommitted"

                # --- an untracked file is unfinished work ------------------------
                # A file never `git add`ed exists nowhere else: no commit, no remote,
                # no reflog. A wrong "ready" here is unrecoverable.
                s="$TMPDIR/untracked"; mkdir -p "$s"; mkrepo "$s/repo-a"
                echo new > "$s/repo-a/brand-new"
                run "$s"
                expect_rc  "untracked" 1
                expect_out "untracked" "1 uncommitted"

                # --- a detached HEAD blocks, and is named ------------------------
                # `rev-parse --abbrev-ref HEAD` prints "HEAD" and exits 0 when
                # detached, so an empty-string test never fires. On a detached head
                # commits are reachable only from this worktree.
                s="$TMPDIR/detached"; mkdir -p "$s"; mkrepo "$s/repo-a"
                echo two > "$s/repo-a/f"
                git -C "$s/repo-a" commit -qam two
                git -C "$s/repo-a" checkout -q --detach HEAD
                run "$s"
                expect_out "detached" "(detached)"
                reject_out "detached" "  HEAD "
                expect_rc  "detached" 1

                # --- SESHY_SESSION names the session the state bus keys on -------
                # sy-gate passes it because the directory basename need not equal the
                # logical session name. Dropping the override makes a live agent
                # invisible.
                printf '{"status":"working","agent":"claude","session":"logical"}\n' \
                  > "$XDG_STATE_HOME/agents/panes/42.json"
                busy_says "SESHY_SESSION names the bus key" 1 logical "42"
                busy_says "the directory basename would miss it" 0 ondisk "42"
                rm -f "$XDG_STATE_HOME/agents/panes"/*.json

                # --- the state reader failing must not block ----------------------
                # This gate fails OPEN by design (D3). Only a return of 1 means busy;
                # anything else is the reader itself failing, and treating that as
                # unfinished would refuse every delete with no way to tell why.
                s="$TMPDIR/readerfail"; mkdir -p "$s"; mkrepo "$s/repo-a"
                # A stub wezterm so the script reaches the reader at all. This works
                # because the assertion sources the raw script; the packaged
                # writeShellApplication prepends its own runtimeInputs and cannot be
                # stubbed, which is why the reader is a sourced helper.
                stub="$TMPDIR/stubbin"; mkdir -p "$stub"
                # A heredoc, not echo: unquoted `[{"pane_id":42}]` loses its quotes to
                # the stub shell's own expansion and jq then reads invalid JSON.
                {
                  printf '#!/bin/sh\n'
                  printf 'cat <<EOF\n'
                  printf '[{"pane_id":42}]\n'
                  printf 'EOF\n'
                } > "$stub/wezterm"
                chmod +x "$stub/wezterm"
                set +e
                body="$(PATH="$stub:$PATH" bash -c '
                  agent_busy_panes() { return 42; }
                  . '"$cfg"'/agent-review.sh '"$s"'
                ' 2>&1)"; rc=$?
                set -e
                expect_out "reader failure is skipped" "the state reader failed"
                expect_rc  "reader failure is skipped" 0

                # --- a paused rebase is not clean --------------------------------
                # The sequencer keeps its state in the gitdir, where
                # `status --porcelain` reports nothing. Deleting the worktree would
                # discard every commit the rebase had already applied.
                s="$TMPDIR/midrebase"; mkdir -p "$s"; mkrepo "$s/repo-a"
                echo two > "$s/repo-a/f"; git -C "$s/repo-a" commit -qam two
                echo three > "$s/repo-a/f"; git -C "$s/repo-a" commit -qam three
                GIT_SEQUENCE_EDITOR="sed -i.bak '2s/^pick/break/'" \
                  git -C "$s/repo-a" rebase -i HEAD~2 > /dev/null 2>&1 || true
                run "$s"
                expect_out "paused rebase" "mid-rebase-merge"
                expect_rc  "paused rebase" 1
                git -C "$s/repo-a" rebase --abort > /dev/null 2>&1 || true

                # --- a merge paused on conflict is not clean ---------------------
                s="$TMPDIR/midmerge"; mkdir -p "$s"; mkrepo "$s/repo-a"
                git -C "$s/repo-a" checkout -q -b other
                echo other > "$s/repo-a/f"; git -C "$s/repo-a" commit -qam other
                git -C "$s/repo-a" checkout -q main
                echo main > "$s/repo-a/f"; git -C "$s/repo-a" commit -qam main
                git -C "$s/repo-a" merge other > /dev/null 2>&1 || true
                run "$s"
                expect_out "paused merge" "mid-MERGE_HEAD"
                expect_rc  "paused merge" 1

                # --- a configured upstream that no longer resolves blocks ---------
                # `fetch.prune` is set globally, so this is routine after a
                # merge-and-delete. It must NOT take the benign no-upstream carve-out:
                # the local commits may exist nowhere else.
                s="$TMPDIR/gone"; mkdir -p "$s"; mkrepo "$s/repo-a"
                echo two > "$s/repo-a/f"; git -C "$s/repo-a" commit -qam two
                git -C "$s/repo-a" update-ref -d refs/remotes/origin/main
                run "$s"
                expect_out "upstream gone" "upstream gone"
                reject_out "upstream gone" "(no upstream)"
                expect_rc  "upstream gone" 1

                # --- discovery accepts a repository root only ---------------------
                # `rev-parse --git-dir` walks upward, so without a toplevel check every
                # top-level directory of one repo reports as its own repository.
                s="$TMPDIR/nested"; mkdir -p "$s"; mkrepo "$s/repo-a"
                mkdir -p "$s/repo-a/sub-one" "$s/repo-a/sub-two"
                echo x > "$s/repo-a/sub-one/f"
                run "$s"
                [ "$(printf '%s\n' "$body" | grep -c 'sub-one\|sub-two')" -eq 0 ] ||
                  note "discovery reported a subdirectory of a repo as its own repository"
                # And running FROM a repo root reports that repo once, not once per
                # top-level directory.
                # `-le 1` was satisfied by 0, so it could not tell "reported once"
                # from "never looked" — the only distinction that matters here.
                set +e
                body="$(cd "$s/repo-a" && agent-review . 2>&1)"; rc=$?
                set -e
                [ "$(printf '%s\n' "$body" | grep -c 'uncommitted')" -eq 1 ] ||
                  note "running from a repo root did not report the dirty count exactly once"
                expect_rc "from a repo root" 1

                # --- an explicit argument wins over the environment --------------
                s="$TMPDIR/argwins"; mkdir -p "$s"; mkrepo "$s/repo-a"
                echo two > "$s/repo-a/f"
                set +e
                body="$(SESHY_SESSION_PATH="$TMPDIR/ready" agent-review "$s" 2>&1)"; rc=$?
                set -e
                expect_rc  "argument beats SESHY_SESSION_PATH" 1
                expect_out "argument beats SESHY_SESSION_PATH" "1 uncommitted"

                # --- a path that is not a directory skips, and says why --------
                run "$TMPDIR/absent"
                expect_rc  "absent path" 2
                expect_out "absent path" "skipping the readiness check"

                # --- commits that exist nowhere else block ------------------------
                # This is the state that actually loses work, and a missing upstream
                # does not measure it. `sy delete` runs `worktree remove --force`
                # then `branch -D`, and `branch -D` never refuses an unmerged branch,
                # so a commit reachable from no other ref is gone.
                s="$TMPDIR/localonly"; mkdir -p "$s/repo-a"
                git init -q "$s/repo-a"
                echo one > "$s/repo-a/f"; git -C "$s/repo-a" add f
                git -C "$s/repo-a" commit -qm one
                git -C "$s/repo-a" checkout -q -b feature
                echo two > "$s/repo-a/f"; git -C "$s/repo-a" commit -qam two
                run "$s"
                expect_out "commits nowhere else" "1 commits nowhere else"
                expect_rc  "commits nowhere else" 1

                # A clean session whose HEAD is reachable from another ref is still
                # ready: this must not refuse the most common delete.
                s="$TMPDIR/reachable"; mkdir -p "$s"; mkrepo "$s/repo-a"
                run "$s"
                reject_out "reachable elsewhere" "commits nowhere else"
                expect_rc  "reachable elsewhere" 0

                # --- a dot-named repo is inspected, not skipped -------------------
                # `*/` misses it, but the delete path removes it anyway: seshy
                # iterates every directory entry and runs `branch -D`.
                s="$TMPDIR/dotrepo"; mkdir -p "$s"; mkrepo "$s/.hidden"
                echo two > "$s/.hidden/f"
                run "$s"
                expect_out "dot-named repo" "1 uncommitted"
                expect_rc  "dot-named repo" 1

                # --- ambient git environment must not leak in ---------------------
                # A hook or `rebase --exec` exports these; `--show-toplevel` would
                # then answer about the ambient repo and every candidate mismatches.
                s="$TMPDIR/ambient"; mkdir -p "$s"; mkrepo "$s/repo-a"
                echo two > "$s/repo-a/f"
                set +e
                body="$(GIT_DIR="$TMPDIR/ready/repo-a/.git" \
                  GIT_WORK_TREE="$TMPDIR/ready/repo-a" agent-review "$s" 2>&1)"; rc=$?
                set -e
                expect_out "ambient git env ignored" "1 uncommitted"
                expect_rc  "ambient git env ignored" 1

                # --- the shape seshy actually creates: a linked worktree ----------
                # Every other fixture is a standalone `git init`, which seshy never
                # produces. Fix 4 rests on `--git-path` resolving per-worktree markers
                # into .git/worktrees/<n>/, and fix 6 on `--show-toplevel` equalling
                # the physical path of a LINKED worktree. Neither was exercised.
                main="$TMPDIR/mainrepo"
                mkrepo "$main"
                s="$TMPDIR/wt"; mkdir -p "$s"
                git -C "$main" worktree add -q "$s/repo-a" -b dev/session/repo-a HEAD

                # Discovery must accept a linked worktree as a repository root.
                run "$s"
                expect_out "worktree is discovered" "dev/session/repo-a"
                expect_rc  "worktree is discovered" 0

                # A commit in the worktree exists on no other ref.
                echo work > "$s/repo-a/f"; git -C "$s/repo-a" commit -qam work
                run "$s"
                expect_out "worktree local commit" "1 commits nowhere else"
                expect_rc  "worktree local commit" 1

                # A paused rebase in a worktree keeps its markers under
                # .git/worktrees/<n>/, which is what `--git-path` must resolve.
                echo more > "$s/repo-a/f"; git -C "$s/repo-a" commit -qam more
                GIT_SEQUENCE_EDITOR="sed -i.bak '2s/^pick/break/'" \
                  git -C "$s/repo-a" rebase -i HEAD~2 > /dev/null 2>&1 || true
                run "$s"
                expect_out "worktree paused rebase" "mid-rebase-merge"
                expect_rc  "worktree paused rebase" 1
                git -C "$s/repo-a" rebase --abort > /dev/null 2>&1 || true

                # An uncommitted change in a worktree still counts.
                echo dirty > "$s/repo-a/f"
                run "$s"
                expect_out "worktree dirty" "uncommitted"
                expect_rc  "worktree dirty" 1

                # --- examining nothing is unknown, not ready --------------------
                # Exit 2 is permissive at the gate, so nothing is trapped, but the
                # owner is told. Reporting 0 here made "found no repository" and
                # "found three clean repositories" the same answer.
                s="$TMPDIR/empty"; mkdir -p "$s/notarepo"
                run "$s"
                expect_rc  "no repositories" 2
                expect_out "no repositories" "readiness could not be determined"

                [ "$fail" -eq 0 ] || exit 1
                echo "OK: agent-review reports readiness correctly" | tee "$out"
              '';

          notify-defect-regressions =
            pkgs.runCommand "notify-defect-regressions-check"
              {
                nativeBuildInputs = [
                  pkgs.ripgrep
                  pkgs.bash
                  # agent_review_suffix reads the state file with jq.
                  pkgs.jq
                ];
              }
              ''
                cfg=${./modules/home/programs/llm/config}
                icons=${notifyIcons}
                fail=0
                note() {
                  echo "FAIL: $1" >&2
                  fail=1
                }

                # --- defect 1: one definition of the group string -------------
                # Execute the helper rather than grepping for its name. A call
                # that passes an empty pane produces the fallback form while
                # agent-focus removes the pane form, which is the original
                . "$cfg/agent-group.sh"

                paned="$(agent_group claude ctx 42)"
                [ "$paned" = "agent:42" ] || note "agent_group with a pane returned '$paned', expected 'agent:42'"

                # Two paneless sessions must not collapse onto one slot.
                a="$(agent_group claude repo-a "")"
                b="$(agent_group claude repo-b "")"
                [ "$a" != "$b" ] || note "paneless sessions share the group '$a'; the ssh fallback is gone"

                # Every consumer must pass the pane in position 3. Passing "" is
                # the bypass a presence-grep cannot see.
                for s in agent-notify agent-prompt; do
                  if ! rg -q 'agent_group "\$agent" "\$context" "\$pane"' "$cfg/$s.sh"; then
                    note "$s.sh does not pass \$pane as agent_group's third argument"
                  fi
                done
                rg -q 'agent_group "" "" "\$pane"' "$cfg/agent-focus.sh" ||
                  note "agent-focus.sh does not rebuild the group from \$pane"

                # No second definition may reappear outside the helper.
                stray="$(
                  rg -l -e 'agent-notify:\$' -e 'agent-prompt:\$' -e '"agent:\$' \
                    "$cfg" 2> /dev/null | rg -v 'agent-group\.sh' || true
                )"
                [ -z "$stray" ] || note "group literal outside agent-group.sh: $stray"

                # --- defect 2: idle dedup is scoped to the pane ---------------
                rg -q 'dedup_key="\$\{pane\}_idle"' "$cfg/agent-notify.sh" ||
                  note "idle dedup is not keyed on the pane; two panes of one harness will collapse"

                # The paneless fallback must hash, not character-substitute. A
                # `tr -c` substitution collapses "my session" and "my_session"
                # onto one key, and the multi-byte "·" separator onto another.
                rg -q 'cksum' "$cfg/agent-notify.sh" ||
                  note "the paneless dedup fallback does not hash the context; distinct sessions will collide"
                # Match the assignment, not the comment that explains why the
                # substitution was wrong. An unanchored grep for `tr -c` here
                # fired on this file's own rationale.
                rg -q 'dedup_key=.*tr -c' "$cfg/agent-notify.sh" &&
                  note "the paneless dedup fallback character-substitutes the context; that is lossy and collides"

                # --- defect 3: an approval toast is clickable -----------------
                rg -q '@CONTENTCLICKED \| @ACTIONCLICKED\)' "$cfg/agent-prompt.sh" ||
                  note "agent-prompt.sh does not route a click outcome to agent-focus"

                # --- defect 4: the fallback glyph is not a harness glyph ------
                if cmp -s "$icons/agent.png" "$icons/claude.png"; then
                  note "agent.png is byte-identical to claude.png; every unrecognized agent renders as Claude"
                fi

                # --- defect 5: the toast body names where and how long --------
                # A "done" toast that says only "finished its turn" makes the
                # human switch to find out what changed. Asserted by running the
                # composer over fixtures rather than by grepping for its parts: a
                # presence-grep passes on code that is present and wrong.
                . "$cfg/agent-review-suffix.sh"
                # The helper builds the path from XDG_STATE_HOME, so a fixture
                # tree is pointed at rather than passed in.
                export XDG_STATE_HOME="$TMPDIR/state"
                fixtures="$XDG_STATE_HOME/agents/panes"
                mkdir -p "$fixtures"

                suffix_is() {
                  local label="$1" want="$2" got="$3"
                  [ "$got" = "$want" ] ||
                    note "review suffix ($label): got '$got', want '$want'"
                }

                # Every field present. `now` is passed so the elapsed-time
                # formatting is asserted against a fixed clock.
                echo '{"repo":"sysinit","branch":"main","dirty":true,"since":1000}' > "$fixtures/full.json"
                suffix_is "all fields" " — sysinit · main ✱ — 1s" \
                  "$(agent_review_suffix full 1001)"

                # An empty field must not shift the rest. This is the tab-versus-\001
                # defect: tab is IFS whitespace, so bash collapses runs of it and a
                # repo with no branch reads the timestamp as its branch name.
                echo '{"repo":"sysinit","branch":"","dirty":false,"since":0}' > "$fixtures/nobranch.json"
                suffix_is "empty branch" " — sysinit" \
                  "$(agent_review_suffix nobranch 1001)"

                # Elapsed time rolls over into minutes and hours.
                echo '{"repo":"r","since":1000}' > "$fixtures/age.json"
                suffix_is "90s reads as minutes" " — r — 1m" \
                  "$(agent_review_suffix age 1090)"
                suffix_is "2h reads as hours" " — r — 2h" \
                  "$(agent_review_suffix age 8200)"

                # Degrade to the harness message alone rather than emitting junk.
                suffix_is "missing file" "" \
                  "$(agent_review_suffix absent 1001)"
                echo 'not json' > "$fixtures/bad.json"
                suffix_is "unparseable file" "" \
                  "$(agent_review_suffix bad 1001)"

                # A future timestamp must not print a negative age.
                suffix_is "clock skew" " — r" \
                  "$(agent_review_suffix age 900)"

                # The notifier must call the helper, not carry its own copy.
                rg -q 'agent_review_suffix' "$cfg/agent-notify.sh" ||
                  note "agent-notify does not call agent_review_suffix; the body cannot name the repo, branch, or age"
                stray_suffix="$(
                  rg -l 'agents/panes/\$pane\.json' "$cfg" 2> /dev/null |
                    rg -v 'agent-review-suffix\.sh' || true
                )"
                [ -z "$stray_suffix" ] ||
                  note "the state-file read was copied outside agent-review-suffix.sh: $stray_suffix"

                # --- defect 6: agent-notify is the only toast producer --------
                # The agent-deck flag is a Lua literal, so nothing else reads it.
                # Reverting it to true silently restores the double-announce.
                ui=${./modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua}
                rg -qU 'notifications = \{\s*\n\s*enabled = false' "$ui" ||
                  note "agent-deck notifications are re-enabled in ui.lua; agent-notify is meant to be the only producer"

                # The scrape bridge must forward into agent-notify, and must
                # skip a pane that already emits its own state. Without the skip
                # a hook-bridged harness is announced twice.
                rg -q 'agent-notify' "$ui" ||
                  note "ui.lua does not forward agent-deck transitions into agent-notify"
                # Anchor on the guard itself. A bare 'uv.agent_state' also
                # matches two unrelated readers further down the file.
                # The OpenCode bridge must bind the event OpenCode actually
                # publishes. `session.idle` does not exist in the plugin event
                rg -q 'session\.status' "$cfg/plugins/sysinit-notify.ts" ||
                  note "the opencode bridge does not bind session.status; session.idle is not a plugin event"
                rg -q '"session\.idle"' "$cfg/plugins/sysinit-notify.ts" &&
                  note "the opencode bridge binds session.idle, which the plugin hook never receives"

                rg -q 'if not \(uv and uv.agent_state' "$ui" ||
                  note "the scrape bridge does not skip hook-bridged panes; claude will double-notify"

                # The two producers phase 3 retired. Each is a plain literal in a
                # Nix file, so nothing else would notice it coming back.
                rg -q '^\s*"notify"$' "$cfg/pi.nix" &&
                  note "pi vendors the upstream notify extension again; agent-notify owns the toast"
                rg -qU 'attention = \{\s*\n\s*notifications = false' "$cfg/opencode-render.nix" ||
                  note "opencode attention.notifications is re-enabled; agent-notify owns the toast"

                [ "$fail" -eq 0 ] || exit 1
                echo "OK: six notification defects each have a failing-on-revert assertion" | tee "$out"
              '';

          zsh-fragments-parse =
            pkgs.runCommand "zsh-fragments-parse-check"
              {
                nativeBuildInputs = [ pkgs.zsh ];
              }
              ''
                src=${./modules}
                found=0
                fail=0
                while IFS= read -r f; do
                  [ -z "$f" ] && continue
                  found=$((found + 1))
                  if ! zsh -n "$f"; then
                    echo "FAIL: $f does not parse" >&2
                    fail=1
                  fi
                done < <(find "$src" -name '*.zsh' | sort)

                # A single aggregate guard is vacuous once the scan root holds
                # more than the subtree you care about: deleting the whole zsh
                # module still leaves other files and the check passes. Assert
                # each subtree contributes, so a move fails loudly.
                require_nonempty() {
                  if [ "$(find "$1" -name "$2" | wc -l)" -eq 0 ]; then
                    echo "FAIL: $1 contributed no $2 files." >&2
                    echo "It moved or was renamed, and this check stopped covering it." >&2
                    fail=1
                  fi
                }
                require_nonempty "$src/home/programs/zsh" '*.zsh'

                if [ "$found" -eq 0 ]; then
                  echo "FAIL: no .zsh fragments found under modules/." >&2
                  exit 1
                fi
                if [ "$fail" -ne 0 ]; then
                  echo "Fix the fragment; it is interpolated into every interactive shell." >&2
                  exit 1
                fi
                echo "OK: $found zsh fragments parse" | tee "$out"
              '';

          # Parse gate for the WezTerm Lua modules. `default.nix` calls their
          # `setup` functions from `extraConfig`, so a syntax error anywhere aborts
          # the whole configuration and the terminal comes up on its built-in
          # defaults, losing `default_prog`, `PATH`, and every keybinding.
          lua-parses =
            pkgs.runCommand "lua-parse-check"
              {
                nativeBuildInputs = [ pkgs.lua5_4 ];
              }
              ''
                src=${./modules}
                found=0
                fail=0
                while IFS= read -r f; do
                  [ -z "$f" ] && continue
                  found=$((found + 1))
                  if ! luac -p "$f"; then
                    echo "FAIL: $f does not parse" >&2
                    fail=1
                  fi
                done < <(find "$src" -name '*.lua' | sort)

                # Same reasoning as the zsh check: `found -eq 0` never fires once
                # the scan root spans several Lua homes. Verified: deleting
                # wezterm/lua left 22 files and the check still passed while
                # reporting success. Each home must contribute.
                require_nonempty() {
                  if [ "$(find "$1" -name '*.lua' | wc -l)" -eq 0 ]; then
                    echo "FAIL: $1 contributed no .lua files." >&2
                    echo "It moved or was renamed, and this check stopped covering it." >&2
                    fail=1
                  fi
                }
                require_nonempty "$src/home/programs/wezterm/lua"
                require_nonempty "$src/darwin/home/hammerspoon"
                require_nonempty "$src/darwin/home/sketchybar/lua"

                if [ "$found" -eq 0 ]; then
                  echo "FAIL: no .lua files found under modules/." >&2
                  exit 1
                fi
                if [ "$fail" -ne 0 ]; then
                  echo "Fix the module; a parse error drops WezTerm to its defaults." >&2
                  exit 1
                fi
                echo "OK: $found lua files parse" | tee "$out"
              '';

          # shellcheck gate for the authored shell scripts.
          #
          # `pkgs.writeShellApplication` already runs shellcheck on what it wraps,
          # but that only covers a script someone remembered to wrap. `statusline.sh`
          shell-scripts-shellcheck =
            pkgs.runCommand "shell-scripts-shellcheck-check"
              {
                nativeBuildInputs = [ pkgs.shellcheck ];
              }
              ''
                src=${./.}
                found=0
                fail=0
                while IFS= read -r f; do
                  [ -z "$f" ] && continue
                  case "$f" in
                    *.sh) ;;
                    *)
                      # Not `$`-anchored: `#!/usr/bin/env bash -e` and
                      # `#!/bin/bash --posix` are exactly how a script escapes a
                      # `$`-anchored pattern. zsh is excluded explicitly, since
                      # those files belong to the zsh parse check.
                      shebang="$(head -n1 "$f" 2> /dev/null)"
                      case "$shebang" in
                        *zsh*) continue ;;
                      esac
                      printf '%s' "$shebang" \
                        | grep -qE '^#!.*[/ ](ba)?sh([[:space:]]|$)' || continue
                      ;;
                  esac
                  found=$((found + 1))
                  if ! shellcheck -s bash "$f"; then
                    fail=1
                  fi
                done < <(find "$src" -type f ! -path '*/.git/*' | sort)

                # Per-subtree, for the reason given in the zsh and lua checks: a
                # whole-source `found -eq 0` guard never fires. Verified: deleting
                # modules/ left 6 files and the check still passed.
                require_nonempty() {
                  if [ "$(find "$1" -type f \( -name '*.sh' -o -name 'pre-commit' \) | wc -l)" -eq 0 ]; then
                    echo "FAIL: $1 contributed no shell scripts." >&2
                    echo "It moved or was renamed, and this check stopped covering it." >&2
                    fail=1
                  fi
                }
                require_nonempty "$src/modules/home/programs/llm/config"
                require_nonempty "$src/hack"
                require_nonempty "$src/.githooks"

                if [ "$found" -eq 0 ]; then
                  echo "FAIL: no shell scripts found in the flake source." >&2
                  exit 1
                fi
                if [ "$fail" -ne 0 ]; then
                  echo "Fix the finding, or add a targeted 'shellcheck disable' with a reason." >&2
                  exit 1
                fi
                echo "OK: $found shell scripts pass shellcheck" | tee "$out"
              '';
        }
      );

      lib = {
        inherit
          builders
          hostConfigs
          ;
      };

      # `nh`, `shfmt`, `shellcheck`, and `lua` are the tools AGENTS.md's Commands
      # section and the checks depend on. They were previously assumed present on
      # the machine, which made `nh darwin build` unrunnable from a clean checkout
      # (nh only reaches PATH after a switch; README.md bootstraps it via
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
              name = "sysinit-fmt";
              runtimeInputs = [
                pkgs.fd
                pkgs.nixfmt
                pkgs.shfmt
              ];
              # Formats Nix and shell. Shell was previously documented in
              # AGENTS.md as `task fmt:sh`, which no Taskfile ever provided.
              # Folding it in here means one command covers the repo and the tool
              # comes from the flake rather than from whatever is on PATH.
              text = ''
                shfmt_flags=(-i 2 -ci -sr -s)

                if [ "''${1:-}" = "--check" ]; then
                  drift=0
                  if ! fd --extension nix --type file --exec-batch nixfmt --check; then
                    drift=1
                  fi
                  # `shfmt -l` exits non-zero when it lists a file. Without the
                  # `|| true` the errexit that writeShellApplication sets kills
                  # the script inside this substitution, and --check reports
                  # nothing while still exiting 1.
                  unformatted="$(fd --extension sh --type file \
                    --exec-batch shfmt "''${shfmt_flags[@]}" -l || true)"
                  if [ -n "$unformatted" ]; then
                    echo "shfmt drift:" >&2
                    echo "$unformatted" >&2
                    drift=1
                  fi
                  [ "$drift" -eq 0 ] && echo "OK: formatting is clean"
                  exit "$drift"
                fi

                if [ "$#" -gt 0 ]; then
                  for target in "$@"; do
                    case "$target" in
                      *.sh) shfmt "''${shfmt_flags[@]}" -w "$target" ;;
                      *) nixfmt "$target" ;;
                    esac
                  done
                  exit 0
                fi

                fd --extension nix --type file --exec-batch nixfmt
                fd --extension sh --type file --exec-batch shfmt "''${shfmt_flags[@]}" -w
              '';
            }
          );
    };
}
