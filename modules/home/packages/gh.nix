{
  config,
  lib,
  utils,
  ...
}:

let
  packages = [ ] ++ config.sysinit.gh.additionalPackages;
in
lib.mkIf (packages != [ ]) {
  home.activation.ghPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "gh" packages config
  );
}
