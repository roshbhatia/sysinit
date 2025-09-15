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
    "https://github.com/dlvhdr/gh-dash"
  ]
  ++ values.gh.additionalPackages;
in
{
  home.activation.ghPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageManagerScript config "gh" ghPackages
  );
}
