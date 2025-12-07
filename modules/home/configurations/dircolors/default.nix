{
  pkgs,
  values,
  utils,
  ...
}:

let
  inherit (utils.theme) mkThemedConfig;

  themeCfg = mkThemedConfig values "vivid" { };
  vividTheme = themeCfg.appTheme;
in
{
  programs.dircolors = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  home.sessionVariables = {
    LS_COLORS = "$(${pkgs.vivid}/bin/vivid generate ${vividTheme})";
    DIR_COLORS = "$(${pkgs.vivid}/bin/vivid generate ${vividTheme})";
    EZA_COLORS = "$(${pkgs.vivid}/bin/vivid generate ${vividTheme})";
  };
}
