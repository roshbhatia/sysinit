{ lib, ... }:

with lib;

let
  constants = import ../core/constants.nix { inherit lib; };
in

{

  presets = constants.transparencyPresets;

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

        window_decorations = if finalConfig.enable then "RESIZE" else "TITLE_BAR | RESIZE";
        macos_window_background_blur = finalConfig.blur;
      }
    else if app == "neovim" then
      {
        enable = finalConfig.enable;

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

        inherit (finalConfig) enable opacity;
      }
    else
      finalConfig;

  mergeTransparency =
    baseConfig: transparencyConfig:
    if transparencyConfig == { } then
      baseConfig
    else
      baseConfig // { transparency = transparencyConfig; };

  contextualTransparency = {

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
