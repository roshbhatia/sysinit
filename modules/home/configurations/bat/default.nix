{
  lib,
  pkgs,
  values,
  ...
}:

let
  themes = import ../../../shared/lib/theme { inherit lib; };

  validatedTheme = themes.validateThemeConfig values.theme;
  theme = themes.getTheme validatedTheme.colorscheme;

  batAdapter = themes.adapters.bat;
  batThemeConfig = batAdapter.createBatTheme theme validatedTheme;

  batThemeName = batThemeConfig.batThemeName;
  hasNativeTheme = batThemeConfig.hasNativeTheme;

  themeKey = "${validatedTheme.colorscheme}-${validatedTheme.variant}";
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
  }
  // lib.optionalAttrs (!hasNativeTheme) {
    "bat/themes/${themeKey}.tmTheme" = {
      text = batThemeConfig.tmTheme;
      force = true;
    };
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
