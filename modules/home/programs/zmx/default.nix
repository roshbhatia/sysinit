{
  config,
  ...
}:
let
  paths = config.sysinit.paths.resolved;
in
{
  home.sessionVariables = {
    ZMX_DIR = paths.zmxSessions;

    ZMX_SESSION_PREFIX = "seshy-";
  };
}
