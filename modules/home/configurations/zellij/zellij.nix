{
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };

  zellijThemeName = themes.getAppTheme "zellij" values.theme.colorscheme values.theme.variant;

  zjstatusUrl = "https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm";
  zjstatusHintsUrl = "https://github.com/b0o/zjstatus-hints/releases/latest/download/zjstatus-hints.wasm";
  vimZellijNavigatorUrl = "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm";
  roomUrl = "https://github.com/rvcas/room/releases/latest/download/room.wasm";

  defaultLayoutContent = ''
    layout {
        pane split_direction="vertical" {
            pane
        }
        pane size=1 borderless=true {
            plugin location="${zjstatusUrl}" {
                format_left   "{mode} #[fg=#89B4FA,bold]{session}"
                format_center "{tabs}"
                format_right  "{datetime}"
                format_space  ""

                border_enabled  "false"
                border_char     "─"
                border_format   "#[fg=#6C7086]{char}"
                border_position "top"

                hide_frame_for_single_pane "false"

                mode_normal        "#[bg=#89B4FA] NORMAL "
                mode_locked        "#[bg=#F38BA8] LOCKED "
                mode_resize        "#[bg=#FAB387] RESIZE "
                mode_pane          "#[bg=#A6E3A1] PANE "
                mode_tab           "#[bg=#F9E2AF] TAB "
                mode_scroll        "#[bg=#CBA6F7] SCROLL "
                mode_enter_search  "#[bg=#94E2D5] SEARCH "
                mode_search        "#[bg=#94E2D5] SEARCH "
                mode_rename_tab    "#[bg=#F2CDCD] RENAME "
                mode_rename_pane   "#[bg=#F2CDCD] RENAME "
                mode_session       "#[bg=#EBA0AC] SESSION "
                mode_move          "#[bg=#F38BA8] MOVE "
                mode_prompt        "#[bg=#A6E3A1] PROMPT "
                mode_tmux          "#[bg=#FFC387] TMUX "

                tab_normal              "#[fg=#6C7086] {index} {name} {floating_indicator}"
                tab_normal_fullscreen   "#[fg=#6C7086] {index} {name} {fullscreen_indicator}"
                tab_normal_sync         "#[fg=#6C7086] {index} {name} {sync_indicator}"
                tab_active              "#[fg=#9399B2,bold,italic] {index} {name} {floating_indicator}"
                tab_active_fullscreen   "#[fg=#9399B2,bold,italic] {index} {name} {fullscreen_indicator}"
                tab_active_sync         "#[fg=#9399B2,bold,italic] {index} {name} {sync_indicator}"

                tab_fullscreen_indicator "□ "
                tab_sync_indicator       "  "
                tab_floating_indicator   "󰉈 "

                datetime        "#[fg=#6C7086,bold] {format} "
                datetime_format "%H:%M"
                datetime_timezone "America/Los_Angeles"
            }
        }
    }
  '';

  configContent = ''
    default_shell "zsh"
    copy_clipboard "primary"
    copy_command "pbcopy"
    mouse_mode true
    on_force_close "detach"
    simplified_ui true
    auto_layout true
    session_serialization true
    show_startup_tips false

    scroll_buffer_size 100000
    scrollback_editor "nvim"
    scrollback_lines_to_serialize 50000
    copy_on_select false

    ui {
        pane_frames {
            rounded_corners true
            hide_session_name false
        }
    }
    pane_frames true

    default_mode "normal"
    theme "${zellijThemeName}"

    load_plugins "session-manager" "zjstatus-hints" "vim-zellij-navigator"
    plugins {
        session-manager {
            location "zellij:session-manager"
        }
        zjstatus-hints {
            location "${zjstatusHintsUrl}"
            max_length 80
            overflow_str "..."
            pipe_name "zjstatus_hints"
            hide_in_base_mode false
        }
        vim-zellij-navigator {
            location "${vimZellijNavigatorUrl}"
        }
    }

    keybinds clear-defaults=true {
        normal {
            bind "Ctrl a" { SwitchToMode "locked"; }
            bind "Ctrl r" { SwitchToMode "resize"; }
            bind "Ctrl S" { SwitchToMode "scroll"; }
            bind "Ctrl :" { SwitchToMode "session"; }
            bind "Ctrl /" { SwitchToMode "search"; }

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

            bind "Ctrl t" { NewTab; }
            bind "Ctrl 1" { GoToTab 1; }
            bind "Ctrl 2" { GoToTab 2; }
            bind "Ctrl 3" { GoToTab 3; }
            bind "Ctrl 4" { GoToTab 4; }
            bind "Ctrl 5" { GoToTab 5; }
            bind "Ctrl 6" { GoToTab 6; }
            bind "Ctrl 7" { GoToTab 7; }
            bind "Ctrl 8" { GoToTab 8; }
            bind "Super t" { NewTab; }
            bind "Super 1" { GoToTab 1; }
            bind "Super 2" { GoToTab 2; }
            bind "Super 3" { GoToTab 3; }
            bind "Super 4" { GoToTab 4; }
            bind "Super 5" { GoToTab 5; }
            bind "Super 6" { GoToTab 6; }
            bind "Super 7" { GoToTab 7; }
            bind "Super 8" { GoToTab 8; }
            bind "Super Shift Left" { GoToPreviousTab; }
            bind "Super Shift Right" { GoToNextTab; }

            bind "Ctrl u" { HalfPageScrollUp; }
            bind "Ctrl d" { HalfPageScrollDown; }
            bind "Ctrl Shift u" { PageScrollUp; }
            bind "Ctrl Shift d" { PageScrollDown; }

            bind "Ctrl w" { CloseFocus; }
            bind "Ctrl \\" { TogglePaneFrames; ToggleActiveSyncTab; }
            bind "Ctrl Enter" { ToggleFloatingPanes; }
            bind "Ctrl f" { ToggleFocusFullscreen; }
            bind "Ctrl z" { TogglePaneFrames; }
            bind "Ctrl q" { Quit; }
            bind "Ctrl D" { Detach; }

            bind "Super k" { Clear; }

            // Plugin Launch
            bind "Ctrl y" {
                LaunchOrFocusPlugin "${roomUrl}" {
                    floating true;
                    ignore_case true;
                    quick_jump true;
                }
            }
        }

        resize {
            bind "h" { Resize "Increase left"; }
            bind "j" { Resize "Increase down"; }
            bind "k" { Resize "Increase up"; }
            bind "l" { Resize "Increase right"; }
            bind "Down" { Resize "Increase down"; }
            bind "Up" { Resize "Increase up"; }
            bind "Right" { Resize "Increase right"; }
            bind "Left" { Resize "Increase left"; }
            bind "=" { Resize "Increase"; }
            bind "-" { Resize "Decrease"; }
            bind "Esc" { SwitchToMode "normal"; }
            bind "Enter" { SwitchToMode "normal"; }
            bind "q" { SwitchToMode "normal"; }
        }

        scroll {
            bind "j" { ScrollDown; }
            bind "k" { ScrollUp; }
            bind "Down" { ScrollDown; }
            bind "Up" { ScrollUp; }
            bind "Ctrl d" { HalfPageScrollDown; }
            bind "Ctrl u" { HalfPageScrollUp; }
            bind "Ctrl f" { PageScrollDown; }
            bind "Ctrl b" { PageScrollUp; }
            bind "g" { ScrollToTop; }
            bind "G" { ScrollToBottom; }
            bind "/" { SwitchToMode "search"; }
            bind "n" { Search "down"; }
            bind "N" { Search "up"; }
            bind "Esc" { SwitchToMode "normal"; }
            bind "q" { SwitchToMode "normal"; }
            bind "Enter" { SwitchToMode "normal"; }
        }

        search {
            bind "Enter" { SwitchToMode "scroll"; }
            bind "Esc" { ScrollToBottom; SwitchToMode "normal"; }
            bind "j" { Search "down"; }
            bind "k" { Search "up"; }
            bind "Down" { Search "down"; }
            bind "Up" { Search "up"; }
            bind "n" { Search "down"; }
            bind "N" { Search "up"; }
        }

        locked {
            bind "Ctrl a" { SwitchToMode "normal"; }
        }
    }
  '';
in
{
  xdg.configFile."zellij/config.kdl" = {
    text = configContent;
  };

  xdg.configFile."zellij/layouts/default.kdl" = {
    text = defaultLayoutContent;
  };

  xdg.configFile."zsh/extras/zellij.sh" = {
    source = ./zellij.sh;
  };
}
