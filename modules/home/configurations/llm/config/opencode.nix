{
  lib,
  config,
  values,
  utils,
  ...
}:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  lsp = import ../shared/lsp.nix;
  directives = import ../shared/directives.nix;
  prompts = import ../shared/prompts.nix { };

  formatLspForOpencode =
    lspConfig:
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
    ) lspConfig;

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
        // (if (server.headers or null) != null then { inherit (server) headers; } else { })
        // (if (server.timeout or null) != null then { inherit (server) timeout; } else { })
      else
        {
          type = "local";
          enabled = server.enabled or true;
          command = [ server.command ] ++ server.args;
        }
        // (if (server.env or { }) != { } then { environment = server.env; } else { })
    ) mcpServers;

  defaultInstructions = [
    "**/CONTRIBUTING.md"
    "**/docs/guidelines.md"
    "**/.cursor/rules/*.md"
    "**/COPILOT.md"
    "**/CLAUDE.md"
    "**/CONSTITUTION.md"
  ];

  agentsMd = ''
    ${directives.general}
  '';

  instructions = defaultInstructions;

  opencodeConfig = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    autoupdate = false;
    share = "disabled";
    theme = "system";

    mcp = formatMcpForOpencode mcpServers.servers;
    lsp = formatLspForOpencode lsp.lsp;

    agent = prompts.toAgents;
    inherit instructions;

    keybinds = {
      leader = "ctrl+a";
    };

    permission = {
      webfetch = "allow";
      grep = "allow";
      read = "allow";
    };
  };

  opencodeConfigFile = utils.xdg.mkWritableXdgConfig {
    inherit config;
    path = "opencode/opencode.json";
    text = opencodeConfig;
  };

  opencodeAgentsFile = utils.xdg.mkWritableXdgConfig {
    inherit config;
    path = "opencode/AGENTS.md";
    text = agentsMd;
  };
in
{
  home.activation = {
    opencodeConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] opencodeConfigFile.script;
    opencodeAgents = lib.hm.dag.entryAfter [ "linkGeneration" ] opencodeAgentsFile.script;
  };
}
