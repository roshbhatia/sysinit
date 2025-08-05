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
  colorDefault = sketchybarColors.muted or "0x88ffffff";
  labelHighlight = sketchybarColors.highlight or "0xff99ccff";
  barColor = sketchybarColors.background or "#222222";
in
{
  services.sketchybar = {
    package = pkgs.sketchybar;
    enable = true;

    config = ''
      PLUGIN_DIR="$CONFIG_DIR/plugins"
      sketchybar --bar height=32 \
        y_offset=5 \
        margin=2 \
        position=top \
        padding_left=10 \
        padding_right=10 \
        blur_radius=30 \
        corner_radius=10 \
        color=${barColor}

      sketchybar --default width=32 \
        icon.font="JetBrainsMono Nerd Font:Bold:18.0" \
        icon.color=${colorDefault} \
        label.font="JetBrainsMono Nerd Font:Bold:18.0" \
        label.highlight_color="${labelHighlight}" \
        label.width=50 \
        label.color=${colorDefault}

      # Workspace strip (Aerospace integration)
      sketchybar --add bracket center_items center
      sketchybar --add item workspace_strip center
      sketchybar --set workspace_strip script="$PLUGIN_DIR/workspace_strip.sh" label.align=center
      sketchybar --add item app_name center
      sketchybar --set app_name label.align=center

      # Spaces (classic strip)
      SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10")
      for i in "''${!SPACE_ICONS[@]}"
      do
        sid="$(($i+1))"
        space=(
          space="$sid"
          icon="''${SPACE_ICONS[i]}"
          icon.padding_left=7
          icon.padding_right=7
          background.color=0x40ffffff
          background.corner_radius=5
          background.height=25
          label.drawing=off
          script="$PLUGIN_DIR/space.sh"
          click_script="yabai -m space --focus $sid"
        )
        sketchybar --add space space."$sid" left --set space."$sid" "''${space[@]}"
      done

      # App icons, front app, chevron
      sketchybar --add item chevron left \
        --set chevron icon= label.drawing=off \
        --add item front_app left \
        --set front_app icon.drawing=off script="$PLUGIN_DIR/front_app.sh" \
        --subscribe front_app front_app_switched

      # Clock, volume, battery
      sketchybar --add item clock right \
        --set clock update_freq=10 icon= script="$PLUGIN_DIR/clock.sh" \
        --add item volume right \
        --set volume script="$PLUGIN_DIR/volume.sh" \
        --subscribe volume volume_change \
        --add item battery right \
        --set battery update_freq=120 script="$PLUGIN_DIR/battery.sh" \
        --subscribe battery system_woke power_source_change

      # Apple menu (custom popup)
      sketchybar --add item apple.logo left
      sketchybar --set apple.logo \
        icon=󰀵 \
        icon.font="JetBrainsMono Nerd Font:Black:16.0" \
        icon.color=${sketchybarColors.success or "0xffaaffaa"} \
        padding_right=15 \
        label.drawing=off \
        click_script="$PLUGIN_DIR/apple_menu.sh"

      sketchybar --update
    '';
  };
}
