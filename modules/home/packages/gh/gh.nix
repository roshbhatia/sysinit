{
  config,
  lib,
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
    utils.packages.mkPackageManagerScript config "gh" ghPackages
  );
}
