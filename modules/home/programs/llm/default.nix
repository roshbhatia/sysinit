{
  lib,
  pkgs,
  config,
  ...
}:
let
  skills = import ./skills.nix { inherit pkgs; };

  # Claude Code standard path - most tools can read from here
  skillFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair ".claude/skills/${name}/SKILL.md" { source = path; }
  ) skills.allSkills;

  # programs.mcp serializes `servers` straight to JSON, so strip option
  # defaults that don't belong on the wire (null command for http servers,
  # null url for stdio servers, the synthetic `type = "local"`, empty
  # headers).
  pruneServer =
    server:
    let
      isHttp = server.type == "http";
      stripped = removeAttrs server [ "type" ];
      filtered = lib.filterAttrs (
        name: value:
        value != null && !(name == "headers" && value == { }) && !(name == "args" && value == [ ])
      ) stripped;
    in
    if isHttp then filtered // { type = "http"; } else filtered;

  mcpServers = lib.mapAttrs (_: pruneServer) config.sysinit.llm.mcp.additionalServers;
in
{
  imports = [
    ./config/aider.nix
    ./config/amp.nix
    ./config/claude.nix
    ./config/codex.nix
    ./config/copilot-cli.nix
    ./config/crush.nix
    ./config/cursor.nix
    ./config/gemini.nix
    ./config/goose.nix
    ./config/hermes.nix
    ./config/mcp-servers.nix
    ./config/opencode.nix
    ./config/pi.nix
  ];

  home.file = skillFiles;

  programs.mcp = {
    enable = true;
    servers = mcpServers;
  };
}
