{
  lib,
  overlay,
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
    additionalPackages = (overlay.uvx.additionalPackages or [ ]);
    executableArguments = [
      "tool"
      "install"
      "--force"
    ];
    executableName = "uv";
  };
}
