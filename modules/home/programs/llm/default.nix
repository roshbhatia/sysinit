{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  skills = import ./skills.nix { inherit pkgs; };

  # Claude Code standard path - most tools can read from here
  skillFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair ".claude/skills/${name}/SKILL.md" { source = path; }
  ) skills.allSkills;

  # Helper scripts shipped beside a skill's SKILL.md; executable so the skill
  # can invoke them by path.
  skillScriptFiles = lib.mapAttrs' (
    relPath: src:
    lib.nameValuePair ".claude/skills/${relPath}" {
      source = src;
      executable = true;
    }
  ) skills.skillExtraFiles;

  # Skills shipped by specutil itself; pulled straight from the flake source
  # so they stay in sync whenever the lock is bumped (nix flake update specutil).
  specutilSkillFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair ".claude/skills/${name}/SKILL.md" { source = path; }
  ) inputs.specutil.lib.skills;

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

  # Agent-agnostic desktop notifier. The script + per-agent icons are installed
  # once here (multiple harness configs reference notify.exe in their hooks, but
  # only one place may own the home.file/home.packages entries).
  notify = import ./config/notify.nix { inherit pkgs lib; };
in
{
  imports = [
    ./openspec-schema.nix
    ./citation-tools.nix
    ./config/aider.nix
    ./config/amp.nix
    ./config/claude.nix
    ./config/codex.nix
    ./config/copilot-cli.nix
    ./config/crush.nix
    ./config/cursor.nix
    ./config/gemini.nix
    ./config/goose.nix
    ./config/mcp-servers.nix
    ./config/opencode.nix
    ./config/pi.nix
  ];

  home.file = skillFiles // skillScriptFiles // specutilSkillFiles // notify.iconFiles;

  home.packages = [
    notify.script
    notify.stateScript
    notify.promptScript
    notify.focusScript
  ];

  programs.mcp = {
    enable = true;
    servers = mcpServers;
  };
}
