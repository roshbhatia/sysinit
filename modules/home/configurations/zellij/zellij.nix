{
  lib,
  config,
  pkgs,
  values,
  ...
}:

let
  # Import theme system (same pattern as Helix)
  themes = import ../../lib/theme { inherit lib; };

  # Get theme configuration from values (same as Helix)
  themeConfig = {
    colorscheme = values.theme.colorscheme;
    variant = values.theme.variant;
    presets = [];
  };

  # Generate themed Zellij configuration with full theme system integration
  zellijTheme = themes.generateAppJSON "zellij" themeConfig;

  # Get the Zellij theme name (same pattern as Helix)
  zellijThemeName = themes.getAppTheme "zellij" values.theme.colorscheme values.theme.variant;

  # Create themed layout content
  defaultLayoutContent = zellijTheme.layouts.default;
  compactLayoutContent = zellijTheme.layouts.compact;

  # Generate dynamic config.kdl with proper theme name
  configContent = ''
    copy_clipboard "primary";
    copy_command "pbcopy";
    keybinds clear-defaults=true {
      normal {
        bind "Ctrl a" { SwitchToMode "locked"; };
        bind "Ctrl h" { MoveFocus "left"; };
        bind "Ctrl j" { MoveFocus "down"; };
        bind "Ctrl k" { MoveFocus "up"; };
        bind "Ctrl l" { MoveFocus "right"; };
        bind "h" { MoveFocus "left"; };
        bind "j" { MoveFocus "down"; };
        bind "k" { MoveFocus "up"; };
        bind "l" { MoveFocus "right"; };
        bind "Ctrl Shift h" { Resize "Increase left"; };
        bind "Ctrl Shift j" { Resize "Increase down"; };
        bind "Ctrl Shift k" { Resize "Increase up"; };
        bind "Ctrl Shift l" { Resize "Increase right"; };
        bind "Ctrl v" { NewPane "right"; };
        bind "Ctrl s" { NewPane "down"; };
        bind "|" { NewPane "right"; };
        bind "-" { NewPane "down"; };
        bind "Ctrl w" { CloseFocus; };
        bind "x" { CloseFocus; };
        bind "Ctrl \\" { TogglePaneFrames; ToggleActiveSyncTab; };
        bind "Ctrl t" { NewTab; };
        bind "t" { NewTab; };
        bind "Ctrl 1" { GoToTab 1; };
        bind "Ctrl 2" { GoToTab 2; };
        bind "Ctrl 3" { GoToTab 3; };
        bind "Ctrl 4" { GoToTab 4; };
        bind "Ctrl 5" { GoToTab 5; };
        bind "Ctrl 6" { GoToTab 6; };
        bind "Ctrl 7" { GoToTab 7; };
        bind "Ctrl 8" { GoToTab 8; };
        bind "1" { GoToTab 1; };
        bind "2" { GoToTab 2; };
        bind "3" { GoToTab 3; };
        bind "4" { GoToTab 4; };
        bind "5" { GoToTab 5; };
        bind "Super t" { NewTab; };
        bind "Super 1" { GoToTab 1; };
        bind "Super 2" { GoToTab 2; };
        bind "Super 3" { GoToTab 3; };
        bind "Super 4" { GoToTab 4; };
        bind "Super 5" { GoToTab 5; };
        bind "Super 6" { GoToTab 6; };
        bind "Super 7" { GoToTab 7; };
        bind "Super 8" { GoToTab 8; };
        bind "Super Shift Left" { GoToPreviousTab; };
        bind "Super Shift Right" { GoToNextTab; };
        bind "Ctrl u" { HalfPageScrollUp; };
        bind "Ctrl d" { HalfPageScrollDown; };
        bind "Ctrl Shift u" { PageScrollUp; };
        bind "Ctrl Shift d" { PageScrollDown; };
        bind "Ctrl /" { SwitchToMode "search"; };
        bind "Ctrl ]" { SwitchToMode "search"; };
        bind "Shift Enter" { ToggleFloatingPanes; };
        bind "Super k" { Clear; };
        bind "Ctrl k" { Clear; };
        bind "r" { SwitchToMode "resize"; };
        bind "s" { SwitchToMode "scroll"; };
        bind ":" { SwitchToMode "session"; };
        bind "f" { ToggleFocusFullscreen; };
        bind "z" { TogglePaneFrames; };
        bind "q" { Quit; };
        bind "d" { Detach; };
      };
      resize {
        bind "h" { Resize "Increase left"; };
        bind "j" { Resize "Increase down"; };
        bind "k" { Resize "Increase up"; };
        bind "l" { Resize "Increase right"; };
        bind "Left" { Resize "Increase left"; };
        bind "Down" { Resize "Increase down"; };
        bind "Up" { Resize "Increase up"; };
        bind "Right" { Resize "Increase right"; };
        bind "=" { Resize "Increase"; };
        bind "-" { Resize "Decrease"; };
        bind "Esc" { SwitchToMode "normal"; };
        bind "Enter" { SwitchToMode "normal"; };
        bind "q" { SwitchToMode "normal"; };
      };
      scroll {
        bind "j" { ScrollDown; };
        bind "k" { ScrollUp; };
        bind "Down" { ScrollDown; };
        bind "Up" { ScrollUp; };
        bind "Ctrl d" { HalfPageScrollDown; };
        bind "Ctrl u" { HalfPageScrollUp; };
        bind "Ctrl f" { PageScrollDown; };
        bind "Ctrl b" { PageScrollUp; };
        bind "g" { ScrollToTop; };
        bind "G" { ScrollToBottom; };
        bind "/" { SwitchToMode "search"; };
        bind "n" { Search "down"; };
        bind "N" { Search "up"; };
        bind "Esc" { SwitchToMode "normal"; };
        bind "q" { SwitchToMode "normal"; };
        bind "Enter" { SwitchToMode "normal"; };
      };
      search {
        bind "Enter" { SwitchToMode "scroll"; };
        bind "Esc" { ScrollToBottom; SwitchToMode "normal"; };
        bind "j" { Search "down"; };
        bind "k" { Search "up"; };
        bind "Down" { Search "down"; };
        bind "Up" { Search "up"; };
        bind "n" { Search "down"; };
        bind "N" { Search "up"; };
      };
      locked {
        bind "Ctrl a" { SwitchToMode "normal"; };
      };
      shared_except "locked" {
        bind "Ctrl y" {
          LaunchOrFocusPlugin "https://github.com/rvcas/room/releases/latest/download/room.wasm" {
            floating true;
            ignore_case true;
            quick_jump true;
          };
        };
      };
    };

    load_plugins "session-manager" "zjstatus-hints";
    mouse_mode true;
    on_force_close "detach";
    pane_frames false;
    simplified_ui true;
    default_shell "zsh";
    ui {
      pane_frames {
        rounded_corners false;
        hide_session_name false;
      };
    };
    scroll_buffer_size 100000;
    scrollback_editor "nvim";
    scrollback_lines_to_serialize 50000;
    copy_on_select true;
    session_serialization false;
    auto_layout true;
    plugins {
      session-manager {
        location "zellij:session-manager";
      };
      zjstatus-hints {
        location "https://github.com/b0o/zjstatus-hints/releases/latest/download/zjstatus-hints.wasm";
        max_length 80;
        overflow_str "…";
        pipe_name "zjstatus_hints";
        hide_in_base_mode false;
      };
    };
    theme "${zellijThemeName}";
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
