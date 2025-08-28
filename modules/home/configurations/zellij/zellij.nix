{
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  semanticColors = themes.getSemanticColors values.theme.colorscheme values.theme.variant;

  zellijTheme = {
    bg = semanticColors.background.primary;
    fg = semanticColors.foreground.primary;
    red = semanticColors.semantic.error;
    green = semanticColors.semantic.success;
    blue = semanticColors.semantic.info;
    yellow = semanticColors.semantic.warning;
    magenta = semanticColors.syntax.keyword;
    cyan = semanticColors.syntax.operator;
    black = semanticColors.background.secondary;
    white = semanticColors.foreground.primary;
    orange = semanticColors.syntax.number;
  };

  defaultLayoutKdl = ''
    layout {
      default_tab_template {
        pane size=1 borderless=true {
          plugin location="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" {
            format_left   "#[fg=${semanticColors.syntax.keyword},bold]{mode} #[fg=${semanticColors.semantic.info}]{session}"
            format_center "{tabs}"
            format_right  "{pipe_zjstatus_hints}"
            format_space  ""

            border_enabled  "false"

            mode_normal  "#[bg=${semanticColors.semantic.success}] "
            mode_locked  "#[bg=${semanticColors.semantic.error}] "
            mode_resize  "#[bg=${semanticColors.semantic.warning}] "
            mode_pane    "#[bg=${semanticColors.semantic.info}] "
            mode_tab     "#[bg=${semanticColors.syntax.keyword}] "
            mode_scroll  "#[bg=${semanticColors.syntax.operator}] "
            mode_enter_search "#[bg=${semanticColors.syntax.number}] "
            mode_search  "#[bg=${semanticColors.syntax.number}] "
            mode_rename_tab "#[bg=${semanticColors.syntax.keyword}] "
            mode_rename_pane "#[bg=${semanticColors.syntax.keyword}] "
            mode_session "#[bg=${semanticColors.syntax.keyword}] "
            mode_move    "#[bg=${semanticColors.syntax.operator}] "
            mode_prompt  "#[bg=${semanticColors.syntax.number}] "
            mode_tmux    "#[bg=${semanticColors.syntax.number}] "

            tab_normal   "#[fg=${semanticColors.foreground.muted}] {name} "
            tab_active   "#[fg=${semanticColors.foreground.primary},bold] {name} "

            pipe_zjstatus_hints_format "#[fg=${semanticColors.foreground.muted}]{output} "
          }
        }
      }
    }
  '';

  configKdl = ''
    theme "${values.theme.colorscheme}-${values.theme.variant}"

    default_shell "zsh"
    default_layout "default"
    default_mode "normal"

    mouse_mode true
    scroll_buffer_size 50000
    copy_command "pbcopy"
    copy_clipboard "primary"

    pane_frames true

    session_serialization false
    pane_viewport_serialization false
    scrollback_lines_to_serialize 10000

    on_force_close "quit"

    plugins {
      zjstatus-hints location="https://github.com/b0o/zjstatus-hints/releases/latest/download/zjstatus-hints.wasm" {
        max_length 50
        overflow_str "..."
        pipe_name "zjstatus_hints"
        hide_in_base_mode false
      }
    }

    load_plugins {
      zjstatus-hints
    }

    keybinds {
      normal {
        bind "Ctrl h" { MoveFocus "left"; }
        bind "Ctrl j" { MoveFocus "down"; }
        bind "Ctrl k" { MoveFocus "up"; }
        bind "Ctrl l" { MoveFocus "right"; }

        bind "Ctrl Shift h" { Resize "Increase left"; }
        bind "Ctrl Shift j" { Resize "Increase down"; }
        bind "Ctrl Shift k" { Resize "Increase up"; }
        bind "Ctrl Shift l" { Resize "Increase right"; }

        bind "Ctrl v" { NewPane "right"; }
        bind "Ctrl s" { NewPane "down"; }
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

        bind "Cmd t" { NewTab; }
        bind "Cmd 1" { GoToTab 1; }
        bind "Cmd 2" { GoToTab 2; }
        bind "Cmd 3" { GoToTab 3; }
        bind "Cmd 4" { GoToTab 4; }
        bind "Cmd 5" { GoToTab 5; }
        bind "Cmd 6" { GoToTab 6; }
        bind "Cmd 7" { GoToTab 7; }
        bind "Cmd 8" { GoToTab 8; }
        bind "Cmd Shift Left" { GoToPreviousTab; }
        bind "Cmd Shift Right" { GoToNextTab; }

        bind "h" { MoveFocus "left"; }
        bind "j" { MoveFocus "down"; }
        bind "k" { MoveFocus "up"; }
        bind "l" { MoveFocus "right"; }
        bind "|" { NewPane "right"; }
        bind "-" { NewPane "down"; }
        bind "x" { CloseFocus; }
        bind "1" { GoToTab 1; }
        bind "2" { GoToTab 2; }
        bind "3" { GoToTab 3; }
        bind "4" { GoToTab 4; }
        bind "5" { GoToTab 5; }
        bind "t" { NewTab; }
        bind "r" { SwitchToMode "Resize"; }
        bind "s" { SwitchToMode "Scroll"; }
        bind "q" { Quit; }
      }

      resize {
        bind "h" { Resize "Increase left"; }
        bind "j" { Resize "Increase down"; }
        bind "k" { Resize "Increase up"; }
        bind "l" { Resize "Increase right"; }
        bind "Esc" { SwitchToMode "Normal"; }
      }

      scroll {
        bind "j" { ScrollDown; }
        bind "k" { ScrollUp; }
        bind "Esc" { SwitchToMode "Normal"; }
      }
    }
  '';
in
{
  programs.zellij = {
    enable = true;

    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;

    settings = {
      theme = "${values.theme.colorscheme}-${values.theme.variant}";
      default_shell = "zsh";
      simplified_ui = false;
    };

    themes = {
      "${values.theme.colorscheme}-${values.theme.variant}" = {
        fg = zellijTheme.fg;
        bg = zellijTheme.bg;
        red = zellijTheme.red;
        green = zellijTheme.green;
        blue = zellijTheme.blue;
        yellow = zellijTheme.yellow;
        magenta = zellijTheme.magenta;
        cyan = zellijTheme.cyan;
        black = zellijTheme.black;
        white = zellijTheme.white;
        orange = zellijTheme.orange;
      };
    };
  };

  xdg.configFile."zellij/config.kdl".text = configKdl;
  xdg.configFile."zellij/layouts/default.kdl".text = defaultLayoutKdl;
}
