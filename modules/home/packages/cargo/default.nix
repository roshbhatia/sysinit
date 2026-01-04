{
  config,
  values,
  utils,
  ...
}:

let
  cargoPackages = values.cargo.additionalPackages or [ ];
in
{
  home.activation = {
    cargoPackages = utils.packages.mkPackageActivation "cargo" cargoPackages config;
  };
}
