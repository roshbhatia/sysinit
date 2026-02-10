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

  # Policy files - enable only deny-based policies (no 'ask' rules)
  policyFiles = {
    "cupcake/policies/opencode/tool_suggestions.rego" = ./policies/opencode/tool_suggestions.rego;
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

    # Note: cupcake init --global not needed for OpenCode (plugin-based, not hook-based)
    # Global rulebook is already installed via xdg.configFile

    # Cursor hooks setup (DISABLED - not configured yet)
    # run ${pkgs.cupcake-cli}/bin/cupcake init --global --harness cursor

    # Claude Code hooks setup (DISABLED - not configured yet)
    # run ${pkgs.cupcake-cli}/bin/cupcake init --global --harness claude
  '';
}
