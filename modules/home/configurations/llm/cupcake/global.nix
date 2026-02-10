{
  pkgs,
  lib,
  ...
}:
let
  policyBase = ./policies;

  # Global rulebook with builtins and signals
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

      builtins:
        # Git protection builtins
        git_pre_check:
          enabled: true
          checks:
            - command: "task fmt:all:check"
              message: "Check formatting before commit"
            - command: "task nix:validate"
              message: "Validate Nix configuration"
          operations: ["commit", "push"]

        git_block_no_verify:
          enabled: true
          message: "Bypassing git hooks with --no-verify is prohibited. Fix reported issues instead."

        # File protection builtins
        protected_paths:
          enabled: true
          paths:
            - "/etc/"
            - "/System/"
            - "/nix/store/"
            - "~/.ssh/"
          message: "System paths are read-only and cannot be modified"

        rulebook_security_guardrails:
          enabled: true
          protected_paths:
            - ".cupcake/"
            - ".git/hooks/"
          message: "Cupcake configuration and git hooks are protected from modification"
    '';

  # Policy files to install
  policyFiles = {
    "cupcake/policies/opencode/system_protection.rego" = ./policies/opencode/system_protection.rego;
    "cupcake/policies/opencode/git_workflow.rego" = ./policies/opencode/git_workflow.rego;
    "cupcake/policies/opencode/file_protection.rego" = ./policies/opencode/file_protection.rego;
    "cupcake/policies/opencode/nix_workflow.rego" = ./policies/opencode/nix_workflow.rego;
    "cupcake/policies/opencode/sysinit_protection.rego" = ./policies/opencode/sysinit_protection.rego;
    "cupcake/policies/opencode/bash_protection.rego" = ./policies/opencode/bash_protection.rego;
  };

  # Convert policy files to xdg.configFile format with force = true
  policyFileConfigs = lib.mapAttrs (_name: source: {
    inherit source;
    force = true;
  }) policyFiles;

in
{
  xdg.configFile = policyFileConfigs // {
    "cupcake/rulebook.yml" = {
      source = makeRulebook "opencode";
      force = true;
    };
  };

  # Initialize Cupcake for all harnesses
  home.activation.cupcakeInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # OpenCode plugin installation (automatic via cupcake init)
    run ${pkgs.cupcake-cli}/bin/cupcake init --global --harness opencode

    # Cursor hooks setup
    run ${pkgs.cupcake-cli}/bin/cupcake init --global --harness cursor

    # Claude Code hooks setup  
    run ${pkgs.cupcake-cli}/bin/cupcake init --global --harness claude
  '';
}
