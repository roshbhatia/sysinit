{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../../lib { inherit lib; };
  primeKeys = import ./settings-keys.nix;
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  piPkgs = import ../shared/pi-packages.nix { inherit lib pkgs; };
  inherit (piPkgs) packages;

  loaded = [
    "piPermissionSystem"
    "openaiFast"
    "openaiVerbosity"
    "piRetry"
    "piVcc"
    "subagents"
    "plannotator"
    "btw"
    "piReverseLast"
    "diff"
    "context"
    "subdirContext"
    "mermaid"
    "readlineSearch"
    "threads"
    "librarian"
    "askUser"
  ];

  excluded = {
    toolDisplay = "calls createReadTool, which prime-agent does not export because it has no read tool";

    webAccess = "imports @earendil-works/pi-ai/compat, a subpath prime-agent-ai 0.7.1 does not export";
  };

  primePackageList = map (name: packages.${name}) loaded;
  primePackagePaths = map (p: "${p}") primePackageList;

  contextHookOrder = [
    "pi-vcc"
    "pi-subagents"
    "plannotator/pi-extension"
    "pi-btw"
    "pi-context"
  ];

  installedNames = map (p: p.npmName or "") primePackageList;

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
      throw "prime-agent: ${lib.concatStringsSep ", " missing} is declared in contextHookOrder but not loaded. Remove it from the order, or add the package."
    else if contextHookActual != contextHookOrder then
      throw "prime-agent: contextHookOrder does not match the load order in primePackagePaths.\n  declared: ${lib.concatStringsSep " -> " contextHookOrder}\n  actual:   ${lib.concatStringsSep " -> " contextHookActual}"
    else
      true;

  bothLists = lib.intersectLists loaded (builtins.attrNames excluded);
  assertExclusionsHold =
    if bothLists != [ ] then
      throw "prime-agent: ${lib.concatStringsSep ", " bothLists} is in both `loaded` and `excluded`. An excluded package cannot reach settings.json."
    else
      true;

  sharedNames = builtins.attrNames packages;
  unaccounted = lib.subtractLists (loaded ++ builtins.attrNames excluded) sharedNames;
  strayNames = lib.subtractLists sharedNames (loaded ++ builtins.attrNames excluded);
  assertPackageSetPartitioned =
    if unaccounted != [ ] then
      throw "prime-agent: ${lib.concatStringsSep ", " unaccounted} is in shared/pi-packages.nix but named in neither `loaded` nor `excluded`. Run it against prime-agent and record the verdict."
    else if strayNames != [ ] then
      throw "prime-agent: ${lib.concatStringsSep ", " strayNames} is named here but absent from shared/pi-packages.nix. Remove the stale entry."
    else
      true;

  primeManagedSettings = {
    packages = primePackagePaths;

    skills = [ "~/.claude/skills" ];

    quietStartup = true;

    shellCommandPrefix = builtins.readFile ../pi/shell-prefix.sh;
  };

  declaredKeys = builtins.attrNames primeManagedSettings;

  preferenceOverlap = lib.intersectLists declaredKeys primeKeys.ownerPreference;
  assertPreferencesUndeclared =
    if preferenceOverlap != [ ] then
      throw "prime-agent: ${lib.concatStringsSep ", " preferenceOverlap} is declared but listed as owner preference. Declaring it reverts the owner's runtime choice on every activation."
    else
      true;

  keysNotDeclared = lib.subtractLists primeKeys.declared declaredKeys;
  keysNotRendered = lib.subtractLists declaredKeys primeKeys.declared;
  assertKeysMatchManifest =
    if keysNotDeclared != [ ] then
      throw "prime-agent: ${lib.concatStringsSep ", " keysNotDeclared} is written to settings.json but missing from settings-keys.nix, so nothing verifies it against the installed binary."
    else if keysNotRendered != [ ] then
      throw "prime-agent: ${lib.concatStringsSep ", " keysNotRendered} is listed in settings-keys.nix but not written to settings.json. Remove the stale entry."
    else
      true;

  yoloMode = true;
in
{
  sysinit.llm.managedFiles.prime-agent = {
    path = ".prime/agent/settings.json";
    format = "json";
    content = primeManagedSettings;
    retire = primeKeys.retired;
    enforce = primeKeys.declared;
  };

  home = {
    file =
      (
        assert assertExclusionsHold;
        assert assertPackageSetPartitioned;
        assert assertContextHookOrder;
        assert assertPreferencesUndeclared;
        assert assertKeysMatchManifest;
        {
          ".prime/agent/extensions/sysinit-notify.ts" = {
            source = ./extensions/sysinit-notify.ts;
            force = true;
          };
        }
      )
      // {
        ".prime/agent/AGENTS.md" = {
          text = kit.mkInstructionsWithStyle {
            harness = "prime-agent";
            skillsRoot = "~/.claude/skills";
          };
          force = true;
        };

        ".prime/agent/extensions/pi-permission-system/config.json" = {
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
      PRIME_AGENT_CODING_AGENT_DIR = "$HOME/.prime/agent";

    };
  };
}
