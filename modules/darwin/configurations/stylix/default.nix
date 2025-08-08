{
  config,
  lib,
  pkgs,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  stylixScheme = themes.generateStylix values.theme.colorscheme values.theme.variant;
in

{
  stylix.enable = true;

  stylix.base16Scheme = stylixScheme;

  stylix.fonts = {
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
  };

  stylix.opacity.terminal = if values.theme.transparency.enable then values.theme.transparency.opacity else 1.0;

  stylix.targets = {
    bat.enable = true;
    firefox.enable = true;
    helix.enable = true;
    k9s.enable = true;
    fzf.enable = true;
    neovim.enable = false;
    wezterm.enable = false;
  };
}
