{
  lib,
  overlay,
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
    additionalPackages = (overlay.pipx.additionalPackages or [ ]);
    executableArguments = [
      "install"
      "--force"
    ];
    executableName = "pipx";
  };
}
