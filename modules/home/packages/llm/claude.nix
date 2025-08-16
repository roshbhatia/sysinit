{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  claudeEnabled = values.llm.claude.enabled or false;

  # Claude Code and powerline via yarn
  claudeYarnPackages = [
    "@anthropic-ai/claude-code"
    "@owloops/claude-powerline"
  ] ++ (values.llm.claude.yarnPackages or [ ]);

  # SuperClaude via uv
  claudeUvPackages = [
    "SuperClaude"
  ] ++ (values.llm.claude.uvPackages or [ ]);
in
lib.mkIf claudeEnabled {
  # Install Claude packages via yarn
  home.activation.claudeYarnPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.sysinit.mkPackageManagerScript config "yarn" claudeYarnPackages
  );

  # Install SuperClaude via uv
  home.activation.claudeUvPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.sysinit.mkPackageManagerScript config "uv" claudeUvPackages
  );
}
