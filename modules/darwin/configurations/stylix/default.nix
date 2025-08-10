{
  lib,
  pkgs,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };

  fontConfig = {
    monospace = {
      package = pkgs.jetbrains-mono;
      name = "JetBrains Mono";
    };
    sansSerif = {
      package = pkgs.inter;
      name = "Inter";
    };
    serif = {
      package = pkgs.crimson;
      name = "Crimson Text";
    };
    emoji = {
      package = pkgs.noto-fonts-emoji;
      name = "Noto Color Emoji";
    };
  };

  stylixConfig =
    themes.createStylixFromTheme values.theme.colorscheme values.theme.variant
      fontConfig;

  additionalTargets = themes.stylixHelpers.enableStylixTargets [
    "vscode"
    "firefox"
  ];

in

stylixConfig // additionalTargets

