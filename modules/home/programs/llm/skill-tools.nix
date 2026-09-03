{ pkgs, ... }:
{
  home.packages = [
    pkgs.sysinit-utils
    pkgs.ask
    pkgs.ask-providers
    pkgs.calldiff
  ];

  home.sessionVariables = {
    # Which agent bare `_` and `_j` run. Without it they open a picker on every
    # call, which is the whole cost of the short wrappers.
    #
    # The environment keeps bare `_` deterministic.
    ASK_PROVIDER = "claude";
  };
}
