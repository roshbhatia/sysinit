{
  lib,
  pkgs,
  config,
  ...
}:
let
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
    if [ ! -f ${piGeminiAuthSrc}/src/index.ts ]; then
      echo "pi.nix: pi-gemini-auth no longer ships src/index.ts; re-pin and check its package.json \`pi.extensions\`." >&2
      exit 1
    fi
    cp -r ${piGeminiAuthSrc} $out
    chmod -R u+w $out
    ln -s ${piGeminiAuthDeps}/node_modules $out/node_modules
  '';

  extensions = import ./vendored-extensions.nix;

  vendoredExtensions = pkgs.runCommand "pi-vendored-extensions" { } ''
    mkdir -p "$out"
    missing=""
    for name in ${lib.escapeShellArgs extensions}; do
      if [ ! -f "${extensionsDir}/$name.ts" ]; then
        missing="$missing $name"
        continue
      fi
      cp "${extensionsDir}/$name.ts" "$out/$name.ts"
    done
    if [ -n "$missing" ]; then
      echo "pi.nix:$missing named in vendored-extensions.nix but absent from the installed pi package." >&2
      echo "A version bump may have renamed or removed them." >&2
      exit 1
    fi
  '';

  extensionFiles = lib.listToAttrs (
    map (
      name:
      lib.nameValuePair ".pi/agent/extensions/${name}.ts" {
        source = "${vendoredExtensions}/${name}.ts";
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

  piPkgs = import ../shared/pi-packages.nix { inherit lib pkgs; };
  inherit (piPkgs) fetchNpmPkg;
  piPackages = piPkgs.packages;

  piPackageList = with piPackages; [
    piPermissionSystem
    openaiFast
    openaiVerbosity
    piRetry
    piVcc
    piPackages.subagents
    plannotator
    btw
    piReverseLast
    toolDisplay
    diff
    webAccess
    context
    subdirContext
    mermaid
    readlineSearch
    threads
    librarian
    askUser
  ];

  piPackagePaths = map (p: "${p}") piPackageList;

  contextHookOrder = [
    "pi-vcc"
    "pi-subagents"
    "plannotator/pi-extension"
    "pi-btw"
    "pi-tool-display"
    "pi-context"
  ];

  installedPiPackageNames = map (p: p.npmName or "") piPackageList;

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
      hasPermSystem = builtins.any (p: lib.hasInfix "permission-system" (p.npmName or "")) piPackageList;
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

  nvimPi = import ../shared/nvim-markdown-editor.nix {
    inherit pkgs;
    name = "nvim-pi";
  };

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
      PI_SKIP_VERSION_CHECK = "1";
    };
  };
}
