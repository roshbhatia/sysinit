{
  config,
  lib,
  ...
}:
# zmx: a named shell session that survives a detach, and nothing else.
#
# It has no windows, panes, or splits on purpose. That is the window manager's
# job, and this repository draws the same line everywhere else, which is why the
# dependency belongs here rather than in a change of its own.
#
# What it does NOT do, so the boundary stays where it was drawn:
#
#   it does not replace `wtrun`, whose worker pane is an owner-visible surface
#   it does not become the viewer source phase 5 built
#
# The package itself comes from `bootstrap/tools.toml`, in the `minimal` group,
# because `zmx-probe.md` established that mise can install it. This module owns
# only the two variables.
let
  paths = config.sysinit.paths.resolved;
in
{
  home.sessionVariables = {
    # The socket directory, which is a state path, so the phase 4 manifest owns
    # it and this module reads it from there.
    ZMX_DIR = paths.zmxSessions;

    # The namespace, which is NOT a state path and so is not in the manifest.
    # Design decision 4 draws that line: the manifest owns where things live,
    # the consumer owns the identity under it.
    #
    # Every session `s` creates lands under this prefix, so a session an owner
    # names by hand at a bare `zmx attach` is distinguishable from one seshy
    # made. `zmx-probe.md` records that zmx is consistent about it: the prefix
    # appears in `ZMX_SESSION` and in both forms of `zmx list`.
    ZMX_SESSION_PREFIX = "seshy-";
  };
}
