{
  config,
  lib,
  pkgs,
  ...
}:
let
  themeLib = import ../../../shared/theme-colors.nix { inherit lib; };
  c = themeLib.colorsOf config;
  tmuxClient = pkgs.writeShellApplication {
    name = "tmux-client";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.tmux
    ];
    text = ''
      session="''${SYSINIT_TMUX_SESSION:-main}"
      case "$session" in
        ""|-*|*:*|*$'\n'*|*$'\r'*)
          printf 'tmux-client: invalid session name %q\n' "$session" >&2
          exit 2
          ;;
      esac
      if [ -n "''${WEZTERM_PANE:-}" ]; then
        value=$(printf '%s' "$session" | base64 | tr -d '\n')
        printf '\033]1337;SetUserVar=SYSINIT_TMUX_SESSION=%s\007' "$value"
      fi
      exec tmux new-session -A -s "$session" -c "$PWD"
    '';
  };
  tmuxLifecycle = pkgs.writeShellApplication {
    name = "tmux-lifecycle";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.tmux
    ];
    text = ''
      if [ "$#" -ne 3 ] || [ "$1" != detached ]; then
        printf 'tmux-lifecycle: usage: tmux-lifecycle detached <session-id> <client-termname>\n' >&2
        exit 2
      fi
      session=$2
      case "$3" in
        wezterm*) ;;
        *) exit 0 ;;
      esac
      tmux has-session -t "$session" 2>/dev/null || exit 0
      manual=$(tmux show-option -qv -t "$session" @sysinit_manual_detach 2>/dev/null || true)
      if [ "$manual" = 1 ]; then
        tmux set-option -u -t "$session" @sysinit_manual_detach
        exit 0
      fi
      clients=$(tmux list-clients -t "$session" -F '#{client_pid}' | wc -l | tr -d ' ')
      if [ "$clients" = 0 ]; then
        tmux kill-session -t "$session"
      fi
    '';
  };
  shell = lib.escapeShellArgs [
    (lib.getExe pkgs.nushell)
    "--config"
    "${config.xdg.configHome}/nushell/config.nu"
    "--env-config"
    "${config.xdg.configHome}/nushell/env.nu"
    "--plugin-config"
    "${config.xdg.configHome}/nushell/plugin.msgpackz"
  ];
  providers = map (provider: {
    inherit (provider) name key manifest;
  }) config.programs.sysinit-wezterm.settings.picker.providers;
  sessionChips = pkgs.writeShellApplication {
    name = "tmux-status-left";
    runtimeInputs = [
      pkgs.jq
      pkgs.sysinit-utils
    ];
    text = ''
      payload=$(agent-sessions) || exit 0
      printf '%s' "$payload" | jq -r --arg selected "$(printf '%s' "$payload" | jq -r '.selected // empty')" '
        def safe_name: gsub("#"; "##") | gsub("[\\r\\n]"; " ");
        def icon: if .status == "waiting" or .status == "blocked" then "⏱"
          elif .status == "done" then "✔"
          elif .status == "working" then "⟳"
          else "·" end;
        def color: if .status == "waiting" or .status == "blocked" then "#${c.base08}"
          elif .status == "done" then "#${c.base0B}"
          elif .status == "working" then "#${c.base0D}"
          else "#${c.base04}" end;
        [.sessions[:6][] |
          (if .name == $selected then "#[fg=#${c.base05},bg=#${c.base02},bold] "
            else "#[fg=" + color + "] " end)
          + "[" + (.name | safe_name | .[0:16]) + "] " + icon + "#[default]
        ] | join("")
      '
    '';
  };
in
{
  home.sessionVariables.TMUX_TMPDIR = lib.mkForce "/tmp";

  programs.tmux = {
    enable = true;
    package = pkgs.tmux;
    terminal = "tmux-256color";
    keyMode = "vi";
    escapeTime = 10;
    historyLimit = 50000;
    extraConfig = ''
      set -g default-shell ${lib.escapeShellArg (lib.getExe pkgs.zsh)}
      set -g default-command ${lib.escapeShellArg shell}
      set -g focus-events on
      set -g mouse on
      set -g set-clipboard on
      set -g allow-passthrough on
      set -g renumber-windows on
      set -g automatic-rename on
      set -g detach-on-destroy off
      set -g window-size largest
      set -g status-position top
      set -g status-interval 1
      set -g status-style 'bg=#${c.base01},fg=#${c.base05}'
      set -g status-left-length 220
      set -g status-right-length 80
      set -g status-left '#(tmux-status-left) #[fg=#${c.base0D},bold] #S #[default]| '
      set -g status-right '#[fg=#${c.base04}]#{window_index}:#{window_name}  #{pane_current_path} '
      setw -g window-status-format ' #[fg=#${c.base04}]#I:#W '
      setw -g window-status-current-format ' #[fg=#${c.base05},bg=#${c.base02},bold]#I:#W#[default] '
      set -g pane-border-style 'fg=#${c.base02}'
      set -g pane-active-border-style 'fg=#${c.base0D}'
      set -as terminal-features ',wezterm*:RGB,wezterm*:sixel'
      set -g set-titles on
      set -g set-titles-string '#S'

      bind-key s display-popup -E -w 92% -h 86% 'ty picker'
      bind-key d set-option -t '#{session_name}' @sysinit_manual_detach 1 \; detach-client
      bind-key c new-window -c '#{pane_current_path}'
      bind-key '-' split-window -v -c '#{pane_current_path}'
      bind-key '|' split-window -h -c '#{pane_current_path}'
      bind-key x kill-pane
      bind-key X kill-window
      bind-key r command-prompt -I '#{window_name}' 'rename-window %%'
      bind-key R command-prompt -I '#{session_name}' 'rename-session %%'
      set-hook -g client-detached 'run-shell "tmux-lifecycle detached #{session_id} #{client_termname}"'
      set-hook -g client-attached 'set-option -u -t "#{session_id}" @sysinit_manual_detach'
    '';
  };

  xdg.configFile."sysinit/tmux-providers.json".text = builtins.toJSON {
    version = "sysinit.tmux-providers/v1";
    inherit providers;
  };

  home.packages = [
    tmuxClient
    tmuxLifecycle
    sessionChips
  ];
}
