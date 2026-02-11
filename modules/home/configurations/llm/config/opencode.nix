{
  lib,
  pkgs,
  values,
  ...
}:
let
  disabledMcpServers = [ "beads" ];

  instructionsLib = import ../instructions.nix;
  mcpServers = import ../mcp.nix { inherit lib values; };

  formatMcpForOpencode =
    disabledServers: servers:
    builtins.mapAttrs (
      name: server:
      let
        isDisabled = builtins.elem name disabledServers;
        baseConfig =
          if (server.type or "local") == "http" then
            {
              type = "remote";
              inherit (server) url;
            }
            // lib.optionalAttrs (server.headers or null != null) { inherit (server) headers; }
            // lib.optionalAttrs (server.timeout or null != null) { inherit (server) timeout; }
          else
            {
              type = "local";
              command = [ server.command ] ++ server.args;
            }
            // lib.optionalAttrs (server.env or { } != { }) { environment = server.env; };
      in
      baseConfig // { enabled = if isDisabled then false else (server.enabled or true); }
    ) servers;

  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    autoupdate = false;
    share = "disabled";
    theme = "system";

    mcp = formatMcpForOpencode disabledMcpServers mcpServers.servers;

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
        # OS builtins - always allow (simple read-only tools)
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

        # Tools with Cupcake validation (rego enforces safe usage)
        "awk*" = "allow"; # Cupcake blocks dangerous patterns
        "sed*" = "allow"; # Cupcake blocks dangerous patterns
        "git*" = "ask"; # Cupcake allows safe read ops, OpenCode prompts for write ops
        "bd*" = "allow"; # Cupcake validates beads operations
        "rg*" = "allow"; # Cupcake blocks -exec/-delete flags
        "ripgrep*" = "allow";
        "fd*" = "allow"; # Cupcake blocks -exec/-delete flags
        "ag*" = "allow";
        "find*" = "allow"; # Cupcake blocks -exec/-delete/-i flags
        "grep*" = "allow";
        "ast-grep*" = "allow"; # Cupcake blocks --rewrite
        "sg*" = "allow"; # Cupcake blocks --rewrite
        "nix*" = "allow"; # Cupcake validates read vs write operations
        "nix-*" = "allow"; # Cupcake validates nix-* tools
        "task*" = "allow"; # Cupcake validates task operations

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
      text = instructionsLib.formatSubagentAsMarkdown { inherit name config; };
    }
  ) (lib.filterAttrs (n: _: n != "formatSubagentAsMarkdown") instructionsLib.subagents);

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
  ];
}
