{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  # aws-knowledge-mcp-server speaks Streamable HTTP; OpenCode's type: "remote"
  # only speaks SSE (upstream issue #8058). Re-enable when that ships.
  disabledMcpServers = [ "aws-knowledge-mcp-server" ];

  # Skills install only to ~/.claude/skills (per default.nix); opencode reads
  # that tree natively. Point instructions at the populated root, not a phantom
  # per-tool dir that holds no SKILL.md files.
  defaultInstructions = kit.mkInstructions "~/.claude/skills";

  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    autoupdate = false;
    share = "disabled";
    theme = "system";

    # Two-tier split: the strong reasoner stays the default; a Haiku-class helper
    # handles cheap summarization/title work. Mirrors aider.nix's architect +
    # editor-model split.
    small_model = "anthropic/claude-haiku-4-5";

    tui = {
      scroll_acceleration = {
        enabled = true;
      };
    };

    mcp = llmLib.mcp.formatForOpencode disabledMcpServers kit.mcpServers.servers;

    instructions = [
      "**/.cursorrules"
      "**/AGENTS.md"
      "**/CLAUDE.md"
      "**/CONSTITUTION.md"
      "**/CONTRIBUTING.md"
      "**/COPILOT.md"
      "**/docs/guidelines.md"
      ".cursor/rules"
      ".sysinit/lessons.md"
    ];

    keybinds = {
      leader = "ctrl+a";
    };

    permission = {
      webfetch = "allow";
      grep = "allow";
      read = "allow";
      bash =
        llmLib.allowlist.formatForOpencode llmLib.allowlist.tierA
        // llmLib.allowlist.formatForOpencodeWithAction "ask" llmLib.allowlist.tierB
        // {
          "*" = "ask";
        };
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
      "@bastiangx/opencode-unmoji"
      "opencode-gemini-auth@latest"
      "opencode-handoff"
      # Bridge OpenCode to Claude Code's native auto-memory files
      # (~/.claude/projects/*/memory/). Reads and writes the same Markdown
      # store Claude Code uses, so memory created in one is visible in both.
      "opencode-claude-memory"
      "opencode-plugin-openspec"

      # Drive a ChatGPT Plus/Pro subscription against GPT-5.x / Codex models —
      # the OpenAI counterpart to opencode-gemini-auth above.
      "opencode-openai-codex-auth@latest"
      # PTY tools (pty_spawn/write/read/list/kill) for interactive and
      # long-running processes (dev servers, watch modes) plain bash can't drive.
      "opencode-pty"
      # Redact secrets before requests leave for the provider; restore after.
      "opencode-vibeguard"
      # Re-align markdown tables in model output (experimental.text.complete).
      "@franlol/opencode-md-table-formatter@latest"
    ];
  };

  subagentFiles = lib.mapAttrs' (
    name: config:
    lib.nameValuePair "opencode/agent/${name}.md" {
      text = llmLib.instructions.formatSubagentAsMarkdown { inherit name config; };
    }
  ) (lib.filterAttrs (n: _: n != "formatSubagentAsMarkdown") llmLib.instructions.subagents);
in
{
  xdg.configFile = lib.mkMerge [
    {
      "opencode/opencode.json" = {
        text = builtins.toJSON opencodeConfig;
        force = true;
      };
    }
    {
      "opencode/AGENTS.md" = {
        text = defaultInstructions;
        force = true;
      };
    }
    subagentFiles
  ];

  home.packages = [ pkgs.opencode ];
}
