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
                want "disabled file itself untouched" "$(jq -r .a "$HOME/d/j.json")" "1"
                rm -f "$HOME/d/j.json"

                R=${main}/bin/sysinit-llm-reconcile

                # 1. seed, all three formats
                "$R" > /dev/null
                want "json seeded"  "$(jq -r .a "$HOME/d/j.json")" "1"
                want "yaml seeded"  "$(yq -r .mode "$HOME/d/y.yaml")" "smart"
                want "toml block style" "$(yq -p toml -r '.p.spec.effort' "$HOME/d/t.toml")" "high"
                want "yaml float kept" "$(yq -r .n "$HOME/d/y.yaml")" "0.2"
                # Block style, not a single-line flow blob. yq carries flow style
                # over from JSON input, and a blob seeds the next merge.
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
                mkdir -p "$change/specs/probe-cap"
                echo "schema: rosh-spec-driven" > "$root/openspec/config.yaml"
                cp "$tmpl/proposal.md" "$change/proposal.md"
                cp "$tmpl/design.md"   "$change/design.md"
                cp "$tmpl/tasks.md"    "$change/tasks.md"
                cp "$tmpl/spec.md"     "$change/specs/probe-cap/spec.md"

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
          pi-settings-keys-exist =
            pkgs.runCommand "pi-settings-keys-exist-check"
              {
                nativeBuildInputs = [ pkgs.ripgrep ];
              }
              ''
                bin=${pkgs.pi-coding-agent}/pi/pi
                fail=0

                # Declared keys must be present.
                for k in ${lib.concatStringsSep " " (import ./modules/home/programs/llm/config/pi-settings-keys.nix).declared}; do
                  if ! rg -qa "$k" "$bin"; then
                    echo "FAIL: pi.nix declares '$k' but the installed pi build does not know it" >&2
                    fail=1
                  fi
                done

                # Retired keys must stay absent, so a future edit cannot quietly
                # reintroduce one that the binary never reads.
                for k in ${lib.concatStringsSep " " (import ./modules/home/programs/llm/config/pi-settings-keys.nix).retired}; do
                  if rg -qa "$k" "$bin"; then
                    echo "FAIL: '$k' is retired but now exists in the pi build; re-evaluate it" >&2
                    fail=1
                  fi
                done

                [ "$fail" -eq 0 ] || exit 1
                echo "OK: every declared pi settings key exists, every retired key is absent" | tee "$out"
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
                # step's `adoptDelete` plus `enforce` shape. The reconciler's own
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
          notify-defect-regressions =
            pkgs.runCommand "notify-defect-regressions-check"
              {
                nativeBuildInputs = [
                  pkgs.ripgrep
                  pkgs.bash
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
                # human switch to find out what changed.
                rg -q 'agents/panes/\$pane.json' "$cfg/agent-notify.sh" ||
                  note "agent-notify does not read the per-pane state file; the body cannot name the repo, branch, or age"

                # The fields must be split on a NON-whitespace separator. Tab and
                # newline are IFS whitespace, so bash collapses runs of them and an
                # empty field shifts every later value left: a repo with no branch
                # reads the timestamp as its branch name.
                rg -q 'join\("' "$cfg/agent-notify.sh" ||
                  note "the state-file fields are not joined on \\u0001; an empty field will shift the rest"
                rg -q 'IFS=\$\(printf' "$cfg/agent-notify.sh" ||
                  note "the state-file fields are not split on the matching separator"

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
