{
  pkgs,
  ...
}:

let
  zjstatusWasm = pkgs.fetchurl {
    url = "https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm";
    sha256 = "0lyxah0pzgw57wbrvfz2y0bjrna9bgmsw9z9f898dgqw1g92dr2d";
    name = "zjstatus.wasm";
  };

  vimZellijNavigatorWasm = pkgs.fetchurl {
    url = "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm";
    sha256 = "13f54hf77bwcqhsbmkvpv07pwn3mblyljx15my66j6kw5zva5rbp";
    name = "vim-zellij-navigator.wasm";
  };
in
{
  stylix.targets.zellij.enable = true;

  programs.zellij = {
    enable = true;

    settings = {
      copy_on_select = true;
      default_mode = "normal";
      mouse_mode = true;
      scroll_buffer_size = 100000;
      scrollback_editor = "${pkgs.neovim}/bin/nvim";
      show_startup_tips = false;
    };

    extraConfig = ''
      keybinds clear-defaults=true {
          normal {
              bind "Ctrl g" { SwitchToMode "locked"; }

              // Like sending "Ctrl l" instead of normal clear
              bind "Super k" { Write 12; }

              bind "Ctrl /" { SwitchToMode "entersearch"; SearchInput 0; }
              bind "Ctrl Esc" { EditScrollback; SwitchToMode "normal"; }
              bind "Ctrl ;" {
                  LaunchOrFocusPlugin "session-manager" {
                      floating true
                      move_to_focused_tab true
                  }
                  SwitchToMode "normal"
              }

              bind "Ctrl f" { ToggleFloatingPanes; }
              bind "Ctrl s" { NewPane "down"; }
              bind "Ctrl v" { NewPane "right"; }

              bind "Ctrl t" { NewTab; }
              bind "Super t" { NewTab; }
              bind "Ctrl 1" { GoToTab 1; }
              bind "Ctrl 2" { GoToTab 2; }
              bind "Ctrl 3" { GoToTab 3; }
              bind "Ctrl 4" { GoToTab 4; }
              bind "Ctrl 5" { GoToTab 5; }
              bind "Ctrl 6" { GoToTab 6; }
              bind "Ctrl 7" { GoToTab 7; }
              bind "Ctrl 8" { GoToTab 8; }
              bind "Ctrl 9" { GoToTab 9; }
              bind "Super 1" { GoToTab 1; }
              bind "Super 2" { GoToTab 2; }
              bind "Super 3" { GoToTab 3; }
              bind "Super 4" { GoToTab 4; }
              bind "Super 5" { GoToTab 5; }
              bind "Super 6" { GoToTab 6; }
              bind "Super 7" { GoToTab 7; }
              bind "Super 8" { GoToTab 8; }
              bind "Super 9" { GoToTab 9; }

              bind "Ctrl d" { HalfPageScrollDown; }
              bind "Ctrl u" { HalfPageScrollUp; }

              bind "Ctrl Shift d" { Detach; }

              bind "Ctrl w" { CloseFocus; }
              bind "Super w" { CloseFocus; }

              bind "Ctrl tab" { GoToNextTab; }
              bind "Super tab" { GoToNextTab; }
              bind "Ctrl Shift tab" { GoToPreviousTab; }
              bind "Super Shift tab" { GoToPreviousTab; }
          }

          locked {
              bind "Ctrl g" { SwitchToMode "normal"; }
          }

          search {
              bind "Shift n" { Search "up"; }
              bind "c" { SearchToggleOption "CaseSensitivity"; }
              bind "d" { HalfPageScrollDown; }
              bind "esc" { ScrollToBottom; SwitchToMode "normal"; }
              bind "j" { ScrollDown; }
              bind "k" { ScrollUp; }
              bind "n" { Search "down"; }
              bind "o" { SearchToggleOption "Wrap"; }
              bind "p" { Search "up"; }
              bind "u" { HalfPageScrollUp; }
              bind "w" { SearchToggleOption "WholeWord"; }
          }

          shared_except "locked" {
              bind "Ctrl Shift h" {
                  MessagePlugin "file:${vimZellijNavigatorWasm}" {
                      name "resize"
                      payload "left"
                      floating false
                  }
              }
              bind "Ctrl shift j" {
                  MessagePlugin "file:${vimZellijNavigatorWasm}" {
                      name "resize"
                      payload "down"
                      floating false
                  }
              }
              bind "Ctrl shift k" {
                  MessagePlugin "file:${vimZellijNavigatorWasm}" {
                      name "resize"
                      payload "up"
                      floating false
                  }
              }
              bind "Ctrl Shift l" {
                  MessagePlugin "file:${vimZellijNavigatorWasm}" {
                      name "resize"
                      payload "right"
                      floating false
                  }
              }
              bind "Ctrl h" {
                  MessagePlugin "file:${vimZellijNavigatorWasm}" {
                      name "move_focus"
                      payload "left"
                      floating false
                  }
              }
              bind "Ctrl j" {
                  MessagePlugin "file:${vimZellijNavigatorWasm}" {
                      name "move_focus"
                      payload "down"
                      floating false
                  }
              }
              bind "Ctrl k" {
                  MessagePlugin "file:${vimZellijNavigatorWasm}" {
                      name "move_focus"
                      payload "up"
                      floating false
                  }
              }
              bind "Ctrl l" {
                  MessagePlugin "file:${vimZellijNavigatorWasm}" {
                      name "move_focus"
                      payload "right"
                      floating false
                  }
              }
          }
      }
    '';

    layouts = {
      default = ''
        layout {
            default_tab_template {
                children
                pane size=1 borderless=true {
                    plugin location="file:${zjstatusWasm}" {

                        border_enabled  "true"
                        border_char     "─"
                        border_format   "#[fg=2]{char}"
                        border_position "top"

                        format_left   "#[fg=4]󰄚 {command_hostname} #[fg=8]{tabs}"
                        format_center "{mode}"
                        format_right  "#[fg=4,bold]󰓥 {session}"
                        format_space  ""

                        mode_normal        "#[fg=2]<  NORMAL >"
                        mode_locked        "#[fg=1,bold]<  LOCKED >"
                        mode_scroll        "#[fg=5,bold]<  SCROLL >"
                        mode_enter_search  "#[fg=4,bold]<  SEARCH >"
                        mode_search        "#[fg=4,bold]<  SEARCH >"

                        tab_normal              "#[fg=8] {name}{fullscreen_indicator}{floating_indicator}{sync_indicator}"
                        tab_active              "#[fg=4,bold] {name}{fullscreen_indicator}{floating_indicator}{sync_indicator}"
                        tab_fullscreen_indicator " 󱟱"
                        tab_floating_indicator   " 󰉈"
                        tab_sync_indicator       " 󰓦"

                        command_hostname_command     "hostname"
                        command_hostname_format      "{stdout}"
                        command_hostname_interval    "0"
                        command_hostname_rendermode  "static"
                    }
                }
            }
        }
      '';
    };
  };
}
