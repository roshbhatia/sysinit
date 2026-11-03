{
  config,
  lib,
  pkgs,
  ...
}:
let
  themeLib = import ../../../shared/theme-colors.nix { inherit lib; };
  c = themeLib.colorsOf config;
  paths = import ../../../lib/paths.nix { inherit lib; };
  presentation = import ./presentation.nix { inherit config pkgs; };
  pickerCommand = "new-pane -O -K -x 92% -y 86% -X 4% -Y 7% -e SYSINIT_TMUX_UI=picker '${pkgs.sysinit-utils}/bin/ty tmux picker'";
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
          command = "send-keys -K C-b f";
        }
        {
          name = "Sessions and providers";
          key = "s";
          command = pickerCommand;
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
              command = "send-keys -K C-b Y";
            }
            {
              name = "Search history";
              key = "/";
              command = "copy-mode ; send-keys -X search-backward";
            }
            {
              name = "Quick select paths and identifiers";
              key = "f";
              command = "send-keys -K C-b t";
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
          name = "Save, restore and logging";
          key = "l";
          menu = [
            {
              name = "Save sessions";
              key = "s";
              command = "send-keys -K C-b C-s";
            }
            {
              name = "Restore saved sessions";
              key = "r";
              command = "send-keys -K C-b C-r";
            }
            {
              name = "Toggle pane logging";
              key = "l";
              command = "send-keys -K C-b P";
            }
            {
              name = "Capture screen";
              key = "p";
              command = "send-keys -K C-b M-p";
            }
            {
              name = "Save complete history";
              key = "h";
              command = "send-keys -K C-b M-P";
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
          command = "send-keys -K C-b d";
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
      export SYSINIT_TMUX_PROVIDERS=${config.xdg.configHome}/sysinit/tmux-providers.json
      session="''${1:-''${SYSINIT_TMUX_SESSION:-terminal-$(date +%s)-$$}}"
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
      if [ -n "''${WEZTERM_PANE:-}" ]; then
        export TERM=wezterm
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
        attached:5|detached:5|detach:5) ;;
        *)
          printf 'usage: tmux-lifecycle attached|detached|detach <socket-path> <session-id> <client-name> <terminal-name-or-client-count>\n' >&2
          exit 2
          ;;
      esac
      socket=$2
      session=$3
      client=$4
      case "$1" in
        attached)
          tmux -S "$socket" set-option -s "@sysinit_client_$client" "$5"
          exit 0
          ;;
        detach)
          tmux -S "$socket" set-option -s "@sysinit_detach_$client" 1
          exec tmux -S "$socket" detach-client -t "$client"
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
      manual=$(tmux -S "$socket" show-option -sqv "@sysinit_detach_$client")
      if [ "$manual" = 1 ]; then
        tmux -S "$socket" set-option -su "@sysinit_detach_$client"
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
  providersFile = pkgs.writeText "tmux-providers.json" (
    builtins.toJSON {
      version = "sysinit.tmux-providers/v1";
      inherit providers;
      presentation = presentation.command;
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
      set -g status-style 'bg=default,fg=#${c.base05}'
      set -g menu-style 'bg=default,fg=#${c.base05}'
      set -g menu-border-style 'bg=default,fg=#${c.base0D}'
      set -g menu-selected-style 'bg=#${c.base0D},fg=#${c.base00},bold'
      set -g popup-style 'bg=default,fg=#${c.base05}'
      set -g popup-border-style 'bg=default,fg=#${c.base0D}'
      set -g status-left ""
      set -g status-right ""
      set -g status-format[0] '#{E:status-left}#(${pkgs.coreutils}/bin/env SYSINIT_TMUX_PROVIDERS=${config.xdg.configHome}/sysinit/tmux-providers.json ${pkgs.sysinit-utils}/bin/ty tmux ui status #{session_id} #{client_width} #{window_id} #{?@sysinit_locked,1,0} #{?pane_in_mode,COPY,NORMAL})#{E:status-right}'
      set -g pane-border-style 'fg=#${c.base02}'
      set -g pane-active-border-style 'fg=#${c.base0D}'
      set -as terminal-features ',wezterm*:RGB,wezterm*:sixel,wezterm*:extkeys,wezterm*:clipboard'
      set -g set-titles on
      set -g set-titles-string '#S'

      ${lib.concatMapStringsSep "\n" (
        slot:
        "bind-key F${toString slot} run-shell '${pkgs.sysinit-utils}/bin/ty tmux ui session-slot ${toString slot}'"
      ) (lib.range 1 9)}
      bind-key s ${pickerCommand}
      bind-key f ${floatingCommand}
      bind-key Y run-shell '${lib.getExe pkgs.tmux} -S #{q:socket_path} set-buffer -w -t #{q:client_name} #{q:pane_current_path}'
      bind-key d run-shell '${lib.getExe tmuxLifecycle} detach #{q:socket_path} #{q:session_id} #{q:client_name} 0'
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
      bind-key -T root WheelUpPane if-shell -F -t = '#{||:#{alternate_on},#{pane_in_mode},#{mouse_any_flag}}' 'send-keys -M' 'copy-mode -e -t = ; send-keys -X -t = -N 5 scroll-up'
      bind-key -T root WheelDownPane if-shell -F -t = '#{||:#{alternate_on},#{pane_in_mode},#{mouse_any_flag}}' 'send-keys -M'
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      bind-key -T copy-mode-vi Escape send-keys -X cancel
      source-file ${whichKey}
      bind-key '?' show-wk-menu-root
      ${lib.concatMapStringsSep "\n" (binding: "bind-key -T copy-mode-vi ${binding}") [
        "J send-keys -X scroll-down"
        "K send-keys -X scroll-up"
        "C-e send-keys -X scroll-down"
        "C-y send-keys -X scroll-up"
        "C-Up send-keys -X scroll-up"
        "C-Down send-keys -X scroll-down"
        "C-u send-keys -X halfpage-up"
        "C-d send-keys -X halfpage-down \\; if-shell -F '#{==:#{scroll_position},0}' 'send-keys -X cancel'"
        "C-b send-keys -X page-up"
        "C-f send-keys -X page-down"
        "PPage send-keys -X page-up"
        "NPage send-keys -X page-down"
        "WheelUpPane select-pane \\; send-keys -X -N 5 scroll-up"
        "WheelDownPane select-pane \\; send-keys -X -N 5 scroll-down \\; if-shell -F '#{==:#{scroll_position},0}' 'send-keys -X cancel'"
      ]}
      bind-key -T copy-mode-vi g send-keys -X history-top
      bind-key -T copy-mode-vi G send-keys -X history-bottom
      bind-key -T copy-mode-vi '[' send-keys -X previous-prompt
      bind-key -T copy-mode-vi ']' send-keys -X next-prompt
      bind-key '<' swap-window -t -1
      bind-key '>' swap-window -t +1
      set -g @thumbs-key t
      set -g @thumbs-osc52 1
      set -g @thumbs-bg-color default
      set -g @thumbs-fg-color '#${c.base05}'
      set -g @thumbs-hint-bg-color default
      set -g @thumbs-hint-fg-color '#${c.base0D}'
      set -g @thumbs-select-bg-color '#${c.base0D}'
      set -g @thumbs-select-fg-color '#${c.base00}'
      set -g @resurrect-dir '${config.xdg.stateHome}/tmux/resurrect'
      set -g @logging-path '${config.xdg.stateHome}/tmux/logs'
      set -g @screen-capture-path '${config.xdg.stateHome}/tmux/captures'
      set -g @save-complete-history-path '${config.xdg.stateHome}/tmux/history'
      set -g @continuum-save-interval 15
      set -g @continuum-restore off
      run-shell '${pkgs.tmuxPlugins.tmux-thumbs}/share/tmux-plugins/tmux-thumbs/tmux-thumbs.tmux'
      run-shell '${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux'
      run-shell '${pkgs.tmuxPlugins.logging}/share/tmux-plugins/logging/logging.tmux'
      run-shell '${pkgs.tmuxPlugins.open}/share/tmux-plugins/open/open.tmux'
      run-shell '${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux'
      set-hook -g client-detached 'run-shell "${lib.getExe tmuxLifecycle} detached #{q:socket_path} #{q:session_id} #{q:hook_client} #{session_attached}"'
      set-hook -g client-session-changed 'run-shell "${lib.getExe tmuxLifecycle} attached #{q:socket_path} #{q:session_id} #{q:client_name} #{q:client_termname}"'
      set-hook -g client-session-changed[1] 'if-shell -F "#{&&:#{@sysinit_float_parent},#{m:wezterm*,#{client_termname}}}" { run-shell -b "${lib.getExe floatingTerminal} redirect #{q:socket_path} #{q:session_id} #{q:client_name} #{q:pane_current_path}"; }'
      set-hook -g session-closed 'run-shell "${lib.getExe floatingTerminal} cleanup #{q:socket_path} #{q:hook_session}"'
    '';
  };

  xdg.configFile."sysinit/terminal.json".source = pkgs.writeText "terminal.json" (
    builtins.toJSON {
      version = "sysinit.terminal/v1";
      renderer = "wezterm";
      tmux = "${pkgs.tmux}/bin/tmux";
      sessionizer = "${pkgs.seshy}/bin/sy";
      client = lib.getExe tmuxClient;
      shellCommand = shell;
      runtimePath = paths.getPathString config.home.username config.home.homeDirectory;
      executable = "${pkgs.wezterm}/bin/wezterm";
      application =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "${config.home.homeDirectory}/${config.targets.darwin.copyApps.directory}/WezTerm.app"
        else
          "";
    }
  );
  xdg.configFile."sysinit/tmux-providers.json".source = providersFile;

  home.activation.sysinitTmux = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if ${lib.getExe pkgs.tmux} has-session 2> /dev/null; then
      run ${lib.getExe pkgs.tmux} source-file ${config.xdg.configFile."tmux/tmux.conf".source}
    fi
  '';

  home.packages = [
    tmuxClient
    floatingTerminal
    tmuxLifecycle
  ];
}
