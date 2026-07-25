{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  # Reuses the shared destructive-command guard, translated to devin's exit-code
  # blocking contract. bashOptions cleared for the same reason as the Claude
  # guard: a non-zero grep must not turn into an unintended block.
  bashGuardScript = pkgs.writeShellApplication {
    name = "claude-bash-guard";
    runtimeInputs = [ pkgs.jq ];
    bashOptions = [ ];
    text = builtins.readFile ./claude-bash-guard.sh;
  };

  devinGuardScript = pkgs.writeShellApplication {
    name = "devin-guard";
    runtimeInputs = [
      pkgs.jq
      bashGuardScript
    ];
    bashOptions = [ ];
    text = builtins.readFile ./devin-guard.sh;
  };

  # devin's matcher is the tool name; its shell tool is `exec`, not `Bash`.
  devinHooks = builtins.toJSON {
    PreToolUse = [
      {
        matcher = "exec";
        hooks = [
          {
            type = "command";
            command = "${lib.getExe devinGuardScript}";
          }
        ];
      }
    ];
  };

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

    # devin checks deny before ask before allow, so the destructive globs win
    # over the tier allowances regardless of ordering. Its rule syntax is
    # `Exec(<command prefix>)`, matched by prefix rather than by glob.
    permissions = {
      allow = llmLib.allowlist.formatForDevin (llmLib.allowlist.tierA ++ llmLib.allowlist.tierB);
      deny = llmLib.allowlist.formatDestructiveForDevin llmLib.allowlist.destructiveDenyGlobs;
      ask = [ ];
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
      text = kit.mkInstructionsWithStyle "~/.config/devin/skills";
      force = true;
    };

    "devin/hooks.v1.json" = {
      text = devinHooks;
      force = true;
    };
  };
}
