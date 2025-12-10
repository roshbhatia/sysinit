{
  pkgs,
  ...
}:
let
  configDir = if pkgs.stdenv.isDarwin then "Library/Application Support/tattoy" else ".config/tattoy";
in
{
  home.file."${configDir}/tattoy.toml".text = ''
    # Tattoy configuration
    # https://github.com/tattoy-org/tattoy

    # General settings
    log_level = "off"
    frame_rate = 60
    scrollback_size = 10000

    # Disable visual indicators - wezterm handles tab/title
    show_tattoy_indicator = false
    show_startup_logo = false

    # Notifications
    [notifications]
    enabled = false

    # Animated cursor with trail effect
    [animated_cursor]
    enabled = true
    opacity = 1.0
    path = "shaders/cursors/smear_fade.glsl"
    cursor_scale = 0.0

    # Text contrast for readability over shader backgrounds
    [text_contrast]
    enabled = true
    target_contrast = 2.0
    apply_to_readable_text_only = true

    # Color adjustments (neutral by default)
    [color]
    saturation = 0.0
    brightness = 0.0
    hue = 0.0

    # Keybindings - use F-keys to avoid conflicts with wezterm/apps
    [keybindings]
    toggle_tattoy = { key = "F1" }
    toggle_scrolling = { key = "F2" }
    toggle_minimap = { mods = "CTRL", key = "m" }
    scroll_up = { key = "UpArrow" }
    scroll_down = { key = "DownArrow" }
    scroll_exit = { key = "Escape" }
    shader_prev = { key = "F11" }
    shader_next = { key = "F12" }
  '';
}
