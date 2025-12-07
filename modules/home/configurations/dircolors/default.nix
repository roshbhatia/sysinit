{
  config,
  lib,
  pkgs,
  values,
  utils,
  ...
}:
with lib;
let
  inherit (utils.theme) mkThemedConfig;

  themeCfg = mkThemedConfig values "vivid" { };
  vividTheme = themeCfg.appTheme;
in
{
  config = {
    programs.dircolors = {
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
    };

    home.sessionVariables = {
      LS_COLORS = "$(${pkgs.vivid}/bin/vivid generate ${vividTheme})";
      DIR_COLORS = "$(${pkgs.vivid}/bin/vivid generate ${vividTheme})";
      EZA_COLORS = "$(${pkgs.vivid}/bin/vivid generate ${vividTheme})";
    };
  };
}
