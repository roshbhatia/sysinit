{
  lib,
  config,
  inputs,
  ...
}:

let
  themeLib = import ../../shared/theme-colors.nix { inherit lib; };
  themeColors = themeLib.colorsOf config;
  themeEnabled = themeLib.enabled config;
  stylixEnabled = themeEnabled;
  c = themeColors;

  stylixTheme = {
    base = if config.stylix.polarity == "light" then "github-light-default" else "github-dark-default";

    accent = "#${c.base0D}";
    accentMuted = "#${c.base04}";
    text = "#${c.base05}";
    muted = "#${c.base04}";

    addedSignColor = "#${c.base0B}";
    removedSignColor = "#${c.base08}";

    lineNumberFg = "#${c.base04}";

    badgeAdded = "#${c.base0B}";
    badgeRemoved = "#${c.base08}";
    badgeNeutral = "#${c.base0D}";

    fileNew = "#${c.base0B}";
    fileDeleted = "#${c.base08}";
    fileRenamed = "#${c.base0E}";
    fileModified = "#${c.base0A}";
    fileUntracked = "#${c.base05}";

    noteBorder = "#${c.base0D}";
    noteTitleText = "#${c.base07}";
  };
in
{
  imports = [
    inputs.hunk.homeManagerModules.default
  ];

  programs.hunk = {
    enable = true;

    enableGitIntegration = false;

    enableClaudeIntegration = true;
    settings = {
      transparent_background = true;
    }
    // (
      if stylixEnabled then
        {
          theme = "custom";
          custom_theme = stylixTheme;
        }
      else
        {
          theme = "auto";
        }
    );
  };
}
