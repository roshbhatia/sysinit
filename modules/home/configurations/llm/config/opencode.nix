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
        # OS builtins - always allow
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

        # Beads - allow all operations
        "bd *" = "allow";

        # Git read operations - always allow
        "git status*" = "allow";
        "git diff*" = "allow";
        "git log*" = "allow";
        "git show*" = "allow";
        "git branch*" = "allow";
        "git remote*" = "allow";
        "git fetch*" = "allow";
        "git ls-files*" = "allow";
        "git rev-parse*" = "allow";
        "git describe*" = "allow";

        # Search tools - allow read-only (no edit/exec flags)
        "rg *" = "allow";
        "ripgrep *" = "allow";
        "fd *" = "allow";
        "ag *" = "allow";
        "find *" = "allow";
        "grep *" = "allow";

        # ast-grep - allow search, not rewrite
        "ast-grep search*" = "allow";
        "sg search*" = "allow";
        "ast-grep scan*" = "allow";
        "sg scan*" = "allow";

        # Nix read operations - always allow
        "nix flake check*" = "allow";
        "nix flake show*" = "allow";
        "nix flake metadata*" = "allow";
        "nix eval*" = "allow";
        "nix search*" = "allow";
        "nix-instantiate*" = "allow";
        "nix show-config*" = "allow";
        "nix-store --query*" = "allow";
        "nix path-info*" = "allow";

        # Task read operations
        "task --list*" = "allow";
        "task --summary*" = "allow";
        "task -l*" = "allow";

        # Everything else requires user confirmation
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
