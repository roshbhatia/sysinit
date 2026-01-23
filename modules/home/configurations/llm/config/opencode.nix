{
  lib,
  pkgs,
  values,
  ...
}:
let
  agents = import ../shared/agents.nix;
  lspConfig = import ../shared/lsp.nix;
  mcpServers = import ../shared/mcp.nix { inherit lib values; };
  skills = import ../shared/skills.nix { inherit lib pkgs; };

  formatMcpForOpencode =
    mcpServers:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          type = "remote";
          enabled = server.enabled or true;
          inherit (server) url;
        }
        // lib.attrsets.optionalAttrs (server.headers or null != null) { inherit (server) headers; }
        // lib.attrsets.optionalAttrs (server.timeout or null != null) { inherit (server) timeout; }
      else
        {
          type = "local";
          enabled = server.enabled or true;
          command = [ server.command ] ++ server.args;
        }
        // lib.attrsets.optionalAttrs (server.env or { } != { }) { environment = server.env; }
    ) mcpServers;

  formatLspForOpencode =
    lspCfg:
    builtins.mapAttrs (
      name: lspCfg:
      let
        cmd =
          if lspCfg ? command then
            if builtins.isList lspCfg.command then lspCfg.command else [ lspCfg.command ]
          else
            [ ];
        # yaml-language-server tends to pollute context with false positives on non-YAML files
        isDisabled = name == "yaml-language-server" || name == "yaml";
      in
      if isDisabled then
        { disabled = true; }
      else
        {
          command = cmd ++ (lspCfg.args or [ ]);
          extensions = lspCfg.extensions or [ ];
        }
    ) lspCfg;

  opencodeConfigJson = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    autoupdate = false;
    share = "disabled";

    theme = "system";

    mcp = formatMcpForOpencode mcpServers.servers;
    lsp = formatLspForOpencode lspConfig.lsp;

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
      "opencode-handoff"
      "opencode-websearch-cited@1.2.0"
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
