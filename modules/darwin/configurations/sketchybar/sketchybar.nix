{
  config,
  lib,
  values,
  pkgs,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  appThemes = values.theme.appThemes or { };
  sketchybarTheme = appThemes.sketchybar or null;
  sketchybarThemeName =
    if sketchybarTheme != null && builtins.isAttrs sketchybarTheme then
      sketchybarTheme.name
    else if sketchybarTheme != null then
      sketchybarTheme
    else
      values.theme.colorscheme;
  sketchybarColors = (themes.getTheme sketchybarThemeName).appAdapters.sketchybar;

  # Helper functions for color conversion
  toSketchybarColor = color:
    let
      cleaned = lib.removePrefix "#" color;
    in
    "0xff${cleaned}";

  toHexColor = color:
    let
      cleaned = lib.removePrefix "#" color;
    in
    "0x${cleaned}";

  # Raw color values
  rawColors = {
    background = sketchybarColors.background or "#24273a";
    foreground = sketchybarColors.foreground or "#cad3f5";
    accent = sketchybarColors.accent or "#8aadf4";
    muted = sketchybarColors.muted or "#a5adcb";
    highlight = sketchybarColors.highlight or "#f5bde6";
    success = sketchybarColors.success or "#a6da95";
    warning = sketchybarColors.warning or "#eed49f";
    error = sketchybarColors.error or "#ed8796";
  };

  # Colors in proper sketchybar format
  barColor = toSketchybarColor rawColors.background;
  colors = {
    text = toHexColor rawColors.foreground;
    accent = toHexColor rawColors.accent;
    muted = toHexColor rawColors.muted;
    highlight = toHexColor rawColors.highlight;
    success = toHexColor rawColors.success;
    warning = toHexColor rawColors.warning;
    error = toHexColor rawColors.error;
  };

  # Dynamic positioning for notched displays
  barConfig = ''
    # Detect display capabilities
    DISPLAY_INFO=$(system_profiler SPDisplaysDataType 2>/dev/null)

    # Set bar configuration based on display
    BAR_HEIGHT=36
    Y_OFFSET=8
    CORNER_RADIUS=12
    BLUR_RADIUS=50

    # Check for notch (approximate detection)
    MODEL_INFO=$(system_profiler SPHardwareDataType 2>/dev/null | grep "Model Name" || echo "")
    if echo "$MODEL_INFO" | grep -q "MacBook Pro.*14\|MacBook Pro.*16"; then
        # Likely has notch, adjust accordingly
        PADDING_LEFT=20
        PADDING_RIGHT=20
        MARGIN=8
    else
        # Standard display
        PADDING_LEFT=12
        PADDING_RIGHT=12
        MARGIN=5
    fi

    sketchybar --bar \
      height=$BAR_HEIGHT \
      color=${barColor} \
      position=top \
      y_offset=$Y_OFFSET \
      margin=$MARGIN \
      padding_left=$PADDING_LEFT \
      padding_right=$PADDING_RIGHT \
      corner_radius=$CORNER_RADIUS \
      blur_radius=$BLUR_RADIUS \
      sticky=on \
      shadow=on
  '';

in
{
  services.sketchybar = {
    package = pkgs.sketchybar;
    enable = true;

    config = ''
      #!/usr/bin/env bash

      # Plugin directory
      PLUGIN_DIR="$CONFIG_DIR/plugins"

      # Source display helper if available
      if [ -f "$PLUGIN_DIR/display_helper.sh" ]; then
          source "$PLUGIN_DIR/display_helper.sh"
      fi

      ${barConfig}

      # Default item configuration
      sketchybar --default \
        icon.font="JetBrainsMono Nerd Font:Bold:16.0" \
        icon.color=${colors.muted} \
        icon.padding_left=4 \
        icon.padding_right=4 \
        label.font="JetBrainsMono Nerd Font:Medium:14.0" \
        label.color=${colors.text} \
        label.padding_left=4 \
        label.padding_right=4 \
        background.color=0x00000000 \
        background.corner_radius=6 \
        background.height=28

      # === LEFT SIDE ===

      # Apple logo / System menu
      sketchybar --add item apple.logo left \
      --set apple.logo \
        icon=󰀵 \
        icon.font="JetBrainsMono Nerd Font:Black:18.0" \
        icon.color=${colors.success} \
        icon.padding_left=8 \
        icon.padding_right=8 \
        label.drawing=off \
        click_script="$PLUGIN_DIR/apple_menu.sh"

      # Separator
      sketchybar --add item separator.left left \
      --set separator.left \
        icon="|" \
        icon.color=${colors.muted} \
        icon.padding_left=4 \
        icon.padding_right=8 \
        label.drawing=off

      # Aerospace workspace indicator
      sketchybar --add item aerospace left \
      --set aerospace \
        script="$PLUGIN_DIR/aerospace.sh" \
        update_freq=2 \
        icon.font="JetBrainsMono Nerd Font:Bold:16.0" \
        background.color=0x20${lib.removePrefix "0x" colors.accent} \
        background.corner_radius=8

      # Front app
      sketchybar --add item front_app left \
      --set front_app \
        script="$PLUGIN_DIR/front_app.sh" \
        icon.font="JetBrainsMono Nerd Font:Bold:16.0" \
        label.max_chars=20 \
        background.color=0x20${lib.removePrefix "0x" colors.highlight} \
        background.corner_radius=8 \
      --subscribe front_app front_app_switched

      # === RIGHT SIDE ===

      # System stats - CPU
      sketchybar --add item cpu right \
      --set cpu \
        script="$PLUGIN_DIR/system_stats.sh cpu" \
        update_freq=3 \
        icon.font="JetBrainsMono Nerd Font:Bold:14.0" \
        background.color=0x20${lib.removePrefix "0x" colors.warning} \
        background.corner_radius=6

      # System stats - Memory
      sketchybar --add item memory right \
      --set memory \
        script="$PLUGIN_DIR/system_stats.sh memory" \
        update_freq=5 \
        icon.font="JetBrainsMono Nerd Font:Bold:14.0" \
        background.color=0x20${lib.removePrefix "0x" colors.warning} \
        background.corner_radius=6

      # Volume
      sketchybar --add item volume right \
      --set volume \
        script="$PLUGIN_DIR/volume.sh" \
        icon.font="JetBrainsMono Nerd Font:Bold:16.0" \
        background.color=0x20${lib.removePrefix "0x" colors.accent} \
        background.corner_radius=8 \
      --subscribe volume volume_change

      # Battery
      sketchybar --add item battery right \
      --set battery \
        script="$PLUGIN_DIR/battery.sh" \
        update_freq=60 \
        icon.font="JetBrainsMono Nerd Font:Bold:16.0" \
        background.color=0x20${lib.removePrefix "0x" colors.success} \
        background.corner_radius=8 \
      --subscribe battery system_woke power_source_change

      # Separator
      sketchybar --add item separator.right right \
      --set separator.right \
        icon="|" \
        icon.color=${colors.muted} \
        icon.padding_left=8 \
        icon.padding_right=4 \
        label.drawing=off

      # Clock
      sketchybar --add item clock right \
      --set clock \
        script="$PLUGIN_DIR/clock.sh" \
        update_freq=30 \
        icon.font="JetBrainsMono Nerd Font:Bold:16.0" \
        icon.color=${colors.accent} \
        label.font="JetBrainsMono Nerd Font:Medium:14.0" \
        background.color=0x30${lib.removePrefix "0x" colors.text} \
        background.corner_radius=10 \
        icon.padding_left=8 \
        icon.padding_right=4 \
        label.padding_left=4 \
        label.padding_right=8

      # === FINALIZE ===

      # Update all items
      sketchybar --update

      echo "SketchyBar configuration loaded successfully"
    '';
  };
}
