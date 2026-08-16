{ pkgs, ... }:
{
  home.packages = [
    pkgs.sysinit-utils
    pkgs.ask
    pkgs.calldiff
  ];

  home.sessionVariables = {
    # Which agent bare `_` and `_j` run. Without it they open a picker on every
    # call, which is the whole cost of the short wrappers.
    #
    # Set here rather than through `ask --set-config provider.default=`, because
    # that writes ~/.config/ask/config.json, which nothing in this repository
    # manages. The env var outranks that file, so once this is set the setting is
    # dead; `ask --set-config` says so when it writes one. `_cld` and `_cdx`
    # outrank both, so a per-call override still works.
    ASK_PROVIDER = "cld";
  };
}
