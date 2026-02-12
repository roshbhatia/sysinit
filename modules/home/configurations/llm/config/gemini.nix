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
    skillsRoot = "~/.gemini/skills";
  };

  geminiSettingsToml = ''
    # MCP Servers
    [mcpServers]
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: server:
        if (server.type or "local") == "http" then
          ''
            [mcpServers."${name}"]
            type = "http"
            url = "${server.url}"
            description = "${server.description or ""}"
          ''
        else
          ''
            [mcpServers."${name}"]
            command = "${server.command}"
            args = [${lib.concatMapStringsSep ", " (arg: "\"${arg}\"") (server.args or [ ])}]
            description = "${server.description or ""}"
            ${lib.optionalString (server.env or { } != { }) "env = ${builtins.toJSON server.env}"}
          ''
      ) mcpServers.servers
    )}
  '';

in
{
  xdg.configFile = {
    "gemini/settings.toml" = {
      text = geminiSettingsToml;
      force = true;
    };
    "gemini/GEMINI.md" = {
      text = defaultInstructions;
      force = true;
    };
  };

  home.packages = with pkgs; [
    gemini-cli
  ];
}
