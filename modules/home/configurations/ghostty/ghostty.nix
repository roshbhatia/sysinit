{
  lib,
  pkgs,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };

  # Create Homebrew wrapper for Ghostty (similar to Firefox)
  ghosttyWrapper =
    pkgs.runCommand "ghostty-homebrew-wrapper"
      {
        pname = "ghostty";
        version = "homebrew";
      }
      ''
        mkdir -p $out/bin
        cat > $out/bin/ghostty <<EOF
        #!/bin/sh
        exec /Applications/Ghostty.app/Contents/MacOS/ghostty "\$@"
        EOF
        chmod +x $out/bin/ghostty
      '';

  # Get theme data and check if ghostty has built-in support
  themeData = themes.getTheme values.theme.colorscheme;

  # Built-in theme mapping for Ghostty (only supported variants)
  builtInThemes = {
    catppuccin = {
      macchiato = "catppuccin-macchiato";
      frappe = "catppuccin-frappe";
      latte = "catppuccin-latte";
      mocha = "catppuccin-mocha";
    };
    rose-pine = {
      moon = "rose-pine-moon";
      dawn = "rose-pine-dawn";
      main = "rose-pine";
    };
    gruvbox = {
      dark = "GruvboxDark";
      light = "GruvboxLight";
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
      light = "iTerm2 Solarized Light";
    };
  };

  # Check if we have a built-in theme for this colorscheme/variant combo
  hasBuiltInTheme =
    lib.hasAttr values.theme.colorscheme builtInThemes
    && lib.hasAttr values.theme.variant builtInThemes.${values.theme.colorscheme};

  builtInThemeName =
    if hasBuiltInTheme then builtInThemes.${values.theme.colorscheme}.${values.theme.variant} else null;

  # Only create custom theme if no built-in theme exists
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

    # Use Homebrew wrapper instead of nixpkgs (which is marked broken)
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

      window-decoration = true;
      window-theme = "auto";
      window-colorspace = "srgb";

      font-family = "Berkeley Mono";
      font-size = 13;
      font-feature = [
        "+zero"
      ];

      cursor-style = "block";
      cursor-style-blink = false;

      scrollback-limit = 10000;
      mouse-hide-while-typing = true;
      confirm-close-surface = false;
      quit-after-last-window-closed = true;

      audio-bell = false;
      visual-bell = "color";
      visual-bell-duration = "200ms";

      shell-integration = "detect";
      shell-integration-features = "cursor,sudo,title";

      window-opacity =
        if values.theme.transparency.enable then values.theme.transparency.opacity else 1.0;

      macos-titlebar-style = "tabs";
      macos-option-as-alt = true;
      macos-titlebar-proxy-icon = "visible";

      gtk-tabs-location = "top";
      tab-width = 8;

      keybind = [
        "cmd+t=new_tab"
        "cmd+w=close_surface"
        "cmd+shift+w=close_all_windows"
        "cmd+n=new_window"
        "cmd+shift+n=new_split:right"
        "cmd+d=new_split:down"
        "cmd+shift+d=new_split:right"
        "cmd+left_bracket=previous_tab"
        "cmd+right_bracket=next_tab"
        "cmd+1=goto_tab:1"
        "cmd+2=goto_tab:2"
        "cmd+3=goto_tab:3"
        "cmd+4=goto_tab:4"
        "cmd+5=goto_tab:5"
        "cmd+6=goto_tab:6"
        "cmd+7=goto_tab:7"
        "cmd+8=goto_tab:8"
        "cmd+9=goto_tab:9"
        "cmd+plus=increase_font_size:1"
        "cmd+minus=decrease_font_size:1"
        "cmd+zero=reset_font_size"
        "cmd+c=copy_to_clipboard"
        "cmd+v=paste_from_clipboard"
        "cmd+k=clear_screen"
        "cmd+f=toggle_fullscreen"
      ];
    };

    # Only create custom theme if no built-in theme exists
    themes = lib.mkIf (!hasBuiltInTheme) {
      "${values.theme.colorscheme}-${values.theme.variant}" = customTheme;
    };
  };
}
