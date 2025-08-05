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

  # Create sketchybar plugin files through home-manager
  # Note: nix-darwin doesn't directly support home.file, but we can use system.activationScripts
  system.activationScripts.sketchybar-plugins.text = ''
    mkdir -p /Users/${values.user.username}/.config/sketchybar/plugins

    # workspace_strip.sh - Aerospace integration
    cat > /Users/${values.user.username}/.config/sketchybar/plugins/workspace_strip.sh << 'EOF'
#!/usr/bin/env bash
if command -v aerospace &> /dev/null; then
    focused_workspace=$(aerospace list-workspaces --focused)
    sketchybar --set workspace_strip label="$focused_workspace"
else
    sketchybar --set workspace_strip label="N/A"
fi
EOF

    # space.sh - Space/Desktop switcher
    cat > /Users/${values.user.username}/.config/sketchybar/plugins/space.sh << 'EOF'
#!/usr/bin/env bash
if command -v yabai &> /dev/null; then
    CURRENT_SPACE=$(yabai -m query --spaces --space | jq -r .index)
    if [ "$CURRENT_SPACE" == "$NAME" ]; then
        sketchybar --set "$NAME" background.drawing=on
    else
        sketchybar --set "$NAME" background.drawing=off
    fi
else
    sketchybar --set "$NAME" background.drawing=off
fi
EOF

    # front_app.sh - Front app display
    cat > /Users/${values.user.username}/.config/sketchybar/plugins/front_app.sh << 'EOF'
#!/usr/bin/env bash
FRONT_APP=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')
if [ ''${#FRONT_APP} -gt 20 ]; then
    FRONT_APP=$(echo "$FRONT_APP" | cut -c1-20)...
fi
sketchybar --set front_app label="$FRONT_APP"
EOF

    # clock.sh - Clock display
    cat > /Users/${values.user.username}/.config/sketchybar/plugins/clock.sh << 'EOF'
#!/usr/bin/env bash
CURRENT_TIME=$(date '+%I:%M %p')
CURRENT_DATE=$(date '+%m/%d')
sketchybar --set clock label="$CURRENT_TIME $CURRENT_DATE"
EOF

    # volume.sh - Volume control
    cat > /Users/${values.user.username}/.config/sketchybar/plugins/volume.sh << 'EOF'
#!/usr/bin/env bash
VOLUME=$(osascript -e 'output volume of (get volume settings)')
MUTED=$(osascript -e 'output muted of (get volume settings)')
if [ "$MUTED" == "true" ]; then
    ICON=""
    LABEL="Muted"
elif [ "$VOLUME" -eq 0 ]; then
    ICON=""
    LABEL="0%"
elif [ "$VOLUME" -lt 33 ]; then
    ICON=""
    LABEL="$VOLUME%"
elif [ "$VOLUME" -lt 66 ]; then
    ICON=""
    LABEL="$VOLUME%"
else
    ICON=""
    LABEL="$VOLUME%"
fi
sketchybar --set volume icon="$ICON" label="$LABEL"
EOF

    # battery.sh - Battery status
    cat > /Users/${values.user.username}/.config/sketchybar/plugins/battery.sh << 'EOF'
#!/usr/bin/env bash
BATTERY_INFO=$(pmset -g batt)
BATTERY_PERCENT=$(echo "$BATTERY_INFO" | grep -Eo "\d+%" | cut -d% -f1)
CHARGING_STATE=$(echo "$BATTERY_INFO" | grep -o "AC Power\|Battery Power")
if [ "$CHARGING_STATE" == "AC Power" ]; then
    ICON=""
elif [ "$BATTERY_PERCENT" -gt 75 ]; then
    ICON=""
elif [ "$BATTERY_PERCENT" -gt 50 ]; then
    ICON=""
elif [ "$BATTERY_PERCENT" -gt 25 ]; then
    ICON=""
else
    ICON=""
fi
sketchybar --set battery icon="$ICON" label="$BATTERY_PERCENT%"
EOF

    # apple_menu.sh - Apple menu
    cat > /Users/${values.user.username}/.config/sketchybar/plugins/apple_menu.sh << 'EOF'
#!/usr/bin/env bash
osascript << APPLESCRIPT
display dialog "System Menu" buttons {"About This Mac", "System Preferences", "Cancel"} default button "Cancel" with title "Apple Menu"
set choice to button returned of result
if choice is "About This Mac" then
    tell application "System Information" to activate
else if choice is "System Preferences" then
    tell application "System Preferences" to activate
end if
APPLESCRIPT
EOF

    # Make all plugin scripts executable
    chmod +x /Users/${values.user.username}/.config/sketchybar/plugins/*.sh
  '';
}
