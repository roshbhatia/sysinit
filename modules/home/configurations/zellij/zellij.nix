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
                format_left   "{mode} {session}"
                format_center "{tabs}"
                format_space  ""

                border_enabled  "false"
                border_char     "─"
                border_position "top"

                hide_frame_for_single_pane "false"

                mode_normal        " NORMAL "
                mode_locked        " LOCKED "
                mode_resize        " RESIZE "
                mode_pane          " PANE "
                mode_tab           " TAB "
                mode_scroll        " SCROLL "
                mode_enter_search  " SEARCH "
                mode_search        " SEARCH "
                mode_rename_tab    " RENAME "
                mode_rename_pane   " RENAME "
                mode_session       " SESSION "
                mode_move          " MOVE "
                mode_prompt        " PROMPT "
                mode_tmux          " TMUX "

                tab_normal              " {index} {name} {floating_indicator}"
                tab_normal_fullscreen   " {index} {name} {fullscreen_indicator}"
                tab_normal_sync         " {index} {name} {sync_indicator}"
                tab_active              " {index} {name} {floating_indicator}"
                tab_active_fullscreen   " {index} {name} {fullscreen_indicator}"
                tab_active_sync         " {index} {name} {sync_indicator}"

                tab_fullscreen_indicator "□ "
                tab_sync_indicator       "  "
                tab_floating_indicator   "󰉈 "
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
                    move_mod "ctrl";
                };
            }
            bind "Ctrl j" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "move_focus";
                    payload "down";
                    move_mod "ctrl";
                };
            }
            bind "Ctrl k" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "move_focus";
                    payload "up";
                    move_mod "ctrl";
                };
            }
            bind "Ctrl l" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "move_focus";
                    payload "right";
                    move_mod "ctrl";
                };
            }

            bind "Ctrl Shift h" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "resize";
                    payload "left";
                    resize_mod "ctrl+shift";
                };
            }
            bind "Ctrl Shift j" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "resize";
                    payload "down";
                    resize_mod "ctrl+shift";
                };
            }
            bind "Ctrl Shift k" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "resize";
                    payload "up";
                    resize_mod "ctrl+shift";
                };
            }
            bind "Ctrl Shift l" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "resize";
                    payload "right";
                    resize_mod "ctrl+shift";
                };
            }

            bind "Ctrl v" { NewPane "Right"; }
            bind "Ctrl s" { NewPane "Down"; }

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

            bind "Ctrl u" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "send_keys";
                    payload "ctrl+u";
                    move_mod "ctrl";
                };
            }
            bind "Ctrl d" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "send_keys";
                    payload "ctrl+d";
                    move_mod "ctrl";
                };
            }
            bind "Ctrl Shift u" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "send_keys";
                    payload "ctrl+shift+u";
                    move_mod "ctrl+shift";
                };
            }
            bind "Ctrl Shift d" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "send_keys";
                    payload "ctrl+shift+d";
                    move_mod "ctrl+shift";
                };
            }
            bind "Ctrl w" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "send_keys";
                    payload "ctrl+w";
                    move_mod "ctrl";
                };
            }

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
