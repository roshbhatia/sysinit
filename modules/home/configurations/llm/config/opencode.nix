{
  lib,
  pkgs,
  values,
  ...
}:
let
  skills = import ../shared/skills.nix { inherit lib pkgs; };
  mcpServers = import ../shared/mcp.nix { inherit lib values; };
  subagents = import ../shared/subagents;
  lsp = import ../shared/lsp.nix;
  directives = import ../shared/directives.nix;

  agents = subagents;

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
    agent = agents;
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
      prettier = {
        command = [
          "npx"
          "prettier"
          "--write"
          "$FILE"
        ];
        environment = {
          NODE_ENV = "development";
        };
        extensions = [
          ".js"
          ".ts"
          ".jsx"
          ".tsx"
        ];
      };
      custom-markdown-formatter = {
        command = [
          "deno"
          "fmt"
          "$FILE"
        ];
        extensions = [ ".md" ];
      };
    };
  };

  agentsMd = ''
    ${directives.general}
  '';

  skillLinksOpencode = builtins.listToAttrs (
    lib.mapAttrs' (name: _path: "opencode/skill/${name}/SKILL.md") skills.allSkills
  );

  skillLinksClaude = builtins.listToAttrs (
    lib.mapAttrs' (name: _path: "claude/skills/${name}/SKILL.md") skills.allSkills
  );

in
{
  xdg.configFile = lib.mkMerge [
    {
      "opencode/opencode.json".text = opencodeConfigJson;
      "opencode/AGENTS.md".text = agentsMd;
    }
    skillLinksOpencode
    skillLinksClaude
  ];
}
