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
      "black"
      "hererocks"
      "yamllint"
    ];
    additionalPackages = (userConfig.uvx.additionalPackages or [ ]);
    executableArguments = [
      "tool"
      "install"
    ];
    executableName = "uv";
  };
}
