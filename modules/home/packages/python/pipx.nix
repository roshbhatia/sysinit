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
    basePackages = [ ];
    additionalPackages = (overlay.pipx.additionalPackages or [ ]);
    executableArguments = [
      "install"
      "--force"
    ];
    executableName = "pipx";
  };
}
