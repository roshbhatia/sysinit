{
  lib,
  pkgs,
  values,
  utils,
  ...
}:

let
  inherit (utils.themes) mkThemedConfig;

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

  xdg.configFile =
    (utils.themes.deployThemeFiles values {
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

  home.activation.buildBatCache = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ -f "${pkgs.bat}/bin/bat" ]; then
      $DRY_RUN_CMD echo "Building bat cache..."
      $DRY_RUN_CMD "${pkgs.bat}/bin/bat" cache --build 2>&1 || echo "Warning: Failed to build bat cache"
      $DRY_RUN_CMD echo "Completed bat cache build"
    else
      echo "Warning: bat not available, skipping cache build"
    fi
  '';
}
