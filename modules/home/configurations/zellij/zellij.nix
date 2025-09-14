{
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };

  zellijThemeName = themes.getAppTheme "zellij" values.theme.colorscheme values.theme.variant;
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  semanticColors = themes.getSemanticColors values.theme.colorscheme values.theme.variant;

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
                format_left   "{mode} #[fg=${palette.blue},bold]{session}"
                format_center "{tabs}"
                format_right  "{datetime}"
                format_space  ""

                border_enabled  "true"
                border_char     "─"
                border_format   "#[fg=${palette.surface0}]{char}"
                border_position "top"

                hide_frame_for_single_pane "false"

                mode_normal        ""
                mode_locked        "#[bg=${palette.red},fg=${palette.base},bold] 🔒 "
                mode_resize        "#[bg=${palette.peach},fg=${palette.base},bold] ↔ "
                mode_pane          "#[bg=${palette.green},fg=${palette.base},bold] ◧ "
                mode_tab           "#[bg=${palette.yellow},fg=${palette.base},bold] ⊡ "
                mode_scroll        "#[bg=${palette.mauve},fg=${palette.base},bold] ↕ "
                mode_enter_search  "#[bg=${palette.teal},fg=${palette.base},bold] 🔍 "
                mode_search        "#[bg=${palette.teal},fg=${palette.base},bold] 🔍 "
                mode_rename_tab    "#[bg=${palette.pink},fg=${palette.base},bold] ✏ "
                mode_rename_pane   "#[bg=${palette.pink},fg=${palette.base},bold] ✏ "
                mode_session       "#[bg=${palette.maroon},fg=${palette.base},bold] 🗂 "
                mode_move          "#[bg=${palette.red},fg=${palette.base},bold] ↹ "
                mode_prompt        "#[bg=${palette.green},fg=${palette.base},bold] ❯ "
                mode_tmux          "#[bg=${palette.peach},fg=${palette.base},bold] T "

                tab_normal              "#[fg=${palette.surface2}] {name} "
                tab_normal_fullscreen   "#[fg=${palette.surface2}] {name} {fullscreen_indicator}"
                tab_normal_sync         "#[fg=${palette.surface2}] {name} {sync_indicator}"
                tab_active              "#[fg=${palette.blue},bold] {name} "
                tab_active_fullscreen   "#[fg=${palette.blue},bold] {name} {fullscreen_indicator}"
                tab_active_sync         "#[fg=${palette.blue},bold] {name} {sync_indicator}"

                tab_separator           "#[fg=${palette.surface0}]│"
                tab_fullscreen_indicator "□ "
                tab_sync_indicator       "⟳ "
                tab_floating_indicator   "◈ "

                datetime        "#[fg=${palette.subtext0}] {format} "
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
            bind "Super /" { SwitchToMode "search"; }
            bind "Ctrl [" { SwitchToMode "scroll"; }

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
            bind "Ctrl l" { Clear; }

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
            bind "v" { SwitchToMode "entersearch"; }
            bind "s" { EditScrollback; SwitchToMode "normal"; }
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
