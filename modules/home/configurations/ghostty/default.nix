{
  config,
  pkgs,
  ...
}:

let
  ghosttyCursorShaders = pkgs.fetchFromGitHub {
    owner = "sahaj-b";
    repo = "ghostty-cursor-shaders";
    rev = "4faa83e4b9306750fc8de64b38c6f53c57862db8";
    sha256 = "sha256-ruhEqXnWRCYdX5mRczpY3rj1DTdxyY3BoN9pdlDOKrE=";
  };
in
{
  stylix.targets.ghostty = {
    enable = true;
  };

  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then null else pkgs.ghostty;

    settings = {
      macos-titlebar-style = "hidden";
      macos-window-shadow = false;

      background-opacity = config.sysinit.theme.transparency.opacity;
      background-opacity-cells = true;
      background-blur = true;

      window-padding-x = 8;
      window-padding-y = 8;
      window-padding-balance = true;

      # Berkeley Mono (TX-02) font features
      # Enable contextual alternates (ligatures) and dotted 0
      font-feature = [
        "+calt"
        "+ss02"
      ];

      # Auto-launch zellij and exit when it closes
      # Shell integration disabled because it doesn't work inside terminal multiplexers
      command = "${pkgs.zsh}/bin/zsh -c ${pkgs.zellij}/bin/zellij";
      shell-integration = "none";

      # Cursor trail shader for smooth cursor movement
      custom-shader = "${ghosttyCursorShaders}/cursor_tail.glsl";
      custom-shader-animation = "always";

      quick-terminal-position = "center";
      quick-terminal-size = "90%,80%";

      keybind = [
        "clear"
        "global:alt+enter=toggle_quick_terminal"
        "super+semicolon=toggle_command_palette"
        "super+c=copy_to_clipboard"
        "super+v=paste_from_clipboard"
        "super+1=goto_tab:1"
        "super+2=goto_tab:2"
        "super+3=goto_tab:3"
        "super+4=goto_tab:4"
        "super+5=goto_tab:5"
        "super+6=goto_tab:6"
        "super+7=goto_tab:7"
        "super+8=goto_tab:8"
        "super+9=goto_tab:9"
        "super+a=select_all"
        "super+equal=increase_font_size:1"
        "super+h=toggle_visibility"
        "super+minus=decrease_font_size:1"
        "super+n=new_window"
        "super+q=quit"
        "super+shift+z=redo"
        "super+t=new_tab"
        "super+w=close_tab"
        "super+z=undo"
      ];
    };
  };
}
