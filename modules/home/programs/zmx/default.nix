{
  config,
  lib,
  ...
}:
# zmx: a named shell session that survives a detach, and nothing else.
let
  paths = config.sysinit.paths.resolved;
in
{
  home.sessionVariables = {
    # The socket directory, which is a state path, so the phase 4 manifest owns
    # it and this module reads it from there.
    ZMX_DIR = paths.zmxSessions;

    # The namespace, which is NOT a state path and so is not in the manifest.
    ZMX_SESSION_PREFIX = "seshy-";
  };
}
