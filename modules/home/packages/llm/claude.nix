{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  claudeEnabled = values.llm.claude.enabled or false;

  claudeYarnPackages = [
    "@anthropic-ai/claude-code"
    "@owloops/claude-powerline"
  ]
  ++ (values.llm.claude.yarnPackages or [ ]);

  claudeUvPackages = [
    "SuperClaude"
  ]
  ++ (values.llm.claude.uvPackages or [ ]);
in
lib.mkIf claudeEnabled {
  home.activation.claudeYarnPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageManagerScript config "yarn" claudeYarnPackages
  );

  home.activation.claudeUvPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageManagerScript config "uv" claudeUvPackages
  );

}
