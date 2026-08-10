{
  lib,
  config,
  inputs,
  ...
}:

let
  # The palette, read through one accessor rather than reached for directly.
  themeLib = import ../../shared/theme-colors.nix { inherit lib; };
  themeColors = themeLib.colorsOf config;
  themeEnabled = themeLib.enabled config;
  stylixEnabled = themeEnabled;
  c = themeColors;

  # Map semantic Base16 roles onto Hunk's custom_theme fields.
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

    # Deliberately NOT enableGitIntegration.
    enableGitIntegration = false;

    # Link the hunk-review skill under ~/.claude/skills for live-session review.
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
          # "auto" queries the terminal background and selects a light or dark github
          # theme, with a dark fallback.
          theme = "auto";
        }
    );
  };
}
