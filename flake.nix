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
          # desktop/media stack) OUT — those are intentionally uncached.
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

          # The schema's templates must be a conforming starting point. A change
          # scaffolded verbatim from them has to pass the schema's own rubric,
          # otherwise an author who fills in the template still trips the gate
          # and has to reverse-engineer the rule from a failure. This caught the
          # design template missing `Rollout & Gating` and `Adversarial Review`,
          # the tasks template missing its per-phase review checkbox, and the
          # spec template modelling no negative scenario.
          #
          # Rules that gate an author or reviewer ACTION rather than template
          # content are exempt: a change that was scaffolded one second ago
          # cannot satisfy them by construction, and pre-baking a satisfying
          # artifact into the templates would only defeat the rule. Every other
          # error still fails the gate, so a real template regression is caught.
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
          # could not see, and WezTerm is where the original bug landed:
          # hammerspoon's cmd+] silently swallowed a workspace binding.
          #
          # The chords are read out of keybindings.lua by loading it under a
          # stubbed `wezterm` (see chordcheck/), not mirrored into Nix by hand. A
          # hand-mirrored list drifts, which is the same defect that let the guard
          # patterns and lib/allowlist.nix disagree on five of six patterns.
          #
          # Aerospace is handled by invariant rather than by enumeration: every
          # aerospace binding uses ALT and no WezTerm binding does, so the check
          # asserts WezTerm claims no ALT chord at all. That makes an aerospace
          # collision impossible by construction instead of by comparison.
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
              # SUPER+m -> Hide. ID 233 carries no label in the source dict and
              # sits among IDs captured from the machine's own defaults, so it is
              # very likely a preserved macOS default rather than a deliberate
              # choice. Disabling an unidentified system hotkey, or moving a
              # cmd+m that behaves conventionally, both risk more than the
              # overlap does. Revisit once ID 233 is identified.
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
          # nothing verified it. It asserts both directions, because a guard that
          # denies everything is as broken as one that denies nothing:
          #
          #   denied[]  — every prohibited form must produce a deny decision
          #   allowed[] — every permitted form must produce none
          #
          # `git push origin feature-f` is in allowed[] on purpose. An unanchored
          # `-f` pattern denies it, which is why the shared regex anchors the flag
          # on leading whitespace. Plain `git push origin main` is likewise
          # allowed: this repo permits pushing to main.
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
          #
          # The file set comes from the directory, not a list, so a fragment added
          # to the module is covered without editing this check. A file set of zero
          # is a failure: otherwise moving or renaming the directory makes the check
          # pass vacuously.
          #
          # `zsh -n` parses without executing, so a fragment that references a
          # function defined in another fragment still checks out.
          # The notification group name must have exactly one definition. It
          # previously had three: agent-notify wrote `agent-notify:<agent>:<ctx>`,
          # agent-prompt wrote `agent-prompt:<agent>:<ctx>`, and agent-focus
          # removed only the first, so an approval toast was never dismissed.
          # `agent_group` in agent-group.sh is now the only place that builds the
          # string; this check fails if any consumer reintroduces a literal.
          # Every settings key pi.nix declares must exist in the pi build that
          # reads it. A key absent from the binary is dead configuration that
          # reads as a working setting: `showLastPrompt` shipped here and in the
          # spec for months, and `powerline` was written by pi's own settings
          # screen. Neither exists in 0.82.1.
          #
          # A check derivation, not a module-level `throw`: this must read the
          # contents of the built binary, and evaluation cannot do that without
          # import-from-derivation.
          pi-settings-keys-exist =
            pkgs.runCommand "pi-settings-keys-exist-check"
              {
                nativeBuildInputs = [ pkgs.ripgrep ];
              }
              ''
                bin=${pkgs.pi-coding-agent}/pi/pi
                fail=0

                # Declared keys must be present.
                for k in ${
                  lib.concatStringsSep " " [
                    "packages"
                    "quietStartup"
                    "theme"
                    "enableInstallTelemetry"
                    "shellCommandPrefix"
                    "externalEditor"
                    "skills"
                  ]
                }; do
                  if ! rg -qa "$k" "$bin"; then
                    echo "FAIL: pi.nix declares '$k' but the installed pi build does not know it" >&2
                    fail=1
                  fi
                done

                # Retired keys must stay absent, so a future edit cannot quietly
                # reintroduce one that the binary never reads.
                for k in ${
                  lib.concatStringsSep " " [
                    "showLastPrompt"
                    "powerline"
                  ]
                }; do
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
          # validates the real merged file. A check derivation is hermetic and
          # cannot read $HOME, so it can never see what OpenCode actually reads.
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
                # come out clean once the SAME merge program activation uses runs.
                # Base-only validation cannot see either case.
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
                # defect with the call still present.
                # shellcheck disable=SC1091
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
                # vocabulary; a probe across 59 events never saw it.
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
          #
          # Parse only, never load: every module opens with `require("wezterm")`,
          # which resolves only inside the WezTerm host. `luac -p` reports syntax
          # errors with file and line and never runs the chunk.
          #
          # Lua 5.4 is the dialect WezTerm embeds. Same zero-file guard as above.
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
          # goes through `pkgs.writeShellScript`, which does not, and `hack/` scripts
          # go through no derivation at all. Checking both directories wholesale
          # means a script cannot escape analysis by not being wrapped.
          #
          # `-s bash` is explicit because most `llm/config` scripts are fragments
          # concatenated into a wrapper and carry no shebang of their own.
          #
          # The scan covers the whole flake source rather than a list of
          # directories. A directory list is itself the escape hatch: an earlier
          # revision scanned only `llm/config` and `hack/`, which silently missed
          # `citation-tools/citelock.sh`, `skills/scripts/worklog-query.sh`, and
          # `.githooks/pre-commit`.
          #
          # Selection is by shebang as well as extension, so an extensionless
          # script such as `.githooks/pre-commit` cannot escape by not being named
          # `*.sh`. zsh shebangs are excluded: those files are zsh, not bash, and
          # belong to the zsh parse check instead.
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
      # `nix run nixpkgs#nh`). This shell makes the documented commands true.
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
              #
              # `--check` replaces the documented-but-absent `task fmt:sh:check`:
              # it reports drift and exits non-zero without writing, so CI or a
              # hook can verify formatting.
              #
              # Scope is `.sh` only. The `.zsh` fragments under the zsh module are
              # zsh, not bash, and shfmt would mangle zsh-specific syntax.
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
