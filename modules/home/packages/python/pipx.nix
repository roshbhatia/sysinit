{
  lib,
  values,
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
in
{
  home.activation.pipxPackages = activation.mkPackageManager {
    name = "pipx";
    basePackages = [ ];
    additionalPackages = (values.pipx.additionalPackages or [ ]);
    executableArguments = [
      "install"
    ];
    executableName = "pipx";
  };
}

