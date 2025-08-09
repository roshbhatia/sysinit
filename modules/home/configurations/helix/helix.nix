{
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  stylixTargets = themes.stylixHelpers.enableStylixTargets ["helix"];
in

{
  programs.helix = {
    enable = true;
    settings = {
      editor = {
        line-number = "relative";

        cursor-shape = {
          insert = "bar";
          select = "underline";
        };

        file-picker = {
          hidden = false;
        };
      };
    };
  };
} // stylixTargets

