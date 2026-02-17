{
  config,
  lib,
  utils,
  ...
}:

let

  packages = [
    "@anthropic-ai/claude-code"
    "@fission-ai/openspec@latest"
    "@github/copilot"
    "@sourcegraph/amp@latest"
    "opencode-ai@latest"
  ]
  ++ config.sysinit.yarn.additionalPackages;
in
{
  home.activation.yarnPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "yarn" packages config
  );
}
