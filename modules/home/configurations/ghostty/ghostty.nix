{
  lib,
  pkgs,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };

  ghosttyWrapper =
    pkgs.runCommand "ghostty-homebrew-wrapper"
      {
        pname = "ghostty";
        version = "homebrew";
        meta = {
          mainProgram = "ghostty";
        };
      }
      ''
        mkdir -p $out/bin
        cat > $out/bin/ghostty <<EOF
        #!/bin/sh
        exec /Applications/Ghostty.app/Contents/MacOS/ghostty "\$@"
        EOF
        chmod +x $out/bin/ghostty
      '';

  builtInThemes = {
    catppuccin = {
      macchiato = "catppuccin-macchiato";
    };
    rose-pine = {
      moon = "rose-pine-moon";
    };
    gruvbox = {
      dark = "GruvboxDark";
    };
    nord = {
      dark = "nord";
    };
    kanagawa = {
      wave = "Kanagawa Wave";
      dragon = "Kanagawa Dragon";
    };
    solarized = {
      dark = "Solarized Dark - Patched";
    };
  };

  hasBuiltInTheme =
    lib.hasAttr values.theme.colorscheme builtInThemes
    && lib.hasAttr values.theme.variant builtInThemes.${values.theme.colorscheme};

  builtInThemeName =
    if hasBuiltInTheme then builtInThemes.${values.theme.colorscheme}.${values.theme.variant} else null;

  semanticColors = themes.getSemanticColors values.theme.colorscheme values.theme.variant;

  customTheme = {
    background = semanticColors.background.primary;
    foreground = semanticColors.foreground.primary;

    cursor-color = semanticColors.accent.primary;
    cursor-text = semanticColors.background.primary;

    selection-background = semanticColors.accent.primary;
    selection-foreground = semanticColors.background.primary;

    palette = [
      "0=${semanticColors.background.primary}"
      "1=${semanticColors.semantic.error}"
      "2=${semanticColors.semantic.success}"
      "3=${semanticColors.semantic.warning}"
      "4=${semanticColors.semantic.info}"
      "5=${semanticColors.syntax.keyword}"
      "6=${semanticColors.syntax.operator}"
      "7=${semanticColors.foreground.primary}"
      "8=${semanticColors.foreground.muted}"
      "9=${semanticColors.semantic.error}"
      "10=${semanticColors.semantic.success}"
      "11=${semanticColors.semantic.warning}"
      "12=${semanticColors.semantic.info}"
      "13=${semanticColors.syntax.keyword}"
      "14=${semanticColors.syntax.operator}"
      "15=${semanticColors.foreground.primary}"
    ];
  };
in
{
  programs.ghostty = {
    enable = true;

    package = ghosttyWrapper // {
      override = _args: ghosttyWrapper;
    };

    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;

    installBatSyntax = false;
    installVimSyntax = false;

    settings = {
      theme =
        if hasBuiltInTheme then builtInThemeName else "${values.theme.colorscheme}-${values.theme.variant}";

      bold-is-bright = true;
      font-family = "Berkeley Mono";
      font-size = 13;
      font-feature = [
        "+zero"
        "+calt"
        "+liga"
        "+dlig"
      ];

      window-padding-x = 4;
      window-padding-y = "2,0";

      background-opacity =
        if values.theme.transparency.enable then values.theme.transparency.opacity else 1.0;

      background-blur = if values.theme.transparency.enable then values.theme.transparency.blur else 0;

      macos-icon = "custom-style";
      macos-icon-frame = "chrome";
      macos-icon-ghost-color = semanticColors.background.primary;
      macos-icon-screen-color = semanticColors.foreground.primary;
      macos-auto-secure-input = true;
      macos-secure-input-indication = true;

      shell-integration = "zsh";

      keybind = [
        "cmd+plus=increase_font_size:1"
        "cmd+minus=decrease_font_size:1"
        "cmd+0=reset_font_size"
        "cmd+n=new_window"
        "cmd+w=close_surface"
        "cmd+r=reload_config"
        "cmd+d=ignore"
        "cmd+shift+d=ignore"
        "cmd+option+up=ignore"
        "cmd+option+down=ignore"
        "cmd+option+left=ignore"
        "cmd+option+right=ignore"
        "cmd+shift+enter=ignore"
        "cmd+ctrl+up=ignore"
        "cmd+ctrl+down=ignore"
        "cmd+ctrl+left=ignore"
        "cmd+ctrl+right=ignore"
        "cmd+ctrl+=ignore"
        "cmd+shift+w=ignore"
      ];
    };

    themes = lib.mkIf (!hasBuiltInTheme) {
      "${values.theme.colorscheme}-${values.theme.variant}" = customTheme;
    };
  };
}
