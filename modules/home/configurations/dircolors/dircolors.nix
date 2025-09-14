{
  pkgs,
  values,
  utils,
  ...
}:

let
  inherit (utils.themes) mkThemedConfig;
  themeCfg = mkThemedConfig values "vivid" { };
  vividTheme = themeCfg.appTheme;
in
{
  programs.dircolors = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  home.sessionVariables = {
    LS_COLORS = "$(${pkgs.vivid}/bin/vivid generate ${vividTheme})";
    DIR_COLORS = "$(${pkgs.vivid}/bin/vivid generate ${vividTheme})";
    EZA_COLORS = "$(${pkgs.vivid}/bin/vivid generate ${vividTheme})";
  };
}
