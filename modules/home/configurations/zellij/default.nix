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

  defaultLayoutContent = ''
    layout {
        pane split_direction="vertical" {
            pane
        }
        pane size=1 borderless=true {
            plugin location="${zjstatusUrl}" {
                format_left   "{mode}#[bg=default] {session} {tabs}"
                format_center ""
                format_right  "#[fg=#${colors.base03},bg=default]{command_git_branch}"
                format_space  ""
                format_hide_on_overlength "true"
                format_precedence "lrc"

                border_enabled  "true"
                hide_frame_for_single_pane "false"

                mode_normal        "#[bg=#${colors.base0D},fg=#${colors.base00},bold] NORMAL #[bg=default,fg=#${colors.base0D}]"
                mode_locked        "#[bg=#${colors.base08},fg=#${colors.base00},bold] LOCKED #[bg=default,fg=#${colors.base08}]"
                mode_resize        "#[bg=#${colors.base0E},fg=#${colors.base00},bold] RESIZE #[bg=default,fg=#${colors.base0E}]"
                mode_pane          "#[bg=#${colors.base0B},fg=#${colors.base00},bold] PANE #[bg=default,fg=#${colors.base0B}]"
                mode_tab           "#[bg=#${colors.base0A},fg=#${colors.base00},bold] TAB #[bg=default,fg=#${colors.base0A}]"
                mode_scroll        "#[bg=#${colors.base0C},fg=#${colors.base00},bold] SCROLL #[bg=default,fg=#${colors.base0C}]"
                mode_enter_search  "#[bg=#${colors.base09},fg=#${colors.base00},bold] SEARCH #[bg=default,fg=#${colors.base09}]"
                mode_search        "#[bg=#${colors.base09},fg=#${colors.base00},bold] SEARCH #[bg=default,fg=#${colors.base09}]"
                mode_rename_tab    "#[bg=#${colors.base0A},fg=#${colors.base00},bold] RENAME #[bg=default,fg=#${colors.base0A}]"
                mode_rename_pane   "#[bg=#${colors.base0B},fg=#${colors.base00},bold] RENAME #[bg=default,fg=#${colors.base0B}]"
                mode_session       "#[bg=#${colors.base0D},fg=#${colors.base00},bold] SESSION #[bg=default,fg=#${colors.base0D}]"
                mode_move          "#[bg=#${colors.base0E},fg=#${colors.base00},bold] MOVE #[bg=default,fg=#${colors.base0E}]"
                mode_prompt        "#[bg=#${colors.base08},fg=#${colors.base00},bold] PROMPT #[bg=default,fg=#${colors.base08}]"
                mode_tmux          "#[bg=#${colors.base0B},fg=#${colors.base00},bold] TMUX #[bg=default,fg=#${colors.base0B}]"

                tab_normal              "#[fg=#${colors.base03}] {index} {name} "
                tab_normal_fullscreen   "#[fg=#${colors.base03}] {index} {name} [] "
                tab_normal_sync         "#[fg=#${colors.base03}] {index} {name}  "
                tab_active              "#[fg=#${colors.base0D},bold] {index} {name} #[fg=#${colors.base03}]│"
                tab_active_fullscreen   "#[fg=#${colors.base0D},bold] {index} {name} [] #[fg=#${colors.base03}]│"
                tab_active_sync         "#[fg=#${colors.base0D},bold] {index} {name}  #[fg=#${colors.base03}]│"

                command_git_branch_command     "git rev-parse --abbrev-ref HEAD 2>/dev/null"
                command_git_branch_format      " {stdout}"
                command_git_branch_interval    "10"
                command_git_branch_rendermode  "static"
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
    session_serialization false
    show_startup_tips false

    scroll_buffer_size 100000
    scrollback_editor "nvim"
    scrollback_lines_to_serialize 50000
    copy_on_select true

    ui {
        pane_frames {
            rounded_corners false
            hide_session_name false
        }
    }
    pane_frames true

    default_mode "normal"

    load_plugins "session-manager" "zjstatus" "vim-zellij-navigator"
    plugins {
        session-manager {
            location "zellij:session-manager"
        }
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
        location "zellij:session-manager" {
            _allow_all_permissions true
        }
    }

    keybinds clear-defaults=true {
        normal {
            // Mode switching
            bind "Ctrl g" { SwitchToMode "locked"; }

            // Scrollback and search
            bind "Ctrl Esc" { SwitchToMode "scroll"; }
            bind "Ctrl /" { SwitchToMode "entersearch"; }

            // Pane navigation (vim keys)
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

            // Pane resize
            bind "Ctrl Shift h" { Resize "Increase left"; }
            bind "Ctrl Shift j" { Resize "Increase down"; }
            bind "Ctrl Shift k" { Resize "Increase up"; }
            bind "Ctrl Shift l" { Resize "Increase right"; }

            // Pane splitting
            bind "Ctrl v" { NewPane "Right"; }
            bind "Ctrl s" { NewPane "Down"; }
            bind "Ctrl w" { CloseFocus; }

            // Tab management
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

            // Session management
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
            // Vim-style navigation
            bind "j" { ScrollDown; }
            bind "k" { ScrollUp; }
            bind "h" { PageScrollUp; }
            bind "l" { PageScrollDown; }

            // Arrow keys
            bind "Down" { ScrollDown; }
            bind "Up" { ScrollUp; }

            // Page movement
            bind "Ctrl d" { HalfPageScrollDown; }
            bind "Ctrl u" { HalfPageScrollUp; }
            bind "Ctrl f" { PageScrollDown; }
            bind "Ctrl b" { PageScrollUp; }
            bind "PageDown" { PageScrollDown; }
            bind "PageUp" { PageScrollUp; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }

            // Jump to top/bottom
            bind "g" { ScrollToTop; }
            bind "G" { ScrollToBottom; }
            bind "Home" { ScrollToTop; }
            bind "End" { ScrollToBottom; }

            // Search
            bind "/" { SwitchToMode "entersearch"; }
            bind "Ctrl /" { SwitchToMode "entersearch"; }
            bind "n" { Search "down"; }
            bind "N" { Search "up"; }

            // Edit scrollback in $EDITOR
            bind "e" { EditScrollback; SwitchToMode "normal"; }

            // Copy mode
            bind "v" { Copy; }
            bind "y" { Copy; }

            // Exit scroll mode
            bind "Esc" { SwitchToMode "normal"; }
            bind "q" { SwitchToMode "normal"; }
            bind "i" { SwitchToMode "normal"; }
            bind "Enter" { SwitchToMode "normal"; }
        }

        entersearch {
            // This mode is for typing the search query
            bind "Ctrl c" { ScrollToBottom; SwitchToMode "normal"; }
            bind "Esc" { ScrollToBottom; SwitchToMode "normal"; }
            bind "Enter" { SwitchToMode "search"; }
        }

        search {
            // This mode is for navigating search results
            bind "n" { Search "down"; }
            bind "N" { Search "up"; }
            bind "j" { Search "down"; }
            bind "k" { Search "up"; }
            bind "Down" { Search "down"; }
            bind "Up" { Search "up"; }

            // Page scrolling while searching
            bind "Ctrl d" { HalfPageScrollDown; }
            bind "Ctrl u" { HalfPageScrollUp; }
            bind "Ctrl f" { PageScrollDown; }
            bind "Ctrl b" { PageScrollUp; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }
            bind "h" { PageScrollUp; }
            bind "l" { PageScrollDown; }

            // Search options
            bind "c" { SearchToggleOption "CaseSensitivity"; }
            bind "w" { SearchToggleOption "Wrap"; }
            bind "o" { SearchToggleOption "WholeWord"; }

            // Exit search
            bind "Esc" { ScrollToBottom; SwitchToMode "normal"; }
            bind "Enter" { SwitchToMode "scroll"; }
            bind "q" { ScrollToBottom; SwitchToMode "normal"; }
        }

        locked {
            bind "Ctrl g" { SwitchToMode "normal"; }
        }
    }
  '';

  autoAttachScript = ''
    #!/usr/bin/env zsh
    # Auto-attach to Zellij when connecting via SSH (Lima)

    should_run_zellij() {
      [[ -z "$ZELLIJ" ]] &&
        [[ -z "$TMUX" ]] &&
        [[ "$TERM_PROGRAM" != "WezTerm" ]] &&
        [[ "$TERM_PROGRAM" != "vscode" ]] &&
        [[ -z "$NVIM" ]]
    }

    if [[ $- == *i* && "$SHLVL" -eq 1 ]]; then
      if should_run_zellij && command -v zellij > /dev/null 2>&1; then
        SESSION_NAME="''${ZELLIJ_SESSION:-$(basename "$PWD")}"

        if zellij list-sessions 2>/dev/null | grep -q "^$SESSION_NAME"; then
          exec zellij attach "$SESSION_NAME"
        else
          exec zellij attach --create "$SESSION_NAME"
        fi
      fi
    fi
  '';
in
{
  home.packages = [ pkgs.zellij ];

  xdg.configFile."zellij/config.kdl" = {
    text = configContent;
  };

  xdg.configFile."zellij/layouts/default.kdl" = {
    text = defaultLayoutContent;
  };

  xdg.configFile."zsh/extras/zellij.sh" = {
    text = autoAttachScript;
    executable = true;
  };
}
