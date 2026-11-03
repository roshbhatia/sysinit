{
  config,
  pkgs,
}:
let
  luaSource = pkgs.sysinit-wezterm-lua;
  plugins = import (pkgs.sysinit-wezterm-source + "/plugins.nix") { inherit pkgs; };
  settings = pkgs.writeText "tmux-native-presentation-settings.json" (
    builtins.toJSON config.programs.sysinit-wezterm.resolvedSettings
  );
  assets =
    pkgs.runCommand "tmux-native-presentation-assets.json"
      {
        nativeBuildInputs = [
          pkgs.wezterm
          pkgs.jq
        ];
      }
      ''
        export HOME="$TMPDIR/home" XDG_CONFIG_HOME="$TMPDIR/config" XDG_STATE_HOME="$TMPDIR/state"
        mkdir -p "$HOME" "$XDG_CONFIG_HOME/wezterm" "$XDG_STATE_HOME"
        cp ${settings} "$XDG_CONFIG_HOME/wezterm/config.json"
        echo '{}' > "$XDG_CONFIG_HOME/wezterm/env.json"
        SYSINIT_WEZTERM_LUA=${luaSource} TMUX_PRESENTATION_ASSETS="$out" \
          wezterm --config-file ${./presentation-assets.lua} show-keys --lua > /dev/null
        jq -e '.processes.nvim.icon and .nerdfonts.md_loading and .tabs.active.bg and .mode_icons.locked and .theme.normal_mode.a.bg and .theme.tab.active.bg and .tab_sections.active[1]' "$out" > /dev/null
      '';
  agents = pkgs.writeText "tmux-presentation-agents.json" (
    builtins.toJSON (import ../llm/harnesses/deck-patterns.nix)
  );
  lua = pkgs.lua5_4.withPackages (ps: [ ps.dkjson ]);
in
{
  inherit assets;
  command = [
    "${lua}/bin/lua"
    "${./presentation.lua}"
    (toString luaSource)
    (toString assets)
    (toString plugins.agent-deck)
    (toString agents)
    "${../llm/runtime/tmux-status.lua}"
  ];
}
