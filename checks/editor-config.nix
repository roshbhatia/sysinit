{ pkgs }:
pkgs.runCommand "editor-config-check"
  {
    nativeBuildInputs = [
      pkgs.git
      pkgs.lua5_4
      pkgs.neovim
      pkgs.nodejs_22
      pkgs.wezterm
    ];
  }
  ''
    export XDG_STATE_HOME="$TMPDIR/state"
    mkdir -p "$XDG_STATE_HOME"
    nvim --headless --clean -u NONE -l ${./neovim.lua} \
      ${../modules/home/programs/neovim/config}
    lua ${./wezterm.lua} \
      ${../modules/home/programs/wezterm/lua} \
      ${./fixtures/wezterm-plugin}
    lua ${./hammerspoon.lua} \
      ${../modules/darwin/home/hammerspoon}
    node ${./launcher-actions.mjs} \
      ${../modules/darwin/home/hammerspoon/lua/sysinit/plugins/ui/launcher/page/actions.js}
    export XDG_CONFIG_HOME="$TMPDIR/config"
    mkdir -p "$XDG_CONFIG_HOME/wezterm"
    cp ${./fixtures/wezterm/config.json} "$XDG_CONFIG_HOME/wezterm/config.json"
    cp ${./fixtures/wezterm/env.json} "$XDG_CONFIG_HOME/wezterm/env.json"
    SYSINIT_WEZTERM_LUA=${../modules/home/programs/wezterm/lua} \
      wezterm --config-file ${./wezterm-entry.lua} show-keys --lua \
      > "$TMPDIR/wezterm-keys.lua"
    touch "$out"
  ''
