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
      default_shell = pkgs.zsh;
      copy_on_select = true;
      mouse_mode = true;
      show_startup_tips = false;
      scroll_buffer_size = 100000;
      scrollback_editor = "$EDITOR";
      default_mode = "normal";
    };

    extraConfig = ''
      plugins {
          about location="zellij:about"
          compact-bar location="zellij:compact-bar"
          configuration location="zellij:configuration"
          filepicker location="zellij:strider" {
              cwd "/"
          }
          plugin-manager location="zellij:plugin-manager"
          session-manager location="zellij:session-manager"
          status-bar location="zellij:status-bar"
          strider location="zellij:strider"
          tab-bar location="zellij:tab-bar"
          welcome-screen location="zellij:session-manager" {
              welcome_screen true
          }
      }

      keybinds clear-defaults=true {
          normal {
              bind "Super k" { Clear; }
              bind "Ctrl /" { SwitchToMode "entersearch"; SearchInput 0; }
              bind "Ctrl 1" { GoToTab 1; }
              bind "Ctrl 2" { GoToTab 2; }
              bind "Ctrl 3" { GoToTab 3; }
              bind "Ctrl 4" { GoToTab 4; }
              bind "Ctrl 5" { GoToTab 5; }
              bind "Ctrl 6" { GoToTab 6; }
              bind "Ctrl 7" { GoToTab 7; }
              bind "Ctrl 8" { GoToTab 8; }
              bind "Ctrl 9" { GoToTab 9; }
              bind "Ctrl ;" { SwitchToMode "session"; }
              bind "Ctrl D" { Detach; }
              bind "Ctrl O" { ToggleTab; }
              bind "Ctrl W" { CloseTab; }
              bind "Ctrl [" { SwitchToMode "scroll"; }
              bind "Ctrl f" { ToggleFloatingPanes; }
              bind "Ctrl o" { SwitchToMode "session"; }
              bind "Ctrl s" { NewPane "down"; }
              bind "Ctrl t" { NewTab; }
              bind "Ctrl v" { NewPane "right"; }
              bind "Ctrl w" { CloseFocus; }
              bind "Ctrl tab" { GoToNextTab; }
              bind "Ctrl Shift tab" { GoToPreviousTab; }
          }

          locked {
              bind "Ctrl g" { SwitchToMode "normal"; }
          }

          pane {
              bind "f" { ToggleFloatingPanes; SwitchToMode "normal"; }
              bind "h" { MoveFocus "left"; }
              bind "j" { MoveFocus "down"; }
              bind "k" { MoveFocus "up"; }
              bind "l" { MoveFocus "right"; }
              bind "s" { NewPane "down"; SwitchToMode "normal"; }
              bind "v" { NewPane "right"; SwitchToMode "normal"; }
              bind "x" { CloseFocus; SwitchToMode "normal"; }
          }

          scroll {
              bind "g" { ScrollToTop; }
              bind "G" { ScrollToBottom; }
              bind "j" { ScrollDown; }
              bind "k" { ScrollUp; }
              bind "/" { SwitchToMode "entersearch"; SearchInput 0; }
              bind "Ctrl /" { SwitchToMode "search"; SearchInput 0; }
              bind "e" { EditScrollback; SwitchToMode "normal"; }
          }

          search {
              bind "N" { Search "up"; }
              bind "c" { SearchToggleOption "CaseSensitivity"; }
              bind "n" { Search "down"; }
              bind "o" { SearchToggleOption "Wrap"; }
              bind "p" { Search "up"; }
              bind "w" { SearchToggleOption "WholeWord"; }
          }

          session {
              bind "c" {
                  LaunchOrFocusPlugin "configuration" {
                      floating true
                      move_to_focused_tab true
                  }
                  SwitchToMode "normal"
              }
              bind "d" { Detach; }
              bind "p" {
                  LaunchOrFocusPlugin "plugin-manager" {
                      floating true
                      move_to_focused_tab true
                  }
                  SwitchToMode "normal"
              }
              bind "w" {
                  LaunchOrFocusPlugin "session-manager" {
                      floating true
                      move_to_focused_tab true
                  }
                  SwitchToMode "normal"
              }
          }

          shared_except "locked" {
              bind "Ctrl H" {
                  MessagePlugin "file:${vimZellijNavigatorWasm}" {
                      name "resize"
                      payload "left"
                      floating false
                  }
              }
              bind "Ctrl J" {
                  MessagePlugin "file:${vimZellijNavigatorWasm}" {
                      name "resize"
                      payload "down"
                      floating false
                  }
              }
              bind "Ctrl K" {
                  MessagePlugin "file:${vimZellijNavigatorWasm}" {
                      name "resize"
                      payload "up"
                      floating false
                  }
              }
              bind "Ctrl L" {
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

          shared_except "locked" "resize" "tab" "move" "prompt" "tmux" {
              bind "Ctrl g" { SwitchToMode "locked"; }
          }

          shared_among "pane" "renametab" "renamepane" {
              bind "enter" { SwitchToMode "normal"; }
          }

          shared_among "pane" "renametab" "renamepane" "session" {
              bind "Ctrl c" { SwitchToMode "normal"; }
          }

          shared_among "pane" "session" {
              bind "esc" { SwitchToMode "normal"; }
          }

          shared_among "scroll" "search" {
              bind "PageDown" { PageScrollDown; }
              bind "PageUp" { PageScrollUp; }
              bind "Ctrl c" { ScrollToBottom; SwitchToMode "normal"; }
              bind "d" { HalfPageScrollDown; }
              bind "j" { ScrollDown; }
              bind "k" { ScrollUp; }
              bind "u" { HalfPageScrollUp; }
              bind "esc" { ScrollToBottom; SwitchToMode "normal"; }
              bind "enter" { ScrollToBottom; SwitchToMode "normal"; }
          }

          entersearch {
              bind "Ctrl c" { SwitchToMode "scroll"; }
              bind "esc" { SwitchToMode "scroll"; }
              bind "enter" { SwitchToMode "search"; }
          }

          renametab {
              bind "esc" { UndoRenameTab; SwitchToMode "normal"; }
          }

          renamepane {
              bind "esc" { UndoRenamePane; SwitchToMode "normal"; }
          }
      }
    '';

    layouts = {
      default = ''
        layout {
            default_tab_template {
                children
                pane size=2 borderless=false {
                    plugin location="file:${zjstatusWasm}" {
                        format_left   "#[bg=2,fg=0] {command_host_os_icon} {session} {mode}"
                        format_center "{tabs}"
                        format_right  "#[bg=2,fg=0] {swap_layout} │ {datetime} "
                        format_space  "#[bg=2]"

                        mode_normal        "#[bg=2,fg=2]│#[bg=2,fg=0] NORMAL "
                        mode_locked        "#[bg=2,fg=2]│#[bg=1,fg=0] LOCKED "
                        mode_resize        "#[bg=2,fg=2]│#[bg=5,fg=0] RESIZE "
                        mode_pane          "#[bg=2,fg=2]│#[bg=5,fg=0] PANE "
                        mode_tab           "#[bg=2,fg=2]│#[bg=5,fg=0] TAB "
                        mode_scroll        "#[bg=2,fg=2]│#[bg=5,fg=0] SCROLL "
                        mode_enter_search  "#[bg=2,fg=2]│#[bg=5,fg=0] SEARCH "
                        mode_search        "#[bg=2,fg=2]│#[bg=5,fg=0] SEARCH "
                        mode_rename_tab    "#[bg=2,fg=2]│#[bg=5,fg=0] RENAME_TAB "
                        mode_rename_pane   "#[bg=2,fg=2]│#[bg=5,fg=0] RENAME_PANE "
                        mode_session       "#[bg=2,fg=2]│#[bg=5,fg=0] SESSION "
                        mode_move          "#[bg=2,fg=2]│#[bg=5,fg=0] MOVE "
                        mode_prompt        "#[bg=2,fg=2]│#[bg=5,fg=0] PROMPT "
                        mode_tmux          "#[bg=2,fg=2]│#[bg=4,fg=0] TMUX "

                        tab_normal "#[bg=2,fg=0] {name} {sync_indicator}{fullscreen_indicator}{floating_indicator}#[bg=2,fg=0]"
                        tab_active "#[bg=0,fg=2] {name} {sync_indicator}{fullscreen_indicator}{floating_indicator}#[bg=0,fg=2]"

                        tab_sync_indicator       "󰓦 "
                        tab_fullscreen_indicator "󱟱 "
                        tab_floating_indicator   "󰉈 "

                        command_host_os_icon_command "echo 󱄅"
                        command_host_os_icon_format "{stdout}"
                        command_host_os_icon_interval "0"
                        command_host_os_icon_rendermode "static"

                        datetime          "{format}"
                        datetime_format   "%H:%M %d-%b-%y"
                        datetime_timezone "America/Los_Angeles"
                    }
                }
            }
        }
      '';
    };
  };
}
