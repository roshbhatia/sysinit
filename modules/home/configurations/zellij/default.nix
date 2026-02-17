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
                  format_left  "#[fg=0,bg=10][{session}]  {tabs}"
                  format_right "#[fg=0,bg=10]{datetime}"
                  format_space "#[bg=10]"

                  tab_normal   "{index}:{name} "
                  tab_active   "#[bold]{index}:{name} "
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
  programs.zsh.initContent = ''
    # Zellij auto-tab naming functions
    function current_dir() {
        local current_dir=$PWD
        if [[ $current_dir == $HOME ]]; then
            current_dir="~"
        else
            current_dir=''${current_dir##*/}
        fi

        echo $current_dir
    }

    function change_tab_title() {
        local title=$1
        command nohup zellij action rename-tab $title >/dev/null 2>&1
    }

    function set_tab_to_working_dir() {
        local result=$?
        local title=$(current_dir)
        # uncomment the following to show the exit code after a failed command
        # if [[ $result -gt 0 ]]; then
        #     title="$title [$result]"
        # fi

        change_tab_title $title
    }

    function set_tab_to_command_line() {
        local cmdline=$1
        change_tab_title $cmdline
    }

    if [[ -n $ZELLIJ ]]; then
        add-zsh-hook precmd set_tab_to_working_dir
        add-zsh-hook preexec set_tab_to_command_line
    fi

    # Auto-attach to Zellij (but not in WezTerm or Neovim)
    if [[ -z "$ZELLIJ" ]] && [[ -z "$NVIM" ]] && [[ "$TERM_PROGRAM" != "WezTerm" ]]; then
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
