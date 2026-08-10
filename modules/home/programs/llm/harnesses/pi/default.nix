{
  lib,
  pkgs,
  config,
  ...
}:
let
  # The palette, read through one accessor rather than reached for directly.
  themeLib = import ../../../../../shared/theme-colors.nix { inherit lib; };
  themeColors = themeLib.colorsOf config;
  llmLib = import ../../lib { inherit lib; };
  piKeys = import ./settings-keys.nix;
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  extensionsDir = "${pkgs.pi-coding-agent}/pi/examples/extensions";

  piGeminiAuthSrc = pkgs.fetchFromGitHub {
    owner = "qraxiss";
    repo = "pi-gemini-auth";
    rev = "3fa07ac080594744a39c736a72885388fb0c1314";
    hash = "sha256-HjiSEC1loWfiziR47LLLx9N4y4Ly25HdWXLXtdqDZLQ=";
  };

  piGeminiAuthDeps = pkgs.buildNpmPackage {
    pname = "pi-gemini-auth-deps";
    version = "1.52.0";
    src = pkgs.runCommand "pi-gemini-auth-deps-src" { } ''
      mkdir -p $out
      cp ${./locks/pi-gemini-auth.package.json} $out/package.json
      cp ${./locks/pi-gemini-auth.lock.json} $out/package-lock.json
    '';
    npmDepsHash = "sha256-hH6PzUgcORQMCrstyGHX5F+fF9OcokoANKAOtF3jl2M=";
    npmFlags = "--ignore-scripts";
    dontNpmBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r node_modules $out/node_modules
      runHook postInstall
    '';
  };

  piGeminiAuth = pkgs.runCommand "pi-gemini-auth" { } ''
    cp -r ${piGeminiAuthSrc} $out
    chmod -R u+w $out
    ln -s ${piGeminiAuthDeps}/node_modules $out/node_modules
  '';

  assertGeminiAuthEntrypoint =
    if !builtins.pathExists "${piGeminiAuthSrc}/src/index.ts" then
      throw "pi.nix: pi-gemini-auth no longer ships src/index.ts; re-pin and check its package.json `pi.extensions`."
    else
      true;

  extensions = import ./vendored-extensions.nix;

  missingExtensions = lib.filter (n: !builtins.pathExists "${extensionsDir}/${n}.ts") extensions;
  assertExtensionsExist =
    if missingExtensions != [ ] then
      throw "pi.nix: ${lib.concatStringsSep ", " missingExtensions} named in `extensions` but absent from the installed pi package. A version bump may have renamed or removed it."
    else
      true;

  extensionFiles = lib.listToAttrs (
    map (
      name:
      lib.nameValuePair ".pi/agent/extensions/${name}.ts" {
        source = "${extensionsDir}/${name}.ts";
        force = true;
      }
    ) extensions
  );

  customExtensionFiles = {
    ".pi/agent/extensions/sysinit-notify.ts" = {
      source = ./extensions/sysinit-notify.ts;
      force = true;
    };
    ".pi/agent/extensions/diff-review.ts" = {
      source = ./extensions/diff-review.ts;
      force = true;
    };
    ".pi/agent/extensions/spec-tools.ts" = {
      source = ./extensions/spec-tools.ts;
      force = true;
    };
    ".pi/agent/extensions/openspec-sidebar" = {
      source = ./extensions/openspec-sidebar;
      recursive = true;
      force = true;
    };
    ".pi/agent/extensions/pi-gemini-auth" = {
      source = piGeminiAuth;
      recursive = true;
      force = true;
    };
  };

  stylixThemeAttrs =
    let
      c = themeColors;
      hex = name: "#${c.${name}}";
    in
    {
      "$schema" =
        "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
      name = piThemeName;
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

    context =
      mkFetchedNpmPackage "pi-context" "1.1.4"
        "sha256-pdRI1D2KIOJVV164DKpzXAQneOOEypB2GXqFzGRvasc=";
    subagents =
      mkFetchedNpmPackage "pi-subagents" "0.24.2"
        "sha256-cRcUl0gNmk4gqStqNffT6FQOozjAMuETe3OeNaQMXfA=";
    readlineSearch =
      mkFetchedNpmPackage "pi-readline-search" "0.1.0"
        "sha256-HxomHcIceZX68M0f0ZcRJSiqDzqCI0p+wcyq8CVL514=";
    threads =
      mkFetchedNpmPackage "pi-threads" "0.2.1"
        "sha256-MF++ANxMplxx0qydKoozrnNTFtb4HQ/0s923cGrsPyM=";
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

    webAccess = pkgs.buildNpmPackage {
      pname = "pi-web-access";
      version = "0.13.0";
      src = fetchNpmPkg {
        name = "pi-web-access";
        version = "0.13.0";
        hash = "sha256-6d/cX9OYHIxZ81fJgEu4L7DzMF/o63AL2/n/3zHs0DU=";
      };
      postPatch = ''
        cp ${./locks/pi-web-access.lock.json} package-lock.json
      '';
      npmDepsHash = "sha256-8onTvv7nUrTXMGvwkMkPEYc+mtpxolzF6Z9EuuB9pbs=";
      npmFlags = [
        "--ignore-scripts"
        "--legacy-peer-deps"
      ];
      dontNpmBuild = true;
      installPhase = ''
        runHook preInstall
        cp -r . $out
        runHook postInstall
      '';
    };

    btw = mkFetchedNpmPackage "pi-btw" "0.4.0" "sha256-8iAnayDUtK/BGl0ldJ9klOpItdCyV8qniSO+pXGslNo=";

    piRetry =
      mkFetchedNpmPackage "@narumitw/pi-retry" "0.22.0"
        "sha256-TwMvcJLe4ldgRw8k6/bsQpJbkePKYww20CqZVQfvsAc=";

    piVcc =
      mkFetchedNpmPackage "@monotykamary/pi-vcc" "0.8.1"
        "sha256-hsk/cwirBtfYK77aMoCoFncYhMsCff+HyBnpZD0GJKU=";

    piPermissionSystem =
      mkBuiltNpmPackage "@gotgenes/pi-permission-system" "5.14.1"
        "sha256-/qNC6erD+Rl12JpLlFwe2N2PgaekpfMHHprnKozN1rk="
        "sha256-Dvu/wuGdwjBQsJCU0N8oI+a1EysJpHFkwLwUpgjJfso="
        ./locks/pi-permission-system.lock.json;

    openaiFast =
      mkFetchedNpmPackage "@benvargas/pi-openai-fast" "1.0.2"
        "sha256-cUY9RGofE+zMlB1qcgkM55KJhEiVHnan9bWSXtvpQ4E=";

    openaiVerbosity =
      mkFetchedNpmPackage "@benvargas/pi-openai-verbosity" "1.0.0"
        "sha256-FXjeNW4UVe5PwNjjr2pL6DrLcYkdNtr7yP4jTzQvyPw=";

    plannotator =
      mkBuiltNpmPackage "@plannotator/pi-extension" "0.19.14"
        "sha256-kyiItKnuYMxp43+5wlC6BUDftp+mTxXG7PB3aEq9Qbg="
        "sha256-oiiZsd1UG1nIa7xhnOcUKpyr2J2qWbghXildxE036Ok="
        ./locks/plannotator.lock.json;

    piReverseLast =
      mkBuiltNpmPackage "@firstpick/pi-extension-reverse-last" "0.1.4"
        "sha256-+NtvjE1W8roNwgR55hzzcJWM4xhSqtk9mKDEWCoEUUE="
        "sha256-k0e9qvB9tvt6qstrYnoH7tyOoB5qRwStzE+cBdRm7CQ="
        ./locks/pi-reverse-last.lock.json;

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

  piPackagePaths = with piPackages; [
    "${piPermissionSystem}"
    "${openaiFast}"
    "${openaiVerbosity}"
    "${piRetry}"
    "${piVcc}"
    "${piPackages.subagents}"
    "${plannotator}"
    "${btw}"
    "${piReverseLast}"
    "${toolDisplay}"
    "${diff}"
    "${webAccess}"
    "${context}"
    "${subdirContext}"
    "${mermaid}"
    "${readlineSearch}"
    "${threads}"
    "${librarian}"
    "${askUser}"
  ];

  contextHookOrder = [
    "pi-vcc" # compaction, earliest: everything downstream sees compacted input
    "pi-subagents" # delegation
    "plannotator/pi-extension" # plan annotations
    "pi-btw" # side conversations
    "pi-tool-display" # display only; its context hook sets thinking labels
    "pi-context" # context management, last
  ];

  installedPiPackageNames = map (
    p:
    let
      manifest = "${p}/package.json";
    in
    if builtins.pathExists manifest then
      (builtins.fromJSON (builtins.readFile manifest)).name or ""
    else
      ""
  ) piPackagePaths;

  contextHookActual = lib.filter (name: name != null) (
    map (
      installed: lib.findFirst (name: lib.hasInfix name installed) null contextHookOrder
    ) installedPiPackageNames
  );

  assertContextHookOrder =
    let
      missing = lib.subtractLists contextHookActual contextHookOrder;
    in
    if missing != [ ] then
      throw "pi.nix: ${lib.concatStringsSep ", " missing} is declared in contextHookOrder but not installed. Remove it from the order, or restore the package."
    else if contextHookActual != contextHookOrder then
      throw "pi.nix: contextHookOrder does not match the load order in piPackagePaths.\n  declared: ${lib.concatStringsSep " -> " contextHookOrder}\n  actual:   ${lib.concatStringsSep " -> " contextHookActual}"
    else
      true;

  assertGatesDisjoint =
    let
      hasPermSystem = builtins.any (p: lib.hasInfix "permission-system" (toString p)) piPackagePaths;
      hasConfirmDestructive = builtins.elem "confirm-destructive" extensions;
    in
    if hasPermSystem && hasConfirmDestructive then
      throw "pi.nix: @gotgenes/pi-permission-system and confirm-destructive cannot both be active. Remove one."
    else
      true;

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

  nvimPi = pkgs.writeShellScriptBin "nvim-pi" ''
    exec ${pkgs.neovim}/bin/nvim --clean -c "set ft=markdown" "$@"
  '';

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

  piThemeName = "stylix";

  yoloMode = true;

  piManagedSettings = {
    packages = piPackagePaths;

    theme = piThemeName;

    skills = [ "~/.claude/skills" ];

    quietStartup = true;

    externalEditor = "${lib.getExe nvimPi}";
    enableInstallTelemetry = false;

    shellCommandPrefix = builtins.readFile ./shell-prefix.sh;
  };

  inherit (piKeys) retired;
  piRetiredSettings = retired;

  piOwnerPreferenceKeys = piKeys.ownerPreference;

  piPreferenceOverlap = lib.intersectLists piDeclaredKeys piOwnerPreferenceKeys;
  assertPreferencesUndeclared =
    if piPreferenceOverlap != [ ] then
      throw "pi.nix: ${lib.concatStringsSep ", " piPreferenceOverlap} is declared but listed as owner preference. Declaring it reverts the owner's runtime choice on every activation."
    else
      true;

  piDeclaredKeys = builtins.attrNames piManagedSettings;

  stylixTheme = builtins.toJSON stylixThemeAttrs;

  assertThemeSelected =
    if (piManagedSettings.theme or "") != piThemeName then
      throw "pi.nix: the ${piThemeName} theme is generated and installed but `piManagedSettings.theme` does not select it."
    else if (stylixThemeAttrs.name or "") != piThemeName then
      throw "pi.nix: the generated theme names itself '${stylixThemeAttrs.name or ""}' but the setting selects '${piThemeName}'. Pi resolves a theme by its name field, so the theme would be installed and unselected."
    else
      true;

  keysNotDeclared = lib.subtractLists piKeys.declared piDeclaredKeys;
  keysNotRendered = lib.subtractLists piDeclaredKeys piKeys.declared;
  assertKeysMatchManifest =
    if keysNotDeclared != [ ] then
      throw "pi.nix: ${lib.concatStringsSep ", " keysNotDeclared} is written to settings.json but missing from settings-keys.nix, so nothing verifies it against the installed binary."
    else if keysNotRendered != [ ] then
      throw "pi.nix: ${lib.concatStringsSep ", " keysNotRendered} is listed in settings-keys.nix but not written to settings.json. Remove the stale entry."
    else
      true;

  piKeyOverlap = lib.intersectLists piDeclaredKeys piRetiredSettings;
  assertPiKeysDisjoint =
    if piKeyOverlap != [ ] then
      throw "pi.nix: ${lib.concatStringsSep ", " piKeyOverlap} is both declared and retired; activation would delete it and then merge it back on every switch."
    else
      true;

  piKeybindings = pkgs.writeText "pi-keybindings.json" (
    builtins.toJSON {
      "app.session.rename" = "ctrl+shift+r";
      "tui.editor.cursorLeft" = "left";
      "app.message.followUp" = "ctrl+enter";
    }
  );

  piOpenaiModels = pkgs.writeShellApplication {
    name = "pi-openai-model-configs";
    runtimeInputs = [
      pkgs.jq
      pkgs.coreutils
    ];
    text = builtins.readFile ./openai-model-configs.sh;
  };

in
{
  sysinit.llm.managedFiles.pi = {
    path = ".pi/agent/settings.json";
    format = "json";
    content = piManagedSettings;
    retire = piRetiredSettings;
    enforce = piKeys.declared;
  };

  home.activation.piOpenaiModelConfigs = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD ${lib.getExe piOpenaiModels} || \
      echo "pi-openai-models: left the openai model configs untouched; see above. Activation continued." >&2
  '';

  home = {
    packages = [
      piAcp
      piCosts
      nvimPi
      piOpenaiModels
    ];

    file =
      (
        assert assertExtensionsExist;
        assert assertGeminiAuthEntrypoint;
        assert assertGatesDisjoint;
        assert assertPiKeysDisjoint;
        assert assertThemeSelected;
        assert assertPreferencesUndeclared;
        assert assertKeysMatchManifest;
        assert assertContextHookOrder;
        extensionFiles
      )
      // customExtensionFiles
      // {
        ".pi/agent/keybindings.json" = {
          source = piKeybindings;
          force = true;
        };
        ".pi/agent/pi-vcc-config.json" = {
          text = builtins.toJSON {
            overrideDefaultCompaction = true;
          };
          force = true;
        };
        ".pi/agent/AGENTS.md" = {
          text = kit.mkInstructionsWithStyle {
            harness = "pi";
            skillsRoot = "~/.claude/skills";
          };
          force = true;
        };
        ".pi/agent/themes/${piThemeName}.json" = {
          text = stylixTheme;
          force = true;
        };
        ".pi/agent/extensions/pi-permission-system/config.json" = {
          text = builtins.toJSON {
            debugLog = false;
            permissionReviewLog = true;
            inherit yoloMode;
            permission = llmLib.allowlist.formatForPi {
              allowTiers = llmLib.allowlist.tierA ++ llmLib.allowlist.tierB;
              denyGlobs = llmLib.allowlist.destructiveDenyGlobs;
              mcpTier = llmLib.allowlist.tierMcp;
              yolo = yoloMode;
            };
          };
          force = true;
        };

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
