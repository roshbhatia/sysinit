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
  home.activation.ghPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "gh" ghPackages config
  );
}
