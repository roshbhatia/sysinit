{
  lib,
  values,
  pkgs,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  theme = themes.getTheme values.theme.colorscheme;
  semanticColors = themes.getSemanticColors values.theme.colorscheme values.theme.variant;

  hex = c: lib.removePrefix "#" c;
  toSketchybar = c: "0xff${hex c}";
  toAlpha = alpha: c: "0x${alpha}${hex c}";

  # Clean, modern color scheme inspired by yessetmurat's config
  colors = {
    # Text colors
    white = "0xffffffff";
    text = toSketchybar semanticColors.foreground.primary;
    muted = toSketchybar semanticColors.foreground.muted;

    # Bar and background colors
    bar = toAlpha "40" "000000"; # Very transparent black
    itemBg = toAlpha "33" "000000"; # Semi-transparent black
    accent = toSketchybar semanticColors.accent.primary;

    # Popup colors
    popupBg = toAlpha "ee" semanticColors.background.secondary;
  };

  writeBatteryScript = pkgs.writeText "battery.sh" ''
    #!/usr/bin/env zsh
    PERCENT=$(pmset -g batt | grep -Eo "\\d+%" | cut -d% -f1) || exit 0
    CHARGING=$(pmset -g batt | grep 'AC Power')
    WHITE=${colors.white}
    ACCENT=${colors.accent}

    if [[ "$CHARGING" != "" ]]; then
      ICON=""; COLOR="$ACCENT"
    else
      case $PERCENT in
        9[0-9]|100) ICON=""; COLOR="$WHITE" ;;
        [6-8][0-9]) ICON=""; COLOR="$WHITE" ;;
        [3-5][0-9]) ICON=""; COLOR="$ACCENT" ;;
        [1-2][0-9]) ICON=""; COLOR="$ACCENT" ;;
        *) ICON=""; COLOR="$ACCENT" ;;
      esac
    fi
    sketchybar --set "$NAME" icon="$ICON" label="''${PERCENT}%" icon.color="$COLOR" label.color="$COLOR"
  '';

  writeAerospaceScript = pkgs.writeText "aerospace.sh" ''
    #!/usr/bin/env zsh
    INACTIVE_BG=${colors.itemBg}
    ACTIVE_BG=${colors.accent}
    WHITE=${colors.white}
    MUTED=${colors.muted}
    SID=$1
    CURRENT=$(aerospace list-workspaces --focused)

    if [[ "$SID" == "$CURRENT" ]]; then
      # Active workspace - animate to accent color with white text
      sketchybar --animate tanh 20 \
                 --set space."$SID" background.color="$ACTIVE_BG" \
                                    background.height=24 \
                                    label.color="$WHITE" \
                                    label.font="TX-02:Bold:13.0"
    else
      # Inactive workspace - animate to muted state
      sketchybar --animate tanh 20 \
                 --set space."$SID" background.color="$INACTIVE_BG" \
                                    background.height=22 \
                                    label.color="$MUTED" \
                                    label.font="TX-02:Medium:13.0"
    fi
  '';

  writeIconMap = pkgs.writeText "icon_map.sh" ''
    #!/bin/bash
    function icon_map() {
      case "$1" in
        "Activity Monitor") echo ":activity_monitor:" ;;
        "App Store") echo ":app_store:" ;;
        "Calculator") echo ":calculator:" ;;
        "Calendar") echo ":calendar:" ;;
        "Code") echo ":code:" ;;
        "Code Insiders") echo ":code:" ;;
        "Discord") echo ":discord:" ;;
        "Ferdium") echo ":discord:" ;;
        "Finder") echo ":finder:" ;;
        "Firefox") echo ":firefox:" ;;
        "Mail") echo ":mail:" ;;
        "Messages") echo ":messages:" ;;
        "Music") echo ":music:" ;;
        "Notes") echo ":notes:" ;;
        "Outlook") echo ":mail:" ;;
        "Safari") echo ":safari:" ;;
        "Slack") echo ":slack:" ;;
        "System Preferences") echo ":gear:" ;;
        "Terminal") echo ":terminal:" ;;
        "Visual Studio Code") echo ":code:" ;;
        "Visual Studio Code Insiders") echo ":code:" ;;
        "Wezterm") echo ":terminal:" ;;
        "Xcode") echo ":xcode:" ;;
        "Zoom") echo ":zoom:" ;;
        *) echo ":default:" ;;
      esac
    }
    icon_map "$1"
  '';

  writeFrontAppScript = pkgs.writeText "front_app.sh" ''
    #!/usr/bin/env bash
    APP=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')
    ICON=$(${writeIconMap} "$APP")
    if [[ "$APP" == "" ]]; then
      sketchybar --set front_app drawing=off
    else
      sketchybar --set front_app icon="$ICON" label="$APP" drawing=on
    fi
  '';
