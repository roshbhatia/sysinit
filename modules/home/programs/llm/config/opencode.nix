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

  # The schemas ship inside the installed derivation, so a version bump moves
  # the binary and its schema together and a key move fails validation on the
  # bump itself. Do not vendor a copy: it would need its own drift check.
  schemaDir = "${render.schemas}";

  # Skills install only to ~/.claude/skills (per default.nix); opencode reads
  # that tree natively. Point instructions at the populated root, not a phantom
  # per-tool dir that holds no SKILL.md files.
  defaultInstructions =
    kit.mkInstructions {
      harness = "opencode";
      skillsRoot = "~/.claude/skills";
    }
    + ''

      ## OpenCode-specific Slack access

      OpenCode's MCP client does not support Slack's dynamic auth flow. If you
      need Slack context or need to send a Slack message, ask Claude Code to do
      it with `claude -p '<your Slack task>'` because Claude has Slack MCP
      access configured.
    ''
    + "\n## Output Style\n\n"
    + kit.llmLib.instructions.outputStyleRules;

  render = import ./opencode-render.nix { inherit pkgs lib; };

  opencodeConfig = render.main // {
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
      # ChatGPT-subscription Codex models, reached through the
      # opencode-openai-codex-auth plugin declared above. The plugin's own
      # presets still name gpt-5.1/gpt-5.2 Codex variants, which OpenAI removed
      # from the ChatGPT sign-in path on 2026-04-14, so the models are declared
      # here instead of relying on the shipped list.
      openai = {
        options = {
          reasoningEffort = "medium";
          reasoningSummary = "auto";
          textVerbosity = "medium";
          include = [ "reasoning.encrypted_content" ];
          store = false;
        };
        models = {
          "gpt-5.5" = {
            name = "GPT-5.5 (ChatGPT)";
          };
          "gpt-5.3-codex" = {
            name = "GPT-5.3 Codex (ChatGPT)";
          };
          "gpt-5.4-mini" = {
            name = "GPT-5.4 Mini (ChatGPT)";
            options = {
              reasoningEffort = "low";
            };
          };
        };
      };

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
        harness = "opencode";
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

  # OpenCode 1.18 moved the terminal-interface settings into their own file and
  # made opencode.json reject unknown keys (`additionalProperties: false` on the
  # Config definition). Writing them into the main file made OpenCode migrate
  # them out on every start and leave a .tui-migration.bak behind each time.
  opencodeTuiFile = pkgs.writeText "opencode-tui-base.json" (builtins.toJSON render.tui);

  # Keys this module used to declare and no longer does. The activation merge is
  # a deep merge, so undeclaring a key leaves it on disk forever; only an
  # explicit delete removes it. Every entry here is a key OpenCode would reject
  # or re-migrate if it stayed in the main file.
  retiredMainKeys = [
    "theme"
    "keybinds"
    "tui"
  ];

  retiredMainFilter = lib.concatMapStringsSep ", " (k: ".${k}") retiredMainKeys;

  updateOpencodeConfig = pkgs.writeShellScript "update-opencode-config" ''
    set -euo pipefail
    target="$HOME/.config/opencode/opencode.json"
    tui="$HOME/.config/opencode/tui.json"
    mkdir -p "$(dirname "$target")"

    for f in "$target" "$tui"; do
      if [ -L "$f" ]; then
        rm -f "$f"
      fi
    done

    tmp="$(mktemp "$target.tmp.XXXXXX")"
    tui_tmp="$(mktemp "$tui.tmp.XXXXXX")"
    trap 'rm -f "$tmp" "$tui_tmp"' EXIT

    if [ -f "$target" ]; then
      # Delete the retired keys BEFORE merging. A deep merge preserves any key
      # present in the live file, so dropping them from the Nix side alone is a
      # no-op against the running harness.
      ${pkgs.jq}/bin/jq 'del(${retiredMainFilter})' "$target" > "$tmp.stripped"
      ${pkgs.jq}/bin/jq -s '.[1] as $managed | (.[0] * $managed) | if ($managed|has("mcp")) then .mcp = $managed.mcp else . end' "$tmp.stripped" ${opencodeConfigFile} > "$tmp"
      rm -f "$tmp.stripped"
    else
      cp ${opencodeConfigFile} "$tmp"
    fi

    if [ -f "$tui" ]; then
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$tui" ${opencodeTuiFile} > "$tui_tmp"
    else
      cp ${opencodeTuiFile} "$tui_tmp"
    fi

    # Validate what OpenCode will actually read, not just the Nix base. A build
    # check cannot see this file: it is hermetic and this path is in $HOME.
    for pair in "$tmp:${schemaDir}/config.json" "$tui_tmp:${schemaDir}/tui.json"; do
      f="''${pair%%:*}"
      s="''${pair##*:}"
      if ! ${pkgs.check-jsonschema}/bin/check-jsonschema --schemafile "$s" "$f" > /dev/null 2>&1; then
        echo "opencode: merged config failed schema validation against $s" >&2
        ${pkgs.check-jsonschema}/bin/check-jsonschema --schemafile "$s" "$f" >&2 || true
        exit 1
      fi
    done

    mv "$tmp" "$target"
    mv "$tui_tmp" "$tui"
    chmod u+w "$target" "$tui"
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
