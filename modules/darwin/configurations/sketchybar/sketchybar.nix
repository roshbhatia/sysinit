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

  colors = {
    text = toSketchybar semanticColors.foreground.primary;
    muted = toSketchybar semanticColors.foreground.muted;
    subtle = toSketchybar semanticColors.foreground.subtle;

    accent = toSketchybar semanticColors.accent.primary;
    accentSecondary = toSketchybar semanticColors.accent.secondary;

    background = toSketchybar semanticColors.background.primary;
    backgroundSecondary = toSketchybar semanticColors.background.secondary;
    backgroundTertiary = toSketchybar semanticColors.background.tertiary;

    success = toSketchybar semanticColors.semantic.success;
    warning = toSketchybar semanticColors.semantic.warning;
    error = toSketchybar semanticColors.semantic.error;
    info = toSketchybar semanticColors.semantic.info;

    popupBg = toAlpha "aa" semanticColors.background.secondary;
    bracketBg = toAlpha "33" semanticColors.background.overlay;
    bracketBorder = toAlpha "66" semanticColors.accent.dim;
    activeWsBg = toSketchybar semanticColors.accent.primary;
    activeWsBorder = toSketchybar semanticColors.accent.secondary;
  };

  writeBatteryScript = pkgs.writeText "battery.sh" ''
    #!/usr/bin/env zsh
    PERCENT=$(pmset -g batt | grep -Eo "\\d+%" | cut -d% -f1) || exit 0
    CHARGING=$(pmset -g batt | grep 'AC Power')
    if [[ "$CHARGING" != "" ]]; then
      ICON=""; COLOR=${colors.accent}
    else
      case $PERCENT in
        9[0-9]|100) ICON=""; COLOR=${colors.success} ;;
        [6-8][0-9]) ICON=""; COLOR=${colors.warning} ;;
        [3-5][0-9]) ICON=""; COLOR=${colors.warning} ;;
        [1-2][0-9]) ICON=""; COLOR=${colors.error} ;;
        *) ICON=""; COLOR=${colors.error} ;;
      esac
    fi
    sketchybar --set "$NAME" icon="$ICON" label="''${PERCENT}%" icon.color="$COLOR" label.color="$COLOR"
  '';

  writeAerospaceScript = pkgs.writeText "aerospace.sh" ''
    #!/usr/bin/env zsh
    INACTIVE_BG=${toAlpha "60" semanticColors.background.secondary}
    ACTIVE_BG=${colors.accent}
    INACTIVE_LABEL=${colors.text}
    ACTIVE_LABEL=${colors.background}
    SID=$1
    CURRENT=$(aerospace list-workspaces --focused)
    if [[ "$SID" == "$CURRENT" ]]; then
      sketchybar --set space."$SID" \
        background.color="$ACTIVE_BG" \
        background.height=24 \
        background.corner_radius=8 \
        label.color="$ACTIVE_LABEL" \
        label.font="TX-02:Bold:12.0"
    else
      sketchybar --set space."$SID" \
        background.color="$INACTIVE_BG" \
        background.height=24 \
        background.corner_radius=8 \
        label.color="$INACTIVE_LABEL" \
        label.font="TX-02:Bold:12.0"
    fi
  '';

  writeIconMap = pkgs.writeText "icon_map.sh" ''
    #!/bin/bash
    function icon_map() {
      case "$1" in
        "Live") echo ":ableton:" ;;
        "Affinity Designer") echo ":affinity_designer:" ;;
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
      # Modern bar configuration inspired by Kcraft059
      sketchybar --bar height=34 color=${toAlpha "aa" semanticColors.background.primary} position=top \
        margin=8 padding_left=12 padding_right=12 corner_radius=14 blur_radius=40 \
        sticky=on shadow=on y_offset=8

      # Enhanced default styling with modern typography
      sketchybar --default icon.font="TX-02:Bold:14.0" icon.color=${colors.muted} \
        label.font="TX-02:Medium:12.0" label.color=${colors.text} \
        background.corner_radius=10 background.height=28 \
        padding_left=8 padding_right=8 icon.padding_left=6 label.padding_right=6

      # Apple logo / system indicator (left)
      sketchybar --add item apple.logo left \
        --set apple.logo icon= icon.color=${colors.accent} icon.font="TX-02:Bold:16.0" \
              background.drawing=off padding_left=4 padding_right=8 \
              click_script="sketchybar --trigger apple_logo_clicked"

      # Aerospace workspace indicators - improved pill design
      for sid in $(aerospace list-workspaces --all); do
        sketchybar --add item space.$sid left \
          --set space.$sid background.drawing=on \
              background.color=${toAlpha "60" semanticColors.background.secondary} \
              background.corner_radius=8 background.height=24 \
              icon.drawing=off \
              label.font="TX-02:Bold:12.0" label.color=${colors.text} label="$sid" \
              click_script="aerospace workspace $sid" script="${writeAerospaceScript} $sid" \
              padding_left=10 padding_right=10
        sketchybar --subscribe space.$sid aerospace_workspace_change
      done

      # Separator after workspaces
      sketchybar --add item spaces_separator left \
        --set spaces_separator icon=│ icon.color=${toAlpha "40" colors.muted} \
              icon.font="TX-02:Medium:14.0" background.drawing=off \
              padding_left=8 padding_right=8

      # Front app with enhanced styling
      sketchybar --add item front_app left \
        --set front_app background.drawing=on \
              background.color=${toAlpha "60" semanticColors.background.secondary} \
              background.corner_radius=8 background.height=24 \
              icon.font="SKEYCHYBAR-Ionicons:13.0" icon.color=${colors.accent} \
              label.font="TX-02:Medium:11.0" label.color=${colors.text} \
              script="${writeFrontAppScript}" padding_left=8 padding_right=8
      sketchybar --subscribe front_app front_app_switched

      # Right side system indicators with improved styling
      sketchybar --add item volume right \
        --set volume background.drawing=on \
              background.color=${toAlpha "60" semanticColors.background.secondary} \
              background.corner_radius=8 background.height=24 \
              icon.font="TX-02:Bold:13.0" icon.color=${colors.accent} \
              label.font="TX-02:Medium:11.0" label.color=${colors.text} \
              popup.background.color=${colors.popupBg} popup.background.corner_radius=10 \
              popup.blur_radius=30 popup.height=36 popup.y_offset=10 \
              popup.padding_left=12 popup.padding_right=12 \
              script="sh /usr/local/share/sketchybar/plugins/volume.sh" \
              click_script="sketchybar --set volume popup.drawing=toggle" \
              padding_left=10 padding_right=10
      sketchybar --subscribe volume volume_change

      sketchybar --add item battery right \
        --set battery background.drawing=on \
              background.color=${toAlpha "60" semanticColors.background.secondary} \
              background.corner_radius=8 background.height=24 \
              icon.font="TX-02:Bold:13.0" label.font="TX-02:Medium:11.0" \
              script="${writeBatteryScript}" \
              click_script="open /System/Library/PreferencePanes/Battery.prefPane" \
              update_freq=90 padding_left=10 padding_right=10
      sketchybar --subscribe battery system_woke power_source_change

      sketchybar --add item clock right \
        --set clock icon=󰃰 icon.color=${colors.accent} icon.font="TX-02:Bold:14.0" \
              background.drawing=on \
              background.color=${toAlpha "60" semanticColors.background.secondary} \
              background.corner_radius=8 background.height=24 \
              label.font="TX-02:Medium:11.0" label.color=${colors.text} \
              script="sh /usr/local/share/sketchybar/plugins/clock.sh" \
              click_script="open /System/Applications/Calendar.app" \
              update_freq=30 padding_left=10 padding_right=10

      # Bracket groups for visual cohesion
      sketchybar --add bracket workspace_group apple.logo '/space\..*/' \
        --set workspace_group background.color=${toAlpha "15" colors.background} \
              background.corner_radius=12 background.height=30

      sketchybar --add bracket system_group volume battery clock \
        --set system_group background.color=${toAlpha "15" colors.background} \
              background.corner_radius=12 background.height=30

      sketchybar --update
    '';
  };
}
