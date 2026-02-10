{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  packages = [ ] ++ (values.gh.additionalPackages or [ ]);
in
lib.mkIf (packages != [ ]) {
  home.activation.ghPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "gh" packages config
  );
}
