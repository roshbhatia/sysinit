{
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

  # Color format helpers
  toSketchybarColor = color: "0xff${lib.removePrefix "#" color}";
  toHexColor = color: "0x${lib.removePrefix "#" color}";

  # Raw color fallback map
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

  # Sketchybar-formatted colors
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

  sharedBackground = "0x44${lib.removePrefix "#" rawColors.foreground}";
  sharedBorder = "0x66${lib.removePrefix "#" rawColors.foreground}";

  barConfig = ''
    BAR_HEIGHT=34
    Y_OFFSET=4
    CORNER_RADIUS=6
    BLUR_RADIUS=50
    PADDING_LEFT=16
    PADDING_RIGHT=16
    MARGIN=0

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
      sticky=off \
      shadow=off
  '';
in
{
  services.sketchybar = {
    package = pkgs.sketchybar;
    enable = true;
    extraPackages = [ pkgs.sketchybar-app-font ];

    config = ''
      #!/usr/bin/env bash

      PLUGIN_DIR="$HOME/.config/sketchybar/plugins"
      [ -f "$PLUGIN_DIR/display_helper.sh" ] && source "$PLUGIN_DIR/display_helper.sh"

      ${barConfig}

      # Defaults with dynamic colors
      sketchybar --default \
        icon.font="JetBrainsMono Nerd Font:Bold:15.0" \
        icon.color=${colors.text} \
        icon.padding_left=8 \
        icon.padding_right=4 \
        label.font="JetBrainsMono Nerd Font:Medium:13.0" \
        label.color=${colors.text} \
        label.padding_left=4 \
        label.padding_right=8 \
        background.drawing=off

      # === LEFT SIDE ITEMS ===
      sketchybar --add item apple.logo left \
        --set apple.logo icon="" click_script="$PLUGIN_DIR/apple_menu.sh"

      sketchybar --add item front_app left \
        --set front_app script="$PLUGIN_DIR/front_app.sh" \
        --subscribe front_app front_app_switched

      sketchybar --add item aerospace left \
        --set aerospace script="$PLUGIN_DIR/aerospace.sh" update_freq=0.5 \
        --subscribe aerospace aerospace_workspace_change space_change

      sketchybar --add bracket left_bracket apple.logo front_app aerospace \
        --set left_bracket \
          background.color=${sharedBackground} \
          background.corner_radius=6 \
          background.height=26 \
          background.border_width=1 \
          background.border_color=${sharedBorder}

      # === RIGHT SIDE ITEMS ===
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

      sketchybar --add item volume right \
        --set volume \
          script="$PLUGIN_DIR/volume.sh" \
          click_script="sketchybar --set volume popup.drawing=toggle" \
          popup.background.corner_radius=6 \
          popup.background.color=0x66${lib.removePrefix "#" rawColors.background} \
          popup.blur_radius=30 \
          popup.height=35 \
        --subscribe volume volume_change

      sketchybar --add bracket right_bracket battery volume clock \
        --set right_bracket \
          background.color=${sharedBackground} \
          background.corner_radius=6 \
          background.height=26 \
          background.border_width=1 \
          background.border_color=${sharedBorder}

      # === VOLUME POPUP ===
      sketchybar --add item volume.mute popup.volume \
        --set volume.mute \
          icon="󰸈" \
          label="Toggle Mute" \
          click_script="$PLUGIN_DIR/volume.sh toggle; sketchybar --set volume popup.drawing=off"

      for level in 25 50 75 100; do
        sketchybar --add item volume.$level popup.volume \
          --set volume.$level \
            icon="󰖀" \
            label="$level%" \
            click_script="$PLUGIN_DIR/volume.sh set $level; sketchybar --set volume popup.drawing=off"
      done

      # Smooth transition
      sketchybar --animate tanh 15 --bar y_offset=4

      sketchybar --update
      echo "SketchyBar configuration loaded successfully"
    '';
  };
}

