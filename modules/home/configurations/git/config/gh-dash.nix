{
  lib,
  utils,
  values,
  ...
}:

let
  inherit (utils.theme) getThemePalette;

  palette = getThemePalette values.theme.colorscheme values.theme.variant;
  semanticColors = utils.theme.utils.createSemanticMapping palette;

  getColor = color: fallback: if color != null then color else fallback;

  themeColors = {
    text = {
      inherit (semanticColors.foreground) primary;
      inherit (semanticColors.foreground) secondary;
      inverted = semanticColors.background.primary;
      faint = semanticColors.foreground.muted;
      warning = semanticColors.semantic.error;
      inherit (semanticColors.semantic) success;
    };

    background = {
      selected = semanticColors.accent.dim or semanticColors.background.tertiary;
    };

    border = {
      primary = getColor (palette.surface1 or null) semanticColors.background.secondary;
      secondary = getColor (palette.surface2 or null) semanticColors.background.tertiary;
      faint = semanticColors.background.secondary;
    };

    inline.icons = {
      newcontributor = "077";
      contributor = "075";
      collaborator = "178";
      member = "178";
      owner = "178";
      unknownrole = "178";
    };
  };

  themeIcons = {
    inline = {
      newcontributor = "󰎔";
      contributor = "";
      collaborator = "";
      member = "";
      owner = "󱇐";
      unknownrole = "󱐡";
    };
  };

  ghDashConfig = {
    prSections = [
      {
        title = "Open Requests";
        filters = "is:open";
      }
      {
        title = "My Pull Requests";
        filters = "is:open author:@me";
      }
      {
        title = "Needs My Review";
        filters = "is:open review-requested:@me";
      }
      {
        title = "Involved";
        filters = "is:open involves:@me -author:@me";
      }
    ];

    pager = {
      diff = "diffnav";
    };

    defaults = {
      refetchIntervalMinutes = 1;
      prApproveComment = "Approved 👍🏽";
      preview = {
        grow = true;
      };
    };

    keybindings = {
      universal = [
        {
          key = "g";
          name = "lazygit";
          command = ''
            cd {{.RepoPath}} && lazygit
          '';
        }
      ];

      prs = [
        {
          key = "O";
          builtin = "checkout";
        }
        {
          key = "r";
          name = "Review PR";
          command = ''
            cd {{.RepoPath}}
            if [ -n "$NVIM" ]; then
              nvim --server "$NVIM" --remote-send ':Octo review {{.PrNumber}}<CR>'
            else
              nvim -c 'Octo review {{.PrNumber}}'
            fi
          '';
        }
        {
          key = "m";
          name = "Merge (squash)";
          command = ''
            gh pr merge --squash --delete-branch --repo {{.RepoName}} {{.PrNumber}}
          '';
        }
        {
          key = "v";
          name = "Approve";
          command = ''
            gh pr review --repo {{.RepoName}} --approve --body "$(gum input --prompt='Approval Comment: ')" {{.PrNumber}}
          '';
        }
        {
          key = "a";
          name = "Add & LazyGit";
          command = ''
            cd {{.RepoPath}}
            git add -A
            lazygit
          '';
        }
      ];

      issues = [
        {
          key = "e";
          name = "Edit Issue";
          command = ''
            cd {{.RepoPath}}
            if [ -n "$NVIM" ]; then
              nvim --server "$NVIM" --remote-send ':Octo issue edit {{.IssueNumber}}<CR>'
            else
              nvim -c 'Octo issue edit {{.IssueNumber}}'
            fi
          '';
        }
        {
          key = "i";
          name = "Create Issue";
          command = ''
            cd {{.RepoPath}}
            if [ -n "$NVIM" ]; then
              nvim --server "$NVIM" --remote-send ':Octo issue create<CR>'
            else
              nvim -c 'Octo issue create'
            fi
          '';
        }
      ];
    };

    theme = {
      ui = {
        sectionsShowCount = true;
        table = {
          showSeparators = true;
          compact = true;
        };
      };

      colors = {
        inherit (themeColors) text;
        inherit (themeColors) background;
        inherit (themeColors) border;
        inline.icons = themeColors.inline.icons;
      };

      icons = themeIcons;
    };
  };

in
{
  xdg.configFile."gh-dash/config.yml" = {
    text = lib.generators.toYAML { } ghDashConfig;
    force = true;
  };
}
