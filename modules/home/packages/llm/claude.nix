{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  claudeEnabled = values.llm.claude.enabled;

  claudeYarnPackages = [
    "@anthropic-ai/claude-code"
    "@owloops/claude-powerline"
  ]
  ++ values.llm.claude.yarnPackages;

  claudeUvPackages = [
    "SuperClaude"
  ]
  ++ values.llm.claude.uvPackages;
in
lib.mkIf claudeEnabled {
  home.activation.claudeYarnPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageManagerScript config "yarn" claudeYarnPackages
  );

  home.activation.claudeUvPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageManagerScript config "uv" claudeUvPackages
  );

}
