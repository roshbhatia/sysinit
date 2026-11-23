colors:
let
  hex = name: "#${colors.${name}}";
in
{
  foreground = hex "base05";
  background = hex "base00";
  cursor_bg = hex "base05";
  cursor_fg = hex "base00";
  selection_bg = hex "base02";
  selection_fg = hex "base05";
  ansi = map hex [
    "base00"
    "base08"
    "base0B"
    "base0A"
    "base0D"
    "base0E"
    "base0C"
    "base05"
  ];
  brights = map hex [
    "base03"
    "base08"
    "base0B"
    "base0A"
    "base0D"
    "base0E"
    "base0C"
    "base07"
  ];
}
