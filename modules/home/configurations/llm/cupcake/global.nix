{
  pkgs,
  lib,
  ...
}:
let
  policyBase = ./policies;
  signalBase = ./signals;

  makeRulebook =
    harness:
    pkgs.writeText "rulebook-${harness}.yml" ''
      version: "1.0"
      harness: ${harness}

      policies:
        directory: ${policyBase}/opencode

      signals:
        git:
          enabled: true
        filesystem:
          enabled: true
        custom:
          git_staged_sysinit:
            command: "${signalBase}/git_staged_sysinit.sh"
            description: "Check if .sysinit files are staged"
          git_unpushed:
            command: "${signalBase}/git_unpushed.sh"
            description: "Count unpushed commits"
          git_current_branch:
            command: "${signalBase}/git_current_branch.sh"
            description: "Get current branch name and protection status"

      builtins:
        # Security boundaries - hard blocks for dangerous operations
        # See: https://cupcake.eqtylab.io/reference/policies/builtin-config/

        rulebook_security_guardrails:
          enabled: true

        protected_paths:
          enabled: true
          paths:
            - "/System/"
            - "~/.ssh/"
            - "/etc/"
          message: "Critical system paths are protected"

        git_pre_check:
          enabled: true

        git_block_no_verify:
          enabled: true
    '';

  policyFiles = {
    "cupcake/policies/opencode/tool_suggestions.rego" = ./policies/opencode/tool_suggestions.rego;
    "cupcake/policies/opencode/safe_operations.rego" = ./policies/opencode/safe_operations.rego;
  };

  signalFiles = {
    "cupcake/signals/git_staged_sysinit.sh" = ./signals/git_staged_sysinit.sh;
    "cupcake/signals/git_unpushed.sh" = ./signals/git_unpushed.sh;
    "cupcake/signals/git_current_branch.sh" = ./signals/git_current_branch.sh;
  };

  policyFileConfigs = lib.mapAttrs (_name: source: {
    inherit source;
    force = true;
  }) policyFiles;

  signalFileConfigs = lib.mapAttrs (_name: source: {
    source = source;
    force = true;
    executable = true;
  }) signalFiles;

in
{
  xdg.configFile =
    policyFileConfigs
    // signalFileConfigs
    // {
      "cupcake/rulebook.yml" = {
        source = makeRulebook "opencode";
        force = true;
      };
    };

  home.activation.cupcakeInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.cupcake-cli}/bin/cupcake init --global --harness opencode
    run ${pkgs.cupcake-cli}/bin/cupcake init --global --harness cursor
    run ${pkgs.cupcake-cli}/bin/cupcake init --global --harness claude
  '';
}
