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
    frame_rate = 60
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

    # Color adjustments (neutral by default)
    [color]
    saturation = 0.0
    brightness = 0.0
    hue = 0.0
  '';
}
