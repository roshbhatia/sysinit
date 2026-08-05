{ pkgs, ... }:

{
  programs.gh = {
    enable = true;

    gitCredentialHelper.enable = true;

    # `gh stack`, from github/gh-stack. Installed as a package rather than with
    # `gh extension install`, which writes into ~/.local/share/gh at runtime and
    # would drift from the lock like any other unpinned fetch.
    extensions = [ pkgs.gh-stack ];

    settings = {
      git_protocol = "https";
      prompt = "enabled";

      aliases = {
        co = "pr checkout";
        pv = "pr view";

        # Stack navigation, spelled short because it gets used constantly while a
        # stack is open. Deliberately no alias for `stack submit`, `stack merge`,
        # or `stack push`: those reach GitHub, and a two-letter alias for an
        # outward-facing action is how one gets run by accident.
        sv = "stack view";
        su = "stack up";
        sd = "stack down";
      };
    };
  };
}
