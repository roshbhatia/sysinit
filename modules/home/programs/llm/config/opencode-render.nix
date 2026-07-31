# The schema-relevant shape of OpenCode's two config files, in one place.
#
# `config/opencode.nix` merges the host-dependent parts (MCP servers, which need
# `config.sysinit.llm.mcp`) onto `main` and writes both files. The flake check
# `opencode-config-schema` imports this same attrset and validates it against
# the schemas the installed OpenCode derivation ships.
#
# Two consumers, one definition: a check that validated its own copy of the
# config would pass while the file OpenCode reads drifted away from it.
#
# The split between the two files is not cosmetic. OpenCode 1.18 moved the
# terminal-interface settings out of `opencode.json` into `tui.json` and set
# `additionalProperties: false` on the Config definition, so a TUI key left in
# the main file is rejected. See `retiredMainKeys` in `opencode.nix` for the
# deletion that removes them from a live file.
{ pkgs, lib }:
{
  # OpenCode's config schema carries an absolute `$ref` to
  # https://models.dev/model-schema.json. A hermetic build has no network and no
  # writable HOME, so any validator that follows it fails with an unretrievable
  # reference rather than a schema violation.
  #
  # Replace every absolute http(s) `$ref` with an empty schema, which accepts
  # anything. Internal `#/$defs/...` references are untouched, so every rule
  # this repository actually cares about still applies: `additionalProperties:
  # false` on Config is what catches a key in the wrong file.
  #
  # The trade is explicit: model identifiers are not validated against
  # models.dev. That check belongs to OpenCode at runtime, not to a build that
  # must stay offline.
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
  '';

  # Everything OpenCode reads from `~/.config/opencode/opencode.json` except the
  # MCP block, which `opencode.nix` adds from the host's server registry.
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

    # Pin the shell rather than inheriting whatever login shell the GUI hands
    # the process, matching CLAUDE_CODE_SHELL in claude.nix and
    # shell_environment_policy.set.SHELL in codex.nix.
    shell = "${lib.getExe pkgs.zsh}";

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
  };
}
