{ config, lib, ... }:

let
  # Use stylix base16 colors directly
  themeColors = {
    text = {
      primary = "#${config.lib.stylix.colors.base05}"; # Foreground
      secondary = "#${config.lib.stylix.colors.base04}"; # Lighter foreground
      inverted = "#${config.lib.stylix.colors.base00}"; # Background
      faint = "#${config.lib.stylix.colors.base03}"; # Comments/muted
      warning = "#${config.lib.stylix.colors.base08}"; # Red
      success = "#${config.lib.stylix.colors.base0B}"; # Green
    };

    background = {
      selected = "#${config.lib.stylix.colors.base02}"; # Selection background
    };

    border = {
      primary = "#${config.lib.stylix.colors.base02}"; # Surface
      secondary = "#${config.lib.stylix.colors.base03}"; # Comments
      faint = "#${config.lib.stylix.colors.base01}"; # Lighter background
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
