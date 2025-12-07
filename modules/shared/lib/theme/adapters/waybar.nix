{
  lib,
  ...
}:

{
  createWaybarTheme =
    theme: validatedConfig:
    let
      palette = theme.palettes.${validatedConfig.variant};
      semanticColors = theme.semanticMapping palette;

      # Helper to convert hex digit to integer
      hexDigitToInt =
        digit:
        let
          digits = {
            "0" = 0;
            "1" = 1;
            "2" = 2;
            "3" = 3;
            "4" = 4;
            "5" = 5;
            "6" = 6;
            "7" = 7;
            "8" = 8;
            "9" = 9;
            "a" = 10;
            "b" = 11;
            "c" = 12;
            "d" = 13;
            "e" = 14;
            "f" = 15;
            "A" = 10;
            "B" = 11;
            "C" = 12;
            "D" = 13;
            "E" = 14;
            "F" = 15;
          };
        in
        digits.${digit};

      # Helper to convert 2-char hex string to integer
      hexToInt =
        hex:
        let
          high = hexDigitToInt (lib.substring 0 1 hex);
          low = hexDigitToInt (lib.substring 1 1 hex);
        in
        high * 16 + low;

      # Helper to convert hex color to RGB values for use in rgba()
      # e.g., "#ff0000" -> "255, 0, 0"
      hexToRgb =
        hex:
        let
          # Remove # if present
          cleanHex = if lib.hasPrefix "#" hex then lib.substring 1 (lib.stringLength hex - 1) hex else hex;
          # Ensure 6-character hex
          normalizedHex = lib.fixedWidthString 6 "0" cleanHex;
          # Extract RGB components
          r = hexToInt (lib.substring 0 2 normalizedHex);
          g = hexToInt (lib.substring 2 2 normalizedHex);
          b = hexToInt (lib.substring 4 2 normalizedHex);
        in
        "${toString r}, ${toString g}, ${toString b}";

      waybarColors = {
        background = semanticColors.background.primary;
        backgroundRgb = hexToRgb semanticColors.background.primary;
        foreground = semanticColors.foreground.primary;
        accent = semanticColors.accent.primary;
        accentRgb = hexToRgb semanticColors.accent.primary;
        accentSecondary = semanticColors.accent.secondary;
        accentSecondaryRgb = hexToRgb semanticColors.accent.secondary;
        success = semanticColors.semantic.success;
        successRgb = hexToRgb semanticColors.semantic.success;
        warning = semanticColors.semantic.warning;
        warningRgb = hexToRgb semanticColors.semantic.warning;
        error = semanticColors.semantic.error;
        errorRgb = hexToRgb semanticColors.semantic.error;
        info = semanticColors.semantic.info;
        infoRgb = hexToRgb semanticColors.semantic.info;
        muted = semanticColors.foreground.muted;
        mutedBg = semanticColors.background.tertiary;
        mutedBgRgb = hexToRgb semanticColors.background.tertiary;
      };

      # Generate CSS with theme colors
      generateWaybarCSS = _themeId: ''
        /* Waybar Styling */

        * {
          border: none;
          border-radius: 0;
          font-family: "JetBrains Mono", "Noto Sans", sans-serif;
          font-size: 13px;
          min-height: 0;
        }

        window#waybar {
          background-color: rgba(${waybarColors.backgroundRgb}, 0.8);
          color: ${waybarColors.foreground};
          transition-property: background-color;
          transition-duration: 0.5s;
        }

        window#waybar.hidden {
          opacity: 0.2;
        }

        /* Modules */
        #workspaces,
        #window,
        #clock,
        #tray,
        #cpu,
        #memory,
        #temperature,
        #pulseaudio {
          padding: 0 10px;
          margin: 0 4px;
        }

        /* Workspaces */
        #workspaces {
          padding: 0;
          margin: 0;
        }

        #workspaces button {
          padding: 8px 10px;
          color: ${waybarColors.accent};
          background-color: transparent;
          border-bottom: 3px solid transparent;
          transition: all 0.3s ease;
        }

        #workspaces button:hover {
          background-color: rgba(${waybarColors.accentRgb}, 0.1);
          color: ${waybarColors.accent};
        }

        #workspaces button.active {
          color: ${waybarColors.accent};
          border-bottom: 3px solid ${waybarColors.accent};
        }

        #workspaces button.persistent {
          color: ${waybarColors.muted};
        }

        /* Window title */
        #window {
          padding-left: 15px;
          padding-right: 15px;
          color: ${waybarColors.foreground};
        }

        /* Clock */
        #clock {
          background-color: rgba(${waybarColors.accentRgb}, 0.1);
          color: ${waybarColors.accent};
          border-radius: 8px;
          padding: 8px 15px;
        }

        /* System tray */
        #tray {
          background-color: rgba(${waybarColors.accentRgb}, 0.1);
          border-radius: 8px;
        }

        /* CPU */
        #cpu {
          background-color: rgba(${waybarColors.successRgb}, 0.1);
          color: ${waybarColors.success};
          border-radius: 8px;
          padding: 8px 12px;
        }

        /* Memory */
        #memory {
          background-color: rgba(${waybarColors.warningRgb}, 0.1);
          color: ${waybarColors.warning};
          border-radius: 8px;
          padding: 8px 12px;
        }

        /* Temperature */
        #temperature {
          background-color: rgba(${waybarColors.infoRgb}, 0.1);
          color: ${waybarColors.info};
          border-radius: 8px;
          padding: 8px 12px;
        }

        #temperature.critical {
          background-color: rgba(${waybarColors.errorRgb}, 0.2);
          color: ${waybarColors.error};
        }

        /* Pulseaudio */
        #pulseaudio {
          background-color: rgba(${waybarColors.accentSecondaryRgb}, 0.1);
          color: ${waybarColors.accentSecondary};
          border-radius: 8px;
          padding: 8px 12px;
        }

        #pulseaudio.muted {
          background-color: rgba(${waybarColors.mutedBgRgb}, 0.1);
          color: ${waybarColors.muted};
        }

        /* Tooltips */
        tooltip {
          background-color: rgba(${waybarColors.backgroundRgb}, 0.95);
          color: ${waybarColors.foreground};
          border-radius: 8px;
          border: 1px solid rgba(${waybarColors.accentRgb}, 0.2);
          padding: 8px 12px;
        }

        tooltip label {
          color: ${waybarColors.foreground};
        }
      '';
    in
    {
      themeCSS = generateWaybarCSS "${validatedConfig.colorscheme}-${validatedConfig.variant}";
      inherit waybarColors;
    };
}
