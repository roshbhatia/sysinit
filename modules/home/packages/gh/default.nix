{
  config,
  values,
  utils,
  ...
}:

let
  ghPackages = [
    "https://github.com/github/gh-copilot"
  ]
  ++ (values.gh.additionalPackages or [ ]);
in
{
  home.activation.ghPackages = utils.packages.mkPackageActivation "gh" ghPackages config;
}
