{
  lib,
  pkgs,
  values,
  ...
}:

let
  themes = import ../../../../shared/lib/theme { inherit lib; };

  zellijThemeName = themes.getAppTheme "zellij" values.theme.colorscheme values.theme.variant;

  zjstatusUrl = "https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm";
  vimZellijNavigatorUrl = "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm";

  defaultLayoutContent = ''
    layout {
        pane split_direction="vertical" {
            pane
        }
        pane size=1 borderless=true {
            plugin location="${zjstatusUrl}" {
                hide_frame_for_single_pane "false"

                mode_default_to_mode "tmux"

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
    theme "${zellijThemeName}"

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

    keybinds clear-defaults=true {
        normal {
            // Mode switching
            bind "Ctrl a" "a" { SwitchToMode "locked"; }
            bind "Ctrl a" "r" { SwitchToMode "resize"; }
            bind "Ctrl a" "S" { SwitchToMode "scroll"; }
            bind "Ctrl a" "/" { SwitchToMode "search"; }

            // Pane navigation (vim keys)
            bind "Ctrl a" "h" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "move_focus";
                    payload "left";
                };
            }
            bind "Ctrl a" "j" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "move_focus";
                    payload "down";
                };
            }
            bind "Ctrl a" "k" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "move_focus";
                    payload "up";
                };
            }
            bind "Ctrl a" "l" {
                MessagePlugin "${vimZellijNavigatorUrl}" {
                    name "move_focus";
                    payload "right";
                };
            }

            // Pane splitting
            bind "Ctrl a" "v" { NewPane "Right"; }
            bind "Ctrl a" "s" { NewPane "Down"; }
            bind "Ctrl a" "w" { CloseFocus; }

            // Tab management
            bind "Ctrl a" "t" { NewTab; }
            bind "Ctrl a" "1" { GoToTab 1; }
            bind "Ctrl a" "2" { GoToTab 2; }
            bind "Ctrl a" "3" { GoToTab 3; }
            bind "Ctrl a" "4" { GoToTab 4; }
            bind "Ctrl a" "5" { GoToTab 5; }
            bind "Ctrl a" "6" { GoToTab 6; }

            // Session management
            bind "Ctrl a" "D" { Detach; }
            bind "Ctrl a" "q" { Quit; }
            bind "Ctrl a" "f" { ToggleFocusFullscreen; }
            bind "Ctrl a" "k" { Clear; }
        }

        resize {
            bind "h" { Resize "Increase left"; }
            bind "j" { Resize "Increase down"; }
            bind "k" { Resize "Increase up"; }
            bind "l" { Resize "Increase right"; }
            bind "Esc" { SwitchToMode "normal"; }
        }

        scroll {
            bind "j" { ScrollDown; }
            bind "k" { ScrollUp; }
            bind "Ctrl d" { HalfPageScrollDown; }
            bind "Ctrl u" { HalfPageScrollUp; }
            bind "g" { ScrollToTop; }
            bind "G" { ScrollToBottom; }
            bind "/" { SwitchToMode "search"; }
            bind "Esc" { SwitchToMode "normal"; }
        }

        search {
            bind "n" { Search "down"; }
            bind "N" { Search "up"; }
            bind "Esc" { SwitchToMode "normal"; }
        }

        locked {
            bind "Ctrl a" "Esc" { SwitchToMode "normal"; }
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
