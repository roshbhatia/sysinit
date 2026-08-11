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

  # Which of the shared pi packages atomic can actually load.
  #
  # Decided by running the built `atomic-coding-agent-0.9.12` against a scratch
  # HOME, one package at a time and then all together, not by reading tool
  # names. Atomic is a pi fork with its own extension package
  # (`@bastani/atomic`), so a pi extension that imports the upstream package by
  # name fails to resolve it and never registers anything.
  #
  # Every entry in `excluded` carries the verdict that put it there. Adding a
  # package to either list without running the loader is how this set rots, and
  # `assertPackageSetPartitioned` below is what makes the omission loud.
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
    # The only genuine tool collision. It takes `web_search`, `fetch_content`,
    # and `get_search_content` from atomic's own bundled `@bastani/web-access`,
    # which then fails to load. Atomic keeps its integrated web tools instead.
    webAccess = "conflicts with the bundled @bastani/web-access on web_search, fetch_content, and get_search_content";

    # Cannot resolve `@earendil-works/pi-coding-agent`.
    piRetry = "imports @earendil-works/pi-coding-agent, which atomic does not provide";
    piVcc = "imports @earendil-works/pi-coding-agent, which atomic does not provide";
    subagents = "imports @earendil-works/pi-coding-agent, which atomic does not provide; atomic bundles @bastani/subagents anyway";
    btw = "imports @earendil-works/pi-coding-agent, which atomic does not provide";
    librarian = "imports @earendil-works/pi-coding-agent, which atomic does not provide";
    threads = "imports @earendil-works/pi-coding-agent, which atomic does not provide";
    askUser = "imports @earendil-works/pi-coding-agent, which atomic does not provide; atomic has a builtin ask_user_question";

    # Cannot resolve `@mariozechner/pi-coding-agent`.
    toolDisplay = "imports @mariozechner/pi-coding-agent, which atomic does not provide";
    context = "its second entry point src/context.ts imports @mariozechner/pi-coding-agent";

    mermaid = "fails atomic's extension preflight schema check";
  };

  atomicPackageList = map (name: packages.${name}) loaded;
  atomicPackagePaths = map (p: "${p}") atomicPackageList;

  # Of the six packages that install a context hook in pi, only plannotator
  # loads here, so the order has one entry rather than six.
  contextHookOrder = [ "plannotator/pi-extension" ];

  # Read from the declaration, not from the built package's `package.json`.
  # Probing a store path at evaluation time forces the package to build, and a
  # linux home config then cannot evaluate on a darwin machine.
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

  # An excluded package MUST NOT reach the rendered list. `loaded` and
  # `excluded` are written by hand, so nothing but this stops a name appearing
  # in both and the exclusion reading as decorative.
  bothLists = lib.intersectLists loaded (builtins.attrNames excluded);
  assertExclusionsHold =
    if bothLists != [ ] then
      throw "atomic.nix: ${lib.concatStringsSep ", " bothLists} is in both `loaded` and `excluded`. An excluded package cannot reach settings.json."
    else
      true;

  # The two lists MUST cover the shared package set exactly. A package added to
  # `shared/pi-packages.nix` for pi would otherwise be silently absent from
  # atomic with no record of whether anyone ran the loader against it.
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

    # Atomic builds every variable name from its own app name
    # (`ENV_PREFIX = APP_NAME.toUpperCase()`), and falls back to the `PI_`
    # spelling of the same name when the `ATOMIC_` one is unset. So each name
    # here is read by atomic alone, while a `PI_*` name set for pi reaches both
    # agents.
    sessionVariables = {
      # Without this, `getAgentDirs()` returns `[~/.atomic/agent, ~/.pi/agent]`,
      # because atomic carries `.pi` as its legacy config dir. Atomic then loads
      # every loose extension in pi's directory, and the four that import
      # `@earendil-works/pi-coding-agent` at runtime fail, which exits 1 and
      # takes the neovim RPC session down with it. Setting the variable is what
      # makes `getAgentDirs()` return the primary alone.
      #
      # The same legacy entry is how atomic read `~/.pi/agent/auth.json`, so
      # pinning the directory means atomic needs its own login. That is the
      # intended trade: atomic writes credentials to `~/.atomic/agent`, and
      # sharing one `auth.json` between two agents that both refresh OAuth
      # tokens risks one corrupting the other's file.
      ATOMIC_CODING_AGENT_DIR = "$HOME/.atomic/agent";

      # Set explicitly rather than inherited. Atomic would otherwise fall back
      # to pi's `PI_SKIP_VERSION_CHECK`, so atomic's startup behaviour would
      # depend on a variable the pi module owns.
      ATOMIC_SKIP_VERSION_CHECK = "1";
    };
  };
}
