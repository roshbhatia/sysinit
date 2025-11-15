{
  lib,
  pkgs,
  values,
  utils,
  ...
}:

let
  inherit (utils.theme) mkThemedConfig;
  inherit (lib) listToAttrs nameValuePair;

  themeCfg = mkThemedConfig values "bat" { };
  batTheme = themeCfg.appTheme;

  themeFiles = builtins.readDir ./themes;

  themeConfigFiles = listToAttrs (
    lib.mapAttrsToList (
      name: _type:
      nameValuePair "bat/themes/${name}" {
        source = ./themes + "/${name}";
      }
    ) themeFiles
  );
in
{
  programs.bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
      pager = "less -FR";
    };
  };

  xdg.configFile = themeConfigFiles // {
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
