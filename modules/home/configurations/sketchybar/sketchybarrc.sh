source "${CONFIG_DIR}/themes/catppuccin-latte.sh"

sketchybar --bar position=top \
                 height=36 \
                 color="${_SSDF_CM_MANTLE}"

PLUGIN_DIR="$CONFIG_DIR/plugins"

sketchybar --default \
  padding_left=5 \
  padding_right=5 \
  icon.font="Hack Nerd Font Mono:Regular:15.0" \
  label.font="Hack Nerd Font Mono:Regular:15.0" \
  icon.color="${_SSDF_CM_SUBTEXT_1}" \
  label.color="${_SSDF_CM_SUBTEXT_1}" \
  icon.padding_left=4 \
  icon.padding_right=4 \
  label.padding_left=4 \
  label.padding_right=4

. "$CONFIG_DIR/items/left.sh"
. "$CONFIG_DIR/items/right.sh"

sketchybar --update

