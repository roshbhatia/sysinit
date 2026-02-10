{
  config,
  pkgs,
  lib,
  ...
}:
let
  policyBase = ./policies;
  signalBase = ./signals;

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
    "cupcake/policies/opencode/style_enforcement.rego" = ./policies/opencode/style_enforcement.rego;
  };

  # Signal scripts to install
  signalFiles = {
    "cupcake/signals/git_staged_sysinit.sh" = ./signals/git_staged_sysinit.sh;
    "cupcake/signals/git_unpushed.sh" = ./signals/git_unpushed.sh;
    "cupcake/signals/git_current_branch.sh" = ./signals/git_current_branch.sh;
  };

  # Convert files to xdg.configFile format with force = true
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

  # Initialize Cupcake for all harnesses
  home.activation.cupcakeInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # OpenCode plugin installation
    run mkdir -p ${config.xdg.configHome}/opencode/plugin
    if [ ! -f ${config.xdg.configHome}/opencode/plugin/cupcake.js ]; then
      run curl -fsSL https://github.com/eqtylab/cupcake/releases/download/opencode-plugin-latest/opencode-plugin.js \
        -o ${config.xdg.configHome}/opencode/plugin/cupcake.js || echo "Warning: Failed to download cupcake plugin"
    fi
    run ${pkgs.cupcake-cli}/bin/cupcake init --global --harness opencode

    # Cursor hooks setup
    run ${pkgs.cupcake-cli}/bin/cupcake init --global --harness cursor

    # Claude Code hooks setup  
    run ${pkgs.cupcake-cli}/bin/cupcake init --global --harness claude
  '';
}
