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
        pane split_direction="vertical" borderless=true {
            pane borderless=true
        }
        pane size=1 borderless=true {
            plugin location="${zjstatusUrl}" {
                format_left   "#[fg=cyan,bg=black,bold][{mode}] #[fg=green,bg=black]{session} #[fg=yellow,bg=black]{command_pwd}"
                format_center "#[fg=blue,bg=black]{tabs}"
                format_right  "#[fg=magenta,bg=black]{pipe_zjstatus_hints}"
                format_space  "#[bg=black]"

                hide_frame_for_single_pane "true"

                // Mode styling
                mode_normal       "#[fg=green,bg=black,bold] NORM "
                mode_locked       "#[fg=red,bg=black,bold] LOCK "
                mode_resize       "#[fg=yellow,bg=black,bold] SIZE "
                mode_pane         "#[fg=blue,bg=black,bold] PANE "
                mode_tab          "#[fg=magenta,bg=black,bold] TAB  "
                mode_scroll       "#[fg=cyan,bg=black,bold] SCRL "
                mode_enter_search "#[fg=white,bg=black,bold] SRCH "
                mode_search       "#[fg=white,bg=black,bold] SRCH "
                mode_rename_tab   "#[fg=magenta,bg=black,bold] REN  "
                mode_rename_pane  "#[fg=blue,bg=black,bold] REN  "
                mode_session      "#[fg=green,bg=black,bold] SESS "
                mode_move         "#[fg=yellow,bg=black,bold] MOVE "
                mode_prompt       "#[fg=white,bg=black,bold] PRMT "
                mode_tmux         "#[fg=orange,bg=black,bold] TMUX "

                // Tab styling
                tab_normal   " #[fg=white,bg=black]{index}:{name} "
                tab_active   " #[fg=black,bg=blue,bold]{index}:{name} "
                tab_separator "#[fg=brightblack,bg=black]│"

                // Commands
                command_pwd_command    "basename $(pwd)"
                command_pwd_format     "{stdout}"
                command_pwd_interval   "1"
                command_pwd_rendermode "static"

                // Pipe configuration
                pipe_zjstatus_hints_format "#[fg=brightblack,bg=black] {output}"
            }
        }
    }
  '';

  compactLayoutContent = ''
    layout {
        pane size=1 borderless=true {
            plugin location="${zjstatusUrl}" {
                format_left   "#[fg=cyan,bg=black,bold][{mode}] #[fg=green,bg=black]{session} #[fg=yellow,bg=black]{command_pwd}"
                format_center "#[fg=blue,bg=black]{tabs}"
                format_right  "#[fg=magenta,bg=black]{pipe_zjstatus_hints}"
                format_space  "#[bg=black]"

                hide_frame_for_single_pane "true"

                // Mode styling
                mode_normal       "#[fg=green,bg=black,bold] NORM "
                mode_locked       "#[fg=red,bg=black,bold] LOCK "
                mode_resize       "#[fg=yellow,bg=black,bold] SIZE "
                mode_pane         "#[fg=blue,bg=black,bold] PANE "
                mode_tab          "#[fg=magenta,bg=black,bold] TAB  "
                mode_scroll       "#[fg=cyan,bg=black,bold] SCRL "
                mode_enter_search "#[fg=white,bg=black,bold] SRCH "
                mode_search       "#[fg=white,bg=black,bold] SRCH "
                mode_rename_tab   "#[fg=magenta,bg=black,bold] REN  "
                mode_rename_pane  "#[fg=blue,bg=black,bold] REN  "
                mode_session      "#[fg=green,bg=black,bold] SESS "
                mode_move         "#[fg=yellow,bg=black,bold] MOVE "
                mode_prompt       "#[fg=white,bg=black,bold] PRMT "
                mode_tmux         "#[fg=orange,bg=black,bold] TMUX "

                // Tab styling
                tab_normal   " #[fg=white,bg=black]{index}:{name} "
                tab_active   " #[fg=black,bg=blue,bold]{index}:{name} "
                tab_separator "#[fg=brightblack,bg=black]│"

                // Commands
                command_pwd_command    "basename $(pwd)"
                command_pwd_format     "{stdout}"
                command_pwd_interval   "1"
                command_pwd_rendermode "static"

                // Pipe configuration
                pipe_zjstatus_hints_format "#[fg=brightblack,bg=black] {output}"
            }
        }
        pane borderless=true
    }
  '';

  configContent = ''
    // General Settings
    default_shell "zsh"
    copy_clipboard "primary"
    copy_command "pbcopy"
    mouse_mode true
    on_force_close "detach"
    simplified_ui true
    auto_layout true
    session_serialization false
    show_startup_tips false

    // Scroll Settings
    scroll_buffer_size 100000
    scrollback_editor "nvim"
    scrollback_lines_to_serialize 50000
    copy_on_select true

    // UI Settings
    ui {
        pane_frames {
            rounded_corners false
            hide_session_name false
        }
    }
    pane_frames false

    // Default to borderless for new panes
    default_mode "normal"
    theme "${zellijThemeName}"

    // Plugin Settings
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

    // Keybindings
    keybinds clear-defaults=true {
        normal {
            // Mode Switching
            bind "Ctrl a" { SwitchToMode "locked"; }
            bind "Ctrl r" { SwitchToMode "resize"; }
            bind "Ctrl S" { SwitchToMode "scroll"; } // Enter scroll mode for scrolling keys
            bind "Ctrl :" { SwitchToMode "session"; }
            bind "Ctrl /" { SwitchToMode "search"; }
            bind "Ctrl ]" { SwitchToMode "search"; }

            // Pane Navigation with vim-zellij-navigator
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

            // Pane Resizing
            bind "Ctrl Shift h" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "resize";
                    payload "left";
                };
            }
            bind "Ctrl Shift j" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "resize";
                    payload "down";
                };
            }
            bind "Ctrl Shift k" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "resize";
                    payload "up";
                };
            }
            bind "Ctrl Shift l" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "resize";
                    payload "right";
                };
            }

            // Pane Splitting
            bind "Ctrl v" { NewPane "right"; }
            bind "Ctrl s" { NewPane "down"; }

            // Tab Management
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

            // Scroll Navigation (compatible with vim-zellij-navigator)
            bind "Ctrl u" { HalfPageScrollUp; }
            bind "Ctrl d" { HalfPageScrollDown; }
            bind "Ctrl Shift u" { PageScrollUp; }
            bind "Ctrl Shift d" { PageScrollDown; }

            // Pane and Session Management
            bind "Ctrl w" { CloseFocus; }
            bind "Ctrl \\" { TogglePaneFrames; ToggleActiveSyncTab; }
            bind "Ctrl Enter" { ToggleFloatingPanes; }
            bind "Ctrl f" { ToggleFocusFullscreen; }
            bind "Ctrl z" { TogglePaneFrames; }
            bind "Ctrl q" { Quit; }
            bind "Ctrl D" { Detach; }

            // Miscellaneous (Note: Ctrl+k used for navigation, only Cmd+k for clear)
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
            // Scroll mode keybindings (no conflict with vim-zellij-navigator)
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

  xdg.configFile."zellij/layouts/compact.kdl" = {
    text = compactLayoutContent;
  };

  xdg.configFile."zsh/extras/zellij.sh" = {
    source = ./zellij.sh;
  };
}
