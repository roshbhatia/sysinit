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

  primePackageList = map (name: packages.${name}) loaded;
  primePackagePaths = map (p: "${p}") primePackageList;

  primeManagedSettings = {
    packages = primePackagePaths;

    skills = [ "~/.claude/skills" ];

    quietStartup = true;

    shellCommandPrefix = builtins.readFile ../pi/shell-prefix.sh;
  };

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
    file = {
      ".prime/agent/extensions/sysinit-notify.ts" = {
        source = ./extensions/sysinit-notify.ts;
        force = true;
      };
    }
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
