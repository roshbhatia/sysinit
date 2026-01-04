{
  config,
  values,
  utils,
  ...
}:

let
  uvxPackages = [
    "hererocks"
    "https://github.com/github/spec-kit.git"
  ]
  ++ (values.uvx.additionalPackages or [ ]);
in
{
  home.activation.uvxPackages = utils.packages.mkPackageActivation "uv" uvxPackages config;
}
