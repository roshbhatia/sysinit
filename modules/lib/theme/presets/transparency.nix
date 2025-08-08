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
      baseConfig =
        if hasAttr preset constants.transparencyPresets then
          constants.transparencyPresets.${preset}
        else
          throw "Transparency preset '${preset}' not found. Available presets: ${concatStringsSep ", " (attrNames constants.transparencyPresets)}";
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
    if condition.nvim_running then
      contextualTransparency.coding
    else if condition.presentation_mode then
      contextualTransparency.presentation
    else if condition.focus_mode then
      contextualTransparency.focus
    else
      baseTransparency;
}
