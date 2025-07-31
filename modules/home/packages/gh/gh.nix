{
  lib,
  values,
  utils,
  ...
}:

let
  ghPackages = [ ]
  ++ (values.gh.additionalPackages or [ ]);
in
{
  home.activation.ghPackages = utils.sysinit.mkPackageManagerActivation "gh" ghPackages;
}
