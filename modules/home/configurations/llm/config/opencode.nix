{
  lib,
  pkgs,
  values,
  ...
}:
let
  agents = import ../shared/agents.nix;
  lsp = import ../shared/lsp.nix;
  mcpServers = import ../shared/mcp.nix { inherit lib values; };
  skills = import ../shared/skills.nix { inherit lib pkgs; };
  subagents = import ../shared/subagents;
  inherit (subagents) formatSubagentAsMarkdown;

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
      _name: lspCfg:
      let
        cmd =
          if lspCfg ? command then
            if builtins.isList lspCfg.command then lspCfg.command else [ lspCfg.command ]
          else
            [ ];
      in
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
    lsp = formatLspForOpencode lsp.lsp;
    agent = builtins.removeAttrs agents [ "formatSubagentAsMarkdown" ];
    instructions = [
      "**/CONTRIBUTING.md"
      "**/docs/guidelines.md"
      "**/.cursor/rules/*.md"
      "**/COPILOT.md"
      "**/CLAUDE.md"
      "**/CONSTITUTION.md"
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
  };

  agentsMd = ''
    ${agents.general}
  '';

  skillLinksOpencode = lib.mapAttrs' (
    name: _path: lib.nameValuePair "opencode/skill/${name}/SKILL.md" { source = _path; }
  ) skills.allSkills;

  subagentLinksOpencode =
    let
      subagentNames = builtins.attrNames (builtins.removeAttrs subagents [ "formatSubagentAsMarkdown" ]);
    in
    lib.listToAttrs (
      builtins.map (
        name:
        lib.nameValuePair "opencode/agent/${name}.md" {
          text = formatSubagentAsMarkdown {
            inherit name;
            config = subagents.${name};
          };
        }
      ) subagentNames
    );

in
{
  xdg.configFile = lib.mkMerge [
    {
      "opencode/opencode.json".text = opencodeConfigJson;
      "opencode/AGENTS.md".text = agentsMd;
    }
    skillLinksOpencode
    subagentLinksOpencode
  ];
}
