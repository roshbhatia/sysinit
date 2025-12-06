{ lib, ... }:

with lib;

let
  presets_core = import ../core/presets.nix { inherit lib; };
in

{

  presets = presets_core.transparencyPresets;

  createAppTransparency =
    app: preset: overrides:
    let
      baseConfig =
        if hasAttr preset presets_core.transparencyPresets then
          presets_core.transparencyPresets.${preset}
        else
          throw "Transparency preset '${preset}' not found. Available presets: ${concatStringsSep ", " (attrNames presets_core.transparencyPresets)}";
      finalConfig = baseConfig // overrides;
    in
    if app == "wezterm" then
      {
        inherit (finalConfig) enable;
        inherit (finalConfig) opacity;
        inherit (finalConfig) blur;

        window_decorations = if finalConfig.enable then "RESIZE" else "TITLE_BAR | RESIZE";
        macos_window_background_blur = finalConfig.blur;
      }
    else if app == "neovim" then
      {
        inherit (finalConfig) enable;

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

  # Use contextual presets from core/presets.nix
  contextualTransparency = presets_core.contextualPresets;

  createConditionalTransparency =
    condition: baseTransparency:
    presets_core.selectTransparencyForConditions condition baseTransparency;
}
