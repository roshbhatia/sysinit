{
  lib,
  userConfig ? { },
  ...
}:

let
  activationUtils = import ../../../../lib/activation/utils.nix { inherit lib; };
in
{
  home.activation.pipxPackages = activationUtils.mkPackageManager {
    name = "pipx";
    basePackages = [
      "black"
      "hererocks"
      "yamllint"
      "uv"
    ];
    additionalPackages =
      if userConfig ? pipx && userConfig.pipx ? additionalPackages then
        userConfig.pipx.additionalPackages
      else
        [ ];
    executableArguments = [
      "install"
      "--force"
    ];
    executableName = "pipx";
  };
}

