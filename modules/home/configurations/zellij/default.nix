{
  config,
  pkgs,
  ...
}:

let
  zjstatusUrl = "https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm";
  vimZellijNavigatorUrl = "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm";

  inherit (config.lib.stylix) colors;
in
{
  programs.zellij = {
    enable = true;
    enableZshIntegration = false; # We'll use custom integration below

    settings = {
      default_shell = "${pkgs.zsh}/bin/zsh";
      auto_layout = true;
      mouse_mode = false;
      on_force_close = "detach";
      show_startup_tips = false;
      simplified_ui = true;

      scroll_buffer_size = 200000;
      scrollback_editor = "${pkgs.neovim-unwrapped}/bin/nvim";
    };

    layouts.default = ''
      layout {
          pane split_direction="vertical" {
              pane
          }

          pane size=1 borderless=true {
              plugin location="${zjstatusUrl}" {
                  format_left  "#[bg=#${colors.base01}]{mode} {tabs}"
                  format_right "#[bg=#${colors.base01}]{session}#[bg=#${colors.base01}] "
                  format_space "#[bg=#${colors.base01}]"

                  hide_frame_for_single_pane "true"

                  mode_normal        "#[fg=#${colors.base00},bg=#${colors.base0D},bold] NORMAL #[bg=#${colors.base01}]"
                  mode_locked        "#[fg=#${colors.base00},bg=#${colors.base08},bold] LOCKED #[bg=#${colors.base01}]"
                  mode_resize        "#[fg=#${colors.base00},bg=#${colors.base0E},bold] RESIZE #[bg=#${colors.base01}]"
                  mode_pane          "#[fg=#${colors.base00},bg=#${colors.base0B},bold] PANE #[bg=#${colors.base01}]"
                  mode_tab           "#[fg=#${colors.base00},bg=#${colors.base0A},bold] TAB #[bg=#${colors.base01}]"
                  mode_scroll        "#[fg=#${colors.base00},bg=#${colors.base0C},bold] SCROLL #[bg=#${colors.base01}]"
                  mode_enter_search  "#[fg=#${colors.base00},bg=#${colors.base09},bold] SEARCH #[bg=#${colors.base01}]"
                  mode_search        "#[fg=#${colors.base00},bg=#${colors.base09},bold] SEARCH #[bg=#${colors.base01}]"
                  mode_session       "#[fg=#${colors.base00},bg=#${colors.base0D},bold] SESSION #[bg=#${colors.base01}]"

                  tab_normal   "#[bg=#${colors.base01}] {index}:{name} "
                  tab_active   "#[bg=#${colors.base01},bold] {index}:{name} "
              }
          }
      }
    '';

    extraConfig = ''
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
  };

  # Custom Zsh integration - only auto-attach if not in WezTerm, Ghostty, or Neovim
  programs.zsh.initExtra = ''
    if [[ -z "$ZELLIJ" ]] && [[ -z "$NVIM" ]] && [[ "$TERM_PROGRAM" != "WezTerm" ]] && [[ "$TERM_PROGRAM" != "ghostty" ]]; then
        if [[ "$ZELLIJ_AUTO_ATTACH" == "true" ]]; then
            zellij attach -c
        else
            zellij
        fi

        if [[ "$ZELLIJ_AUTO_EXIT" == "true" ]]; then
            exit
        fi
    fi
  '';
}
