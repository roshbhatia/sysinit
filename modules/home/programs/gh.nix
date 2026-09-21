{
  config,
  lib,
  pkgs,
  ...
}:

let
  prDiff = pkgs.sysinit.writeShellApplication {
    name = "gh-pr-diff";
    runtimeInputs = [
      pkgs.gh
      pkgs.git
    ];
    text = ''
      exec ${lib.getExe pkgs.python3} ${./gh-pr-diff.py} "$@"
    '';
  };
in

{
  home.packages = [ prDiff ];
  programs.gh-dash = {
    enable = true;
    package = null;
    settings = (builtins.fromJSON (builtins.readFile ./gh-dash.json)) // {
      prSections = [
        {
          title = "Needs My Review";
          filters = "is:open review-requested:@me -is:draft";
        }
        {
          title = "Assigned to Me";
          filters = "is:open assignee:@me -author:@me -is:draft";
        }
        {
          title = "My Pull Requests";
          filters = "is:open author:@me";
        }
        {
          title = "Reviewed";
          filters = "is:open reviewed-by:@me -author:@me";
        }
      ];
      issuesSections = [ ];
      keybindings.prs = [
        {
          key = "d";
          name = "Review diff in Neovim";
          command = ''${lib.getExe prDiff} "https://github.com/{{.RepoName}}/pull/{{.PrNumber}}"'';
        }
        {
          key = "D";
          name = "Review diff in Changes";
          command = ''${lib.getExe prDiff} --tool changes "https://github.com/{{.RepoName}}/pull/{{.PrNumber}}"'';
        }
        {
          key = "H";
          name = "PR commit history in Neovim";
          command = ''${lib.getExe prDiff} --history "https://github.com/{{.RepoName}}/pull/{{.PrNumber}}"'';
        }
        {
          key = "T";
          name = "PR checks in Enhance";
          command = ''gh enhance "https://github.com/{{.RepoName}}/pull/{{.PrNumber}}"'';
        }
        {
          key = "V";
          name = "Write a PR review";
          command = ''gh pr review "https://github.com/{{.RepoName}}/pull/{{.PrNumber}}"'';
        }
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        {
          key = "o";
          name = "Open PR in Firefox";
          command = ''/usr/bin/open -b org.mozilla.firefox "https://github.com/{{.RepoName}}/pull/{{.PrNumber}}"'';
        }
      ];
      repoPaths = {
        "roshbhatia/*" = "${config.home.homeDirectory}/github/personal/roshbhatia/*";
      };
    };
  };

  programs.gh = {
    enable = true;

    gitCredentialHelper.enable = true;

    extensions = [
      pkgs.gh-aw
      (if pkgs.stdenv.hostPlatform.isDarwin then pkgs.sysinit-gh-dash else pkgs.gh-dash)
      pkgs.gh-enhance
      pkgs.gh-stack
    ];

    settings = {
      git_protocol = "https";
      prompt = "enabled";

      aliases = {
        co = "pr checkout";
        pv = "pr view";

        sv = "stack view";
        su = "stack up";
        sd = "stack down";
      };
    };
  };
}
