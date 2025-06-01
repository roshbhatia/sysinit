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
      "uv"
    ];
    additionalPackages = (userConfig.pipx.additionalPackages or [ ]);
    executableArguments = [
      "install"
      "--force"
    ];
    executableName = "pipx";
  };
}
