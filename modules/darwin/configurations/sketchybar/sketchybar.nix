{
  lib,
  values,
  pkgs,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  sketchybarTheme = values.theme.appThemes.sketchybar or values.theme.colorscheme;
  theme = themes.getTheme sketchybarTheme;
  cfg = theme.appAdapters.sketchybar or (throw "Theme lacks sketchybar adapter");

  hex = c: lib.removePrefix "#" c;
  toSketchybar = c: "0xff${hex c}";
  toAlpha = alpha: c: "0x${alpha}${hex c}";

  raw = {
    background = cfg.background;
    foreground = cfg.foreground;
    accent = cfg.accent;
    muted = cfg.muted;
    highlight = cfg.highlight;
    success = cfg.success;
    warning = cfg.warning;
    error = cfg.error;
  };

  colors = {
    text = toSketchybar raw.foreground;
    accent = toSketchybar raw.accent;
    highlight = toSketchybar raw.highlight;
    muted = toSketchybar raw.muted;
    success = toSketchybar raw.success;
    warning = toSketchybar raw.warning;
    error = toSketchybar raw.error;
    popupBg = toAlpha "aa" raw.background;
    bracketBg = toAlpha "33" raw.foreground;
    bracketBorder = toAlpha "66" raw.highlight;
    activeWsBg = toSketchybar raw.accent;
    activeWsBorder = toSketchybar raw.highlight;
  };

  writeBatteryScript = pkgs.writeText "battery.sh" ''
    #!/usr/bin/env zsh
    PERCENT=$(pmset -g batt | grep -Eo "\\d+%" | cut -d% -f1) || exit 0
    CHARGING=$(pmset -g batt | grep 'AC Power')
    if [[ "$CHARGING" != "" ]]; then
      ICON=""; COLOR=${colors.accent}
    else
      case $PERCENT in
        9[0-9]|100) ICON=""; COLOR=${colors.success} ;;
        [6-8][0-9]) ICON=""; COLOR=${colors.warning} ;;
        [3-5][0-9]) ICON=""; COLOR=${colors.warning} ;;
        [1-2][0-9]) ICON=""; COLOR=${colors.error} ;;
        *) ICON=""; COLOR=${colors.error} ;;
      esac
    fi
    sketchybar --set "$NAME" icon="$ICON" label="''${PERCENT}%" icon.color="$COLOR" label.color="$COLOR"
  '';

  writeAerospaceScript = pkgs.writeText "aerospace.sh" ''
    #!/usr/bin/env zsh
    BR_BG=${colors.bracketBg}; BR_BORDER=${colors.bracketBorder}
    ACT_BG=${colors.activeWsBg}; ACT_BORDER=${colors.activeWsBorder}
    MT=${colors.muted}; TX=${colors.text}
    SID=$1
    CURRENT=$(aerospace list-workspaces --focused)
    if [[ "$SID" == "$CURRENT" ]]; then
      sketchybar --set space."$SID" background.color="$ACT_BG" background.border_color="$ACT_BORDER" icon.color="$TX" label.color="$TX"
    else
      sketchybar --set space."$SID" background.color="$BR_BG" background.border_color="$BR_BORDER" icon.color="$MT" label.color="$TX"
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
      sketchybar --bar height=34 color=${toAlpha "00" raw.background} position=top y_offset=4 \
        margin=0 padding_left=0 padding_right=0 corner_radius=0 blur_radius=50 sticky=off shadow=off

      sketchybar --default icon.font="JetBrainsMono Nerd Font:Bold:15.0" icon.color=${colors.muted} \
        label.font="JetBrainsMono Nerd Font:Medium:13.0" label.color=${colors.text} background.drawing=off

      sketchybar --add item left_padding left \
        --set left_padding width=16

      sketchybar --add item spaces left \
        --set spaces background.color=${toAlpha "00" raw.background}

      for sid in $(aerospace list-workspaces --all); do
        sketchybar --add item space.$sid left \
          --set space.$sid background.drawing=on background.corner_radius=6 background.height=26 \
              background.color=${colors.bracketBg} background.border_color=${colors.bracketBorder} background.border_width=1 \
              icon.font="JetBrainsMono Nerd Font:Bold:15.0" icon.color=${colors.muted} \
              label.font="JetBrainsMono Nerd Font:Medium:13.0" label.color=${colors.text} label="$sid" \
              click_script="aerospace workspace $sid" script="${writeAerospaceScript} $sid" \
              padding_left=8 padding_right=8
        sketchybar --subscribe space.$sid aerospace_workspace_change
      done

      sketchybar --add item front_app left \
        --set front_app background.color=${colors.bracketBg} background.corner_radius=6 background.border_width=1 \
            background.border_color=${colors.bracketBorder} background.height=26 \
            icon.font="SKEYCHYBAR-Ionicons" icon.color=${colors.accent} label.color=${colors.text} \
            script="${writeFrontAppScript}" padding_left=8 padding_right=8
      sketchybar --subscribe front_app front_app_switched

      sketchybar --add item right_padding right \
        --set right_padding width=16

      sketchybar --add item volume right \
        --set volume background.color=${colors.bracketBg} background.corner_radius=6 background.border_width=1 \
            background.border_color=${colors.bracketBorder} background.height=26 \
            popup.background.color=${colors.popupBg} popup.background.corner_radius=6 popup.blur_radius=30 \
            popup.height=35 popup.y_offset=10 popup.padding_left=10 popup.padding_right=10 \
            script="sh /usr/local/share/sketchybar/plugins/volume.sh" click_script="sketchybar --set volume popup.drawing=toggle" \
            padding_left=8 padding_right=8
      sketchybar --subscribe volume volume_change

      sketchybar --add item battery right \
        --set battery background.color=${colors.bracketBg} background.corner_radius=6 background.border_width=1 \
            background.border_color=${colors.bracketBorder} background.height=26 \
            script="${writeBatteryScript}" click_script="open /System/Library/PreferencePanes/Battery.prefPane" \
            update_freq=60 padding_left=8 padding_right=8
      sketchybar --subscribe battery system_woke power_source_change

      sketchybar --add item clock right \
        --set clock icon=󰃰 icon.color=${colors.highlight} label.font="JetBrainsMono Nerd Font:Bold:13.0" \
            background.color=${colors.bracketBg} background.corner_radius=6 background.border_width=1 \
            background.border_color=${colors.bracketBorder} background.height=26 \
            script="sh /usr/local/share/sketchybar/plugins/clock.sh" click_script="open /System/Applications/Calendar.app" \
            update_freq=30 padding_left=8 padding_right=8

      sketchybar --add bracket left_group spaces front_app \
        --set left_group background.color=${toAlpha "00" raw.background} y_offset=4 padding_left=8 padding_right=8

      sketchybar --add bracket right_group volume battery clock \
        --set right_group background.color=${toAlpha "00" raw.background} y_offset=4 padding_left=8 padding_right=8

      sketchybar --update
    '';
  };
}

