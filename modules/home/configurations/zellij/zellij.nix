{
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };

  zellijThemeName = themes.getAppTheme "zellij" values.theme.colorscheme values.theme.variant;

  defaultLayoutContent = ''
    layout {
        pane split_direction="vertical" {
            pane
        }
        pane size=1 borderless=true {
            plugin location="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" {
                format_left  "#[fg=foreground,bg=background][{session}]  {tabs}"
                format_right "#[fg=foreground,bg=background]{datetime}"
                format_space "#[bg=background]"
                hide_frame_for_single_pane "true"
                tab_normal   "{index}:{name}  "
                tab_active   "{index}:{name}* "
                datetime          " {format} "
                datetime_format   "%H:%M %d-%b-%y"
                datetime_timezone "Europe/Berlin"
            }
        }
    }
  '';

  compactLayoutContent = ''
    layout {
        pane size=1 borderless=true {
            plugin location="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" {
                format_left  "#[fg=foreground,bg=background][{session}]  {tabs}"
                format_right "#[fg=foreground,bg=background]{datetime}"
                format_space "#[bg=background]"
                hide_frame_for_single_pane "true"
                tab_normal   "{index}:{name}  "
                tab_active   "{index}:{name}* "
                datetime          " {format} "
                datetime_format   "%H:%M %d-%b-%y"
                datetime_timezone "Europe/Berlin"
            }
        }
        pane
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
    theme "${zellijThemeName}"

    // Plugin Settings
    load_plugins "session-manager" "zjstatus-hints" "vim-zellij-navigator"
    plugins {
        session-manager {
            location "zellij:session-manager"
        }
        zjstatus-hints {
            location "https://github.com/b0o/zjstatus-hints/releases/latest/download/zjstatus-hints.wasm"
            max_length 80
            overflow_str "…"
            pipe_name "zjstatus_hints"
            hide_in_base_mode false
        }
        vim-zellij-navigator {
            location "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm"
        }
    }

    // Keybindings
    keybinds clear-defaults=true {
        normal {
            // Mode Switching
            bind "Ctrl a" { SwitchToMode "locked"; }
            bind "Ctrl r" { SwitchToMode "resize"; }
            bind "Ctrl S" { SwitchToMode "scroll"; }
            bind "Ctrl :" { SwitchToMode "session"; }
            bind "Ctrl /" { SwitchToMode "search"; }
            bind "Ctrl ]" { SwitchToMode "search"; }

            // Pane Navigation
            bind "Ctrl h" {
                MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
                    name "move_focus";
                    payload "left";
                };
            }
            bind "Ctrl j" {
                MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
                    name "move_focus";
                    payload "down";
                };
            }
            bind "Ctrl k" {
                MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
                    name "move_focus";
                    payload "up";
                };
            }
            bind "Ctrl l" {
                MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
                    name "move_focus";
                    payload "right";
                };
            }

            // Pane Resizing
            bind "Ctrl Shift h" {
                MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
                    name "resize";
                    payload "left";
                };
            }
            bind "Ctrl Shift j" {
                MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
                    name "resize";
                    payload "down";
                };
            }
            bind "Ctrl Shift k" {
                MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
                    name "resize";
                    payload "up";
                };
            }
            bind "Ctrl Shift l" {
                MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
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

            // Scroll Navigation
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

            // Miscellaneous
            bind "Super k" { Clear; }
            bind "Ctrl k" { Clear; }

            // Plugin Launch
            bind "Ctrl y" {
                LaunchOrFocusPlugin "https://github.com/rvcas/room/releases/latest/download/room.wasm" {
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

  xdg.configFile."zellij/layouts/compact.kdl" = {
    text = compactLayoutContent;
  };

  xdg.configFile."zsh/extras/zellij.sh" = {
    source = ./zellij.sh;
  };
}
