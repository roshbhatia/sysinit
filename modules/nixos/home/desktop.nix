# NixOS desktop home-manager configuration: niri, quickshell, rofi, mako, nemo
{
  config,
  lib,
  pkgs,
  values,
  ...
}:

let
  colors = config.lib.stylix.colors;

  wallpaper = pkgs.fetchurl {
    url = "https://images2.alphacoders.com/140/1406218.png";
    sha256 = "sha256-2VJu0diUD14psjpZJU+X2U1EPsM4GvZzTNy3bJCOz5Q=";
  };
in
{
  stylix.targets = {
    rofi.enable = false;
    mako.enable = false;
  };

  # === Niri Window Manager ===
  xdg.configFile."niri/config.kdl".text = ''
    // Environment variables for Wayland apps
    environment {
      NIXOS_OZONE_WL "1"
      GDK_BACKEND "wayland"
      QT_QPA_PLATFORM "wayland"
      MOZ_ENABLE_WAYLAND "1"
    }

    input {
      keyboard {
        xkb {
          layout "us"
        }
        repeat-delay 300
        repeat-rate 50
      }

      mouse {
        accel-profile "flat"
        accel-speed -0.5
      }

      touchpad {
        natural-scroll
        tap
        dwt
      }

      warp-mouse-to-focus
      focus-follows-mouse
    }

    // Cursor
    cursor {
      hide-when-typing
      hide-after-inactive-ms 10000
    }

    // Layout
    layout {
      gaps 13

      center-focused-column "on-overflow"

      focus-ring {
        off
      }

      border {
        off
      }

      shadow {
        on
        softness 20
        spread 3
        offset x=0 y=3
        color "#00000050"
        inactive-color "#00000030"
      }
    }

    // Dim unfocused windows to indicate focus (instead of border/ring)
    window-rule {
      opacity 1.0
      draw-border-with-background false
    }
    window-rule {
      match is-focused=false
      opacity 0.88

      preset-column-widths {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
      }

      default-column-width {
        proportion 0.5
      }
    }

    prefer-no-csd

    // Screenshots
    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

    // Overview
    overview {
      backdrop-color "#1d2021"
    }

    // Hotkey overlay
    hotkey-overlay {
      skip-at-startup
    }

    // Startup commands
    spawn-at-startup "${pkgs.swaybg}/bin/swaybg" "-i" "${wallpaper}" "-m" "fill"
    spawn-at-startup "${pkgs.mako}/bin/mako"
    spawn-at-startup "nm-applet" "--indicator"
    spawn-at-startup "quickshell"
    spawn-sh-at-startup "echo MAIN > ~/.cache/niri-mode"

    // Key bindings
    binds {
      // ── Launching ──
      Alt+Return { spawn "${pkgs.wezterm}/bin/wezterm"; }
      Super+Space { spawn "${pkgs.rofi}/bin/rofi" "-show" "drun" "-theme" "${config.xdg.configHome}/rofi/config.rasi"; }

      // ── Window management ──
      Super+Q { close-window; }

      // Focus (vim-style, matching aerospace alt+hjkl)
      Alt+H { focus-column-left; }
      Alt+J { focus-window-down; }
      Alt+K { focus-window-up; }
      Alt+L { focus-column-right; }

      // Move columns/windows (matching aerospace move mode but always available)
      Alt+Ctrl+H { move-column-left; }
      Alt+Ctrl+J { move-window-down; }
      Alt+Ctrl+K { move-window-up; }
      Alt+Ctrl+L { move-column-right; }

      // Resize (matching aerospace alt+shift+j/k)
      Alt+Shift+J { set-column-width "-10%"; }
      Alt+Shift+K { set-column-width "+10%"; }

      // Maximize / fullscreen (matching aerospace alt+f)
      Alt+F { maximize-column; }
      Alt+Shift+F { fullscreen-window; }

      // Center column
      Alt+C { center-column; }

      // Consume / expel windows into/from column
      Alt+Comma { consume-window-into-column; }
      Alt+Period { expel-window-from-column; }

      // Column width presets
      Alt+R { switch-preset-column-width; }

      // Float toggle
      Alt+V { toggle-window-floating; }

      // Layout toggle (matching aerospace alt+t tiles, alt+a accordion)
      Alt+T { toggle-column-tabbed-display; }

      // ── Workspaces (matching aerospace alt+1/2/c/e/m) ──
      Alt+1 { focus-workspace 1; }
      Alt+2 { focus-workspace 2; }
      Alt+3 { focus-workspace 3; }
      Alt+4 { focus-workspace 4; }
      Alt+5 { focus-workspace 5; }
      Alt+6 { focus-workspace 6; }
      Alt+7 { focus-workspace 7; }
      Alt+8 { focus-workspace 8; }
      Alt+9 { focus-workspace 9; }

      // Move to workspace (matching aerospace alt+shift+N)
      Alt+Shift+1 { move-column-to-workspace 1; }
      Alt+Shift+2 { move-column-to-workspace 2; }
      Alt+Shift+3 { move-column-to-workspace 3; }
      Alt+Shift+4 { move-column-to-workspace 4; }
      Alt+Shift+5 { move-column-to-workspace 5; }
      Alt+Shift+6 { move-column-to-workspace 6; }
      Alt+Shift+7 { move-column-to-workspace 7; }
      Alt+Shift+8 { move-column-to-workspace 8; }
      Alt+Shift+9 { move-column-to-workspace 9; }

      // Workspace cycling (matching aerospace alt+tab)
      Alt+Tab { focus-workspace-down; }
      Alt+Shift+Tab { focus-workspace-up; }

      // Workspace back-and-forth (matching aerospace alt+p)
      Alt+P { focus-workspace-previous; }

      // ── Monitor focus ──
      Alt+Shift+H { focus-monitor-left; }
      Alt+Shift+L { focus-monitor-right; }

      // Move column to monitor
      Alt+Ctrl+Shift+H { move-column-to-monitor-left; }
      Alt+Ctrl+Shift+L { move-column-to-monitor-right; }

      // ── Media keys (work when locked) ──
      XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05+"; }
      XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05-"; }
      XF86AudioMute        allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }

      // ── Screenshot ──
      Print { screenshot; }
      Alt+Print { screenshot-screen; }
      Alt+Shift+Print { screenshot-window; }

      // ── Overview ──
      Super+Tab { toggle-overview; }
    }
  '';

  # === Rofi App Launcher (Gruvbox) ===
  xdg.configFile."rofi/config.rasi".text = ''
    configuration {
      modi: "drun,run,window";
      show-icons: true;
      terminal: "wezterm";
      drun-display-format: "{icon} {name}";
      disable-history: false;
      hide-scrollbar: true;
      sorting-method: "fzf";

      /* Clear conflicting defaults first, then set vim-style navigation */
      kb-clear-line: "";
      kb-remove-to-sol: "";
      kb-remove-to-eol: "";
      kb-remove-char-forward: "Delete";
      kb-remove-word-back: "Control+BackSpace";
      kb-accept-entry: "Return,KP_Enter";
      kb-cancel: "Escape,Control+bracketleft";
      kb-row-up: "Up,Control+k,Control+p";
      kb-row-down: "Down,Control+j,Control+n";
      kb-page-prev: "Page_Up,Control+u";
      kb-page-next: "Page_Down,Control+d";
      kb-move-front: "Control+a";
      kb-move-end: "Control+e";
      kb-delete-entry: "Shift+Delete";
    }

    * {
      bg:          #1d2021e6;
      bg-solid:    #1d2021;
      bg-alt:      #282828;
      fg:          #ebdbb2;
      fg-dim:      #928374;
      accent:      #fe8019;
      accent-alt:  #fabd2f;
      urgent:      #fb4934;
      green:       #b8bb26;
      border-col:  #504945;
      transparent: rgba(0, 0, 0, 0);
    }

    window {
      width: 520px;
      border: 2px;
      border-color: @border-col;
      background-color: @bg;
      border-radius: 6px;
      padding: 0;
    }

    mainbox {
      background-color: @transparent;
      children: [ inputbar, message, listview ];
      spacing: 0;
    }

    inputbar {
      background-color: @bg-alt;
      children: [ prompt, entry ];
      padding: 14px 16px;
      border: 0 0 1px 0;
      border-color: @border-col;
      border-radius: 6px 6px 0 0;
    }

    prompt {
      background-color: @accent;
      text-color: @bg-solid;
      padding: 6px 14px;
      border-radius: 4px;
      font: "${values.theme.font.monospace} 13";
      vertical-align: 0.5;
    }

    entry {
      background-color: @transparent;
      text-color: @fg;
      padding: 6px 14px;
      placeholder: "Search...";
      placeholder-color: @fg-dim;
      font: "${values.theme.font.monospace} 13";
      cursor: text;
      cursor-color: @accent;
    }

    message {
      background-color: @transparent;
      border: 0;
      padding: 8px 16px;
    }

    textbox {
      text-color: @fg-dim;
      background-color: @transparent;
    }

    listview {
      background-color: @transparent;
      columns: 1;
      lines: 12;
      padding: 8px 0;
      spacing: 0;
      fixed-height: true;
    }

    element {
      background-color: @transparent;
      text-color: @fg;
      padding: 10px 18px;
      border-radius: 0;
    }

    element selected.normal {
      background-color: @accent;
      text-color: @bg-solid;
    }

    element selected.urgent {
      background-color: @urgent;
      text-color: @bg-solid;
    }

    element selected.active {
      background-color: @green;
      text-color: @bg-solid;
    }

    element normal.urgent {
      text-color: @urgent;
    }

    element normal.active {
      text-color: @green;
    }

    element alternate.normal {
      background-color: @transparent;
      text-color: @fg;
    }

    element-icon {
      size: 24px;
      background-color: inherit;
      padding: 0 10px 0 0;
    }

    element-text {
      background-color: inherit;
      text-color: inherit;
      font: "${values.theme.font.monospace} 13";
      vertical-align: 0.5;
    }

    mode-switcher {
      background-color: @bg-alt;
      padding: 6px 8px;
      border: 1px 0 0 0;
      border-color: @border-col;
      spacing: 4px;
    }

    button {
      background-color: @transparent;
      text-color: @fg-dim;
      padding: 4px 12px;
      border-radius: 4px;
      font: "${values.theme.font.monospace} 12";
    }

    button selected {
      background-color: @border-col;
      text-color: @fg;
    }
  '';

  # === Mako Notifications (Gruvbox) ===
  services.mako = {
    enable = true;
    settings = {
      font = "${values.theme.font.monospace} 11";
      background-color = "#1d2021";
      text-color = "#ebdbb2";
      border-color = "#504945";
      border-size = 2;
      border-radius = 0;
      padding = "15";
      margin = "10";
      width = 350;
      height = 100;
      default-timeout = 5000;
      layer = "overlay";
    };

    extraConfig = ''
      [urgency=low]
      border-color=#${colors.base03}

      [urgency=high]
      border-color=#${colors.base08}
      default-timeout=0
    '';
  };

  # === Wallpaper ===
  home.file.".background-image" = {
    source = wallpaper;
    force = true;
  };

  # === Nemo File Manager ===
  home.file.".local/share/nemo/actions/open-terminal.nemo_action".text = ''
    [Nemo Action]
    Active=true
    Name=Open Terminal Here
    Exec=wezterm -e bash -c "cd %f && bash"
    Selection=Any
    Extensions=any;
  '';

  dconf.settings = {
    "org/cinnamon/desktop/default-applications/terminal".exec = "wezterm";
    "org/nemo/preferences" = {
      show-hidden-files = false;
      show-advanced-permissions = true;
      date-format = "informal";
      default-folder-viewer = "icon-view";
    };
    "org/nemo/window-state" = {
      geometry = "1200x800+50+50";
      sidebar-width = 200;
    };
  };
}
