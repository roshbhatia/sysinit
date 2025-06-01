{
  lib,
  userConfig ? { },
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
in
{
  home.activation.pipxPackages = activation.mkPackageManager {
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

