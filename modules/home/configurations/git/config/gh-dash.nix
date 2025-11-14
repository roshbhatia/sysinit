{
  lib,
  utils,
  values,
  ...
}:

let
  inherit (utils.themes) validateThemeConfig getThemePalette;

  validatedTheme = validateThemeConfig values.theme;
  palette = getThemePalette validatedTheme.colorscheme validatedTheme.variant;
  semanticColors = utils.themes.utils.createSemanticMapping palette;

  getColor = color: fallback: if color != null then color else fallback;

  themeColors = {
    text = {
      primary = semanticColors.foreground.primary;
      secondary = semanticColors.foreground.secondary;
      inverted = semanticColors.background.primary;
      faint = semanticColors.foreground.muted;
      warning = semanticColors.semantic.error;
      success = semanticColors.semantic.success;
    };

    background = {
      selected = semanticColors.accent.dim or semanticColors.background.tertiary;
    };

    border = {
      primary = getColor (palette.surface1 or null) semanticColors.background.secondary;
      secondary = getColor (palette.surface2 or null) semanticColors.background.tertiary;
      faint = semanticColors.background.secondary;
    };

    inline.icons = {
      newcontributor = "077";
      contributor = "075";
      collaborator = "178";
      member = "178";
      owner = "178";
      unknownrole = "178";
    };
  };

  themeIcons = {
    inline = {
      newcontributor = "󰎔";
      contributor = "";
      collaborator = "";
      member = "";
      owner = "󱇐";
      unknownrole = "󱐡";
    };
  };

  ghDashConfig = {
    prSections = [
      {
        title = "Open Requests";
        filters = "is:open";
      }
      {
        title = "My Pull Requests";
        filters = "is:open author:@me";
      }
      {
        title = "Needs My Review";
        filters = "is:open review-requested:@me";
      }
      {
        title = "Involved";
        filters = "is:open involves:@me -author:@me";
      }
    ];

    pager = {
      diff = "diffnav";
    };

    defaults = {
      refetchIntervalMinutes = 1;
    };

    keybindings = {
      universal = [
        {
          key = "g";
          name = "lazygit";
          command = "lazygit";
        }
        {
          key = "C";
          name = "Code Review";
          command = "nvim -c ':silent Octo pr edit {{.PrNumber}}'";
        }
      ];
    };

    theme = {
      ui = {
        sectionsShowCount = true;
        table = {
          showSeparators = true;
          compact = true;
        };
      };

      colors = {
        text = themeColors.text;
        background = themeColors.background;
        border = themeColors.border;
        inline.icons = themeColors.inline.icons;
      };

      icons = themeIcons;
    };
  };

in
{
  xdg.configFile."gh-dash/config.yml" = {
    text = lib.generators.toYAML { } ghDashConfig;
    force = true;
  };
}
