{ lib, ... }:

with lib;

let
  constants = import ../core/constants.nix { inherit lib; };
in

{
  # Base transparency presets
  presets = constants.transparencyPresets;

  # Create transparency config for specific apps
  createAppTransparency =
    app: preset: overrides:
    let
      baseConfig = constants.transparencyPresets.${preset} or constants.transparencyPresets.medium;
      finalConfig = baseConfig // overrides;
    in
    if app == "wezterm" then
      {
        enable = finalConfig.enable;
        opacity = finalConfig.opacity;
        blur = finalConfig.blur;
        # Wezterm-specific settings
        window_decorations = if finalConfig.enable then "RESIZE" else "TITLE_BAR | RESIZE";
        macos_window_background_blur = finalConfig.blur;
      }
    else if app == "neovim" then
      {
        enable = finalConfig.enable;
        # Neovim uses boolean transparency
        transparent_background = finalConfig.enable;
        show_end_of_buffer = !finalConfig.enable;
      }
    else if
      elem app [
        "bat"
        "git"
        "atuin"
      ]
    then
      {
        # Terminal apps don't usually have transparency settings
        # but we can pass through for potential use
        inherit (finalConfig) enable opacity;
      }
    else
      finalConfig;

  # Merge transparency with existing config
  mergeTransparency =
    baseConfig: transparencyConfig:
    if transparencyConfig == { } then
      baseConfig
    else
      baseConfig // { transparency = transparencyConfig; };

  # Dynamic transparency based on context
  contextualTransparency = {
    # Different transparency for different scenarios
    coding = {
      enable = true;
      opacity = 0.90;
      blur = 60;
    };
    reading = {
      enable = true;
      opacity = 0.85;
      blur = 80;
    };
    presentation = {
      enable = false;
      opacity = 1.0;
      blur = 0;
    };
    focus = {
      enable = true;
      opacity = 0.95;
      blur = 40;
    };
  };

  # Create transparency override for specific conditions
  createConditionalTransparency =
    condition: baseTransparency:
    if condition.nvim_running or false then
      contextualTransparency.coding
    else if condition.presentation_mode or false then
      contextualTransparency.presentation
    else if condition.focus_mode or false then
      contextualTransparency.focus
    else
      baseTransparency;
}
