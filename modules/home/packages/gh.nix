{
  config,
  lib,
  values,
  utils,
  ...
}:

let

  packages = [
    "https://github.com/github/gh-copilot"
  ]
  ++ (values.gh.additionalPackages or [ ]);
in
lib.mkIf (packages != [ ]) {
  home.activation.ghPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "gh" packages config
  );
}
