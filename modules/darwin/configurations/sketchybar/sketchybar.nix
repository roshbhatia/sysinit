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

  textColor = toSketchybar raw.foreground;
  accentColor = toSketchybar raw.accent;
  highlightColor = toSketchybar raw.highlight;
  mutedColor = toSketchybar raw.muted;
  successColor = toSketchybar raw.success;
  errorColor = toSketchybar raw.error;
  warningColor = toSketchybar raw.warning;
  popupBgColor = toAlphaHex "aa" raw.background;
  bracketBg = toAlphaHex "33" raw.foreground;
  bracketBorder = toAlphaHex "66" raw.highlight;

  barConfig = ''
    sketchybar --bar \
      height=34 \
      color=${toAlphaHex "00" raw.background} \
      position=top \
      y_offset=4 \
      margin=0 \
      padding_left=0 \
      padding_right=0 \
      corner_radius=0 \
      blur_radius=50 \
      sticky=off \
      shadow=off
  '';

  workspaceConfig = ''
    for sid in $(aerospace list-workspaces --all); do
      sketchybar --add item space.$sid left \
        --subscribe space.$sid aerospace_workspace_change \
        --set space.$sid \
          background.color=${bracketBg} \
          background.border_color=${bracketBorder} \
          background.border_width=1 \
          background.corner_radius=6 \
          background.height=26 \
          background.drawing=on \
          icon.font="JetBrainsMono Nerd Font:Bold:15.0" \
          icon.color=${mutedColor} \
          label.font="JetBrainsMono Nerd Font:Medium:13.0" \
          label.color=${textColor} \
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
      #!/usr/bin/env zsh

      PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

      ${barConfig}

      sketchybar --default \
        icon.font="JetBrainsMono Nerd Font:Bold:15.0" \
        icon.color=${mutedColor} \
        icon.padding_left=8 \
        icon.padding_right=4 \
        label.font="JetBrainsMono Nerd Font:Medium:13.0" \
        label.color=${textColor} \
        label.padding_left=4 \
        label.padding_right=8 \
        background.drawing=off

      # Bar items

      sketchybar --add item left_padding left \
        --set left_padding width=16

      sketchybar --add item front_app left \
        --set front_app \
          background.color=${bracketBg} \
          background.corner_radius=6 \
          background.border_width=1 \
          background.border_color=${bracketBorder} \
          background.height=26 \
          icon.color=${accentColor} \
          script="$PLUGIN_DIR/front_app.sh" \
        --subscribe front_app front_app_switched

      sketchybar --add item spaces left \
        --set spaces \
          background.color=${toAlphaHex "00" raw.background} \
          y_offset=0

      ${workspaceConfig}

      sketchybar --add item right_padding right \
        --set right_padding width=16

      sketchybar --add item clock right \
        --set clock \
          icon=󰃰 \
          icon.color=${highlightColor} \
          label.font="JetBrainsMono Nerd Font:Bold:13.0" \
          background.color=${bracketBg} \
          background.corner_radius=6 \
          background.border_width=1 \
          background.border_color=${bracketBorder} \
          background.height=26 \
          script="$PLUGIN_DIR/clock.sh" \
          click_script="open /System/Applications/Calendar.app" \
          update_freq=30

      sketchybar --add item battery right \
        --set battery \
          background.color=${bracketBg} \
          background.corner_radius=6 \
          background.border_width=1 \
          background.border_color=${bracketBorder} \
          background.height=26 \
          script="$PLUGIN_DIR/battery.sh" \
          click_script="open /System/Library/PreferencePanes/Battery.prefPane" \
          update_freq=60 \
        --subscribe battery system_woke power_source_change

      sketchybar --add item volume right \
        --set volume \
          background.color=${bracketBg} \
          background.corner_radius=6 \
          background.border_width=1 \
          background.border_color=${bracketBorder} \
          background.height=26 \
          popup.background.corner_radius=6 \
          popup.background.color=${popupBgColor} \
          popup.blur_radius=30 \
          popup.height=35 \
          popup.y_offset=10 \
          popup.padding_left=10 \
          popup.padding_right=10 \
          script="$PLUGIN_DIR/volume.sh" \
          click_script="sketchybar --set volume popup.drawing=toggle" \
        --subscribe volume volume_change

      # Bracket groups

      sketchybar --add bracket left_group front_app spaces \
        --set left_group \
          background.color=${toAlphaHex "00" raw.background} \
          padding_left=8 \
          padding_right=8 \
          y_offset=4 \
          notch_width=150

      sketchybar --add bracket right_group clock battery volume \
        --set right_group \
          background.color=${toAlphaHex "00" raw.background} \
          padding_left=8 \
          padding_right=8 \
          y_offset=4

      # Final updates
      sketchybar --update

      echo "SketchyBar configuration loaded successfully"
    '';
  };
}

