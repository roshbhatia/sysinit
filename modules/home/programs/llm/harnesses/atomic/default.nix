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

  atomicPackageList = map (name: packages.${name}) loaded;
  atomicPackagePaths = map (p: "${p}") atomicPackageList;

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

    file = {
      ".atomic/agent/extensions/sysinit-notify.ts" = {
        source = ./extensions/sysinit-notify.ts;
        force = true;
      };
    }
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
