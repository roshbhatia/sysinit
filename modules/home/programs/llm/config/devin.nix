{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  # devin reads JSON-with-comments from ~/.config/devin/config.json. Only
  # settings that differ from the shipped defaults are written here; defaults
  # are left to the CLI so this file does not drift as they change.
  devinConfig = builtins.toJSON {
    # Match the no-co-author posture of every other harness in this repo.
    attribution = false;

    # Nix owns the binary, so the CLI must not replace itself behind nix's back.
    auto_update = false;

    # devin will otherwise silently inherit settings from Cursor, Windsurf, and
    # Claude Code. That would make its behavior depend on config this module
    # does not own, which defeats the point of declaring it here.
    read_config_from = {
      claude = false;
      cursor = false;
      windsurf = false;
    };

    # devin's stdio entry shape is `{ command, args, env }` and its remote shape
    # is a bare `{ url }`, which is exactly what formatForCursor emits. Do not
    # swap in the Claude formatter: it adds `type`, `description`, and `enabled`
    # keys that are not part of devin's schema.
    mcpServers = llmLib.mcp.formatForCursor kit.mcpServers.servers;
  };
in
{
  home.packages = [ pkgs.devin-cli ];

  xdg.configFile = {
    "devin/config.json" = {
      text = devinConfig;
      force = true;
    };
    # devin has no documented global-instructions path of its own, so the shared
    # context lands as AGENTS.md, which it reads from the project root.
    "devin/AGENTS.md" = {
      text = kit.mkInstructionsWithStyle "~/.claude/skills";
      force = true;
    };
  };
}
