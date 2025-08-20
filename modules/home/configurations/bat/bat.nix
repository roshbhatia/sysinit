{
  lib,
  pkgs,
  config,
  values,
  utils,
  ...
}:

let
  inherit (utils.themeHelper) mkThemedConfig;
  themeCfg = mkThemedConfig values "bat" { };
  batTheme = themeCfg.appTheme;
in
{
  programs.bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
      pager = "less -FR";
    };
  };

  # Deploy custom bat theme and rebuild cache
  xdg.configFile =
    (utils.themeHelper.deployThemeFiles values {
      app = "bat";
      themeDir = ./themes;
      targetPath = "bat/themes";
      fileExtension = "tmTheme";
    })
    // {
      "bat/config".text = ''
        --theme="${batTheme}"
        --style=numbers,changes,header
        --pager="less -FR"
      '';
    };

  home.activation.buildBatCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f "${pkgs.bat}/bin/bat" ]; then
      echo "Building bat cache..."
      "${pkgs.bat}/bin/bat" cache --build || echo "Warning: Failed to build bat cache"
      echo "Completed bat cache build"
    else
      echo "Warning: bat not available at ${pkgs.bat}/bin/bat, skipping cache build"
    fi
  '';
}
