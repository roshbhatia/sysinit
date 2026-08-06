_final: prev: {
  # tmux control mode: wezterm terminates its `send-keys` command with CR, but
  # tmux reads control commands with EVBUFFER_EOL_LF. tmux 3.5a masked the
  # framing error via PTY CR-to-LF handling; 3.7b (what programs.tmux pins) does
  # not, so every `tmux -CC` pane stalls on the first keystroke. Upstream fixed
  # it in 2bd22e73 on 2026-08-04, which is newer than nixpkgs' pinned
  # 0-unstable-2026-07-16 snapshot. Patch rather than override src so cargoHash
  # and the passthru terminfo derivation stay valid. Drop this once nixpkgs
  # carries a wezterm snapshot >= 2026-08-05.
  # https://github.com/wezterm/wezterm/issues/8001
  #
  # The second patch teaches control mode to adopt panes tmux created on its
  # own. Claude Code's teammate backend spawns each teammate with
  # `tmux split-window -d`, and `-d` suppresses `%window-pane-changed`, so
  # `%layout-change` is the only notice wezterm gets. That path queued
  # `ListAllPanes { prune: true }`, which could only ever remove panes, so
  # teammates ran invisibly. Not yet upstream; carried until #6828 is fixed.
  # https://github.com/wezterm/wezterm/issues/6828
  wezterm = prev.wezterm.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./patches/wezterm-tmux-adopt-splits.patch ];
    postPatch = (old.postPatch or "") + ''
      substituteInPlace mux/src/tmux_commands.rs \
        --replace-fail 'send-keys -H -t %{} {}\r' 'send-keys -H -t %{} {}\n'
    '';
  });
}
