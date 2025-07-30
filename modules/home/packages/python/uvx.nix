{
  lib,
  values,
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
in
{
  home.activation.uvxPackages = activation.mkPackageManager {
    name = "uvx";
    basePackages = [
      "hererocks"
    ];
    additionalPackages = (values.uvx.additionalPackages or [ ]);
    executableArguments = [
      "tool"
      "install"
    ];
    executableName = "uv";
  };
}

