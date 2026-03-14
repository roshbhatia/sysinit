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

      preset-column-widths {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
      }

      default-column-width {
        proportion 0.5
      }
    }

    // All windows slightly transparent, focused windows less so
    window-rule {
      draw-border-with-background false
      opacity 0.92
    }
    window-rule {
      match is-focused=false
      opacity 0.78
    }

    prefer-no-csd

    // Screenshots
    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

    // Overview
    overview {
      backdrop-color "#1d2021"
    }

    // Hotkey overlay (Super+? to show)
    hotkey-overlay {
      skip-at-startup
      hide-not-bound
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

      // ── Keybinding cheatsheet ──
      Super+Shift+Slash { show-hotkey-overlay; }
    }
  '';

  # === Rofi App Launcher (Gruvbox) ===
  xdg.configFile."rofi/config.rasi".text = ''
    configuration {
      modi: "drun,run,window";
      show-icons: true;
      icon-theme: "Papirus-Dark";
      terminal: "wezterm";
      drun-display-format: "{name}";
      window-format: "{w} {c} {t}";
      disable-history: false;
      hide-scrollbar: true;
      sorting-method: "fzf";
      click-to-exit: true;
      steal-focus: true;

      /* Clear conflicting defaults, then set vim-style navigation */
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
      kb-mode-next: "Control+Tab";
      kb-mode-previous: "Control+Shift+Tab";
    }

    * {
      bg:             #1d2021cc;
      bg-solid:       #1d2021;
      bg-entry:       #28282800;
      bg-selected:    #3c383680;
      fg:             #ebdbb2;
      fg-dim:         #928374;
      fg-placeholder: #665c54;
      accent:         #fe8019;
      accent-dim:     #fe801940;
      yellow:         #fabd2f;
      urgent:         #fb4934;
      green:          #b8bb26;
      blue:           #83a598;
      border-col:     #50494580;
      none:           transparent;
      font:           "${values.theme.font.monospace} 13";
    }

    window {
      transparency:    "real";
      width:           560px;
      border:          1px;
      border-color:    @border-col;
      background-color: @bg;
      border-radius:   8px;
      padding:         0;
      location:        center;
      anchor:          center;
    }

    mainbox {
      background-color: @none;
      children:        [ inputbar, listview ];
      spacing:         0;
    }

    inputbar {
      background-color: @none;
      children:        [ textbox-prompt, entry ];
      padding:         16px 20px;
      spacing:         12px;
    }

    textbox-prompt {
      expand:          false;
      str:             "";
      font:            "Symbols Nerd Font Mono 15";
      text-color:      @accent;
      background-color: @none;
      vertical-align:  0.5;
      horizontal-align: 0.5;
    }

    entry {
      background-color: @bg-entry;
      text-color:      @fg;
      padding:         8px 0;
      placeholder:     "Type to search...";
      placeholder-color: @fg-placeholder;
      font:            @font;
      cursor:          text;
      cursor-color:    @accent;
    }

    listview {
      background-color: @none;
      columns:         1;
      lines:           8;
      padding:         0 8px 8px 8px;
      spacing:         2px;
      fixed-height:    true;
      cycle:           false;
    }

    element {
      background-color: @none;
      text-color:      @fg;
      padding:         10px 14px;
      border-radius:   6px;
      spacing:         12px;
    }

    element selected.normal {
      background-color: @bg-selected;
      text-color:      @fg;
    }

    element selected.urgent {
      background-color: @urgent;
      text-color:      @bg-solid;
    }

    element selected.active {
      background-color: @bg-selected;
      text-color:      @green;
    }

    element normal.urgent {
      text-color:      @urgent;
    }

    element normal.active {
      text-color:      @green;
    }

    element alternate.normal {
      background-color: @none;
      text-color:      @fg;
    }

    element-icon {
      size:            22px;
      background-color: inherit;
      padding:         0;
      cursor:          pointer;
    }

    element-text {
      background-color: inherit;
      text-color:      inherit;
      font:            @font;
      vertical-align:  0.5;
      cursor:          pointer;
    }

    scrollbar {
      handle-width:    4px;
      handle-color:    @border-col;
      background-color: @none;
      border-radius:   2px;
      margin:          0 0 0 4px;
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

  # === GTK / Icon Theme ===
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
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
