{
  config,
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  stylixTargets = themes.stylixHelpers.enableStylixTargets ["bat"];
in

{
  programs.bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
      pager = "less -FR";
    };
  };
} // stylixTargets

