{
}:

{
  createK9sTheme =
    theme: validatedConfig:
    let
      palette = theme.palettes.${validatedConfig.variant};
      semanticColors = theme.semanticMapping palette;

      k9sColors = {
        primary = semanticColors.foreground.primary;
        background = semanticColors.background.primary;
        secondary = semanticColors.foreground.secondary;
        muted = semanticColors.foreground.muted;
        accent = semanticColors.accent.primary;
        error = semanticColors.semantic.error;
        warning = semanticColors.semantic.warning;
        success = semanticColors.semantic.success;
        info = semanticColors.semantic.info;
        border = semanticColors.accent.primary;
        selection = semanticColors.accent.primary;
        highlight = semanticColors.accent.secondary;
        muted_light = semanticColors.background.tertiary;
        muted_dark = semanticColors.background.overlay;
      };

      generateK9sYaml = _themeId: ''
        k9s:
          body:
            fgColor: "${k9sColors.primary}"
            bgColor: default
            logoColor: "${k9sColors.accent}"
          prompt:
            fgColor: "${k9sColors.primary}"
            bgColor: default
            suggestColor: "${k9sColors.info}"
          help:
            fgColor: "${k9sColors.primary}"
            bgColor: default
            sectionColor: "${k9sColors.info}"
            keyColor: "${k9sColors.accent}"
            numKeyColor: "${k9sColors.error}"
          frame:
            title:
              fgColor: "${k9sColors.info}"
              bgColor: default
              highlightColor: "${k9sColors.warning}"
              counterColor: "${k9sColors.error}"
              filterColor: "${k9sColors.accent}"
            border:
              fgColor: "${k9sColors.accent}"
              focusColor: "${k9sColors.info}"
            menu:
              fgColor: "${k9sColors.primary}"
              keyColor: "${k9sColors.accent}"
              numKeyColor: "${k9sColors.error}"
            crumbs:
              fgColor: "${k9sColors.muted_dark}"
              bgColor: default
              activeColor: "${k9sColors.highlight}"
            status:
              newColor: "${k9sColors.accent}"
              modifyColor: "${k9sColors.info}"
              addColor: "${k9sColors.accent}"
              pendingColor: "${k9sColors.warning}"
              errorColor: "${k9sColors.error}"
              highlightColor: "${k9sColors.accent}"
              killColor: "${k9sColors.accent}"
              completedColor: "${k9sColors.muted}"
          info:
            fgColor: "${k9sColors.warning}"
            sectionColor: "${k9sColors.primary}"
          views:
            table:
              fgColor: "${k9sColors.primary}"
              bgColor: default
              cursorFgColor: "${k9sColors.muted_dark}"
              cursorBgColor: "${k9sColors.muted_light}"
              markColor: "${k9sColors.highlight}"
              header:
                fgColor: "${k9sColors.warning}"
                bgColor: default
                sorterColor: "${k9sColors.accent}"
            xray:
              fgColor: "${k9sColors.primary}"
              bgColor: default
              cursorColor: "${k9sColors.muted_light}"
              cursorTextColor: "${k9sColors.muted_dark}"
              graphicColor: "${k9sColors.error}"
            charts:
              bgColor: default
              chartBgColor: default
              dialBgColor: default
              defaultDialColors:
                - "${k9sColors.accent}"
                - "${k9sColors.error}"
              defaultChartColors:
                - "${k9sColors.accent}"
                - "${k9sColors.error}"
              resourceColors:
                cpu:
                  - "${k9sColors.accent}"
                  - "${k9sColors.info}"
                mem:
                  - "${k9sColors.warning}"
                  - "${k9sColors.error}"
            yaml:
              keyColor: "${k9sColors.accent}"
              valueColor: "${k9sColors.primary}"
              colonColor: "${k9sColors.muted}"
            logs:
              fgColor: "${k9sColors.primary}"
              bgColor: default
              indicator:
                fgColor: "${k9sColors.info}"
                bgColor: default
                toggleOnColor: "${k9sColors.accent}"
                toggleOffColor: "${k9sColors.muted}"
          dialog:
            fgColor: "${k9sColors.warning}"
            bgColor: default
            buttonFgColor: "${k9sColors.muted_dark}"
            buttonBgColor: default
            buttonFocusFgColor: "${k9sColors.muted_dark}"
            buttonFocusBgColor: "${k9sColors.error}"
            labelFgColor: "${k9sColors.highlight}"
            fieldFgColor: "${k9sColors.primary}"
      '';
    in
    {
      themeYaml = generateK9sYaml "${validatedConfig.colorscheme}-${validatedConfig.variant}";
      inherit k9sColors;
    };
}
