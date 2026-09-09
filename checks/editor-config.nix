{ pkgs }:
let
  inherit (pkgs) lib;
  remoteHosts = import ../modules/home/programs/wezterm/remote-hosts.nix { inherit lib; };
  tetherConfig = pkgs.writeText "tether-config.json" (builtins.toJSON remoteHosts.tetherConfig);
  # The roster.catalog/v1 files `roster refresh` wrote on 2026-09-08: the
  # seshy catalog from the real adapter over this Mac's sessions, trimmed to
  # two rows with $HOME replaced, and the remote-seshy catalog from the adapter
  # with ssh and tether stubbed as roster-sources.nix stubs them. Rendered as
  # lua tables so the headless test needs no JSON parser.
  rosterCatalogs = pkgs.runCommand "roster-catalog-fixtures" { } ''
    mkdir -p "$out"
    ${lib.concatMapStringsSep "\n"
      (
        source:
        "cp ${
          pkgs.writeText "roster-${source}.lua" (
            "return "
            + lib.generators.toLua { } (
              builtins.fromJSON (builtins.readFile (./fixtures/roster + "/${source}.json"))
            )
          )
        } \"$out/${source}.lua\""
      )
      [
        "seshy"
        "remote-seshy"
      ]
    }
  '';
  weztermLua = ../modules/home/programs/wezterm/lua;
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
    export SYSINIT_NVIM_CONFIG=${../modules/home/programs/neovim/config}
    export SYSINIT_NVIM_DIFFVIEW=${pkgs.vimPlugins.diffview-nvim}
    nvim --headless --clean -u NONE \
      --cmd 'set runtimepath^=${pkgs.vimPlugins.plenary-nvim}' \
      -c 'runtime plugin/plenary.vim' \
      -c "PlenaryBustedDirectory ${./neovim} { minimal_init = '${./neovim.lua}', sequential = true }"
    lua ${./wezterm.lua} \
      ${weztermLua} \
      ${./fixtures/wezterm-plugin} \
      ${rosterCatalogs}
    # The session tree names one tool, roster, and reads its catalogs. A session
    # manager, a hop negotiator, a multiplexer, or one of the deleted cachers
    # named in the lua is a second decider the catalog never sees. Spelled as
    # an if: under set -e a failing `! grep` is ignored, so that form cannot
    # fail.
    if grep -rEn \
      -e '\<sy\>' \
      -e tether \
      -e zmx \
      -e mosh \
      -e seshy-remote-list \
      -e tether-refresh \
      ${weztermLua}; then
      echo "the wezterm lua tree names a tool other than roster" >&2
      exit 1
    fi
    # The rendered tether config is tether.config/v1: mode and flaky present,
    # one entry per host in the map, and only the keys the schema allows.
    jq -e --argjson hosts '${builtins.toJSON (builtins.attrNames remoteHosts.hosts)}' '
      (.mode | IN("auto", "native", "roam", "persist"))
      and (.flaky.rtt_ms | type == "number")
      and (.flaky.loss | type == "number")
      and ((.hosts | keys) == $hosts)
      and ([.hosts[] | keys[]] - ["pin", "mode"] == [])
      and ([.hosts[] | .pin // "native-mux"] | all(IN("native-mux", "mosh-mux", "ssh-raw", "ssh")))
    ' ${tetherConfig} > /dev/null
    lua ${./hammerspoon.lua} \
      ${../modules/darwin/home/hammerspoon}
    node ${./launcher-actions.mjs} \
      ${../modules/darwin/home/hammerspoon/lua/sysinit/plugins/ui/launcher/page/actions.js} \
      ${../modules/darwin/home/hammerspoon/lua/sysinit/plugins/ui/launcher/page/panel.html}
    export XDG_CONFIG_HOME="$TMPDIR/config"
    mkdir -p "$XDG_CONFIG_HOME/wezterm"
    cp ${./fixtures/wezterm/config.json} "$XDG_CONFIG_HOME/wezterm/config.json"
    cp ${./fixtures/wezterm/env.json} "$XDG_CONFIG_HOME/wezterm/env.json"
    SYSINIT_WEZTERM_LUA=${weztermLua} \
      wezterm --config-file ${./wezterm-entry.lua} show-keys --lua \
      > "$TMPDIR/wezterm-keys.lua"
    grep -Fq "{ key = 'h', mods = 'CTRL'" "$TMPDIR/wezterm-keys.lua"
    grep -Fq "{ key = 'phys:1', mods = 'SHIFT|SUPER'" "$TMPDIR/wezterm-keys.lua"
    test "$(grep -c '^    { key =' "$TMPDIR/wezterm-keys.lua")" -ge 80
    touch "$out"
  ''
