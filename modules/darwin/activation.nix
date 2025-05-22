{
  lib,
  userConfig ? { },
  ...
}:

let
  activationUtils = import ../lib/activation/utils.nix { inherit lib; };
in
{
  imports = [ ];

  home.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
  };

  home.activation.setupActivationUtils = activationUtils.mkActivationUtils {
    logDir = "/tmp/sysinit-logs";
    logPrefix = "sysinit";
    additionalPaths = if userConfig ? additionalPaths then userConfig.additionalPaths else [ ];
  };
}
