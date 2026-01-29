{
  lib,
  pkgs,
  values,
  ...
}:
let
  # We use a plugin for this, so don't need the MCP.
  disabledMcpServers = [ "beads" ];

  # yaml-language-server tends to pollute context with false positives on non-YAML files.
  disabledLspServers = [ "yaml-language-server" ];

  agents = import ../shared/agents.nix;
  lspConfig = import ../shared/lsp.nix;
  mcpServers = import ../shared/mcp.nix { inherit lib values; };
  skills = import ../shared/skills.nix { inherit lib pkgs; };

  formatMcpForOpencode =
    servers:
    builtins.mapAttrs (
      name: server:
      let
        isDisabled = builtins.elem name disabledMcpServers;
        baseConfig =
          if (server.type or "local") == "http" then
            {
              type = "remote";
              inherit (server) url;
            }
            // lib.attrsets.optionalAttrs (server.headers or null != null) { inherit (server) headers; }
            // lib.attrsets.optionalAttrs (server.timeout or null != null) { inherit (server) timeout; }
          else
            {
              type = "local";
              command = [ server.command ] ++ server.args;
            }
            // lib.attrsets.optionalAttrs (server.env or { } != { }) { environment = server.env; };
      in
      baseConfig // { enabled = if isDisabled then false else (server.enabled or true); }
    ) servers;

  formatLspForOpencode =
    lspServers:
    builtins.mapAttrs (
      name: lspCfg:
      let
        cmd =
          if lspCfg ? command then
            if builtins.isList lspCfg.command then lspCfg.command else [ lspCfg.command ]
          else
            [ ];
        isDisabled = builtins.elem name disabledLspServers;
      in
      if isDisabled then
        { disabled = true; }
      else
        {
          command = cmd ++ (lspCfg.args or [ ]);
          extensions = lspCfg.extensions or [ ];
        }
    ) lspServers;

  opencodeConfigJson = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    autoupdate = false;
    share = "disabled";
    theme = "system";

    mcp = formatMcpForOpencode mcpServers.servers;
    lsp = formatLspForOpencode lspConfig.lsp // {
      yaml = {
        disabled = true;
      };
    };

    instructions = [
      "**/.cursorrules"
      "**/AGENTS.md"
      "**/CLAUDE.md"
      "**/CONSTITUTION.md"
      "**/CONTRIBUTING.md"
      "**/COPILOT.md"
      "**/docs/guidelines.md"
      ".cursor/rules"
    ];

    keybinds = {
      leader = "ctrl+a";
    };

    permission = {
      webfetch = "allow";
      grep = "allow";
      read = "allow";
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
      "@mohak34/opencode-notifier@latest"
      "@zenobius/opencode-background"
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
      "opencode/opencode.json".text = opencodeConfigJson;
    }
    subagentFiles
    skillLinksOpencode
  ];
}
