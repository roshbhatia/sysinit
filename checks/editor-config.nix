{ pkgs }:
let
  weztermRoot = pkgs.sysinit-wezterm-source;
  weztermLua = weztermRoot + "/lua";
  nvimRoot = pkgs.sysinit-nvim-source;
in
pkgs.runCommand "editor-config-check"
  {
    nativeBuildInputs = [
      pkgs.git
      pkgs.jq
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
    export SYSINIT_NVIM_CONFIG=${nvimRoot}
    export SYSINIT_NOTES_PLUGIN=${pkgs.agent-notes-nvim}
    export SYSINIT_NVIM_DIFFVIEW=${pkgs.vimPlugins.diffview-nvim}
    nvim --headless --clean -u NONE \
      --cmd 'set runtimepath^=${pkgs.vimPlugins.plenary-nvim}' \
      -c 'runtime plugin/plenary.vim' \
      -c "PlenaryBustedDirectory ${nvimRoot + "/checks/neovim"} { minimal_init = '${
        nvimRoot + "/checks/neovim.lua"
      }', sequential = true }"
    lua ${weztermRoot + "/checks/wezterm.lua"} \
      ${weztermLua} \
      ${weztermRoot + "/checks/fixtures/wezterm-plugin"}
    if grep -rEn -e roster -e tether -e 'refresh_catalogs' ${weztermLua}; then
      echo "WezTerm must not perform catalog discovery or transport negotiation" >&2
      exit 1
    fi
    lua ${./hammerspoon.lua} \
      ${../modules/darwin/home/hammerspoon}
    node ${./launcher-actions.mjs} \
      ${../modules/darwin/home/hammerspoon/lua/sysinit/plugins/ui/launcher/page/actions.js} \
      ${../modules/darwin/home/hammerspoon/lua/sysinit/plugins/ui/launcher/page/panel.html}
    export XDG_CONFIG_HOME="$TMPDIR/config"
    mkdir -p "$XDG_CONFIG_HOME/wezterm"
    cp ${weztermRoot + "/checks/fixtures/wezterm/config.json"} "$XDG_CONFIG_HOME/wezterm/config.json"
    cp ${weztermRoot + "/checks/fixtures/wezterm/env.json"} "$XDG_CONFIG_HOME/wezterm/env.json"
    SYSINIT_WEZTERM_LUA=${weztermLua} \
      wezterm --config-file ${weztermRoot + "/checks/wezterm-entry.lua"} show-keys --lua \
      > "$TMPDIR/wezterm-keys.lua"
    grep -Fq "{ key = 'h', mods = 'CTRL'" "$TMPDIR/wezterm-keys.lua"
    grep -Fq "{ key = 'phys:1', mods = 'SHIFT|SUPER'" "$TMPDIR/wezterm-keys.lua"
    test "$(grep -c '^    { key =' "$TMPDIR/wezterm-keys.lua")" -ge 80
    touch "$out"
  ''
