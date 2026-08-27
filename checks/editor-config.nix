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
    export HOME="$TMPDIR/home"
    export XDG_CACHE_HOME="$TMPDIR/cache"
    export XDG_DATA_HOME="$TMPDIR/data"
    export XDG_STATE_HOME="$TMPDIR/state"
    mkdir -p "$HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"
    export SYSINIT_NVIM_CONFIG=${../modules/home/programs/neovim/config}
    export SYSINIT_NVIM_DIFFVIEW=${pkgs.vimPlugins.diffview-nvim}
    nvim --headless --clean -u NONE \
      --cmd 'set runtimepath^=${pkgs.vimPlugins.plenary-nvim}' \
      -c 'runtime plugin/plenary.vim' \
      -c "PlenaryBustedDirectory ${./neovim} { minimal_init = '${./neovim.lua}', sequential = true }"
    lua ${./wezterm.lua} \
      ${../modules/home/programs/wezterm/lua} \
      ${./fixtures/wezterm-plugin}
    lua ${./hammerspoon.lua} \
      ${../modules/darwin/home/hammerspoon}
    node ${./launcher-actions.mjs} \
      ${../modules/darwin/home/hammerspoon/lua/sysinit/plugins/ui/launcher/page/actions.js} \
      ${../modules/darwin/home/hammerspoon/lua/sysinit/plugins/ui/launcher/page/panel.html}
    export XDG_CONFIG_HOME="$TMPDIR/config"
    mkdir -p "$XDG_CONFIG_HOME/wezterm"
    cp ${./fixtures/wezterm/config.json} "$XDG_CONFIG_HOME/wezterm/config.json"
    cp ${./fixtures/wezterm/env.json} "$XDG_CONFIG_HOME/wezterm/env.json"
    SYSINIT_WEZTERM_LUA=${../modules/home/programs/wezterm/lua} \
      wezterm --config-file ${./wezterm-entry.lua} show-keys --lua \
      > "$TMPDIR/wezterm-keys.lua"
    grep -Fq "{ key = 'h', mods = 'CTRL'" "$TMPDIR/wezterm-keys.lua"
    grep -Fq "{ key = 'phys:1', mods = 'SHIFT|SUPER'" "$TMPDIR/wezterm-keys.lua"
    test "$(grep -c '^    { key =' "$TMPDIR/wezterm-keys.lua")" -ge 80
    touch "$out"
  ''
