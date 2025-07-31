{
  lib,
  values,
  utils,
  ...
}:

let
  pipxPackages = [ ]
  ++ (values.pipx.additionalPackages or [ ]);
in
{
  home.activation.pipxPackages = utils.sysinit.mkPackageManagerActivation "pipx" pipxPackages;
}