in
{
  services.sketchybar = {
    package = pkgs.sketchybar;
    enable = true;
    config = ''
      # Modern rounded bar configuration
      sketchybar --bar height=34 \
                       color=${colors.bar} \
                       position=top \
                       blur_radius=40 \
                       sticky=on \
                       shadow=on \
                       corner_radius=16 \
                       margin=8 \
                       y_offset=6 \
                       padding_left=12 \
                       padding_right=12

      # Clean default styling
      sketchybar --default background.color=${colors.itemBg} \
                           background.corner_radius=8 \
                           background.height=26 \
                           background.drawing=on \
                           icon.font="sketchybar-app-font:Regular:14.0" \
                           icon.color=${colors.white} \
                           icon.padding_left=6 \
                           icon.padding_right=4 \
                           label.font="TX-02:Semibold:12.0" \
                           label.color=${colors.white} \
                           label.padding_left=2 \
                           label.padding_right=6 \
                           padding_left=2 \
                           padding_right=2

      # Aerospace workspace indicators with proper spacing
      for sid in $(aerospace list-workspaces --all); do
        sketchybar --add item space.$sid left \
                   --set space.$sid icon.drawing=off \
                                    label="$sid" \
                                    label.font="TX-02:Bold:13.0" \
                                    background.corner_radius=6 \
                                    background.height=22 \
                                    padding_left=8 \
                                    padding_right=8 \
                                    click_script="aerospace workspace $sid" \
                                    script="${writeAerospaceScript} $sid"
        sketchybar --subscribe space.$sid aerospace_workspace_change
      done

      # Separator after workspaces
      sketchybar --add item separator left \
                 --set separator icon="|" \
                                 icon.color=${colors.muted} \
                                 icon.font="TX-02:Medium:12.0" \
                                 background.drawing=off \
                                 padding_left=6 \
                                 padding_right=6

      # Front app indicator with better spacing
      sketchybar --add item front_app left \
                 --set front_app background.corner_radius=8 \
                                 background.height=26 \
                                 padding_left=8 \
                                 padding_right=8 \
                                 script="${writeFrontAppScript}"
      sketchybar --subscribe front_app front_app_switched

      # System indicators (right side) - NO CALENDAR ICON
      sketchybar --add item clock right \
                 --set clock label.font="TX-02:Medium:12.0" \
                             background.corner_radius=8 \
                             background.height=26 \
                             padding_left=8 \
                             padding_right=8 \
                             script="sh /usr/local/share/sketchybar/plugins/clock.sh" \
                             click_script="open /System/Applications/Calendar.app" \
                             update_freq=30

      sketchybar --add item battery right \
                 --set battery background.corner_radius=8 \
                               background.height=26 \
                               padding_left=8 \
                               padding_right=8 \
                               script="${writeBatteryScript}" \
                               click_script="open /System/Library/PreferencePanes/Battery.prefPane" \
                               update_freq=120
      sketchybar --subscribe battery system_woke power_source_change

      sketchybar --add item volume right \
                 --set volume icon=󰕾 \
                              background.corner_radius=8 \
                              background.height=26 \
                              padding_left=8 \
                              padding_right=8 \
                              popup.background.color=${colors.popupBg} \
                              popup.background.corner_radius=8 \
                              popup.blur_radius=30 \
                              popup.height=35 \
                              popup.y_offset=10 \
                              popup.padding_left=10 \
                              popup.padding_right=10 \
                              script="sh /usr/local/share/sketchybar/plugins/volume.sh" \
                              click_script="sketchybar --set volume popup.drawing=toggle"
      sketchybar --subscribe volume volume_change

      # Force initial update
      sketchybar --update
    '';
  };
}
