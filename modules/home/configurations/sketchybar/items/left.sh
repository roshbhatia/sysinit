#!/usr/bin/env bash
set -e

PLUGIN_DIR="$CONFIG_DIR/plugins"

sketchybar --query bar | jq -r '.items[]' | grep '^space\.' | while read -r item; do
  sketchybar --remove item "$item"
done

sketchybar --add event aerospace_workspace_change
sketchybar --add event aerospace_workspace_monitor_change

FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused)"
draw_spaces() {
  monitor_ids=($(aerospace list-monitors --json | jq '.[]."monitor-id"'))
  for display in "${monitor_ids[@]}"; do
    for sid in $(aerospace list-workspaces --monitor "$display"); do
      # Get the workspace name
      space_name=$(aerospace list-workspaces --all | awk -v s="$sid" '$1==s {for(i=2;i<=NF;++i) printf $i " "; print ""}' | sed 's/ *$//')
      if [[ -z "$space_name" ]]; then
        space_name="$sid"
      fi
      # Highlight focused workspace
      if [[ "$sid" == "$FOCUSED_WORKSPACE" ]]; then
        label="[$space_name]"
      else
        label="$space_name"
      fi
      workspace=(
        label="$label"
        label.font="$ICON_FONT:Regular:14"
        label.color="$ICON_COLOR"
        display="$display"
        label.drawing=on
        background.drawing=off
        script="$PLUGIN_DIR/aerospace.sh $sid"
        click_script="aerospace workspace $sid"
      )
      sketchybar --add item "space.$sid" left \
        --subscribe "space.$sid" aerospace_workspace_change \
        --subscribe "space.$sid" aerospace_workspace_monitor_change \
        --set "space.$sid" "${workspace[@]}"
    done
  done
}

draw_spaces

sketchybar --add item chevron left \
           --set chevron icon= label.drawing=off

sketchybar --add item front_app left \
           --set front_app icon.drawing=off script="$PLUGIN_DIR/front_app.sh" \
           --subscribe front_app front_app_switched

wrapper=(
  background.drawing=off
)

separator=(
  icon=" | "
  icon.font="$ICON_FONT:Heavy:16.0"
  padding_left=15
  padding_right=15
  label.drawing=off
  associated_display=active
  icon.color="$ICON_COLOR"
)

sketchybar --add bracket wrapper '/space\..*/' \
  --set wrapper "${wrapper[@]}"

sketchybar --add item separator left \
  --set separator "${separator[@]}"

# End of file

