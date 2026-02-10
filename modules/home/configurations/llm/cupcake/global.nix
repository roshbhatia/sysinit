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
        # Minimal builtins - no policies loaded, just path protection
        protected_paths:
          enabled: true
          paths:
            - "/System/"
            - "~/.ssh/"
          message: "Critical system paths are protected"
    '';

  # Policy files - ALL DISABLED for now (were too restrictive with 'ask' prompts)
  # Re-enable individually as needed after testing
  policyFiles = {
    # All policies disabled - they had too many blocking 'ask' rules
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

  # Initialize Cupcake for all harnesses (DISABLED - policies too restrictive)
  home.activation.cupcakeInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # OpenCode plugin installation (DISABLED)
    # run mkdir -p ${config.xdg.configHome}/opencode/plugin
    # if [ ! -f ${config.xdg.configHome}/opencode/plugin/cupcake.js ]; then
    #   run curl -fsSL https://github.com/eqtylab/cupcake/releases/download/opencode-plugin-latest/opencode-plugin.js \
    #     -o ${config.xdg.configHome}/opencode/plugin/cupcake.js || echo "Warning: Failed to download cupcake plugin"
    # fi
    # run ${pkgs.cupcake-cli}/bin/cupcake init --global --harness opencode

    # Cursor hooks setup (DISABLED)
    # run ${pkgs.cupcake-cli}/bin/cupcake init --global --harness cursor

    # Claude Code hooks setup (DISABLED)
    # run ${pkgs.cupcake-cli}/bin/cupcake init --global --harness claude
  '';
}
