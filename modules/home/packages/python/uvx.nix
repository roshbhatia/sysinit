{
  lib,
  userConfig ? { },
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
in
{
  home.activation.uvxPackages = activation.mkPackageManager {
    name = "uvx";
    basePackages = [
      "skydeckai-code"
    ];
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

