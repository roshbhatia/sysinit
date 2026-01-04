{
  config,
  values,
  utils,
  ...
}:

let
  pipxPackages = values.pipx.additionalPackages or [ ];
in
{
  home.activation.pipxPackages = utils.packages.mkPackageActivation "pipx" pipxPackages config;
}
