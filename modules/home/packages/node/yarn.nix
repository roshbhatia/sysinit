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
    "@fission-ai/openspec@latest"
    "@github/copilot"
    "osgrep"
  ]
  ++ (values.yarn.additionalPackages or [ ]);

in
{
  home.activation.yarnPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageManagerScript config "yarn" yarnPackages
  );
}
