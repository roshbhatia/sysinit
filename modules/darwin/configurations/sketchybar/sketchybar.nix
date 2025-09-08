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
    SID=$1
    CURRENT=$(aerospace list-workspaces --focused)
    if [[ "$SID" == "$CURRENT" ]]; then
      sketchybar --set space."$SID" \
        background.color="$ACTIVE_BG" \
        label.color="$WHITE"
    else
      sketchybar --set space."$SID" \
        background.color="$INACTIVE_BG" \
        label.color="$WHITE"
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
      # Clean, modern bar configuration inspired by yessetmurat
      sketchybar --bar height=40 color=${colors.bar} position=top \
        blur_radius=30 sticky=on shadow=off

      # Default item styling - clean and minimal
      sketchybar --default icon.font="sketchybar-app-font:Regular:15.0" icon.color=${colors.white} \
        label.font="TX-02:Semibold:14.0" label.color=${colors.white} \
        background.color=${colors.itemBg} background.corner_radius=6 background.height=28 \
        padding_left=2 padding_right=2 icon.padding_left=10 label.padding_right=4 \
        y_offset=1

      # Aerospace workspace indicators - clean pill design
      for sid in $(aerospace list-workspaces --all); do
        sketchybar --add item space.$sid left \
          --set space.$sid background.drawing=on \
              background.color=${colors.itemBg} background.corner_radius=6 background.height=28 \
              icon.drawing=off label="$sid" label.color=${colors.white} \
              label.font="TX-02:Semibold:14.0" \
              click_script="aerospace workspace $sid" script="${writeAerospaceScript} $sid" \
              padding_left=2 padding_right=2 icon.padding_left=10 label.padding_right=4
        sketchybar --subscribe space.$sid aerospace_workspace_change
      done

      # Front app indicator - using sketchybar-app-font
      sketchybar --add item front_app left \
        --set front_app background.drawing=on \
              background.color=${colors.itemBg} background.corner_radius=6 background.height=28 \
              icon.font="sketchybar-app-font:Regular:15.0" icon.color=${colors.white} \
              label.font="TX-02:Semibold:14.0" label.color=${colors.white} \
              script="${writeFrontAppScript}" \
              padding_left=2 padding_right=2 icon.padding_left=10 label.padding_right=4
      sketchybar --subscribe front_app front_app_switched

      # Calendar/Clock
      sketchybar --add item clock right \
        --set clock icon=󰃰 icon.color=${colors.white} icon.font="TX-02:Semibold:15.0" \
              background.drawing=on background.color=${colors.itemBg} \
              background.corner_radius=6 background.height=28 \
              label.font="TX-02:Semibold:14.0" label.color=${colors.white} \
              script="sh /usr/local/share/sketchybar/plugins/clock.sh" \
              click_script="open /System/Applications/Calendar.app" \
              update_freq=30 padding_left=2 padding_right=2 \
              icon.padding_left=10 label.padding_right=4

      # Battery indicator
      sketchybar --add item battery right \
        --set battery background.drawing=on background.color=${colors.itemBg} \
              background.corner_radius=6 background.height=28 \
              icon.font="TX-02:Semibold:15.0" label.font="TX-02:Semibold:14.0" \
              script="${writeBatteryScript}" \
              click_script="open /System/Library/PreferencePanes/Battery.prefPane" \
              update_freq=120 padding_left=2 padding_right=2 \
              icon.padding_left=10 label.padding_right=4
      sketchybar --subscribe battery system_woke power_source_change

      # Volume indicator
      sketchybar --add item volume right \
        --set volume background.drawing=on background.color=${colors.itemBg} \
              background.corner_radius=6 background.height=28 \
              icon.font="TX-02:Semibold:15.0" icon.color=${colors.white} \
              label.font="TX-02:Semibold:14.0" label.color=${colors.white} \
              popup.background.color=${colors.popupBg} popup.background.corner_radius=6 \
              popup.blur_radius=30 popup.height=35 popup.y_offset=10 \
              popup.padding_left=10 popup.padding_right=10 \
              script="sh /usr/local/share/sketchybar/plugins/volume.sh" \
              click_script="sketchybar --set volume popup.drawing=toggle" \
              padding_left=2 padding_right=2 icon.padding_left=10 label.padding_right=4
      sketchybar --subscribe volume volume_change

      sketchybar --update
    '';
  };
}
