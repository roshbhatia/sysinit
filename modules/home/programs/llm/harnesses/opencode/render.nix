{ pkgs, lib }:
let
  llmLib = import ../../lib { inherit lib; };

  retiredMain = [
    "theme"
    "keybinds"
    "tui"
    "subagent_depth"
    "lsp"
    "autoupdate"
    "provider"
    "permission"
    "plugin"
    "small_model"
    "share"
  ];

  retiredTui = [ ];

  authoritative = [
    "mcp"
    "providers"
    "permissions"
    "formatter"
    "plugins"
    "skills"
    "instructions"
    "experimental"
    "compaction"
    "agents"
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

  permissionRule = action: resource: effect: {
    inherit action resource effect;
  };
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
    for f in config cli; do
      jq 'walk(
            if type == "object" and has("$ref") and (.["$ref"] | startswith("http"))
            then {}
            else .
            end
          )' "${pkgs.opencode}/share/$f.json" > "$out/$f.json"
    done

    jq -e '.["$defs"].Config.additionalProperties == false' "$out/config.json" > /dev/null \
      || { echo "opencode schema localization lost Config.additionalProperties" >&2; exit 1; }
    jq -e '.additionalProperties == false' "$out/cli.json" > /dev/null \
      || { echo "opencode schema localization lost the cli additionalProperties" >&2; exit 1; }
  '';

  main = {
    "$schema" = "https://opencode.ai/config.json";
    update = "disable";
    experimental = {
      portable_shell_scanner = true;
    };

    model = "openai/gpt-5.5";

    default_agent = "build";

    compaction = {
      auto = true;
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

    skills = [ "~/.claude/skills" ];

    permissions = [
      (permissionRule "*" "*" "allow")
    ]
    ++ map (cmd: permissionRule "shell" cmd "deny") llmLib.allowlist.destructiveDenyGlobs;

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

    plugins = [ "./plugins/sysinit-edits.js" ];

    providers = {
      openai = {
        settings = {
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
            settings = {
              reasoningEffort = "low";
            };
          };
        };
      };

      ollama = {
        name = "Ollama (local)";
        settings = {
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
    "$schema" = "https://opencode.ai/v2/cli.json";
    theme = {
      name = "system";
      mode = "system";
    };
    keybinds = {
      leader = "ctrl+a";
    };
    leader.timeout = 2000;
    mouse = true;
    scroll.acceleration = true;
    prompt = {
      editor = true;
      paste = "compact";
      image_preview = true;
    };
    session = {
      sidebar = "auto";
      scrollbar = true;
      thinking = "hide";
      grouping = "auto";
      image_preview = true;
      tps = true;
      markdown = "rendered";
      new_location = "inherit";
      permissions = "autoaccept";
    };
    tabs = {
      mode = "auto";
      scope = "cwd";
      layout = "horizontal";
      indicators = "status";
    };
    diffs = {
      source = "branch";
      wrap = "word";
      tree = true;
      single = false;
      view = "auto";
    };
    terminal = {
      title = true;
      copy = "select";
    };
    mini = {
      thinking = "hide";
      tools = "show";
      shell_output = "show";
      turn_summary = "show";
      footer = "show";
      splash = "show";
      work_spinner = "block-soft-slide";
      mono = false;
      replay = true;
      replay_limit = 200;
    };
    plugins = [ "./sysinit-notify.js" ];

    attention = {
      notifications = false;
      sound = true;
    };
  };
}
