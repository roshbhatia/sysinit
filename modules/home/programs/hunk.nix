{
  config,
  inputs,
  ...
}:

let
  stylixEnabled = config.stylix.enable or false;
  c = config.lib.stylix.colors;

  # Map semantic Base16 roles onto Hunk's custom_theme fields. Hunk's
  # transparent-background mode removes all surfaces, so each foreground must
  # remain legible against the terminal background rather than a diff tint.
  # Keys are camelCase, which hunk reads verbatim from [custom_theme].
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

    # Deliberately NOT enableGitIntegration. That option sets
    # `programs.git.settings.core.pager = "hunk pager"`, which routes every
    # `git diff` and `git log` through a reviewer.
    # archive/2026-08-06-quiet-pi-sidebar-and-diff-review removed that on
    # purpose, and re-adding it is a second decision this change is not making.
    # `review` is the entry point instead: one verb, invoked when you want it.
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
          # "auto" queries the terminal background and selects a light or dark
          # github theme, with a dark fallback.
          theme = "auto";
        }
    );
  };
}
