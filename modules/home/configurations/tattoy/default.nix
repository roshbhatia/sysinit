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

    # Keybindings - use numpad keys to avoid conflicts with wezterm
    [keybindings]
    toggle_tattoy = { key = "Numpad0" }
    toggle_scrolling = { key = "Numpad1" }
    toggle_minimap = { mods = "CTRL", key = "m" }
    scroll_up = { key = "Numpad2" }
    scroll_down = { key = "Numapd3" }
    scroll_exit = { key = "Numpad4" }
    shader_prev = { key = "Numpad5" }
    shader_next = { key = "Numpad6" }
  '';
}
