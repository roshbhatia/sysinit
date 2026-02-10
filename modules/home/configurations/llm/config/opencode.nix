{
  lib,
  pkgs,
  values,
  ...
}:
let
  disabledMcpServers = [ "beads" ];

  disabledLspServers = [
    "yaml"
    "yaml-language-server"
    "yaml-ls"
    "yamlls"
  ];

  agents = import ../agents.nix;
  lspConfig = import ../lsp.nix;
  mcpServers = import ../mcp.nix { inherit lib values; };
  skills = import ../skills.nix { inherit lib pkgs; };
  formatters = import ../opencode-formatters.nix { inherit lib; };

  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    autoupdate = false;
    share = "disabled";
    theme = "system";

    mcp = formatters.formatMcpForOpencode disabledMcpServers mcpServers.servers;
    lsp = formatters.formatLspForOpencode disabledLspServers lspConfig.lsp;

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
      lsp = "allow";
      bash = {
        # Safe read-only operations - always allow
        "git status*" = "allow";
        "git diff*" = "allow";
        "git log*" = "allow";
        "git show*" = "allow";
        "git branch*" = "allow";
        "git remote*" = "allow";
        "ls*" = "allow";
        "cat*" = "allow";
        "pwd*" = "allow";
        "which*" = "allow";
        "echo*" = "allow";

        # Beads operations - always allow
        "bd ready*" = "allow";
        "bd list*" = "allow";
        "bd show*" = "allow";
        "bd stats*" = "allow";
        "bd blocked*" = "allow";
        "bd create*" = "allow";
        "bd update*" = "allow";
        "bd close*" = "allow";
        "bd dep*" = "allow";
        "bd sync*" = "allow";

        # Task operations - always allow
        "task --list*" = "allow";
        "task --summary*" = "allow";

        # Nix read operations - always allow
        "nix flake check*" = "allow";
        "nix eval*" = "allow";
        "nix search*" = "allow";

        # Everything else requires user confirmation via OpenCode native ask
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
      text = agents.formatSubagentAsMarkdown { inherit name config; };
    }
  ) (lib.filterAttrs (n: _: n != "formatSubagentAsMarkdown") agents.subagents);

  skillLinksOpencode = lib.mapAttrs' (
    name: _path: lib.nameValuePair "opencode/skill/${name}/SKILL.md" { source = _path; }
  ) skills.allSkills;

in
{
  xdg.configFile = lib.mkMerge [
    {
      "opencode/opencode.json" = {
        text = builtins.toJSON opencodeConfig;
        force = true;
      };
    }
    subagentFiles
    skillLinksOpencode
  ];
}
