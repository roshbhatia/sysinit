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
      height = 26;
      title = "on";
      spaces = "off";
      clock = "on";
      power = "on";
      dnd = "on";
      padding_left = 20;
      padding_right = 20;
      spacing_left = 25;
      spacing_right = 15;
      text_font = "JetBrains Mono NL:Regular:12.0";
      icon_font = "Symbols Nerd Font Mono:Regular:12.0";
      background_color = toSpacebarColor ((palette.colors.base or (throw "palette.colors.base not set")));
      foreground_color = toSpacebarColor ((palette.colors.text or (throw "palette.colors.text not set")));
      power_icon_color = toSpacebarColor (
        (semanticColors.semantic.warning or (throw "semanticColors.semantic.warning not set"))
      );
      battery_icon_color = toSpacebarColor (
        (semanticColors.semantic.error or (throw "semanticColors.semantic.error not set"))
      );
      dnd_icon_color = toSpacebarColor (
        (palette.colors.overlay0 or (throw "palette.colors.overlay0 not set"))
      );
      clock_icon_color = toSpacebarColor (
        (semanticColors.accent.primary or (throw "semanticColors.accent.primary not set"))
      );
      power_icon_strip = "󰁹 󱐋";
      clock_icon = "";
      dnd_icon = "⏾";
      clock_format = ''"%a %d %b %H:%M"'';
      left_shell = "on";
      left_shell_icon = "󱎃";
      left_shell_command = "${aerospaceSpacesScript}";
      right_shell = "on";
      right_shell_icon = "";
      right_shell_command = "/Users/${values.user.username}/.local/bin/gh-whoami";
      debug_output = "off";
    };
  };
}

