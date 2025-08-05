{ lib, values, ... }:

let
  themes = import ../../../lib/theme { inherit lib; };
  sketchybarTheme = values.theme.appThemes.sketchybar;
  sketchybarThemeName = if builtins.isAttrs sketchybarTheme then sketchybarTheme.name else sketchybarTheme;
  sketchybarThemeVariant = if builtins.isAttrs sketchybarTheme && sketchybarTheme ? variant then sketchybarTheme.variant else values.theme.variant;
  palette = themes.getThemePalette sketchybarThemeName sketchybarThemeVariant;
  colors = themes.getUnifiedColors palette;
  colorBlack = colors.black.primary or "0x40000000";
  colorDefault = colors.fgDim.primary or "0x88ffffff";
  labelHighlight = colors.accent.primary or "0xff99ccff";

  pluginDateLabel = ''
    #!/usr/bin/env zsh
    sketchybar --set "$NAME" label="$(date '+%m/%d %H:%M')"
  '';

  pluginBattery = ''
    #!/usr/bin/env zsh
    source "$CONFIG_DIR/plugins/colors.sh"
    PERCENTAGE="$(pmset -g batt | grep -Eo "\\d+%" | cut -d% -f1)"
    CHARGING="$(pmset -g batt | grep 'AC Power')"
    if [ "''${PERCENTAGE}" = "" ]; then exit 0; fi
    case ''${PERCENTAGE} in
      [8-9][0-9] | 100) ICON="􀛨"; ICON_COLOR=''${BATTERY_1} ;;
      7[0-9])           ICON="􀺸"; ICON_COLOR=''${BATTERY_2} ;;
      [4-6][0-9])       ICON="􀺶"; ICON_COLOR=''${BATTERY_3} ;;
      [1-3][0-9])       ICON="􀛩"; ICON_COLOR=''${BATTERY_4} ;;
      [0-9])            ICON="􀛪"; ICON_COLOR=''${BATTERY_5} ;;
    esac
    if [ ! -z "''${CHARGING}" ]; then ICON="􀢋"; ICON_COLOR=''${YELLOW}; fi
    sketchybar --set "$NAME" icon="$ICON" label=" ''${PERCENTAGE}%" icon.color="''${ICON_COLOR}"
  '';

  pluginAppleMenu = ''
    #!/usr/bin/env zsh
    source "$CONFIG_DIR/plugins/icons.sh"
    source "$CONFIG_DIR/plugins/colors.sh"
    POPUP_OFF='sketchybar --set apple.logo popup.drawing=off'
    POPUP_CLICK_SCRIPT='sketchybar --set $NAME popup.drawing=toggle'
    apple_logo=(
      icon=''${APPLE}
      icon.font="JetBrainsMono Nerd Font:Black:16.0"
      icon.color=''${GREEN}
      padding_right=15
      label.drawing=off
      click_script="$POPUP_CLICK_SCRIPT"
      popup.height=35
    )
    apple_prefs=(
      icon=''${PREFERENCES}
      label="Preferences"
      click_script="open -a 'System Preferences'; $POPUP_OFF"
    )
    apple_activity=(
      icon=''${ACTIVITY}
      label="Activity"
      click_script="open -a 'Activity Monitor'; $POPUP_OFF"
    )
    apple_lock=(
      icon=''${LOCK}
      label="Lock Screen"
      click_script="pmset displaysleepnow; $POPUP_OFF"
    )
    sketchybar --add item apple.logo left                  \
               --set apple.logo "''${apple_logo[@]}"         \
               --add item apple.prefs popup.apple.logo     \
               --set apple.prefs "''${apple_prefs[@]}"       \
               --add item apple.activity popup.apple.logo  \
               --set apple.activity "''${apple_activity[@]}" \
               --add item apple.lock popup.apple.logo      \
               --set apple.lock "''${apple_lock[@]}"
  '';

  pluginWorkspaceStrip = ''
    #!/usr/bin/env zsh
    AEROSPACE_FOCUSED_MONITOR_NO=$(aerospace list-workspaces --focused)
    AEROSPACE_LIST_OF_WINDOWS_IN_FOCUSED_MONITOR=$(aerospace list-windows --workspace $AEROSPACE_FOCUSED_MONITOR_NO | awk -F'|' '{gsub(/^ *| *$/, "" $2); print $2}')
    if [ "''${SENDER}" = "front_app_switched" ]; then
      sketchybar --set "$NAME" label="''${INFO}" icon.background.image="app.''${INFO}" icon.background.image.scale=0.8
      apps=''${AEROSPACE_LIST_OF_WINDOWS_IN_FOCUSED_MONITOR}
      icon_strip=" "
      if [ "''${apps}" != "" ]; then
        while read -r app; do
          icon_strip+=" $($CONFIG_DIR/plugins/icon_map.sh \"$app\")"
        done <<< "''${apps}"
      else
        icon_strip=" —"
      fi
      sketchybar --set space.''${AEROSPACE_FOCUSED_MONITOR_NO} label="''${icon_strip}"
    fi
  '';

  pluginIconMap = ''
    #!/usr/bin/env zsh
    case "$1" in
      "Firefox") echo "" ;;
      "Microsoft Outlook") echo "󰴢" ;;
      "Slack") echo "" ;;
      "Discord") echo "" ;;
      "Messenger") echo "󰍦" ;;
      "Messages") echo "󰍦" ;;
      "Ferdium") echo "󰒱" ;;
      "Apple Music") echo "" ;;
      "Podcasts") echo "" ;;
      "Books") echo "" ;;
      "VSCode Insiders") echo "" ;;
      "Bruno") echo "󰚩" ;;
      "Zoom") echo "" ;;
      "Audible") echo "" ;;
      "Wezterm") echo "" ;;
      "Finder") echo "" ;;
      "Terminal") echo "" ;;
      *) echo "" ;;
    esac
  '';

  pluginColors = ''
    #!/usr/bin/env zsh
    BATTERY_1="${palette.green.primary}"
    BATTERY_2="${palette.yellow.primary}"
    BATTERY_3="${palette.pink.primary}"
    BATTERY_4="${palette.red.primary}"
    BATTERY_5="${palette.maroon.primary}"
    YELLOW="${palette.yellow.primary}"
    GREEN="${palette.green.primary}"
  '';

  pluginIcons = ''
    #!/usr/bin/env zsh
    APPLE="󰀵"
    PREFERENCES=""
    ACTIVITY="󰍛"
    LOCK="󰌾"
  '';

  sketchybarrc = ''
    sketchybar --bar height=32 \
      y_offset=5 \
      margin=2 \
      position=top \
      padding_left=10 \
      padding_right=10 \
      blur_radius=30 \
      corner_radius=10 \
      color=${colorBlack}

    sketchybar --default width=32 \
      icon.font="JetBrainsMono Nerd Font:Bold:18.0" \
      icon.color=${colorDefault} \
      label.font="JetBrainsMono Nerd Font:Bold:18.0" \
      label.highlight_color="${labelHighlight}" \
      label.width=50 \
      label.color=${colorDefault}

    sketchybar --add bracket center_items center
    sketchybar --add item workspace_strip center
    sketchybar --set workspace_strip script="$CONFIG_DIR/plugins/workspace_strip.sh" label.align=center
    sketchybar --add item app_name center
    sketchybar --set app_name label.align=center
  '';

in
{
  home.file = {
    ".config/sketchybar/sketchybarrc" = {
      text = sketchybarrc;
      executable = false;
    };
    ".config/sketchybar/plugins/date_label.sh" = {
      text = pluginDateLabel;
      executable = true;
    };
    ".config/sketchybar/plugins/battery.sh" = {
      text = pluginBattery;
      executable = true;
    };
    ".config/sketchybar/plugins/apple_menu.sh" = {
      text = pluginAppleMenu;
      executable = true;
    };
    ".config/sketchybar/plugins/workspace_strip.sh" = {
      text = pluginWorkspaceStrip;
      executable = true;
    };
    ".config/sketchybar/plugins/icon_map.sh" = {
      text = pluginIconMap;
      executable = true;
    };
    ".config/sketchybar/plugins/colors.sh" = {
      text = pluginColors;
      executable = false;
    };
    ".config/sketchybar/plugins/icons.sh" = {
      text = pluginIcons;
      executable = false;
    };
  };
}
