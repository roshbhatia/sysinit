{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  yarnPackages = [
    "@anthropic-ai/claude-code"
    "@github/copilot-language-server"
    "@owloops/claude-powerline"
  ]
  ++ values.yarn.additionalPackages;

in
{
  home.activation.yarnPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageManagerScript config "yarn" yarnPackages
  );
}
