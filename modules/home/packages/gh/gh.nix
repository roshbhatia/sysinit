{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  ghPackages = [
    "github/gh-copilot"
  ]
  ++ (values.gh.additionalPackages or [ ]);
in
{
  home.activation.ghPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.sysinit.mkPackageManagerScript config "gh" ghPackages
  );
}
