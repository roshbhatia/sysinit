{ lib, utils, values, ... }:

let
  inherit (utils.themes) validateThemeConfig getThemePalette;

  validatedTheme = validateThemeConfig values.theme;
  palette = getThemePalette validatedTheme.colorscheme validatedTheme.variant;
  semanticColors = utils.themes.utils.createSemanticMapping palette;

  getColor = color: fallback:
    if color != null then color else fallback;

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

  toYAML = config:
    let
      indent = n: lib.concatStrings (lib.genList (_: "  ") n);

      valueToYAML = level: value:
        if builtins.isAttrs value then
          attrsToYAML level value
        else if builtins.isList value then
          listToYAML level value
        else if builtins.isBool value then
          if value then "true" else "false"
        else if builtins.isString value then
          if builtins.match "^(true|false|yes|no|[0-9]+)$" value != null then
            ''"${value}"''
          else
            value
        else
          toString value;

      attrsToYAML = level: attrs:
        lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value:
          let
            key = "${indent level}${name}:";
          in
          if builtins.isAttrs value && value != {} then
            "${key}\n${valueToYAML (level + 1) value}"
          else if builtins.isList value then
            "${key}\n${valueToYAML (level + 1) value}"
          else
            "${key} ${valueToYAML level value}"
        ) attrs);

      listToYAML = level: list:
        lib.concatStringsSep "\n" (lib.imap0 (idx: item:
          if builtins.isAttrs item then
            let
              attrs = lib.mapAttrsToList (name: value:
                let key = "${name}:";
                in
                if builtins.isAttrs value && value != {} then
                  "${key}\n${valueToYAML (level + 2) value}"
                else if builtins.isList value then
                  "${key}\n${valueToYAML (level + 2) value}"
                else
                  "${key} ${valueToYAML (level + 1) value}"
              ) item;
              firstAttr = lib.head attrs;
              restAttrs = lib.tail attrs;
            in
            if restAttrs == [] then
              "${indent level}- ${firstAttr}"
            else
              "${indent level}- ${firstAttr}\n${indent (level + 1)}${lib.concatStringsSep ("\n" + indent (level + 1)) restAttrs}"
          else
            "${indent level}- ${valueToYAML level item}"
        ) list);

    in ''
      # yaml-language-server: $schema=https://gh-dash.dev/schema.json

      ${valueToYAML 0 config}
    '';

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
      diff = "delta";
    };

    defaults = {
      refetchIntervalMinutes = 1;
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
    text = toYAML ghDashConfig;
    force = true;
  };
}
