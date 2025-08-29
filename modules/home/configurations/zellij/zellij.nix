{
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  zellijTheme = themes.getAppTheme "zellij" values.theme.colorscheme values.theme.variant;
in
{
  programs.zellij = {
    enable = true;
    theme = zellijTheme;
    pane_frames = false;
    simplified_ui = true;
    scrollback_editor = "nvim";
    scroll_buffer_size = 50000;
    mouse_mode = true;
    copy_command = "pbcopy";
    copy_clipboard = "primary";
    scrollback_lines_to_serialize = 100000;
    on_force_close = "detach";
    plugins = {
      zjstatus-hints = {
        location = "https://github.com/b0o/zjstatus-hints/releases/latest/download/zjstatus-hints.wasm";
        max_length = 50;
        overflow_str = "...";
        pipe_name = "zjstatus_hints";
        hide_in_base_mode = false;
      };
      session-manager = {
        location = "zellij:session-manager";
      };
      status-bar = {
        location = "zellij:status-bar";
      };
    };
    load_plugins = [
      "zjstatus-hints"
      "session-manager"
      "status-bar"
    ];
  };

  xdg.configFile."zsh/extras/zellij.sh" = {
    source = ./zellij.sh;
  };

  xdg.configFile."zellij/config.kdl" = {
    source = ./config.kdl;
  };
}
