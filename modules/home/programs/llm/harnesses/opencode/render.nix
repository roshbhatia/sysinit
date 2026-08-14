{ pkgs, lib }:
let
  llmLib = import ../../lib { inherit lib; };

  retiredMain = [
    "theme"
    "keybinds"
    "tui"
  ];

  retiredTui = [ ];

  authoritative = [
    "mcp"
    "provider"
    "permission"
    "lsp"
    "formatter"
    "plugin"
    "instructions"
  ];

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

  retire = retiredMain;
  enforce = authoritative;

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

  main = {
    "$schema" = "https://opencode.ai/config.json";
    autoupdate = false;
    share = "disabled";

    model = "openai/gpt-5.5";
    small_model = "openai/gpt-5.4-mini";

    default_agent = "build";
    subagent_depth = 1;

    compaction = {
      auto = true;
      prune = true;
    };

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
      bash = {
        "*" = "allow";
      }
      // (llmLib.allowlist.formatDestructiveForOpencode llmLib.allowlist.destructiveDenyGlobs);
      skill = {
        "*" = "allow";
      };
    };

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
      "opencode-claude-memory"
      "opencode-plugin-openspec"

      "opencode-openai-codex-auth"
      "opencode-pty"
      "opencode-vibeguard"
      "@franlol/opencode-md-table-formatter"
    ];

    provider = {
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
          "muse-glimmer:30b-mlx" = {
            name = "Muse Glimmer 30B (MLX)";
            limit = {
              context = 65536;
              output = 8192;
            };
          };
          "qwen3.5:35b-a3b-coding-nvfp4" = {
            name = "Qwen3.5 35B A3B Coding";
            limit = {
              context = 65536;
              output = 8192;
            };
          };
          "gemma4:12b-mlx" = {
            name = "Gemma4 12B (MLX)";
            limit = {
              context = 65536;
              output = 4096;
            };
          };
        };
      };
    };
  };

  tui = {
    "$schema" = "https://opencode.ai/tui.json";
    theme = "system";
    keybinds = {
      leader = "ctrl+a";
    };
    scroll_acceleration = {
      enabled = true;
    };

    attention = {
      notifications = false;
      sound = true;
    };
  };
}
