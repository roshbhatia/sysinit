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

  theme = themes.getTheme sketchybarThemeName;
  sketchybarColors =
    if theme ? appAdapters && theme.appAdapters ? sketchybar then
      theme.appAdapters.sketchybar
    else
      throw "Theme '${sketchybarThemeName}' does not provide a SketchyBar adapter.";

  hex = c: lib.removePrefix "#" c;
  toHex = c: "0x${hex c}";
  toSketchybar = c: "0xff${hex c}";
  toAlphaHex = alpha: c: "0x${alpha}${hex c}";

  raw = {
    background = sketchybarColors.background or (throw "Missing 'background' in sketchybar theme.");
    foreground = sketchybarColors.foreground or (throw "Missing 'foreground' in sketchybar theme.");
    accent = sketchybarColors.accent or (throw "Missing 'accent' in sketchybar theme.");
    muted = sketchybarColors.muted or (throw "Missing 'muted' in sketchybar theme.");
    highlight = sketchybarColors.highlight or (throw "Missing 'highlight' in sketchybar theme.");
    success = sketchybarColors.success or (throw "Missing 'success' in sketchybar theme.");
    warning = sketchybarColors.warning or (throw "Missing 'warning' in sketchybar theme.");
    error = sketchybarColors.error or (throw "Missing 'error' in sketchybar theme.");
  };

  barColor = toSketchybar raw.background;
  textColor = toHex raw.foreground;
  popupBgColor = toAlphaHex "66" raw.background;
  bracketBg = toAlphaHex "44" raw.foreground;
  bracketBorder = toAlphaHex "66" raw.foreground;

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

  workspaceConfig = ''
    for sid in $(aerospace list-workspaces --all); do
      sketchybar --add item space.$sid left \
        --subscribe space.$sid aerospace_workspace_change \
        --set space.$sid \
          background.color=${bracketBg} \
          background.corner_radius=6 \
          background.height=20 \
          background.drawing=off \
          label="$sid" \
          click_script="aerospace workspace $sid" \
          script="$PLUGIN_DIR/aerospace.sh $sid"
    done
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

      ${barConfig}

      sketchybar --default \
        icon.font="JetBrainsMono Nerd Font:Bold:15.0" \
        icon.color=${textColor} \
        icon.padding_left=8 \
        icon.padding_right=4 \
        label.font="JetBrainsMono Nerd Font:Medium:13.0" \
        label.color=${textColor} \
        label.padding_left=4 \
        label.padding_right=8 \
        background.drawing=off

      sketchybar --add item apple.logo left \
        --set apple.logo \
          icon="" \
          click_script="$PLUGIN_DIR/apple_menu.sh"

      sketchybar --add item front_app left \
        --set front_app \
          script="$PLUGIN_DIR/front_app.sh" \
        --subscribe front_app front_app_switched

      ${workspaceConfig}

      sketchybar --add bracket left_bracket apple.logo front_app \
        --set left_bracket \
          background.color=${bracketBg} \
          background.corner_radius=6 \
          background.height=26 \
          background.border_width=1 \
          background.border_color=${bracketBorder}

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
          popup.background.color=${popupBgColor} \
          popup.blur_radius=30 \
          popup.height=35 \
        --subscribe volume volume_change

      sketchybar --add bracket right_bracket battery volume clock \
        --set right_bracket \
          background.color=${bracketBg} \
          background.corner_radius=6 \
          background.height=26 \
          background.border_width=1 \
          background.border_color=${bracketBorder}

      sketchybar --animate tanh 15 --bar y_offset=4
      sketchybar --update

      echo "SketchyBar configuration loaded successfully"
    '';
  };
}
