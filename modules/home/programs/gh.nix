{ pkgs, ... }:

{
  programs.gh = {
    enable = true;

    gitCredentialHelper.enable = true;

    extensions = [ pkgs.gh-stack ];

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
