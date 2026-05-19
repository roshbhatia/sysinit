{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  codingToolsets = [
    "terminal"
    "file"
    "skills"
    "memory"
    "delegation"
    "web"
  ];

  codingSystemPrompt = kit.mkInstructions "~/.claude/skills";

  stylixSkin =
    let
      c = config.lib.stylix.colors;
      hex = name: "#${c.${name}}";
    in
    {
      name = "stylix";
      description = "Mirrors the active stylix base16 palette";
      colors = {
        banner_border = hex "base0D";
        banner_title = hex "base0E";
        banner_accent = hex "base0C";
        banner_dim = hex "base03";
        banner_text = hex "base05";

        ui_accent = hex "base0D";
        ui_label = hex "base04";
        ui_ok = hex "base0B";
        ui_error = hex "base08";
        ui_warn = hex "base0A";

        prompt = hex "base0D";
        input_rule = hex "base02";
        response_border = hex "base02";

        session_label = hex "base04";
        session_border = hex "base02";

        status_bar_bg = hex "base01";
        voice_status_bg = hex "base01";
        selection_bg = hex "base02";

        completion_menu_bg = hex "base01";
        completion_menu_current_bg = hex "base02";
        completion_menu_meta_bg = hex "base01";
        completion_menu_meta_current_bg = hex "base02";
      };
    };

  hermesBase = {
    platform_toolsets = {
      cli = codingToolsets;
    };

    agent = {
      max_turns = 90;
      verbose = false;
      system_prompt = codingSystemPrompt;
    };

    compression = {
      enabled = true;
      threshold = 0.50;
    };

    display = {
      compact = false;
      streaming = true;
      show_reasoning = false;
      persistent_output = true;
      skin = "stylix";
    };

    delegation = {
      max_iterations = 45;
    };

    tui_auto_resume_recent = false;

    mcp_servers = llmLib.mcp.formatForHermes kit.mcpServers.servers;
  };

  hermesConfigBase = pkgs.writeText "hermes-config-base.yaml" (builtins.toJSON hermesBase);

  updateHermesConfig = pkgs.writeShellScript "update-hermes-config" ''
    set -euo pipefail

    target="$HOME/.hermes/config.yaml"
    target_dir="$(dirname "$target")"
    mkdir -p "$target_dir"

    if [ -L "$target" ]; then
      rm -f "$target"
    fi

    merged="$(mktemp "''${target}.tmp.XXXXXX")"
    trap 'rm -f "$merged"' EXIT

    if [ -f "$target" ]; then
      ${pkgs.yq-go}/bin/yq eval-all \
        '. as $item ireduce ({}; . * $item)' \
        "$target" ${hermesConfigBase} > "$merged"
    else
      cp ${hermesConfigBase} "$merged"
    fi

    mv "$merged" "$target"
    chmod u+w "$target"
  '';
in
{
  home = {
    packages = [ pkgs.hermes-agent ];

    sessionVariables = {
      HERMES_TUI = "1";
    };

    activation.hermesConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${updateHermesConfig}
    '';

    file = kit.skillsLib.installHermesSkillsTo ".hermes/skills" // {
      ".hermes/skins/stylix.yaml" = {
        text = builtins.toJSON stylixSkin;
        force = true;
      };
    };
  };
}
