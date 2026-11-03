{
  config,
  lib,
  pkgs,
  ...
}:
let
  themeLib = import ../../../shared/theme-colors.nix { inherit lib; };
  c = themeLib.colorsOf config;
  smoothScroll = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "smooth-scroll";
    version = "0-unstable-2d686bc";
    rtpFilePath = "smooth-scroll.tmux";
    src = pkgs.fetchFromGitHub {
      owner = "azorng";
      repo = "tmux-smooth-scroll";
      rev = "2d686bc5b696c0e66173997e5141b14c8bedd973";
      hash = "sha256-+DtK0hMO1TAPYR/0jF12I5mqGOAz8PiMzhvGQDbwm3k=";
    };
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postInstall = ''
      for entry in init scroll; do
        wrapProgram "$out/share/tmux-plugins/smooth-scroll/src/$entry.sh" \
          --prefix PATH : ${
            lib.makeBinPath [
              pkgs.tmux
              pkgs.coreutils
              pkgs.gawk
              pkgs.perl
            ]
          }
      done
    '';
  };
  floatingTerminal = pkgs.writeShellApplication {
    name = "tmux-floating-terminal";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.tmux
    ];
    text = builtins.readFile ./floating-terminal.sh;
  };
  floatingCommand = "run-shell '${lib.getExe floatingTerminal} toggle #{q:socket_path} #{q:session_id} #{q:client_name} #{q:pane_current_path}'";
  lock = "set-option key-table sysinit-locked ; set-option prefix None ; set-option @sysinit_locked 1 ; switch-client -T sysinit-locked";
  unlock = "set-option key-table root ; set-option prefix C-b ; set-option @sysinit_locked 0 ; switch-client -T root";
  action = command: "run-shell '${pkgs.sysinit-utils}/bin/ty tmux ${command} #{pane_id}'";
  spawn =
    kind: local:
    "run-shell '${pkgs.sysinit-utils}/bin/ty tmux spawn #{pane_id} ${kind}${lib.optionalString local " --local"}'";
  menuItem =
    item:
    lib.mapAttrs (
      name: value:
      if name == "menu" then
        map menuItem value
      else if name == "command" then
        builtins.replaceStrings [ "'" ] [ "\"" ] value
      else
        value
    ) item;
  whichKeyConfig = pkgs.writeText "tmux-which-key.json" (
    builtins.toJSON {
      command_alias_start_index = 200;
      custom_variables = [ ];
      macros = [ ];
      keybindings.prefix_table = "Space";
      title = {
        style = "align=centre,bold";
        prefix = "tmux";
        prefix_style = "fg=#${c.base0D},align=centre,bold";
      };
      position = {
        x = "C";
        y = "C";
      };
      items = map menuItem [
        {
          name = "Reload configuration";
          key = "R";
          command = "source-file '${config.xdg.configHome}/tmux/tmux.conf'";
        }
        {
          name = "Floating terminal";
          key = "f";
          command = floatingCommand;
        }
        {
          name = "Sessions and providers";
          key = "s";
          command = "display-popup -E -w 92% -h 86% '${pkgs.sysinit-utils}/bin/ty tmux picker'";
        }
        {
          name = "Panes";
          key = "p";
          menu = [
            {
              name = "Split right on current host";
              key = "v";
              command = spawn "right" false;
            }
            {
              name = "Split down on current host";
              key = "s";
              command = spawn "down" false;
            }
            {
              name = "Split right locally";
              key = "V";
              command = spawn "right" true;
            }
            {
              name = "Split down locally";
              key = "S";
              command = spawn "down" true;
            }
            {
              name = "Choose pane";
              key = "p";
              command = "display-panes -d 0";
            }
            {
              name = "Zoom";
              key = "z";
              command = "resize-pane -Z";
            }
            {
              name = "Rotate";
              key = "o";
              command = "rotate-window";
              transient = true;
            }
            {
              name = "Tiled layout";
              key = "t";
              command = "select-layout tiled";
            }
            {
              name = "Next layout";
              key = "l";
              command = "next-layout";
              transient = true;
            }
            {
              name = "Break into window";
              key = "b";
              command = "break-pane";
            }
            {
              name = "Close pane";
              key = "x";
              command = "confirm-before -p 'Close pane #P? (y/n)' kill-pane";
            }
          ];
        }
        {
          name = "Windows";
          key = "w";
          menu = [
            {
              name = "New on current host";
              key = "c";
              command = spawn "window" false;
            }
            {
              name = "New locally";
              key = "C";
              command = spawn "window" true;
            }
            {
              name = "Choose window";
              key = "w";
              command = "choose-tree -Zw";
            }
            {
              name = "Previous";
              key = "p";
              command = "previous-window";
              transient = true;
            }
            {
              name = "Next";
              key = "n";
              command = "next-window";
              transient = true;
            }
            {
              name = "Last";
              key = "Tab";
              command = "last-window";
            }
            {
              name = "Move left";
              key = "h";
              command = "swap-window -d -t -1";
              transient = true;
            }
            {
              name = "Move right";
              key = "l";
              command = "swap-window -d -t +1";
              transient = true;
            }
            {
              name = "Rename";
              key = "r";
              command = "command-prompt -I '#W' 'rename-window %%'";
            }
            {
              name = "Close";
              key = "x";
              command = "confirm-before -p 'Close window #W? (y/n)' kill-window";
            }
          ];
        }
        {
          name = "Copy, search and history";
          key = "c";
          menu = [
            {
              name = "Copy mode";
              key = "c";
              command = "copy-mode";
            }
            {
              name = "Copy working directory";
              key = "y";
              command = "set-buffer -w '#{pane_current_path}'";
            }
            {
              name = "Search history";
              key = "/";
              command = "copy-mode ; send-keys -X search-backward";
            }
            {
              name = "Quick select paths and identifiers";
              key = "f";
              command = "display-popup -E -w 85% -h 75% '${pkgs.sysinit-utils}/bin/ty tmux select #{pane_id}'";
            }
            {
              name = "Edit scrollback";
              key = "e";
              command = action "scrollback";
            }
            {
              name = "Buffers";
              key = "b";
              command = "choose-buffer -Z";
            }
            {
              name = "Paste";
              key = "p";
              command = "paste-buffer -p";
            }
            {
              name = "Previous prompt";
              key = "[";
              command = "copy-mode ; send-keys -X previous-prompt";
            }
            {
              name = "Next prompt";
              key = "]";
              command = "copy-mode ; send-keys -X next-prompt";
            }
            {
              name = "Clear history";
              key = "k";
              command = "send-keys C-l ; clear-history";
            }
          ];
        }
        {
          name = "Agent tools";
          key = "a";
          menu = [
            {
              name = "Watch worker logs";
              key = "w";
              command = "split-window -h -c '#{pane_current_path}' '${pkgs.sysinit-utils}/bin/utils watch worker #{q:pane_current_path}'";
            }
            {
              name = "Watch state bus";
              key = "b";
              command = "split-window -h -c '#{pane_current_path}' '${pkgs.sysinit-utils}/bin/utils watch bus #{q:pane_current_path}'";
            }
            {
              name = "Review current repository";
              key = "r";
              command = "split-window -h -c '#{pane_current_path}' 'nvim -c Review'";
            }
          ];
        }
        {
          name = "Rename session";
          key = "r";
          command = "command-prompt -I '#S' 'rename-session %%'";
        }
        {
          name = "Lock application keys (Ctrl-G unlocks)";
          key = "g";
          command = lock;
        }
        {
          name = "Detach and preserve session";
          key = "d";
          command = "set-option @sysinit_manual_detach 1 ; detach-client";
        }
      ];
    }
  );
  whichKey = pkgs.runCommand "tmux-which-key-config" { } ''
    ${pkgs.tmuxPlugins.tmux-which-key}/share/tmux-plugins/tmux-which-key/plugin/build.py ${whichKeyConfig} $out
    ${pkgs.gnused}/bin/sed -i '/^display -p /d' "$out"
  '';
  tmuxClient = pkgs.writeShellApplication {
    name = "tmux-client";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.tmux
      pkgs.sysinit-utils
    ];
    text = ''
      if [ "$#" -gt 1 ]; then
        printf 'usage: tmux-client [session-name]\n' >&2
        exit 2
      fi
      export SYSINIT_TMUX_PROVIDERS=${providersFile}
      session="''${1:-''${SYSINIT_TMUX_SESSION:-main}}"
      case "$session" in
        ""|-*|*:*|*$'\n'*|*$'\r'*|*$'\t'*)
          printf 'tmux-client: invalid session name %q\n' "$session" >&2
          exit 2
          ;;
      esac
      if [ -n "''${WEZTERM_PANE:-}" ]; then
        value=$(printf '%s' "$session" | base64 | tr -d '\n')
        printf '\033]1337;SetUserVar=SYSINIT_TMUX_SESSION=%s\007' "$value"
      fi
      if [ -n "''${TMUX:-}" ]; then
        tmux new-session -Ad -s "$session" -c "$PWD"
        exec tmux switch-client -t "=$session"
      fi
      exec tmux -f ${config.xdg.configFile."tmux/tmux.conf".source} new-session -A -s "$session" -c "$PWD"
    '';
  };
  tmuxLifecycle = pkgs.writeShellApplication {
    name = "tmux-lifecycle";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.tmux
    ];
    text = ''
      case "''${1:-}:$#" in
        attached:5|detached:5) ;;
        *)
          printf 'usage: tmux-lifecycle attached|detached <socket-path> <session-id> <client-name> <terminal-name-or-client-count>\n' >&2
          exit 2
          ;;
      esac
      socket=$2
      session=$3
      client=$4
      case "$1" in
        attached)
          tmux -S "$socket" set-option -s "@sysinit_client_$client" "$5"
          tmux -S "$socket" set-option -u -t "$session" @sysinit_manual_detach
          exit 0
          ;;
        detached)
          terminal=$(tmux -S "$socket" show-option -sqv "@sysinit_client_$client")
          tmux -S "$socket" set-option -su "@sysinit_client_$client"
          ;;
        *) exit 2 ;;
      esac
      case "$terminal" in
        wezterm*) ;;
        *) exit 0 ;;
      esac
      tmux -S "$socket" has-session -t "$session" 2>/dev/null || exit 0
      manual=$(tmux -S "$socket" show-option -qv -t "$session" @sysinit_manual_detach 2>/dev/null || true)
      if [ "$manual" = 1 ]; then
        tmux -S "$socket" set-option -u -t "$session" @sysinit_manual_detach
        exit 0
      fi
      clients=$5
      if [ "$clients" = 0 ]; then
        tmux -S "$socket" kill-session -t "$session"
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
      printf '%s' "$payload" | jq -r --arg selected "''${1:-}" '
        [.sessions[:6][] |
          (if .name == $selected then "#[fg=#${c.base05},bg=#${c.base02},bold] "
           elif .status == "waiting" then "#[fg=#${c.base08}] "
           elif .status == "done" then "#[fg=#${c.base0B}] "
           else "#[fg=#${c.base04}] " end)
          + "[" + (.name | gsub("#"; "##") | gsub("[\\r\\n]"; " ") | .[0:18])
          + (if .status then ":" + .status else "" end) + "]#[default]"
        ] | join("")
      '
    '';
  };
  providersFile = pkgs.writeText "tmux-providers.json" (
    builtins.toJSON {
      version = "sysinit.tmux-providers/v1";
      inherit providers;
    }
  );
