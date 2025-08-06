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
  toSketchybarColor =
    color:
    let
      cleaned = lib.removePrefix "#" color;
    in
    "0xff${cleaned}";

  toHexColor =
    color:
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

    # Floating bar configuration
    BAR_HEIGHT=36
    Y_OFFSET=8        # Float from top
    CORNER_RADIUS=12  # Rounded corners
    BLUR_RADIUS=30    # Background blur

    PADDING_LEFT=16
    PADDING_RIGHT=16
    MARGIN=0

    sketchybar --bar \
      height=$BAR_HEIGHT \
      color=0xaa24273a \
      position=top \
      y_offset=$Y_OFFSET \
      margin=$MARGIN \
      padding_left=$PADDING_LEFT \
      padding_right=$PADDING_RIGHT \
      corner_radius=$CORNER_RADIUS \
      blur_radius=$BLUR_RADIUS \
      sticky=off \
      shadow=on
  '';

in
{
  services.sketchybar = {
    package = pkgs.sketchybar;
    enable = true;
    extraPackages = [ pkgs.sketchybar-app-font ];

    config = ''
      #!/usr/bin/env bash

      # Plugin directory
      PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

      # Source display helper if available
      if [ -f "$PLUGIN_DIR/display_helper.sh" ]; then
          source "$PLUGIN_DIR/display_helper.sh"
      fi

      ${barConfig}

      # Default item configuration - with JetBrains Mono Nerd Font
      sketchybar --default \
        icon.font="JetBrainsMono Nerd Font:Bold:16.0" \
        icon.color=0xffcad3f5 \
        icon.padding_left=4 \
        icon.padding_right=2 \
        label.font="JetBrainsMono Nerd Font:Medium:13.0" \
        label.color=0xffcad3f5 \
        label.padding_left=2 \
        label.padding_right=8 \
        background.drawing=off

      # === LEFT SIDE ===

      # Left side items
      sketchybar --add item apple.logo left \
      --set apple.logo \
        icon="" \
        click_script="$PLUGIN_DIR/apple_menu.sh"

      sketchybar --add item front_app left \
      --set front_app \
        script="$PLUGIN_DIR/front_app.sh" \
      --subscribe front_app front_app_switched

      sketchybar --add item aerospace left \
      --set aerospace \
        script="$PLUGIN_DIR/aerospace.sh" \
        update_freq=0.5 \
      --subscribe aerospace aerospace_workspace_change space_change

      # Left divider after aerospace
      sketchybar --add item left_divider left \
      --set left_divider \
        icon="│" \
        icon.color=0x60cad3f5 \
        label="" \
        background.drawing=off

      # === RIGHT SIDE ===

      # Right side items - simplified
      sketchybar --add item clock right \
      --set clock \
        script="$PLUGIN_DIR/clock.sh" \
        click_script="open /System/Applications/Calendar.app" \
        update_freq=30

      sketchybar --add item battery right \
      --set battery \
        script="$PLUGIN_DIR/battery.sh" \
        click_script="open /System/Library/PreferencePanes/Battery.prefPane" \
        update_freq=60 \
      --subscribe battery system_woke power_source_change

      # Right divider before volume
      sketchybar --add item right_divider1 right \
      --set right_divider1 \
        icon="│" \
        icon.color=0x60cad3f5 \
        label="" \
        background.drawing=off

      sketchybar --add slider volume_slider right 100 \
      --set volume_slider \
        slider.highlight_color=0xff8aadf4 \
        slider.background.height=6 \
        slider.background.corner_radius=3 \
        slider.background.color=0x60cad3f5 \
        slider.knob="" \
        script="$PLUGIN_DIR/volume.sh slider" \
        click_script="$PLUGIN_DIR/volume.sh set_slider" \
      --subscribe volume_slider volume_change mouse.clicked

      sketchybar --add item volume right \
      --set volume \
        script="$PLUGIN_DIR/volume.sh" \
        click_script="sketchybar --set volume popup.drawing=toggle" \
        popup.background.corner_radius=8 \
        popup.background.color=0xaa24273a \
        popup.blur_radius=20 \
        popup.height=35 \
      --subscribe volume volume_change

      # Volume popup items
      sketchybar --add item volume.mute popup.volume \
      --set volume.mute \
        icon="󰸈" \
        label="Toggle Mute" \
        click_script="$PLUGIN_DIR/volume.sh toggle; sketchybar --set volume popup.drawing=off"

      sketchybar --add item volume.25 popup.volume \
      --set volume.25 \
        icon="󰖀" \
        label="25%" \
        click_script="$PLUGIN_DIR/volume.sh set 25; sketchybar --set volume popup.drawing=off"

      sketchybar --add item volume.50 popup.volume \
      --set volume.50 \
        icon="󰖁" \
        label="50%" \
        click_script="$PLUGIN_DIR/volume.sh set 50; sketchybar --set volume popup.drawing=off"

      sketchybar --add item volume.75 popup.volume \
      --set volume.75 \
        icon="󰕾" \
        label="75%" \
        click_script="$PLUGIN_DIR/volume.sh set 75; sketchybar --set volume popup.drawing=off"

      sketchybar --add item volume.100 popup.volume \
      --set volume.100 \
        icon="󰕾" \
        label="100%" \
        click_script="$PLUGIN_DIR/volume.sh set 100; sketchybar --set volume popup.drawing=off"

      # === FINALIZE ===

      # Add animations for smooth transitions
      sketchybar --animate tanh 20 --bar y_offset=8

      # Update all items with animation
      sketchybar --animate sin 15 --update

      echo "SketchyBar configuration loaded successfully"
    '';
  };
}

