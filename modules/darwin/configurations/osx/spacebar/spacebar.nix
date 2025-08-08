{
  lib,
  pkgs,
  values,
  ...
}:

let
  themes = import ../../../../lib/theme { inherit lib; };
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  semanticColors = themes.utils.createSemanticMapping palette;

  toSpacebarColor = color: "0xff${lib.toLower (lib.removePrefix "#" color)}";

  aerospaceSpacesScript = pkgs.writeShellScript "aerospace-spaces" ''
    current=$(aerospace list-workspaces --focused)
    all=$(aerospace list-workspaces --monitor all)

    result=""
    for space in $all; do
      if [ "$space" = "$current" ]; then
        result="$result [$space]"
      else
        result="$result  $space "
      fi
    done

    echo "$result"
  '';
in
{
  services.spacebar = {
    enable = true;
    package = pkgs.spacebar;
    config = {
      position = "top";
      display = "main";
      height = 32;
      title = "off";
      spaces = "off";
      clock = "on";
      power = "on";
      dnd = "on";
      padding_left = 20;
      padding_right = 20;
      spacing_left = 25;
      spacing_right = 15;
      text_font = ''"JetBrains Mono NL:Regular:12.0"'';
      icon_font = ''"Symbols Nerd Font Mono:Regular:12.0"'';
      background_color = toSpacebarColor (palette.colors.base or "#1e1e2e");
      foreground_color = toSpacebarColor (palette.colors.text or "#cdd6f4");
      power_icon_color = toSpacebarColor (semanticColors.semantic.warning or "#f9e2af");
      battery_icon_color = toSpacebarColor (semanticColors.semantic.error or "#f38ba8");
      dnd_icon_color = toSpacebarColor (palette.colors.overlay0 or "#6c7086");
      clock_icon_color = toSpacebarColor (semanticColors.accent.primary or "#89b4fa");
      power_icon_strip = "󰁹 󱐋";
      clock_icon = "";
      dnd_icon = "";
      clock_format = ''"%a %d %b %H:%M"'';
      left_shell = "on";
      left_shell_icon = "";
      left_shell_command = "${aerospaceSpacesScript}";
      right_shell = "on";
      right_shell_icon = "";
      right_shell_command = "gh-whoami";
      debug_output = "off";
    };
  };

  environment.variables = {
    SPACEBAR_HEIGHT = "32";
  };
}
