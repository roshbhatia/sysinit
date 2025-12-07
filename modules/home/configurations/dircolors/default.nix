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
  cfg = config.programs.dircolors;
  inherit (utils.theme) mkThemedConfig;

  themeCfg = mkThemedConfig values "vivid" { };
  vividTheme = themeCfg.appTheme;
in
{
  config = mkIf cfg.enable {
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
