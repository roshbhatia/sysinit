{
  config,
  values,
  utils,
  ...
}:

let
  yarnPackages = [
    "@anthropic-ai/claude-code"
    "@fission-ai/openspec@latest"
    "@github/copilot"
    "@sourcegraph/amp@latest"
  ]
  ++ (values.yarn.additionalPackages or [ ]);

in
{
  home.activation.yarnPackages = utils.packages.mkPackageActivation "yarn" yarnPackages config;
}