in
{
  programs.tmux = {
    enable = true;
    package = pkgs.tmux;
    terminal = "tmux-256color";
    keyMode = "vi";
    escapeTime = 10;
    historyLimit = 200000;
    extraConfig = ''
      set -g default-shell ${lib.escapeShellArg (lib.getExe pkgs.zsh)}
      set -g default-command ${lib.escapeShellArg shell}
      set -g focus-events on
      set -g mouse on
      set -g set-clipboard on
      set -g allow-passthrough on
      set -g extended-keys always
      set -g extended-keys-format csi-u
      set -g renumber-windows on
      set -g automatic-rename on
      set -g detach-on-destroy off
      set -g window-size largest
      set -g status-position bottom
      set -g status-interval 1
      set -g status-style 'bg=#${c.base01},fg=#${c.base05}'
      set -g status-left-length 220
      set -g status-right-length 80
      set -g status-left '#{?@sysinit_locked,#[fg=#${c.base08},bold] LOCKED (Ctrl-G) #[default],}#(${lib.getExe sessionChips} #{q:session_name}) #[fg=#${c.base0D},bold] #S #[default]| '
      set -g status-right '#[fg=#${c.base04}]#{window_index}:#{window_name}  #{pane_current_path} '
      setw -g window-status-format ' #[fg=#${c.base04}]#I:#W '
      setw -g window-status-current-format ' #[fg=#${c.base05},bg=#${c.base02},bold]#I:#W#[default] '
      set -g pane-border-style 'fg=#${c.base02}'
      set -g pane-active-border-style 'fg=#${c.base0D}'
      set -as terminal-features ',wezterm*:RGB,wezterm*:sixel,wezterm*:extkeys,wezterm*:clipboard'
      set -g set-titles on
      set -g set-titles-string '#S'

      bind-key s display-popup -E -w 92% -h 86% '${pkgs.sysinit-utils}/bin/ty tmux picker'
      bind-key f ${floatingCommand}
      bind-key Y set-buffer -w '#{pane_current_path}'
      bind-key d set-option @sysinit_manual_detach 1 \; detach-client
      bind-key c ${spawn "window" false}
      bind-key C ${spawn "window" true}
      bind-key '-' ${spawn "down" false}
      bind-key '|' ${spawn "right" false}
      bind-key S ${spawn "down" true}
      bind-key V ${spawn "right" true}
      bind-key x confirm-before -p 'Close pane #P? (y/n)' kill-pane
      bind-key X confirm-before -p 'Close window #W? (y/n)' kill-window
      bind-key r command-prompt -I '#{window_name}' 'rename-window %%'
      bind-key R command-prompt -I '#{session_name}' 'rename-session %%'
      bind-key g ${builtins.replaceStrings [ " ; " ] [ " \\; " ] lock}
      bind-key -T root C-g ${builtins.replaceStrings [ " ; " ] [ " \\; " ] lock}
      bind-key -T sysinit-locked C-g ${builtins.replaceStrings [ " ; " ] [ " \\; " ] unlock}
      bind-key -T sysinit-locked Any send-keys
      ${lib.concatMapStringsSep "\n"
        (direction: ''
          bind-key -T root C-${direction} run-shell '${pkgs.sysinit-utils}/bin/ty tmux navigate #{pane_id} ${direction}'
          bind-key -T root C-S-${direction} run-shell '${pkgs.sysinit-utils}/bin/ty tmux resize #{pane_id} ${direction}'
        '')
        [
          "h"
          "j"
          "k"
          "l"
        ]
      }
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      bind-key -T copy-mode-vi Escape send-keys -X cancel
      source-file ${whichKey}
      bind-key '?' show-wk-menu-root
      set -g @smooth-scroll-speed 50
      set -g @smooth-scroll-easing sine
      set -g @smooth-scroll-mouse true
      run-shell ${smoothScroll}/share/tmux-plugins/smooth-scroll/smooth-scroll.tmux
      set-hook -g client-detached 'run-shell "${lib.getExe tmuxLifecycle} detached #{q:socket_path} #{q:session_id} #{q:hook_client} #{session_attached}"'
      set-hook -g client-session-changed 'run-shell "${lib.getExe tmuxLifecycle} attached #{q:socket_path} #{q:session_id} #{q:client_name} #{q:client_termname}"'
      set-hook -g client-session-changed[1] 'if-shell -F "#{&&:#{@sysinit_float_parent},#{m:wezterm*,#{client_termname}}}" { run-shell -b "${lib.getExe floatingTerminal} redirect #{q:socket_path} #{q:session_id} #{q:client_name} #{q:pane_current_path}"; }'
      set-hook -g session-closed 'run-shell "${lib.getExe floatingTerminal} cleanup #{q:socket_path} #{q:hook_session}"'
    '';
  };

  xdg.configFile."sysinit/tmux-providers.json".source = providersFile;

  home.activation.sysinitTmux = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if ${lib.getExe pkgs.tmux} has-session 2> /dev/null; then
      run ${lib.getExe pkgs.tmux} source-file ${config.xdg.configFile."tmux/tmux.conf".source}
    fi
  '';

  home.packages = [
    tmuxClient
    tmuxLifecycle
    sessionChips
  ];
}
