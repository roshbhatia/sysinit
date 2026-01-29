{
  config,
  lib,
  values,
  utils,
  pkgs,
  ...
}:

let

  packages = [
    "https://github.com/github/gh-copilot"
  ]
  ++ (values.gh.additionalPackages or [ ]);
in
{
  home.activation.ghPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "gh" packages config
  );
}
