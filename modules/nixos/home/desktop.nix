# NixOS desktop home-manager configuration: niri, waybar, rofi, mako, nemo
{
  config,
  lib,
  pkgs,
  values,
  ...
}:

let
  c = config.lib.stylix.colors; # base16 palette

  wallpaper = pkgs.fetchurl {
    url = "https://wallpapercave.com/wp/wp12329549.png";
    sha256 = "sha256-9R3cDgd1VslCF6mG6jBO64MEdRjCGzWE4m/dAjEixzk=";
  };
in
{
  stylix.targets = {
    waybar.enable = false;
    rofi.enable = false;
    mako.enable = false;
  };

  # === Niri Window Manager ===
  xdg.configFile."niri/config.kdl".text = ''
    // ── Environment ──
    environment {
      NIXOS_OZONE_WL "1"
      GDK_BACKEND "wayland"
      QT_QPA_PLATFORM "wayland"
      MOZ_ENABLE_WAYLAND "1"
      __NV_DISABLE_EXPLICIT_SYNC "1"
    }

    // ── Input ──
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

    // ── Cursor ──
    cursor {
      xcursor-theme "macOS"
      xcursor-size 16
      hide-when-typing
      hide-after-inactive-ms 10000
    }

    // ── Layout ──
    layout {
      gaps 10

      center-focused-column "on-overflow"

      focus-ring {
        off
      }

      border {
        off
      }

      shadow {
        on
        softness 30
        spread 5
        offset x=0 y=5
        color "#00000064"
        inactive-color "#00000040"
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

    // ── Animations ──
    animations {
      workspace-switch {
        spring damping-ratio=0.85 stiffness=1000 epsilon=0.0001
      }
      window-open {
        duration-ms 200
        curve "ease-out-expo"
      }
      window-close {
        duration-ms 100
        curve "ease-out-quad"
      }
      horizontal-view-movement {
        spring damping-ratio=1.0 stiffness=1000 epsilon=0.0001
      }
      window-movement {
        spring damping-ratio=0.85 stiffness=900 epsilon=0.0001
      }
      window-resize {
        spring damping-ratio=1.0 stiffness=1000 epsilon=0.0001
      }
    }

    // ── Window Rules ──

    // Squared corners, no rounding, no clipping
    window-rule {
      geometry-corner-radius 0
      clip-to-geometry false
    }

    // ── Opacity ──
    window-rule {
      opacity 0.90
    }
    window-rule {
      match is-focused=false
      opacity 0.80
    }

    // WezTerm: REQUIRED — wezterm waits for a zero-sized configure event
    // from the compositor. Without this rule, wezterm hangs with a blank
    // window because niri sends a fixed size instead of letting wezterm
    // pick its own. See: https://github.com/niri-wm/niri/wiki/Application:-WezTerm
    window-rule {
      match app-id=r#"^org\.wezfurlong\.wezterm$"#
      default-column-width {}
    }

    // ── Floating windows ──
    window-rule {
      match title="^Picture-in-Picture$"
      open-floating true
    }
    window-rule {
      match app-id="^pavucontrol$"
      open-floating true
    }
    window-rule {
      match app-id="^1password$"
      open-floating true
    }
    window-rule {
      match app-id="^nemo$"
      open-floating true
    }

    // ── Misc ──
    prefer-no-csd

    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

    overview {
      backdrop-color "#${c.base00}"
    }

    hotkey-overlay {
      skip-at-startup
      hide-not-bound
    }

    // ── Startup ──
    spawn-at-startup "${pkgs.swaybg}/bin/swaybg" "-i" "${wallpaper}" "-m" "fill"
    spawn-at-startup "${pkgs.waybar}/bin/waybar"
    spawn-at-startup "${pkgs.mako}/bin/mako"
    spawn-at-startup "nm-applet" "--indicator"
    spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
    spawn-at-startup "${pkgs.wl-clipboard}/bin/wl-paste" "--watch" "${pkgs.cliphist}/bin/cliphist" "store"

    // ── Key Bindings ──
    binds {
      // Launch
      Alt+Return hotkey-overlay-title="Terminal" { spawn "${pkgs.wezterm}/bin/wezterm" "start"; }
      Super+Space hotkey-overlay-title="App Launcher" { spawn "${pkgs.rofi}/bin/rofi" "-show" "drun" "-theme" "${config.xdg.configHome}/rofi/config.rasi"; }

      // Window management
      Super+Q hotkey-overlay-title="Close Window" { close-window; }

      // Focus (vim-style, matching aerospace)
      Alt+H hotkey-overlay-title="Focus Left" { focus-column-left; }
      Alt+J hotkey-overlay-title="Focus Down" { focus-window-down; }
      Alt+K hotkey-overlay-title="Focus Up" { focus-window-up; }
      Alt+L hotkey-overlay-title="Focus Right" { focus-column-right; }

      // Move (matching aerospace move mode)
      Alt+Ctrl+H hotkey-overlay-title="Move Left" { move-column-left; }
      Alt+Ctrl+J hotkey-overlay-title="Move Down" { move-window-down; }
      Alt+Ctrl+K hotkey-overlay-title="Move Up" { move-window-up; }
      Alt+Ctrl+L hotkey-overlay-title="Move Right" { move-column-right; }

      // Resize (matching aerospace)
      Alt+Shift+J hotkey-overlay-title="Shrink Width" { set-column-width "-10%"; }
      Alt+Shift+K hotkey-overlay-title="Grow Width" { set-column-width "+10%"; }

      // Fullscreen / maximize (matching aerospace alt+f)
      Alt+F hotkey-overlay-title="Maximize" { maximize-column; }
      Alt+Shift+F hotkey-overlay-title="Fullscreen" { fullscreen-window; }

      // Column operations
      Alt+C hotkey-overlay-title="Center Column" { center-column; }
      Alt+Comma hotkey-overlay-title="Consume Into Column" { consume-window-into-column; }
      Alt+Period hotkey-overlay-title="Expel From Column" { expel-window-from-column; }
      Alt+R hotkey-overlay-title="Cycle Column Width" { switch-preset-column-width; }
      Alt+V hotkey-overlay-title="Toggle Float" { toggle-window-floating; }
      Alt+T hotkey-overlay-title="Toggle Tabbed" { toggle-column-tabbed-display; }

      // Workspaces (matching aerospace)
      Alt+1 { focus-workspace 1; }
      Alt+2 { focus-workspace 2; }
      Alt+3 { focus-workspace 3; }
      Alt+4 { focus-workspace 4; }
      Alt+5 { focus-workspace 5; }
      Alt+6 { focus-workspace 6; }
      Alt+7 { focus-workspace 7; }
      Alt+8 { focus-workspace 8; }
      Alt+9 { focus-workspace 9; }

      Alt+Shift+1 { move-column-to-workspace 1; }
      Alt+Shift+2 { move-column-to-workspace 2; }
      Alt+Shift+3 { move-column-to-workspace 3; }
      Alt+Shift+4 { move-column-to-workspace 4; }
      Alt+Shift+5 { move-column-to-workspace 5; }
      Alt+Shift+6 { move-column-to-workspace 6; }
      Alt+Shift+7 { move-column-to-workspace 7; }
      Alt+Shift+8 { move-column-to-workspace 8; }
      Alt+Shift+9 { move-column-to-workspace 9; }

      // Workspace navigation (matching aerospace)
      Alt+Tab { focus-workspace-down; }
      Alt+Shift+Tab { focus-workspace-up; }
      Alt+P { focus-workspace-previous; }

      // Monitor
      Alt+Shift+H { focus-monitor-left; }
      Alt+Shift+L { focus-monitor-right; }
      Alt+Ctrl+Shift+H { move-column-to-monitor-left; }
      Alt+Ctrl+Shift+L { move-column-to-monitor-right; }

      // Media (work when locked)
      XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05+"; }
      XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05-"; }
      XF86AudioMute        allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
      XF86AudioPlay  allow-when-locked=true { spawn "${pkgs.playerctl}/bin/playerctl" "play-pause"; }
      XF86AudioPause allow-when-locked=true { spawn "${pkgs.playerctl}/bin/playerctl" "play-pause"; }
      XF86AudioNext  allow-when-locked=true { spawn "${pkgs.playerctl}/bin/playerctl" "next"; }
      XF86AudioPrev  allow-when-locked=true { spawn "${pkgs.playerctl}/bin/playerctl" "previous"; }

      // Screenshot
      Print hotkey-overlay-title="Screenshot" { screenshot; }
      Alt+Print { screenshot-screen; }
      Alt+Shift+Print { screenshot-window; }

      // Log out (back to login screen, like macOS)
      Super+Ctrl+Q hotkey-overlay-title="Log Out" { quit skip-confirmation=true; }

      // Clipboard history
      Super+V hotkey-overlay-title="Clipboard History" { spawn "sh" "-c" "${pkgs.cliphist}/bin/cliphist list | ${pkgs.rofi}/bin/rofi -dmenu -theme ${config.xdg.configHome}/rofi/config.rasi | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy"; }

      // Power off monitors
      Super+Shift+P hotkey-overlay-title="Monitors Off" { power-off-monitors; }

      // Overview + cheatsheet
      Super+Tab hotkey-overlay-title="Overview" { toggle-overview; }
      Super+Shift+Slash hotkey-overlay-title="Keybindings" { show-hotkey-overlay; }
    }
  '';

  # === Rofi App Launcher ===
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
      bg:             #${c.base00}cc;
      bg-solid:       #${c.base00};
      bg-entry:       #${c.base01}00;
      bg-selected:    #${c.base01}80;
      fg:             #${c.base06};
      fg-dim:         #${c.base04};
      fg-placeholder: #${c.base03};
      accent:         #${c.base09};
      urgent:         #${c.base08};
      green:          #${c.base0B};
      border-col:     #${c.base02}80;
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
    }

    element-text {
      background-color: inherit;
      text-color:      inherit;
      font:            @font;
      vertical-align:  0.5;
    }
  '';

  # === Mako Notifications ===
  services.mako = {
    enable = true;
    settings = {
      font = "${values.theme.font.monospace} 11";
      background-color = "#${c.base00}";
      text-color = "#${c.base06}";
      border-color = "#${c.base02}";
      border-size = 2;
      border-radius = 8;
      padding = "15";
      margin = "10";
      width = 350;
      height = 100;
      default-timeout = 5000;
      layer = "overlay";
    };

    extraConfig = ''
      [urgency=low]
      border-color=#${c.base03}

      [urgency=high]
      border-color=#${c.base08}
      default-timeout=0
    '';
  };

  # === GTK / Icon / Cursor / Theme ===
  gtk = {
    enable = true;
    theme = {
      name = lib.mkForce "Gruvbox-Dark";
      package = lib.mkForce pkgs.gruvbox-gtk-theme;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  home.pointerCursor = {
    name = "macOS";
    package = pkgs.apple-cursor;
    size = 16;
    gtk.enable = true;
  };

  # === Wallpaper ===
  home.file.".background-image" = {
    source = wallpaper;
    force = true;
  };

  # === XDG Default Applications ===
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "application/pdf" = "org.pwmt.zathura.desktop";
      "image/png" = "imv.desktop";
      "image/jpeg" = "imv.desktop";
      "image/gif" = "imv.desktop";
      "image/webp" = "imv.desktop";
      "video/mp4" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "audio/mpeg" = "mpv.desktop";
      "audio/flac" = "mpv.desktop";
      "inode/directory" = "nemo.desktop";
    };
  };

  # === USB Auto-Mount ===
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "never"; # no tray icon, just auto-mount
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
    # Tell XDG portal to report dark mode (fixes wezterm appearance warning)
    "org/gnome/desktop/interface" = {
      color-scheme = lib.mkForce "prefer-dark";
      gtk-theme = lib.mkForce "Gruvbox-Dark";
      icon-theme = lib.mkForce "Papirus-Dark";
    };
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
