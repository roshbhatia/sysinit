{
  pkgs,
  lib,
  config,
  userConfig ? { },
  ...
}:

let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
in
{
  home.activation.uvxPackages = activationUtils.mkPackageManager {
    name = "uvx";
    basePackages = [ "skydeckai-code" ];
    additionalPackages =
      if userConfig ? uvx && userConfig.uvx ? additionalPackages then
        userConfig.uvx.additionalPackages
      else
        [ ];
    executableArguments = [
      "tool"
      "install"
    ];
    executableName = "uv";
  };
}

