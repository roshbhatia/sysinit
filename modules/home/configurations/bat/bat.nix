{
  config,
  lib,
  pkgs,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  batConfig = themes.createAppConfig "bat" values.theme {};
in

{
  programs.bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
      pager = "less -FR";
    };
  };
} // batConfig
