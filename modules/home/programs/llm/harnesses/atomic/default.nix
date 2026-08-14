{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../../lib { inherit lib; };
  atomicKeys = import ./settings-keys.nix;
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  piPkgs = import ../shared/pi-packages.nix { inherit lib pkgs; };
  inherit (piPkgs) packages;

  loaded = [
    "piPermissionSystem"
    "openaiFast"
    "openaiVerbosity"
    "plannotator"
    "piReverseLast"
    "diff"
    "subdirContext"
    "readlineSearch"
  ];

  excluded = {
    webAccess = "conflicts with the bundled @bastani/web-access on web_search, fetch_content, and get_search_content";

    piRetry = "imports @earendil-works/pi-coding-agent, which atomic does not provide";
    piVcc = "imports @earendil-works/pi-coding-agent, which atomic does not provide";
    subagents = "imports @earendil-works/pi-coding-agent, which atomic does not provide; atomic bundles @bastani/subagents anyway";
    btw = "imports @earendil-works/pi-coding-agent, which atomic does not provide";
    librarian = "imports @earendil-works/pi-coding-agent, which atomic does not provide";
    threads = "imports @earendil-works/pi-coding-agent, which atomic does not provide";
    askUser = "imports @earendil-works/pi-coding-agent, which atomic does not provide; atomic has a builtin ask_user_question";

    toolDisplay = "imports @mariozechner/pi-coding-agent, which atomic does not provide";
    context = "its second entry point src/context.ts imports @mariozechner/pi-coding-agent";

    mermaid = "fails atomic's extension preflight schema check";
  };

  atomicPackageList = map (name: packages.${name}) loaded;
  atomicPackagePaths = map (p: "${p}") atomicPackageList;

  contextHookOrder = [ "plannotator/pi-extension" ];

  installedNames = map (p: p.npmName or "") atomicPackageList;

  contextHookActual = lib.filter (name: name != null) (
    map (
      installed: lib.findFirst (name: lib.hasInfix name installed) null contextHookOrder
    ) installedNames
  );

  assertContextHookOrder =
    let
      missing = lib.subtractLists contextHookActual contextHookOrder;
    in
    if missing != [ ] then
      throw "atomic.nix: ${lib.concatStringsSep ", " missing} is declared in contextHookOrder but not loaded. Remove it from the order, or add the package."
    else if contextHookActual != contextHookOrder then
      throw "atomic.nix: contextHookOrder does not match the load order in atomicPackagePaths.\n  declared: ${lib.concatStringsSep " -> " contextHookOrder}\n  actual:   ${lib.concatStringsSep " -> " contextHookActual}"
    else
      true;

  bothLists = lib.intersectLists loaded (builtins.attrNames excluded);
  assertExclusionsHold =
    if bothLists != [ ] then
      throw "atomic.nix: ${lib.concatStringsSep ", " bothLists} is in both `loaded` and `excluded`. An excluded package cannot reach settings.json."
    else
      true;

  sharedNames = builtins.attrNames packages;
  unaccounted = lib.subtractLists (loaded ++ builtins.attrNames excluded) sharedNames;
  strayNames = lib.subtractLists sharedNames (loaded ++ builtins.attrNames excluded);
  assertPackageSetPartitioned =
    if unaccounted != [ ] then
      throw "atomic.nix: ${lib.concatStringsSep ", " unaccounted} is in shared/pi-packages.nix but named in neither `loaded` nor `excluded`. Run it against atomic and record the verdict."
    else if strayNames != [ ] then
      throw "atomic.nix: ${lib.concatStringsSep ", " strayNames} is named here but absent from shared/pi-packages.nix. Remove the stale entry."
    else
      true;

  nvimAtomic = import ../shared/nvim-markdown-editor.nix {
    inherit pkgs;
    name = "nvim-atomic";
  };

  atomicManagedSettings = {
    packages = atomicPackagePaths;

    skills = [ "~/.claude/skills" ];

    quietStartup = true;

    externalEditor = "${lib.getExe nvimAtomic}";
    enableInstallTelemetry = false;
    enableAnalytics = false;

    shellCommandPrefix = builtins.readFile ../pi/shell-prefix.sh;
  };

  declaredKeys = builtins.attrNames atomicManagedSettings;

  preferenceOverlap = lib.intersectLists declaredKeys atomicKeys.ownerPreference;
  assertPreferencesUndeclared =
    if preferenceOverlap != [ ] then
      throw "atomic.nix: ${lib.concatStringsSep ", " preferenceOverlap} is declared but listed as owner preference. Declaring it reverts the owner's runtime choice on every activation."
    else
      true;

  keysNotDeclared = lib.subtractLists atomicKeys.declared declaredKeys;
  keysNotRendered = lib.subtractLists declaredKeys atomicKeys.declared;
  assertKeysMatchManifest =
    if keysNotDeclared != [ ] then
      throw "atomic.nix: ${lib.concatStringsSep ", " keysNotDeclared} is written to settings.json but missing from settings-keys.nix, so nothing verifies it against the installed binary."
    else if keysNotRendered != [ ] then
      throw "atomic.nix: ${lib.concatStringsSep ", " keysNotRendered} is listed in settings-keys.nix but not written to settings.json. Remove the stale entry."
    else
      true;

  yoloMode = true;
in
{
  sysinit.llm.managedFiles.atomic = {
    path = ".atomic/agent/settings.json";
    format = "json";
    content = atomicManagedSettings;
    retire = atomicKeys.retired;
    enforce = atomicKeys.declared;
  };

  home = {
    packages = [ nvimAtomic ];

    file =
      (
        assert assertExclusionsHold;
        assert assertPackageSetPartitioned;
        assert assertContextHookOrder;
        assert assertPreferencesUndeclared;
        assert assertKeysMatchManifest;
        {
          ".atomic/agent/extensions/sysinit-notify.ts" = {
            source = ./extensions/sysinit-notify.ts;
            force = true;
          };
        }
      )
      // {
        ".atomic/agent/AGENTS.md" = {
          text = kit.mkInstructionsWithStyle {
            harness = "atomic";
            skillsRoot = "~/.claude/skills";
          };
          force = true;
        };

        ".atomic/agent/extensions/pi-permission-system/config.json" = {
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
      };

    sessionVariables = {
      ATOMIC_CODING_AGENT_DIR = "$HOME/.atomic/agent";

      ATOMIC_SKIP_VERSION_CHECK = "1";

    };
  };
}
