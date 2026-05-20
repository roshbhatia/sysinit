{
  lib,
  pkgs,
  config,
  ...
}:
let
  piExtensionsRev = "2b895e20cd5b65bb02ef58026f3eb981fd7d27ae";
  piExtensionsSrc = pkgs.fetchFromGitHub {
    owner = "earendil-works";
    repo = "pi";
    rev = piExtensionsRev;
    sha256 = "0lkxghxxfvrjmbr6b9wgma5ch3zzz9nmhypj0ib7fww0gnvzpl8d";
  };
  extensionsDir = "${piExtensionsSrc}/packages/coding-agent/examples/extensions";

  # confirm-destructive intentionally not in this list — replaced by
  # @gotgenes/pi-permission-system below (bash-AST-aware gate). The two
  # cannot both intercept tool calls without conflict.
  extensions = [
    "dirty-repo-guard"
    "git-checkpoint"
    "handoff"
    "input-transform"
    "interactive-shell"
    "mac-system-theme"
    "model-status"
    "notify"
    "preset"
    "reload-runtime"
    "session-name"
    "status-line"
    "tools"
    "trigger-compact"
  ];

  extensionFiles = lib.listToAttrs (
    map (
      name:
      lib.nameValuePair ".pi/agent/extensions/${name}.ts" {
        source = "${extensionsDir}/${name}.ts";
        force = true;
      }
    ) extensions
  );

  # Custom local extensions authored in this repo and installed under the
  # same ~/.pi/agent/extensions/ root as the vendored upstream ones.
  customExtensionFiles = {
    ".pi/agent/extensions/openspec-status.ts" = {
      source = ./extensions/openspec-status.ts;
      force = true;
    };
  };

  stylixTheme =
    let
      c = config.lib.stylix.colors;
      hex = name: "#${c.${name}}";
    in
    builtins.toJSON {
      "$schema" =
        "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
      name = "stylix";
      vars = {
        primary = hex "base0D";
        secondary = hex "base03";
        accent = hex "base0D";
        muted = hex "base03";
        dim = hex "base04";
        success = hex "base0B";
        error = hex "base08";
        warning = hex "base0A";
        selectedBg = hex "base01";
        userMsgBg = hex "base01";
        toolPendingBg = hex "base02";
        toolSuccessBg = hex "base01";
        toolErrorBg = hex "base01";
        customMsgBg = hex "base02";
      };
      colors = {
        accent = "accent";
        border = "primary";
        borderAccent = hex "base0C";
        borderMuted = "dim";
        success = "success";
        error = "error";
        warning = "warning";
        muted = "secondary";
        dim = "dim";
        text = "";
        thinkingText = "secondary";

        selectedBg = "selectedBg";
        userMessageBg = "userMsgBg";
        userMessageText = "";
        customMessageBg = "customMsgBg";
        customMessageText = "";
        customMessageLabel = "primary";
        toolPendingBg = "toolPendingBg";
        toolSuccessBg = "toolSuccessBg";
        toolErrorBg = "toolErrorBg";
        toolTitle = "primary";
        toolOutput = "secondary";

        mdHeading = hex "base0A";
        mdLink = "primary";
        mdLinkUrl = "dim";
        mdCode = hex "base0C";
        mdCodeBlock = "";
        mdCodeBlockBorder = "secondary";
        mdQuote = "secondary";
        mdQuoteBorder = "secondary";
        mdHr = "secondary";
        mdListBullet = hex "base0C";

        toolDiffAdded = "success";
        toolDiffRemoved = "error";
        toolDiffContext = "secondary";

        syntaxComment = "secondary";
        syntaxKeyword = hex "base0E";
        syntaxFunction = hex "base0D";
        syntaxVariable = hex "base08";
        syntaxString = hex "base0B";
        syntaxNumber = hex "base09";
        syntaxType = hex "base0A";
        syntaxOperator = hex "base05";
        syntaxPunctuation = "secondary";

        thinkingOff = "dim";
        thinkingMinimal = "secondary";
        thinkingLow = hex "base0D";
        thinkingMedium = hex "base0C";
        thinkingHigh = hex "base0E";
        thinkingXhigh = hex "base08";

        bashMode = hex "base0A";
      };
      export = {
        pageBg = hex "base00";
        cardBg = hex "base01";
        infoBg = hex "base02";
      };
    };

  # ---------------------------------------------------------------------------
  # Pi packages - pre-fetched into the Nix store as local paths.
  # Pi loads them via local path entries in settings.json, so no runtime network
  # access is needed.  Each package is either a plain source fetch (no runtime
  # npm deps) or a buildNpmPackage derivation (runtime deps needed at load time).
  # ---------------------------------------------------------------------------

  # Helper: fetch an npm package tarball from the registry and extract it.
  # npm tarballs have a top-level "package/" dir; fetchzip strips it so
  # the derivation root contains package.json directly. Scoped packages
  # use `@scope/basename` for the URL path but only `basename` in the
  # tarball filename, so we split before joining.
  fetchNpmPkg =
    {
      name,
      version,
      hash,
    }:
    let
      basename = lib.last (lib.splitString "/" name);
    in
    pkgs.fetchzip {
      url = "https://registry.npmjs.org/${name}/-/${basename}-${version}.tgz";
      inherit hash;
    };

  # Helper: build an npm package that has runtime dependencies.
  # The package-lock.json is injected via postPatch because npm registry
  # tarballs do not include one, but buildNpmPackage requires it for npm ci.
  buildNpmPkg =
    {
      name,
      version,
      hash,
      npmDepsHash,
      lockFile,
    }:
    pkgs.buildNpmPackage {
      pname = name;
      inherit version npmDepsHash;
      src = fetchNpmPkg { inherit name version hash; };
      postPatch = ''
        cp ${lockFile} package-lock.json
      '';
      npmFlags = "--ignore-scripts";
      dontNpmBuild = true;
      installPhase = ''
        runHook preInstall
        cp -r . $out
        runHook postInstall
      '';
    };

  mkFetchedNpmPackage =
    name: version: hash:
    fetchNpmPkg {
      inherit name version hash;
    };

  mkBuiltNpmPackage =
    name: version: hash: npmDepsHash: lockFile:
    buildNpmPkg {
      inherit
        name
        version
        hash
        npmDepsHash
        lockFile
        ;
    };

  piPackages = {
    # Git packages - source only (no runtime npm deps)
    annotatedReply = pkgs.fetchFromGitHub {
      owner = "omaclaren";
      repo = "pi-annotated-reply";
      rev = "a230173eec2f3375671eb306b8749662b0ac9122";
      hash = "sha256-BiwaJB1XrWsAuYXVrRTtpYZdIRD24KPxCfroAXiA02c=";
    };

    # Git package with runtime npm deps - package-lock.json is in the repo
    mermaid = pkgs.buildNpmPackage {
      pname = "pi-mermaid";
      version = "0.3.0";
      src = pkgs.fetchFromGitHub {
        owner = "Gurpartap";
        repo = "pi-mermaid";
        rev = "34cab3ae794422d43707f129120a73ea39f51742";
        hash = "sha256-tXFYBlFjXUR4TF6k0FWC9T6kxWjlF/kAEt/Q9/nUCJY=";
      };
      npmDepsHash = "sha256-rHFkSF+v9MeXXfq8x7Vl9al7EmLgGrC1AMH+WVyxviA=";
      npmFlags = "--ignore-scripts";
      dontNpmBuild = true;
      installPhase = ''
        runHook preInstall
        cp -r . $out
        runHook postInstall
      '';
    };

    # npm packages - source only (no runtime deps beyond pi's bundled ones)
    context =
      mkFetchedNpmPackage "pi-context" "1.1.4"
        "sha256-pdRI1D2KIOJVV164DKpzXAQneOOEypB2GXqFzGRvasc=";
    subagents =
      mkFetchedNpmPackage "pi-subagents" "0.24.2"
        "sha256-cRcUl0gNmk4gqStqNffT6FQOozjAMuETe3OeNaQMXfA=";
    readlineSearch =
      mkFetchedNpmPackage "pi-readline-search" "0.1.0"
        "sha256-HxomHcIceZX68M0f0ZcRJSiqDzqCI0p+wcyq8CVL514=";
    rtk = mkFetchedNpmPackage "pi-rtk" "0.1.4" "sha256-2UaCeGo5IadpVywZHzh3D1RQ7L+CGjGg+aMWlJUxW14=";
    threads =
      mkFetchedNpmPackage "pi-threads" "0.2.1"
        "sha256-MF++ANxMplxx0qydKoozrnNTFtb4HQ/0s923cGrsPyM=";
    interview =
      mkFetchedNpmPackage "pi-interview" "0.8.7"
        "sha256-d7ZwYDc+FIOx9qRp+6hObjsha459exdjcRWo+iyJ0d0=";
    librarian =
      mkFetchedNpmPackage "pi-librarian" "1.3.7"
        "sha256-Obn+DyQD1WCptZO5t0YgUOdpGULNYfPxUA7NeGT7GfQ=";
    askUser =
      mkFetchedNpmPackage "pi-ask-user" "0.11.0"
        "sha256-R1TN2GWrwv3UhlAC0Ym1nMZABi/IrLxtD6EYxbDEfm8=";
    toolDisplay =
      mkFetchedNpmPackage "pi-tool-display" "0.3.6"
        "sha256-6ykaEl8IlwH667YQ+CBO/I/0rTDlIues4fYZDKJg2JE=";
    subdirContext =
      mkFetchedNpmPackage "pi-subdir-context" "1.1.7"
        "sha256-nPHuANl4j5Ank2ccLUQFLxRIxTPJCLF3G73NpU8xHnI=";

    # npm packages with runtime deps - lock files stored in ./locks/
    dcp =
      mkBuiltNpmPackage "pi-dcp" "0.2.0" "sha256-mQ+F/0EoH8WKvY4Nq5vPnOhQWHNBTd7PmVDHmEfOfOQ="
        "sha256-YyuGS17egfLwhqOwfYUKV7YY6Je9lS60HRUzBBBtoS8="
        ./locks/pi-dcp.lock.json;
    webfetch =
      mkBuiltNpmPackage "pi-webfetch-to-markdown" "1.0.1"
        "sha256-48W7utsKPZky3W5Xe9bB9g9Wp9lcQVWteZwsEYtmQ7k="
        "sha256-vjBFvarCqnv80YoWck0MnAXScWe4l8xP/qSBZ6kmWJY="
        ./locks/pi-webfetch-to-markdown.lock.json;
    mcpAdapter =
      mkBuiltNpmPackage "pi-mcp-adapter" "2.6.0" "sha256-PvG5zESCiVHC69zPyVhZ0fqQhTaJZFHEOAFEnMSIiak="
        "sha256-OSuEzxoOC2lPXUZRNqNhLTNRLkWFwQloFklW5hMvRyE="
        ./locks/pi-mcp-adapter.lock.json;

    # Phase B additions (zero-dep extensions) — load order positions are
    # set via piPackagePaths array order below.

    # pi-btw: /btw spawns a parallel sub-session with tools inherited from
    # the parent. Use for tangents that shouldn't break the main flow.
    btw = mkFetchedNpmPackage "pi-btw" "0.4.0" "sha256-8iAnayDUtK/BGl0ldJ9klOpItdCyV8qniSO+pXGslNo=";

    # @samfp/pi-memory stays out: needs node:sqlite which bun lacks. Every
    # other pi-* memory package on npm at audit time still imports from
    # @mariozechner/* (pre-rename), so they break against pi 0.74's
    # @earendil-works/* runtime without a source patch the user has
    # explicitly declined. Skip memory entirely for now; .sysinit/lessons.md
    # and Claude Code's auto-memory cover the cross-session persistence
    # use case.

    # @gotgenes/pi-permission-system 5.14.1: bash-AST-aware permission gate.
    # Imports @earendil-works/* (post-rename) so works with pi 0.74. The
    # earlier failure attributed to this package was actually node:sqlite
    # in @samfp/pi-memory at the same time — re-verified clean here.
    piPermissionSystem =
      mkBuiltNpmPackage "@gotgenes/pi-permission-system" "5.14.1"
        "sha256-/qNC6erD+Rl12JpLlFwe2N2PgaekpfMHHprnKozN1rk="
        "sha256-Dvu/wuGdwjBQsJCU0N8oI+a1EysJpHFkwLwUpgjJfso="
        ./locks/pi-permission-system.lock.json;

    # @benvargas/pi-openai-fast: /fast toggle for OpenAI priority service
    # tier on supported GPT-5.4 models. Inert when Anthropic is active.
    openaiFast =
      mkFetchedNpmPackage "@benvargas/pi-openai-fast" "1.0.2"
        "sha256-cUY9RGofE+zMlB1qcgkM55KJhEiVHnan9bWSXtvpQ4E=";

    # @benvargas/pi-openai-verbosity: per-model OpenAI Codex text-verbosity
    # overrides. Pairs with openaiFast. Inert when Anthropic is active.
    openaiVerbosity =
      mkFetchedNpmPackage "@benvargas/pi-openai-verbosity" "1.0.0"
        "sha256-FXjeNW4UVe5PwNjjr2pL6DrLcYkdNtr7yP4jTzQvyPw=";

    # @juicesharp/rpiv-advisor: second-opinion reviewer the model can
    # request from a stronger model before acting. Spec-driven gate fit.
    rpivAdvisor =
      mkFetchedNpmPackage "@juicesharp/rpiv-advisor" "1.5.0"
        "sha256-21vwJsX9+bbsyf/0FyrJM1lkUOoRvJKMCXUagl61Eqg=";

    # Phase C additions (heavier packages with runtime npm deps).

    # taskplane: parallel task orchestration with checkpoint discipline.
    # Maps onto openspec apply phases for multi-step changes.
    taskplane =
      mkBuiltNpmPackage "taskplane" "0.30.0" "sha256-J2dGslYCL39fPbvvCFVnRI07lEBHy5d4h+ZZHPlNIrM="
        "sha256-rbCUAJ0HBgnTIxjWhzBhver9lGdDDOngCin7W3Z6tm4="
        ./locks/taskplane.lock.json;

    # @plannotator/pi-extension: interactive plan review with inline
    # annotations. Pairs with openspec-propose review point.
    plannotator =
      mkBuiltNpmPackage "@plannotator/pi-extension" "0.19.14"
        "sha256-kyiItKnuYMxp43+5wlC6BUDftp+mTxXG7PB3aEq9Qbg="
        "sha256-oiiZsd1UG1nIa7xhnOcUKpyr2J2qWbghXildxE036Ok="
        ./locks/plannotator.lock.json;

    # @benvargas/pi-claude-code-use: patches Anthropic OAuth so pi can
    # piggyback on a Claude Code subscription session. Inert when not
    # using Anthropic provider.
    piClaudeCodeUse =
      mkBuiltNpmPackage "@benvargas/pi-claude-code-use" "1.0.1"
        "sha256-remGlC3uuDoSq18TgOy344fj9lEecTr0cjMZ2FlYRag="
        "sha256-NbhgVngG5y29BvVE5lcp+xImiOXi0m1kH5I6d9JuNq0="
        ./locks/pi-claude-code-use.lock.json;

    # @firstpick/pi-extension-reverse-last: session-aware undo for write/
    # edit tool calls (/reverse-last). Complements git-checkpoint at the
    # in-session granularity.
    piReverseLast =
      mkBuiltNpmPackage "@firstpick/pi-extension-reverse-last" "0.1.4"
        "sha256-+NtvjE1W8roNwgR55hzzcJWM4xhSqtk9mKDEWCoEUUE="
        "sha256-k0e9qvB9tvt6qstrYnoH7tyOoB5qRwStzE+cBdRm7CQ="
        ./locks/pi-reverse-last.lock.json;

    # @heyhuynhgiabuu/pi-diff: scoped package, Shiki-powered syntax-highlighted
    # diffs with side-by-side split view for edit and unified view for write.
    diff = pkgs.buildNpmPackage {
      pname = "pi-diff";
      version = "0.3.0";
      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/@heyhuynhgiabuu/pi-diff/-/pi-diff-0.3.0.tgz";
        hash = "sha256-lQ9V8DvaHCj7hG9q+SJwy7M9hDCOPXRfWTqBh9kjS9A=";
      };
      postPatch = ''
        cp ${./locks/pi-diff.lock.json} package-lock.json
      '';
      npmDepsHash = "sha256-DPZfPc5njMabDdo5UwX7UoWvHPwC261LhT8BsAm7U00=";
      npmFlags = "--ignore-scripts";
      dontNpmBuild = true;
      installPhase = ''
        runHook preInstall
        cp -r . $out
        runHook postInstall
      '';
    };
  };

  # Load order matters (per design D3):
  # 1. Provider routing — openaiFast + openaiVerbosity (inert for non-OpenAI)
  # 2. Orchestration — pi-subagents
  # 3. Memory + advisor — samfpMemory, rpivAdvisor
  # 4. UI / workflow — btw
  # 5. Tool providers — toolDisplay, diff, dcp, webfetch, mcpAdapter
  # 6. Content utilities — context, subdirContext, annotatedReply, mermaid,
  #                        readlineSearch, rtk, threads, interview, librarian,
  #                        askUser
  # (Permission gate will sit at position 1 once Phase C lands.)
  piPackagePaths = with piPackages; [
    # 1. Permission gate — MUST load first to wrap all tool calls below.
    "${piPermissionSystem}"
    # 2. Provider routing (inert when target provider not active).
    "${piClaudeCodeUse}"
    "${openaiFast}"
    "${openaiVerbosity}"
    # 3. Orchestration.
    "${piPackages.subagents}"
    "${taskplane}"
    # 4. Memory + advisor.
    "${rpivAdvisor}"
    # 5. UI / workflow.
    "${plannotator}"
    "${btw}"
    "${piReverseLast}"
    # 6. Tool providers.
    "${toolDisplay}"
    "${diff}"
    "${dcp}"
    "${webfetch}"
    "${mcpAdapter}"
    # 7. Content utilities.
    "${context}"
    "${subdirContext}"
    "${annotatedReply}"
    "${mermaid}"
    "${readlineSearch}"
    "${rtk}"
    "${threads}"
    "${interview}"
    "${librarian}"
    "${askUser}"
  ];

  # Build-time assertion: permission-system and confirm-destructive must
  # not both be active. The check works at module evaluation time.
  _gateConflictCheck =
    let
      hasPermSystem = builtins.any (p: lib.hasInfix "permission-system" (toString p)) piPackagePaths;
      hasConfirmDestructive = builtins.elem "confirm-destructive" extensions;
    in
    if hasPermSystem && hasConfirmDestructive then
      throw "pi.nix: @gotgenes/pi-permission-system and confirm-destructive cannot both be active. Remove one."
    else
      true;

  # @psg2/pi-costs: standalone CLI that analyses session JSONL logs for cost/token
  # summaries. Pre-compiled to dist/cli.js (bun target) — no npm deps, wraps with bun.
  piCosts = pkgs.stdenvNoCC.mkDerivation {
    pname = "pi-costs";
    version = "1.0.1";
    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/@psg2/pi-costs/-/pi-costs-1.0.1.tgz";
      hash = "sha256-J66+LmY5fJ+SAhzaDanQTPLftA0Az94cRTc4agI7PoI=";
    };
    nativeBuildInputs = [ pkgs.makeWrapper ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/pi-costs $out/bin
      cp -r . $out/lib/pi-costs/
      makeWrapper ${pkgs.bun}/bin/bun $out/bin/pi-costs \
        --add-flags "$out/lib/pi-costs/dist/cli.js"
      runHook postInstall
    '';
  };

  # nvim-pi: fast external editor wrapper — opens nvim without plugins.
  # Pi's externalEditor spawns $VISUAL/$EDITOR; nvim-pi overrides that with
  # --clean so lazy.nvim plugins don't load, eliminating the startup lag.
  nvimPi = pkgs.writeShellScriptBin "nvim-pi" ''
    exec ${pkgs.neovim}/bin/nvim --clean -c "set ft=markdown" "$@"
  '';

  # pi-acp is a standalone CLI tool (not a pi package) - exposed via home.packages.
  # dist/ is pre-compiled in the npm tarball; --ignore-scripts prevents npm ci
  # from triggering the prepare lifecycle hook (which would try to run tsup).
  piAcp = pkgs.buildNpmPackage {
    pname = "pi-acp";
    version = "0.0.26";
    src = fetchNpmPkg {
      name = "pi-acp";
      version = "0.0.26";
      hash = "sha256-37n4i+JY8I63xdXIL+BCFPohWYgugeW4ASB06y/+tjI=";
    };
    postPatch = ''
      cp ${./locks/pi-acp.lock.json} package-lock.json
    '';
    npmDepsHash = "sha256-IChKY574YL+/YeJben7ZrIsa0Y3ZPWDPDhEVNMwGDr4=";
    npmFlags = "--ignore-scripts";
    dontNpmBuild = true;
  };

  piManagedSettings = {
    packages = piPackagePaths;
    quietStartup = true;
    showLastPrompt = true;
  };

  # All Nix-managed settings in one store file. Merged into settings.json at
  # activation time so keys written by pi at runtime are preserved.
  piSettingsBase = pkgs.writeText "pi-settings-base.json" (builtins.toJSON piManagedSettings);

  piKeybindings = pkgs.writeText "pi-keybindings.json" (
    builtins.toJSON {
      renameSession = "ctrl+shift+r";
      externalEditor = null;
    }
  );

  # Merge piSettingsBase into settings.json, keeping keys written by pi at
  # runtime (e.g. session data).  Right-hand side wins on conflict so our
  # Nix-managed values always take effect.
  updatePiSettings = pkgs.writeShellScript "update-pi-settings" ''
    set -euo pipefail

    settings="$HOME/.pi/agent/settings.json"
    settings_dir="$(dirname "$settings")"
    mkdir -p "$settings_dir"

    merged_settings="$(mktemp "''${settings}.tmp.XXXXXX")"
    trap 'rm -f "$merged_settings"' EXIT

    if [ -f "$settings" ]; then
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$settings" ${piSettingsBase} > "$merged_settings"
    else
      cp ${piSettingsBase} "$merged_settings"
    fi

    mv "$merged_settings" "$settings"
  '';
in
{
  home = {
    packages = [
      piAcp
      piCosts
      nvimPi
    ];

    activation.piSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${updatePiSettings}
    '';

    file =
      extensionFiles
      // customExtensionFiles
      // {
        ".pi/agent/keybindings.json" = {
          source = piKeybindings;
          force = true;
        };
        ".pi/agent/themes/stylix.json" = {
          text = stylixTheme;
          force = true;
        };
        # Disable write/edit overrides in pi-tool-display so pi-diff owns them.
        ".pi/agent/extensions/pi-tool-display/config.json" = {
          text = builtins.toJSON {
            registerToolOverrides = {
              read = true;
              grep = true;
              find = true;
              ls = true;
              bash = true;
              edit = false;
              write = false;
            };
          };
          force = true;
        };
      };

    sessionVariables = {
      PI_SKIP_VERSION_CHECK = "$HOME/.pi";
    };
  };
}
