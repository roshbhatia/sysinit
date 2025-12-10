{
  pkgs,
  ...
}:
let
  configDir = if pkgs.stdenv.isDarwin then "Library/Application Support/tattoy" else ".config/tattoy";
in
{
  home.file."${configDir}/tattoy.toml".text = ''
    frame_rate = 144
    scrollback_size = 10000
    show_tattoy_indicator = false
    show_startup_logo = false

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
