# The schema-relevant shape of OpenCode's two config files, in one place.
#
# `./default.nix` merges the host-dependent parts (MCP servers, which need
# `config.sysinit.llm.mcp`) onto `main` and writes both files. The flake check
{ pkgs, lib }:
let
  llmLib = import ../../lib { inherit lib; };

  # merge preserves whatever is already on disk, so undeclaring a key is a no-op
  # against the running harness unless it is deleted first.
  #
  # Each name is quoted in the rendered jq program, so a key like `$schema` or
  retiredMain = [
    "theme"
    "keybinds"
    "tui"
  ];

  retiredTui = [ ];

  # Blocks this repository owns outright. A deep merge would leave a stale entry
  # behind at any depth, for example a `provider.ollama` that Nix stopped
  # declaring, so these are replaced wholesale rather than merged. A top-level
  # `del` list cannot express that: it only reaches depth one.
  authoritative = [
    "mcp"
    "provider"
    "permission"
    "lsp"
    "formatter"
    "plugin"
    "instructions"
  ];

  # One jq program, rendered once and used by both the activation script and the
  # flake check. Two hand-copies of this pipeline agreed today and would drift on
  # the next edit, which is the defect this attribute exists to prevent.
  #
  mergeProgram =
    retired:
    let
      dels = lib.concatMapStringsSep " | " (k: ''del(."${k}")'') retired;
      strip = if retired == [ ] then "." else dels;
      repl = lib.concatMapStringsSep "\n        | " (
        k: ''if ($managed|has("${k}")) then ."${k}" = $managed."${k}" else . end''
      ) authoritative;
    in
    ''
      .[1] as $managed
            | (.[0] | ${strip})
            | (. * $managed)
            | ${repl}'';
in
{
  inherit
    retiredMain
    retiredTui
    authoritative
    mergeProgram
    ;

  # The two lists above, in the shape `sysinit.llm.managedFiles` consumes.
  # `retire` applies on every activation: a key that was never declared is absent
  # from the base, and the merge preserves a base-absent key by design.
  # `enforce` applies on every activation, which is what `authoritative` always
  # meant: these blocks are this repository's, not OpenCode's.
  retire = retiredMain;
  enforce = authoritative;

  # OpenCode's config schema carries an absolute `$ref` to
  # https://models.dev/model-schema.json. A hermetic build has no network and no
  # writable HOME, so any validator that follows it fails with an unretrievable
  # reference rather than a schema violation.
  schemas = pkgs.runCommand "opencode-schemas-local" { nativeBuildInputs = [ pkgs.jq ]; } ''
    mkdir -p "$out"
    for f in config tui; do
      jq 'walk(
            if type == "object" and has("$ref") and (.["$ref"] | startswith("http"))
            then {}
            else .
            end
          )' "${pkgs.opencode}/share/opencode/$f.json" > "$out/$f.json"
    done

    jq -e '.["$defs"].Config.additionalProperties == false' "$out/config.json" > /dev/null \
      || { echo "opencode schema localization lost Config.additionalProperties" >&2; exit 1; }
    jq -e '.additionalProperties == false' "$out/tui.json" > /dev/null \
      || { echo "opencode schema localization lost the tui additionalProperties" >&2; exit 1; }
  '';

  # Everything OpenCode reads from `~/.config/opencode/opencode.json` except the
  # MCP block, which `./default.nix` adds from the host's server registry.
  main = {
    "$schema" = "https://opencode.ai/config.json";
    autoupdate = false;
    share = "disabled";

    # Two-tier split on the Codex models the ChatGPT subscription already pays
    # for: gpt-5.5 is OpenAI's recommended Codex default, gpt-5.4-mini handles
    # cheap summarization/title work. Can be overridden to a local Ollama model
    # at startup with --model ollama/qwen2.5-coder:7b.
    model = "openai/gpt-5.5";
    small_model = "openai/gpt-5.4-mini";

    # No `shell`. This pinned zsh to match CLAUDE_CODE_SHELL and codex's
    # shell_environment_policy.set.SHELL; all three are now unset, because the
    # owner hit problems with agents running through a zsh profile. Whatever
    # stdout that profile produces contaminates a captured tool result.

    # `build` is OpenCode's own default primary agent. Naming it makes the
    # choice visible next to the four subagent definitions this module writes.
    default_agent = "build";
    # A subagent may not launch a subagent. Matches codex's agents.max_depth = 1.
    subagent_depth = 1;

    compaction = {
      auto = true;
      # Drop stale tool output rather than carrying it through a summary.
      prune = true;
    };

    # Long command output goes to the truncation directory instead of the
    # context window. The defaults are 2000 lines and 51200 bytes; a nix build
    # log clears both, so tighten the line cap and keep the byte cap.
    tool_output = {
      max_lines = 1000;
      max_bytes = 51200;
    };

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

  # Everything OpenCode reads from `~/.config/opencode/tui.json`.
  tui = {
    "$schema" = "https://opencode.ai/tui.json";
    theme = "system";
    keybinds = {
      leader = "ctrl+a";
    };
    scroll_acceleration = {
      enabled = true;
    };

    # OpenCode's own toast is off; the plugin at
    # `./plugins/sysinit-notify.ts` forwards session.idle and
    # session.error into agent-notify instead, so one producer announces every
    # harness. The sound stays on: it is a local cue, not a second toast.
    attention = {
      notifications = false;
      sound = true;
    };
  };
}
