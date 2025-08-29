{ lib, ... }:

with lib;

let
  utils = import ../core/utils.nix { inherit lib; };
in

rec {
  createZellijTheme =
    themeData: variant: overrides:
    let
      palette = themeData.palettes.${variant};
      semanticColors = utils.createSemanticMapping palette;
    in
    {
      bg = semanticColors.background.primary;
      fg = semanticColors.foreground.primary;
      red = semanticColors.semantic.error;
      green = semanticColors.semantic.success;
      blue = semanticColors.semantic.info;
      yellow = semanticColors.semantic.warning;
      magenta = semanticColors.accent.primary;
      orange = semanticColors.accent.secondary;
      cyan = semanticColors.syntax.operator;
      black = semanticColors.background.overlay;
      white = semanticColors.foreground.primary;
    }
    // overrides;

  generateZjstatusLayout =
    themeData: variant: layoutConfig:
    let
      palette = themeData.palettes.${variant};
      semanticColors = utils.createSemanticMapping palette;

      colors = {
        bg_primary = semanticColors.background.primary;
        bg_secondary = semanticColors.background.secondary;
        bg_overlay = semanticColors.background.overlay;
        fg_primary = semanticColors.foreground.primary;
        fg_muted = semanticColors.foreground.muted;
        accent_primary = semanticColors.accent.primary;
        accent_secondary =
          if hasAttr "secondary" semanticColors.accent then
            semanticColors.accent.secondary
          else
            semanticColors.accent.primary;
        error = semanticColors.semantic.error;
        success = semanticColors.semantic.success;
        warning = semanticColors.semantic.warning;
        info = semanticColors.semantic.info;
      };

      defaultLayout = {
        format_left = "{mode} #[fg=${colors.accent_primary},bold,italic]{session} ";
        format_center = "{tabs}";
        format_right = "{command_git_branch}{pipe_zjstatus_hints} #[fg=${colors.fg_muted}]{datetime}";

        modes = {
          normal = "#[bg=${colors.accent_primary},fg=${colors.bg_primary},bold] NORMAL ";
          locked = "#[bg=${colors.bg_overlay},fg=${colors.fg_primary}] LOCKED ";
          resize = "#[bg=${colors.warning},fg=${colors.bg_primary},bold] RESIZE ";
          scroll = "#[bg=${colors.accent_secondary},fg=${colors.bg_primary},bold] SCROLL ";
          search = "#[bg=${colors.error},fg=${colors.bg_primary},bold] SEARCH ";
          session = "#[bg=${colors.accent_primary},fg=${colors.bg_primary},bold] SESSION ";
        };

        tabs = {
          normal = "#[fg=${colors.fg_muted}] {index} {name} ";
          active = "#[fg=${colors.fg_primary},bold,italic] {index} {name} ";
          normal_fullscreen = "#[fg=${colors.fg_muted}] {index} {name} 󰊓 ";
          active_fullscreen = "#[fg=${colors.fg_primary},bold,italic] {index} {name} 󰊓 ";
        };

        git_branch = "#[fg=${colors.info}] {stdout} ";
        hints = "#[fg=${colors.fg_muted},italic]{output} ";
        datetime = "#[fg=${colors.fg_muted}] {format} ";
      };

      finalConfig = defaultLayout // layoutConfig;

      themeName =
        if hasAttr "zellij" themeData.appAdapters then
          if builtins.isFunction themeData.appAdapters.zellij then
            themeData.appAdapters.zellij variant
          else if hasAttr variant themeData.appAdapters.zellij then
            themeData.appAdapters.zellij.${variant}
          else
            "${themeData.meta.id}-${variant}"
        else
          "${themeData.meta.id}-${variant}";
    in
    ''
      layout {
          default_tab_template {
              children
              pane size=1 borderless=true {
                  plugin location="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" {
                      format_left   "${finalConfig.format_left}"
                      format_center "${finalConfig.format_center}"
                      format_right  "${finalConfig.format_right}"
                      format_space  ""
                      border_enabled  "false"
                      border_char     "─"
                      border_format   "#[fg=${colors.bg_overlay}]{char}"
                      border_position "top"
                      hide_frame_for_single_pane "true"
                      mode_normal        "${finalConfig.modes.normal}"
                      mode_locked        "${finalConfig.modes.locked}"
                      mode_resize        "${finalConfig.modes.resize}"
                      mode_pane          "#[bg=${colors.info},fg=${colors.bg_primary},bold] PANE "
                      mode_tab           "#[bg=${colors.success},fg=${colors.bg_primary},bold] TAB "
                      mode_scroll        "${finalConfig.modes.scroll}"
                      mode_enter_search  "${finalConfig.modes.search}"
                      mode_search        "${finalConfig.modes.search}"
                      mode_rename_tab    "#[bg=${colors.warning},fg=${colors.bg_primary},bold] RENAME "
                      mode_rename_pane   "#[bg=${colors.warning},fg=${colors.bg_primary},bold] RENAME "
                      mode_session       "${finalConfig.modes.session}"
                      mode_move          "#[bg=${colors.success},fg=${colors.bg_primary},bold] MOVE "
                      mode_prompt        "#[bg=${colors.error},fg=${colors.bg_primary},bold] PROMPT "
                      mode_tmux          "#[bg=${colors.bg_overlay},fg=${colors.fg_primary}] TMUX "
                      session_format   " {name} "
                      tab_normal              "${finalConfig.tabs.normal}"
                      tab_normal_fullscreen   "${finalConfig.tabs.normal_fullscreen}"
                      tab_normal_sync         "#[fg=${colors.fg_muted}] {index} {name} 󰓦 "
                      tab_active              "${finalConfig.tabs.active}"
                      tab_active_fullscreen   "${finalConfig.tabs.active_fullscreen}"
                      tab_active_sync         "#[fg=${colors.fg_primary},bold,italic] {index} {name} 󰓦 "
                      command_git_branch_command     "git rev-parse --abbrev-ref HEAD 2>/dev/null"
                      command_git_branch_format      "${finalConfig.git_branch}"
                      command_git_branch_interval    "10"
                      command_git_branch_rendermode  "static"
                      pipe_zjstatus_hints_format "${finalConfig.hints}"
                      datetime        "${finalConfig.datetime}"
                      datetime_format "%H:%M"
                      datetime_timezone "America/New_York"
                      notification_format_unread           "#[fg=${colors.error},blink] 󰍡 #[fg=${colors.error}]{message} "
                      notification_format_no_notifications ""
                      notification_show_interval           "2"
                  }
              }
          }
      }
    '';

  generateCompactLayout =
    themeData: variant:
    let
      palette = themeData.palettes.${variant};
      semanticColors = utils.createSemanticMapping palette;
      colors = {
        bg_primary = semanticColors.background.primary;
        bg_overlay = semanticColors.background.overlay;
        fg_primary = semanticColors.foreground.primary;
        fg_muted = semanticColors.foreground.muted;
        accent_primary = semanticColors.accent.primary;
        warning = semanticColors.semantic.warning;
        error = semanticColors.semantic.error;
        info = semanticColors.semantic.info;
        accent_secondary =
          if hasAttr "secondary" semanticColors.accent then
            semanticColors.accent.secondary
          else
            semanticColors.accent.primary;
      };
    in
    ''
      layout {
          default_tab_template {
              children
              pane size=1 borderless=true {
                  plugin location="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" {
                      format_left   "{mode}"
                      format_center ""
                      format_right  "{command_git_branch}{datetime}"
                      format_space  ""

                      border_enabled "false"
                      hide_frame_for_single_pane "true"

                      mode_normal   "#[bg=${colors.accent_primary},fg=${colors.bg_primary}] N "
                      mode_locked   "#[bg=${colors.bg_overlay},fg=${colors.fg_primary}] L "
                      mode_resize   "#[bg=${colors.warning},fg=${colors.bg_primary}] R "
                      mode_scroll   "#[bg=${colors.accent_secondary},fg=${colors.bg_primary}] S "
                      mode_search   "#[bg=${colors.error},fg=${colors.bg_primary}] / "
                      mode_session  "#[bg=${colors.accent_primary},fg=${colors.bg_primary}] : "

                      command_git_branch_command     "git branch --show-current 2>/dev/null"
                      command_git_branch_format      "#[fg=${colors.info}]{stdout} "
                      command_git_branch_interval    "15"
                      command_git_branch_rendermode  "static"

                      datetime "#[fg=${colors.fg_muted}]{format}"
                      datetime_format "%H:%M"
                  }
              }
          }
      }
    '';

  generateZellijConfig =
    themeData: variant: config:
    let
      themeName =
        if hasAttr "zellij" themeData.appAdapters then
          if builtins.isFunction themeData.appAdapters.zellij then
            themeData.appAdapters.zellij variant
          else if hasAttr variant themeData.appAdapters.zellij then
            themeData.appAdapters.zellij.${variant}
          else
            "${themeData.meta.id}-${variant}"
        else
          "${themeData.meta.id}-${variant}";
    in
    ''
      theme "${themeName}"
    '';
}
