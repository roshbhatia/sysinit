{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  # Keep this list for confirmed per-harness incompatibilities only.
  disabledMcpServers = [ "slack" ];

  # Skills install only to ~/.claude/skills (per default.nix); opencode reads
  # that tree natively. Point instructions at the populated root, not a phantom
  # per-tool dir that holds no SKILL.md files.
  defaultInstructions =
    kit.mkInstructions "~/.claude/skills"
    + ''

      ## OpenCode-specific Slack access

      OpenCode's MCP client does not support Slack's dynamic auth flow. If you
      need Slack context or need to send a Slack message, ask Claude Code to do
      it with `claude -p '<your Slack task>'` because Claude has Slack MCP
      access configured.
    ''
    + "\n## Output Style\n\n"
    + kit.llmLib.instructions.outputStyleRules;

  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    autoupdate = false;
    share = "disabled";
    theme = "system";

    # Two-tier split: the strong reasoner stays the default; a Haiku-class helper
    # handles cheap summarization/title work. Can be overridden to a local Ollama
    # model at startup with --model ollama/qwen2.5-coder:7b.
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
      write = "allow";
      # Catch-all allow, with the shared destructive-command globs denied. More
      # specific keys override "*". Prefix-matched (leakier than the Claude/Codex
      # regex guards), so this is defense-in-depth, not the primary gate.
      bash = {
        "*" = "allow";
      }
      // (llmLib.allowlist.formatDestructiveForOpencode llmLib.allowlist.destructiveDenyGlobs);
      skill = {
        "*" = "allow";
      };
    };

    # Live nix diagnostics via nixd (full store path — no PATH dependency).
    lsp = {
      nixd = {
        command = [ "${pkgs.nixd}/bin/nixd" ];
        extensions = [ ".nix" ];
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
      "opencode-gemini-auth"
      "opencode-handoff"
      # Bridge OpenCode to Claude Code's native auto-memory files
      # (~/.claude/projects/*/memory/). Reads and writes the same Markdown
      # store Claude Code uses, so memory created in one is visible in both.
      "opencode-claude-memory"
      "opencode-plugin-openspec"

      # Drive a ChatGPT Plus/Pro subscription against GPT-5.x / Codex models —
      # the OpenAI counterpart to opencode-gemini-auth above.
      "opencode-openai-codex-auth"
      # PTY tools (pty_spawn/write/read/list/kill) for interactive and
      # long-running processes (dev servers, watch modes) plain bash can't drive.
      "opencode-pty"
      # Redact secrets before requests leave for the provider; restore after.
      "opencode-vibeguard"
      # Re-align markdown tables in model output (experimental.text.complete).
      "@franlol/opencode-md-table-formatter"
    ];

    # Ollama local inference provider. Models must be pulled separately:
    #   ollama pull qwen2.5-coder:14b   # main coding model (~8 GB)
    #   ollama pull qwen2.5-coder:7b    # fast/cheap tasks (~4.5 GB)
    # Switch to a local model with: opencode --model ollama/qwen2.5-coder:14b
    provider = {
      ollama = {
        npm = "@ai-sdk/openai-compatible";
        name = "Ollama (local)";
        options = {
          baseURL = "http://localhost:11434/v1";
        };
        models = {
          "qwen2.5-coder:14b" = {
            name = "Qwen2.5-Coder 14B";
            limit = {
              context = 32768;
              output = 8192;
            };
          };
          "qwen2.5-coder:7b" = {
            name = "Qwen2.5-Coder 7B";
            limit = {
              context = 32768;
              output = 4096;
            };
          };
        };
      };
    };
  };

  subagentFiles = lib.mapAttrs' (
    name: agentConfig:
    lib.nameValuePair "opencode/agent/${name}.md" {
      text = llmLib.instructions.formatSubagentAsMarkdown {
        inherit name;
        config = agentConfig;
      };
    }
  ) llmLib.instructions.subagentDefs;

  # opencode.json must be a mutable file (not a Nix-store symlink) so OpenCode
  # can write plugin installation state back on first startup.  Deep-merge on
  # every activation: Nix wins for all declared keys; runtime-written keys not
  # in the Nix config (e.g., accepted telemetry prompts) are preserved from the
  # existing file.  Plugin arrays are replaced wholesale — Nix is authoritative
  # on which plugins are declared.
  opencodeConfigFile = pkgs.writeText "opencode-base.json" (builtins.toJSON opencodeConfig);

  updateOpencodeConfig = pkgs.writeShellScript "update-opencode-config" ''
    set -euo pipefail
    target="$HOME/.config/opencode/opencode.json"
    mkdir -p "$(dirname "$target")"

    if [ -L "$target" ]; then
      rm -f "$target"
    fi

    tmp="$(mktemp "$target.tmp.XXXXXX")"
    trap 'rm -f "$tmp"' EXIT

    if [ -f "$target" ]; then
      ${pkgs.jq}/bin/jq -s '.[1] as $managed | .[0] * $managed | .mcp = $managed.mcp' "$target" ${opencodeConfigFile} > "$tmp"
    else
      cp ${opencodeConfigFile} "$tmp"
    fi
    mv "$tmp" "$target"
    chmod u+w "$target"
  '';
in
{
  home.activation.opencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${updateOpencodeConfig}
  '';

  xdg.configFile = lib.mkMerge [
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
