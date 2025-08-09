{
  config,
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  helixConfig = themes.createAppConfig "helix" values.theme {};
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
} // helixConfig
