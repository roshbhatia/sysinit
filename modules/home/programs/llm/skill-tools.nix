{ pkgs, ... }:
let
  askProviderNames = builtins.attrNames pkgs.ask-providers.providers;
in
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

  xdg.configFile = builtins.listToAttrs (
    map (name: {
      name = "ask/providers/${name}/provider.yaml";
      value.source = "${pkgs.ask-providers}/share/ask/providers/${name}/provider.yaml";
    }) askProviderNames
  );
}
