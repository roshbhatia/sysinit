{
  lib,
  pkgs,
  values,
  ...
}:
let
  instructionsLib = import ../instructions.nix;
  mcpServers = import ../mcp.nix { inherit lib values; };
  skillsLib = import ../skills.nix { inherit pkgs; };

  defaultInstructions = instructionsLib.makeInstructions {
    inherit (skillsLib) localSkillDescriptions remoteSkillDescriptions;
    skillsRoot = "~/.agents/skills";
  };

  codexConfigToml = ''
    # Codex CLI configuration
    # See: https://docs.openai.com/en/docs/build-a-system/configure-codex

    # Default model to use
    # model = "gpt-4o"

    # Approval policy for tool execution
    # approval_policy = "on-request"  # default | on-request | always | never

    # Sandbox mode for command execution
    # sandbox_mode = "workspace-read"  # off | workspace-read | workspace-write | container

    # Web search configuration
    # web_search = "cached"  # cached | live | disabled

    # MCP Servers
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: server:
        if (server.type or "local") == "http" then
          ''
            [mcp_servers."${name}"]
            url = "${server.url}"
            ${lib.optionalString (server.description or "" != "") ''description = "${server.description}"''}
          ''
        else
          ''
            [mcp_servers."${name}"]
            command = "${server.command}"
            ${lib.optionalString ((server.args or [ ]) != [ ])
              "args = [${lib.concatMapStringsSep ", " (arg: "\"${arg}\"") server.args}]"
            }
            ${lib.optionalString (server.env or { } != { }) ''
              [mcp_servers."${name}".env]
              ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k} = \"${v}\"") server.env)}
            ''}
            ${lib.optionalString (server.description or "" != "") ''description = "${server.description}"''}
          ''
      ) mcpServers.servers
    )}
  '';

in
{
  xdg.configFile = {
    "codex/config.toml" = {
      text = codexConfigToml;
      force = true;
    };
    "codex/AGENTS.md" = {
      text = defaultInstructions;
      force = true;
    };
  };

  home.packages = with pkgs; [
    codex
  ];
}
