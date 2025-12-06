{
  lib,
  pkgs,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };

  validatedTheme = themes.validateThemeConfig values.theme;
  theme = themes.getTheme validatedTheme.colorscheme;

  batAdapter = themes.adapters.bat;
  batThemeConfig = batAdapter.createBatTheme theme validatedTheme;

  # Determine the bat theme name to use
  batThemeName = batThemeConfig.batThemeName;
in
{
  programs.bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
      pager = "less -FR";
    };
  };

  xdg.configFile = {
    "bat/config".text = ''
      --theme="${batThemeName}"
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
