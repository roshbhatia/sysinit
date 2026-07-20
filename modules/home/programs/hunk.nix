{
  config,
  lib,
  inputs,
  ...
}:

let
  stylixEnabled = config.stylix.enable or false;
  c = config.lib.stylix.colors;

  # Map the active stylix base16 palette onto hunk's custom_theme fields.
  # base inherits the diff row-background tints; stylix drives the chrome,
  # accents, signs, badges, and file-state colors. Keys are camelCase, which
  # hunk reads verbatim from the [custom_theme] TOML table.
  stylixTheme = {
    base = if config.stylix.polarity == "light" then "github-light-default" else "github-dark-default";

    background = "#${c.base00}";
    panel = "#${c.base01}";
    panelAlt = "#${c.base02}";
    border = "#${c.base03}";
    accent = "#${c.base0D}";
    accentMuted = "#${c.base03}";
    text = "#${c.base05}";
    muted = "#${c.base03}";

    addedSignColor = "#${c.base0B}";
    removedSignColor = "#${c.base08}";

    lineNumberBg = "#${c.base01}";
    lineNumberFg = "#${c.base03}";
    selectedHunk = "#${c.base02}";

    badgeAdded = "#${c.base0B}";
    badgeRemoved = "#${c.base08}";
    badgeNeutral = "#${c.base0D}";

    fileNew = "#${c.base0B}";
    fileDeleted = "#${c.base08}";
    fileRenamed = "#${c.base0E}";
    fileModified = "#${c.base0A}";
    fileUntracked = "#${c.base03}";

    noteBorder = "#${c.base0D}";
    noteBackground = "#${c.base01}";
    noteTitleBackground = "#${c.base0D}";
    noteTitleText = "#${c.base00}";
  };
in
{
  imports = [
    inputs.hunk.homeManagerModules.default
  ];

  programs.hunk = {
    enable = true;
    enableGitIntegration = true;
    # Link the hunk-review skill under ~/.claude/skills for live-session review.
    enableClaudeIntegration = true;
    settings =
      if stylixEnabled then
        {
          theme = "custom";
          custom_theme = stylixTheme;
        }
      else
        {
          # "auto" queries the terminal background and selects a light or dark
          # github theme, with a dark fallback.
          theme = "auto";
        };
  };
}
