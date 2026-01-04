{
  config,
  values,
  utils,
  ...
}:

let
  vetPackages = values.vet.additionalPackages or [ ];
in
{
  home.activation = {
    vetPackages = utils.packages.mkPackageActivation "vet" vetPackages config;
  };
}
