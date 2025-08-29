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
    utils.sysinit.mkPackageManagerScript config "yarn" claudeYarnPackages
  );

  home.activation.claudeUvPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.sysinit.mkPackageManagerScript config "uv" claudeUvPackages
  );

  home.activation.claudeSuperclaude = lib.hm.dag.entryAfter [ "claudeUvPackages" ] ''
    echo "Configuring SuperClaude integration..."
    if command -v SuperClaude >/dev/null 2>&1; then
      SuperClaude install --components core mcp --yes --quiet --force --no-backup || echo "Warning: SuperClaude post-install failed"
    else
      echo "Warning: SuperClaude not found in PATH"
    fi
  '';
}
