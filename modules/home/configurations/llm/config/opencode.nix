{
  lib,
  pkgs,
  values,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  mcpServers = import ../mcp.nix { inherit lib values; };
  skillsLib = import ../skills.nix { inherit pkgs; };

  disabledMcpServers = [ "beads" ];

  defaultInstructions = llmLib.instructions.makeInstructions {
    inherit (skillsLib) localSkillDescriptions remoteSkillDescriptions;
    skillsRoot = "~/.config/opencode/skills";
  };

  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    autoupdate = false;
    share = "disabled";
    theme = "system";

    mcp = llmLib.mcp.formatForOpencode disabledMcpServers mcpServers.servers;

    instructions = [
      "**/.cursorrules"
      "**/AGENTS.md"
      "**/CLAUDE.md"
      "**/CONSTITUTION.md"
      "**/CONTRIBUTING.md"
      "**/COPILOT.md"
      "**/docs/guidelines.md"
      ".cursor/rules"
      ".sysinit/lessons.md"
    ];

    keybinds = {
      leader = "ctrl+a";
    };

    permission = {
      webfetch = "allow";
      grep = "allow";
      read = "allow";
      bash = {
        "ls*" = "allow";
        "cat*" = "allow";
        "pwd*" = "allow";
        "which*" = "allow";
        "echo*" = "allow";
        "whoami*" = "allow";
        "hostname*" = "allow";
        "uname*" = "allow";
        "date*" = "allow";
        "wc*" = "allow";
        "head*" = "allow";
        "tail*" = "allow";
        "sort*" = "allow";
        "uniq*" = "allow";
        "cut*" = "allow";
        "awk*" = "allow";
        "sed*" = "allow";
        "git*" = "ask";
        "bd*" = "allow";
        "rg*" = "allow";
        "ripgrep*" = "allow";
        "fd*" = "allow";
        "ag*" = "allow";
        "find*" = "allow";
        "grep*" = "allow";
        "ast-grep*" = "allow";
        "sg*" = "allow";
        "nix*" = "allow";
        "nix-*" = "allow";
        "task*" = "allow";
        "*" = "ask";
      };
      skill = {
        "*" = "allow";
      };
    };

    formatter = {
      deadnix = {
        command = [
          "${pkgs.deadnix}/bin/deadnix"
          "--edit"
          "$FILE"
        ];
        extensions = [ ".nix" ];
      };
    };

    plugin = [
      "@bastiangx/opencode-unmoji"
      "opencode-beads"
      "opencode-handoff"
    ];
  };

  subagentFiles = lib.mapAttrs' (
    name: config:
    lib.nameValuePair "opencode/agent/${name}.md" {
      text = llmLib.instructions.formatSubagentAsMarkdown { inherit name config; };
    }
  ) (lib.filterAttrs (n: _: n != "formatSubagentAsMarkdown") llmLib.instructions.subagents);

in
{
  xdg.configFile = lib.mkMerge [
    {
      "opencode/opencode.json" = {
        text = builtins.toJSON opencodeConfig;
        force = true;
      };
    }
    {
      "opencode/AGENTS.md" = {
        text = defaultInstructions;
        force = true;
      };
    }
    subagentFiles
  ];
}
