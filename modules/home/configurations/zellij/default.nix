{
  pkgs,
  config,
  ...
}:

let
  zjstatusUrl = "https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm";
  vimZellijNavigatorUrl = "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm";

  # Use Stylix colors
  inherit (config.lib.stylix) colors;
in
{
  programs.zellij = {
    enable = true;
    enableZshIntegration = false; # We'll handle Ghostty command separately

    settings = {
      default_shell = "zsh";
      copy_clipboard = "primary";
      copy_command = "pbcopy";
      mouse_mode = true;
      on_force_close = "detach";
      simplified_ui = true;
      pane_frames = true;
      auto_layout = true;
      session_serialization = false;

      scroll_buffer_size = 100000;
      scrollback_editor = "nvim";
      copy_on_select = true;

      ui = {
        pane_frames = {
          rounded_corners = false;
          hide_session_name = true;
        };
      };

      default_mode = "normal";

      theme = "custom";
      themes.custom = {
        fg = "#${colors.base05}";
        bg = "#${colors.base00}";
        black = "#${colors.base00}";
        red = "#${colors.base08}";
        green = "#${colors.base0B}";
        yellow = "#${colors.base0A}";
        blue = "#${colors.base0D}";
        magenta = "#${colors.base0E}";
        cyan = "#${colors.base0C}";
        white = "#${colors.base05}";
        orange = "#${colors.base09}";
      };
    };
  };

  # Custom layout with zjstatus
  xdg.configFile."zellij/layouts/default.kdl".text = ''
    layout {
        pane split_direction="vertical" {
            pane
        }
        pane size=1 borderless=true {
            plugin location="${zjstatusUrl}" {
                format_left   "{mode} {tabs}"
                format_center ""
                format_right  ""
                format_space  ""

                border_enabled  "false"
                hide_frame_for_single_pane "true"

                mode_normal        "#[bg=#${colors.base0D},fg=#${colors.base00},bold] NORMAL#[bg=default] "
                mode_locked        "#[bg=#${colors.base08},fg=#${colors.base00},bold] LOCKED#[bg=default] "
                mode_resize        "#[bg=#${colors.base0E},fg=#${colors.base00},bold] RESIZE#[bg=default] "
                mode_pane          "#[bg=#${colors.base0B},fg=#${colors.base00},bold] PANE#[bg=default] "
                mode_tab           "#[bg=#${colors.base0A},fg=#${colors.base00},bold] TAB#[bg=default] "
                mode_scroll        "#[bg=#${colors.base0C},fg=#${colors.base00},bold] SCROLL#[bg=default] "
                mode_enter_search  "#[bg=#${colors.base09},fg=#${colors.base00},bold] SEARCH#[bg=default] "
                mode_search        "#[bg=#${colors.base09},fg=#${colors.base00},bold] SEARCH#[bg=default] "
                mode_session       "#[bg=#${colors.base0D},fg=#${colors.base00},bold] SESSION#[bg=default] "

                tab_normal   " {index} {name} "
                tab_active   "#[fg=#${colors.base0D},bold] {index} {name}#[fg=#${colors.base03}] │"
            }
        }
    }
  '';

  # Custom keybinds config (home-manager doesn't support keybinds in settings yet)
  xdg.configFile."zellij/config.kdl".text = pkgs.lib.mkAfter ''
    load_plugins "zjstatus" "vim-zellij-navigator"
    plugins {
        zjstatus {
            location "${zjstatusUrl}"
        }
        vim-zellij-navigator {
            location "${vimZellijNavigatorUrl}"
        }
    }

    plugin_permissions {
        location "${zjstatusUrl}" {
            _allow_all_permissions true
        }
        location "${vimZellijNavigatorUrl}" {
            _allow_all_permissions true
        }
    }

    keybinds clear-defaults=true {
        normal {
            bind "Ctrl g" { SwitchToMode "locked"; }
            bind "Ctrl Esc" { SwitchToMode "scroll"; }
            bind "Ctrl /" { SwitchToMode "entersearch"; }

            bind "Ctrl h" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "move_focus";
                    payload "left";
                };
            }
            bind "Ctrl j" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "move_focus";
                    payload "down";
                };
            }
            bind "Ctrl k" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "move_focus";
                    payload "up";
                };
            }
            bind "Ctrl l" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "move_focus";
                    payload "right";
                };
            }

            bind "Ctrl Shift h" { Resize "Increase left"; }
            bind "Ctrl Shift j" { Resize "Increase down"; }
            bind "Ctrl Shift k" { Resize "Increase up"; }
            bind "Ctrl Shift l" { Resize "Increase right"; }

            bind "Ctrl v" { NewPane "Right"; }
            bind "Ctrl s" { NewPane "Down"; }
            bind "Ctrl w" { CloseFocus; }

            bind "Ctrl t" { NewTab; }
            bind "Ctrl 1" { GoToTab 1; }
            bind "Ctrl 2" { GoToTab 2; }
            bind "Ctrl 3" { GoToTab 3; }
            bind "Ctrl 4" { GoToTab 4; }
            bind "Ctrl 5" { GoToTab 5; }
            bind "Ctrl 6" { GoToTab 6; }
            bind "Ctrl 7" { GoToTab 7; }
            bind "Ctrl 8" { GoToTab 8; }
            bind "Ctrl 9" { GoToTab 9; }

            bind "Ctrl Shift d" { Detach; }
            bind "Ctrl m" { ToggleFocusFullscreen; }
            bind "Super k" { Clear; }
        }

        resize {
            bind "h" { Resize "Increase left"; }
            bind "j" { Resize "Increase down"; }
            bind "k" { Resize "Increase up"; }
            bind "l" { Resize "Increase right"; }
            bind "Esc" { SwitchToMode "normal"; }
            bind "Enter" { SwitchToMode "normal"; }
            bind "q" { SwitchToMode "normal"; }
        }

        scroll {
            bind "j" { ScrollDown; }
            bind "k" { ScrollUp; }
            bind "h" { PageScrollUp; }
            bind "l" { PageScrollDown; }
            bind "Down" { ScrollDown; }
            bind "Up" { ScrollUp; }
            bind "Ctrl d" { HalfPageScrollDown; }
            bind "Ctrl u" { HalfPageScrollUp; }
            bind "Ctrl f" { PageScrollDown; }
            bind "Ctrl b" { PageScrollUp; }
            bind "PageDown" { PageScrollDown; }
            bind "PageUp" { PageScrollUp; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }
            bind "g" { ScrollToTop; }
            bind "G" { ScrollToBottom; }
            bind "Home" { ScrollToTop; }
            bind "End" { ScrollToBottom; }
            bind "/" { SwitchToMode "entersearch"; }
            bind "Ctrl /" { SwitchToMode "entersearch"; }
            bind "n" { Search "down"; }
            bind "N" { Search "up"; }
            bind "e" { EditScrollback; SwitchToMode "normal"; }
            bind "v" { Copy; }
            bind "y" { Copy; }
            bind "Esc" { SwitchToMode "normal"; }
            bind "q" { SwitchToMode "normal"; }
            bind "i" { SwitchToMode "normal"; }
            bind "Enter" { SwitchToMode "normal"; }
        }

        entersearch {
            bind "Ctrl c" { ScrollToBottom; SwitchToMode "normal"; }
            bind "Esc" { ScrollToBottom; SwitchToMode "normal"; }
            bind "Enter" { SwitchToMode "search"; }
        }

        search {
            bind "n" { Search "down"; }
            bind "N" { Search "up"; }
            bind "j" { Search "down"; }
            bind "k" { Search "up"; }
            bind "Down" { Search "down"; }
            bind "Up" { Search "up"; }
            bind "Ctrl d" { HalfPageScrollDown; }
            bind "Ctrl u" { HalfPageScrollUp; }
            bind "Ctrl f" { PageScrollDown; }
            bind "Ctrl b" { PageScrollUp; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }
            bind "h" { PageScrollUp; }
            bind "l" { PageScrollDown; }
            bind "c" { SearchToggleOption "CaseSensitivity"; }
            bind "w" { SearchToggleOption "Wrap"; }
            bind "o" { SearchToggleOption "WholeWord"; }
            bind "Esc" { ScrollToBottom; SwitchToMode "normal"; }
            bind "Enter" { SwitchToMode "scroll"; }
            bind "q" { ScrollToBottom; SwitchToMode "normal"; }
        }

        locked {
            bind "Ctrl g" { SwitchToMode "normal"; }
        }
    }
  '';
}
